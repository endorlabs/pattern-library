#!/usr/bin/env bash
### gets all critical vulns from all monitored versions of all projects
### don't forget to `endorctl init` or set appropriate env vars

[[ -z "$1" ]] && {
    >&2 cat << USAGE
Usage $0 PACKAGE_SEARCH
  PACKAGE_SEARCH is ideally a normalized packageURL with version
  Try $0 'mvn://org.apache.logging.log4j:log4j-core@3.0.0-beta2'
USAGE
    exit 1
}

## fix package matching
pkg_query="$1"
operator='=='
if [[ "$pkg_query" =~ ^pkg:maven/ ]] 
then pkg_url="mvn://$(echo "$pkg_query" | cut -d '/' -f 2):$(echo "$pkg_query" | cut -d '/' -f 3)"

elif [[ "$pkg_query" =~ ^[a-z]+://.+@.+ ]]
then pkg_url="$pkg_query" ; >&2 echo "Assuming '$pkg_query' is a packageURL"

else pkg_url=$pkg_query ; operator='matches' ; ENDOR_API_TIMEOUT=40s ; 
fi

if [[ $operator == "matches" ]]
then
    >&2 echo "Matching queries can be slow; search using packageURL format for a precise version for fastest results"
else
    [[ "$pkg_query"  == "$pkg_url" ]] || >&2 echo"$pkg_query => $pkg_url"
fi

## find the package version
PKVER_DATA=$(endorctl -n oss api list -r PackageVersion --filter="meta.name $operator '$pkg_url'" --field-mask='uuid,meta.name') || {
    _code=$?
    >&2 echo "Can't get package data, code $_code"
    echo "$PKVER_DATA" | jq
    exit $_code
}

## get the Metric data
MATCHES=( $(echo $PKVER_DATA | jq -r '.list.objects[]|.uuid') )
for found_uuid in "${MATCHES[@]}"
do
    >&2 echo "MATCH $found_uuid"
    SCORE_DATA=$(endorctl -n oss api list -r Metric --filter="meta.name==package_version_scorecard and meta.parent_uuid==$found_uuid" 2>/dev/null)
    if ! (echo "$SCORE_DATA" | jq -r '.list.objects[]' >/dev/null 2>/dev/null)
    then
        >&2 echo "-- MISSING SCORE DATA, skipping"
        continue
    fi
    
    PKG_NAME=$(endorctl -n oss api list -r PackageVersion --filter=uuid==$found_uuid --field-mask=meta.name 2>/dev/null | jq -r '.list.objects[0].meta.name')
    TOTAL_SCORE=$(echo "$SCORE_DATA" | jq -r '.list.objects[0].spec.metric_values.scorecard.score_card.overall_score')
    echo "{  \"name\": \"$PKG_NAME\", \"Total\": "$TOTAL_SCORE",  \"Scores\": $(echo "$SCORE_DATA" | jq -r '.list.objects[0].spec.raw.scoreCard.Scores') }" | jq
done
### pipe results to jq or something like fx for further processing

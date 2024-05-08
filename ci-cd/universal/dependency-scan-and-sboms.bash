## paste into or call from CI step using `bash` shell settings
# CONFIGURATION - use your CI's env & secrets to populate in production
BIN_OS='linux' ; BIN_ARCH='amd64'       # match your OS (linux or macos) and arch (amd64 or arm64)
ENDOR_NAMESPACE='your-namespace'      # get from UI: log in and look for name upper-left, under the E
ENDOR_API_CREDENTIALS_KEY='your-key'  # this is not secret; it's an ID -- get this and below from generating an API key
# ENDOR_API_CREDENTIALS_SECRET='your-secret'  # get this from a vault! Don't put this here, it's secret!


# ADDITIONAL CONFIGURATION for scan - this example assumes your working directory is the root
#   of your cloned git repository, and that you have completed building the projects in this repo
#   SEE [scan | Endor Labs](https://docs.api.endorlabs.com/endorctl/commands/scan/) for more options
ENDOR_SCAN_PR='false'  # set this true if this scan is occuring when a PR or MR is opened
# ENDOR_SCAN_INCLUDE=  # use this regex to scan specific software pacakges inside a repository; otherwise all will be scanned
ENDOR_SCAN_EXCLUDE='docs/'  # use this regex to exclude paths containing code you don't want scanned; docs and tests are common exclusions
ENDOR_SCAN_SUMMARY_OUTPUT_TYPE='summary'  # shows table of policy violations; use table, json, or yaml to get all findings in output
# ENDOR_SCAN_REGISTRIES=    # use this to provide URLs of private package registries (like Artifactory), if any, for Endor Labs to query

set -eo pipefail
### this assumes you have scripts from this repo in your workingdir at .endorlabs/ -- adjust as needed!
## download latest endorctl and verify it
$(source .endorlabs/get-latest-endorctl.bash) > /dev/null
ENDORCTL=".endorlabs/endorctl"


# scan dependencies and check for secrets
# saves output in endorlabs-output.summary (or .table, .json, etc.)
# and logs in endorlabs-scan.log
if ("$ENDORCTL" scan --path=$(pwd) --dependencies --secrets | tee endorlabs-output.${ENDOR_SCAN_SUMMARY_OUTPUT_TYPE:-.table})
then
    >&2 echo "OK: scan completed with no errors or policy violations"
elif [[ $? == 128 ]]
then
    >&2 echo "WARNS: scan completed with policy warnings"
elif [[ $? == 129 ]]
then
    >&2 echo "BLOCK: scan completed with policy errors!"
    # do any post processing here, but we'll stop
    exit 129
else
    _code=$?
    >&2 echo "ERROR: scan failed with code $_code"
    exit $_code
fi

# generate SBOM file
GIT_SHA=$(git show -s --format='%H')  # gets the source ref so we can find the right versions

## Get the project that relates to this repo
PROJECT_UUID=$(endorctl api list -r Project --filter="meta.name=='$(git remote get-url origin)'" --field-mask='uuid' | jq -r '.list.objects[]|.uuid')

## get the list of pacakges that are part of this repo
PACKAGE_UUIDS=( $(endorctl api list -r Package --filter="meta.parent_kind=='Project' and meta.parent_uuid=='$PROJECT_UUID'" --field-mask='uuid'| jq -r '.list.objects[]|.uuid') )
for PACKAGE_ID in "${PACKAGE_UUIDS[@]}"
do
    ## Get the version of this package that's associated with this ref
    package_ver_data=$(endorctl api list -r PackageVersion --field-mask='uuid,meta,spec.source_code_reference'\
     --filter="meta.parent_uuid==$PACKAGE_ID and spec.source_code_reference.version.sha==${GIT_SHA}" 2>/dev/null) 
    package_ver_uuid=$(echo "$package_ver_data" | jq -r '.list.objects[].uuid' 2>/dev/null) || {
        >&2 echo "no package versions match $PACKAGE_ID@$GIT_SHA"
        continue
    }
    package_ver_name=$(echo "$package_ver_data" | jq -r '.list.objects[].meta.name')
    sbom_file="$package_ver_uuid.cdx.json"

    ## Export the SBOM for the correct package version, if it's available
    >&2 echo "Getting SBOM for package $package_ver_name as '$sbom_file'"
    "$ENDORCTL" sbom export --package-version-uuid=$package_ver_uuid > "$sbom_file" 2>/dev/null || {
        >&2 echo "-- ERR SBOM not available for $package_ver_name:\n     $(jq -r '.message' "$sbom_file")"
        # echo "$(jq -r '.code' "$sbom_file")"; exit 1
        rm "$sbom_file"
    }
done


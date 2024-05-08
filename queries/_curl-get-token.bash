#!/usr/bin/env bash
set -e

function check_env () {
    if [[ -z "${!1}" ]]
    then
        >&2 echo "${1} must be set"
        exit 1
    fi
    [[ "$2" == "echo" ]] && echo "${!1}"
    return 0
}

function check_bin_path () {
    if pth=$(which "$1")
    then
        [[ "$2" == "echo" ]] && echo "$pth"
    else
        >&2 echo "could not find required tool '${1}' in PATH"
        exit 2
    fi
    return 0
}

## Check for env variables to be set
check_env ENDOR_NAMESPACE
check_env ENDOR_API_CREDENTIALS_KEY
check_env ENDOR_API_CREDENTIALS_SECRET

## we need curl and jq to do the job; bail early if they can't be found in PATH
check_bin_path curl
check_bin_path jq

## POST a JSON document to the Endor Labs api-key auth endpoint
RESULT=$(curl -s -X POST -H "Content-Type: application/json" -o - \
  -d "{\"key\": \"${ENDOR_API_CREDENTIALS_KEY}\", \"secret\": \"${ENDOR_API_CREDENTIALS_SECRET}\"}"\
  'https://api.endorlabs.com/v1/auth/api-key')
  
TOKEN=$(echo "$RESULT" | jq -r '.token')
[[ "$TOKEN" == "null" ]] && { >&2 echo "ERROR getting auth token"; echo "$RESULT" | jq -C >&2 ; exit 5; }
    
>&2 echo "Got token successfully, saving in ENDOR_TOKEN and creating convenience env alias endor_curl"
export ENDOR_TOKEN="$TOKEN"

## function that wraps curl to make requests be authorized with token
## if the first arg is a flag starting with `--`, that will be the "pretty" mode (default is jq)
## use as `endor_curl [--raw|jq|fx|...] URL [curl_options]`
function endor_curl () {
    ## if first arg is '--raw', remove it at set raw mode
    if [[ "$1" == --* ]]; then
        mode=${1/--/}
        shift
        [[ "$mode" == "raw" ]] && mode="cat"
    else
        mode="jq" # default to colorizing with jq
    fi
    check_bin_path $mode

    ## curl the URL with auth and any args provided;
    ## if $mode is set, then just pipe the result to cat, otherwise make it pretty with jq -C
    curl -s -H "Authorization: Bearer ${ENDOR_TOKEN}" -o - "$@"\
     | ( ${mode} )

}



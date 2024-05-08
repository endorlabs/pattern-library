#!/usr/bin/env bash
## A simple example to show how to use _curl-get-token.bash and the endor_curl function
## Lists a single project's uuid and metadata
set -eo pipefail

## uses another script in this repo to authenticated
## you'll need to set your API key and secret first
source "$(dirname "${BASH_SOURCE[0]}")/_curl-get-token.bash"

## endor_curl is defined during 'source' above, and by default "pretties" the output with 'jq'
## for it to work, you'll need to have set ENDOR_NAMESPACE to your namespace
## -G is a curl option that allows specifying query parameters with -d, which properly encodes them
endor_curl "https://api.endorlabs.com/v1/namespaces/${ENDOR_NAMESPACE}/projects"  -G \
    -d "list_parameters.mask=uuid,meta,processing_status" \
    -d "list_parameters.page_size=1" 

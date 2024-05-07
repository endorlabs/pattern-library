#!/usr/bin/env bash
### gets all critical vulns from all monitored versions of all projects
### don't forget to `endorctl init` or set appropriate env vars

endorctl api list -r Finding \
    --filter='context.type contains [CONTEXT_TYPE_MAIN, CONTEXT_TYPE_REF] AND spec.level ==  "FINDING_LEVEL_CRITICAL" AND spec.finding_categories contains FINDING_CATEGORY_VULNERABILITY' \
    --list-all

### pipe results to jq or something like fx for further processing

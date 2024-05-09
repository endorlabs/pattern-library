# endorctl / API Queries

This section contains example, documented shell scripts that show how to use `curl` or the Endor Labs CLI (`endorctl`) to perform various common API queries that many users find valuable.

Endor Labs' platform is **API-first**, so _all data is available via the API_; this resource only covers very common use cases and patterns that aren't in the [`api` subcommand reference](https://docs.endorlabs.com/endorctl/commands/api/). Refer to [Endor Labs Documenation](https://docs.endorlabs.com/) for more complete information.

## Use notes

All examples that use `endorctl` (files that begin `cli-`) assume that you have an authenticated session. That means one of:

* You've run `endorctl init --method=METHOD_NAME` successfully on the local machine
* You've generated an API key and secret, and set the relevante environment variables correctly
* You're using one of the secretless authentication pathways (e.g. GitHub Action OIDC, GCP OIDC, etc.) and have set the relevant environement variables correctly

It also assumes you've set the environment variable `ENDOR_NAMESPACE` to your namespace (found in the upper-left of the web portal when you log in).

Use `endorctl api list -r Project --field-mask 'uuid' --page-size=1` to quickly verify you have basic read rights setup correctly; if you don't get an error message, you should be ok.

-----

All examples that use `curl` (files that begin `curl-`) assume you have an API key and secret in the same environment variables `endorctl` would expect, and that you've set up your host so that `curl` can traverse any egress controls on your network transparently.

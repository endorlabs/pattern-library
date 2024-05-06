# Supervision with Endor Labs

Supervision patterns involve scanning targets without having to integrate into a given software repo's pipelines or workflows

There are two basic recommended patterns for supervision

1. The [Endor Labs GitHub App](https://docs.endorlabs.com/integrations/github-app/) for continous monitoring
    - this approach scans the default branch daily, using Endor Labs hosted containers, and attempts auto-build where required
    - deploy in a few clicks
    - supports GitHub and GitHub Enterprise Cloud only
2. Supervisory pipelines -- see [an example template for supervision using GitHub Actions](https://github.com/endorlabs/endor-github-workflow)
    - this approach involves conducting scans in your environment
    - more customizable: customize scan cadence and frequency, target branch, etc.
    - supports any git-based repository

## Tradeoffs

Supervision has significant advantages:

- Low effort/cost to deploy and maintain
- Automatic discovery and onboarding of new repos
- Adds no time to build or deploy pipelines

However, there are some notable disadvantages in exchange:

- Since it's not aligned with PR events, can't have PR comments or other "point of introduction" feedback
- Policy _enforcement_ is not possible (alerting only)
- Relies on an auto-build approach, which may not always be successful, leading to reduced results quality and some projects that will not scan through this method

## Recommended pattern

Our recommendation is generally to rollout as follows:

1. Deploy supervisory scanning & develop basic policies
2. Using results to inform priority, deploy pipeline workflow integrations
    1. in places where scans fail or get inadequte results
    2. in places where policy enforcement, scans of every release, or dev feedback during PR is essential
    3. in places where any of the above are _desired_ (i.e. high value) but not essential

This approach allows you to get immediate value, then iterate to get increase the benefits from using Endor Labs
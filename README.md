<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/kubemoot-horizontal-white-text.png">
  <img src=".github/assets/kubemoot-horizontal-color.png" alt="Kubemoot" height="64">
</picture>

# Kubemoot Docs Site (Hugo + Docsy)

[![Latest release](https://img.shields.io/github/v/release/kubemoot/kubemoot-docs?sort=semver)](https://github.com/kubemoot/kubemoot-docs/releases/latest) [![Build status](https://github.com/kubemoot/kubemoot-docs/actions/workflows/release-docs.yaml/badge.svg?branch=main)](https://github.com/kubemoot/kubemoot-docs/actions/workflows/release-docs.yaml?query=branch%3Amain) [![License: Apache 2.0](https://img.shields.io/github/license/kubemoot/kubemoot-docs)](https://github.com/kubemoot/kubemoot-docs/blob/main/LICENSE)

The documentation site for the Kubemoot ecosystem, published at
[kubemoot.org](https://kubemoot.org). Built with Hugo and the
[Docsy](https://www.docsy.dev/) theme. This repo holds the site shell and the
cross-cutting chapters; each component's reference docs live in its own repo and
are aggregated at build time via Hugo module mounts.

## Site structure

| Content path | Source |
|---|---|
| `/docs/` | `kubemoot/docs/` (operator, agent runtime, reference, the kmctl CLI) |

Additional component chapters are added as those repos publish their own `docs/`
directories.

## Build the site

The `hugo.toml` mount points at `../kubemoot/docs`, so the site needs a `kubemoot`
checkout next to this one. Fetch just its `docs/` directory with a sparse checkout,
then build:

```bash
git clone --filter=blob:none --sparse https://github.com/kubemoot/kubemoot.git ../kubemoot
git -C ../kubemoot sparse-checkout set docs
npm ci                 # the PostCSS toolchain Docsy needs
hugo --gc --minify --baseURL https://kubemoot.org/   # output in ./public/
```

Without `../kubemoot/docs`, Hugo still exits 0 and builds a site with only the shell pages,
no component docs, and no error. If the page count is far below 100, check the mount
path first.

For a live preview, run `hugo server` from this directory instead of the last command
and open http://localhost:1313. Node must be on your `PATH` for the Docsy PostCSS step.

## kubemoot.org (CI build and deploy)

`.github/workflows/site.yaml` builds the site on a GitHub-hosted runner: it checks
out this shell beside a sparse checkout of `kubemoot/docs`, runs Hugo with
`--baseURL https://kubemoot.org/`, proves the render (index, docs index, quickstart,
a page-count floor), and uploads `public/` as an artifact. When the repository
variable `SITE_DEPLOY` is `true`, a second job publishes that artifact as the
Cloudflare Worker `kubemoot-org` (static assets, `wrangler.toml`) with
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. The custom domain `kubemoot.org`
is declared in `wrangler.toml` and attached by Cloudflare on the first deploy.

The Worker script `worker/index.js` redirects `www.kubemoot.org` to the apex with a 301
and serves everything else from the built site, including `404.html` with a 404 status.
The build also produces `robots.txt`, `sitemap.xml`, and `llms.txt` (generated from the
docs sections by `layouts/index.llms.txt`). `scripts/check-site.sh public` verifies those
files, the description, Open Graph, Twitter card, and canonical tags, and that every
`llms.txt` link resolves; `node --test worker/index.test.js` tests the redirect. The share
image is `static/social/kubemoot.png`, a brand copy tracked in `brand.lock`.

## How aggregation works

The `hugo.toml` `[module]` section mounts each component's `docs/` tree under
`content/`:

```
../kubemoot/docs  -->  content/docs
```

`CLAUDE.md` files from component repos are excluded from the build output by the
mount's file filter.

## Republishing when component docs change

The site aggregates each component's docs at build time, so a change to
`kubemoot/docs` reaches the site only when this repo builds again. The workflow
`trigger-docs-rebuild.yaml` in the `kubemoot` repo does that: when `docs/**` changes on
`main`, it sends this repo a `kubemoot-docs-changed` repository dispatch. Release Docs
Site then builds a new release candidate from this repo's unchanged `main` (the next free
`rc.N`, with no commit) and records the kubemoot commit it built with in the image label
`org.kubemoot.docs.kubemoot-revision` and in the candidate tag's message. To republish by
hand, run Release Docs Site with `force_release`.

## Docker image

The Dockerfile builds the site in a `golang:1.26-bookworm` stage (Go for Hugo
modules, Node for the Docsy PostCSS step), placing the checked-out component docs at
the mount path, then serves the static output from `nginxinc/nginx-unprivileged:1.27-alpine`. The site base
URL is the `SITE_URL` build argument (default `https://kubemoot.org/`), and the site
serves at its host root.

## Helm chart

`charts/kubemoot-docs/` - Deployment + Service + HTTPRoute (Gateway API),
mirroring the `kubemoot-dashboard` chart conventions. See the chart's
`values.yaml` for the image, pull-secret, and gateway settings.

## Community and contributing

Kubemoot is an independent open-source project under the Apache License 2.0. Contributing, support, governance, the code of conduct, security reporting, and releases are documented in one place: the [Community section of kubemoot.org](https://kubemoot.org/docs/community/). Ask questions and share ideas in [GitHub Discussions](https://github.com/orgs/kubemoot/discussions). Write to moot@kubemoot.org for anything else. Use security@kubemoot.org only to report a vulnerability, privately.

Documentation for each component lives in that component's repo: edit `docs/` in
[kubemoot/kubemoot](https://github.com/kubemoot/kubemoot) for the operator chapter.
Edit the site shell, landing page, and cross-cutting chapters (including the Community
section) here. See [CONTRIBUTING](CONTRIBUTING.md).

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

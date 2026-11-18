<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/kubemoot-horizontal-white-text.png">
  <img src=".github/assets/kubemoot-horizontal-color.png" alt="Kubemoot" height="64">
</picture>

# Kubemoot Docs Site (Hugo + Docsy)

[![Latest release](https://img.shields.io/github/v/release/kubemoot/kubemoot-docs?sort=semver)](https://github.com/kubemoot/kubemoot-docs/releases/latest) [![Build status](https://github.com/kubemoot/kubemoot-docs/actions/workflows/release-docs.yaml/badge.svg?branch=main)](https://github.com/kubemoot/kubemoot-docs/actions/workflows/release-docs.yaml?query=branch%3Amain) [![License: Apache 2.0](https://img.shields.io/github/license/kubemoot/kubemoot-docs)](https://github.com/kubemoot/kubemoot-docs/blob/main/LICENSE) [![OpenSSF Scorecard](https://img.shields.io/ossf-scorecard/github.com/kubemoot/kubemoot-docs?label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/kubemoot/kubemoot-docs)

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

### Site-owned pages

Four pages live in this repo under `content/en/docs/introduction/` and publish at
the same URLs whenever the site publishes, without waiting for a Kubemoot release:

- `roadmap.md` at `/docs/introduction/roadmap/`
- `faq.md` at `/docs/introduction/faq/`
- `related-projects.md` at `/docs/introduction/related-projects/`
- `how-the-pieces-fit-together.md` at `/docs/introduction/how-the-pieces-fit-together/`

They sit inside the `/docs/` tree, so the other chapters link to them with their
usual relative paths. The `kubemoot/docs` mount in `hugo.toml` excludes the same
four files, so the site has exactly one copy of each even when the pinned Kubemoot release
still contains one. Edit these pages here, not in `kubemoot/docs`.

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

## Preview

**Contributors:** run `hugo server` from this directory instead of the last command
and open http://localhost:1313. Pages reload as you edit. Node must be on your `PATH`
for the Docsy PostCSS step.

**Release candidate on a cluster:** every merge to `main` builds a candidate image and
chart. With `gateway.enabled: false` the chart installs only a Deployment and a
Service (`kubemoot-docs`, port 80) and exposes no hostname. To read a deployed
candidate, forward the Service and open http://localhost:8080:

```bash
kubectl -n <namespace> port-forward svc/kubemoot-docs 8080:80
```

kubemoot.org changes only through Publish Release.

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

## Diagrams

The site loads no unpinned third-party script. Docsy loads jQuery and the offline
search's `lunr` from public CDNs, each at an exact version with a subresource-integrity
hash, so a changed file fails to run.

Draw diagrams as inline SVG in the page or as an image file next to it
(`how-the-pieces-fit-together.md` uses an SVG). Mermaid is rejected: Docsy's renderer
loads it from a CDN as an unpinned `@latest` script, which would bypass the project's rule
that dependencies are pinned, so a page with a `mermaid` code block fails the build with a
message that points here. `scripts/check-site.sh` runs `scripts/check-scripts.sh`, which
fails when a built page loads an external script without an exact version and an integrity
hash, when an inline script imports a module from a CDN, or when it finds no script tags at
all. It reads the HTML, so a script another script adds at run time is not seen.
`scripts/check-site.test.sh` tests it against fixture pages.

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

## Container image

CI builds the site on a GitHub-hosted runner with the Hugo version in `.hugo-version`
and the Node version in `.nvmrc` (`.github/actions/build-site`, the same build as
kubemoot.org), and checks that nginx serves it with `nginx.conf`
(`scripts/check-nginx.sh`). The Paketo nginx buildpack then packages `public/` and
`nginx.conf` into the image in the cluster. nginx listens on 8080 as a non-root user
and writes only under `/tmp`, so the pod runs with a read-only root filesystem. The
image's site is built for `https://kubemoot.org/` and serves at its host root. Internal
links are relative, so the image works at any address, including a port-forward.

## Helm chart

`charts/kubemoot-docs/` - Deployment + Service + an optional HTTPRoute (Gateway API,
`gateway.enabled`),
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

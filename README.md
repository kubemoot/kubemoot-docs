# Kubemoot Docs Site (Hugo + Docsy)

The documentation site for the Kubemoot ecosystem. Built with Hugo and the
[Docsy](https://www.docsy.dev/) theme. This repo holds the site shell and the
cross-cutting chapters; each component's reference docs live in its own repo and
are aggregated at build time via Hugo module mounts.

## Site structure

| Content path | Source |
|---|---|
| `/docs/` | `kubemoot/docs/` (operator, agent runtime, reference, the kmctl CLI) |

Additional component chapters (CrewForge, Homelab Pilot, crews) are added as
those repos publish their own `docs/` directories.

## Local preview

The `hugo.toml` mount points at `../kubemoot/docs`, so the site builds against a
sibling `kubemoot` checkout. From inside the `homelab-ecosystem` umbrella, where
`kubemoot` is a sibling submodule, just run:

```bash
cd kubemoot-docs
npm install           # one-time: the PostCSS toolchain Docsy needs
hugo server
# visit http://localhost:1313
```

## kubemoot.org (CI build and deploy)

`.github/workflows/site.yaml` builds the site on a GitHub-hosted runner: it checks
out this shell beside a sparse checkout of `kubemoot/docs`, runs Hugo with
`--baseURL https://kubemoot.org/`, proves the render (index, docs index, quickstart,
a page-count floor), and uploads `public/` as an artifact. When the repository
variable `SITE_DEPLOY` is `true`, a second job publishes that artifact as the
Cloudflare Worker `kubemoot-org` (static assets, `wrangler.toml`) with
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. The custom domain `kubemoot.org`
is declared in `wrangler.toml` and attached by Cloudflare on the first deploy.

Outside CI, the same build is:

```bash
git clone --filter=blob:none --sparse https://github.com/kubemoot/kubemoot.git ../kubemoot
cd ../kubemoot && git sparse-checkout set docs && cd -
npm ci
hugo --gc --minify --baseURL https://kubemoot.org/   # output in ./public/
```

## How aggregation works

The `hugo.toml` `[module]` section mounts each component's `docs/` tree under
`content/`:

```
../kubemoot/docs  -->  content/docs
```

`CLAUDE.md` files from component repos are excluded from the build output by the
mount's file filter.

## Docker image

The Dockerfile builds the site in a `golang:1.26-bookworm` stage (Go for Hugo
modules, Node for the Docsy PostCSS step), placing the CI-checked-out component
docs at the mount path, then serves the static output from `nginx:1.27-alpine`.
The production `baseURL` is set in the Dockerfile and the site serves at its host
root.

## Helm chart

`charts/kubemoot-docs/` - Deployment + Service + HTTPRoute (Gateway API),
mirroring the `kubemoot-dashboard` chart conventions. See the chart's
`values.yaml` for the image and gateway settings.

## CI / Release

- `.github/workflows/ci-docs.yaml` - build and container-image push on every push
  to `main` (non-PR); also callable via `workflow_call` from the release workflow.
- `.github/workflows/release-docs.yaml` - SemVer release (tag prefix `docs-v`):
  retags the built image, updates `Chart.yaml`, pushes the chart to the project's
  OCI registry, commits the chart bump, tags, and creates a GitHub Release.

The workflows expect registry credentials and a read token for the component
repos, configured as repository secrets.

## Publishing content changes

The site aggregates each component's docs (e.g. `kubemoot/docs`) at **build time**
via a sparse checkout of that repo's `main`. The release pipeline lives in THIS
repo, so a push to a component repo does NOT rebuild the site on its own, and a
no-op `workflow_dispatch` does NOT bump the version (so nothing redeploys).

To publish a component-docs change: merge it to the component repo's `main`, then
make a commit in this repo that **changes a tracked file under the release
`paths:` filter** (`**.md`, `content/**`, `layouts/**`, `Dockerfile`, `charts/**`,
and the rest in `release-docs.yaml`). That bumps the SemVer tag, builds a fresh
image (picking up the component's current `main`), pushes a new chart version, and
the GitOps pipeline rolls it out to the live site. (A cross-repo auto-trigger from
the component repos is a future improvement.)

IMPORTANT: an **empty** commit does NOT work. `Release Docs Site` triggers on
push only when changed paths match the filter, so `git commit --allow-empty`
matches nothing and never fires. A one-line README edit is the simplest reliable
trigger. A cross-repo auto-trigger (a component push to `docs/**` dispatches this
repo's release) would remove the manual step; tracked as a backlog improvement.

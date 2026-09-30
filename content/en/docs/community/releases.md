---
title: "Releases and Versioning"
weight: 50
description: "How a merge to main becomes a release candidate and how a maintainer promotes it to a versioned release."
---

Every merge to `main` builds a release candidate. A maintainer promotes a tested
candidate to a public release. Users install final releases; `main` is in development.

## From merge to release

**Release candidates.** Each component in a repository has its own release workflow
that runs on a push to `main` that changes that component's files. The workflow:

1. Runs the component's CI.
2. Computes the next version from the conventional-commit messages since the
   component's last release: `fix:`, `docs:`, `chore:`, and `refactor:` bump the patch
   number, `feat:` bumps the minor, and `feat!:`, `fix!:`, or a `BREAKING CHANGE`
   footer bumps the major. See [Contributing](../contributing/#commit-messages).
3. Tags the commit with a candidate version, `X.Y.Z-rc.N`.
4. Builds the candidate image and chart and pushes them to the maintainers' own
   registry. Candidates are not published publicly and are not meant for installation.

**Promotion.** When a candidate has passed its tests, a maintainer runs the
**Promote Release** workflow. It publishes the exact images that were tested, copied by
digest and not rebuilt, to GHCR under their final version `X.Y.Z`. It packages the final
Helm charts with the final image versions, pushes them to `oci://ghcr.io/kubemoot/charts`,
tags the candidates' commits with the final version, runs the quickstart against the
published chart, and creates the GitHub Release with notes generated from the
conventional commits. Promotion defaults to a dry run that plans the release and
publishes nothing.

Promotion is per repository:

- `kubemoot` promotes the operator chart together with every image it pins.
- `crews` promotes each crew chart. A crew that pins an unreleased Kubemoot candidate
  is refused until Kubemoot is promoted.
- `kmctl` promotes the command-line binaries.
- `kubemoot-docs` promotes this documentation site.

A merged pull request therefore ships in the next promoted release, not at merge time.

## Git tags are the version

The git tag is the single source of truth for a version. No version is written by hand
in a manifest, an image tag, or an environment variable; the pipeline propagates it.
Each component has its own tag stream, so components version independently:

| Repository | Final tag format | Example |
|------------|------------------|---------|
| `kubemoot`, operator | `v<version>` | `vX.Y.Z` |
| `kubemoot`, other components | `<component>-v<version>` | `agent-runtime-vX.Y.Z` |
| `crews`, each crew | `<crew>-v<version>` | `homelab-pilot-crew-vX.Y.Z` |
| `kmctl` | `v<version>` | `vX.Y.Z` |

Candidate tags add a suffix: `vX.Y.Z-rc.N`.

## Where the artifacts are

Released artifacts are public. Candidates are not.

- **Container images** are published to GHCR under `ghcr.io/kubemoot`, as
  `ghcr.io/kubemoot/<image>:<version>`. Only final versions are published: there is no
  `latest` tag and no candidate tag.
- **Helm charts** are published as OCI artifacts under `oci://ghcr.io/kubemoot/charts`,
  for the operator chart and for each crew chart.
- **GitHub Releases** are created per promoted component, with generated release notes. The
  `kmctl` release carries the command-line binaries for Linux, macOS, and Windows on
  `amd64` and `arm64`, with a checksums file.
- **This documentation site** is deployed when the docs release is promoted.

Release images are `amd64` only today.

## API versions

The Kubemoot API group is `kubemoot.ai/v1alpha1`. Software versions and the API
version are separate: a component release does not promote the API, and the API can
change between releases while it is `v1alpha1`.

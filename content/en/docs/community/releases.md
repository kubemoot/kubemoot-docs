---
title: "Releases and Versioning"
weight: 50
description: "How a merge to main becomes a release candidate and how a maintainer promotes it to a versioned release."
---

Every merge to `main` builds a release candidate. A maintainer promotes a tested
candidate to a public release. Users install final releases; `main` is in development.

## The version rule

Versions live only in git tags. Files in git hold `0.0.0`. Every build computes its
version from the tags and stamps it into what it publishes, and CI never commits a
version back to the repository. The source tree therefore never carries a release or
candidate number, and the tag is the only record of what was released.

All repositories use the same pipeline pieces from
[`kubemoot/release-actions`](https://github.com/kubemoot/release-actions): one action
computes the next candidate version, one sets up the promotion helpers, and one
shell library holds the shared logic for candidates, promotion, and release notes. A
repository pins a released version of these actions by commit.

## From merge to release

**Release candidates.** Each component in a repository has its own release workflow
that runs on a push to `main` that changes that component's files. The workflow:

1. Runs the component's CI.
2. Computes the next version from the conventional-commit messages since the
   component's last release: `fix:`, `docs:`, `chore:`, and `refactor:` bump the patch
   number, `feat:` bumps the minor, and `feat!:`, `fix!:`, or a `BREAKING CHANGE`
   footer bumps the major. See [Contributing](../contributing/#commit-messages).
3. Tags the commit with a candidate version, `X.Y.Z-rc.N`.
4. Builds the candidate image and chart, stamping the candidate version at build time,
   and pushes them to the maintainers' own registry. Candidates are not published
   publicly and are not meant for installation.

**Promotion.** When a candidate has passed its tests, a maintainer runs the
**Promote Release** workflow. It always starts as a dry run: it plans the release,
packages the artifacts, shows the release notes in the run summary, and publishes
nothing. The maintainer reviews the plan, then runs it again with the dry run turned
off. A promotion publishes the exact images that were tested, copied by digest and not
rebuilt, to GHCR under their final version `X.Y.Z`. It packages the final Helm charts
with the final image versions, pushes them to `oci://ghcr.io/kubemoot/charts`, tags the
candidates' commits with the final version, runs the quickstart against the published
chart, and creates the GitHub Release.

Promotion is per repository:

- `kubemoot` promotes the operator chart together with every image it pins.
- `crews` promotes each crew chart. A crew that pins an unreleased Kubemoot candidate
  is refused until Kubemoot is promoted.
- `kmctl` promotes the command-line binaries.
- `kubemoot-docs` promotes this documentation site.
- `vscode-crewforge` promotes the CrewForge extension.

A merged pull request therefore ships in the next promoted release, not at merge time.

## Release notes

The notes of a GitHub Release list only what a user can see, in four groups:

- **Breaking changes**
- **New**: `feat:` commits
- **Fixed**: `fix:` commits
- **Faster**: `perf:` commits

Maintenance, documentation, and refactoring commits do not appear in the notes. Every
release links to the full list of commits since the previous release for readers who
want everything.

## CrewForge

CrewForge is promoted like every other component and publishes one more artifact: the
extension is released to the VS Code Marketplace and to Open VSX.

| Step | What happens |
|------|--------------|
| Candidate | Every merge to `main` tags `vX.Y.Z-rc.N` and packages the extension without publishing it. |
| Promotion | A maintainer runs **Promote Release**. It packages the extension again at the final version, tags the commit `vX.Y.Z`, and creates the GitHub Release with the package attached. |
| Registry publish | With the registry option selected, the same run publishes the attached package to the Marketplace and to Open VSX. |
| Approval | Registry publishing runs in the protected `marketplace` environment. It runs only from `main` and waits for a maintainer to approve, with no administrator bypass. |
| Sign-in | No registry token is stored. The Marketplace publish signs in with a Microsoft Entra federated credential that trusts only the `marketplace` environment. Open VSX uses Trusted Publishing, which trusts the promotion workflow of the repository. |
| Changelog | The Changelog tab on both registries is generated from the GitHub Releases, so it matches the release notes. |

## Git tags are the version

Each component has its own tag stream, so components version independently:

| Repository | Final tag format | Example |
|------------|------------------|---------|
| `kubemoot`, operator | `v<version>` | `vX.Y.Z` |
| `kubemoot`, operator chart | `operator-chart-v<version>` | `operator-chart-vX.Y.Z` |
| `kubemoot`, other components | `<component>-v<version>` | `agent-runtime-vX.Y.Z` |
| `crews`, each crew | `<crew>-v<version>` | `homelab-pilot-crew-vX.Y.Z` |
| `kmctl` | `v<version>` | `vX.Y.Z` |
| `vscode-crewforge`, CrewForge | `v<version>` | `vX.Y.Z` |
| `kubemoot-docs`, this site | `docs-v<version>` | `docs-vX.Y.Z` |

Candidate tags add a suffix: `vX.Y.Z-rc.N`.

## Where each repository stands

The version rule is the target for every repository. Today:

- `kmctl`, `vscode-crewforge`, and `kubemoot-docs` follow it: they stamp the version at
  build and commit nothing.
- `crews` follows next.
- `kubemoot` moves after the current release cycle.
- The remaining repositories follow after that.

A repository that has not moved yet still commits its candidate version to its chart
files after each build. Treat any version number in such a file as a build artifact, not
as a release record; the tag is the record.

## Where the artifacts are

Released artifacts are public. Candidates are not.

- **Container images** are published to GHCR under `ghcr.io/kubemoot`, as
  `ghcr.io/kubemoot/<image>:<version>`. Only final versions are published: there is no
  `latest` tag and no candidate tag.
- **Helm charts** are published as OCI artifacts under `oci://ghcr.io/kubemoot/charts`,
  for the operator chart and for each crew chart.
- **GitHub Releases** are created per promoted component, with generated release notes. The
  `kmctl` release carries the command-line binaries for Linux, macOS, and Windows on
  `amd64` and `arm64`, with a checksums file. The CrewForge release carries the extension
  package.
- **The CrewForge extension** is published to the VS Code Marketplace and Open VSX.
- **This documentation site** is deployed when the docs release is promoted.

Release images are `amd64` only today.

## API versions

The Kubemoot API group is `kubemoot.ai/v1alpha1`. Software versions and the API
version are separate: a component release does not promote the API, and the API can
change between releases while it is `v1alpha1`.

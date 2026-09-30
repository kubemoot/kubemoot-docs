---
title: "Releases and Versioning"
weight: 50
description: "How a merge to main becomes a versioned release: semantic versions from conventional commits, tags, images, charts, and GitHub Releases."
---

Kubemoot has no release trains or manual release steps. A merge to `main` is the
release.

## From merge to release

Each component in a repository has its own release workflow that runs on a push to
`main` that changes that component's files. The workflow:

1. Runs the component's CI.
2. Computes the next version from the conventional-commit messages since the
   component's last tag: `fix:`, `docs:`, `chore:`, and `refactor:` bump the patch
   number, `feat:` bumps the minor, and `feat!:`, `fix!:`, or a `BREAKING CHANGE`
   footer bumps the major. See [Contributing](../contributing/#commit-messages).
3. Tags the commit with that version.
4. Publishes the versioned container image and Helm chart.
5. Creates a GitHub Release for the tag.

## Git tags are the version

The git tag is the single source of truth for a version. No version is written by hand
in a manifest, an image tag, or an environment variable; the pipeline propagates it.
Each component has its own tag stream, so components version independently:

| Repository | Tag format | Example |
|------------|------------|---------|
| `kubemoot`, operator | `v<version>` | `vX.Y.Z` |
| `kubemoot`, other components | `<component>-v<version>` | `agent-runtime-vX.Y.Z` |
| `crews`, each crew | `<crew>-v<version>` | `homelab-pilot-crew-vX.Y.Z` |
| `kmctl` | `v<version>` | `vX.Y.Z` |


## Where the artifacts are

- **Container images** are published to GHCR under `ghcr.io/kubemoot`, as
  `ghcr.io/kubemoot/<image>:<version>`. Only versioned tags are published: there is no
  `latest` tag.
- **Helm charts** are published as OCI artifacts under `oci://ghcr.io/kubemoot/charts`,
  for the operator chart and for each crew chart.
- **GitHub Releases** are created per component, with generated release notes. The
  `kmctl` release carries the command-line binaries for Linux, macOS, and Windows on
  `amd64` and `arm64`, with a checksums file.
- **This documentation site** is rebuilt when the component docs or the site change.

Release images are `amd64` only today.

## API versions

The Kubemoot API group is `kubemoot.ai/v1alpha1`. Software versions and the API
version are separate: a component release does not promote the API, and the API can
change between releases while it is `v1alpha1`.

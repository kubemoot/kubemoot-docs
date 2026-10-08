---
title: "How Kubemoot Is Built and Secured"
weight: 45
description: "How changes are made, how versions and releases work, how the supply chain is protected, how the code is checked, and how the settings are managed, with a link to the evidence for each point."
---

This page describes how the project builds, releases, and protects its software, and
where you can see each practice for yourself. It follows the
[OpenSSF Best Practices](https://www.bestpractices.dev/) criteria for open-source
projects. The per-criterion answers live on the
[project's Best Practices entry](https://www.bestpractices.dev/projects/15226); this
page explains the practices in plain words and links to the files, workflows, and pages
that show them.

## How changes are made

- **Pull requests from forks.** Contributors fork a repository, branch off `main`, and
  open a pull request using the template. A maintainer review and approval is required
  to merge. See [Contributing](../contributing/#open-a-pull-request) and
  [Governance](../governance/#how-public-issues-and-pull-requests-are-handled).
- **Maintainers use pull requests too.** Every change to a public repository reaches
  `main` through a pull request that merges only after its required checks pass: the DCO
  sign-off, CodeQL, and a gate that waits for every other check, including the tests.
- **Conventional Commits.** Every commit message carries a prefix such as `fix:` or
  `feat:`, and the prefix decides the version bump. See
  [Contributing](../contributing/#commit-messages).
- **Developer Certificate of Origin.** Every commit is signed off, and a pull request
  check named "DCO" verifies it
  ([workflow](https://github.com/kubemoot/kubemoot/blob/main/.github/workflows/dco.yaml)).
  There is no contributor license agreement. See
  [Contributing](../contributing/#licensing-and-sign-off).
- **Tests ship with the change.** A new feature comes with tests, and a bug fix comes
  with a test that fails without the fix. The pull request template has a checklist
  item for it
  ([template](https://github.com/kubemoot/.github/blob/main/PULL_REQUEST_TEMPLATE.md)).
  See [Contributing](../contributing/#tests-ship-with-the-code).
- **AI-assisted work is visible.** Agent-authored commits use the `Klaude` identity and
  name the model in a `Co-Authored-By:` trailer, and they pass the same gates as every
  other change. See [Contributing](../contributing/#ai-assisted-working-style).
- **License.** Every repository is Apache License 2.0, for example the
  [LICENSE of kubemoot](https://github.com/kubemoot/kubemoot/blob/main/LICENSE).

## How versions and releases work

- **Versions live only in git tags.** Files in git hold `0.0.0`; every build computes
  its version from the tags and stamps it into what it publishes, and CI never commits a
  version back. See [The version rule](../releases/#the-version-rule).
- **Every merge to `main` builds a release candidate.** Candidates are tagged
  `X.Y.Z-rc.N` and are not published publicly. See
  [From merge to release](../releases/#from-merge-to-release).
- **A maintainer publishes a candidate.** The **Publish Release** workflow starts as a
  dry run that publishes nothing, then runs again with approval. It copies the exact
  tested images by digest rather than rebuilding them
  ([workflow](https://github.com/kubemoot/kubemoot/blob/main/.github/workflows/publish-release.yaml)).
- **Releases are immutable.** A published version is never rewritten; a fix ships as the
  next version.
- **Release notes list what users see.** Breaking changes, new features, fixes, and
  speedups, with a link to every commit. See
  [Release notes](../releases/#release-notes) and the
  [releases of kubemoot](https://github.com/kubemoot/kubemoot/releases).
- **One shared pipeline.** Every repository uses the same pinned actions from
  [`kubemoot/release-actions`](https://github.com/kubemoot/release-actions), so the logic
  is not copied from repository to repository.
- **No stored registry tokens for CrewForge.** The extension is published to the VS Code
  Marketplace and Open VSX only from the Publish Release workflow, in a protected environment
  that waits for maintainer approval, using federated sign-in instead of a stored token.
  See [CrewForge](../releases/#crewforge).

## How the supply chain is protected

- **Dependencies are pinned by digest.** Container base images and GitHub Actions
  reference an immutable digest or commit, not a movable tag. The default workflow token
  is read-only, and a job that needs more asks for it.
- **How images are built.** Every image is built inside the project's own cluster, in a
  short-lived pod with no Docker daemon and no privileged container. The Java, GraalVM
  native, and Go images, and the image of this documentation site, are built with
  [Cloud Native Buildpacks](https://buildpacks.io/) and the [Paketo](https://paketo.io/)
  buildpacks, as a non-root user, and carry a software bill of materials. The images
  that keep a Dockerfile (the dashboard, the RAG query service, the code sandbox, and
  the test runner) are built by [Buildah](https://buildah.io/) in a pod with its own
  user namespace, so the build is root only inside that namespace. The builder images are pinned by digest. Images go to
  the project's own registry first, and **Publish Release** copies the tested image to
  GHCR by digest, never rebuilding it (see the
  [roadmap](../../introduction/roadmap/#images-built-with-cloud-native-buildpacks)).
- **Dependabot** proposes updates to dependencies and Actions in every repository
  ([configuration](https://github.com/kubemoot/kubemoot/blob/main/.github/dependabot.yml)).
- **Signatures and provenance.** `kmctl` and CrewForge releases carry a keyless
  [Sigstore](https://www.sigstore.dev/) signature and SLSA build provenance. Every
  container image and Helm chart published to GHCR carries both, and the Kubemoot and
  crew GitHub Releases attach the provenance file.
  No signing key is stored; the certificate is issued to the release workflow's
  identity. You can check any of them yourself with the commands in
  [Verify images and charts](../releases/#verify-images-and-charts).
- **Secret scanning with push protection** is on for every public repository and blocks
  a push that contains a known credential format.

## How the code is checked

- **Tests** run in CI on every pull request and every push to `main`, and the
  [quickstart](../../introduction/quickstart/) runs against each release's published
  chart. The [Development Guide](../development/) lists the command for each component.
- **Linters** run in CI for every language and block a merge on any finding:
  `golangci-lint` for each Go module, Checkstyle for the Java services, ESLint and
  `svelte-check` for the dashboard and CrewForge, ruff for Python, and ShellCheck for
  scripts, with a cyclomatic complexity limit of 10. A false positive is suppressed on
  its line with the reason. See
  [Linters and warnings](../contributing/#linters-and-warnings).
- **CodeQL** scans every repository on every pull request, every push to `main`, and
  weekly. Every alert it has raised was fixed.
- **SonarQube** applies a quality gate on every push to `main` in the code repositories
  ([workflow](https://github.com/kubemoot/kubemoot/blob/main/.github/workflows/quality.yaml)).
- **Fuzz tests.** Every Go native fuzz target in the operator runs on each operator
  change ([workflow](https://github.com/kubemoot/kubemoot/blob/main/.github/workflows/ci.yaml)).
  Fuzzing has found real parser bugs, and each failing input is kept as a regression
  seed beside its fix.
- **OpenSSF Scorecard** runs on every push to `main` and weekly, and the results are
  public
  ([workflow](https://github.com/kubemoot/kubemoot/blob/main/.github/workflows/scorecard.yaml)).

The same checks are summarized on [Security](../security/#how-the-code-is-checked).

## How vulnerabilities are reported

Report a vulnerability privately through GitHub private vulnerability reporting or
[security@kubemoot.org](mailto:security@kubemoot.org), never in a public issue. The
steps, the supported versions, and the security model with its known limitations are on
the [Security](../security/) page, and each repository carries a `SECURITY.md` with the
same instructions.

## A known gap: credentials for tools

Kubemoot does not yet limit which Secrets a crew author may reference from an MCPServer.
Anyone who can create an MCPServer in a namespace can have the operator mount any Secret
in that namespace into it. Per-tool credential grants are the top priority on the
[roadmap](../../introduction/roadmap/#credentials-for-tools-granted-per-tool), and
[Secrets and tools](../../concepts/secrets-and-tools/) explains what to do until they
ship.

## Settings are code

The settings that protect the project are managed as code in OpenTofu, not by hand in a
web console: GitHub organization and repository settings, DNS, project mail routing,
CodeQL setup, and private vulnerability reporting. A settings change is therefore a
reviewed commit, and a drifted setting is corrected by the next apply. This
configuration lives in a maintainer-only repository.

## Badges

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/kubemoot/kubemoot/badge)](https://scorecard.dev/viewer/?uri=github.com/kubemoot/kubemoot)

The live results are in the
[Scorecard viewer](https://scorecard.dev/viewer/?uri=github.com/kubemoot/kubemoot).

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/15226/badge)](https://www.bestpractices.dev/projects/15226)

Kubemoot meets the OpenSSF Best Practices "passing" criteria. The answer and evidence
for each criterion are on the
[project's Best Practices entry](https://www.bestpractices.dev/projects/15226).

## Related pages

[Contributing](../contributing/), [Releases and Versioning](../releases/),
[Security](../security/), and [Governance](../governance/).

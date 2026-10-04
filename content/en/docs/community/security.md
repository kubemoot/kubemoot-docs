---
title: "Security"
weight: 40
description: "How to report a vulnerability, which versions get fixes, how the code is checked, and where the security model and known limitations are documented."
aliases:
  - /security/
---

## Reporting a vulnerability

Report a vulnerability privately, by either of these:

- **GitHub private vulnerability reporting.** Open
  [a private report on the kubemoot repository](https://github.com/kubemoot/kubemoot/security/advisories/new),
  or use **Report a vulnerability** on the **Security** tab of the affected repository
  (`kubemoot`, `kmctl`, `vscode-crewforge`, `crews`, or `kubemoot-docs`). The report is
  sent over HTTPS and only you and the maintainers can see it.
- **Email** [security@kubemoot.org](mailto:security@kubemoot.org). The project publishes
  no OpenPGP key, so email is not encrypted end to end; when the details must stay
  confidential in transit, use GitHub's private reporting.

The security address is only for vulnerability reports; send every other question to
[moot@kubemoot.org](mailto:moot@kubemoot.org) or
[GitHub Discussions](https://github.com/orgs/kubemoot/discussions). Do not open a public
issue, Discussion, or pull request for a security report.

Include what is affected (repository and version), the steps to reproduce, and what an
attacker gains. The project acknowledges reports within a reasonable period and
coordinates disclosure with the reporter before any public announcement. With a single
maintainer, that is best effort, not a guaranteed response time.

## Supported versions

Every merge to `main` that changes a component builds a release candidate, and a maintainer promotes it to a
versioned release (see [Releases](../releases/)). Kubemoot is a young project and does not backport fixes.
A security fix lands on `main` and ships in the next promoted release of the affected component;
to receive it, move to that release.

## How the code is checked

These checks run on the public repositories without anyone starting them:

- **CodeQL** code scanning, for every language in each repository, on every pull
  request, every push to `main`, and weekly.
- **Dependabot** security updates and version updates for each repository's
  dependencies and GitHub Actions.
- **Secret scanning** with push protection, which blocks a push that contains a known
  credential format.
- **OpenSSF Scorecard**, on every push to `main` and weekly. The results are public, for
  example the [Scorecard for kubemoot](https://scorecard.dev/viewer/?uri=github.com/kubemoot/kubemoot).
- **Fuzzing.** Every Go native fuzz target in the operator runs on each operator change,
  in pull requests and on `main`.
- **SonarQube** quality gate on every push to `main` in `kubemoot`, `kmctl`,
  `vscode-crewforge`, and `crews`; for `kubemoot` it also imports Trivy's findings.

Workflows reference GitHub Actions by commit SHA, and the default workflow token is
read-only; a job that needs more asks for it.

Every container image and Helm chart that **Promote Release** publishes to GHCR carries
a keyless Sigstore signature and SLSA build provenance
([Verify images and charts](../releases/#verify-images-and-charts)). The `kmctl` and
CrewForge releases carry the same for their release assets, attached to the GitHub
Release.

## Security model and known limitations

Kubemoot is a `v1alpha1` platform to evaluate and shape, not one to install where it
holds data or credentials you care about without reading its security model first. The
limitations are listed as they stand so you can decide whether they matter for your
deployment. The full text is the "Security model and known limitations" section of
[`SECURITY.md`](https://github.com/kubemoot/kubemoot/blob/main/SECURITY.md) in the
`kubemoot` repository. It covers:

- In-cluster endpoints, including the NATS message bus, that accept requests without
  authentication, and the fact that namespaces separate names but are not a security
  boundary today.
- Creating an `Agent`, `MCPServer`, or `RAGSource` is equivalent to creating pods.
- The RBAC of the optional internal MCP servers and of the reference crews.
- Agents act on text they read, so prompt injection through a tool, document, or web
  page can steer a tool-calling agent.
- The code sandbox depends on a CNI that enforces NetworkPolicy.
- API stability and platforms: `kubemoot.ai/v1alpha1` can change between releases, and
  release images are `amd64` only.

Admission webhooks require cert-manager; the quickstart runs with webhooks off for that
reason.

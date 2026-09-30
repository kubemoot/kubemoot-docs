---
title: "Security"
weight: 40
description: "How to report a vulnerability, which versions get fixes, and where the security model and known limitations are documented."
---

## Reporting a vulnerability

Report vulnerabilities privately to
[security@kubemoot.org](mailto:security@kubemoot.org). That address is only for vulnerability
reports; send every other question to [moot@kubemoot.org](mailto:moot@kubemoot.org) or
[GitHub Discussions](https://github.com/orgs/kubemoot/discussions). Do not open a public
issue, Discussion, or pull request for a security report. Where a repository's **Security**
tab offers **Report a vulnerability**, GitHub's private reporting works too.

Include what is affected (repository and version), the steps to reproduce, and what an
attacker gains. The project acknowledges reports within a reasonable period and
coordinates disclosure with the reporter before any public announcement. With a single
maintainer, that is best effort, not a guaranteed response time.

## Supported versions

Every merge to `main` that changes a component releases it (see [Releases](../releases/)). Kubemoot is a young project and does not backport fixes.
A security fix lands on `main` and ships in the next release of the affected component;
to receive it, move to that release.

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

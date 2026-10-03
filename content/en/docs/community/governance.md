---
title: "Governance"
weight: 20
description: "Who maintains Kubemoot, how decisions are made, and how public issues and pull requests are handled."
---

Kubemoot is an independent open-source project. Its governance is small and
deliberately simple, and this page states how it works today.

## Maintainers

| Maintainer | Role |
|------------|------|
| Jonathan Johnson | Maintainer |

Write access to the repositories in the `kubemoot` organization is limited to the
maintainers. Everyone else contributes through forks and pull requests.

## How decisions are made

The maintainer decides. Day-to-day changes are decided in the pull request or issue
where they come up. Changes that affect the API (the CRDs), the consensus protocol, or
how components fit together are discussed in the open first, so the reasoning is on
record:

- **Proposals.** Larger or cross-cutting changes start as an issue titled
  `Proposal: <summary>` that describes the problem, the proposed approach, the
  alternatives considered, and what it touches. A maintainer labels it `proposal`, and
  the discussion happens in the issue.
- **Architecture decisions.** Accepted proposals are implemented, and the reasoning
  behind significant ones is written into the architecture and concepts pages, so the
  design is documented in one place.
- **Direction.** The [Roadmap](../../introduction/roadmap/) lists the major directions
  under consideration. Items on it move when someone makes the case in
  [Discussions](https://github.com/orgs/kubemoot/discussions).

A formal enhancement-proposal process may be adopted if the number of contributors
warrants one.

## How public issues and pull requests are handled

Anyone can open an issue, start a Discussion, or send a pull request. Maintainers
review all of them.

- A pull request is reviewed against the [Contributing](../contributing/) standards:
  tests, conventional commits, and the project's conventions. A maintainer approval is
  required to merge.
- A good idea does not have to arrive in a mergeable form. Accepted ideas may be merged
  as submitted or reworked by the maintainers to fit the project's design. When the
  maintainers rework a significant contribution, such as an architectural change or a
  notable feature, the contributor is credited with a `Co-authored-by` trailer on the
  commit. Smaller ideas are acknowledged in the issue or pull request discussion.
- A change can also be declined. The maintainer says why.
- With a single maintainer, response time is best effort.

## Becoming a maintainer

The maintainers are not adding maintainers yet while the project's direction is moving
quickly; this may change as the project matures.

## Code of conduct and security

All participation is covered by the [Code of Conduct](../code-of-conduct/).
Vulnerabilities follow the [Security](../security/) policy.

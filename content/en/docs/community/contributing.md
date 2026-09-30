---
title: "Contributing"
weight: 10
description: "Issues, ideas, pull requests, commit conventions, tests, and how AI-assisted work is credited."
---

Contributions are welcome: bug reports, ideas, documentation fixes, tests, and code.
This page is the process. The [Development Guide](development/) covers the repository
layout and how to build and test each component.

## Report a bug or request a feature

- **Not sure it is a bug, or have a question?** Open a
  [Discussion](https://github.com/orgs/kubemoot/discussions).
- **Found a defect?** Open an issue on the repo where you found it, using the bug
  report template. If the [Quickstart](../introduction/quickstart/) itself failed, use
  the quickstart-failed template; it asks for what is needed to reproduce a
  fresh-cluster run.
- **Have an idea for a feature?** Start in Discussions, so the shape of the idea can
  settle before anyone writes code. A maintainer turns it into an issue when the work
  is clear. The feature request template works too when you already know what
  you want.
- **Larger or cross-cutting change?** Open an issue titled `Proposal: <summary>`
  describing the problem, the approach, the alternatives, and what it touches (CRDs,
  runtime, dashboard, crews). See [Governance](../governance/#how-decisions-are-made).

## Open a pull request

1. Fork the repository you want to change, clone your fork, and branch off `main`.
2. Make the change, with tests (see below).
3. Run the test suite for the component you touched. For the `kubemoot` repo, run the
   quickstart against a local `kind` cluster as a smoke test; it installs the operator,
   a small CPU model, and a two-agent crew, asks the crew a question, and checks that an
   answer comes back:

   ```bash
   kind create cluster --name kubemoot
   ./quickstart/quickstart.sh
   ```

4. Commit with a conventional-commit message (below).
5. Open a pull request against `main` using the template, and say what changed and why.

Once merged, a pull request builds a release candidate from `main` and ships in the
next promoted release; see [Releases](../releases/). Install final releases, not
`main`.

Small, focused pull requests review faster: one concern per pull request. A maintainer
review and approval is required to merge. The [Governance](../governance/) page
describes how public pull requests are handled.

## Commit messages

Versions come from git tags, and the release pipeline computes each version from the
conventional-commit prefixes since the previous release. Never type a version number by
hand. Use a [Conventional Commits](https://www.conventionalcommits.org/) prefix:

| Prefix | Version bump |
|--------|--------------|
| `fix:` | patch |
| `feat:` | minor |
| `docs:`, `chore:`, `refactor:` | patch |
| `feat!:`, `fix!:`, or a footer containing `BREAKING CHANGE` | major |

See [Releases](../releases/) for what a bump does.

## Tests ship with the code

A pull request that adds a function, method, or class includes a test for it, covering
the expected input and at least one unexpected one. Tests are part of the change, not a
follow-up. Where a repo has a linter, CI runs it; a failing check means the code needs
to change, not the check.

Keep functions at a cyclomatic complexity of 10 or less. Past that, extract methods,
use a dispatch table, or decompose the conditional before opening the pull request.

## Conventions a reviewer looks for

- **Prompts in ADL.** Agent prompt text lives in `PromptModule` resources written in
  ADL (the Architecture Definition Language), never inline in an Agent spec. See
  [Write Agents & ADL](../user-guides/write-agents-and-adl/).
- **Lifecycle belongs to the operator.** Cleanup, garbage collection, and namespace
  management are handled in the operator with finalizers and owner references, not in
  client-side tools.
- **Documentation with the change.** Component docs live in that component's `docs/`
  directory; the site shell and cross-cutting chapters live in the
  [kubemoot-docs](https://github.com/kubemoot/kubemoot-docs) repo.

## AI-assisted working style

Kubemoot is built largely by AI coding agents working under maintainer direction.
Their work is held to the same gates as anyone else's: tests, complexity limits, and
review. The code is judged on what it does, not on who or what typed it, and
contributions from AI assistants are welcome on the same terms.

Agent-authored commits are identifiable:

- The author is `Klaude <klaude@kubemoot.org>`, the identity the project's agents
  commit under.
- The model that did the work is credited in a `Co-Authored-By:` trailer on the commit.

If an AI assistant helped with your contribution, you are welcome to note it in the pull
request; it is not required.

## Credit

A contribution the maintainers rework to fit the project's design is still credited to
you. A significant contribution, such as an architectural change or a notable feature,
is credited with a `Co-authored-by` trailer on the commit. Smaller ideas are
acknowledged in the issue or pull request discussion.

## Licensing and sign-off

Kubemoot repositories are licensed under the Apache License 2.0. By submitting a
contribution you agree it is licensed under the same terms as the repository you are
contributing to. There is no contributor license agreement (CLA).

Every commit in a pull request requires a Developer Certificate of Origin (DCO) sign-off, which certifies
that you have the right to submit the change. Read the certificate at
[developercertificate.org](https://developercertificate.org/). Add the sign-off with
`git commit -s`, which appends a `Signed-off-by: Name <email>` line matching the commit
author. A pull request check named "DCO" verifies the sign-off.

To fix a missing sign-off:

```bash
git commit --amend -s --no-edit      # the last commit
git rebase --signoff <base-branch>   # several commits
```

Then force-push the pull request branch.

## Response time

The project has a single maintainer today, so responses to issues and pull requests are
best effort, with no guaranteed window. If a pull request sits without review, a polite
ping after a week or two is fine.

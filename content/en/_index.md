---
title: Kubemoot
description: "Kubemoot runs a crew of AI agents on Kubernetes that deliberate to a consensus answer, instead of trusting one large model. Open models, on the accelerators you choose."
---

{{< blocks/cover image_anchor="top" height="med" color="table" >}}
<div class="mx-auto">
  <h1 class="kubemoot-hero-title">{{< lockup >}}</h1>
  <p class="h4 mb-3">Every voice, one answer.</p>
  <p class="lead mt-3">
    A committee of AI agents that deliberate to an answer, instead of trusting one
    large model. Multi-agent consensus, Kubernetes-native.
  </p>
  <a class="btn btn-lg btn-drop me-3 mb-4" href="/docs/introduction/installation/">
    Install <i class="fas fa-arrow-alt-circle-right ms-2"></i>
  </a>
  <a class="btn btn-lg btn-outline-hero me-3 mb-4" href="/docs/introduction/quickstart/">
    Quickstart <i class="fas fa-terminal ms-2"></i>
  </a>
  <a class="btn btn-lg btn-outline-hero me-3 mb-4" href="https://github.com/kubemoot/kubemoot">
    View on GitHub <i class="fab fa-github ms-2"></i>
  </a>
</div>
{{< /blocks/cover >}}

{{% blocks/lead color="light" %}}
A **moot** is an assembly that settles a question by deliberation. Kubemoot runs a
crew of AI agents on Kubernetes that each bring their own expertise and reach
**consensus** over a message bus, where any of them can agree, raise a concern,
object, or stand aside. Capability is composed horizontally from many small models
rather than concentrated in one frontier model. Kubemoot focuses on crews of agents
reaching consensus on shared accelerators, and runs alongside projects such as kagent
and agentgateway.
{{% /blocks/lead %}}

{{% blocks/section color="white" type="row" %}}

{{% blocks/feature icon="fas fa-users" title="Consensus, not one model" %}}
Specialists deliberate and settle by signal - no single model, no fixed pipeline,
no majority vote. Failure is first-class signal, not silence.
{{% /blocks/feature %}}

{{% blocks/feature icon="fas fa-cubes" title="Declarative crews" %}}
Crews, agents, prompts (ADL), and scheduling policies are Kubernetes objects. Author by
`kubectl apply`; version with `git diff`; no recompilation.
{{% /blocks/feature %}}

{{% blocks/feature icon="fas fa-microchip" title="Runs on your accelerators" %}}
Just-in-time model scheduling spreads small models across commodity or local accelerators.
A crew states the models it needs and the cluster's catalog supplies them, so a crew
is portable across clusters; no frontier-model dependency.
{{% /blocks/feature %}}

{{% blocks/feature icon="fas fa-vial" title="Measurable" %}}
Executable fitness functions score a crew against ground truth - reference-grounded,
fabrication-aware - so crew quality is something you track, not guess.
{{% /blocks/feature %}}

{{% /blocks/section %}}

{{% blocks/section color="light" %}}
## Five-minute start

A CPU trial you can run on a laptop, no accelerator required: one script takes an empty
cluster to a crew answering a question. NATS, Ollama serving a small model from the
cluster's model catalog on CPU, the operator, and a two-agent crew.

```bash
git clone https://github.com/kubemoot/kubemoot.git && cd kubemoot
git checkout "$(git describe --tags --abbrev=0 --match 'operator-chart-v[0-9]*' --exclude '*-rc.*')"
kind create cluster --name kubemoot
./quickstart/quickstart.sh
```

The `git checkout` selects the latest release, and the script installs the chart of the
release it is checked out at. The same script runs in CI against every release, on a
2-CPU node. What each step creates, the CPU-trial-versus-accelerator profile, and how to
go further: **[Quickstart](/docs/introduction/quickstart/)**. To install the operator on
your own cluster with an accelerator-backed model server (vLLM is the preferred engine):
**[Installation](/docs/introduction/installation/)**.
{{% /blocks/section %}}

{{% blocks/section color="white" %}}
## The ecosystem

- **Kubemoot** - the operator: the Kubernetes controller and runtime that wire a crew together.
- **Crews** - packaged crews as Helm charts, from the reference crew to examples you can copy.
- **Homelab Pilot** - the reference crew, with its chat and dashboard app.
- **kmctl** - the command-line tool for crews, discussions, and the cluster's model catalog.
- **CrewForge** - the VS Code extension for building, deploying, and talking to crews.

See **[Ecosystem](/docs/ecosystem/)** for what each component is and how they fit.
{{% /blocks/section %}}

{{% blocks/section color="dark" %}}
## Community

Kubemoot is an independent open-source project under the Apache 2.0 license.
Start with the **[Community](/docs/community/)** section and the
**[Contributing](/docs/community/contributing/)** page, the
**[kubemoot organization](https://github.com/kubemoot)** on GitHub, and
**[Discussions](https://github.com/orgs/kubemoot/discussions)**. For anything else,
write to **moot@kubemoot.org**. **security@kubemoot.org** is only for vulnerability reports.

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/15226/badge)](https://www.bestpractices.dev/projects/15226)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/kubemoot/kubemoot/badge)](https://scorecard.dev/viewer/?uri=github.com/kubemoot/kubemoot)

See **[How Kubemoot is built and secured](/docs/community/how-kubemoot-is-built-and-secured/)**.
{{% /blocks/section %}}

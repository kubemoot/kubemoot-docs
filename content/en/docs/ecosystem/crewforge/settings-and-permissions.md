---
title: "Settings and permissions"
weight: 50
description: "Every CrewForge setting, and the cluster permissions each feature needs."
---

## Settings

Open **Settings** in VS Code and search for `crewforge`.

| Setting | Default | Meaning |
|---|---|---|
| `crewforge.kubeconfig` | empty | Path to a kubeconfig file. Empty uses `KUBECONFIG`, then `~/.kube/config`. |
| `crewforge.context` | empty | Kubernetes context to use. Empty uses the kubeconfig's current context. |
| `crewforge.namespaces` | `[]` | Show crews only in these namespaces. Set it when your account may read only some namespaces. Empty shows every namespace you can read. |
| `crewforge.streamTimeoutSeconds` | `600` | Longest a single turn may stream before CrewForge gives up on it. The minimum is 60. |
| `crewforge.dashboardService` | empty | The Kubemoot dashboard's Service as `namespace/name:port`. CrewForge reads it through the Kubernetes service proxy, read-only, for thread counts, discussion failures, fitness scores, and archived iterations. Empty finds the Service labelled `app.kubernetes.io/name=kubemoot-dashboard`. |
| `crewforge.dashboardUrl` | empty | The address of the [Kubemoot dashboard](../../../operating/dashboard/) for this cluster. **Powered by Kubemoot** in a chat opens it, and **Open this turn in the Kubemoot dashboard** appears under an answer only when this is set. Behind a `kubectl port-forward`, use the local address. Empty makes **Powered by Kubemoot** open this setting. |

The Kubemoot dashboard is optional. Without it, the parts of the crew and fitness
dashboards that come from it (discussion counts, agent failures, judge scores, and the
results workbook download) say they are not available.

## What your account needs

CrewForge acts as you. Each feature needs only the permissions below, and a part that
cannot be read says so instead of failing the whole view.

**Browse crews and chat**

- `list` on `crews.kubemoot.ai`, cluster-wide or in each namespace of
  `crewforge.namespaces`.
- `get` and `create` on `services/proxy` in the crew's namespace, to ask and to stream
  the answer.
- `get` on `endpoints` in that namespace, to tell whether the crew's discussion gateway
  is running.

**Explore a deployed crew**

- `get` and `list` on `agents`, `promptmodules`, `skills`, `mcpservers`, and
  `crewschedulingpolicies`. A kind you may not read shows as a warning under the crew.
- `delete` on those kinds and on `crews`, to undeploy a crew whose source is not open.

**Develop crews**

- `get` and `list` on the Kubemoot kinds a source renders.
- `patch` on `crews`, to record the deploy annotations.
- `create` on `crewfitnesses` and `crewfitnesssuites`, to start a fitness run.
- Whatever `helm` or `kubectl` need to deploy: typically `create`, `patch`, and `delete`
  on the objects a source renders, in the namespaces you deploy to.
- `get` on `helmreleases.helm.toolkit.fluxcd.io` (optional) to show the state of a
  crew that Flux manages. Without it the tree says it cannot read it.

**Dashboards** (each optional)

- `get` on `services/proxy` of the Kubemoot dashboard, and `list` on `services` to find
  it.
- `list` on `deployments`, or `get` on the Crew CRD, to find the operator's version.
- `patch` on `crewfitnesssuites`, and `delete` on `crewfitnesses`, for Pause, Resume,
  and Stop.

## The boundary CrewForge keeps

CrewForge's own writes to the API server are Kubemoot custom resources only: the
annotations on a Crew, the fitness runs it starts, and deleting a crew's Kubemoot objects
when you undeploy one. Deploying otherwise runs your own `helm` and `kubectl`.

CrewForge never deletes namespaces, manages Jobs, touches resources that are not
Kubemoot's, or implements cleanup or lifecycle logic. The
[operator](../../kubemoot-controller/) owns namespace lifecycle, garbage collection, Job
management, and cascading cleanup, through finalizers and owner references, even when
CrewForge started the delete.

## What CrewForge records on a deployed crew

A deploy from CrewForge annotates the Crew so later deploys can warn you before they
replace someone else's work.

| Annotation | Holds |
|---|---|
| `crewforge.kubemoot.ai/source` | The source's identity: `<repository>//<path>`, or `local:<folder>` outside git. |
| `crewforge.kubemoot.ai/owner` | The developer who deployed it, from git's `user.email`. |
| `crewforge.kubemoot.ai/revision` | The last commit that touched the source, with `-dirty` when it had uncommitted changes. |
| `crewforge.kubemoot.ai/channel` | `helm`, `bundle`, or `flux`. |
| `crewforge.kubemoot.ai/deployed-at` | When the deploy ran. |

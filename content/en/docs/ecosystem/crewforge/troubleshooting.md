---
title: "Troubleshooting"
weight: 60
description: "Fix a page stuck on Reading, an unreachable cluster, a missing kmctl or helm, a schema mismatch, and find CrewForge's logs."
---

## Where the logs are

CrewForge writes to its own output channel. Open **View > Output** and choose
**CrewForge** from the drop-down. It holds page errors, Lint failures, and the output of
the `helm` and `kubectl` commands behind a deploy, redeploy, or undeploy. A failed deploy
opens it for you. A failed `kmctl create` shows kmctl's own message in a dialog.

For a bug report, run **CrewForge: Show Connection Info** and use its **Copy** button. It
gives CrewForge's version, the Kubemoot operator's version, the Kubernetes server version,
and the context and server address.

## A dashboard says "Reading..." or "Still reading"

A dashboard shows **Reading...** while it loads, and **Still reading from context X...**
above the page when a read takes more than a moment. The trees show the same line above
their items. The cluster is answering slowly; the page updates when it does.

If the cluster does not answer, the page gives up after 45 seconds with **No answer from
context X in 45 s. Is the cluster running? Refresh reads again.** A request to the API
server that gets no answer for 20 seconds fails the same way in the trees. Check that the
cluster is up and that you can reach it (network, VPN, `kubectl get nodes` from a
terminal), then press **Refresh**.

If a page never leaves **Reading...** and then says **This page did not start**, its
script did not load. Run **Developer: Reload Window**. If the page stays empty, reinstall
the extension and report it with the output of **Show Connection Info**.

## The cluster is unreachable

CrewForge names the context and server it tried and what failed: refused, timed out, host
name not found, connection cut, an untrusted certificate, rejected credentials, a refused
request, or a login plugin that failed. The full list, with what each means, is in
[Install and connect](../install-and-connect/#when-the-cluster-cannot-be-reached).

Every one of those messages offers **Select Kubernetes Context**. Common fixes:

- The cluster is not running, or a `kubectl port-forward` or tunnel in front of it is
  down. Start it and press **Refresh**.
- The kubeconfig points at another cluster than the one you expect. Check the status
  bar's context, or run **CrewForge: Select Kubeconfig File**.
- The token expired. Log in again, or get a fresh kubeconfig.
- Your account is not allowed to read crews. See
  [what your account needs](../settings-and-permissions/#what-your-account-needs), and set
  `crewforge.namespaces` if you may read only some namespaces.

## Deployed Crews is empty

The context is reachable but shows no crews. Check in this order:

1. The status bar's context is the one you mean.
2. The Kubemoot operator is installed on that cluster (`kubectl get crds | grep kubemoot`).
3. `crewforge.namespaces` is empty, or includes the namespace you are looking for.
4. Your account may `list` `crews.kubemoot.ai` there.

## Crew Sources is empty

CrewForge looks in the folders open in the workspace for a Helm chart whose templates
declare a Kubemoot Crew, and for a folder of plain manifests that includes one. Open the
folder that holds the crew, or create one with **New Kubemoot Crew Here**. A source whose
render fails is listed with the error as an item; click it to open the file and line.

## A tool is missing

| You see | Cause and fix |
|---|---|
| Creating a crew needs kmctl 0.12.0 or later on your PATH, and none was found. | Install [kmctl](../../../user-guides/kmctl/#install) and make sure it is on the PATH of the VS Code that runs CrewForge. In a remote window, that is the remote machine's PATH. |
| Creating a crew needs kmctl 0.12.0 or later (for create --chart); found kmctl X. | `kmctl create --chart` arrived in 0.12.0. Upgrade kmctl. |
| Lint needs helm on your PATH to lint a Helm chart, and none was found. | Install [Helm](https://helm.sh/docs/intro/install/). A bundle of plain manifests lints without it. |
| Deploying a chart or a bundle fails to start. | `helm` and `kubectl` must be on the PATH of the VS Code window. Start VS Code from a shell where `helm version` and `kubectl version --client` work, then check the **CrewForge** output channel. |

Create Crew and Lint check the tool before they ask you anything, and show the problem as
a message you cannot miss.

## A schema mismatch

CrewForge checks your Kubemoot objects against the schemas your cluster serves. When your
source and your cluster's operator are different versions, you may see:

- **Lint: "spec has no field X; the API server would drop it."** The field is not in the
  CRD your operator serves. It is a typo, or the source is newer than the operator.
  Fix the name, or upgrade the operator.
- **Lint: "The Kubemoot schema check was skipped."** CrewForge could not read the schemas
  from the cluster, so it ran `helm lint` and the render only. Fix the connection and lint
  again.
- **Compare with Live shows a difference you did not make.** The API server drops fields
  its CRD does not define, so the live object lacks them. Treat it as the same mismatch.
- **Pause, Resume, and Stop are missing on the fitness dashboard.** Your operator's
  CrewFitnessSuite CRD does not have `spec.suspend` and `spec.cancel`. Upgrade the
  operator.

Check the operator's version with **Show Connection Info**. For the fields a resource
supports, see the [reference pages](../../../reference/crew/).

## Deploy and redeploy

- **A deploy is refused because Flux or a bundle already owns the crew.** Two channels
  must not fight over the same objects. Change the crew through the channel it came by,
  or undeploy it first. A Flux-managed crew changes only through git.
- **CrewForge warns that the crew came from another source or developer.** The Crew's
  recorded source or owner differs from yours. Confirm only if you mean to replace it.
- **Redeploy goes to the wrong namespace.** Choose **Change the Namespace Redeploy
  Uses...** from the status bar menu, or deploy again with **Deploy to Namespace...**.
- **The deploy finished but the crew never becomes ready.** Cancel the progress
  notification and open the crew dashboard's **Overview** for its phase and conditions. A
  new crew also needs a model provider that the scheduler can bind its Models to; see
  [Models and scheduling](../../../concepts/models-and-scheduling/).

## The chat will not send

When the send button is missing and a line above the input gives a reason, the crew
cannot take a question yet:

- **The crew is not ready: phase X.** Wait for the crew, or open its dashboard to see
  which agent is not ready.
- **Can't reach the crew's discussion gateway.** The crew's `<crew>-discussion` Service
  has no ready address. Check the crew's pods. CrewForge reads the crew again every 15
  seconds while the chat is visible and after each turn.
- A reason that names the cluster is a connection problem; see above.

If a turn ends with a red card or a notice under the answer, an agent failed, could not
run, or had not finished. Under the answer, **N agents took part** shows each agent's last
word. When every GPU is busy, an agent waits for one with room for its model; see
[Models and scheduling](../../../concepts/models-and-scheduling/#when-every-gpu-is-busy).

---
title: "Develop a crew in VS Code"
weight: 20
description: "The inner loop, step by step: create, understand, edit, lint, deploy, ask, debug, redeploy, and retest a crew from the editor."
aliases:
  - /docs/user-guides/develop-crews-in-vscode/
---

This guide walks the whole loop on one small example: a `helpdesk` crew scaffolded from
the starter crew, a read-only guide to its own Kubernetes namespace. You create it, change
it, deploy it to a namespace, ask it something, and redeploy after an edit. Everything happens in
the editor, without GitOps: CrewForge deploys with Helm straight to a namespace, and
never commits or pushes. Flux rollouts stay the outer loop.

You need CrewForge connected to a cluster that runs the Kubemoot operator, with `helm`
and `kmctl` 0.14.0 or later on your PATH. See [Install and connect](../install-and-connect/).

## 1. Create the crew

Right-click a folder in the Explorer and choose **New Kubemoot Crew Here**. The entry
appears only on folders that are not already inside a crew source. You can also click the
**+** on the Crew Sources view and pick a folder; the folder of your active file comes
first.

![The Explorer's context menu on a folder named notes, ending with the entry New Kubemoot Crew Here.](../explorer-new-crew.png)

CrewForge asks for three things:

1. **A name**, for example `helpdesk`.
2. **How many specialists** to start with, 1 to 5. The scaffold adds a coordinator and that
   many specialists, so `2` gives three agents. Each size is a working crew; it adds the
   next specialist in this order:

   | Size | Adds |
   |---|---|
   | 1 | `workloads`: Pods, Deployments, ReplicaSets, StatefulSets, Jobs |
   | 2 | `events`: Warning events, restarts, recent failures |
   | 3 | `networking`: Services, endpoints, routes, NetworkPolicies |
   | 4 | `config`: ConfigMaps, ServiceAccounts, Secret references |
   | 5 | `reviewer`: checks the answer against the gathered data |
3. **A model family**: `qwen`, `gemma`, `llama`, or `mistral`.

CrewForge then runs `kmctl create helpdesk --chart` and writes the crew as a Helm chart
in a folder named `helpdesk`. kmctl asks the cluster which model providers exist and
generates Models for them.

What you see: the new crew is selected in **Crew Sources**, its `README.md` opens with
`templates/crew.yaml` beside it, and a notification offers **Deploy to Namespace...**.
The chart holds:

```text
helpdesk/
  Chart.yaml
  values.yaml
  README.md
  templates/
    crew.yaml            the Crew and its scheduling policy
    agents.yaml          the coordinator and the specialists
    promptmodules.yaml   what each agent is told
    models.yaml          the Models the scheduler can bind agents to
    tools.yaml           the read-only Kubernetes MCP server and its gateway
    rbac.yaml            the Role the tool server runs with
  fitness/
    fitness.yaml         a starter fitness suite
```

The crew works as scaffolded. The tool server is read-only and its `Role` allows only
`get`, `list`, and `watch` in the crew's namespace, with no Secret access. The fitness
suite has 3 scenarios at size 1 and up to 7 at size 5, and they pass on a fresh install.
The [starter crew](../../../user-guides/starter-crew/) guide describes it in full.

The fitness suite sits outside `templates/` on purpose, so installing the chart does not
start a run.

## 2. Understand what it declares

Expand `helpdesk` in **Crew Sources**. CrewForge renders the chart and lists what it
declares, group by group:

- the **Crew**,
- its **Agents**, each with its role and capabilities,
- the **Prompts** (PromptModules) the agents compose, in order, marked ADL or prose,
- **Skills**,
- the **Models** the scheduler can bind the agents to, and the ModelProvider they run on,
  marked *shared, installed elsewhere* because the cluster provides it,
- **RAG Sources**, **MCP Servers**, and the **Tools** the agents enable,
- **Policies**: the scheduling policy and the archetype it runs,
- **Notifications**,
- **Fitness Scenarios**, from the `fitness/` folder,
- then its deployments. A new crew shows **not deployed**.

A group with nothing in it says *none*. Hover a Model for its model name, capability tier,
and context length, or a policy for what it governs.

Click any of them to open its file at that object. The view follows the file system:
adding, renaming, or deleting a file updates it without a refresh. When the chart does
not render, the error is an item in the tree, and clicking it opens the file and line
when the error names one.

To go the other way, right-click any file or folder of a crew in the Explorer and choose
**View in CrewForge**. It selects the matching item in Crew Sources and opens the crew's
dashboard.

![The Explorer's context menu on templates/crew.yaml, ending with the entry View in CrewForge.](../explorer-view-in-crewforge.png)

## 3. Edit it

Open `templates/crew.yaml` and give the crew a real description. Then open
`templates/promptmodules.yaml` and change one rule in a specialist's PromptModule, or in
the coordinator's `synthesis-prompt`, which shapes the final answer. For example, add
`ALWAYS end with a one-line summary that starts "In short:"` to `synthesis-prompt`. Deploy
it (step 5), ask the crew `List the pods in this namespace`, and the answer ends with that
line. To point the crew at a domain of your own, rewrite each specialist's resume in
`templates/agents.yaml` and its tools in `templates/tools.yaml`.

To add a part, use **Add <Kind>...** on its group in Crew Sources, for example **Add
Agent...** on Agents. CrewForge asks for the agent's name, role, capabilities,
PromptModules, and tools, writes `templates/agent-<name>.yaml` in the shape of the
chart's other templates, opens it, shows it in the tree, and lints the chart.
**Remove from Source...** on an object takes it out again, after a confirmation.

Whenever a file of the crew is open, the status bar names the crew and where it stands:

- **not deployed**,
- **deployed in crew-helpdesk, in sync**, or
- **deployed in crew-helpdesk, changed**.

Click it for the next steps in that state. Above each object in a crew manifest, a code
lens shows the same drift check.

## 4. Lint it

Choose **Lint** from the crew's menu in Crew Sources or from the status bar menu. Lint
runs `helm lint`, renders the chart, and checks every Kubemoot object against the schemas
your cluster serves. Findings land in the Problems panel, on the file and line they
concern.

![VS Code with promptmodules.yaml open at a line underlined in red. The Problems panel lists "PromptModule/helpdesk-tooler-2-system: spec has no field priority; the API server would drop it", and an information note from helm lint.](../lint-problems.png)

A field the CRD does not define is the most common finding. Saving a file of the crew
lints it again once your saves settle, so the Problems panel keeps up as you type. A
clean chart reports **Lint: helpdesk has no problems.**

## 5. Deploy it

Choose **Deploy to Namespace...** (the rocket on a source). CrewForge asks for a
namespace on the current context. It offers the last one you picked for this source,
and `crew-helpdesk` the first time. Then it runs:

```bash
helm upgrade --install helpdesk <chart folder> --namespace crew-helpdesk --create-namespace
```

A bundle of plain manifests deploys with `kubectl apply --server-side` instead.

What you see: a progress notification that follows the crew until the operator has seen
the deploy and the Crew and all its agents report ready. Cancel the notification to stop
following; the deploy itself is already done. Then CrewForge selects the crew in
**Deployed Crews**, and the source's line reads **deployed in crew-helpdesk, in sync**. A
crew or agent that fails says so.

Click the crew for its dashboard.

![The crew dashboard's Overview tab: the helpdesk crew is Ready; below its buttons are the source path and chart version, the deployment namespace, channel, and Helm release, and a table of three ready agents with their roles and capabilities.](../crew-overview.png)

The **Overview** shows the source, where it is deployed, each agent and whether it is
ready, the crew's phase, and your conversations with it. CrewForge remembers the
namespace for **Redeploy**. A crew can also go to more namespaces; each deployment shows
under its source.

## 6. Ask it something

Choose **Ask** on the deployed crew, on the source, in the dashboard, or in the status
bar menu. A chat opens beside the editor. Type a question and press Enter:

> A user cannot connect to the VPN from home. What should I check first?

The send button shows once there is text and the crew can take a question. When the crew
is not ready, in an error state, or out of reach, the reason shows above the input and
sending waits.

While the crew works, each agent has a card: starting up, queued, analyzing (with the GPU
it landed on), then what it found in plain words ("agrees", "has a concern", "objects",
"failed") or "stood aside".

![The chat while a turn runs. Two agents have reported, one agreeing and one with a concern, and a line below says the coordinator is writing the answer.](../chat-running.png)

Then the answer follows, with its time and how long the crew took.

![The finished chat. The question is a blue bubble on the right; the crew's answer is a numbered list of three checks, with "2 agents took part" below it and the time and duration, 5 s, beside two buttons that appear on hover.](../chat-answer.png)

Ask again in the same panel and the crew keeps the conversation's context. See
[Views and dashboards](../views-and-dashboards/#the-chat) for the buttons on each message.

## 7. Debug a turn

Under each answer, **N agents took part** lists each agent's last word in the turn. When
the crew's source is open in the workspace, an agent's name links to where it is defined:
its Agent, then the PromptModules it composes. That takes you from a surprising answer to
the prompt that shaped it.

A turn that goes wrong keeps what went wrong under the answer: an agent that failed, could
not run, or had not finished, an error from the crew's discussion gateway, a timeout, or
a stop. With `crewforge.dashboardUrl` set, **Open this turn in the Kubemoot dashboard**
opens the dashboard's Discussions page for the full thread.

For the objects as the cluster holds them, open the crew dashboard's **Live** tab, or
choose **Show YAML** or **Show Bundle YAML** on the crew.

## 8. Change it and redeploy

Edit a file, for example the specialist's PromptModule, and save. The status bar and the
source's line now read **deployed in crew-helpdesk, changed**. The crew dashboard's
**Diff** tab shows exactly what differs from what is running.

![The crew dashboard's Diff tab: "1 of 15 objects differ; 14 in sync". The Crew helpdesk is marked changed in source, and the diff shows the old description line in red and the new one in green.](../crew-diff.png)

Choose **Redeploy** (the sync icon on a changed source, or the status bar). It upgrades
the release in the namespace you last deployed to and waits for the agents again.

## 9. Retest

When the redeploy finishes, its notification offers two buttons:

- **Re-ask last question** asks the same question again in the open chat, or in the
  newest saved conversation with the crew.
- **Rerun fitness** runs the fitness definition you ran last, without asking.

Compare the new answer with the old one, or the new fitness results with the previous
run. See [Fitness from the editor](../fitness/).

## 10. Finish

- **Undeploy** removes the crew from a namespace. For a Helm crew it runs `helm uninstall`
  and the operator's finalizers clean up the rest. The namespace stays unless the crew and
  namespace opt in to its deletion; see
  [Crew](../../../reference/crew/).
- **Delete Source...** moves the crew's folder to your trash, after a confirmation that
  names it. If the crew is deployed, it offers to undeploy first.
- To roll the crew out through GitOps, commit it to the repository your cluster watches.
  **Deploy with a Channel...** and **Follow Flux Rollout** cover that outer loop. See
  [Views and dashboards](../views-and-dashboards/).

## Next

- [Views and dashboards](../views-and-dashboards/): every view, tab, and action, and what
  each changes.
- [Fitness from the editor](../fitness/): measure whether the crew does its job.
- [Build a Crew](../../../user-guides/build-a-crew/): the same workflow at the
  resource level, from a terminal.

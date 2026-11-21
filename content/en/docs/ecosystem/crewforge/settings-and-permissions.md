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
| `crewforge.namespaces` | `[]` | Show crews only in these namespaces. Empty reads the namespace of the kubeconfig context, and falls back to every namespace when the context sets none or that namespace holds no crews. A list you set wins, and `*` shows every namespace you can read. |
| `crewforge.streamTimeoutSeconds` | `600` | Longest a single turn may stream before CrewForge gives up on it. The minimum is 60. |
| `crewforge.operatorNamespace` | `kubemoot` | Namespace of the Kubemoot operator, whose report service `kubemoot-operator-report` serves a crew's memory export to the memory view. |
| `crewforge.tokenServiceAccount` | empty | `NAMESPACE/NAME` of a ServiceAccount to mint a ten-minute token for when you ask a crew or open its memory, for a kubeconfig that signs in with a client certificate and so has no bearer token. You need `create` on `serviceaccounts/token` for it; the crew then sees that ServiceAccount as the caller. Empty sends the kubeconfig's own token. Only a crew that sets `spec.discussion.access` uses it. |
| `crewforge.tokenAudiences` | `[]` | Audiences the minted token is bound to, for a crew that lists `tokenAudiences` in `spec.discussion.access`. Used only with `crewforge.tokenServiceAccount`. |
| `crewforge.dashboardService` | empty | The Kubemoot dashboard's Service as `namespace/name:port`. CrewForge reads it through the Kubernetes service proxy, read-only, for thread counts, discussion failures, fitness scores, and archived iterations. Empty finds the Service labelled `app.kubernetes.io/part-of=kubemoot` whose `app.kubernetes.io/name` is `dashboard` (the operator chart's subchart) or `kubemoot-dashboard` (a standalone install). Add an optional base path, `namespace/name:port/base`, when the dashboard serves under a path such as `/dashboard`. |
| `crewforge.yamlFormat` | `yaml` | How Show Live YAML, Show Source YAML, and Compare with Live write an object. `yaml` is block YAML. `kyaml` is KYAML, the strict YAML subset `kubectl get -o kyaml` prints: every string quoted, maps in `{ }`, lists in `[ ]`. KYAML is still valid YAML. |
| `crewforge.dashboardUrl` | empty | The address of the [Kubemoot dashboard](../../../operating/dashboard/) for this cluster. **Powered by Kubemoot** in a chat opens it, and **Open this turn in the Kubemoot dashboard** appears under an answer only when this is set. Behind a `kubectl port-forward`, use the local address. Empty makes **Powered by Kubemoot** open this setting. |

The Kubemoot dashboard is optional. Without it, the parts of the crew and fitness
dashboards that come from it (discussion counts, agent failures, judge scores, and the
results workbook download) say they are not available.

## What your account needs

CrewForge acts as you. Each feature needs only the permissions below, and a part that
cannot be read says so instead of failing the whole view.

**Browse crews and chat**

- `list` on `crews.kubemoot.ai`, in the context's namespace, in each namespace of
  `crewforge.namespaces`, or cluster-wide when the setting is `*` or the fallback to every
  namespace applies.
- `get` on `services`, `list` on `pods`, and `create` on `pods/portforward` in the crew's
  namespace, to ask and to stream the answer. CrewForge reaches the crew's discussion
  gateway through a port-forward and sends your kubeconfig's bearer token with each request.
- `get` on `endpoints` in that namespace, to tell whether the crew's discussion gateway
  is running.

**Explore a deployed crew**

- `get` and `list` on `agents`, `promptmodules`, `skills`, `mcpservers`, and
  `crewschedulingpolicies`. A kind you may not read shows as a warning under the crew.
- `delete` on those kinds and on `crews`, to undeploy a crew whose source is not open.

**Stop, pause, resume and delete a conversation**

- The same `get` on `services`, `list` on `pods`, and `create` on `pods/portforward` as
  chat. The owner of a conversation needs nothing more.
- For another caller's conversation, `update` (stop, pause, resume) or `delete` on
  `crews/conversations` in the crew's namespace, which the ClusterRole
  `kubemoot-conversation-controller` grants. Nobody is bound to it by default.

**Crew memory**

- `get` on the Crew, which the operator's report service checks for your token.
- `get` on `services`, `list` on `pods`, and `create` on `pods/portforward` in the
  operator's namespace (`crewforge.operatorNamespace`), to reach the report service.

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

## Who the crew sees

CrewForge sends your kubeconfig's bearer token to the crew. A crew that sets
`spec.discussion.access` uses it to know who is asking and keeps each conversation for the
caller that started it; a crew that sets nothing stays open and ignores it. CrewForge
never shows or logs the token. See [Who is asking](../../../concepts/who-is-asking/).

A kubeconfig that signs in with a client certificate has no bearer token. When the crew
requires one, set `crewforge.tokenServiceAccount` to a ServiceAccount you may mint tokens
for, and `crewforge.tokenAudiences` when the crew lists `tokenAudiences`. The Kubernetes
audit log records who minted the token. A refusal says which part is missing: the crew
requires a token (401), your identity may not use the crew (403), or the conversation is
not yours (404).

## Acting on conversations

The owner of a conversation stops, pauses, resumes or deletes it without a reason. An
operator acting on someone else's conversation needs the
`kubemoot-conversation-controller` role, and CrewForge asks for a reason (1 to 200
characters) when the gateway says it is needed. The reason goes to the crew as the
`Kubemoot-Access-Reason` header, and the crew records the use in its audit log. A refusal
says which part is missing: no token (401), an identity that may not use the crew (403),
a conversation that is not yours or not there (404), nothing running or still running
(409), or a store that failed (500). The endpoints and the owner rule are in
[Conversations, turns, and threads](../../../concepts/conversations-turns-and-threads/#stopping-pausing-resuming-and-deleting-a-conversation).

## Live updates

The chat's live updates need no permission beyond chat's. CrewForge reads the crew's
conversation event stream through the same port-forward and token; the crew sends a
caller events only for the conversations that caller owns, and no client reads NATS.

## The boundary CrewForge keeps

Deleting a conversation is a request to the crew's discussion gateway, not a write by
CrewForge: the crew erases its own stores.

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

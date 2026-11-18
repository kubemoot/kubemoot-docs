# kmctl in use: check the cluster, scaffold a crew, install it, ask it a question.
# Needs a cluster with the Kubemoot operator and a model catalog entry that can call
# tools, plus kmctl and helm on PATH. Render with `make recordings`.
Output static/recordings/kmctl.gif
Output static/recordings/kmctl.webm
Source tapes/settings.tape

Hide
Type "export PS1='$ ' && cd $(mktemp -d) && clear"
Enter
Show

Type "kmctl status"
Enter
Wait+Screen@30s /Kubemoot/
Sleep 2s

Type "kmctl model list"
Enter
Sleep 3s

Type "kmctl create hello --chart --members 1 --no-input"
Enter
Sleep 3s

Type "cd hello && helm upgrade --install hello . -n crew-hello --create-namespace"
Enter
Wait+Screen@2m /STATUS: deployed/
Sleep 2s

Type "kmctl crew get hello -n crew-hello"
Enter
Wait+Screen@5m /Ready/
Sleep 2s

Type 'kmctl conversation ask hello "List the pods in this namespace and their status." -n crew-hello'
Enter
Wait+Screen@10m /\$ $/
Sleep 6s

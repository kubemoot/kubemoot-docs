# The quickstart: an empty kind cluster to a crew answering a question.
# Run from a checkout of the kubemoot repository at the latest release; the cluster
# is created here, so Docker, kind, kubectl, helm and python3 must be on PATH.
# The waits are long in real time, so the recording plays back faster than it ran.
# Render with `make recordings`.
Output static/recordings/quickstart.gif
Output static/recordings/quickstart.webm
Source tapes/settings.tape
Set PlaybackSpeed 6

Hide
Type "export PS1='READY> ' && cd ${KUBEMOOT_CHECKOUT:?set KUBEMOOT_CHECKOUT} && clear"
Enter
Show

Type "kind create cluster --name kubemoot"
Enter
Wait+Screen@5m /Have a nice day/
Sleep 1s

Type "./quickstart/quickstart.sh"
Enter
Wait+Screen@45m /READY>\s*$/
Sleep 8s

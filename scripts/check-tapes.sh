#!/usr/bin/env bash
# Checks the recording tools against tapes/tool-versions, then parses every tape with
# `vhs validate` (no cluster, nothing is run).
#   scripts/check-tapes.sh [--tools | --validate]
# --tools checks vhs, ttyd and ffmpeg only (rendering needs all three); --validate checks
# vhs and ttyd and parses the tapes (CI, which never renders); no argument does both.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../tapes/tool-versions
. "$root/tapes/tool-versions"
fail=0
bad() { echo "check-tapes: $*" >&2; fail=1; }

have="$(vhs --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
[[ "$have" == "$VHS_VERSION" ]] || bad "vhs is '${have:-missing}', tapes/tool-versions pins $VHS_VERSION"
have="$(ttyd --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
[[ "$have" == "$TTYD_VERSION" ]] || bad "ttyd is '${have:-missing}', tapes/tool-versions pins $TTYD_VERSION"
if [[ "${1:-}" != --validate ]]; then
  have="$(ffmpeg -version 2>/dev/null | grep -oE 'version [0-9]+' | head -1 | cut -d' ' -f2 || true)"
  [[ "$have" == "$FFMPEG_MAJOR" ]] || bad "ffmpeg major is '${have:-missing}', tapes/tool-versions pins $FFMPEG_MAJOR"
fi
((fail == 0)) || exit 1
[[ "${1:-}" == --tools ]] && exit 0

cd "$root"
shopt -s nullglob
for t in tapes/*.tape; do
  [[ "$t" == tapes/settings.tape ]] && continue
  echo "validate $t"
  vhs validate "$t" || fail=1
done
exit "$fail"

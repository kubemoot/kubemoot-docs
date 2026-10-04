#!/usr/bin/env bash
# Versions live only in git tags: the chart holds 0.0.0, no workflow commits or pushes
# to main, and a kubemoot docs change rebuilds the site through a dispatch event, not a
# commit. Run: scripts/release.test.sh [REPO_ROOT]   (exit 0 = all passed)
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
failures=0
check() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    echo "ok - ${name}"
  else
    echo "not ok - ${name}: want [${want}] got [${got}]" >&2
    failures=$((failures + 1))
  fi
}

chart="${root}/charts/kubemoot-docs/Chart.yaml"
check "Chart.yaml holds version 0.0.0" "0.0.0|0.0.0" \
  "$(sed -nE 's/^version: *"?([^"]*)"?$/\1/p' "$chart")|$(sed -nE 's/^appVersion: *"?([^"]*)"?$/\1/p' "$chart")"

workflows=("${root}"/.github/workflows/*.yaml)
commits="$(grep -nE 'git commit|git push[^"]*(origin main|HEAD:main)|\[skip ci\]' "${workflows[@]}" \
  | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(#|echo )' || true)"
check "no workflow commits or pushes to main" "" "$commits"
check "no workflow writes a chart file" "" \
  "$(grep -nE '(sed|yq).*(Chart|values)\.yaml' "${workflows[@]}" || true)"

release="${root}/.github/workflows/release-docs.yaml"
check "the release listens for kubemoot docs changes" "1" \
  "$(grep -cE '^[[:space:]]+types: \[kubemoot-docs-changed\]$' "$release")"
check "a dispatch forces a new candidate" "1" \
  "$(grep -cF "force: \${{ inputs.force_release || github.event_name == 'repository_dispatch' }}" "$release")"
check "the image records the kubemoot docs commit" "1" \
  "$(grep -cF 'org.kubemoot.docs.kubemoot-revision=' "${root}/.github/workflows/ci-docs.yaml")"
# shellcheck disable=SC2016 # the workflow's literal text, not an expansion
check "the candidate tag records the kubemoot docs commit" "1" \
  "$(grep -cF 'Built with kubemoot docs @ ${KUBEMOOT_SHA}' "$release")"
check "the image records the docs commit" "1" \
  "$(grep -cF 'org.opencontainers.image.revision=' "${root}/.github/workflows/ci-docs.yaml")"
check "promotion copies the image of the candidate it promotes" "1" \
  "$(grep -cF "rc=\"\$(sed -n 's/^rc_tag=docs-v//p' <<<\"\${plan}\")\"" "${root}/.github/workflows/promote-release.yaml")"
check "the release never copies another build's :latest" "0" \
  "$(grep -c ':latest" "' "$release" || true)"
check "no republish marker file" "absent" "$([ -e "${root}/component-sync.md" ] && echo present || echo absent)"

if [ "$failures" -ne 0 ]; then echo "${failures} test(s) failed" >&2; exit 1; fi
echo "all release tests passed"

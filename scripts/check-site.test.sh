#!/usr/bin/env bash
# Tests scripts/check-scripts.sh against fixture HTML.
#   scripts/check-site.test.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0

# expect NAME WANT HTML: write HTML as the only page and compare the exit status.
expect() {
  local name="$1" want="$2" html="$3" dir="$work/$1"
  mkdir -p "$dir"
  printf '%s\n' "$html" >"$dir/index.html"
  local got=0
  "$here/check-scripts.sh" "$dir" >"$dir.out" 2>&1 || got=$?
  if ((got != want)); then
    echo "FAIL $name: exit $got, want $want"
    sed 's/^/  /' "$dir.out"
    failures=$((failures + 1))
  else
    echo "ok   $name"
  fi
}

jq='<script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha512-abc" crossorigin="anonymous"></script>'
lunr='<script defer src="https://unpkg.com/lunr@2.3.9/lunr.min.js" integrity="sha384-abc" crossorigin="anonymous"></script>'

expect pinned-pass 0 "$jq $lunr <script src=/js/main.js></script>"
expect pinned-minified-pass 0 '<script src=https://unpkg.com/lunr@2.3.9/lunr.min.js integrity=sha384-abc crossorigin=anonymous></script>'
expect first-party-only-pass 0 '<script src="/js/main.js"></script> <script src="https://kubemoot.org/js/x.js"></script>'
expect inline-script-pass 0 '<script>console.log("hi")</script>'
expect unpinned-latest 1 '<script src="https://cdn.jsdelivr.net/npm/mermaid@latest/dist/mermaid.min.js" integrity="sha384-abc"></script>'
expect missing-integrity 1 '<script src="https://unpkg.com/lunr@2.3.9/lunr.min.js"></script>'
expect single-quoted-unpinned 1 "<script src='https://cdn.jsdelivr.net/npm/mermaid@latest/x.js'></script>"
expect protocol-relative-unpinned 1 '<script src="//cdn.example.com/lib.js" integrity="sha384-abc"></script>'
expect inline-module-import 1 '<script type="module">import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@latest/dist/mermaid.esm.min.mjs"; mermaid.initialize({});</script>'
expect dynamic-import 1 "<script>import('https://cdn.example.com/x.mjs')</script>"
expect zero-script-tags 1 '<html><body>no scripts</body></html>'

mkdir -p "$work/empty"
if "$here/check-scripts.sh" "$work/empty" >"$work/empty.out" 2>&1; then
  echo "FAIL empty-directory: passed with no HTML"
  failures=$((failures + 1))
else
  echo "ok   empty-directory"
fi

((failures == 0)) || exit 1
echo "check-site.test: all passed"

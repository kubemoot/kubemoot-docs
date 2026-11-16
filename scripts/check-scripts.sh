#!/usr/bin/env bash
# Checks that every third-party script a built site loads is pinned: an exact version in
# the URL (name@X.Y.Z or name-X.Y.Z.js) and a subresource-integrity hash. Docsy loads
# jQuery and lunr this way. An unpinned URL (@latest, a bare package name) or a script
# without integrity fails, and so does an inline module import of a CDN.
#   scripts/check-scripts.sh [PUBLIC_DIR]
#
# Limit: the check reads the HTML. A script that another script builds at run time
# (document.createElement, a dynamic URL) or an @import in CSS is not seen.
set -euo pipefail

public="${1:-public}"
fail=0

bad() {
  echo "check-scripts: $*" >&2
  fail=1
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

find "$public" -name '*.html' -print0 | xargs -0 -r cat | tr '\n' ' ' >"$work/all.html"
grep -oE '<script[^>]*>' "$work/all.html" | sort -u >"$work/tags" || true

total="$(wc -l <"$work/tags")"
if ((total == 0)); then
  bad "found no script tags in $public; the site always loads jquery and lunr, so the build or this check is broken"
fi

external=0
while IFS= read -r tag; do
  src="$(printf '%s' "$tag" | sed -nE "s/.*[[:space:]]src=[\"']?([^\"' >]+).*/\\1/p")"
  [[ "$src" =~ ^(https?:)?// ]] || continue
  [[ "$src" =~ ^https://kubemoot\.org/ ]] && continue
  external=$((external + 1))
  [[ "$tag" =~ integrity=[\"\']?sha(256|384|512)- ]] || bad "script without an integrity hash: $src"
  [[ "$src" =~ @[0-9]+\.[0-9]+\.[0-9]+ || "$src" =~ -[0-9]+\.[0-9]+\.[0-9]+[^/]*$ ]] || bad "script without an exact version: $src"
done <"$work/tags"

if grep -qE "(import[[:space:]]*\\(|import[^;\"']*from|importScripts\\()[[:space:]]*[\"'](https?:)?//" "$work/all.html"; then
  bad "an inline script imports a module from a CDN"
fi

((fail == 0)) || exit 1
echo "check-scripts: ok ($total script tags, $external external, all pinned)"

#!/usr/bin/env bash
# Tests for check-nginx.sh against a small fixture site: the repository's nginx.conf
# passes, a configuration nginx refuses or whose probe never answers exits 2, a
# configuration that breaks what the cluster relies on exits 1, and missing inputs
# exit 2. Needs nginx and curl, like check-nginx.sh (NGINX_BIN picks the binary).
# Usage: scripts/check-nginx.test.sh   (exit 0 = all passed)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
conf="${here}/../nginx.conf"
failures=0
check() { # check NAME WANT GOT
  if [ "$2" = "$3" ]; then
    echo "ok - $1"
  else
    echo "not ok - $1: want [$2] got [$3]" >&2
    failures=$((failures + 1))
  fi
}
# status CMD...: the exit status of the command, its output dropped.
status() { local rc=0; "$@" >/dev/null 2>&1 || rc=$?; echo "$rc"; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

site="${work}/public"
mkdir -p "${site}/docs" "${site}/css"
printf '<html>home</html>\n' > "${site}/index.html"
printf '<html>docs</html>\n' > "${site}/docs/index.html"
printf '<html>not found</html>\n' > "${site}/404.html"
printf 'body{}\n' > "${site}/css/main.1234.css"

check "the repository's nginx.conf passes" 0 "$(status "${here}/check-nginx.sh" "$site" "$conf")"

sed 's/listen 8080;/listen 8080 no-such-flag;/' "$conf" > "${work}/refused.conf"
check "a configuration nginx refuses exits 2" 2 "$(status "${here}/check-nginx.sh" "$site" "${work}/refused.conf")"

sed 's#location ~ /\\.(?!well-known) {#location ~ /\\.never-matches {#' "$conf" > "${work}/dotfiles.conf"
check "the dotfile rule was loosened" 1 "$(status cmp -s "$conf" "${work}/dotfiles.conf")"
check "serving dotfiles exits 1" 1 "$(status "${here}/check-nginx.sh" "$site" "${work}/dotfiles.conf")"

sed 's#return 200 "ok\\n";#return 200 "up\\n";#' "$conf" > "${work}/probe.conf"
check "the probe answer was changed" 1 "$(status cmp -s "$conf" "${work}/probe.conf")"
check "a probe that does not answer ok exits 2" 2 "$(status "${here}/check-nginx.sh" "$site" "${work}/probe.conf")"

sed 's#add_header Cache-Control "no-cache";#add_header Cache-Control "max-age=60";#' "$conf" > "${work}/cached.conf"
check "HTML cached by the browser exits 1" 1 "$(status "${here}/check-nginx.sh" "$site" "${work}/cached.conf")"

check "no arguments exits 2" 2 "$(status "${here}/check-nginx.sh")"
check "a directory without a site exits 2" 2 "$(status "${here}/check-nginx.sh" "${work}" "$conf")"
check "a missing nginx.conf exits 2" 2 "$(status "${here}/check-nginx.sh" "$site" "${work}/none.conf")"

if [ "$failures" -ne 0 ]; then echo "${failures} test(s) failed" >&2; exit 1; fi
echo "all check-nginx tests passed"

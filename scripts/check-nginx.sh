#!/usr/bin/env bash
# Serves a built site with the image's nginx.conf and checks what the cluster relies on:
# the probe endpoint, the /docs redirect, the docs landing, the cache headers, the 404
# page and the hidden dotfiles. Runs nginx the way the Paketo nginx buildpack does
# (`-p <app dir> -c nginx.conf -g "pid ...;"`, the site in public/), from a copy of the
# site in a temporary, read-only app directory. CI runs it with the runner's
# distribution nginx, not the Paketo nginx the image ships; both read the same
# configuration.
#
# Usage: scripts/check-nginx.sh PUBLIC_DIR [NGINX_CONF]   (exit 0 = all passed)
# Env:
#   NGINX_BIN  the nginx binary (default: nginx, run with `sudo -n` when not root, because
#              a distribution nginx creates its compiled-in temp paths under /var/lib)
#   PORT    the port nginx.conf listens on (8080)
set -euo pipefail

die() { echo "check-nginx: $*" >&2; exit 2; }

failures=0
check() { # check NAME WANT GOT
  if [ "$2" = "$3" ]; then
    echo "ok - $1"
  else
    echo "not ok - $1: want [$2] got [$3]" >&2
    failures=$((failures + 1))
  fi
}

# nginx_cmd: the command that starts nginx, one word per line.
nginx_cmd() {
  if [ -n "${NGINX_BIN:-}" ]; then
    echo "$NGINX_BIN"
  elif [ "$(id -u)" -eq 0 ]; then
    echo nginx
  else
    printf '%s\n' sudo -n nginx
  fi
}

# header NAME FILE: the values of every NAME header in FILE, joined with ", ".
header() {
  awk -F': ' -v name="$1" '
    tolower($1) == name { sub(/\r$/, "", $2); out = out (out == "" ? "" : ", ") $2 }
    END { print out }
  ' "$2"
}

# fetch PATH: the status, the Location and Cache-Control headers and the start of the
# body of a GET, one per line.
fetch() {
  local headers body status
  headers="$(mktemp)"; body="$(mktemp)"
  status="$(curl -s -o "$body" -D "$headers" -w '%{http_code}' "http://127.0.0.1:${PORT:-8080}$1")"
  echo "$status"
  header location "$headers"
  header cache-control "$headers"
  head -c 200 "$body" | tr '\n' ' '
  echo
  rm -f "$headers" "$body"
}

# wait_until_serving PID: true once nginx answers the probe; false when nginx exits first.
wait_until_serving() {
  local pid="$1" _
  for _ in $(seq 1 50); do
    [ "$(curl -fs "http://127.0.0.1:${PORT:-8080}/docs/healthz" 2>/dev/null)" = "ok" ] && return 0
    kill -0 "$pid" 2>/dev/null || return 1
    sleep 0.2
  done
  return 1
}

main() {
  [ $# -ge 1 ] && [ $# -le 2 ] || die "usage: check-nginx.sh PUBLIC_DIR [NGINX_CONF]"
  local public="$1"
  local conf="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/nginx.conf}"
  [ -f "${public}/index.html" ] || die "no built site in ${public}"
  [ -f "$conf" ] || die "nginx.conf not found: ${conf}"

  # The app directory is read-only, as in the image; only the pid file and nginx's
  # temp paths (under /tmp) are written.
  local app run
  app="$(mktemp -d)"; run="$(mktemp -d)"
  # shellcheck disable=SC2064 # expand now: the trap runs after main returns
  trap "chmod -R u+w '${app}'; rm -rf '${app}' '${run}'" EXIT
  cp "$conf" "${app}/nginx.conf"
  cp -R "$public" "${app}/public"
  printf 'hidden\n' > "${app}/public/.hidden"
  chmod -R a+rX,a-w "$app"
  chmod a+rwx "$run"

  local cmd=() args
  mapfile -t cmd < <(nginx_cmd)
  args=(-p "${app}/" -c "${app}/nginx.conf" -g "pid ${run}/nginx.pid;")
  "${cmd[@]}" -t "${args[@]}" || die "nginx -t refused ${conf}"
  "${cmd[@]}" "${args[@]}" &
  local pid=$!
  # shellcheck disable=SC2064 # expand now: the trap runs after main returns
  trap "${cmd[*]} -p '${app}/' -c '${app}/nginx.conf' -g 'pid ${run}/nginx.pid;' -s stop 2>/dev/null; wait ${pid} 2>/dev/null; chmod -R u+w '${app}'; rm -rf '${app}' '${run}'" EXIT
  wait_until_serving "$pid" || die "nginx did not start serving"

  local r asset
  mapfile -t r < <(fetch /docs/healthz)
  check "the probe answers 200" "200" "${r[0]}"
  check "the probe says ok" "ok " "${r[3]}"
  mapfile -t r < <(fetch /docs)
  check "/docs redirects" "301" "${r[0]}"
  check "/docs redirects to /docs/ on the same host" "/docs/" "${r[1]}"
  mapfile -t r < <(fetch /docs/)
  check "the docs landing answers 200" "200" "${r[0]}"
  check "HTML is revalidated" "no-cache" "${r[2]}"
  asset="$(cd "$public" && find . -name '*.css' -print -quit | sed 's#^\.##')"
  [ -n "$asset" ] || die "no stylesheet in ${public}"
  mapfile -t r < <(fetch "$asset")
  check "a stylesheet answers 200" "200" "${r[0]}"
  check "a stylesheet is cached for good" "max-age=2592000, public, immutable" "${r[2]}"
  mapfile -t r < <(fetch /no-such-page/)
  check "a missing page answers 404" "404" "${r[0]}"
  check "a missing page shows the site's 404 page" "$(head -c 200 "${public}/404.html" | tr '\n' ' ')" "${r[3]}"
  mapfile -t r < <(fetch /.hidden)
  check "a dotfile is not served" "404" "${r[0]}"

  if [ "$failures" -ne 0 ]; then echo "${failures} check(s) failed" >&2; exit 1; fi
  echo "all nginx checks passed"
}

main "$@"

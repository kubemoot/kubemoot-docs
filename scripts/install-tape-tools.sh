#!/usr/bin/env bash
# Installs the pinned vhs and ttyd (tapes/tool-versions) into BIN_DIR from their GitHub
# release tags, and fails unless each download matches its pinned sha256. linux x86_64.
# ffmpeg is not installed here; use the system package manager.
#   scripts/install-tape-tools.sh [BIN_DIR]     (default ./.tools/bin)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../tapes/tool-versions
. "$root/tapes/tool-versions"
bin="${1:-$root/.tools/bin}"
mkdir -p "$bin"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

verify() { # file sha256
  echo "$2  $1" | sha256sum --check --status || {
    echo "install-tape-tools: checksum mismatch for $(basename "$1")" >&2
    exit 1
  }
}

vhs_tar="vhs_${VHS_VERSION}_Linux_x86_64.tar.gz"
curl -fsSL -o "$work/$vhs_tar" "https://github.com/charmbracelet/vhs/releases/download/v${VHS_VERSION}/${vhs_tar}"
verify "$work/$vhs_tar" "$VHS_SHA256"
tar -xzf "$work/$vhs_tar" -C "$work" "vhs_${VHS_VERSION}_Linux_x86_64/vhs"
install -m 0755 "$work/vhs_${VHS_VERSION}_Linux_x86_64/vhs" "$bin/vhs"

curl -fsSL -o "$work/ttyd" "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64"
verify "$work/ttyd" "$TTYD_SHA256"
install -m 0755 "$work/ttyd" "$bin/ttyd"

echo "installed vhs ${VHS_VERSION} and ttyd ${TTYD_VERSION} in ${bin}"

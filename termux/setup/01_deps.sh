#!/usr/bin/env bash
# 01_deps.sh — Install minimal Termux dependencies
# PhantomSec OS Termux Edition v2.8.0

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 1 — Dependencies"

# ── Update package repos ───────────────────────────────────────────────────
log "Updating package repos..."
pkg update -y -o Dpkg::Options::="--force-confdef" 2>/dev/null || pkg update -y || true

# ── Required: build tools ──────────────────────────────────────────────────
DEPS="clang make git wget curl"
MISSING=""
for dep in $DEPS; do
  command -v "$dep" &>/dev/null || MISSING="$MISSING $dep"
done

if [ -n "$MISSING" ]; then
  log "Installing:$MISSING"
  pkg install -y $MISSING 2>&1 | tail -1
else
  ok "All dependencies already installed."
fi

# ── Verify ──────────────────────────────────────────────────────────────────
require_cmd clang clang
require_cmd make make
require_cmd git git

ok "Dependencies ready."

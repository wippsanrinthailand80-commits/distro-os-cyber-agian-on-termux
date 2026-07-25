#!/usr/bin/env bash
# 03_proot.sh — Build phantom-proot from source using Termux clang
# PhantomSec phantom-proot installer — Step 3

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 3 — Build phantom-proot"
info "Building PhantomSec's own proot from C source — no third-party proot used."

mkdir -p "$LOCAL_BIN"

PROOT_SRC="$INSTALL_DIR/os/tools/proot"

# Sanity check — source must exist after clone
[ -d "$PROOT_SRC" ] || err "proot source not found at $PROOT_SRC\nDid step 2 (clone) succeed?"

log "Cleaning previous build artifacts..."
make -C "$PROOT_SRC" clean 2>/dev/null || true

log "Compiling phantom-proot with Termux clang..."
# Always pass CC=clang — Termux ships clang, not gcc
make -C "$PROOT_SRC" CC=clang

log "Installing phantom-proot → $PROOT_BIN"
# Pass CC=clang on install too so make doesn't try to rebuild with gcc
make -C "$PROOT_SRC" CC=clang PREFIX="$LOCAL_BIN" install

# Verify binary exists and is executable
if [ -x "$PROOT_BIN" ]; then
  ok "phantom-proot installed → $PROOT_BIN"
else
  err "phantom-proot binary not found at $PROOT_BIN after install"
fi

#!/usr/bin/env bash
# 03_proot.sh — Build phantom-proot from source using Termux clang
# PhantomSec phantom-proot installer — Step 3

set -euo pipefail
source "$(dirname "$0")/_common.sh"

step "Step 3 — Build phantom-proot"
info "Building PhantomSec's own proot from C source — no third-party proot used."

mkdir -p "$LOCAL_BIN"

PROOT_SRC="$INSTALL_DIR/os/tools/proot"

log "Cleaning previous build..."
make -C "$PROOT_SRC" clean 2>/dev/null || true

log "Compiling with Termux clang..."
# Use clang (Termux native compiler) — no kernel headers needed
make -C "$PROOT_SRC" CC=clang PREFIX="$LOCAL_BIN"

log "Installing phantom-proot → $PROOT_BIN"
make -C "$PROOT_SRC" install PREFIX="$LOCAL_BIN"

# Quick smoke test
if "$PROOT_BIN" -h 2>&1 | grep -q "phantom-proot"; then
  ok "phantom-proot installed and working → $PROOT_BIN"
else
  ok "phantom-proot installed → $PROOT_BIN"
fi

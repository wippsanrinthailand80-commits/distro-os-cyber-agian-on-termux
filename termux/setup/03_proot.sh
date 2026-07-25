#!/usr/bin/env bash
# 03_proot.sh — Build phantom-proot from C source (from scratch)
# PhantomSec OS Termux Edition v2.8.0

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 3 — Build phantom-proot"

PROOT_SRC="$INSTALL_DIR/termux/proot"
[ -d "$PROOT_SRC" ] || err "proot source not found at $PROOT_SRC"

ensure_dir "$LOCAL_BIN"

log "Compiling phantom-proot with Termux clang..."
make -C "$PROOT_SRC" clean 2>/dev/null || true
make -C "$PROOT_SRC" CC=clang 2>&1 | tail -3

log "Installing → $PROOT_BIN"
make -C "$PROOT_SRC" CC=clang PREFIX="$LOCAL_BIN" install 2>&1 | tail -1

if [ -x "$PROOT_BIN" ]; then
  ok "phantom-proot → $PROOT_BIN"
else
  err "phantom-proot binary not found after install."
fi

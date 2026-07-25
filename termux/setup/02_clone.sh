#!/usr/bin/env bash
# 02_clone.sh — Clone or update PhantomSec repo
# PhantomSec phantom-proot installer — Step 2

set -euo pipefail
source "$(dirname "$0")/_common.sh"

step "Step 2 — PhantomSec source"

if [ -d "$INSTALL_DIR/.git" ]; then
  warn "Repo exists — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only -q
  ok "Updated → $INSTALL_DIR"
else
  log "Cloning PhantomSec OS..."
  git clone --depth=1 -q "$REPO_URL" "$INSTALL_DIR"
  ok "Cloned → $INSTALL_DIR"
fi

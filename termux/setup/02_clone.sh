#!/usr/bin/env bash
# 02_clone.sh — Clone or update PhantomSec repo
# PhantomSec phantom-proot installer — Step 2

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 2 — PhantomSec source"

if [ -d "$INSTALL_DIR/.git" ]; then
  warn "Repo exists — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only -q \
    || { warn "Fast-forward failed — resetting to origin/main..."; \
         git -C "$INSTALL_DIR" fetch -q origin && \
         git -C "$INSTALL_DIR" reset --hard origin/main -q; }
  ok "Updated → $INSTALL_DIR"
elif [ -d "$INSTALL_DIR" ]; then
  # Directory exists but is NOT a git repo (partial/failed prev install)
  warn "$INSTALL_DIR exists but is not a git repo — removing and re-cloning..."
  rm -rf "$INSTALL_DIR"
  log "Cloning PhantomSec OS..."
  git clone --depth=1 -q "$REPO_URL" "$INSTALL_DIR"
  ok "Cloned → $INSTALL_DIR"
else
  log "Cloning PhantomSec OS..."
  git clone --depth=1 -q "$REPO_URL" "$INSTALL_DIR"
  ok "Cloned → $INSTALL_DIR"
fi

#!/usr/bin/env bash
# 02_clone.sh — Fetch or update the PhantomSec repo
# PhantomSec OS Termux Edition v2.8.0

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 2 — Fetch Source"

ensure_dir "$LOCAL_BIN"

if [ -d "$INSTALL_DIR/.git" ]; then
  log "Updating existing repo at $INSTALL_DIR..."
  git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null || {
    warn "Pull failed — force resetting to origin/main..."
    git -C "$INSTALL_DIR" fetch origin main
    git -C "$INSTALL_DIR" reset --hard origin/main
  }
  ok "Repo updated."
else
  log "Cloning repo to $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>&1 | tail -1
  ok "Repo cloned."
fi

# ── Verify critical paths ──────────────────────────────────────────────────
[ -d "$INSTALL_DIR/os/tools" ] || err "Source tree incomplete — os/tools/ missing."
[ -d "$INSTALL_DIR/termux" ]   || err "Source tree incomplete — termux/ missing."

ok "Source ready at $INSTALL_DIR"

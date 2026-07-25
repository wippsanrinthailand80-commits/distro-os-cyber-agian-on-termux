#!/usr/bin/env bash
# 02_clone.sh — Clone or update PhantomSec repo
# PhantomSec phantom-proot installer — Step 2

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 2 — PhantomSec source"

_do_clone() {
  # Remove -q so git errors are visible
  log "Cloning PhantomSec OS (this may take a moment)..."
  if git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"; then
    ok "Cloned → $INSTALL_DIR"
  else
    warn "depth=1 clone failed — retrying without --depth (slower but more reliable)..."
    rm -rf "$INSTALL_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR" \
      || err "git clone failed.\nCheck: internet connection, github.com reachable, ca-certificates installed.\nTry: pkg install ca-certificates"
    ok "Cloned → $INSTALL_DIR"
  fi
}

if [ -d "$INSTALL_DIR/.git" ]; then
  warn "Repo exists — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only \
    || { warn "Fast-forward failed — resetting to origin/main..."; \
         git -C "$INSTALL_DIR" fetch origin && \
         git -C "$INSTALL_DIR" reset --hard origin/main; }
  ok "Updated → $INSTALL_DIR"
elif [ -d "$INSTALL_DIR" ]; then
  # Directory exists but is NOT a git repo (partial/failed prev install)
  warn "$INSTALL_DIR exists but is not a git repo — removing and re-cloning..."
  rm -rf "$INSTALL_DIR"
  _do_clone
else
  _do_clone
fi

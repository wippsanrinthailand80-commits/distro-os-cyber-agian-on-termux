#!/usr/bin/env bash
# 01_deps.sh — Install Termux build dependencies
# PhantomSec phantom-proot installer — Step 1

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 1 — Termux dependencies"

log "Updating Termux package lists..."
pkg update -y -q

log "Installing: ca-certificates clang make git curl tar wget..."
# ca-certificates — required for git clone via HTTPS (SSL verification)
# clang = C compiler on Termux (no gcc needed — clang builds everything)
pkg install -y ca-certificates clang make git curl tar wget

# Verify git can reach GitHub via HTTPS
log "Verifying HTTPS connectivity to GitHub..."
if curl -fsSL --max-time 10 -o /dev/null -w "%{http_code}" \
    "https://github.com" 2>/dev/null | grep -q "^2\|^3"; then
  ok "HTTPS to GitHub: OK"
else
  warn "Could not reach github.com — check your internet connection."
  warn "The install will continue; git clone may fail if network is unavailable."
fi

ok "All Termux dependencies installed."

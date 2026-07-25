#!/usr/bin/env bash
# 01_deps.sh — Install Termux build dependencies
# PhantomSec phantom-proot installer — Step 1

set -euo pipefail
source "$(dirname "$0")/_common.sh"

step "Step 1 — Termux dependencies"

log "Updating Termux package lists..."
pkg update -y -q

log "Installing: clang make git curl tar wget..."
# clang = C compiler on Termux (no gcc needed — clang builds everything)
pkg install -y clang make git curl tar wget

ok "All Termux dependencies installed."

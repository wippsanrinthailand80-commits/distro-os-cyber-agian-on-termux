#!/usr/bin/env bash
# 00_check.sh — Sanity checks
# PhantomSec phantom-proot installer — Step 0

set -euo pipefail
source "$(dirname "$0")/_common.sh"

step "Step 0 — Pre-flight checks"

# Must be Termux
[ -d "/data/data/com.termux" ] || \
  err "This installer is for Termux (Android) only.\nLinux bare-metal: bash <(curl -sL ${RAW_URL}/os/install.sh)"

# Architecture check
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64) ok "Architecture: $ARCH (ARM64) ✓" ;;
  x86_64)  warn "Architecture: $ARCH — ARM64 is primary; x86-64 should work too." ;;
  *)       err "Unsupported architecture: $ARCH (need aarch64 or x86_64)" ;;
esac

# Android API level (optional — getprop may not exist everywhere)
if command -v getprop &>/dev/null; then
  API=$(getprop ro.build.version.sdk 2>/dev/null || echo 0)
  if [ "$API" -lt 28 ]; then
    warn "Android API $API detected. phantom-proot works best on API 28+."
  else
    info "Android API: $API ✓"
  fi
fi

# Enough free space? (~500 MB needed)
FREE_KB=$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4}' || echo 999999)
if [ "$FREE_KB" -lt 524288 ]; then
  warn "Low disk space: ${FREE_KB} KB free. Recommend at least 512 MB."
fi

ok "Pre-flight checks passed."

#!/usr/bin/env bash
# 00_check.sh — Pre-flight environment checks
# PhantomSec OS Termux Edition v2.8.0

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 0 — Environment Check"

# ── Termux detection ────────────────────────────────────────────────────────
if [ ! -d "/data/data/com.termux" ] && [ -z "${TERMUX_VERSION:-}" ]; then
  warn "Termux not detected — some features may not work."
fi

# ── Architecture ────────────────────────────────────────────────────────────
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64)  info "Architecture: ARM64 ✓" ;;
  x86_64)         warn "x86_64 detected — ARM64 is recommended for full tool support." ;;
  *)              err "Unsupported architecture: $ARCH" ;;
esac

# ── Android version ─────────────────────────────────────────────────────────
if command -v getprop &>/dev/null; then
  API="$(getprop ro.build.version.sdk 2>/dev/null || echo 0)"
  if [ "$API" -gt 0 ] && [ "$API" -lt 28 ]; then
    warn "Android API $API — API 28+ recommended."
  fi
fi

# ── Disk space ──────────────────────────────────────────────────────────────
AVAIL_KB="$(df -k "$HOME" 2>/dev/null | awk 'NR==2{print $4}' || echo 0)"
if [ "$AVAIL_KB" -gt 0 ] && [ "$AVAIL_KB" -lt 524288 ]; then
  warn "Low disk space: $(( AVAIL_KB / 1024 ))MB available (512MB+ recommended)."
fi

# ── Existing installation ──────────────────────────────────────────────────
if [ -d "$ROOTFS_DIR" ]; then
  warn "Existing rootfs found at $ROOTFS_DIR — will be rebuilt."
  rm -rf "$ROOTFS_DIR"
fi

ok "Environment checks passed."

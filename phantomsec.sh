#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec — Distro Feel Edition  v2.5.5                         ║
# ║          รองรับ Termux (Android) | macOS | Linux                        ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# GitHub: https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux
# This is a wrapper that sources the distro-feel edition

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the actual implementation from distro-feel/
if [ -f "$SCRIPT_DIR/distro-feel/phantomsec.sh" ]; then
  source "$SCRIPT_DIR/distro-feel/phantomsec.sh"
else
  echo "Error: distro-feel/phantomsec.sh not found"
  echo "Please ensure the distro-feel directory exists in: $SCRIPT_DIR"
  exit 1
fi

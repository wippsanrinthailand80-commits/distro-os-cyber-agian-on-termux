#!/usr/bin/env bash
# _common.sh — PhantomSec OS Termux Edition v2.8.0
# Shared constants, paths, and logging helpers.
# Sourced by every setup script via $PHANTOMSEC_COMMON.

VERSION="2.8.0"

# ── Colors ──────────────────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' B='\033[1m'   D='\033[2m' NC='\033[0m'

# ── Logging ─────────────────────────────────────────────────────────────────
log()  { echo -e "${G}[+]${NC} $*"; }
warn() { echo -e "${Y}[!]${NC} $*"; }
err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }
ok()   { echo -e "${G}[✓]${NC} $*"; }
info() { echo -e "${D}    $*${NC}"; }
step() { echo -e "\n${C}${B}━━━  $*  ━━━${NC}\n"; }

# ── Paths ───────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux"
RAW_URL="https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main"

INSTALL_DIR="${PHANTOMSEC_DIR:-$HOME/.phantomsec-os}"
ROOTFS_DIR="${PHANTOMSEC_ROOTFS:-$HOME/.phantomsec-rootfs}"
LOCAL_BIN="$HOME/.local/bin"
PROOT_BIN="$LOCAL_BIN/phantom-proot"
TOOLS_SRC="$INSTALL_DIR/os"

# ── Helpers ─────────────────────────────────────────────────────────────────
require_cmd() {
  command -v "$1" &>/dev/null || err "'$1' is required but not found.\nRun: pkg install $2"
}

ensure_dir() { mkdir -p "$1" 2>/dev/null; }

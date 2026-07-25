#!/usr/bin/env bash
# _common.sh — Shared variables and helper functions
# Sourced by every setup/*.sh script

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' R='\033[0;31m' NC='\033[0m' BOLD='\033[1m' DIM='\033[2m'

log()  { echo -e "${G}[+]${NC} $*"; }
warn() { echo -e "${Y}[!]${NC} $*"; }
err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }
ok()   { echo -e "${G}[✓]${NC} $*"; }
info() { echo -e "${C}${DIM}    $*${NC}"; }
step() { echo -e "\n${C}${BOLD}━━━  $*  ━━━${NC}\n"; }

REPO_URL="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux"
RAW_URL="https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main"

INSTALL_DIR="${PHANTOMSEC_DIR:-$HOME/.phantomsec-os}"
ROOTFS_DIR="${PHANTOMSEC_ROOTFS:-$HOME/.phantomsec-rootfs}"
LOCAL_BIN="$HOME/.local/bin"
PROOT_BIN="$LOCAL_BIN/proot"

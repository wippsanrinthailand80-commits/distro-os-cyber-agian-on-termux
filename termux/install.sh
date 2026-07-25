#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec OS — Termux Edition v2.2.0                          ║
# ║          phantom-proot installer — modular setup                        ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# One-line install:
#   bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/termux/install.sh)

set -euo pipefail

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' R='\033[0;31m' NC='\033[0m' BOLD='\033[1m' DIM='\033[2m'

err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }
log()  { echo -e "${G}[+]${NC} $*"; }
info() { echo -e "${C}${DIM}    $*${NC}"; }

RAW_URL="https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main"
SETUP_DIR="$(dirname "$0")/setup"

echo ""
echo -e "${C}${BOLD}"
cat << 'BANNER'
  ██████╗ ██╗  ██╗ █████╗ ███╗  ██╗████████╗ ██████╗ ███╗  ███╗
  ██╔══██╗██║  ██║██╔══██╗████╗ ██║╚══██╔══╝██╔═══██╗████╗████║
  ██████╔╝███████║███████║██╔██╗██║   ██║   ██║   ██║██╔████╔██║
  ██╔═══╝ ██╔══██║██╔══██║██║╚████║   ██║   ██║   ██║██║╚██╔╝██║
  ██║     ██║  ██║██║  ██║██║ ╚███║   ██║   ╚██████╔╝██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝
BANNER
echo -e "${NC}"
echo -e "${C}${BOLD}  PhantomSec OS — Termux Edition v2.2.0${NC}"
echo -e "${DIM}  phantom-proot: built from scratch in C | no root | no proot-distro${NC}\n"

# ── Locate setup scripts ──────────────────────────────────────────────────────
# Case 1: running from inside a cloned repo  (./termux/install.sh)
# Case 2: running via one-liner curl pipe    (bash <(curl ...))
#         → scripts must be fetched from GitHub

_run_step() {
  local script="$1"
  local label="$2"

  if [ -f "$SETUP_DIR/$script" ]; then
    bash "$SETUP_DIR/$script"
  else
    # Fetch and run directly from GitHub
    log "Fetching $label from GitHub..."
    bash <(curl -fsSL "${RAW_URL}/termux/setup/${script}") \
      || err "Setup step failed: $script"
  fi
}

# ── Run all setup steps in order ─────────────────────────────────────────────
_run_step "00_check.sh"     "pre-flight checks"
_run_step "01_deps.sh"      "Termux dependencies"
_run_step "02_clone.sh"     "clone repo"
_run_step "03_proot.sh"     "build phantom-proot"
_run_step "04_rootfs.sh"    "download Ubuntu rootfs"
_run_step "05_configure.sh" "configure rootfs"
_run_step "06_tools.sh"     "build PhantomSec tools"
_run_step "07_launchers.sh" "create launchers"

# ── Done ─────────────────────────────────────────────────────────────────────
LOCAL_BIN="$HOME/.local/bin"

echo ""
echo -e "${C}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C}${BOLD}  PhantomSec OS — Termux Edition v2.2.0 ready!${NC}"
echo -e "${C}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${G}Enter full environment:${NC}  ${BOLD}phantomsec-os${NC}"
echo ""
echo -e "  ${G}Run tools directly:${NC}"
echo -e "     ${BOLD}ps-psh${NC}         PhantomSec Shell"
echo -e "     ${BOLD}ps-netghost${NC}    Network Ghost"
echo -e "     ${BOLD}ps-spectrscan${NC}  Spectrum Scanner"
echo -e "     ${BOLD}ps-scdna${NC}       SC-DNA"
echo -e "     ${BOLD}ps-entropyd${NC}    Entropy Daemon"
echo ""
echo -e "  ${DIM}Built with Termux clang — no apt-get inside proot needed.${NC}"
echo -e "  ${DIM}Powered by phantom-proot (PhantomSec's own proot, 100% from scratch).${NC}"
echo ""
echo -e "  ${Y}Restart shell or run:  source ~/.bashrc${NC}"
echo -e "  ${Y}For authorized security testing and educational use only.${NC}"
echo -e "  ${Y}ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"
echo ""

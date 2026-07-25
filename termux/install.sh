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
ok()   { echo -e "${G}[✓]${NC} $*"; }

RAW_URL="https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main"

STEPS=(
  "_common.sh"
  "00_check.sh"
  "01_deps.sh"
  "02_clone.sh"
  "03_proot.sh"
  "04_rootfs.sh"
  "05_configure.sh"
  "06_tools.sh"
  "07_launchers.sh"
)

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

# ── Stage all setup scripts into a temp directory ─────────────────────────────
# Doing this first guarantees that sourcing _common.sh always works,
# regardless of whether we are running from a clone or a curl pipe.

SETUP_TMP="$(mktemp -d /tmp/phantomsec-setup.XXXXXX)"
trap 'rm -rf "$SETUP_TMP"' EXIT

# Try to find scripts relative to THIS file first (clone / local run).
# $BASH_SOURCE[0] is reliable even in sourced scripts; fall back to $0.
SELF="${BASH_SOURCE[0]:-$0}"
LOCAL_SETUP="$(cd "$(dirname "$SELF")" 2>/dev/null && pwd)/setup"

log "Staging setup scripts..."
for SCRIPT in "${STEPS[@]}"; do
  DEST="$SETUP_TMP/$SCRIPT"
  if [ -f "$LOCAL_SETUP/$SCRIPT" ]; then
    cp "$LOCAL_SETUP/$SCRIPT" "$DEST"
  else
    curl -fsSL "${RAW_URL}/termux/setup/${SCRIPT}" -o "$DEST" \
      || err "Could not fetch setup script: $SCRIPT"
  fi
  chmod +x "$DEST"
done
ok "All setup scripts staged → $SETUP_TMP"

# ── Run each step in order ────────────────────────────────────────────────────
RUN_STEPS=(
  "00_check.sh"
  "01_deps.sh"
  "02_clone.sh"
  "03_proot.sh"
  "04_rootfs.sh"
  "05_configure.sh"
  "06_tools.sh"
  "07_launchers.sh"
)

for SCRIPT in "${RUN_STEPS[@]}"; do
  bash "$SETUP_TMP/$SCRIPT" \
    || err "Setup step failed: $SCRIPT\nCheck the output above for details."
done

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
echo -e "  ${DIM}Compiled with Termux clang — no apt-get inside proot needed.${NC}"
echo -e "  ${DIM}Powered by phantom-proot (100% from scratch, no proot-distro).${NC}"
echo ""
echo -e "  ${Y}Restart shell or run:  source ~/.bashrc${NC}"
echo -e "  ${Y}For authorized security testing and educational use only.${NC}"
echo -e "  ${Y}ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"
echo ""

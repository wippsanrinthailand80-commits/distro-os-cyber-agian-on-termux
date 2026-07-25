#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec OS — Termux Edition v2.8.0 Beta                     ║
# ║          Custom proot · No distro needed · ARM64 native                 ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# One-line install:
#   bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/termux/install.sh)

set -euo pipefail

VERSION="2.8.0"

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' R='\033[0;31m' NC='\033[0m' B='\033[1m' D='\033[2m'

err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }
log()  { echo -e "${G}[+]${NC} $*"; }
ok()   { echo -e "${G}[✓]${NC} $*"; }

RAW_URL="https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main"

# ── Setup scripts (run in order) ───────────────────────────────────────────
SETUP_SCRIPTS=(
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

# ── Banner ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${C}${B}"
cat << 'BANNER'
  ██████╗ ██╗  ██╗ █████╗ ███╗  ██╗████████╗ ██████╗ ███╗  ███╗
  ██╔══██╗██║  ██║██╔══██╗████╗ ██║╚══██╔══╝██╔═══██╗████╗████║
  ██████╔╝███████║███████║██╔██╗██║   ██║   ██║   ██║██╔████╔██║
  ██╔═══╝ ██╔══██║██╔══██║██║╚████║   ██║   ██║   ██║██║╚██╔╝██║
  ██║     ██║  ██║██║  ██║██║ ╚███║   ██║   ╚██████╔╝██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝
BANNER
echo -e "${NC}"
echo -e "${C}${B}  PhantomSec OS — Termux Edition v${VERSION} Beta${NC}"
echo -e "${D}  Custom proot · No distro downloads · ARM64 native · ~5MB rootfs${NC}"
echo -e "${D}  Built with Termux clang from scratch — no proot-distro, no Ubuntu${NC}\n"

# ── Stage scripts into temp directory ──────────────────────────────────────
SETUP_TMP="$(mktemp -d "${TMPDIR:-/tmp}/phantomsec-setup.XXXXXX")"
trap 'rm -rf "$SETUP_TMP"' EXIT

SELF_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "/proc/self/fd/"* ]]; then
  SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup"
fi

log "Staging setup scripts..."
for SCRIPT in "${SETUP_SCRIPTS[@]}"; do
  DEST="$SETUP_TMP/$SCRIPT"
  if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/$SCRIPT" ]; then
    cp "$SELF_DIR/$SCRIPT" "$DEST"
  else
    curl -fsSL "${RAW_URL}/termux/setup/${SCRIPT}" -o "$DEST" \
      || err "Could not fetch: termux/setup/$SCRIPT"
  fi
  chmod +x "$DEST"
done
ok "Scripts staged."

export PHANTOMSEC_COMMON="$SETUP_TMP/_common.sh"

# ── Run each step ──────────────────────────────────────────────────────────
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
    || err "Setup step failed: $SCRIPT\nSee output above for details."
done

# ── Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${C}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C}${B}  PhantomSec OS v${VERSION} Beta — Ready!${NC}"
echo -e "${C}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${G}Enter with menu:${NC}    ${B}phantomsec-os${NC}"
echo ""
echo -e "  ${G}Run tools directly:${NC}"
echo -e "     ${B}ps-psh${NC}          PhantomSec Shell"
echo -e "     ${B}ps-netghost${NC}     Network Ghost"
echo -e "     ${B}ps-spectrscan${NC}   SpecterScan"
echo -e "     ${B}ps-scdna${NC}        SyscallDNA"
echo -e "     ${B}ps-entropyd${NC}     Entropy Daemon"
echo -e "     ${B}ps-passgen${NC}      Password Generator"
echo -e "     ${B}ps-hashcheck${NC}    Hash Identifier"
echo -e "     ${B}ps-vulnscan${NC}     Vulnerability Scanner"
echo -e "     ${B}ps-portscan${NC}     Port Scanner"
echo -e "     ${B}ps-revshell${NC}     Reverse Shell Generator"
echo ""
echo -e "  ${D}Custom proot built from C source — no third-party dependencies.${NC}"
echo -e "  ${D}Minimal busybox rootfs — no Ubuntu download, ~5MB total.${NC}"
echo ""
echo -e "  ${Y}Restart your shell or run:  source ~/.bashrc${NC}"
echo -e "  ${Y}For authorized security testing and educational use only.${NC}"
echo -e "  ${Y}ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"
echo ""

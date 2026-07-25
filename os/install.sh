#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec OS — Real Distro Installer                          ║
# ║          Builds C/C++ tools from source via Makefile                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Requirements: gcc, make, nasm (optional), grub-pc-bin, xorriso

set -euo pipefail

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' R='\033[0;31m' NC='\033[0m' BOLD='\033[1m'

log()  { echo -e "${G}[+]${NC} $*"; }
warn() { echo -e "${Y}[!]${NC} $*"; }
err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }
ok()   { echo -e "${G}[✓]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-/usr/local/bin}"
PS_LANG="${PHANTOMSEC_LANG:-en}"

echo ""
echo -e "${C}${BOLD}  PhantomSec OS v2.0.1${NC}"
echo -e "${C}  Real Distro — C/C++ Build Installer${NC}\n"

# ── Detect OS ────────────────────────────────────────────────────────────────
if [ -d "/data/data/com.termux" ]; then
  ERR="PhantomSec OS requires a full Linux system (x86-64). Termux is not supported."
  err "$ERR"
fi

OS="$(uname -s)"
[ "$OS" != "Linux" ] && err "PhantomSec OS requires Linux (x86-64 bare metal or VM)."
ARCH="$(uname -m)"
[ "$ARCH" != "x86_64" ] && err "Only x86-64 is supported. Detected: $ARCH"

# ── Check dependencies ───────────────────────────────────────────────────────
log "Checking build dependencies..."

MISSING=()
for dep in gcc make; do
  command -v "$dep" &>/dev/null || MISSING+=("$dep")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  warn "Missing: ${MISSING[*]}"
  if command -v apt-get &>/dev/null; then
    log "Installing via apt..."
    sudo apt-get update -qq
    sudo apt-get install -y gcc make nasm grub-pc-bin xorriso
  elif command -v pacman &>/dev/null; then
    log "Installing via pacman..."
    sudo pacman -S --noconfirm gcc make nasm grub xorriso
  elif command -v dnf &>/dev/null; then
    log "Installing via dnf..."
    sudo dnf install -y gcc make nasm grub2-tools xorriso
  else
    err "Cannot install dependencies automatically. Install manually: ${MISSING[*]}"
  fi
fi
ok "Dependencies satisfied."

# ── Build tools ──────────────────────────────────────────────────────────────
log "Building PhantomSec OS tools from source..."
cd "$SCRIPT_DIR"

make LANG="$PS_LANG" all 2>&1 | sed 's/^/  /' || err "Build failed. Check output above."
ok "Build complete."

# ── Install binaries ─────────────────────────────────────────────────────────
log "Installing to $PREFIX/bin ..."
sudo make PREFIX="$PREFIX" install 2>&1 | sed 's/^/  /'
ok "Tools installed to $PREFIX/bin"

# ── Build ISO (optional) ─────────────────────────────────────────────────────
if command -v grub-mkrescue &>/dev/null && command -v xorriso &>/dev/null; then
  log "Building bootable ISO..."
  bash "$SCRIPT_DIR/distro/build.sh" 2>&1 | sed 's/^/  /' || warn "ISO build failed (optional step)."
  ok "ISO ready: $SCRIPT_DIR/distro/phantomsec.iso"
else
  warn "grub-mkrescue / xorriso not found — skipping ISO build (optional)."
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${C}${BOLD}  PhantomSec OS v2.0.1 installed.${NC}"
echo -e "  Tools: psh  netghost  spectrscan  scdna  entropyd"
echo -e "  Run:   psh --help"
echo ""
echo -e "  ${Y}For authorized security testing and educational research only.${NC}"
echo -e "  ${Y}ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"
echo ""

#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec OS — Termux Edition v2.0.1                          ║
# ║          Custom proot-distro environment on Termux (Android)            ║
# ║          Builds real C/C++ OS tools inside an isolated Linux env        ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# One-line install:
#   bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/termux/install.sh)

set -euo pipefail

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' R='\033[0;31m' NC='\033[0m' BOLD='\033[1m' DIM='\033[2m'

log()  { echo -e "${G}[+]${NC} $*"; }
warn() { echo -e "${Y}[!]${NC} $*"; }
err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }
ok()   { echo -e "${G}[✓]${NC} $*"; }
info() { echo -e "${C}${DIM}    $*${NC}"; }

REPO_URL="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux"
INSTALL_DIR="$HOME/.phantomsec-os"
LOCAL_BIN="$HOME/.local/bin"

# ── Sanity check — must be Termux ────────────────────────────────────────────
[ -d "/data/data/com.termux" ] || err "This script is for Termux (Android) only.\nFor Linux bare-metal/VM, use: bash <(curl -sL ${REPO_URL/github.com/raw.githubusercontent.com}/main/os/install.sh)"

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
echo -e "${C}${BOLD}  PhantomSec OS — Termux Edition v2.0.1${NC}"
echo -e "${DIM}  Custom proot-distro Linux environment on Android${NC}\n"

# ── Step 1: Update Termux & install proot-distro ─────────────────────────────
log "Updating Termux packages..."
pkg update -y -q
pkg upgrade -y -q

log "Installing proot-distro, git, curl..."
pkg install -y proot-distro git curl
ok "Base packages ready."

# ── Step 2: Install Ubuntu via proot-distro ───────────────────────────────────
if proot-distro list 2>/dev/null | grep -q "ubuntu.*installed"; then
  warn "Ubuntu proot already installed — skipping."
else
  log "Installing Ubuntu via proot-distro (this takes a few minutes)..."
  proot-distro install ubuntu
  ok "Ubuntu installed."
fi

# ── Step 3: Clone PhantomSec OS source ───────────────────────────────────────
log "Cloning PhantomSec OS source..."
rm -rf "$INSTALL_DIR"
git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
ok "Source cloned → $INSTALL_DIR"

# ── Step 4: Build C/C++ tools inside proot Ubuntu ────────────────────────────
log "Installing build dependencies inside proot Ubuntu..."
proot-distro login ubuntu -- bash -c \
  "apt-get update -qq && apt-get install -y -q gcc make nasm libssl-dev 2>/dev/null | tail -3"
ok "Build deps ready inside proot."

log "Compiling PhantomSec OS tools from source..."
proot-distro login ubuntu \
  --bind "$INSTALL_DIR/os:/opt/phantomsec-os" -- bash -c \
  "cd /opt/phantomsec-os && make CC=gcc CFLAGS='-O2 -Wall -std=c11 -D_GNU_SOURCE' all && make PREFIX=/usr/local install && echo '[OK] Built: psh netghost spectrscan scdna entropyd'"
ok "C/C++ tools built and installed inside proot Ubuntu."

# ── Step 5: Create launcher scripts ─────────────────────────────────────────
mkdir -p "$LOCAL_BIN"

# Main env launcher
cat > "$LOCAL_BIN/phantomsec-os" << 'LAUNCHER'
#!/usr/bin/env bash
echo -e "\033[0;36m[PhantomSec OS — Termux Edition]\033[0m"
echo -e "\033[2mEntering proot environment...\033[0m\n"
exec proot-distro login ubuntu -- "${@:-bash}"
LAUNCHER
chmod +x "$LOCAL_BIN/phantomsec-os"

# Per-tool launchers
for TOOL in psh netghost spectrscan scdna entropyd; do
  cat > "$LOCAL_BIN/$TOOL" << TOOL_EOF
#!/usr/bin/env bash
exec proot-distro login ubuntu -- $TOOL "\$@"
TOOL_EOF
  chmod +x "$LOCAL_BIN/$TOOL"
done
ok "Launchers created in $LOCAL_BIN"

# ── Step 6: Add ~/.local/bin to PATH ─────────────────────────────────────────
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$PREFIX/etc/bash.bashrc"; do
  [ -f "$RC" ] || continue
  grep -q 'local/bin' "$RC" && continue
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
done

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${C}${BOLD}  PhantomSec OS — Termux Edition v2.0.1 installed.${NC}"
echo ""
echo -e "  ${G}Enter OS environment:${NC}    phantomsec-os"
echo -e "  ${G}Run tools directly:${NC}      psh · netghost · spectrscan · scdna · entropyd"
echo -e "  ${G}Full proot shell:${NC}         proot-distro login ubuntu"
echo ""
echo -e "  ${DIM}Tools compiled from source inside isolated Ubuntu proot on Android.${NC}"
echo -e "  ${Y}For authorized security testing and educational research only.${NC}"
echo -e "  ${Y}ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"
echo ""

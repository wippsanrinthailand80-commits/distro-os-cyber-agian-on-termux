#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec — Distro Feel Edition v2.5.3                        ║
# ║          Shell Toolkit Installer                                         ║
# ║          Supports: Termux (Android) · Linux · macOS                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# NOTE: This installs the shell-based Distro Feel toolkit.
#       For the real C/C++ OS, see: os/install.sh

set -euo pipefail

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' R='\033[0;31m' NC='\033[0m' BOLD='\033[1m'

INSTALL_DIR="${PHANTOMSEC_DIR:-$HOME/.phantomsec}"
BIN_DIR="$HOME/.local/bin"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTRO_FEEL_DIR="$REPO_DIR"

log()  { echo -e "${G}[+]${NC} $*"; }
warn() { echo -e "${Y}[!]${NC} $*"; }
err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }
ok()   { echo -e "${G}[✓]${NC} $*"; }

echo ""
echo -e "${C}${BOLD}  PhantomSec — Distro Feel Edition v2.5.3${NC}"
echo -e "${C}  Shell Toolkit Installer${NC}"
echo -e "${Y}  (Not a real OS — shell-based distro feel toolkit)${NC}\n"

# ── Detect environment ───────────────────────────────────────────────────────
if [ -d "/data/data/com.termux" ]; then
  ENV="termux"; PKG="pkg"
elif command -v apt-get &>/dev/null; then
  ENV="debian"; PKG="sudo apt-get"
elif command -v pacman &>/dev/null; then
  ENV="arch"; PKG="sudo pacman -S --noconfirm"
elif [ "$(uname)" = "Darwin" ]; then
  ENV="macos"; PKG="brew"
else
  ENV="generic"; PKG=""
fi
log "Detected environment: $ENV"

# ── Install dependencies ─────────────────────────────────────────────────────
log "Installing dependencies..."
case "$ENV" in
  termux)
    pkg update -y -q
    pkg install -y curl git nmap python dnsutils whois openssl-tool 2>/dev/null || true ;;
  debian)
    sudo apt-get update -qq
    sudo apt-get install -y curl git nmap python3 dnsutils whois openssl 2>/dev/null || true ;;
  arch)
    sudo pacman -S --noconfirm curl git nmap python bind-tools whois openssl 2>/dev/null || true ;;
  macos)
    brew install curl git nmap python3 whois openssl 2>/dev/null || true ;;
  *) warn "Unknown environment — skipping package install." ;;
esac
ok "Dependencies done."

# ── Install toolkit ──────────────────────────────────────────────────────────
log "Installing Distro Feel toolkit to $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

cp -r "$DISTRO_FEEL_DIR/phantomsec.sh" "$INSTALL_DIR/"
cp -r "$DISTRO_FEEL_DIR/modules" "$INSTALL_DIR/" 2>/dev/null || true
cp -r "$DISTRO_FEEL_DIR/themes" "$INSTALL_DIR/" 2>/dev/null || true
cp -r "$DISTRO_FEEL_DIR/wordlists" "$INSTALL_DIR/" 2>/dev/null || true
chmod +x "$INSTALL_DIR/phantomsec.sh"
chmod +x "$INSTALL_DIR/modules/"*.sh 2>/dev/null || true
chmod +x "$INSTALL_DIR/themes/"*.sh  2>/dev/null || true

# ── Create launcher ──────────────────────────────────────────────────────────
cat > "$BIN_DIR/phantomsec" <<'LAUNCHER'
#!/usr/bin/env bash
exec bash "${PHANTOMSEC_DIR:-$HOME/.phantomsec}/phantomsec.sh" "$@"
LAUNCHER
chmod +x "$BIN_DIR/phantomsec"

# ── Add to PATH ──────────────────────────────────────────────────────────────
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  [ -f "$RC" ] || continue
  grep -q '\.local/bin' "$RC" && continue
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
done

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${C}${BOLD}  PhantomSec Distro Feel v2.5.3 installed.${NC}"
echo -e "  Run: ${G}phantomsec${NC}"
echo -e "  Or:  ${G}bash ~/.phantomsec/phantomsec.sh${NC}"
echo ""
echo -e "  ${Y}For authorized security testing and educational research only.${NC}"
echo -e "  ${Y}ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"
echo ""

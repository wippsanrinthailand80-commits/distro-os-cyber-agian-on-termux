#!/usr/bin/env bash
# PhantomSec — Distro Feel Edition Installer
# Supports Termux (Android), Debian/Ubuntu, Arch, macOS

set -euo pipefail

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' R='\033[0;31m' NC='\033[0m' BOLD='\033[1m'

INSTALL_DIR="${PHANTOMSEC_DIR:-$HOME/.phantomsec}"
BIN_DIR="$HOME/.local/bin"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { echo -e "${G}[+]${NC} $*"; }
warn() { echo -e "${Y}[!]${NC} $*"; }
err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }

echo ""
echo -e "${C}${BOLD}  PhantomSec — Distro Feel Edition v2.5.5${NC}"
echo -e "${C}  Installing...${NC}\n"

# Detect environment
if [ -d "/data/data/com.termux" ]; then
  ENV="termux"
  PKG="pkg"
elif command -v apt-get &>/dev/null; then
  ENV="debian"
  PKG="sudo apt-get"
elif command -v pacman &>/dev/null; then
  ENV="arch"
  PKG="sudo pacman -S --noconfirm"
elif [ "$(uname)" = "Darwin" ]; then
  ENV="macos"
  PKG="brew"
else
  ENV="generic"
  PKG=""
fi

log "Environment: $ENV"

# Create directories
mkdir -p "$INSTALL_DIR"/{logs,reports,profiles,wordlists}
mkdir -p "$BIN_DIR"
log "Directories: $INSTALL_DIR"

# Copy files
cp -r "$REPO_DIR"/* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/phantomsec.sh"
chmod +x "$INSTALL_DIR/modules/"*.sh 2>/dev/null || true
chmod +x "$INSTALL_DIR/themes/"*.sh 2>/dev/null || true

# Create launcher
cat > "$BIN_DIR/phantomsec" << EOF
#!/usr/bin/env bash
export PHANTOMSEC_DIR="$INSTALL_DIR"
exec "$INSTALL_DIR/phantomsec.sh" "\$@"
EOF
chmod +x "$BIN_DIR/phantomsec"

# Add to PATH if needed
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
  SHELL_RC="$HOME/.bashrc"
  [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
  echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
  warn "Added $BIN_DIR to PATH in $SHELL_RC — restart shell or run: source $SHELL_RC"
fi

# Download basic wordlist
if [ ! -f "$INSTALL_DIR/wordlists/common.txt" ]; then
  log "Downloading wordlist..."
  curl -sL "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt" \
    -o "$INSTALL_DIR/wordlists/common.txt" 2>/dev/null || warn "Wordlist download failed (optional)"
fi

# Install optional tools
log "Checking optional tools..."
TOOLS_TO_INSTALL=""
for tool in nmap curl wget git python3; do
  command -v "$tool" &>/dev/null || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL $tool"
done

if [ -n "$TOOLS_TO_INSTALL" ]; then
  warn "Optional tools missing:$TOOLS_TO_INSTALL"
  if [ -n "$PKG" ]; then
    echo -ne "${Y}  Install them now? [y/N]${NC} "; read -r yn
    [ "${yn,,}" = "y" ] && $PKG install -y $TOOLS_TO_INSTALL 2>/dev/null || true
  fi
fi

echo ""
log "Installation complete!"
echo -e "\n  ${BOLD}Run:${NC} ${C}phantomsec${NC}  or  ${C}bash $INSTALL_DIR/phantomsec.sh${NC}\n"

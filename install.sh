#!/data/data/com.termux/files/usr/bin/bash
# ╔═══════════════════════════════════════════════════════════════╗
# ║           PhantomSec OS — Termux Cybersecurity Distro        ║
# ║                    Installer v1.0.0                           ║
# ╚═══════════════════════════════════════════════════════════════╝

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

PHANTOMSEC_DIR="$HOME/.phantomsec"
PHANTOMSEC_BIN="$PREFIX/bin/phantomsec"
VERSION="1.1.0"

clear
cat << "EOF"

██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗███████╗███████╗ ██████╗
██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║██╔════╝██╔════╝██╔════╝
██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║███████╗█████╗  ██║
██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║╚════██║██╔══╝  ██║
██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║███████║███████╗╚██████╗
╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝ ╚═════╝

EOF

echo -e "${MAGENTA}${BOLD}              [ Termux Cybersecurity Distro v${VERSION} ]${NC}"
echo -e "${DIM}              By the PhantomSec Project${NC}"
echo ""
sleep 1

print_status() { echo -e "${CYAN}[*]${NC} $1"; }
print_ok()     { echo -e "${GREEN}[✓]${NC} $1"; }
print_warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
print_err()    { echo -e "${RED}[✗]${NC} $1"; }
print_step()   { echo -e "\n${MAGENTA}${BOLD}━━━ $1 ━━━${NC}"; }

# ──────────────────────────────────────────
#  Pre-flight checks
# ──────────────────────────────────────────
print_step "Pre-flight checks"

if [ ! -d "$PREFIX" ]; then
  print_err "Termux environment not detected. Please run inside Termux."
  exit 1
fi
print_ok "Termux detected"

if ! ping -c 1 8.8.8.8 &>/dev/null; then
  print_err "No internet connection. Please connect and retry."
  exit 1
fi
print_ok "Internet connection OK"

# ──────────────────────────────────────────
#  Update repos
# ──────────────────────────────────────────
print_step "Updating repositories"
pkg update -y && pkg upgrade -y
print_ok "Packages updated"

# ──────────────────────────────────────────
#  Core packages  (NO python-pip — Termux forbids pip self-upgrade)
# ──────────────────────────────────────────
print_step "Installing core dependencies"

# Install one-by-one so a missing package never aborts the whole install
CORE_PKGS=(
  python
  git
  curl
  wget
  nmap
  hydra
  sqlmap
  openssl-tool
  openssh
  termux-tools
  termux-api
  figlet
  toilet
  lolcat
  ncurses-utils
  jq
  bc
  vim
  nano
  tmux
  zsh
  perl
  ruby
  nodejs-lts
)

for p in "${CORE_PKGS[@]}"; do
  print_status "Installing ${p}..."
  pkg install -y "$p" >/dev/null 2>&1 && print_ok "$p" || print_warn "Skipped: $p"
done

# ──────────────────────────────────────────
#  PhantomSec environment
# ──────────────────────────────────────────
print_step "Setting up PhantomSec environment"

mkdir -p "$PHANTOMSEC_DIR"/{logs,sessions,wordlists,reports,tools}
print_ok "Directories created"

# Wordlist
print_status "Downloading mini wordlist..."
curl -sL "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000.txt" \
  -o "$PHANTOMSEC_DIR/wordlists/common-passwords.txt" 2>/dev/null || true
print_ok "Wordlist ready"

# Copy modules
cp -f "$(dirname "$0")/modules/"*.sh "$PHANTOMSEC_DIR/tools/" 2>/dev/null || true

# Install main launcher
cp -f "$(dirname "$0")/phantomsec.sh" "$PHANTOMSEC_BIN"
chmod +x "$PHANTOMSEC_BIN"
print_ok "Launcher installed → $PHANTOMSEC_BIN"

# Config
mkdir -p "$HOME/.config/phantomsec"
cp -f "$(dirname "$0")/config/settings.conf" "$HOME/.config/phantomsec/" 2>/dev/null || true
print_ok "Config ready"

# ──────────────────────────────────────────
#  Shell aliases
# ──────────────────────────────────────────
print_step "Configuring shell"

for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rcfile" ] && ! grep -q "PhantomSec" "$rcfile" 2>/dev/null; then
    cat >> "$rcfile" << 'RCBLOCK'

# PhantomSec
alias phantomsec='bash $PREFIX/bin/phantomsec'
export PHANTOMSEC_DIR="$HOME/.phantomsec"
RCBLOCK
    print_ok "Alias added to $(basename $rcfile)"
  fi
done

# ──────────────────────────────────────────
#  Done
# ──────────────────────────────────────────
print_step "Installation Complete"
echo ""
echo -e "${GREEN}${BOLD}  ██████╗  ██████╗ ███╗   ██╗███████╗${NC}"
echo -e "${GREEN}${BOLD}  ██╔══██╗██╔═══██╗████╗  ██║██╔════╝${NC}"
echo -e "${GREEN}${BOLD}  ██║  ██║██║   ██║██╔██╗ ██║█████╗  ${NC}"
echo -e "${GREEN}${BOLD}  ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ${NC}"
echo -e "${GREEN}${BOLD}  ██████╔╝╚██████╔╝██║ ╚████║███████╗${NC}"
echo -e "${GREEN}${BOLD}  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝${NC}"
echo ""
echo -e "${WHITE}  PhantomSec installed successfully!${NC}"
echo -e "${DIM}  Launch:  ${CYAN}phantomsec${NC}"
echo -e "${DIM}  Opt-in Python tools:  ${CYAN}bash python_tools.sh${NC}"
echo ""

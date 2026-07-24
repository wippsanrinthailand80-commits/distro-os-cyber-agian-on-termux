#!/data/data/com.termux/files/usr/bin/bash
# ╔═══════════════════════════════════════════════════════════════╗
# ║           PhantomSec OS — Termux Cybersecurity Distro        ║
# ║                    Installer v1.0.0                           ║
# ╚═══════════════════════════════════════════════════════════════╝

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

PHANTOMSEC_DIR="$HOME/.phantomsec"
PHANTOMSEC_BIN="$PREFIX/bin/phantomsec"
VERSION="1.0.0"
REPO_URL="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-again-on-termux"

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
#  Core packages
# ──────────────────────────────────────────
print_step "Updating repositories"
pkg update -y && pkg upgrade -y
print_ok "Packages updated"

print_step "Installing core dependencies"
CORE_PKGS=(
  python python-pip git curl wget
  nmap hydra sqlmap
  openssl-tool openssh
  termux-tools termux-api
  figlet toilet lolcat
  ncurses-utils jq bc
  vim nano tmux zsh
  perl ruby nodejs-lts
)

for pkg in "${CORE_PKGS[@]}"; do
  print_status "Installing ${pkg}..."
  pkg install -y "$pkg" 2>/dev/null && print_ok "$pkg" || print_warn "Skipped: $pkg"
done

# ──────────────────────────────────────────
#  Python tools (optional — install separately)
# ──────────────────────────────────────────
print_step "Python security tools"
print_warn "Skipping pip packages (Termux restriction)."
print_warn "Run  bash python_tools.sh  later to install them optionally."

# ──────────────────────────────────────────
#  PhantomSec setup
# ──────────────────────────────────────────
print_step "Setting up PhantomSec environment"

mkdir -p "$PHANTOMSEC_DIR"/{logs,sessions,wordlists,reports,tools}

# Download rockyou wordlist (mini)
print_status "Downloading mini wordlist..."
curl -sL "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000.txt" \
  -o "$PHANTOMSEC_DIR/wordlists/common-passwords.txt" 2>/dev/null || true
print_ok "Wordlist ready"

# Copy tool scripts
cp -f "$(dirname "$0")/tools/"*.sh "$PHANTOMSEC_DIR/tools/" 2>/dev/null || true
cp -f "$(dirname "$0")/modules/"*.sh "$PHANTOMSEC_DIR/tools/" 2>/dev/null || true

# Install main launcher
cp -f "$(dirname "$0")/phantomsec.sh" "$PHANTOMSEC_BIN"
chmod +x "$PHANTOMSEC_BIN"

# Install config
mkdir -p "$HOME/.config/phantomsec"
cp -f "$(dirname "$0")/config/settings.conf" "$HOME/.config/phantomsec/" 2>/dev/null || true

# ZSH + Oh-My-Zsh (optional)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  print_status "Installing Oh-My-Zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
fi

# Setup .zshrc alias
grep -q "phantomsec" "$HOME/.zshrc" 2>/dev/null || echo '
# PhantomSec
alias ps="phantomsec"
alias psmenu="phantomsec"
export PHANTOMSEC_DIR="$HOME/.phantomsec"
' >> "$HOME/.zshrc"

grep -q "phantomsec" "$HOME/.bashrc" 2>/dev/null || echo '
# PhantomSec
alias ps="phantomsec"
export PHANTOMSEC_DIR="$HOME/.phantomsec"
' >> "$HOME/.bashrc"

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
echo -e "${WHITE}  PhantomSec has been installed successfully!${NC}"
echo -e "${DIM}  Type ${CYAN}phantomsec${DIM} to launch the main menu.${NC}"
echo ""

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
#  Enable extra Termux repositories
#  (hydra, sqlmap อยู่ใน unstable-repo ใน Termux เวอร์ชันใหม่)
# ──────────────────────────────────────────
print_step "Enabling Termux repositories"
pkg install -y unstable-repo 2>/dev/null && print_ok "unstable-repo" || print_warn "unstable-repo (ข้ามได้)"
pkg install -y root-repo    2>/dev/null && print_ok "root-repo"     || print_warn "root-repo (ข้ามได้)"

# ──────────────────────────────────────────
#  Update repos
# ──────────────────────────────────────────
print_step "Updating repositories"
pkg update -y && pkg upgrade -y
print_ok "Packages updated"

# ──────────────────────────────────────────
#  Helper: ติดตั้ง pkg พร้อม retry 1 ครั้ง
# ──────────────────────────────────────────
install_pkg() {
  local pkg="$1"
  print_status "Installing ${pkg}..."
  if pkg install -y "$pkg" >/dev/null 2>&1; then
    print_ok "$pkg"
    return 0
  fi
  # retry ครั้งที่ 2 หลัง 3 วินาที (เผื่อ network ชั่วคราว)
  sleep 3
  if pkg install -y "$pkg" >/dev/null 2>&1; then
    print_ok "$pkg (retry สำเร็จ)"
    return 0
  fi
  print_warn "ข้าม: $pkg (จะลอง fallback ทีหลัง)"
  return 1
}

# ──────────────────────────────────────────
#  Core packages
#  หมายเหตุ: ruby ต้องอยู่ก่อน lolcat เสมอ
#            (lolcat เป็น Ruby gem)
# ──────────────────────────────────────────
print_step "Installing core dependencies"

CORE_PKGS=(
  python
  git
  curl
  wget
  ruby
  perl
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
  nodejs-lts
)

for p in "${CORE_PKGS[@]}"; do
  install_pkg "$p"
done

# ──────────────────────────────────────────
#  Fallback สำหรับแพ็กเกจที่มักติดตั้งยาก
# ──────────────────────────────────────────
print_step "Fallback installs"

# sqlmap — ลองผ่าน pip ถ้า pkg ล้มเหลว
if ! command -v sqlmap &>/dev/null; then
  print_status "sqlmap: ลอง pip install..."
  pip install sqlmap --quiet --no-deps 2>/dev/null \
    && print_ok "sqlmap (via pip)" \
    || print_warn "sqlmap ติดตั้งไม่ได้อัตโนมัติ — รัน: pip install sqlmap"
fi

# hydra — แจ้งถ้ายังไม่มี
if ! command -v hydra &>/dev/null; then
  print_warn "hydra ยังไม่ถูกติดตั้ง — รัน: pkg install hydra"
fi

# lolcat — ลอง gem install ถ้า pkg ล้มเหลว
if ! command -v lolcat &>/dev/null; then
  print_status "lolcat: ลอง gem install..."
  gem install lolcat --no-document 2>/dev/null \
    && print_ok "lolcat (via gem)" \
    || print_warn "lolcat ติดตั้งไม่ได้อัตโนมัติ — รัน: gem install lolcat"
fi

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

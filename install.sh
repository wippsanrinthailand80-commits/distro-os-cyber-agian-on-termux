#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║           PhantomSec OS — Termux Cybersecurity Distro               ║
# ║                    Installer v1.1.0                                  ║
# ╚══════════════════════════════════════════════════════════════════════╝

R='\033[0;31m'  G='\033[0;32m'  Y='\033[1;33m'
C='\033[0;36m'  M='\033[0;35m'  W='\033[1;37m'
BOLD='\033[1m'  DIM='\033[2m'   NC='\033[0m'

PHANTOMSEC_DIR="$HOME/.phantomsec"
PHANTOMSEC_BIN="$PREFIX/bin/phantomsec"
VERSION="1.1.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── ตัวแปรติดตามสถานะ ─────────────────────────────────────────────────
INSTALLED=()    # ติดตั้งสำเร็จ
FALLBACK=()     # ใช้ fallback (pip/gem)
SKIPPED=()      # ติดตั้งไม่ได้เลย
TOTAL_STEPS=8
CURRENT_STEP=0

# ── Helper functions ──────────────────────────────────────────────────
ok()     { echo -e "  ${G}[✓]${NC} $1"; INSTALLED+=("$1"); }
warn()   { echo -e "  ${Y}[!]${NC} $1"; }
err()    { echo -e "  ${R}[✗]${NC} $1"; }
info()   { echo -e "  ${C}[*]${NC} $1"; }

step() {
  ((CURRENT_STEP++))
  local pct=$(( CURRENT_STEP * 100 / TOTAL_STEPS ))
  local filled=$(( pct / 5 ))
  local bar=""
  for i in $(seq 1 $filled);      do bar="${bar}█"; done
  for i in $(seq 1 $((20-filled))); do bar="${bar}░"; done
  echo ""
  echo -e "${M}${BOLD}━━━ [${CURRENT_STEP}/${TOTAL_STEPS}] $1${NC}"
  echo -e "  ${DIM}[${bar}] ${pct}%${NC}"
}

install_pkg() {
  local pkg="$1"
  info "ติดตั้ง ${pkg}..."
  if pkg install -y "$pkg" >/dev/null 2>&1; then
    echo -e "  ${G}[✓]${NC} ${pkg}"
    INSTALLED+=("$pkg")
    return 0
  fi
  # retry หลัง 3 วิ
  sleep 3
  if pkg install -y "$pkg" >/dev/null 2>&1; then
    echo -e "  ${G}[✓]${NC} ${pkg} ${DIM}(retry)${NC}"
    INSTALLED+=("$pkg")
    return 0
  fi
  echo -e "  ${Y}[!]${NC} ${pkg} ${DIM}— จะลอง fallback${NC}"
  return 1
}

# ── Banner ─────────────────────────────────────────────────────────────
clear
echo -e "${M}${BOLD}"
cat << 'BANNER'
  ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗
  ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║
  ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
  ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
  ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝
BANNER
echo -e "${NC}"
echo -e "  ${DIM}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "  ${DIM}│  ${C}Termux Cybersecurity Distro${DIM}  │  ${G}Installer v${VERSION}${DIM}   │${NC}"
echo -e "  ${DIM}└─────────────────────────────────────────────────────┘${NC}"
echo ""
sleep 1

# ══════════════════════════════════════════════════════════════════════
#  STEP 1 — Pre-flight checks
# ══════════════════════════════════════════════════════════════════════
step "Pre-flight checks"

# ตรวจสอบ Termux
if [ -z "$PREFIX" ] || [ ! -d "$PREFIX/bin" ]; then
  err "ไม่พบ Termux environment — กรุณารันใน Termux เท่านั้น"
  exit 1
fi
echo -e "  ${G}[✓]${NC} Termux environment"

# ตรวจสอบ Android version ผ่าน uname
KERNEL=$(uname -r 2>/dev/null)
echo -e "  ${G}[✓]${NC} Kernel: ${DIM}${KERNEL}${NC}"

# ตรวจสอบ internet
echo -ne "  ${C}[*]${NC} ตรวจสอบอินเทอร์เน็ต... "
if curl -s --max-time 8 https://github.com > /dev/null 2>&1; then
  echo -e "${G}OK${NC}"
else
  echo -e "${R}ไม่มีสัญญาณ${NC}"
  err "กรุณาเชื่อมต่ออินเทอร์เน็ตก่อนติดตั้ง"
  exit 1
fi

# ตรวจสอบพื้นที่ว่าง (ต้องการ ~500MB)
FREE_KB=$(df "$HOME" 2>/dev/null | awk 'NR==2{print $4}')
FREE_MB=$(( ${FREE_KB:-0} / 1024 ))
if [ "$FREE_MB" -lt 300 ]; then
  warn "พื้นที่ว่างน้อย (${FREE_MB}MB) — แนะนำ 500MB ขึ้นไป"
else
  echo -e "  ${G}[✓]${NC} พื้นที่ว่าง: ${DIM}${FREE_MB}MB${NC}"
fi

# ══════════════════════════════════════════════════════════════════════
#  STEP 2 — Termux storage permission
# ══════════════════════════════════════════════════════════════════════
step "Termux storage permission"

if [ ! -d "$HOME/storage" ]; then
  info "ขอสิทธิ์เข้าถึง storage..."
  echo -e "  ${Y}[!]${NC} จะมี popup ขึ้นมาให้กด ${W}Allow${NC}"
  termux-setup-storage 2>/dev/null || true
  sleep 2
  [ -d "$HOME/storage" ] \
    && echo -e "  ${G}[✓]${NC} Storage permission" \
    || warn "Storage permission ข้าม (ไม่บังคับ)"
else
  echo -e "  ${G}[✓]${NC} Storage permission มีอยู่แล้ว"
fi

# ══════════════════════════════════════════════════════════════════════
#  STEP 3 — Enable Termux repositories
# ══════════════════════════════════════════════════════════════════════
step "Enable Termux repositories"

info "เปิด unstable-repo (hydra, sqlmap)..."
pkg install -y unstable-repo >/dev/null 2>&1 \
  && echo -e "  ${G}[✓]${NC} unstable-repo" \
  || warn "unstable-repo (ข้ามได้)"

info "เปิด root-repo..."
pkg install -y root-repo >/dev/null 2>&1 \
  && echo -e "  ${G}[✓]${NC} root-repo" \
  || warn "root-repo (ข้ามได้)"

# ══════════════════════════════════════════════════════════════════════
#  STEP 4 — Update packages
# ══════════════════════════════════════════════════════════════════════
step "Update packages"

info "กำลัง update & upgrade..."
pkg update -y 2>&1 | tail -2
pkg upgrade -y 2>&1 | tail -2
echo -e "  ${G}[✓]${NC} Packages อัปเดตแล้ว"

# ══════════════════════════════════════════════════════════════════════
#  STEP 5 — Install core packages
#  (ruby ต้องอยู่ก่อน lolcat เสมอ)
# ══════════════════════════════════════════════════════════════════════
step "Install core packages"

CORE_PKGS=(
  python git curl wget
  ruby perl
  nmap hydra sqlmap
  openssl-tool openssh
  termux-tools termux-api
  figlet toilet lolcat
  ncurses-utils jq bc
  vim nano tmux zsh
  nodejs-lts
)

for p in "${CORE_PKGS[@]}"; do
  install_pkg "$p" || true
done

# ══════════════════════════════════════════════════════════════════════
#  STEP 6 — Fallback installs (pip / gem)
# ══════════════════════════════════════════════════════════════════════
step "Fallback installs"

# sqlmap → pip
if ! command -v sqlmap &>/dev/null; then
  info "sqlmap: ลอง pip..."
  if pip install sqlmap --quiet --no-deps 2>/dev/null; then
    echo -e "  ${G}[✓]${NC} sqlmap ${DIM}(via pip)${NC}"
    FALLBACK+=("sqlmap(pip)")
  else
    warn "sqlmap ไม่สามารถติดตั้งอัตโนมัติได้"
    warn "  → รัน: pip install sqlmap"
    SKIPPED+=("sqlmap")
  fi
else
  echo -e "  ${G}[✓]${NC} sqlmap พร้อมแล้ว"
fi

# lolcat → gem
if ! command -v lolcat &>/dev/null; then
  info "lolcat: ลอง gem install..."
  if gem install lolcat --no-document 2>/dev/null; then
    echo -e "  ${G}[✓]${NC} lolcat ${DIM}(via gem)${NC}"
    FALLBACK+=("lolcat(gem)")
  else
    warn "lolcat ไม่สามารถติดตั้งอัตโนมัติได้"
    warn "  → รัน: gem install lolcat"
    SKIPPED+=("lolcat")
  fi
else
  echo -e "  ${G}[✓]${NC} lolcat พร้อมแล้ว"
fi

# hydra
if ! command -v hydra &>/dev/null; then
  warn "hydra ยังไม่ถูกติดตั้ง"
  warn "  → รัน: pkg install hydra"
  SKIPPED+=("hydra")
else
  echo -e "  ${G}[✓]${NC} hydra พร้อมแล้ว"
fi

# ══════════════════════════════════════════════════════════════════════
#  STEP 7 — Setup PhantomSec environment
# ══════════════════════════════════════════════════════════════════════
step "Setup PhantomSec environment"

# ไดเรกทอรี
mkdir -p "$PHANTOMSEC_DIR"/{logs,sessions,wordlists,reports,tools}
echo -e "  ${G}[✓]${NC} สร้าง directories แล้ว"

# Wordlist
info "ดาวน์โหลด wordlist..."
curl -sL --max-time 20 \
  "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000.txt" \
  -o "$PHANTOMSEC_DIR/wordlists/common-passwords.txt" 2>/dev/null \
  && echo -e "  ${G}[✓]${NC} Wordlist พร้อม" \
  || warn "ดาวน์โหลด wordlist ไม่ได้ (ข้ามได้)"

# copy modules
cp -f "$SCRIPT_DIR/modules/"*.sh "$PHANTOMSEC_DIR/tools/" 2>/dev/null || true
echo -e "  ${G}[✓]${NC} Modules คัดลอกแล้ว"

# ติดตั้ง launcher
cp -f "$SCRIPT_DIR/phantomsec.sh" "$PHANTOMSEC_BIN"
chmod +x "$PHANTOMSEC_BIN"
echo -e "  ${G}[✓]${NC} Launcher → ${DIM}$PHANTOMSEC_BIN${NC}"

# config
mkdir -p "$HOME/.config/phantomsec"
cp -f "$SCRIPT_DIR/config/settings.conf" "$HOME/.config/phantomsec/" 2>/dev/null || true
echo -e "  ${G}[✓]${NC} Config พร้อม"

# ══════════════════════════════════════════════════════════════════════
#  STEP 8 — Configure shell aliases
# ══════════════════════════════════════════════════════════════════════
step "Configure shell"

for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rcfile" ] && ! grep -q "PhantomSec" "$rcfile" 2>/dev/null; then
    cat >> "$rcfile" << 'RCBLOCK'

# PhantomSec
alias phantomsec='bash $PREFIX/bin/phantomsec'
export PHANTOMSEC_DIR="$HOME/.phantomsec"
RCBLOCK
    echo -e "  ${G}[✓]${NC} Alias เพิ่มใน ${DIM}$(basename "$rcfile")${NC}"
  fi
done

# ══════════════════════════════════════════════════════════════════════
#  สรุปผลการติดตั้ง
# ══════════════════════════════════════════════════════════════════════
echo ""
echo -e "${M}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${M}${BOLD}  สรุปผลการติดตั้ง${NC}"
echo -e "${M}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# tools ที่สำคัญ — แสดงสถานะจริง
CRITICAL=(nmap hydra sqlmap curl wget git python3 openssl)
for t in "${CRITICAL[@]}"; do
  if command -v "$t" &>/dev/null; then
    echo -e "  ${G}[✓]${NC}  ${W}$t${NC}"
  else
    echo -e "  ${R}[✗]${NC}  ${W}$t${NC}  ${DIM}— ไม่พบ${NC}"
  fi
done

echo ""
echo -e "  ${G}ติดตั้งสำเร็จ:${NC}  ${#INSTALLED[@]} packages"
[ ${#FALLBACK[@]}  -gt 0 ] && echo -e "  ${Y}fallback:${NC}      ${FALLBACK[*]}"
[ ${#SKIPPED[@]}   -gt 0 ] && echo -e "  ${R}ข้าม:${NC}          ${SKIPPED[*]}"

echo ""
echo -e "${G}${BOLD}"
cat << 'DONE'
  ██████╗  ██████╗ ███╗   ██╗███████╗
  ██╔══██╗██╔═══██╗████╗  ██║██╔════╝
  ██║  ██║██║   ██║██╔██╗ ██║█████╗
  ██║  ██║██║   ██║██║╚██╗██║██╔══╝
  ██████╔╝╚██████╔╝██║ ╚████║███████╗
  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝
DONE
echo -e "${NC}"
echo -e "  ${W}PhantomSec OS ${VERSION} ติดตั้งสำเร็จ!${NC}"
echo ""
echo -e "  ${DIM}เปิดใช้งาน:${NC}  ${C}phantomsec${NC}"
echo -e "  ${DIM}หรือ:${NC}        ${C}bash $PREFIX/bin/phantomsec${NC}"
echo -e "  ${DIM}Python tools (optional):${NC}  ${C}bash python_tools.sh${NC}"
echo ""
echo -e "  ${Y}[!] เปิด terminal ใหม่เพื่อให้ alias มีผล${NC}"
echo ""

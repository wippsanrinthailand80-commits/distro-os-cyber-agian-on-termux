#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec OS — One-Command Bootstrap                      ║
# ║  รันด้วยคำสั่งเดียว:                                                ║
# ║  curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/bootstrap.sh | bash
# ╚══════════════════════════════════════════════════════════════════════╝

set -euo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' M='\033[0;35m' W='\033[1;37m'
BOLD='\033[1m' DIM='\033[2m' NC='\033[0m'

# ── Error handler ──────────────────────────────────────────────────────
trap 'echo -e "\n${R}[✗] Bootstrap failed (line $LINENO). Check the output above.${NC}"; exit 1' ERR

REPO_URL="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux"
REPO_DIR="$HOME/distro-os-cyber-agian-on-termux"

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
echo -e "  ${DIM}┌──────────────────────────────────────────────┐${NC}"
echo -e "  ${DIM}│  ${C}Bootstrap Installer${DIM}  │  ${G}PhantomSec OS v1.1.0${DIM}  │${NC}"
echo -e "  ${DIM}└──────────────────────────────────────────────┘${NC}"
echo ""

# ── ตรวจสอบ Termux ─────────────────────────────────────────────────────
if [ -z "$PREFIX" ] || [ ! -d "$PREFIX/bin" ]; then
  echo -e "${R}[✗] กรุณารันใน Termux เท่านั้น${NC}"
  exit 1
fi
echo -e "${G}[✓]${NC} Termux ตรวจพบแล้ว"

# ── ตรวจสอบ internet ────────────────────────────────────────────────────
echo -ne "${C}[*]${NC} ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต... "
if curl -s --max-time 5 https://github.com > /dev/null 2>&1; then
  echo -e "${G}OK${NC}"
else
  echo -e "${R}ไม่มีสัญญาณ${NC}"
  echo -e "${R}[✗] กรุณาเชื่อมต่ออินเทอร์เน็ตก่อน${NC}"
  exit 1
fi

# ── ติดตั้ง git ──────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  echo -e "${C}[*]${NC} กำลังติดตั้ง git..."
  pkg install -y git >/dev/null 2>&1
fi
echo -e "${G}[✓]${NC} git พร้อม"

# ── Clone หรืออัปเดต repo ────────────────────────────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  echo -e "${Y}[!]${NC} พบ repo เดิมอยู่แล้ว — กำลังอัปเดต..."
  cd "$REPO_DIR"
  git pull origin main 2>&1 || {
    echo -e "${R}[✗] git pull ล้มเหลว — ลอง clone ใหม่${NC}"
    cd "$HOME"
    rm -rf "$REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
  }
else
  echo -e "${C}[*]${NC} กำลัง clone PhantomSec OS..."
  git clone "$REPO_URL" "$REPO_DIR" 2>&1 || {
    echo -e "${R}[✗] clone ล้มเหลว กรุณาตรวจสอบอินเทอร์เน็ตและลองใหม่${NC}"
    exit 1
  }
fi

echo -e "${G}[✓]${NC} ได้ไฟล์ทั้งหมดแล้ว"

# ── รัน installer ────────────────────────────────────────────────────────
echo ""
echo -e "${M}${BOLD}[→] เริ่มการติดตั้ง...${NC}"
echo ""
sleep 1

cd "$REPO_DIR"
chmod +x install.sh
bash install.sh

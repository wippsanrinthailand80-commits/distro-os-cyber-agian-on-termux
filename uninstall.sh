#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║              PhantomSec OS — Uninstaller v1.1.0                     ║
# ╚══════════════════════════════════════════════════════════════════════╝

R='\033[0;31m'  G='\033[0;32m'  Y='\033[1;33m'
C='\033[0;36m'  M='\033[0;35m'  W='\033[1;37m'
BOLD='\033[1m'  DIM='\033[2m'   NC='\033[0m'

PHANTOMSEC_DIR="$HOME/.phantomsec"
PHANTOMSEC_BIN="$PREFIX/bin/phantomsec"
PHANTOMSEC_CONF="$HOME/.config/phantomsec"

# ── helper ────────────────────────────────────────────────────────────
ok()   { echo -e "  ${G}[✓]${NC} $1"; }
warn() { echo -e "  ${Y}[!]${NC} $1"; }
err()  { echo -e "  ${R}[✗]${NC} $1"; }
info() { echo -e "  ${C}[-]${NC} $1"; }

removed=0
skipped=0

remove_path() {
  local path="$1"
  local label="$2"
  if [ -e "$path" ] || [ -L "$path" ]; then
    rm -rf "$path" && ok "ลบแล้ว: ${DIM}${label}${NC}" && ((removed++)) || err "ลบไม่ได้: ${label}"
  else
    info "ไม่พบ:  ${DIM}${label}${NC}" && ((skipped++))
  fi
}

# ── ลบ RC block จาก .bashrc / .zshrc ด้วย Python3 ──────────────────
clean_rc() {
  local rcfile="$1"
  [ -f "$rcfile" ] || return

  # ใช้ Python3 ลบทุกบรรทัดที่เกี่ยวกับ PhantomSec ออกเป็น block
  python3 - "$rcfile" << 'PYEOF'
import sys, re, os

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# ลบ block ที่ install.sh เพิ่มไว้ (รองรับ blank line นำหน้าด้วย)
# block: optional blank + "# PhantomSec" + alias + export
pattern = re.compile(
    r'\n?# PhantomSec\n'
    r"alias phantomsec='bash \$PREFIX/bin/phantomsec'\n"
    r'export PHANTOMSEC_DIR="\$HOME/\.phantomsec"\n?',
    re.MULTILINE
)

new_content, count = pattern.subn('', content)

if count > 0:
    with open(path, 'w') as f:
        f.write(new_content)
    print(f"  \033[0;32m[✓]\033[0m ล้าง RC block จาก {os.path.basename(path)} ({count} block)")
else:
    # fallback: ลบทีละบรรทัดถ้า pattern ไม่ตรง
    lines = new_content.splitlines(keepends=True)
    filtered = [
        l for l in lines
        if not any(kw in l for kw in [
            '# PhantomSec',
            'alias phantomsec=',
            'PHANTOMSEC_DIR',
        ])
    ]
    if len(filtered) < len(lines):
        with open(path, 'w') as f:
            f.writelines(filtered)
        print(f"  \033[1;33m[!]\033[0m ล้าง RC lines จาก {os.path.basename(path)} (fallback)")
    else:
        print(f"  \033[2m[-]\033[0m ไม่พบ PhantomSec block ใน {os.path.basename(path)}")
PYEOF
}

# ══════════════════════════════════════════════════════════════════════
#  BANNER
# ══════════════════════════════════════════════════════════════════════
clear
echo -e "${R}${BOLD}"
cat << 'BANNER'
  ██╗   ██╗███╗   ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗
  ██║   ██║████╗  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
  ██║   ██║██╔██╗ ██║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║
  ██║   ██║██║╚██╗██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║
  ╚██████╔╝██║ ╚████║██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
   ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
BANNER
echo -e "${NC}"
echo -e "  ${W}PhantomSec OS — Uninstaller v1.1.0${NC}"
echo -e "  ${DIM}─────────────────────────────────────────────────────────${NC}"
echo ""

# ── ยืนยันก่อนลบ ─────────────────────────────────────────────────────
echo -e "${R}${BOLD}  [!] คำเตือน: การลบนี้ไม่สามารถย้อนคืนได้!${NC}"
echo ""
echo -e "  สิ่งที่จะถูกลบ:"
echo -e "  ${DIM}• $PHANTOMSEC_DIR${NC}         (ไฟล์ทั้งหมดของ PhantomSec)"
echo -e "  ${DIM}• $PHANTOMSEC_CONF${NC}  (ไฟล์ config)"
echo -e "  ${DIM}• $PHANTOMSEC_BIN${NC}    (คำสั่ง phantomsec)"
echo -e "  ${DIM}• alias + export ใน .bashrc / .zshrc${NC}"
echo ""
echo -ne "  ${R}แน่ใจว่าต้องการลบ? [y/N]: ${NC}"
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo ""
  warn "ยกเลิกการลบ"
  exit 0
fi

echo ""
echo -e "${M}${BOLD}━━━ กำลังลบ PhantomSec OS ━━━${NC}"
echo ""

# ══════════════════════════════════════════════════════════════════════
#  1. ลบ shell config ก่อน (ก่อนที่ alias จะหายไป)
# ══════════════════════════════════════════════════════════════════════
echo -e "${C}[1/4] ล้าง shell config...${NC}"
clean_rc "$HOME/.bashrc"
clean_rc "$HOME/.zshrc"
# ล้าง fish shell ถ้ามี
if [ -f "$HOME/.config/fish/config.fish" ]; then
  clean_rc "$HOME/.config/fish/config.fish"
fi

echo ""

# ══════════════════════════════════════════════════════════════════════
#  2. ลบ launcher script
# ══════════════════════════════════════════════════════════════════════
echo -e "${C}[2/4] ลบ binary...${NC}"
remove_path "$PHANTOMSEC_BIN"     "bin/phantomsec"

echo ""

# ══════════════════════════════════════════════════════════════════════
#  3. ลบ config folder
# ══════════════════════════════════════════════════════════════════════
echo -e "${C}[3/4] ลบ config...${NC}"
remove_path "$PHANTOMSEC_CONF"    ".config/phantomsec/"

echo ""

# ══════════════════════════════════════════════════════════════════════
#  4. ลบ data directory (wordlists, logs, keys, modules)
# ══════════════════════════════════════════════════════════════════════
echo -e "${C}[4/4] ลบข้อมูล PhantomSec...${NC}"
remove_path "$PHANTOMSEC_DIR"     ".phantomsec/"

echo ""

# ══════════════════════════════════════════════════════════════════════
#  สรุปผล
# ══════════════════════════════════════════════════════════════════════
echo -e "${M}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$removed" -gt 0 ]; then
  echo -e "  ${G}${BOLD}[✓] PhantomSec OS ถูกลบออกสำเร็จ${NC}"
  echo -e "  ${DIM}ลบ: ${removed} รายการ  |  ไม่พบ: ${skipped} รายการ${NC}"
else
  warn "ไม่พบไฟล์ PhantomSec ให้ลบ — อาจถูกลบไปแล้ว"
fi

echo ""
echo -e "  ${Y}[!] เปิด terminal ใหม่เพื่อให้ alias หายไปจาก session ปัจจุบัน${NC}"
echo ""

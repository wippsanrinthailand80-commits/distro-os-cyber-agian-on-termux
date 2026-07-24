#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║              PhantomSec OS — Updater v1.2.0                         ║
# ╚══════════════════════════════════════════════════════════════════════╝

R='\033[0;31m'  G='\033[0;32m'  Y='\033[1;33m'
C='\033[0;36m'  M='\033[0;35m'  W='\033[1;37m'
BOLD='\033[1m'  DIM='\033[2m'   NC='\033[0m'

PHANTOMSEC_BIN="$PREFIX/bin/phantomsec"
PHANTOMSEC_DIR="${PHANTOMSEC_DIR:-$HOME/.phantomsec}"
REPO_URL="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux"

ok()   { echo -e "  ${G}[✓]${NC} $1"; }
warn() { echo -e "  ${Y}[!]${NC} $1"; }
err()  { echo -e "  ${R}[✗]${NC} $1"; }
info() { echo -e "  ${C}[*]${NC} $1"; }

# ─── หา repo dir (ตามตำแหน่ง update.sh) ──────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ถ้ารันจาก $PREFIX/bin หรือ $PHANTOMSEC_DIR ให้หา repo จาก PATH ที่รู้จัก
if [ ! -f "$REPO_DIR/phantomsec.sh" ]; then
  for candidate in \
      "$HOME/distro-os-cyber-agian-on-termux" \
      "$HOME/phantomsec" \
      "$HOME/PhantomSec"; do
    if [ -f "$candidate/phantomsec.sh" ]; then
      REPO_DIR="$candidate"
      break
    fi
  done
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  err "ไม่พบ repo PhantomSec ในเครื่อง"
  echo -e "  ${DIM}clone ก่อนด้วย:${NC}"
  echo -e "  ${C}git clone ${REPO_URL}${NC}"
  exit 1
fi

# ─── Banner ──────────────────────────────────────────────────────────
clear
echo -e "${M}${BOLD}"
cat << 'BANNER'
  ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗
  ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
  ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗
  ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝
  ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗
   ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
BANNER
echo -e "${NC}"
echo -e "  ${DIM}Repo: ${C}${REPO_DIR}${NC}"
echo ""

# ─── เวอร์ชันก่อนอัปเดต ──────────────────────────────────────────────
OLD_VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo 'unknown')"
info "เวอร์ชันปัจจุบัน: ${W}${OLD_VERSION}${NC}"
echo ""

# ─── ตรวจสอบ internet ────────────────────────────────────────────────
echo -ne "  ${C}[*]${NC} ตรวจสอบอินเทอร์เน็ต... "
if ! curl -s --max-time 8 https://github.com > /dev/null 2>&1; then
  echo -e "${R}ไม่มีสัญญาณ${NC}"
  err "กรุณาเชื่อมต่ออินเทอร์เน็ตก่อน"
  exit 1
fi
echo -e "${G}OK${NC}"
echo ""

# ─── git pull ────────────────────────────────────────────────────────
echo -e "${M}${BOLD}━━━ [1/3] ดึงไฟล์ใหม่จาก GitHub ━━━${NC}"
cd "$REPO_DIR" || exit 1

# บันทึก commit ก่อน pull เพื่อแสดง changelog
BEFORE_COMMIT="$(git rev-parse HEAD 2>/dev/null)"

# ตรวจจับ branch ปัจจุบัน แทนการ hardcode main
CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo 'main')"
PULL_OUTPUT="$(git pull origin "$CURRENT_BRANCH" 2>&1)"
PULL_STATUS=$?

echo "$PULL_OUTPUT" | while IFS= read -r line; do
  echo -e "  ${DIM}${line}${NC}"
done

if [ $PULL_STATUS -ne 0 ]; then
  err "git pull ล้มเหลว"
  echo -e "  ${DIM}${PULL_OUTPUT}${NC}"
  exit 1
fi

# เวอร์ชันหลัง pull
NEW_VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo 'unknown')"
echo ""

# ─── copy ไฟล์ทับที่ติดตั้งไว้ ──────────────────────────────────────
echo -e "${M}${BOLD}━━━ [2/3] ติดตั้งไฟล์เวอร์ชันใหม่ ━━━${NC}"

# 1. อัปเดต launcher หลัก ($PREFIX/bin/phantomsec)
if [ -f "$REPO_DIR/phantomsec.sh" ]; then
  cp -f "$REPO_DIR/phantomsec.sh" "$PHANTOMSEC_BIN"
  chmod +x "$PHANTOMSEC_BIN"
  ok "อัปเดต launcher → ${DIM}$PHANTOMSEC_BIN${NC}"
else
  warn "ไม่พบ phantomsec.sh ใน repo"
fi

# 2. อัปเดต VERSION file ไปยัง PHANTOMSEC_DIR (ที่ phantomsec.sh อ่านตอน run จาก $PREFIX/bin)
mkdir -p "$PHANTOMSEC_DIR"
if [ -f "$REPO_DIR/VERSION" ]; then
  cp -f "$REPO_DIR/VERSION" "$PHANTOMSEC_DIR/VERSION"
  ok "อัปเดต VERSION → ${DIM}$PHANTOMSEC_DIR/VERSION${NC}"
fi

# 3. อัปเดต modules
if [ -d "$REPO_DIR/modules" ]; then
  mkdir -p "$PHANTOMSEC_DIR/tools"
  cp -f "$REPO_DIR/modules/"*.sh "$PHANTOMSEC_DIR/tools/" 2>/dev/null && \
    ok "อัปเดต modules → ${DIM}$PHANTOMSEC_DIR/tools/${NC}"
fi

# 4. อัปเดต themes
if [ -d "$REPO_DIR/themes" ]; then
  mkdir -p "$PHANTOMSEC_DIR/themes"
  cp -f "$REPO_DIR/themes/"*.sh "$PHANTOMSEC_DIR/themes/" 2>/dev/null && \
    ok "อัปเดต themes → ${DIM}$PHANTOMSEC_DIR/themes/${NC}"
fi

# 5. อัปเดต config (ถ้ายังไม่เคยแก้เอง)
if [ -f "$REPO_DIR/config/settings.conf" ]; then
  CONF_DEST="$HOME/.config/phantomsec/settings.conf"
  mkdir -p "$HOME/.config/phantomsec"
  if [ ! -f "$CONF_DEST" ]; then
    cp -f "$REPO_DIR/config/settings.conf" "$CONF_DEST"
    ok "เพิ่ม config ใหม่"
  else
    warn "Config มีอยู่แล้ว — ไม่ทับ (แก้เองได้)"
  fi
fi

# 6. อัปเดต scripts ตัวช่วย (update.sh, uninstall.sh)
for helper in update.sh uninstall.sh bootstrap.sh; do
  if [ -f "$REPO_DIR/$helper" ]; then
    cp -f "$REPO_DIR/$helper" "$PREFIX/bin/phantomsec-${helper%.sh}" 2>/dev/null
    chmod +x "$PREFIX/bin/phantomsec-${helper%.sh}" 2>/dev/null
  fi
done
ok "อัปเดต helper scripts"

echo ""

# ─── สรุปผล ──────────────────────────────────────────────────────────
echo -e "${M}${BOLD}━━━ [3/3] สรุปผลการอัปเดต ━━━${NC}"
echo ""

if [ "$OLD_VERSION" != "$NEW_VERSION" ]; then
  echo -e "  ${G}${BOLD}[✓] อัปเดตสำเร็จ!${NC}"
  echo -e "  ${DIM}เวอร์ชัน:${NC}  ${Y}${OLD_VERSION}${NC}  →  ${G}${NEW_VERSION}${NC}"
else
  echo -e "  ${G}[✓] ไฟล์เป็นเวอร์ชันล่าสุดอยู่แล้ว${NC}  ${DIM}(v${NEW_VERSION})${NC}"
fi

# แสดง commit ที่เปลี่ยนไป (ถ้ามี)
AFTER_COMMIT="$(git rev-parse HEAD 2>/dev/null)"
if [ -n "$BEFORE_COMMIT" ] && [ "$BEFORE_COMMIT" != "$AFTER_COMMIT" ]; then
  echo ""
  echo -e "  ${C}Commits ใหม่:${NC}"
  git log --oneline "${BEFORE_COMMIT}..${AFTER_COMMIT}" 2>/dev/null | while IFS= read -r line; do
    echo -e "  ${DIM}  • ${line}${NC}"
  done
fi

echo ""
echo -e "  ${Y}[!] รัน ${C}phantomsec${Y} เพื่อใช้เวอร์ชันใหม่ได้เลย${NC}"
echo ""

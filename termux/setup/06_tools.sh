#!/usr/bin/env bash
# 06_tools.sh — Build PhantomSec tools with Termux clang, install into rootfs
# PhantomSec phantom-proot installer — Step 6
#
# ทำไมถึง build บน Termux แทนที่จะ build ข้างใน proot?
#   — Termux มี clang พร้อมใช้เสมอ ไม่ต้อง apt-get ข้างใน rootfs เลย
#   — Binary ที่ได้เป็น ARM64 native เหมือนกัน — ใช้ได้ใน rootfs โดยตรง
#   — ไม่มีปัญหา "Package has no installation candidate" อีกต่อไป

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 6 — Build PhantomSec tools"
info "Compiling with Termux clang (native ARM64) — no apt-get inside proot needed."

TOOLS_SRC="$INSTALL_DIR/os"
BIN_DEST="$ROOTFS_DIR/usr/local/bin"
mkdir -p "$BIN_DEST"

# ── i18n: check for language flag ────────────────────────────────────────────
LANG_FLAG="${PHANTOMSEC_LANG:-en}"
case "$LANG_FLAG" in
  th) EXTRA_CFLAGS="-DLANG_TH" ; info "Language: Thai (th)" ;;
  *)  EXTRA_CFLAGS=""           ; info "Language: English (en)" ;;
esac

BASE_CFLAGS="-O2 -Wall -Wextra -std=c11 -D_GNU_SOURCE -I${TOOLS_SRC}/i18n $EXTRA_CFLAGS"

# ── Build each tool ───────────────────────────────────────────────────────────
build_tool() {
  local name="$1"
  local src="$2"
  local extra_libs="${3:-}"

  log "Compiling $name..."
  # shellcheck disable=SC2086
  clang $BASE_CFLAGS -o "$BIN_DEST/$name" "$src" $extra_libs \
    && ok "$name → $BIN_DEST/$name" \
    || { warn "Failed to build $name — skipping."; return 0; }
}

build_tool "psh"        "$TOOLS_SRC/tools/psh/psh.c"               "-lm"
build_tool "spectrscan" "$TOOLS_SRC/tools/spectrscan/spectrscan.c"  "-lm"
build_tool "entropyd"   "$TOOLS_SRC/tools/entropyd/entropyd.c"      "-lm"
build_tool "scdna"      "$TOOLS_SRC/tools/scdna/scdna.c"            "-lm"
build_tool "netghost"   "$TOOLS_SRC/tools/netghost/netghost.c"      ""

# ── Also copy into Termux LOCAL_BIN so tools work outside proot too ──────────
for TOOL in psh spectrscan entropyd scdna netghost; do
  [ -f "$BIN_DEST/$TOOL" ] && cp "$BIN_DEST/$TOOL" "$LOCAL_BIN/$TOOL" && chmod +x "$LOCAL_BIN/$TOOL"
done

ok "All PhantomSec tools compiled and installed."
info "Inside rootfs : $BIN_DEST/"
info "On Termux     : $LOCAL_BIN/"

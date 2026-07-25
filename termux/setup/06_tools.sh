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

# Sanity checks
[ -d "$TOOLS_SRC" ]       || err "OS source not found at $TOOLS_SRC\nDid step 2 (clone) succeed?"
[ -x "$(command -v clang 2>/dev/null)" ] || err "clang not found — did step 1 (deps) succeed?"

mkdir -p "$BIN_DEST" "$LOCAL_BIN"

# ── i18n: check for language flag ─────────────────────────────────────────────
LANG_FLAG="${PHANTOMSEC_LANG:-en}"
case "$LANG_FLAG" in
  th) EXTRA_CFLAGS="-DLANG_TH" ; info "Language: Thai (th)" ;;
  *)  EXTRA_CFLAGS=""           ; info "Language: English (en)" ;;
esac

I18N_DIR="$TOOLS_SRC/i18n"
# i18n headers are optional — only add -I flag if the directory exists
I18N_FLAG=""
[ -d "$I18N_DIR" ] && I18N_FLAG="-I${I18N_DIR}"

# shellcheck disable=SC2086
BASE_CFLAGS="-O2 -Wall -Wextra -std=c11 -D_GNU_SOURCE ${I18N_FLAG} ${EXTRA_CFLAGS}"

# ── Build each tool ────────────────────────────────────────────────────────────
build_tool() {
  local name="$1"
  local src="$2"
  local extra_libs="${3:-}"

  if [ ! -f "$src" ]; then
    warn "Source not found: $src — skipping $name."
    return 0
  fi

  log "Compiling $name..."
  # shellcheck disable=SC2086
  if clang $BASE_CFLAGS -o "$BIN_DEST/$name" "$src" $extra_libs; then
    ok "$name → $BIN_DEST/$name"
    # Copy to Termux LOCAL_BIN so tools work outside proot too
    cp "$BIN_DEST/$name" "$LOCAL_BIN/$name" && chmod +x "$LOCAL_BIN/$name"
  else
    warn "Failed to build $name — skipping (install will continue)."
  fi
}

build_tool "psh"        "$TOOLS_SRC/tools/psh/psh.c"               "-lm"
build_tool "spectrscan" "$TOOLS_SRC/tools/spectrscan/spectrscan.c"  "-lm"
build_tool "entropyd"   "$TOOLS_SRC/tools/entropyd/entropyd.c"      "-lm"
build_tool "scdna"      "$TOOLS_SRC/tools/scdna/scdna.c"            "-lm"
build_tool "netghost"   "$TOOLS_SRC/tools/netghost/netghost.c"      ""
build_tool "passgen"    "$TOOLS_SRC/tools/passgen/passgen.c"        ""
build_tool "vulnscan"   "$TOOLS_SRC/tools/vulnscan/vulnscan.c"      ""

# hashcheck needs OpenSSL (EVP API)
if [ -f "$TOOLS_SRC/tools/hashcheck/hashcheck.c" ]; then
  log "Compiling hashcheck (requires OpenSSL)..."
  # shellcheck disable=SC2086
  if clang $BASE_CFLAGS -o "$BIN_DEST/hashcheck" \
      "$TOOLS_SRC/tools/hashcheck/hashcheck.c" -lssl -lcrypto; then
    ok "hashcheck → $BIN_DEST/hashcheck"
    cp "$BIN_DEST/hashcheck" "$LOCAL_BIN/hashcheck" && chmod +x "$LOCAL_BIN/hashcheck"
  else
    warn "Failed to build hashcheck — skipping (install will continue)."
  fi
fi

# ── Install Termux shell tools (ps-*.sh) ──────────────────────────────────────
TERMUX_TOOLS_DIR="$INSTALL_DIR/termux/tools"
if [ -d "$TERMUX_TOOLS_DIR" ]; then
  log "Installing Termux shell tools..."
  for SCRIPT in "$TERMUX_TOOLS_DIR"/ps-*.sh; do
    [ -f "$SCRIPT" ] || continue
    TOOL_NAME="$(basename "$SCRIPT" .sh)"
    cp "$SCRIPT" "$LOCAL_BIN/$TOOL_NAME"
    chmod +x "$LOCAL_BIN/$TOOL_NAME"
    ok "$TOOL_NAME → $LOCAL_BIN/$TOOL_NAME"
  done
fi

ok "PhantomSec tools build complete."
info "Inside rootfs : $BIN_DEST/"
info "On Termux     : $LOCAL_BIN/"

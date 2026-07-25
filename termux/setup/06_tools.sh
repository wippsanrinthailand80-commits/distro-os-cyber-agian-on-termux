#!/usr/bin/env bash
# 06_tools.sh — Build PhantomSec C tools + install shell tools
# PhantomSec OS Termux Edition v2.8.0

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 6 — Build Tools"

TOOLS_SRC="$INSTALL_DIR/os"
BIN_DEST="$ROOTFS_DIR/usr/local/bin"
[ -d "$TOOLS_SRC" ] || err "OS source not found at $TOOLS_SRC"

ensure_dir "$BIN_DEST" "$LOCAL_BIN"

require_cmd clang clang

# ── i18n ────────────────────────────────────────────────────────────────────
I18N_DIR="$TOOLS_SRC/i18n"
I18N_FLAG=""
[ -d "$I18N_DIR" ] && I18N_FLAG="-I${I18N_DIR}"

LANG_FLAG="${PHANTOMSEC_LANG:-en}"
EXTRA_CFLAGS=""
[ "$LANG_FLAG" = "th" ] && EXTRA_CFLAGS="-DLANG_TH"

BASE_CFLAGS="-O2 -Wall -Wextra -std=c11 -D_GNU_SOURCE ${I18N_FLAG} ${EXTRA_CFLAGS}"

# ── Build function ──────────────────────────────────────────────────────────
build_tool() {
  local name="$1" src="$2" libs="${3:-}"
  [ -f "$src" ] || { warn "Source missing: $src — skipping $name."; return 0; }
  log "Compiling $name..."
  if clang $BASE_CFLAGS -o "$BIN_DEST/$name" "$src" $libs 2>/dev/null; then
    ok "$name → $BIN_DEST/$name"
    cp "$BIN_DEST/$name" "$LOCAL_BIN/$name" 2>/dev/null && chmod +x "$LOCAL_BIN/$name"
  else
    warn "Failed to build $name — skipping."
  fi
}

# ── C tools ─────────────────────────────────────────────────────────────────
build_tool "psh"        "$TOOLS_SRC/tools/psh/psh.c"               "-lm"
build_tool "spectrscan" "$TOOLS_SRC/tools/spectrscan/spectrscan.c"  "-lm"
build_tool "entropyd"   "$TOOLS_SRC/tools/entropyd/entropyd.c"      "-lm"
build_tool "scdna"      "$TOOLS_SRC/tools/scdna/scdna.c"            "-lm"
build_tool "netghost"   "$TOOLS_SRC/tools/netghost/netghost.c"      ""
build_tool "passgen"    "$TOOLS_SRC/tools/passgen/passgen.c"        ""
build_tool "vulnscan"   "$TOOLS_SRC/tools/vulnscan/vulnscan.c"      ""

# ── hashcheck (needs OpenSSL) ──────────────────────────────────────────────
if [ -f "$TOOLS_SRC/tools/hashcheck/hashcheck.c" ]; then
  log "Compiling hashcheck (requires OpenSSL)..."
  if clang $BASE_CFLAGS -o "$BIN_DEST/hashcheck" "$TOOLS_SRC/tools/hashcheck/hashcheck.c" -lssl -lcrypto 2>/dev/null; then
    ok "hashcheck → $BIN_DEST/hashcheck"
    cp "$BIN_DEST/hashcheck" "$LOCAL_BIN/hashcheck" 2>/dev/null && chmod +x "$LOCAL_BIN/hashcheck"
  else
    warn "Failed to build hashcheck — skipping."
  fi
fi

# ── Shell tools ─────────────────────────────────────────────────────────────
TERMUX_TOOLS="$INSTALL_DIR/termux/tools"
if [ -d "$TERMUX_TOOLS" ]; then
  log "Installing shell tools..."
  for script in "$TERMUX_TOOLS"/ps-*.sh; do
    [ -f "$script" ] || continue
    name="$(basename "$script" .sh)"
    cp "$script" "$LOCAL_BIN/$name"
    chmod +x "$LOCAL_BIN/$name"
    # Also install into rootfs
    cp "$script" "$BIN_DEST/$name"
    chmod +x "$BIN_DEST/$name"
    ok "$name → $LOCAL_BIN/$name"
  done
fi

ok "Tools build complete."

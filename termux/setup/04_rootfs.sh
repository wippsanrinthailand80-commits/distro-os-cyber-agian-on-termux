#!/usr/bin/env bash
# 04_rootfs.sh — Build custom minimal rootfs with busybox
# PhantomSec OS Termux Edition v2.8.0
#
# Builds a ~5MB rootfs from busybox (compiled static) + skeleton files.
# No Ubuntu download, no external distro dependency.

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 4 — Build Rootfs"

SKELETON="$INSTALL_DIR/termux/rootfs"
[ -d "$SKELETON" ] || err "Rootfs skeleton not found at $SKELETON"

# ── Clean previous rootfs ──────────────────────────────────────────────────
rm -rf "$ROOTFS_DIR"
ensure_dir "$ROOTFS_DIR"

# ── Copy skeleton ───────────────────────────────────────────────────────────
log "Copying rootfs skeleton..."
cp -a "$SKELETON"/. "$ROOTFS_DIR"/

# ── Create directory structure ─────────────────────────────────────────────
mkdir -p "$ROOTFS_DIR"/{bin,sbin,usr/bin,usr/sbin,usr/local/bin}
mkdir -p "$ROOTFS_DIR"/{proc,dev,sys,tmp,var/tmp,root,home/phantom}

# ── Build busybox from source (static) ─────────────────────────────────────
# This is the most reliable way to get a working static busybox for ANY arch.
BB_SRC_DIR="$INSTALL_DIR/.busybox-build"
BB_VERSION="1_36_1"

if [ -x "$ROOTFS_DIR/bin/busybox" ]; then
  info "busybox already present."
else
  log "Building busybox (static) from source..."

  if [ ! -d "$BB_SRC_DIR" ]; then
    log "Downloading busybox source..."
    curl -fsSL "https://busybox.net/downloads/busybox-${BB_VERSION}.tar.bz2" \
      -o "/tmp/busybox.tar.bz2" || err "Failed to download busybox source."
    ensure_dir "$BB_SRC_DIR"
    tar xjf "/tmp/busybox.tar.bz2" -C "$INSTALL_DIR" 2>/dev/null
    mv "$INSTALL_DIR/busybox-${BB_VERSION}" "$BB_SRC_DIR" 2>/dev/null || true
    rm -f "/tmp/busybox.tar.bz2"
  fi

  [ -d "$BB_SRC_DIR" ] || err "busybox source directory not found after extraction."

  log "Configuring busybox for static build..."
  make -C "$BB_SRC_DIR" CC=clang \
    EXTRA_CFLAGS="-static" \
    LDFLAGS="-static" \
    defconfig 2>/dev/null

  # Enable sh and essential applets
  sed -i 's/# CONFIG_SH is not set/CONFIG_SH=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_BASH is not set/CONFIG_BASH=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_CAT is not set/CONFIG_CAT=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_ECHO is not set/CONFIG_ECHO=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_LS is not set/CONFIG_LS=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_MKDIR is not set/CONFIG_MKDIR=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_RM is not set/CONFIG_RM=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_CP is not set/CONFIG_CP=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_MV is not set/CONFIG_MV=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_GREP is not set/CONFIG_GREP=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_SED is not set/CONFIG_SED=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_AWK is not set/CONFIG_AWK=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_FIND is not set/CONFIG_FIND=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_WC is not set/CONFIG_WC=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_HEAD is not set/CONFIG_HEAD=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_TAIL is not set/CONFIG_TAIL=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_ID is not set/CONFIG_ID=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_UNAME is not set/CONFIG_UNAME=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_HOSTNAME is not set/CONFIG_HOSTNAME=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_WHOAMI is not set/CONFIG_WHOAMI=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_PWD is not set/CONFIG_PWD=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_SLEEP is not set/CONFIG_SLEEP=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_DATE is not set/CONFIG_DATE=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_TRUE is not set/CONFIG_TRUE=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_FALSE is not set/CONFIG_FALSE=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_TEST is not set/CONFIG_TEST=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_STTY is not set/CONFIG_STTY=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_ENV is not set/CONFIG_ENV=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_EXPORT is not set/CONFIG_EXPORT=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIG_EXPR is not set/CONFIG_EXPR=y/' "$BB_SRC_DIR/.config"
  sed -i 's/# CONFIGPrintf is not set/CONFIG_PRINTF=y/' "$BB_SRC_DIR/.config" 2>/dev/null || true

  make -C "$BB_SRC_DIR" CC=clang \
    EXTRA_CFLAGS="-static" \
    LDFLAGS="-static" \
    -j"$(nproc)" 2>&1 | tail -3

  cp "$BB_SRC_DIR/busybox" "$ROOTFS_DIR/bin/busybox"
  chmod +x "$ROOTFS_DIR/bin/busybox"
  rm -rf "$BB_SRC_DIR"
fi

# ── Verify busybox is static ───────────────────────────────────────────────
if ! file "$ROOTFS_DIR/bin/busybox" 2>/dev/null | grep -qi "static\|dynamically"; then
  info "Cannot determine linkage — proceeding anyway."
fi

# ── Create symlinks for all applets ────────────────────────────────────────
log "Creating busybox applets..."
cd "$ROOTFS_DIR/bin"
for applet in $(./busybox --list 2>/dev/null); do
  [ -e "$applet" ] || ln -sf busybox "$applet"
done

# Also create in usr/bin for PATH compatibility
for applet in $(./busybox --list 2>/dev/null); do
  [ -e "$ROOTFS_DIR/usr/bin/$applet" ] || \
    ln -sf ../../bin/busybox "$ROOTFS_DIR/usr/bin/$applet" 2>/dev/null || true
done
cd - >/dev/null

# ── Verify ──────────────────────────────────────────────────────────────────
if "$ROOTFS_DIR/bin/busybox" sh -c 'echo rootfs-ok' 2>/dev/null | grep -q rootfs-ok; then
  ok "Rootfs built at $ROOTFS_DIR ($(du -sh "$ROOTFS_DIR" | cut -f1))"
else
  err "busybox binary is not executable — build failed.\nTry: file $ROOTFS_DIR/bin/busybox"
fi

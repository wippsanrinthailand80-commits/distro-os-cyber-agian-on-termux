#!/usr/bin/env bash
# 04_rootfs.sh — Build custom minimal rootfs with busybox
# PhantomSec OS Termux Edition v2.8.0
#
# Builds a ~5MB rootfs from static busybox + skeleton files.
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

# ── Get static busybox ─────────────────────────────────────────────────────
BB_BIN="$ROOTFS_DIR/bin/busybox"
ARCH="$(uname -m)"

download_busybox() {
  local url="$1" label="$2"
  log "Trying $label..."
  if curl -fsSL "$url" -o "$BB_BIN" 2>/dev/null && chmod +x "$BB_BIN" && \
     "$BB_BIN" --list >/dev/null 2>&1; then
    return 0
  fi
  rm -f "$BB_BIN"
  return 1
}

build_busybox_static() {
  log "Building busybox from source (static)..."
  local src="/tmp/busybox-src"
  rm -rf "$src"
  curl -fsSL "https://busybox.net/downloads/busybox-1.36.1.tar.bz2" -o /tmp/bb.tar.bz2 || return 1
  tar xjf /tmp/bb.tar.bz2 -C /tmp 2>/dev/null
  mv /tmp/busybox-1.36.1 "$src" 2>/dev/null
  rm -f /tmp/bb.tar.bz2
  [ -d "$src" ] || return 1

  make -C "$src" CC=clang defconfig 2>/dev/null
  make -C "$src" CC=clang \
    EXTRA_CFLAGS="-static" LDFLAGS="-static" \
    -j"$(nproc)" 2>/dev/null | tail -2
  cp "$src/busybox" "$BB_BIN"
  rm -rf "$src"
}

if [ -x "$BB_BIN" ]; then
  info "busybox already present."
else
  # Try pre-built static binaries first (fast), then compile (slow)
  if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    download_busybox "https://busybox.net/downloads/binaries/1.35.0-aarch64-linux-musl/busybox" "busybox.net aarch64" ||
    download_busybox "https://raw.githubusercontent.com/nicholasgasior/busybox-static/master/busybox-aarch64" "github nicholasgasior" ||
    build_busybox_static ||
    err "Failed to get busybox. Check your internet connection."
  elif [ "$ARCH" = "x86_64" ]; then
    download_busybox "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox" "busybox.net x86_64" ||
    build_busybox_static ||
    err "Failed to get busybox."
  else
    build_busybox_static || err "Failed to build busybox for $ARCH."
  fi
fi

# ── Verify binary works ───────────────────────────────────────────────────
if ! "$BB_BIN" sh -c 'echo ok' 2>/dev/null | grep -q ok; then
  err "busybox binary is broken. Try: file $BB_BIN"
fi

# ── Create symlinks for all applets ────────────────────────────────────────
log "Creating busybox applets..."
cd "$ROOTFS_DIR/bin"
for applet in $($BB_BIN --list 2>/dev/null); do
  [ -e "$applet" ] || ln -sf busybox "$applet"
done

# usr/bin symlink for PATH compatibility
for applet in $($BB_BIN --list 2>/dev/null); do
  [ -e "$ROOTFS_DIR/usr/bin/$applet" ] || \
    ln -sf ../../bin/busybox "$ROOTFS_DIR/usr/bin/$applet" 2>/dev/null || true
done
cd - >/dev/null

ok "Rootfs built at $ROOTFS_DIR ($(du -sh "$ROOTFS_DIR" | cut -f1))"

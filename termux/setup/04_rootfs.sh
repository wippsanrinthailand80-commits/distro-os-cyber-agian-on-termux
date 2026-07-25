#!/usr/bin/env bash
# 04_rootfs.sh — Build custom minimal rootfs with busybox
# PhantomSec OS Termux Edition v2.8.0
#
# Instead of downloading Ubuntu (70MB+), we build a ~5MB rootfs
# from busybox + our skeleton files. Faster, smaller, fully controlled.

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 4 — Build Rootfs"

SKELETON="$INSTALL_DIR/termux/rootfs"
[ -d "$SKELETON" ] || err "Rootfs skeleton not found at $SKELETON"

# ── Clean previous rootfs ──────────────────────────────────────────────────
rm -rf "$ROOTFS_DIR"
ensure_dir "$ROOTFS_DIR"

# ── Copy skeleton (etc/, home/, etc.) ──────────────────────────────────────
log "Copying rootfs skeleton..."
cp -a "$SKELETON"/. "$ROOTFS_DIR"/

# ── Create directory structure ─────────────────────────────────────────────
mkdir -p "$ROOTFS_DIR"/{bin,sbin,usr/bin,usr/sbin,usr/local/bin}
mkdir -p "$ROOTFS_DIR"/{proc,dev,sys,tmp,var/tmp,root}

# ── Download busybox static binary ─────────────────────────────────────────
BUSYBOX_URL="https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox"
BUSYBOX_ARM_URL="https://busybox.net/downloads/binaries/1.35.0-aarch64-linux-musl/busybox"

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) BUSYBOX_URL="$BUSYBOX_ARM_URL" ;;
esac

if [ -x "$ROOTFS_DIR/bin/busybox" ]; then
  info "busybox already present."
else
  log "Downloading busybox static binary for $ARCH..."
  curl -fsSL "$BUSYBOX_URL" -o "$ROOTFS_DIR/bin/busybox" || {
    warn "Download failed — trying Termux package busybox..."
    # Fallback: copy busybox from Termux
    if command -v busybox &>/dev/null; then
      cp "$(command -v busybox)" "$ROOTFS_DIR/bin/busybox"
    else
      pkg install -y busybox 2>/dev/null
      cp "$(command -v busybox)" "$ROOTFS_DIR/bin/busybox"
    fi
  }
  chmod +x "$ROOTFS_DIR/bin/busybox"
fi

# ── Create symlinks for all busybox applets ────────────────────────────────
log "Creating busybox applets..."
cd "$ROOTFS_DIR/bin"
for applet in $(./busybox --list 2>/dev/null); do
  [ -e "$applet" ] || ln -sf busybox "$applet"
done

# Also create in usr/bin and usr/sbin for compatibility
for applet in $(./busybox --list 2>/dev/null); do
  [ -e "$ROOTFS_DIR/usr/bin/$applet" ] || ln -sf ../../bin/busybox "$ROOTFS_DIR/usr/bin/$applet" 2>/dev/null || true
done

cd - >/dev/null

# ── Verify ──────────────────────────────────────────────────────────────────
if "$ROOTFS_DIR/bin/busybox" sh -c 'echo rootfs-ok' 2>/dev/null | grep -q rootfs-ok; then
  ok "Rootfs built at $ROOTFS_DIR ($(du -sh "$ROOTFS_DIR" | cut -f1))"
else
  err "busybox binary is not executable — build failed."
fi

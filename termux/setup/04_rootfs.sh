#!/usr/bin/env bash
# 04_rootfs.sh — Build custom minimal rootfs with busybox
# PhantomSec OS Termux Edition v2.8.0

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

get_busybox() {
  local url="$1"
  log "Downloading busybox static ($url)..."
  curl -fsSL --connect-timeout 10 --max-time 60 "$url" -o "$BB_BIN" 2>/dev/null
  chmod +x "$BB_BIN"
  "$BB_BIN" --list >/dev/null 2>&1
}

if [ -x "$BB_BIN" ]; then
  info "busybox already present."
else
  GOT_BB=0

  # Source 1: Alpine Linux package (guaranteed static musl binary)
  if [ "$GOT_BB" -eq 0 ]; then
    ALPINE_VER="3.20"
    case "$ARCH" in
      aarch64|arm64) ALPINE_ARCH="aarch64" ;;
      x86_64)        ALPINE_ARCH="x86_64" ;;
      armv7l)        ALPINE_ARCH="armv7" ;;
      *)             ALPINE_ARCH="x86_64" ;;
    esac
    APK_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/main/${ALPINE_ARCH}/busybox-static-1.36.1-r31.apk"
    if curl -fsSL --connect-timeout 10 --max-time 60 "$APK_URL" -o /tmp/busybox.apk 2>/dev/null; then
      # .apk files are just tar.gz — extract busybox from it
      tar xzf /tmp/busybox.apk -C /tmp 2>/dev/null
      # Alpine names it busybox.static
      if [ -f /tmp/bin/busybox.static ]; then
        cp /tmp/bin/busybox.static "$BB_BIN"
        chmod +x "$BB_BIN"
        GOT_BB=1
        ok "Got busybox from Alpine Linux."
      fi
      rm -rf /tmp/bin /tmp/busybox.apk
    fi
  fi

  # Source 2: busybox.net pre-built
  if [ "$GOT_BB" -eq 0 ]; then
    BB_VER="1.36.1"
    case "$ARCH" in
      aarch64|arm64) URL="https://busybox.net/downloads/binaries/${BB_VER}-aarch64-linux-musl/busybox" ;;
      x86_64)        URL="https://busybox.net/downloads/binaries/${BB_VER}-x86_64-linux-musl/busybox" ;;
    esac
    if [ -n "${URL:-}" ] && get_busybox "$URL"; then
      GOT_BB=1
      ok "Got busybox from busybox.net."
    fi
  fi

  # Source 3: Termux package (fallback — may be dynamic)
  if [ "$GOT_BB" -eq 0 ]; then
    warn "Trying Termux busybox package (may not work inside rootfs)..."
    pkg install -y busybox 2>/dev/null || true
    if command -v busybox &>/dev/null; then
      cp "$(command -v busybox)" "$BB_BIN"
      chmod +x "$BB_BIN"
      GOT_BB=1
    fi
  fi

  [ "$GOT_BB" -eq 1 ] || err "Failed to get busybox from all sources.\nCheck your internet connection and try again."
fi

# ── Verify ──────────────────────────────────────────────────────────────────
if ! "$BB_BIN" sh -c 'echo ok' 2>/dev/null | grep -q ok; then
  err "busybox binary is broken: file $BB_BIN"
fi

# ── Create symlinks ────────────────────────────────────────────────────────
log "Creating busybox applets..."
cd "$ROOTFS_DIR/bin"
for applet in $($BB_BIN --list 2>/dev/null); do
  [ -e "$applet" ] || ln -sf busybox "$applet"
done
for applet in $($BB_BIN --list 2>/dev/null); do
  [ -e "$ROOTFS_DIR/usr/bin/$applet" ] || \
    ln -sf ../../bin/busybox "$ROOTFS_DIR/usr/bin/$applet" 2>/dev/null || true
done
cd - >/dev/null

ok "Rootfs built at $ROOTFS_DIR ($(du -sh "$ROOTFS_DIR" | cut -f1))"

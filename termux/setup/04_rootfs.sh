#!/usr/bin/env bash
# 04_rootfs.sh — Build custom minimal rootfs with busybox
# PhantomSec OS Termux Edition v2.8.0

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 4 — Build Rootfs"

SKELETON="$INSTALL_DIR/termux/rootfs"
[ -d "$SKELETON" ] || err "Rootfs skeleton not found at $SKELETON"

# ── Pre-flight checks ──────────────────────────────────────────────────────
# Check disk space (need at least 10MB)
AVAIL_KB=$(df -k "$HOME" 2>/dev/null | awk 'NR==2{print $4}' || echo 0)
if [ "$AVAIL_KB" -gt 0 ] && [ "$AVAIL_KB" -lt 10240 ]; then
  err "Not enough disk space: $((AVAIL_KB / 1024))MB available, need at least 10MB.\nFree some space and try again."
fi

# ── Clean previous rootfs ──────────────────────────────────────────────────
rm -rf "$ROOTFS_DIR"
ensure_dir "$ROOTFS_DIR"
[ -d "$ROOTFS_DIR" ] || err "Failed to create $ROOTFS_DIR"

# ── Copy skeleton ───────────────────────────────────────────────────────────
log "Copying rootfs skeleton..."
cp -a "$SKELETON"/. "$ROOTFS_DIR"/

# ── Create directory structure ─────────────────────────────────────────────
log "Creating directory structure..."
mkdir -p "$ROOTFS_DIR"/{bin,sbin,usr/bin,usr/sbin,usr/local/bin}
mkdir -p "$ROOTFS_DIR"/{proc,dev,sys,tmp,var/tmp,root,home/phantom}

# Verify key directories exist
for d in bin usr/bin usr/local/bin home/phantom; do
  [ -d "$ROOTFS_DIR/$d" ] || err "Failed to create $ROOTFS_DIR/$d"
done

# ── Get static busybox ─────────────────────────────────────────────────────
BB_BIN="$ROOTFS_DIR/bin/busybox"
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) ALPINE_ARCH="aarch64" ;;
  x86_64)        ALPINE_ARCH="x86_64" ;;
  armv7l)        ALPINE_ARCH="armv7" ;;
  *)             ALPINE_ARCH="aarch64"; warn "Unknown arch $ARCH — trying aarch64." ;;
esac

if [ -x "$BB_BIN" ] && "$BB_BIN" sh -c 'echo ok' 2>/dev/null | grep -q ok; then
  info "busybox already present and working."
else
  # ── Source 1: Alpine Linux (only reliable source for static aarch64) ───
  ALPINE_VER="3.20"
  APK_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/main/${ALPINE_ARCH}/busybox-static-1.36.1-r31.apk"
  APK_TMP="/tmp/phantomsec-busybox.apk"
  BB_EXTRACTED="/tmp/phantomsec-bb/bin/busybox.static"

  GOT_BB=0
  for ATTEMPT in 1 2 3; do
    log "Downloading static busybox (attempt $ATTEMPT/3)..."
    rm -f "$APK_TMP"

    if ! curl -fsSL --connect-timeout 15 --max-time 120 \
         -o "$APK_TMP" "$APK_URL" 2>/dev/null; then
      warn "Download failed (attempt $ATTEMPT)."
      sleep 2
      continue
    fi

    # Verify the downloaded file is a valid gzip
    if ! gunzip -t "$APK_TMP" 2>/dev/null; then
      warn "Downloaded file is corrupted (attempt $ATTEMPT)."
      rm -f "$APK_TMP"
      sleep 2
      continue
    fi

    # Extract busybox from .apk (tar.gz)
    rm -rf /tmp/phantomsec-bb
    mkdir -p /tmp/phantomsec-bb
    if ! tar xzf "$APK_TMP" -C /tmp/phantomsec-bb 2>/dev/null; then
      warn "Extraction failed (attempt $ATTEMPT)."
      rm -rf /tmp/phantomsec-bb "$APK_TMP"
      sleep 2
      continue
    fi

    if [ ! -f "$BB_EXTRACTED" ]; then
      warn "busybox.static not found in archive (attempt $ATTEMPT)."
      rm -rf /tmp/phantomsec-bb "$APK_TMP"
      sleep 2
      continue
    fi

    # Copy to rootfs
    cp "$BB_EXTRACTED" "$BB_BIN"
    chmod +x "$BB_BIN"
    rm -rf /tmp/phantomsec-bb "$APK_TMP"
    GOT_BB=1
    break
  done

  # ── Source 2: Compile from source (slow but guaranteed) ────────────────
  if [ "$GOT_BB" -eq 0 ]; then
    warn "Alpine download failed. Compiling busybox from source (may take a minute)..."
    BB_SRC_DIR="/tmp/phantomsec-bb-src"
    rm -rf "$BB_SRC_DIR"

    if curl -fsSL --connect-timeout 15 --max-time 120 \
         "https://busybox.net/downloads/busybox-1.36.1.tar.bz2" \
         -o /tmp/phantomsec-bb.tar.bz2 2>/dev/null; then
      tar xjf /tmp/phantomsec-bb.tar.bz2 -C /tmp 2>/dev/null
      mv /tmp/busybox-1.36.1 "$BB_SRC_DIR" 2>/dev/null || true
      rm -f /tmp/phantomsec-bb.tar.bz2

      if [ -d "$BB_SRC_DIR" ]; then
        log "Configuring busybox (static build)..."
        make -C "$BB_SRC_DIR" defconfig 2>/dev/null
        # Enable essential applets
        for cfg in CONFIG_SH CONFIG_BASH CONFIG_CAT CONFIG_ECHO CONFIG_LS \
                   CONFIG_MKDIR CONFIG_RM CONFIG_CP CONFIG_MV CONFIG_GREP \
                   CONFIG_SED CONFIG_AWK CONFIG_FIND CONFIG_WC CONFIG_ID \
                   CONFIG_UNAME CONFIG_HOSTNAME CONFIG_PWD CONFIG_SLEEP; do
          sed -i "s/# ${cfg} is not set/${cfg}=y/" "$BB_SRC_DIR/.config" 2>/dev/null || true
        done

        log "Compiling busybox..."
        make -C "$BB_SRC_DIR" CC=clang \
          EXTRA_CFLAGS="-static" LDFLAGS="-static" \
          -j"$(nproc)" 2>/dev/null | tail -2

        if [ -f "$BB_SRC_DIR/busybox" ]; then
          cp "$BB_SRC_DIR/busybox" "$BB_BIN"
          chmod +x "$BB_BIN"
          GOT_BB=1
          ok "Compiled busybox from source."
        fi
        rm -rf "$BB_SRC_DIR"
      fi
    fi
    rm -f /tmp/phantomsec-bb.tar.bz2
  fi

  [ "$GOT_BB" -eq 1 ] || err "Failed to get busybox.\nCheck internet connection and disk space.\nTry: df -h $HOME"
fi

# ── Verify busybox works ───────────────────────────────────────────────────
if ! "$BB_BIN" sh -c 'echo ok' 2>/dev/null | grep -q ok; then
  err "busybox binary exists but doesn't work.\nFile: $BB_BIN\nTry: ls -la $BB_BIN"
fi

# Count applets
APPLET_COUNT=$("$BB_BIN" --list 2>/dev/null | wc -l)
info "busybox: $APPLET_COUNT applets available."

# ── Create symlinks ────────────────────────────────────────────────────────
log "Creating busybox applets..."
cd "$ROOTFS_DIR/bin"
for applet in $($BB_BIN --list 2>/dev/null); do
  [ -e "$applet" ] || ln -sf busybox "$applet"
done
cd - >/dev/null

# usr/bin symlinks for PATH compatibility
mkdir -p "$ROOTFS_DIR/usr/bin"
cd "$ROOTFS_DIR/usr/bin"
for applet in $($BB_BIN --list 2>/dev/null); do
  [ -e "$applet" ] || ln -sf ../../bin/busybox "$applet" 2>/dev/null || true
done
cd - >/dev/null

# ── Final verification ─────────────────────────────────────────────────────
ROOTFS_SIZE=$(du -sh "$ROOTFS_DIR" | cut -f1)
if "$BB_BIN" sh -c 'echo verify-ok' 2>/dev/null | grep -q verify-ok; then
  ok "Rootfs built: $ROOTFS_SIZE ($APPLET_COUNT applets) → $ROOTFS_DIR"
else
  err "Rootfs verification failed."
fi

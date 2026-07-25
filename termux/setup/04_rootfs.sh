#!/usr/bin/env bash
# 04_rootfs.sh — Download and extract Ubuntu ARM64 minimal rootfs
# PhantomSec phantom-proot installer — Step 4

set -euo pipefail
source "$(dirname "$0")/_common.sh"

step "Step 4 — Ubuntu ARM64 rootfs"

# Ubuntu 22.04 LTS (Jammy) ARM64 minimal base image
ROOTFS_TAR="/tmp/phantomsec-rootfs.tar.gz"
ROOTFS_URL="https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-arm64-root.tar.gz"

if [ -d "$ROOTFS_DIR/bin" ] && [ -d "$ROOTFS_DIR/etc" ]; then
  warn "Rootfs already exists at $ROOTFS_DIR — skipping download."
  info "Delete $ROOTFS_DIR to force re-download."
else
  log "Downloading Ubuntu 22.04 LTS ARM64 minimal rootfs (~30 MB)..."
  info "URL: $ROOTFS_URL"
  curl -L --progress-bar -o "$ROOTFS_TAR" "$ROOTFS_URL" \
    || err "Download failed. Check your internet connection."

  log "Extracting rootfs to $ROOTFS_DIR ..."
  mkdir -p "$ROOTFS_DIR"
  tar -xf "$ROOTFS_TAR" -C "$ROOTFS_DIR" \
    || err "Extraction failed — archive may be corrupt. Delete /tmp/phantomsec-rootfs.tar.gz and retry."
  rm -f "$ROOTFS_TAR"
  ok "Ubuntu rootfs extracted → $ROOTFS_DIR"
fi

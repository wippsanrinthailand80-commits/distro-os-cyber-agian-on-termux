#!/usr/bin/env bash
# 04_rootfs.sh — Download and extract Ubuntu ARM64 minimal rootfs
# PhantomSec phantom-proot installer — Step 4

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 4 — Ubuntu ARM64 rootfs"

# Use unique temp file to prevent symlink/race attacks
ROOTFS_TAR="$(mktemp "${TMPDIR:-/tmp}/phantomsec-rootfs.XXXXXX.tar.gz")"

# Cleanup trap for partial downloads
cleanup_rootfs() {
  rm -f "$ROOTFS_TAR"
}
trap cleanup_rootfs EXIT

# Multiple URL fallbacks — tried in order until one works
ROOTFS_URLS=(
  "https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-arm64.tar.gz"
  "https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-arm64-root.tar.gz"
)

if [ -d "$ROOTFS_DIR/bin" ] && [ -d "$ROOTFS_DIR/etc" ]; then
  warn "Rootfs already exists at $ROOTFS_DIR — skipping download."
  info "Delete $ROOTFS_DIR to force re-download."
else
  # ── Download with fallback URLs ─────────────────────────────────────────────
  rm -f "$ROOTFS_TAR"
  DOWNLOADED=0
  for URL in "${ROOTFS_URLS[@]}"; do
    log "Trying: $URL"
    if curl -fsSL --max-time 300 --retry 3 --retry-delay 5 \
        -o "$ROOTFS_TAR" "$URL" 2>/dev/null; then
      # Validate file exists and has content
      SIZE=$(wc -c < "$ROOTFS_TAR" 2>/dev/null || echo 0)
      if [ "$SIZE" -lt 1048576 ]; then
        warn "File too small (${SIZE} bytes) — not a valid rootfs"
        rm -f "$ROOTFS_TAR"
        continue
      fi

      # Check if file is actually HTML (redirect/error page)
      FILE_TYPE=$(file -b "$ROOTFS_TAR" 2>/dev/null || echo "unknown")
      if echo "$FILE_TYPE" | grep -qi "html\|text\|ascii"; then
        warn "Downloaded file is $FILE_TYPE, not a tarball — server may be returning error page"
        rm -f "$ROOTFS_TAR"
        continue
      fi

      # Verify gzip integrity
      if ! gzip -t "$ROOTFS_TAR" 2>/dev/null; then
        warn "Gzip integrity check failed — file may be corrupt"
        rm -f "$ROOTFS_TAR"
        continue
      fi

      # Check it's actually a tar archive
      if ! tar -tzf "$ROOTFS_TAR" >/dev/null 2>&1; then
        warn "Not a valid tar.gz archive"
        rm -f "$ROOTFS_TAR"
        continue
      fi

      ok "Downloaded $(( SIZE / 1024 / 1024 )) MB — validation OK"
      DOWNLOADED=1
      break
    else
      warn "Download failed from $URL — trying next..."
      rm -f "$ROOTFS_TAR"
    fi
  done

  [ "$DOWNLOADED" -eq 1 ] || err "All rootfs URLs failed.\nCheck internet connection and try again."

  # ── Extract ─────────────────────────────────────────────────────────────────
  log "Extracting rootfs to $ROOTFS_DIR ..."
  mkdir -p "$ROOTFS_DIR"

  # Try extraction with verbose error output for debugging
  EXTRACTION_OK=0

  # Method 1: gzip + tar (most compatible with Termux)
  log "Attempting extraction (method: gzip pipe)..."
  if gzip -dc "$ROOTFS_TAR" | tar -xf - -C "$ROOTFS_DIR" 2>&1; then
    EXTRACTION_OK=1
  fi

  # Method 2: tar -xzf
  if [ "$EXTRACTION_OK" -eq 0 ]; then
    log "Attempting extraction (method: tar -xzf)..."
    # Clean hidden files too (rm -rf * misses dotfiles)
    find "$ROOTFS_DIR" -mindepth 1 -delete 2>/dev/null || rm -rf "$ROOTFS_DIR"/*
    if tar -xzf "$ROOTFS_TAR" -C "$ROOTFS_DIR" 2>&1; then
      EXTRACTION_OK=1
    fi
  fi

  # Method 3: tar -xf (auto-detect compression)
  if [ "$EXTRACTION_OK" -eq 0 ]; then
    log "Attempting extraction (method: tar -xf)..."
    find "$ROOTFS_DIR" -mindepth 1 -delete 2>/dev/null || rm -rf "$ROOTFS_DIR"/*
    if tar -xf "$ROOTFS_TAR" -C "$ROOTFS_DIR" 2>&1; then
      EXTRACTION_OK=1
    fi
  fi

  if [ "$EXTRACTION_OK" -eq 1 ]; then
    # Verify extraction produced a valid rootfs
    if [ -d "$ROOTFS_DIR/bin" ] && [ -d "$ROOTFS_DIR/etc" ]; then
      ok "Rootfs extracted → $ROOTFS_DIR"
    else
      warn "Extraction completed but rootfs looks incomplete (missing /bin or /etc)"
      info "Contents of $ROOTFS_DIR:"
      ls -la "$ROOTFS_DIR" 2>/dev/null | head -20
      rm -f "$ROOTFS_TAR"
      err "Incomplete rootfs extraction. Run the installer again."
    fi
  else
    rm -f "$ROOTFS_TAR"
    err "Extraction failed — archive corrupt or unsupported format.\nDeleted: $ROOTFS_TAR\nRun the installer again to re-download."
  fi

  rm -f "$ROOTFS_TAR"
fi

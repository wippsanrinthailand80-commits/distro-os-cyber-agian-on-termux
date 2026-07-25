#!/usr/bin/env bash
# 05_configure.sh — Configure the rootfs
# PhantomSec OS Termux Edition v2.8.0

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 5 — Configure Rootfs"

[ -d "$ROOTFS_DIR/bin" ] || err "Rootfs not found at $ROOTFS_DIR"

# ── Ensure /proc /dev /sys mount points exist ──────────────────────────────
mkdir -p "$ROOTFS_DIR"/{proc,dev,sys,tmp,var/tmp,root}

# ── Set hostname ────────────────────────────────────────────────────────────
echo "phantomsec" > "$ROOTFS_DIR/etc/hostname"

# ── DNS resolution ──────────────────────────────────────────────────────────
cat > "$ROOTFS_DIR/etc/resolv.conf" << 'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 208.67.222.222
EOF

# ── /etc/hosts ──────────────────────────────────────────────────────────────
cat > "$ROOTFS_DIR/etc/hosts" << 'EOF'
127.0.0.1 localhost phantomsec
::1       localhost phantomsec
EOF

# ── /etc/passwd ─────────────────────────────────────────────────────────────
cat > "$ROOTFS_DIR/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/sh
phantom:x:1000:1000:phantom:/home/phantom:/bin/sh
EOF

# ── /etc/group ──────────────────────────────────────────────────────────────
cat > "$ROOTFS_DIR/etc/group" << 'EOF'
root:x:0:
phantom:x:1000:
EOF

# ── /etc/profile — login environment ───────────────────────────────────────
cat > "$ROOTFS_DIR/etc/profile" << 'PROFILE'
export HOME=/home/phantom
export PATH=/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin
export TERM=xterm-256color
export LANG=C.UTF-8
export USER=phantom
export LOGNAME=phantom

# PhantomSec prompt
PS1='\[\033[1;32m\]phantom\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$ '
export PS1
PROFILE

# ── User home directory ─────────────────────────────────────────────────────
mkdir -p "$ROOTFS_DIR/home/phantom"
cat > "$ROOTFS_DIR/home/phantom/.profile" << 'EOF'
. /etc/profile
EOF

ok "Rootfs configured."

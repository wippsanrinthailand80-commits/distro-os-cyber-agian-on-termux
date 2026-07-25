#!/usr/bin/env bash
# 05_configure.sh — Configure rootfs basics
# PhantomSec phantom-proot installer — Step 5

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 5 — Configure rootfs"

# Sanity check — rootfs must exist after step 4
[ -d "$ROOTFS_DIR/bin" ] || err "Rootfs not found at $ROOTFS_DIR\nDid step 4 (rootfs download) succeed?"

# Essential mount-point directories (list form avoids brace-expansion quoting pitfalls)
for d in proc dev sys tmp run root; do
  mkdir -p "$ROOTFS_DIR/$d"
done

# DNS
cat > "$ROOTFS_DIR/etc/resolv.conf" << 'DNS'
nameserver 8.8.8.8
nameserver 1.1.1.1
DNS

# Hostname
echo "phantomsec" > "$ROOTFS_DIR/etc/hostname"

# /etc/hosts
cat > "$ROOTFS_DIR/etc/hosts" << 'HOSTS'
127.0.0.1   localhost
127.0.1.1   phantomsec
::1         localhost ip6-localhost ip6-loopback
HOSTS

# APT sources — detect architecture for correct mirror
ARCH="$(uname -m)"
if [ "$ARCH" = "x86_64" ]; then
  APT_MIRROR="https://archive.ubuntu.com/ubuntu"
else
  APT_MIRROR="https://ports.ubuntu.com/ubuntu-ports"
fi

cat > "$ROOTFS_DIR/etc/apt/sources.list" << SOURCES
deb ${APT_MIRROR} jammy           main restricted universe multiverse
deb ${APT_MIRROR} jammy-updates   main restricted universe multiverse
deb ${APT_MIRROR} jammy-security  main restricted universe multiverse
SOURCES

# APT options: non-interactive, no recommends
mkdir -p "$ROOTFS_DIR/etc/apt/apt.conf.d"
cat > "$ROOTFS_DIR/etc/apt/apt.conf.d/99phantomsec" << 'APTCONF'
APT::Get::Assume-Yes "true";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APTCONF

ok "Rootfs configured (DNS, hostname, hosts, apt sources)."

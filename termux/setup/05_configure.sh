#!/usr/bin/env bash
# 05_configure.sh — Configure rootfs basics
# PhantomSec phantom-proot installer — Step 5

set -euo pipefail
source "$(dirname "$0")/_common.sh"

step "Step 5 — Configure rootfs"

# Essential mount-point directories
mkdir -p "$ROOTFS_DIR"/{proc,dev,sys,tmp,run,root}

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

# APT sources — enable main + universe + multiverse for ARM64 (ports.ubuntu.com)
# The minimal cloudimg ships only "main restricted" — gcc/clang live in universe
cat > "$ROOTFS_DIR/etc/apt/sources.list" << 'SOURCES'
deb http://ports.ubuntu.com/ubuntu-ports jammy           main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports jammy-updates   main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports jammy-security  main restricted universe multiverse
SOURCES

# APT options: non-interactive, no recommends
mkdir -p "$ROOTFS_DIR/etc/apt/apt.conf.d"
cat > "$ROOTFS_DIR/etc/apt/apt.conf.d/99phantomsec" << 'APTCONF'
APT::Get::Assume-Yes "true";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APTCONF

ok "Rootfs configured (DNS, hostname, hosts, apt sources)."

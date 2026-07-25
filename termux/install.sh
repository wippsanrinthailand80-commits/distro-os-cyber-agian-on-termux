#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec OS — Termux Edition v2.1.0                          ║
# ║          Powered by phantom-proot — built from scratch, no root         ║
# ║          Zero third-party proot dependency                              ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# One-line install:
#   bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/termux/install.sh)

set -euo pipefail

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' R='\033[0;31m' NC='\033[0m' BOLD='\033[1m' DIM='\033[2m'

log()  { echo -e "${G}[+]${NC} $*"; }
warn() { echo -e "${Y}[!]${NC} $*"; }
err()  { echo -e "${R}[✗]${NC} $*"; exit 1; }
ok()   { echo -e "${G}[✓]${NC} $*"; }
info() { echo -e "${C}${DIM}    $*${NC}"; }
step() { echo -e "\n${C}${BOLD}━━━  $*  ━━━${NC}\n"; }

REPO_URL="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux"
RAW_URL="https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main"
INSTALL_DIR="$HOME/.phantomsec-os"
ROOTFS_DIR="$HOME/.phantomsec-rootfs"
LOCAL_BIN="$HOME/.local/bin"
PROOT_BIN="$LOCAL_BIN/proot"

# ── Sanity check — must be Termux ────────────────────────────────────────────
[ -d "/data/data/com.termux" ] || \
  err "This script is for Termux (Android) only.\nFor Linux bare-metal/VM use: bash <(curl -sL ${RAW_URL}/os/install.sh)"

echo ""
echo -e "${C}${BOLD}"
cat << 'BANNER'
  ██████╗ ██╗  ██╗ █████╗ ███╗  ██╗████████╗ ██████╗ ███╗  ███╗
  ██╔══██╗██║  ██║██╔══██╗████╗ ██║╚══██╔══╝██╔═══██╗████╗████║
  ██████╔╝███████║███████║██╔██╗██║   ██║   ██║   ██║██╔████╔██║
  ██╔═══╝ ██╔══██║██╔══██║██║╚████║   ██║   ██║   ██║██║╚██╔╝██║
  ██║     ██║  ██║██║  ██║██║ ╚███║   ██║   ╚██████╔╝██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝
BANNER
echo -e "${NC}"
echo -e "${C}${BOLD}  PhantomSec OS — Termux Edition v2.1.0${NC}"
echo -e "${DIM}  phantom-proot: zero third-party proot dependency${NC}\n"

# ── Step 1: Update Termux & install build deps ────────────────────────────────
step "Step 1 — Termux packages"
log "Updating Termux packages..."
pkg update -y -q
pkg upgrade -y -q

log "Installing build dependencies (gcc, make, git, curl, tar)..."
pkg install -y gcc make git curl wget tar
ok "Build dependencies ready."

# ── Step 2: Clone PhantomSec repo ────────────────────────────────────────────
step "Step 2 — Clone PhantomSec OS"
if [ -d "$INSTALL_DIR/.git" ]; then
  warn "Repo already exists — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  log "Cloning PhantomSec OS..."
  git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi
ok "Source ready → $INSTALL_DIR"

# ── Step 3: Build phantom-proot from source ───────────────────────────────────
step "Step 3 — Build phantom-proot (from scratch)"
info "This is PhantomSec's own proot — no third-party proot used."

mkdir -p "$LOCAL_BIN"
make -C "$INSTALL_DIR/os/tools/proot" clean 2>/dev/null || true
make -C "$INSTALL_DIR/os/tools/proot" CC=gcc PREFIX="$LOCAL_BIN"
make -C "$INSTALL_DIR/os/tools/proot" install PREFIX="$LOCAL_BIN"
ok "phantom-proot built → $PROOT_BIN"

# ── Step 4: Download Ubuntu ARM64 minimal rootfs ──────────────────────────────
step "Step 4 — Download Ubuntu rootfs"

ROOTFS_TAR="/tmp/phantomsec-rootfs.tar.gz"
# Ubuntu 22.04 LTS (Jammy) ARM64 minimal base image
ROOTFS_URL="https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-arm64-root.tar.gz"

if [ -d "$ROOTFS_DIR/bin" ] && [ -d "$ROOTFS_DIR/etc" ]; then
  warn "Rootfs already exists at $ROOTFS_DIR — skipping download."
else
  log "Downloading Ubuntu 22.04 LTS ARM64 minimal rootfs..."
  info "(~30 MB — this may take a minute on mobile data)"
  curl -L --progress-bar -o "$ROOTFS_TAR" "$ROOTFS_URL"

  log "Extracting rootfs to $ROOTFS_DIR ..."
  mkdir -p "$ROOTFS_DIR"
  tar -xf "$ROOTFS_TAR" -C "$ROOTFS_DIR"
  rm -f "$ROOTFS_TAR"
  ok "Ubuntu rootfs extracted."
fi

# ── Step 5: Configure rootfs basics ──────────────────────────────────────────
step "Step 5 — Configure rootfs"

# Essential directories for bind mounts
mkdir -p "$ROOTFS_DIR"/{proc,dev,sys,tmp,run}
mkdir -p "$ROOTFS_DIR/root"

# DNS resolution
echo "nameserver 8.8.8.8"       >  "$ROOTFS_DIR/etc/resolv.conf"
echo "nameserver 1.1.1.1"       >> "$ROOTFS_DIR/etc/resolv.conf"

# Hostname
echo "phantomsec"               > "$ROOTFS_DIR/etc/hostname"

# /etc/hosts basics
cat > "$ROOTFS_DIR/etc/hosts" << 'HOSTS'
127.0.0.1   localhost
127.0.1.1   phantomsec
::1         localhost ip6-localhost ip6-loopback
HOSTS

ok "Rootfs configured."

# ── Step 6: Build PhantomSec tools inside our phantom-proot ──────────────────
step "Step 6 — Build PhantomSec tools inside phantom-proot"
info "Using phantom-proot to enter rootfs — no root, no proot-distro."

_proot_run() {
  "$PROOT_BIN" \
    -r "$ROOTFS_DIR" \
    -b /proc:/proc   \
    -b /dev:/dev     \
    -b /sys:/sys     \
    -b "$INSTALL_DIR/os:/opt/phantomsec-os" \
    -- "$@"
}

log "Installing build tools inside Ubuntu rootfs..."
_proot_run bash -c "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -q gcc make libm-dev 2>&1 | tail -5
"

log "Compiling PhantomSec OS tools from source inside rootfs..."
_proot_run bash -c "
  cd /opt/phantomsec-os
  make CC=gcc CFLAGS='-O2 -Wall -std=c11 -D_GNU_SOURCE' all
  make PREFIX=/usr/local install
  echo '[OK] psh  netghost  spectrscan  scdna  entropyd'
"
ok "PhantomSec tools built and installed inside rootfs."

# ── Step 7: Create launcher scripts ──────────────────────────────────────────
step "Step 7 — Launchers"

# Main environment launcher
cat > "$LOCAL_BIN/phantomsec-os" << LAUNCHER
#!/usr/bin/env bash
# PhantomSec OS — Termux launcher (phantom-proot)
exec "${PROOT_BIN}" \\
  -r "${ROOTFS_DIR}" \\
  -b /proc:/proc     \\
  -b /dev:/dev       \\
  -b /sys:/sys       \\
  -b "\${HOME}:/root" \\
  -- "\${@:-bash}" --login
LAUNCHER
chmod +x "$LOCAL_BIN/phantomsec-os"

# Per-tool launchers (run tools without entering full shell)
for TOOL in psh netghost spectrscan scdna entropyd; do
  cat > "$LOCAL_BIN/ps-${TOOL}" << TOOL_EOF
#!/usr/bin/env bash
exec "${PROOT_BIN}" \\
  -r "${ROOTFS_DIR}" \\
  -b /proc:/proc -b /dev:/dev -b /sys:/sys \\
  -- ${TOOL} "\$@"
TOOL_EOF
  chmod +x "$LOCAL_BIN/ps-${TOOL}"
done
ok "Launchers created in $LOCAL_BIN"

# ── Step 8: Add ~/.local/bin to PATH ─────────────────────────────────────────
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$PREFIX/etc/bash.bashrc"; do
  [ -f "$RC" ] || continue
  grep -q 'local/bin' "$RC" && continue
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
  info "Added ~/.local/bin to PATH in $RC"
done

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${C}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C}${BOLD}  PhantomSec OS — Termux Edition v2.1.0 installed.${NC}"
echo -e "${C}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${G}Enter OS environment:${NC}   ${BOLD}phantomsec-os${NC}"
echo ""
echo -e "  ${G}Run tools directly:${NC}"
echo -e "     ps-psh        — PhantomSec Shell"
echo -e "     ps-netghost   — Network Ghost"
echo -e "     ps-spectrscan — Spectrum Scanner"
echo -e "     ps-scdna      — SC-DNA"
echo -e "     ps-entropyd   — Entropy Daemon"
echo ""
echo -e "  ${G}Run raw proot shell:${NC}"
echo -e "     proot -r ~/.phantomsec-rootfs -b /proc:/proc -b /dev:/dev -b /sys:/sys -- bash"
echo ""
echo -e "  ${DIM}Powered by phantom-proot — PhantomSec's own proot,${NC}"
echo -e "  ${DIM}built from scratch in C. No third-party proot used.${NC}"
echo ""
echo -e "  ${Y}For authorized security testing and educational use only.${NC}"
echo -e "  ${Y}ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"
echo ""

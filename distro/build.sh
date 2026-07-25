#!/bin/bash
# PhantomSec OS — Custom Linux Distro Builder
# Builds a minimal Linux-from-scratch ISO with PhantomSec tools included
#
# WARNING: This script requires significant disk space (~10GB) and build time.
# It is designed to run on a Debian/Ubuntu host system.
# Run as root in an isolated build environment.
#
# Usage: sudo ./build.sh [--arch x86_64] [--output /tmp/phantomsec.iso]

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
DISTRO_NAME="PhantomSec OS"
DISTRO_VERSION="2.0.0"
ARCH="${ARCH:-x86_64}"
BUILD_DIR="${BUILD_DIR:-/tmp/phantomsec-build}"
SYSROOT="${BUILD_DIR}/sysroot"
TOOLS_DIR="${BUILD_DIR}/tools"
OUTPUT="${OUTPUT:-/tmp/phantomsec-${DISTRO_VERSION}-${ARCH}.iso}"
KERNEL_VERSION="6.6.30"
BUSYBOX_VERSION="1.36.1"
MUSL_VERSION="1.2.5"
NJOBS=$(nproc)

# Colors
R="\033[0;31m" G="\033[0;32m" Y="\033[1;33m" C="\033[0;36m" NC="\033[0m"

log()   { echo -e "${G}[+]${NC} $*"; }
warn()  { echo -e "${Y}[!]${NC} $*"; }
error() { echo -e "${R}[✗]${NC} $*"; exit 1; }
step()  { echo -e "\n${C}════════════════════════════════════════════${NC}"; \
          echo -e "${C}  $*${NC}"; \
          echo -e "${C}════════════════════════════════════════════${NC}\n"; }

# ── Preflight checks ──────────────────────────────────────────────────────────
preflight() {
    step "Preflight checks"
    [ "$(id -u)" -eq 0 ] || error "Must run as root"
    for cmd in gcc make wget tar xz gzip cpio dd; do
        command -v "$cmd" >/dev/null 2>&1 || error "Missing required tool: $cmd"
    done

    # Check disk space (need 10GB)
    FREE_KB=$(df /tmp | awk 'NR==2{print $4}')
    [ "${FREE_KB}" -gt 10485760 ] || warn "Less than 10GB free — build may fail"

    log "Architecture: ${ARCH}"
    log "Kernel: ${KERNEL_VERSION}"
    log "Output: ${OUTPUT}"
    log "Build dir: ${BUILD_DIR}"
    log "Jobs: ${NJOBS}"
}

# ── Directory structure ───────────────────────────────────────────────────────
create_dirs() {
    step "Creating build directories"
    mkdir -p "${BUILD_DIR}"/{src,sysroot,tools,iso}
    mkdir -p "${SYSROOT}"/{bin,sbin,lib,lib64,usr/{bin,sbin,lib,include},etc,dev,proc,sys,tmp,var/{log,run},home,root,opt/phantomsec/{tools,configs,profiles}}
    chmod 1777 "${SYSROOT}/tmp"
    log "Directory structure created"
}

# ── Download sources ──────────────────────────────────────────────────────────
download_sources() {
    step "Downloading source packages"
    cd "${BUILD_DIR}/src"

    if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
        log "Downloading Linux kernel ${KERNEL_VERSION}..."
        wget -q --show-progress "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"
    fi

    if [ ! -f "busybox-${BUSYBOX_VERSION}.tar.bz2" ]; then
        log "Downloading BusyBox ${BUSYBOX_VERSION}..."
        wget -q --show-progress "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
    fi

    if [ ! -f "musl-${MUSL_VERSION}.tar.gz" ]; then
        log "Downloading musl libc ${MUSL_VERSION}..."
        wget -q --show-progress "https://musl.libc.org/releases/musl-${MUSL_VERSION}.tar.gz"
    fi

    log "All sources downloaded"
}

# ── Build musl libc ───────────────────────────────────────────────────────────
build_musl() {
    step "Building musl libc ${MUSL_VERSION}"
    cd "${BUILD_DIR}/src"
    [ -d "musl-${MUSL_VERSION}" ] || tar xf "musl-${MUSL_VERSION}.tar.gz"
    cd "musl-${MUSL_VERSION}"

    ./configure \
        --prefix="${SYSROOT}/usr" \
        --syslibdir="${SYSROOT}/lib" \
        --enable-static \
        --disable-shared

    make -j"${NJOBS}"
    make install
    log "musl libc installed"
}

# ── Build Linux kernel ────────────────────────────────────────────────────────
build_kernel() {
    step "Building Linux kernel ${KERNEL_VERSION}"
    cd "${BUILD_DIR}/src"
    [ -d "linux-${KERNEL_VERSION}" ] || tar xf "linux-${KERNEL_VERSION}.tar.xz"
    cd "linux-${KERNEL_VERSION}"

    # Use PhantomSec kernel config if available, else use tinyconfig
    if [ -f "$(dirname "$0")/kernel.config" ]; then
        cp "$(dirname "$0")/kernel.config" .config
        log "Using PhantomSec kernel config"
    else
        make tinyconfig
        # Enable minimum required features
        scripts/config --enable CONFIG_64BIT
        scripts/config --enable CONFIG_EFI
        scripts/config --enable CONFIG_NET
        scripts/config --enable CONFIG_INET
        scripts/config --enable CONFIG_PACKET
        scripts/config --enable CONFIG_AF_PACKET
        scripts/config --enable CONFIG_RAW_SOCKETS
        scripts/config --enable CONFIG_INOTIFY_USER
        scripts/config --enable CONFIG_PROC_FS
        scripts/config --enable CONFIG_SYS_FS
        scripts/config --enable CONFIG_DEVTMPFS
        scripts/config --enable CONFIG_TMPFS
        scripts/config --enable CONFIG_EXT4_FS
        scripts/config --enable CONFIG_VFAT_FS
        scripts/config --enable CONFIG_ISO9660_FS
        scripts/config --enable CONFIG_BLK_DEV_INITRD
        scripts/config --enable CONFIG_PTRACE
        scripts/config --enable CONFIG_SECCOMP
        scripts/config --enable CONFIG_BPFFILTER
        scripts/config --set-str CONFIG_DEFAULT_HOSTNAME "phantomsec"
        make olddefconfig
    fi

    make -j"${NJOBS}" bzImage
    cp arch/x86/boot/bzImage "${BUILD_DIR}/iso/vmlinuz"
    log "Kernel built: $(du -sh arch/x86/boot/bzImage | cut -f1)"
}

# ── Build BusyBox ─────────────────────────────────────────────────────────────
build_busybox() {
    step "Building BusyBox ${BUSYBOX_VERSION}"
    cd "${BUILD_DIR}/src"
    [ -d "busybox-${BUSYBOX_VERSION}" ] || tar xf "busybox-${BUSYBOX_VERSION}.tar.bz2"
    cd "busybox-${BUSYBOX_VERSION}"

    make defconfig
    # Static link with musl
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    sed -i 's|CONFIG_SYSROOT=""|CONFIG_SYSROOT="${SYSROOT}"|' .config

    make -j"${NJOBS}" CC="gcc" \
        CFLAGS="--sysroot=${SYSROOT}" \
        LDFLAGS="--static"

    make install CONFIG_PREFIX="${SYSROOT}"
    log "BusyBox installed"
}

# ── Build PhantomSec tools ────────────────────────────────────────────────────
build_phantomsec_tools() {
    step "Building PhantomSec C/C++ tools"
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

    if [ -f "${SCRIPT_DIR}/Makefile" ]; then
        cd "${SCRIPT_DIR}"
        mkdir -p bin
        make all CC=gcc CFLAGS="-O2 -Wall -std=c11 -D_GNU_SOURCE -static"
        for tool in bin/*; do
            [ -f "$tool" ] || continue
            cp "$tool" "${SYSROOT}/opt/phantomsec/tools/"
            ln -sf "/opt/phantomsec/tools/$(basename "$tool")" "${SYSROOT}/usr/bin/$(basename "$tool")"
            log "Installed: $(basename "$tool")"
        done
    else
        warn "PhantomSec tools Makefile not found — skipping"
    fi
}

# ── Configure root filesystem ─────────────────────────────────────────────────
configure_rootfs() {
    step "Configuring root filesystem"

    # /etc/passwd, group, shadow
    cat > "${SYSROOT}/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/usr/bin/psh
phantom:x:1000:1000:PhantomSec User:/home/phantom:/usr/bin/psh
EOF

    cat > "${SYSROOT}/etc/group" << 'EOF'
root:x:0:root
phantom:x:1000:phantom
sudo:x:27:phantom
EOF

    cat > "${SYSROOT}/etc/shadow" << 'EOF'
root:!:19000:0:99999:7:::
phantom:!:19000:0:99999:7:::
EOF
    chmod 640 "${SYSROOT}/etc/shadow"

    # /etc/os-release
    cat > "${SYSROOT}/etc/os-release" << EOF
NAME="${DISTRO_NAME}"
VERSION="${DISTRO_VERSION}"
ID=phantomsec
ID_LIKE=linux
PRETTY_NAME="${DISTRO_NAME} ${DISTRO_VERSION}"
HOME_URL="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux"
BUILD_ID="${DISTRO_VERSION}-$(date +%Y%m%d)"
ANSI_COLOR="1;36"
EOF

    # /etc/hostname
    echo "phantomsec" > "${SYSROOT}/etc/hostname"

    # /etc/profile — load PhantomSec environment
    cat > "${SYSROOT}/etc/profile" << 'EOF'
# PhantomSec OS — /etc/profile
export PATH="/opt/phantomsec/tools:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PHANTOMSEC_LANG="${PHANTOMSEC_LANG:-en}"
export PS1='\[\033[0;36m\]phantom\[\033[0m\]@\[\033[0;32m\]\h\[\033[0m\]:\[\033[0;34m\]\w\[\033[0m\]$ '
export TERM=xterm-256color
export LANG=en_US.UTF-8

# Load PhantomSec functions
[ -f /etc/phantomsec.sh ] && . /etc/phantomsec.sh
EOF

    # /etc/phantomsec.sh — PhantomSec shell functions
    cat > "${SYSROOT}/etc/phantomsec.sh" << 'PSEOF'
# PhantomSec OS shell functions
# Available in all shells

ps_banner() {
    printf "\033[0;36m"
    echo " ╔══════════════════════════════════════╗"
    echo " ║     PhantomSec OS v2.0.0             ║"
    echo " ║     Built entirely in C/C++          ║"
    echo " ╚══════════════════════════════════════╝"
    printf "\033[0m\n"
}

ps_tools() {
    echo ""
    printf "\033[1;37m  PhantomSec Tools:\033[0m\n"
    printf "  \033[0;32mspectrscan\033[0m  — Passive firewall ACL reconstructor\n"
    printf "  \033[0;32mentropyd\033[0m    — Real-time ransomware detector\n"
    printf "  \033[0;32mscdna\033[0m       — Syscall DNA behavioral fingerprinter\n"
    printf "  \033[0;32mnetghost\033[0m    — Passive network topology mapper\n"
    printf "  \033[0;32mpsh\033[0m         — PhantomSec shell (you are here)\n"
    echo ""
}

# Auto-show banner on interactive login
if [ -n "$PS1" ] && [ -z "$PHANTOMSEC_NOBANNER" ]; then
    ps_banner
fi
PSEOF

    # Create /init (PID 1 — custom C init, or BusyBox init as fallback)
    ln -sf /sbin/init "${SYSROOT}/init" 2>/dev/null || true

    # Default home directories
    mkdir -p "${SYSROOT}/home/phantom"
    mkdir -p "${SYSROOT}/root"
    chmod 700 "${SYSROOT}/root"

    log "Root filesystem configured"
}

# ── Build initramfs ───────────────────────────────────────────────────────────
build_initramfs() {
    step "Building initramfs"
    cd "${SYSROOT}"

    # Create device nodes
    mknod -m 622 dev/console c 5 1 2>/dev/null || true
    mknod -m 666 dev/null    c 1 3 2>/dev/null || true
    mknod -m 666 dev/zero    c 1 5 2>/dev/null || true
    mknod -m 444 dev/random  c 1 8 2>/dev/null || true
    mknod -m 444 dev/urandom c 1 9 2>/dev/null || true

    find . | cpio -H newc -o | gzip -9 > "${BUILD_DIR}/iso/initramfs.img"
    log "initramfs: $(du -sh "${BUILD_DIR}/iso/initramfs.img" | cut -f1)"
}

# ── Build ISO ─────────────────────────────────────────────────────────────────
build_iso() {
    step "Building bootable ISO"

    # GRUB bootloader config
    mkdir -p "${BUILD_DIR}/iso/boot/grub"
    cat > "${BUILD_DIR}/iso/boot/grub/grub.cfg" << EOF
set timeout=3
set default=0

menuentry "${DISTRO_NAME} ${DISTRO_VERSION}" {
    linux /vmlinuz quiet console=tty0 console=ttyS0,115200 init=/init
    initrd /initramfs.img
}

menuentry "${DISTRO_NAME} — Verbose Boot" {
    linux /vmlinuz console=tty0 init=/init
    initrd /initramfs.img
}

menuentry "Poweroff" {
    halt
}
EOF

    # Build ISO with GRUB
    if command -v grub-mkrescue >/dev/null 2>&1; then
        grub-mkrescue -o "${OUTPUT}" "${BUILD_DIR}/iso/"
        log "ISO built: ${OUTPUT}"
        log "Size: $(du -sh "${OUTPUT}" | cut -f1)"
    else
        warn "grub-mkrescue not found — creating raw initramfs only"
        cp "${BUILD_DIR}/iso/vmlinuz" "$(dirname "${OUTPUT}")/phantomsec-vmlinuz"
        cp "${BUILD_DIR}/iso/initramfs.img" "$(dirname "${OUTPUT}")/phantomsec-initramfs.img"
        log "Kernel: $(dirname "${OUTPUT}")/phantomsec-vmlinuz"
        log "Initramfs: $(dirname "${OUTPUT}")/phantomsec-initramfs.img"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${C}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C}║  PhantomSec OS — Custom Linux Build System               ║${NC}"
    echo -e "${C}║  Building from scratch — no reskins, no wrappers          ║${NC}"
    echo -e "${C}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    preflight
    create_dirs
    download_sources
    build_musl
    build_kernel
    build_busybox
    build_phantomsec_tools
    configure_rootfs
    build_initramfs
    build_iso

    echo ""
    echo -e "${G}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${G}║  Build complete!                                          ║${NC}"
    echo -e "${G}║  ISO: ${OUTPUT}${NC}"
    echo -e "${G}║  Test with: qemu-system-x86_64 -cdrom ${OUTPUT} -m 512M${NC}"
    echo -e "${G}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

main "$@"

#!/usr/bin/env bash
# 07_launchers.sh — Launcher scripts + interactive login menu
# PhantomSec OS Termux Edition v2.8.0

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 7 — Launchers & Menu"

[ -x "$PROOT_BIN" ] || err "phantom-proot not found at $PROOT_BIN"

ensure_dir "$LOCAL_BIN"

# ── Common proot invocation ────────────────────────────────────────────────
# Key design decisions:
#   - Home binds to /home/phantom (not /root) to avoid path conflicts
#   - All commands use absolute paths inside rootfs
#   - HOME is set to /home/phantom so profile loads correctly
PROOT_ARGS="-r \"\$ROOTFS\" -b /proc:/proc -b /dev:/dev -b /sys:/sys -b \"\$HOME:/home/phantom\" -w /home/phantom"

# ── Main launcher: phantomsec-os ───────────────────────────────────────────
cat > "$LOCAL_BIN/phantomsec-os" << 'LAUNCHER'
#!/usr/bin/env bash
# PhantomSec OS — Interactive launcher with menu
VERSION="2.8.0"
PROOT="__PROOT__"
ROOTFS="__ROOTFS__"

if [ ! -x "$PROOT" ]; then
  echo "[!] phantom-proot not found at $PROOT" >&2
  echo "    Run: bash <(curl -sL __RAW_URL__/termux/install.sh)" >&2
  exit 1
fi

if [ ! -d "$ROOTFS/bin" ]; then
  echo "[!] Rootfs not found at $ROOTFS" >&2
  echo "    Run installer again." >&2
  exit 1
fi

run_in_proot() {
  exec "$PROOT" \
    -r "$ROOTFS" \
    -b /proc:/proc -b /dev:/dev -b /sys:/sys \
    -b "$HOME:/home/phantom" \
    -w /home/phantom \
    -- "$@"
}

show_menu() {
  clear
  echo ""
  echo -e "\033[0;36m╔══════════════════════════════════════════════════╗"
  echo -e "║                                                  ║"
  echo -e "║  \033[1;37m  ██████╗ ██╗  ██╗ █████╗ ███╗  ██╗████████╗\033[0;36m  ║"
  echo -e "║  \033[1;37m  ██╔══██╗██║  ██║██╔══██╗████╗ ██║╚══██╔══╝\033[0;36m  ║"
  echo -e "║  \033[1;37m  ██████╔╝███████║███████║██╔██╗██║   ██║   \033[0;36m  ║"
  echo -e "║  \033[1;37m  ██╔═══╝ ██╔══██║██╔══██║██║╚████║   ██║   \033[0;36m  ║"
  echo -e "║  \033[1;37m  ██║     ██║  ██║██║  ██║██║ ╚███║   ██║   \033[0;36m  ║"
  echo -e "║  \033[1;37m  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝   ╚═╝   \033[0;36m  ║"
  echo -e "║                                                  ║"
  echo -e "║  \033[1;33m  PhantomSec OS v${VERSION} Beta\033[0;36m                    ║"
  echo -e "║  \033[2m  Custom proot · No distro needed · ARM64\033[0;36m       ║"
  echo -e "╠══════════════════════════════════════════════════╣"
  echo -e "║                                                  ║"
  echo -e "║  \033[1;32m  1\033[0;36m  Full Shell          \033[1;32m 6\033[0;36m  EntropyDaemon    ║"
  echo -e "║  \033[1;32m  2\033[0;36m  PhantomShell        \033[1;32m 7\033[0;36m  Password Gen     ║"
  echo -e "║  \033[1;32m  3\033[0;36m  NetGhost            \033[1;32m 8\033[0;36m  Hash Check       ║"
  echo -e "║  \033[1;32m  4\033[0;36m  SpecterScan         \033[1;32m 9\033[0;36m  Vuln Scanner     ║"
  echo -e "║  \033[1;32m  5\033[0;36m  SyscallDNA         \033[1;32m10\033[0;36m  Port Scanner     ║"
  echo -e "║                             \033[1;32m11\033[0;36m  RevShell Gen     ║"
  echo -e "║                                                  ║"
  echo -e "╠══════════════════════════════════════════════════╣"
  echo -e "║  \033[1;33m  [1-11]\033[0;36m Select tool   \033[1;33m[q]\033[0;36m Quit              ║"
  echo -e "╚══════════════════════════════════════════════════╝\033[0m"
  echo ""
}

TOOL_PATH="/usr/local/bin"

while true; do
  show_menu
  read -rp "  Select [1-11/q]: " choice
  echo ""
  case "$choice" in
    1) run_in_proot /bin/sh --login ;;
    2) run_in_proot "$TOOL_PATH/psh" ;;
    3) run_in_proot "$TOOL_PATH/netghost" ;;
    4) run_in_proot "$TOOL_PATH/spectrscan" ;;
    5) run_in_proot "$TOOL_PATH/scdna" ;;
    6) run_in_proot "$TOOL_PATH/entropyd" ;;
    7) run_in_proot "$TOOL_PATH/passgen" ;;
    8) run_in_proot "$TOOL_PATH/hashcheck" ;;
    9) run_in_proot "$TOOL_PATH/vulnscan" ;;
   10) run_in_proot "$TOOL_PATH/ps-portscan" ;;
   11) run_in_proot "$TOOL_PATH/ps-revshell" ;;
    q|Q) echo -e "\033[0;32m  Stay phantom. 🤫\033[0m"; exit 0 ;;
    *) echo -e "\033[0;31m  Invalid option.\033[0m"; sleep 1 ;;
  esac
done
LAUNCHER

# Substitute paths into the launcher
sed -i "s|__PROOT__|${PROOT_BIN}|g" "$LOCAL_BIN/phantomsec-os"
sed -i "s|__ROOTFS__|${ROOTFS_DIR}|g" "$LOCAL_BIN/phantomsec-os"
sed -i "s|__RAW_URL__|${RAW_URL}|g" "$LOCAL_BIN/phantomsec-os"
chmod +x "$LOCAL_BIN/phantomsec-os"
ok "phantomsec-os → $LOCAL_BIN/phantomsec-os"

# ── Per-tool launchers (direct access without menu) ────────────────────────
for TOOL in psh netghost spectrscan scdna entropyd passgen hashcheck vulnscan; do
  cat > "$LOCAL_BIN/ps-${TOOL}" << TOOL_LAUNCHER
#!/usr/bin/env bash
# PhantomSec — ${TOOL}
exec "${PROOT_BIN}" \\
  -r "${ROOTFS_DIR}" \\
  -b /proc:/proc -b /dev:/dev -b /sys:/sys \\
  -b "\${HOME}:/home/phantom" \\
  -w /home/phantom \\
  -- /usr/local/bin/${TOOL} "\$@"
TOOL_LAUNCHER
  chmod +x "$LOCAL_BIN/ps-${TOOL}"
  ok "ps-${TOOL} → $LOCAL_BIN/ps-${TOOL}"
done

# ── Ensure ~/.local/bin is in PATH ─────────────────────────────────────────
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "${PREFIX:-}/etc/bash.bashrc"; do
  [ -f "$RC" ] || continue
  grep -q '\.local/bin' "$RC" 2>/dev/null && continue
  echo "$PATH_LINE" >> "$RC"
  info "Added ~/.local/bin to PATH in $RC"
done

# Create .bashrc if it doesn't exist (needed for login shell)
if [ ! -f "$HOME/.bashrc" ]; then
  echo "$PATH_LINE" > "$HOME/.bashrc"
  info "Created ~/.bashrc with PATH"
fi

ok "All launchers ready."

#!/usr/bin/env bash
# Quick-fix: regenerate PhantomSec launchers with correct tool paths
# Run this directly in Termux:
#   bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/fix-launchers.sh)

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' BOLD='\033[1m'
ok()  { echo -e "${G}[✓]${NC} $*"; }
log() { echo -e "${G}[+]${NC} $*"; }

ROOTFS_DIR="${PHANTOMSEC_ROOTFS:-$HOME/.phantomsec-rootfs}"
LOCAL_BIN="$HOME/.local/bin"
PROOT_BIN="$LOCAL_BIN/proot"
TOOL_PATH="/usr/local/bin"

mkdir -p "$LOCAL_BIN"

echo -e "\n${C}${BOLD}  Regenerating PhantomSec launchers...${NC}\n"

# Main env
cat > "$LOCAL_BIN/phantomsec-os" << LAUNCHER
#!/usr/bin/env bash
exec "${PROOT_BIN}" \
  -r "${ROOTFS_DIR}" \
  -b /proc:/proc -b /dev:/dev -b /sys:/sys \
  -b "\${HOME}:/root" -w /root \
  -- /bin/bash --login
LAUNCHER
chmod +x "$LOCAL_BIN/phantomsec-os"
ok "phantomsec-os"

for TOOL in psh netghost spectrscan scdna entropyd; do
  cat > "$LOCAL_BIN/ps-${TOOL}" << TOOL_LAUNCHER
#!/usr/bin/env bash
exec "${PROOT_BIN}" \
  -r "${ROOTFS_DIR}" \
  -b /proc:/proc -b /dev:/dev -b /sys:/sys \
  -- ${TOOL_PATH}/${TOOL} "\$@"
TOOL_LAUNCHER
  chmod +x "$LOCAL_BIN/ps-${TOOL}"
  ok "ps-${TOOL} → ${TOOL_PATH}/${TOOL}"
done

echo ""
log "Done. Try: ps-psh"

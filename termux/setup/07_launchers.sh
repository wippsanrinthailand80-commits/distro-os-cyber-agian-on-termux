#!/usr/bin/env bash
# 07_launchers.sh — Create launcher scripts
# PhantomSec phantom-proot installer — Step 7

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 7 — Launchers"

mkdir -p "$LOCAL_BIN"

[ -x "$PROOT_BIN" ] || err "phantom-proot not found at $PROOT_BIN\nDid step 3 (proot build) succeed?"

# Tools live at /usr/local/bin/<name> inside the rootfs
TOOL_PATH_IN_ROOTFS="/usr/local/bin"

# ── Main environment launcher ──────────────────────────────────────────────────
cat > "$LOCAL_BIN/phantomsec-os" << LAUNCHER
#!/usr/bin/env bash
# PhantomSec OS — enter full environment via phantom-proot
PROOT="${PROOT_BIN}"
ROOTFS="${ROOTFS_DIR}"

if [ ! -x "\$PROOT" ]; then
  echo "[!] phantom-proot not found at \$PROOT" >&2
  echo "    Run the installer again: bash <(curl -sL ${RAW_URL}/termux/install.sh)" >&2
  exit 1
fi

if [ ! -d "\$ROOTFS/bin" ]; then
  echo "[!] Rootfs not found at \$ROOTFS" >&2
  echo "    Run the installer again to re-download." >&2
  exit 1
fi

exec "\$PROOT" \\
  -r "\$ROOTFS" \\
  -b /proc:/proc    \\
  -b /dev:/dev      \\
  -b /sys:/sys      \\
  -b "\${HOME}:/root" \\
  -w /root          \\
  -- /bin/bash --login
LAUNCHER
chmod +x "$LOCAL_BIN/phantomsec-os"
ok "phantomsec-os → $LOCAL_BIN/phantomsec-os"

# ── Per-tool launchers — use FULL PATH inside rootfs ──────────────────────────
for TOOL in psh netghost spectrscan scdna entropyd passgen hashcheck vulnscan; do
  cat > "$LOCAL_BIN/ps-${TOOL}" << TOOL_LAUNCHER
#!/usr/bin/env bash
# PhantomSec tool launcher — ${TOOL}
exec "${PROOT_BIN}" \\
  -r "${ROOTFS_DIR}" \\
  -b /proc:/proc -b /dev:/dev -b /sys:/sys \\
  -b "\${HOME}:/root" \\
  -- ${TOOL_PATH_IN_ROOTFS}/${TOOL} "\$@"
TOOL_LAUNCHER
  chmod +x "$LOCAL_BIN/ps-${TOOL}"
  ok "ps-${TOOL} → ${TOOL_PATH_IN_ROOTFS}/${TOOL} (inside rootfs)"
done

# ── Add ~/.local/bin to PATH ───────────────────────────────────────────────────
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "${PREFIX:-}/etc/bash.bashrc"; do
  [ -f "$RC" ] || continue
  grep -q '\.local/bin' "$RC" && continue
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
  info "Added ~/.local/bin to PATH in $RC"
done

ok "All launchers ready."
info "Run: phantomsec-os       — enter full shell environment"
info "Run: ps-psh              — PhantomSec Shell"
info "Run: ps-netghost         — NetGhost"
info "Run: ps-spectrscan       — SpecterScan"
info "Run: ps-scdna            — SyscallDNA"
info "Run: ps-entropyd         — EntropyWarden"
info "Run: ps-passgen          — Password Generator"
info "Run: ps-hashcheck        — Hash Identifier"
info "Run: ps-vulnscan         — Vulnerability Scanner"
info "Run: ps-portscan         — Port Scanner"
info "Run: ps-revshell         — Reverse Shell Generator"

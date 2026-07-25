#!/usr/bin/env bash
# 07_launchers.sh — Create launcher scripts
# PhantomSec phantom-proot installer — Step 7

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 7 — Launchers"

mkdir -p "$LOCAL_BIN"

# Sanity check — proot must exist
[ -x "$PROOT_BIN" ] || err "phantom-proot not found at $PROOT_BIN\nDid step 3 (proot build) succeed?"

# ── Main environment launcher ──────────────────────────────────────────────────
cat > "$LOCAL_BIN/phantomsec-os" << LAUNCHER
#!/usr/bin/env bash
# PhantomSec OS — enter full environment via phantom-proot
PROOT_BIN_PATH="${PROOT_BIN}"
ROOTFS="${ROOTFS_DIR}"
exec "\${PROOT_BIN_PATH}" \\
  -r "\${ROOTFS}" \\
  -b /proc:/proc  \\
  -b /dev:/dev    \\
  -b /sys:/sys    \\
  -b "\${HOME}:/root" \\
  -- "\${@:-bash}" --login
LAUNCHER
chmod +x "$LOCAL_BIN/phantomsec-os"
ok "phantomsec-os → $LOCAL_BIN/phantomsec-os"

# ── Per-tool launchers ──────────────────────────────────────────────────────────
for TOOL in psh netghost spectrscan scdna entropyd; do
  cat > "$LOCAL_BIN/ps-${TOOL}" << TOOL_LAUNCHER
#!/usr/bin/env bash
# PhantomSec tool launcher — ${TOOL}
PROOT_BIN_PATH="${PROOT_BIN}"
ROOTFS="${ROOTFS_DIR}"
exec "\${PROOT_BIN_PATH}" \\
  -r "\${ROOTFS}" \\
  -b /proc:/proc -b /dev:/dev -b /sys:/sys \\
  -- ${TOOL} "\$@"
TOOL_LAUNCHER
  chmod +x "$LOCAL_BIN/ps-${TOOL}"
done
ok "Tool launchers: ps-psh  ps-netghost  ps-spectrscan  ps-scdna  ps-entropyd"

# ── Add ~/.local/bin to PATH in shell rc files ─────────────────────────────────
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$PREFIX/etc/bash.bashrc"; do
  [ -f "$RC" ] || continue
  grep -q '\.local/bin' "$RC" && continue
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
  info "Added ~/.local/bin to PATH in $RC"
done

ok "All launchers ready."
info "Run: phantomsec-os    — enter full environment"
info "Run: ps-psh           — PhantomSec Shell only"

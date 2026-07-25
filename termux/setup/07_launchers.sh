#!/usr/bin/env bash
# 07_launchers.sh — Create launcher scripts
# PhantomSec phantom-proot installer — Step 7

set -euo pipefail
source "${PHANTOMSEC_COMMON:-$(dirname "$0")/_common.sh}"

step "Step 7 — Launchers"

mkdir -p "$LOCAL_BIN"

# ── Main environment launcher ─────────────────────────────────────────────────
cat > "$LOCAL_BIN/phantomsec-os" << LAUNCHER
#!/usr/bin/env bash
# PhantomSec OS — enter full environment via phantom-proot
exec "${PROOT_BIN}" \\
  -r "${ROOTFS_DIR}" \\
  -b /proc:/proc     \\
  -b /dev:/dev       \\
  -b /sys:/sys       \\
  -b "\${HOME}:/root" \\
  -- "\${@:-bash}" --login
LAUNCHER
chmod +x "$LOCAL_BIN/phantomsec-os"
ok "phantomsec-os → $LOCAL_BIN/phantomsec-os"

# ── Per-tool launchers (run tools without entering full shell) ────────────────
for TOOL in psh netghost spectrscan scdna entropyd; do
  cat > "$LOCAL_BIN/ps-${TOOL}" << TOOL_LAUNCHER
#!/usr/bin/env bash
# PhantomSec tool launcher — ${TOOL}
exec "${PROOT_BIN}" \\
  -r "${ROOTFS_DIR}" \\
  -b /proc:/proc -b /dev:/dev -b /sys:/sys \\
  -- ${TOOL} "\$@"
TOOL_LAUNCHER
  chmod +x "$LOCAL_BIN/ps-${TOOL}"
done
ok "Tool launchers: ps-psh  ps-netghost  ps-spectrscan  ps-scdna  ps-entropyd"

# ── Add ~/.local/bin to PATH in shell rc files ────────────────────────────────
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$PREFIX/etc/bash.bashrc"; do
  [ -f "$RC" ] || continue
  grep -q 'local/bin' "$RC" && continue
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
  info "Added ~/.local/bin to PATH in $RC"
done

ok "All launchers ready."

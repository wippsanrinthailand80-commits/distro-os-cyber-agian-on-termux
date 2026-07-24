#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Optional Python Security Tools Installer
# Run this AFTER install.sh if you want extra Python libs
#
# Usage: bash python_tools.sh

G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' M='\033[0;35m' R='\033[0;31m' NC='\033[0m' BOLD='\033[1m'

echo -e "${M}${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║   PhantomSec — Python Tools Setup   ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

ok()   { echo -e "  ${G}[✓]${NC} $1"; }
warn() { echo -e "  ${Y}[!]${NC} $1"; }
info() { echo -e "  ${C}[*]${NC} $1"; }

# Packages safe to install in Termux (do NOT include pip itself)
# These are installed one-by-one via pkg first, then pip fallback
PKG_PYTHON=(
  python-requests
  python-cryptography
)

PIP_SAFE=(
  colorama
  rich
  prompt_toolkit
  pycryptodome
  dnspython
)

echo ""
echo -e "  ${Y}[!] Termux blocks pip from upgrading itself.${NC}"
echo -e "  ${Y}[!] Packages that require pip as a dep are skipped automatically.${NC}"
echo ""

# ── Step 1: install via pkg where available ────────────────────────────
echo -e "  ${C}[*] Installing via pkg (recommended)...${NC}"
for p in "${PKG_PYTHON[@]}"; do
  info "pkg: $p"
  pkg install -y "$p" >/dev/null 2>&1 && ok "$p" || warn "Not in pkg repo: $p"
done

# ── Step 2: remaining packages via pip ────────────────────────────────
echo ""
echo -e "  ${C}[*] Installing via pip (safe packages only)...${NC}"
for p in "${PIP_SAFE[@]}"; do
  info "pip: $p"
  # Run pip in a subshell; if it writes the forbidden error to /dev/tty
  # we catch the exit code and skip cleanly
  result=$(pip install "$p" --quiet --no-deps 2>&1)
  code=$?
  if [ $code -eq 0 ]; then
    ok "$p"
  else
    warn "Skipped $p (use: pip install $p manually if needed)"
  fi
done

echo ""
echo -e "  ${G}${BOLD}[✓] Done! Optional Python tools installed.${NC}"
echo -e "  ${C}Restart PhantomSec: phantomsec${NC}"
echo ""

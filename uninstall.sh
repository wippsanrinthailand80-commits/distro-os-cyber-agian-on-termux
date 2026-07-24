#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Uninstaller

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' NC='\033[0m'

echo -e "${R}[PhantomSec Uninstaller]${NC}"
echo -e "${Y}[!] This will remove PhantomSec and all its data.${NC}"
echo -ne "${R}Are you sure? [y/N]: ${NC}"; read -r confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
  rm -rf "$HOME/.phantomsec"
  rm -f "$HOME/.config/phantomsec/settings.conf"
  rm -f "$PREFIX/bin/phantomsec"
  sed -i '/PhantomSec/d' "$HOME/.zshrc" 2>/dev/null || true
  sed -i '/phantomsec/d' "$HOME/.bashrc" 2>/dev/null || true
  echo -e "${G}[✓] PhantomSec removed successfully.${NC}"
else
  echo -e "${Y}[!] Uninstall cancelled.${NC}"
fi

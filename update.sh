#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Updater

G='\033[0;32m' C='\033[0;36m' M='\033[0;35m' NC='\033[0m' Y='\033[1;33m'
REPO="https://github.com/wippsanrinthailand80-commits/distro-os-cyber-again-on-termux"

echo -e "${M}[PhantomSec Updater]${NC}"
echo -e "${C}[*] Pulling latest version from GitHub...${NC}"
cd "$(dirname "$0")" || exit 1
git pull origin main 2>&1
echo -e "${G}[✓] PhantomSec updated!${NC}"
echo -e "${Y}[!] Restart the menu to apply changes.${NC}"

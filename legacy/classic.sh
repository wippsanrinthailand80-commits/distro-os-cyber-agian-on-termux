#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Classic (green-on-black) Theme
# Homage to the old-school hacker terminal aesthetic

G='\033[0;32m'
DG='\033[0;92m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${G}[PhantomSec] Applying classic theme...${NC}"

# Set terminal colours where supported
printf '\033]11;#000000\007'  # black background
printf '\033]10;#00ff00\007'  # green foreground

echo ""
echo -e "${G}"
cat << 'CLASSIC'
  ╔══════════════════════════════════════╗
  ║   CLASSIC // GREEN ON BLACK          ║
  ║   ██████╗ ██╗  ██╗ █████╗ ███╗      ║
  ║   ██╔══██╗██║  ██║██╔══██╗████╗     ║
  ║   ██████╔╝███████║███████║██╔██╗    ║
  ╚══════════════════════════════════════╝
CLASSIC
echo -e "${NC}"

echo -e "${DG}[✓] Classic theme applied.${NC}"
echo -e "${DIM}    To make permanent, add 'bash themes/classic.sh' to ~/.bashrc${NC}"
echo ""

#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec Termux — Port Scanner
# Usage: ps-portscan <target> [profile]

TARGET="${1:-}"
[ -z "$TARGET" ] && { echo "Usage: $0 <target> [quick|full|stealth]"; exit 1; }
PROFILE="${2:-quick}"

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' R='\033[0;31m' Y='\033[1;33m'

echo -e "\n${G}[+] Port Scanner: ${C}$TARGET${NC} (${PROFILE})"

if command -v nmap &>/dev/null; then
  case "$PROFILE" in
    full)    nmap -sV -sC -O -p- "$TARGET" ;;
    stealth) nmap -sS -T3 "$TARGET" ;;
    udp)     nmap -sU --top-ports 200 "$TARGET" ;;
    *)       nmap -T4 --top-ports 1000 "$TARGET" ;;
  esac
elif command -v nc &>/dev/null; then
  echo "  Scanning with netcat..."
  for port in 21 22 23 25 53 80 110 111 135 139 143 443 445 993 995 1723 3389 5900 8080 8443; do
    (echo >/dev/tcp/"$TARGET"/"$port") 2>/dev/null && echo -e "  ${G}$port/open${NC}" &
  done
  wait
else
  echo -e "${R}  Install nmap: pkg install nmap${NC}"
fi

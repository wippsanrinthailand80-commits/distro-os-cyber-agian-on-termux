#!/usr/bin/env bash
# PhantomSec — Port Scanner
# Usage: ps-portscan <target> [quick|full|stealth|udp]

TARGET="${1:-}"
[ -z "$TARGET" ] && { echo "Usage: $0 <target> [quick|full|stealth|udp]"; exit 1; }
PROFILE="${2:-quick}"

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' R='\033[0;31m' Y='\033[1;33m' B='\033[1m'

echo -e "\n${G}[+] Port Scanner: ${C}${TARGET}${NC} (${PROFILE})"
echo ""

scan_common() {
  local ports="$1"
  local timeout="${2:-1}"
  for port in $ports; do
    (echo >/dev/tcp/"$TARGET"/"$port") 2>/dev/null && \
      echo -e "  ${G}${port}/open${NC}" &
  done
  wait
}

if command -v nmap &>/dev/null; then
  case "$PROFILE" in
    full)    nmap -sV -sC -O -p- "$TARGET" ;;
    stealth) nmap -sS -T3 "$TARGET" ;;
    udp)     nmap -sU --top-ports 200 "$TARGET" ;;
    *)       nmap -T4 --top-ports 1000 "$TARGET" ;;
  esac
elif command -v nc &>/dev/null; then
  echo -e "  ${Y}Scanning with netcat...${NC}"
  case "$PROFILE" in
    full)    COMMON_PORTS="21 22 23 25 53 80 110 111 135 139 143 443 445 993 995 1723 3306 3389 5432 5900 8080 8443 9090" ;;
    stealth) COMMON_PORTS="22 80 443 8080 8443" ;;
    *)       COMMON_PORTS="21 22 23 25 53 80 110 111 135 139 143 443 445 993 995 1723 3389 5900 8080 8443" ;;
  esac
  scan_common "$COMMON_PORTS"
else
  echo -e "${R}  Install nmap or netcat: pkg install nmap nc${NC}"
fi

echo ""

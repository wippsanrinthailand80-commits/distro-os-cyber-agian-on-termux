#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Network Tools Module (standalone)
# Usage: bash nettools.sh [subnet|host]

G='\033[0;32m' NC='\033[0m' C='\033[0;36m' Y='\033[1;33m' R='\033[0;31m'

echo -e "${C}[PhantomSec NetTools]${NC}"
echo "─────────────────────────────────────────────"

echo -e "\n${G}[+] Network Interfaces${NC}"
ip addr 2>/dev/null | grep -E "inet |link/ether" | awk '{print "  "$1" "$2}' || ifconfig 2>/dev/null

echo -e "\n${G}[+] Default Gateway${NC}"
ip route 2>/dev/null | grep default || netstat -rn 2>/dev/null | head -5

echo -e "\n${G}[+] DNS Servers${NC}"
cat /etc/resolv.conf 2>/dev/null | grep nameserver

echo -e "\n${G}[+] Open Ports (localhost)${NC}"
ss -tuln 2>/dev/null | grep LISTEN | head -20 || netstat -tuln 2>/dev/null | head -20

if [ -n "$1" ]; then
  echo -e "\n${G}[+] Ping sweep: $1${NC}"
  nmap -sn "$1" 2>/dev/null | grep -E "Nmap scan|Host is up" | head -20
fi

echo -e "\n${Y}[✓] NetTools complete${NC}"

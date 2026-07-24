#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Recon Module (standalone)
# Usage: bash recon.sh <target>

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <target>"
  exit 1
fi

G='\033[0;32m' NC='\033[0m' C='\033[0;36m' Y='\033[1;33m'

echo -e "${C}[PhantomSec Recon] Target: $TARGET${NC}"
echo "─────────────────────────────────────"

echo -e "${G}[+] WHOIS${NC}"
whois "$TARGET" 2>/dev/null | grep -E "Registrar|Creation|Expiration|Name Server|Country" | head -10

echo -e "\n${G}[+] DNS Records${NC}"
dig +short A "$TARGET"
dig +short MX "$TARGET"
dig +short NS "$TARGET"

echo -e "\n${G}[+] Top Ports (nmap -F)${NC}"
nmap -F "$TARGET" 2>/dev/null | grep -E "open|closed|filtered" | head -20

echo -e "\n${G}[+] HTTP Headers${NC}"
curl -sI "https://$TARGET" 2>/dev/null | head -20

echo -e "\n${G}[+] GeoIP${NC}"
curl -s "http://ip-api.com/json/$TARGET" 2>/dev/null | python3 -m json.tool 2>/dev/null | grep -E "country|city|isp|org|query"

echo ""
echo -e "${Y}[✓] Recon complete for $TARGET${NC}"

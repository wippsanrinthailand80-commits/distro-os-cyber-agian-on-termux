#!/usr/bin/env bash
# PhantomSec — OSINT Module (called by phantomsec.sh)
TARGET="${1:-}"
[ -z "$TARGET" ] && { echo "Usage: $0 <ip|domain|email>"; exit 1; }
G='\033[0;32m' C='\033[0;36m' NC='\033[0m'
echo -e "${G}[+] GeoIP:${NC}"
_json_pretty() { jq . 2>/dev/null || python3 -m json.tool 2>/dev/null || cat; }
curl -s --max-time 8 "http://ip-api.com/json/${TARGET}?fields=country,city,isp,org,as,proxy,query" 2>/dev/null \
  | _json_pretty | grep -vE '^\{$|^\}$' | sed 's/^/  /'
echo -e "\n${G}[+] Reverse DNS:${NC}"
host "$TARGET" 2>/dev/null | head -5 | sed 's/^/  /'

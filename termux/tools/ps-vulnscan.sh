#!/usr/bin/env bash
# PhantomSec — Web Vulnerability Scanner
# Usage: ps-vulnscan <target>

TARGET="${1:-}"
[ -z "$TARGET" ] && { echo "Usage: $0 <url or domain>"; exit 1; }

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' R='\033[0;31m' Y='\033[1;33m'

echo -e "\n${G}[+] Vulnerability Scan: ${C}${TARGET}${NC}\n"

echo -e "${G}[*] Directory discovery:${NC}"
for path in /admin /wp-admin /wp-login.php /phpmyadmin /.env /.git/config /robots.txt /sitemap.xml /server-status /server-info /phpinfo.php /cgi-bin/ /backup /config /database /test /debug /api /console /panel; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$TARGET$path" 2>/dev/null)
  if [ "$code" != "000" ] && [ "$code" != "404" ]; then
    color="$Y"
    [ "$code" = "200" ] && color="$R"
    echo -e "  ${color}$path → HTTP $code${NC}"
  fi
done

echo -e "\n${G}[*] Security headers:${NC}"
headers=$(curl -sI --max-time 5 "http://$TARGET" 2>/dev/null)
for h in "X-Frame-Options" "X-Content-Type-Options" "X-XSS-Protection" "Content-Security-Policy" "Strict-Transport-Security"; do
  if echo "$headers" | grep -qi "$h"; then
    echo -e "  ${G}[+] $h: $(echo "$headers" | grep -i "$h" | head -1 | cut -d: -f2-)${NC}"
  else
    echo -e "  ${R}[-] Missing: $h${NC}"
  fi
done

echo -e "\n${G}[*] Technology fingerprint:${NC}"
echo "$headers" | grep -iE "server:|x-powered-by:|x-aspnet|x-generator" | sed 's/^/  /' || echo "  No tech headers found"

echo ""

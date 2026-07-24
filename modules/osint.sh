#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — OSINT Module (standalone)
# Usage: bash osint.sh <target>
# target = email | domain | username | IP

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <email|domain|username|IP>"
  exit 1
fi

G='\033[0;32m' R='\033[0;31m' Y='\033[1;33m'
C='\033[0;36m' M='\033[0;35m' NC='\033[0m' DIM='\033[2m'

echo -e "${M}[PhantomSec OSINT] Target: ${C}${TARGET}${NC}"
echo "─────────────────────────────────────────────────────"

# ── ตรวจจับประเภท target ──────────────────────────────────────────────
is_ip()    { [[ "$TARGET" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; }
is_email() { [[ "$TARGET" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; }
is_domain(){ [[ "$TARGET" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]+\.[a-zA-Z]{2,}$ ]] && ! is_ip && ! is_email; }

# ── IP OSINT ───────────────────────────────────────────────────────────
osint_ip() {
  echo -e "\n${G}[+] GeoIP & ISP${NC}"
  curl -s --max-time 8 "http://ip-api.com/json/${TARGET}?fields=country,regionName,city,zip,lat,lon,isp,org,as,proxy,hosting,mobile,query" \
    2>/dev/null | python3 -m json.tool 2>/dev/null | grep -vE "^\{$|^\}$" | sed 's/^/  /'

  echo -e "\n${G}[+] Reverse DNS${NC}"
  host "$TARGET" 2>/dev/null | head -3 | sed 's/^/  /' || echo "  (none)"

  echo -e "\n${G}[+] Open Ports (top 20 — quick scan)${NC}"
  if command -v nmap &>/dev/null; then
    nmap -F --open -T3 "$TARGET" 2>/dev/null | grep -E "open|filtered" | head -15 | sed 's/^/  /'
  else
    echo "  (nmap not installed)"
  fi

  echo -e "\n${G}[+] OTX AlienVault Threat Intel${NC}"
  curl -s --max-time 10 "https://otx.alienvault.com/api/v1/indicators/IPv4/${TARGET}/general" \
    2>/dev/null | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  print(f'  Pulse count (threat feeds): {d.get(\"pulse_info\",{}).get(\"count\",0)}')
  print(f'  Country: {d.get(\"country_name\",\"?\")}')
  print(f'  AS name: {d.get(\"asn\",\"?\")}')
except: print('  (error)')
" 2>/dev/null
}

# ── Domain OSINT ───────────────────────────────────────────────────────
osint_domain() {
  echo -e "\n${G}[+] WHOIS${NC}"
  whois "$TARGET" 2>/dev/null | grep -iE "Registrar:|Creation|Expir|Name Server|Country" | head -10 | sed 's/^/  /'

  echo -e "\n${G}[+] DNS Records${NC}"
  echo -ne "  A:     "; dig +short A     "$TARGET" 2>/dev/null | head -3 | tr '\n' ' '; echo
  echo -ne "  MX:    "; dig +short MX    "$TARGET" 2>/dev/null | head -3 | tr '\n' ' '; echo
  echo -ne "  NS:    "; dig +short NS    "$TARGET" 2>/dev/null | head -3 | tr '\n' ' '; echo
  echo -ne "  TXT:   "; dig +short TXT   "$TARGET" 2>/dev/null | head -2 | tr '\n' ' '; echo
  echo -ne "  CNAME: "; dig +short CNAME "$TARGET" 2>/dev/null | head -2 | tr '\n' ' '; echo

  echo -e "\n${G}[+] Subdomains (certificate transparency)${NC}"
  curl -s --max-time 12 "https://crt.sh/?q=%25.${TARGET}&output=json" 2>/dev/null \
    | python3 -c "
import sys,json
try:
  data=json.load(sys.stdin)
  names=sorted(set(
    n.strip() for x in data
    for n in x.get('name_value','').split('\n')
    if n.strip() and not n.startswith('*')
  ))
  for n in names[:25]: print(f'  {n}')
  if len(names)>25: print(f'  ... ({len(names)-25} more)')
except: print('  (error)')
" 2>/dev/null

  echo -e "\n${G}[+] Wayback Machine — snapshot count${NC}"
  curl -s --max-time 10 \
    "http://web.archive.org/cdx/search/cdx?url=${TARGET}&output=text&limit=1&fl=timestamp&from=20100101" \
    2>/dev/null | head -1 | awk '{print "  Oldest snapshot: "$1}' || echo "  (none)"

  echo -e "\n${G}[+] HTTP Fingerprint${NC}"
  curl -sI --max-time 8 "https://${TARGET}" 2>/dev/null \
    | grep -iE "^Server:|^X-Powered-By:|^X-Generator:|^Via:" | sed 's/^/  /'
}

# ── Email OSINT ────────────────────────────────────────────────────────
osint_email() {
  local domain="${TARGET##*@}"
  echo -e "\n${G}[+] Domain MX records${NC}"
  dig +short MX "$domain" 2>/dev/null | sed 's/^/  /'

  echo -e "\n${G}[+] Email domain info${NC}"
  curl -s --max-time 8 "http://ip-api.com/json/$domain" 2>/dev/null \
    | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  print(f'  Country: {d.get(\"country\",\"?\")}')
  print(f'  ISP: {d.get(\"isp\",\"?\")}')
except: pass
" 2>/dev/null

  echo -e "\n${G}[+] Certificate transparency (subdomains of $domain)${NC}"
  curl -s --max-time 10 "https://crt.sh/?q=%25.${domain}&output=json" 2>/dev/null \
    | python3 -c "
import sys,json
try:
  data=json.load(sys.stdin)
  names=sorted(set(
    n.strip() for x in data
    for n in x.get('name_value','').split('\n')
    if n.strip() and not n.startswith('*')
  ))
  for n in names[:15]: print(f'  {n}')
except: print('  (error)')
" 2>/dev/null

  echo -e "\n${G}[+] HaveIBeenPwned (requires API key for full results)${NC}"
  local hibp
  hibp=$(curl -s --max-time 10 -H "User-Agent: PhantomSec/1.3" \
    "https://haveibeenpwned.com/api/v3/breachedaccount/${TARGET}?truncateResponse=false" 2>/dev/null)
  if echo "$hibp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d))" 2>/dev/null | grep -q "^[1-9]"; then
    echo -e "  ${R}[!] Found in breaches:${NC}"
    echo "$hibp" | python3 -c "
import sys,json
try:
  for b in json.load(sys.stdin)[:10]:
    print(f'  • {b.get(\"Name\",\"?\")} ({b.get(\"BreachDate\",\"?\")})')
except: pass
" 2>/dev/null
  else
    echo -e "  ${Y}[!] API key required for HIBP — visit hibp.com/api${NC}"
  fi
}

# ── Username OSINT ─────────────────────────────────────────────────────
osint_username() {
  echo -e "\n${G}[+] Username search across platforms${NC}"
  echo -e "  ${DIM}ตรวจสอบว่า username มีอยู่หรือไม่ (HTTP 200 = found)${NC}"; echo ""

  local platforms=(
    "GitHub:https://github.com/$TARGET"
    "Twitter/X:https://twitter.com/$TARGET"
    "Instagram:https://www.instagram.com/$TARGET/"
    "Reddit:https://www.reddit.com/user/$TARGET"
    "TikTok:https://www.tiktok.com/@$TARGET"
    "YouTube:https://www.youtube.com/@$TARGET"
    "LinkedIn:https://www.linkedin.com/in/$TARGET"
    "Twitch:https://www.twitch.tv/$TARGET"
    "Steam:https://steamcommunity.com/id/$TARGET"
    "GitLab:https://gitlab.com/$TARGET"
    "Keybase:https://keybase.io/$TARGET"
    "HackerNews:https://news.ycombinator.com/user?id=$TARGET"
    "Dev.to:https://dev.to/$TARGET"
    "Medium:https://medium.com/@$TARGET"
    "Pastebin:https://pastebin.com/u/$TARGET"
  )

  for entry in "${platforms[@]}"; do
    local platform="${entry%%:*}"
    local url="${entry#*:}"
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 \
      -H "User-Agent: Mozilla/5.0 (Linux; Android 12; Termux) PhantomSec/1.3" \
      -L "$url" 2>/dev/null)
    case "$code" in
      200) echo -e "  ${G}[FOUND]${NC}   ${platform}:  $url" ;;
      404) echo -e "  ${DIM}[404]${NC}     ${platform}" ;;
      403) echo -e "  ${Y}[403]${NC}     ${platform}  ${DIM}(blocked)${NC}" ;;
      301|302) echo -e "  ${Y}[REDIR]${NC}   ${platform}" ;;
      000) echo -e "  ${DIM}[TIMEOUT]${NC} ${platform}" ;;
      *)   echo -e "  ${DIM}[${code}]${NC}      ${platform}" ;;
    esac
  done
}

# ── Run ────────────────────────────────────────────────────────────────
if is_ip; then
  echo -e "  ${C}Type detected: IP Address${NC}"
  osint_ip
elif is_email; then
  echo -e "  ${C}Type detected: Email${NC}"
  osint_email
elif is_domain; then
  echo -e "  ${C}Type detected: Domain${NC}"
  osint_domain
else
  echo -e "  ${C}Type detected: Username${NC}"
  osint_username
fi

echo ""
echo -e "${Y}[✓] OSINT complete for: $TARGET${NC}"
echo -e "${DIM}    ใช้เพื่อการป้องกันและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"

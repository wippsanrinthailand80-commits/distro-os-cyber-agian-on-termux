#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║          PhantomSec — Distro Feel Edition  v2.5.0                         ║
# ║          รองรับ Termux (Android) | macOS | Linux                        ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# GitHub: https://github.com/wippsanrinthailand80-commits/phantomsec-distro-feel

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="2.5.0"
PHANTOMSEC_DIR="${PHANTOMSEC_DIR:-$HOME/.phantomsec}"
LOG_DIR="$PHANTOMSEC_DIR/logs"
REPORT_DIR="$PHANTOMSEC_DIR/reports"
LANG_FILE="$PHANTOMSEC_DIR/lang"

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$PHANTOMSEC_DIR/profiles"

# ── Language (EN / TH) ──────────────────────────────────────────────────────
LANG_CODE="$(cat "$LANG_FILE" 2>/dev/null || echo 'en')"

_t() {
  # _t KEY  →  returns translation string
  local key="$1"
  if [ "$LANG_CODE" = "th" ]; then
    case "$key" in
      TITLE)         echo "PhantomSec — Distro Feel Edition" ;;
      SUBTITLE)      echo "ชุดเครื่องมือความปลอดภัยไซเบอร์บน Termux" ;;
      MAIN_MENU)     echo "เมนูหลัก" ;;
      NETWORK)       echo "🌐  เครือข่าย & การสแกน" ;;
      OSINT)         echo "🔍  OSINT & การลาดตระเวน" ;;
      WEBEXPLOIT)    echo "🕸️  ช่องโหว่เว็บ" ;;
      CRYPTO)        echo "🔐  เข้ารหัส & ถอดรหัส" ;;
      FORENSIC)      echo "🧬  นิติวิทยาศาสตร์ดิจิทัล" ;;
      PRIVESC)       echo "⬆️  การยกระดับสิทธิ์" ;;
      SETTINGS)      echo "⚙️  ตั้งค่า & ธีม" ;;
      ABOUT)         echo "ℹ️  เกี่ยวกับ" ;;
      EXIT)          echo "🚪  ออกจากโปรแกรม" ;;
      CHOOSE)        echo "เลือกตัวเลือก" ;;
      BACK)          echo "← กลับ" ;;
      ENTER)         echo "กด [ENTER] เพื่อดำเนินการต่อ..." ;;
      INVALID)       echo "ตัวเลือกไม่ถูกต้อง กรุณาลองใหม่" ;;
      TARGET)        echo "เป้าหมาย" ;;
      DONE)          echo "เสร็จสิ้น" ;;
      *)             echo "$key" ;;
    esac
  else
    case "$key" in
      TITLE)         echo "PhantomSec — Distro Feel Edition" ;;
      SUBTITLE)      echo "Cybersecurity Toolkit for Termux & Linux" ;;
      MAIN_MENU)     echo "Main Menu" ;;
      NETWORK)       echo "🌐  Network & Scanning" ;;
      OSINT)         echo "🔍  OSINT & Reconnaissance" ;;
      WEBEXPLOIT)    echo "🕸️  Web Exploitation" ;;
      CRYPTO)        echo "🔐  Crypto & Encoding" ;;
      FORENSIC)      echo "🧬  Digital Forensics" ;;
      PRIVESC)       echo "⬆️  Privilege Escalation" ;;
      SETTINGS)      echo "⚙️  Settings & Themes" ;;
      ABOUT)         echo "ℹ️  About" ;;
      EXIT)          echo "🚪  Exit" ;;
      CHOOSE)        echo "Choose option" ;;
      BACK)          echo "← Back" ;;
      ENTER)         echo "Press [ENTER] to continue..." ;;
      INVALID)       echo "Invalid option, please try again" ;;
      TARGET)        echo "Target" ;;
      DONE)          echo "Done" ;;
      *)             echo "$key" ;;
    esac
  fi
}

# ── Colours & styles ─────────────────────────────────────────────────────────
R='\033[0;31m'   G='\033[0;32m'   Y='\033[1;33m'
C='\033[0;36m'   M='\033[0;35m'   W='\033[1;37m'
B='\033[0;34m'   DIM='\033[2m'    BOLD='\033[1m'
BLINK='\033[5m'  UL='\033[4m'     NC='\033[0m'

# ── Active theme (loaded from config) ────────────────────────────────────────
THEME_FILE="$PHANTOMSEC_DIR/theme"
THEME="$(cat "$THEME_FILE" 2>/dev/null || echo 'phantom')"
source "$SCRIPT_DIR/themes/${THEME}.sh" 2>/dev/null || true

# ── Helpers ───────────────────────────────────────────────────────────────────
log() { echo "[$(date '+%T')] $*" >> "$LOG_DIR/session_$(date +%Y%m%d).log"; }
press_enter() { echo -e "\n${DIM}  $(_t ENTER)${NC}"; read -r; }

draw_line() {
  local char="${1:-═}" len="${2:-70}"
  printf "${M}"; printf '%0.s'"$char" $(seq 1 "$len"); printf "${NC}\n"
}

show_banner() {
  clear
  printf "${C}${BOLD}"
  cat << 'BANNER'

  ██████╗ ██╗  ██╗ █████╗ ███╗  ██╗████████╗ ██████╗ ███╗  ███╗
  ██╔══██╗██║  ██║██╔══██╗████╗ ██║╚══██╔══╝██╔═══██╗████╗████║
  ██████╔╝███████║███████║██╔██╗██║   ██║   ██║   ██║██╔████╔██║
  ██╔═══╝ ██╔══██║██╔══██║██║╚████║   ██║   ██║   ██║██║╚██╔╝██║
  ██║     ██║  ██║██║  ██║██║ ╚███║   ██║   ╚██████╔╝██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝

BANNER
  printf "${NC}"
  printf "  ${DIM}$(_t SUBTITLE)${NC}   ${M}v${VERSION}${NC}   ${DIM}[${LANG_CODE^^}]${NC}\n\n"
}

show_box() {
  local title="$1" width="${2:-68}"
  local inner=$((width - 2))
  printf "  ${M}╔"; printf '%0.s═' $(seq 1 $inner); printf "╗${NC}\n"
  printf "  ${M}║${NC}${BOLD}  %-$((inner-2))s${M}║${NC}\n" "$title"
  printf "  ${M}╚"; printf '%0.s═' $(seq 1 $inner); printf "╝${NC}\n"
}

menu_item() {
  local num="$1" label="$2"
  printf "  ${M}[${C}${BOLD}%-2s${NC}${M}]${NC}  %s\n" "$num" "$label"
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" &>/dev/null; then
    echo -e "${Y}[!] '$tool' not installed.${NC}"
    if command -v pkg &>/dev/null; then
      echo -ne "  Install now? [y/N] "; read -r yn
      [ "${yn,,}" = "y" ] && pkg install -y "$tool"
    elif command -v apt-get &>/dev/null; then
      echo -ne "  Install now? [y/N] "; read -r yn
      [ "${yn,,}" = "y" ] && sudo apt-get install -y "$tool"
    fi
    return 1
  fi
  return 0
}

prompt_target() {
  local label="${1:-$(_t TARGET)}"
  echo -ne "  ${C}$label:${NC} "; read -r TARGET
  echo "$TARGET"
}

# ── Network & Scanning ────────────────────────────────────────────────────────
menu_network() {
  while true; do
    show_banner; show_box "  $(_t NETWORK)"
    echo ""
    menu_item "1"  "Network Info (IP, gateway, DNS, interfaces)"
    menu_item "2"  "Host Discovery (ping sweep)"
    menu_item "3"  "Port Scan (nmap)"
    menu_item "4"  "MAC Vendor Lookup"
    menu_item "5"  "Traceroute"
    menu_item "6"  "ARP Table"
    menu_item "0"  "$(_t BACK)"
    echo ""
    echo -ne "  ${M}▶ $(_t CHOOSE): ${NC}"; read -r choice
    case "$choice" in
      1) bash "$SCRIPT_DIR/modules/nettools.sh" ;;
      2) T=$(prompt_target "Subnet (e.g. 192.168.1.0/24)")
         require_tool nmap && nmap -sn "$T" | grep -E "Nmap|Host is" ;;
      3) T=$(prompt_target "Target IP/hostname")
         require_tool nmap
         echo -ne "  ${C}Scan type [quick/full/udp]:${NC} "; read -r stype
         case "$stype" in
           full) nmap -sV -sC -O "$T" ;;
           udp)  sudo nmap -sU --top-ports 200 "$T" ;;
           *)    nmap -F "$T" ;;
         esac ;;
      4) echo -ne "  ${C}MAC address:${NC} "; read -r mac
         curl -s --max-time 8 "https://api.macvendors.com/$mac" && echo "" ;;
      5) T=$(prompt_target)
         require_tool traceroute && traceroute "$T" ;;
      6) arp -n 2>/dev/null || ip neigh show ;;
      0) return ;;
      *) echo -e "${R}  $(_t INVALID)${NC}" ;;
    esac
    press_enter
  done
}

# ── OSINT & Recon ─────────────────────────────────────────────────────────────
menu_osint() {
  while true; do
    show_banner; show_box "  $(_t OSINT)"
    echo ""
    menu_item "1"  "Full OSINT (IP / domain / email / username)"
    menu_item "2"  "WHOIS lookup"
    menu_item "3"  "DNS records (A, MX, NS, TXT, AAAA)"
    menu_item "4"  "Subdomain enumeration"
    menu_item "5"  "SSL/TLS certificate info"
    menu_item "6"  "GeoIP lookup"
    menu_item "7"  "Shodan quick check"
    menu_item "0"  "$(_t BACK)"
    echo ""
    echo -ne "  ${M}▶ $(_t CHOOSE): ${NC}"; read -r choice
    case "$choice" in
      1) T=$(prompt_target); bash "$SCRIPT_DIR/modules/osint.sh" "$T" ;;
      2) T=$(prompt_target "Domain/IP"); whois "$T" 2>/dev/null | head -40 ;;
      3) T=$(prompt_target "Domain")
         for rec in A AAAA MX NS TXT SOA; do
           echo -e "\n${G}[$rec]${NC}"
           dig +short "$rec" "$T" 2>/dev/null | sed 's/^/  /'
         done ;;
      4) T=$(prompt_target "Domain")
         require_tool subfinder && subfinder -d "$T" -silent 2>/dev/null || \
         { require_tool amass && amass enum -passive -d "$T" 2>/dev/null; } ;;
      5) T=$(prompt_target "Domain")
         echo | openssl s_client -connect "$T:443" 2>/dev/null | \
           openssl x509 -noout -text 2>/dev/null | grep -E "Subject:|Issuer:|Not Before|Not After|DNS:" | head -20 ;;
      6) T=$(prompt_target "IP/Domain")
         curl -s "http://ip-api.com/json/$T" 2>/dev/null | \
           node -e "const d=[]; process.stdin.on('data',c=>d.push(c)); process.stdin.on('end',()=>{
             const r=JSON.parse(d.join(''));
             Object.entries(r).forEach(([k,v])=>console.log('  '+k+': '+v));
           })" 2>/dev/null || python3 -c "
import sys,json,urllib.request
r=json.load(urllib.request.urlopen('http://ip-api.com/json/$T'))
[print(f'  {k}: {v}') for k,v in r.items()]" 2>/dev/null ;;
      7) T=$(prompt_target "IP")
         curl -s "https://internetdb.shodan.io/$T" 2>/dev/null | python3 -m json.tool 2>/dev/null ;;
      0) return ;;
      *) echo -e "${R}  $(_t INVALID)${NC}" ;;
    esac
    press_enter
  done
}

# ── Web Exploitation ──────────────────────────────────────────────────────────
menu_webexploit() {
  while true; do
    show_banner; show_box "  $(_t WEBEXPLOIT)"
    echo ""
    menu_item "1"  "HTTP Headers & Tech fingerprint"
    menu_item "2"  "Directory brute-force (gobuster/ffuf)"
    menu_item "3"  "Parameter fuzzing"
    menu_item "4"  "SQL injection test (sqlmap)"
    menu_item "5"  "XSS payload generator"
    menu_item "6"  "JWT Decoder"
    menu_item "7"  "CORS misconfiguration check"
    menu_item "8"  "WAF detection"
    menu_item "0"  "$(_t BACK)"
    echo ""
    echo -ne "  ${M}▶ $(_t CHOOSE): ${NC}"; read -r choice
    case "$choice" in
      1) T=$(prompt_target "URL (https://...)")
         echo -e "\n${G}HTTP Headers:${NC}"
         curl -sI "$T" 2>/dev/null | head -30
         echo -e "\n${G}Tech detection (whatweb):${NC}"
         require_tool whatweb && whatweb "$T" 2>/dev/null ;;
      2) T=$(prompt_target "URL")
         W="${SCRIPT_DIR}/wordlists/common.txt"
         [ ! -f "$W" ] && W="/usr/share/wordlists/dirb/common.txt"
         if require_tool ffuf; then
           ffuf -u "$T/FUZZ" -w "$W" -mc 200,301,302,403 -of json -o "$REPORT_DIR/dirfuzz_$(date +%s).json" 2>/dev/null
         elif require_tool gobuster; then
           gobuster dir -u "$T" -w "$W" -o "$REPORT_DIR/gobuster_$(date +%s).txt" 2>/dev/null
         fi ;;
      3) T=$(prompt_target "URL with parameter (e.g. https://site.com/page?id=1)")
         require_tool ffuf && ffuf -u "$T" -w "$SCRIPT_DIR/wordlists/params.txt:FUZZ" 2>/dev/null ;;
      4) T=$(prompt_target "URL")
         require_tool sqlmap && sqlmap -u "$T" --batch --level=2 --risk=2 2>/dev/null | tail -30 ;;
      5) echo -e "\n${G}XSS Payloads:${NC}"
         cat << 'XSS'
  <script>alert(1)</script>
  <img src=x onerror=alert(1)>
  <svg onload=alert(1)>
  "><script>alert(document.domain)</script>
  javascript:alert(1)
  '-alert(1)-'
  \x3cscript\x3ealert(1)\x3c/script\x3e
XSS
         ;;
      6) echo -ne "  ${C}Paste JWT:${NC} "; read -r jwt
         python3 -c "
import base64,json,sys
parts='$jwt'.split('.')
for i,p in enumerate(['HEADER','PAYLOAD']):
    b=p+':\\n'
    try:
        dec=base64.urlsafe_b64decode(parts[i]+'==')
        b+=json.dumps(json.loads(dec),indent=2)
    except: b+='(decode error)'
    print(b)
print('SIGNATURE: (not verified)\\n'+parts[2][:30]+'...')" 2>/dev/null ;;
      7) T=$(prompt_target "URL")
         echo -e "\n${G}CORS check:${NC}"
         curl -sI -H "Origin: https://evil.com" "$T" 2>/dev/null | grep -i "Access-Control" || echo "  No CORS headers found" ;;
      8) T=$(prompt_target "URL")
         echo -e "\n${G}WAF detection:${NC}"
         require_tool wafw00f && wafw00f "$T" 2>/dev/null || \
           curl -sI "$T" 2>/dev/null | grep -iE "cloudflare|sucuri|akamai|imperva|f5|barracuda|server" ;;
      0) return ;;
      *) echo -e "${R}  $(_t INVALID)${NC}" ;;
    esac
    press_enter
  done
}

# ── Crypto & Encoding ─────────────────────────────────────────────────────────
menu_crypto() {
  while true; do
    show_banner; show_box "  $(_t CRYPTO)"
    echo ""
    menu_item "1"  "Hash generator (MD5/SHA1/SHA256/SHA512)"
    menu_item "2"  "Base64 encode/decode"
    menu_item "3"  "URL encode/decode"
    menu_item "4"  "Hex encode/decode"
    menu_item "5"  "ROT13"
    menu_item "6"  "OpenSSL encrypt/decrypt file"
    menu_item "7"  "Password hash (bcrypt/sha-crypt)"
    menu_item "8"  "Generate random secret key"
    menu_item "0"  "$(_t BACK)"
    echo ""
    echo -ne "  ${M}▶ $(_t CHOOSE): ${NC}"; read -r choice
    case "$choice" in
      1) echo -ne "  ${C}Input:${NC} "; read -r inp
         echo -e "\n  ${G}MD5:${NC}    $(echo -n "$inp" | md5sum | cut -d' ' -f1)"
         echo -e "  ${G}SHA1:${NC}   $(echo -n "$inp" | sha1sum | cut -d' ' -f1)"
         echo -e "  ${G}SHA256:${NC} $(echo -n "$inp" | sha256sum | cut -d' ' -f1)"
         echo -e "  ${G}SHA512:${NC} $(echo -n "$inp" | sha512sum | cut -d' ' -f1)" ;;
      2) echo -e "  ${M}[1]${NC} Encode  ${M}[2]${NC} Decode"
         echo -ne "  Mode: "; read -r m
         echo -ne "  ${C}Input:${NC} "; read -r inp
         [ "$m" = "1" ] && echo -n "$inp" | base64 || echo "$inp" | base64 -d ;;
      3) echo -ne "  ${C}Input:${NC} "; read -r inp
         python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$inp" 2>/dev/null ;;
      4) echo -e "  ${M}[1]${NC} Encode  ${M}[2]${NC} Decode"
         echo -ne "  Mode: "; read -r m
         echo -ne "  ${C}Input:${NC} "; read -r inp
         [ "$m" = "1" ] && echo -n "$inp" | xxd -p | tr -d '\n' && echo \
                        || echo "$inp" | xxd -r -p ;;
      5) echo -ne "  ${C}Input:${NC} "; read -r inp
         echo "$inp" | tr 'A-Za-z' 'N-ZA-Mn-za-m' ;;
      6) echo -e "  ${M}[1]${NC} Encrypt  ${M}[2]${NC} Decrypt"
         echo -ne "  Mode: "; read -r m
         echo -ne "  ${C}File:${NC} "; read -r f
         [ "$m" = "1" ] && openssl enc -aes-256-cbc -pbkdf2 -in "$f" -out "${f}.enc" \
                        || openssl enc -d -aes-256-cbc -pbkdf2 -in "$f" -out "${f%.enc}.dec" ;;
      7) echo -ne "  ${C}Password:${NC} "; read -rs pw; echo ""
         python3 -c "
import crypt,hashlib,os
salt=crypt.mksalt(crypt.METHOD_SHA512)
print('  SHA512-crypt:',crypt.crypt('$pw',salt))
print('  SHA256:     ',hashlib.sha256('$pw'.encode()).hexdigest())" 2>/dev/null ;;
      8) echo -e "\n  ${G}Random keys:${NC}"
         echo "  32-byte hex:  $(openssl rand -hex 32)"
         echo "  64-byte hex:  $(openssl rand -hex 64)"
         echo "  Base64 32b:   $(openssl rand -base64 32)"
         echo "  UUID:         $(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || openssl rand -hex 16 | sed 's/\(.\{8\}\)\(.\{4\}\)\(.\{4\}\)\(.\{4\}\)/\1-\2-\3-\4-/')" ;;
      0) return ;;
      *) echo -e "${R}  $(_t INVALID)${NC}" ;;
    esac
    press_enter
  done
}

# ── Digital Forensics ─────────────────────────────────────────────────────────
menu_forensic() {
  while true; do
    show_banner; show_box "  $(_t FORENSIC)"
    echo ""
    menu_item "1"  "File magic & metadata (file, exiftool)"
    menu_item "2"  "Strings extraction"
    menu_item "3"  "Entropy analysis (detect encrypted/compressed)"
    menu_item "4"  "Network capture (tcpdump)"
    menu_item "5"  "Process forensics (lsof, netstat, /proc)"
    menu_item "6"  "Log analysis (auth, syslog)"
    menu_item "0"  "$(_t BACK)"
    echo ""
    echo -ne "  ${M}▶ $(_t CHOOSE): ${NC}"; read -r choice
    case "$choice" in
      1) echo -ne "  ${C}File:${NC} "; read -r f
         file "$f" 2>/dev/null
         require_tool exiftool && exiftool "$f" 2>/dev/null | head -30 ;;
      2) echo -ne "  ${C}File:${NC} "; read -r f
         strings "$f" 2>/dev/null | grep -v "^.$" | head -60 ;;
      3) echo -ne "  ${C}File:${NC} "; read -r f
         python3 -c "
import sys,math
data=open('$f','rb').read()[:65536]
freq=[0]*256
for b in data: freq[b]+=1
n=len(data)
ent=sum(-p/n*math.log2(p/n) for p in freq if p>0)
print(f'  Entropy: {ent:.4f} bits/byte')
print(f'  Size sampled: {n} bytes')
if ent>7.5: print('  !! HIGH entropy — likely encrypted or compressed')
elif ent>6:  print('  ~ Medium entropy — possibly compressed')
else:        print('  OK Normal entropy — plaintext/source')
" 2>/dev/null ;;
      4) echo -ne "  ${C}Interface [eth0]:${NC} "; read -r iface; iface="${iface:-eth0}"
         echo -ne "  ${C}Output file:${NC} "; read -r cap
         echo -e "${Y}  Capturing on $iface — Ctrl+C to stop${NC}"
         sudo tcpdump -i "$iface" -w "${cap:-capture.pcap}" 2>/dev/null ;;
      5) echo -e "\n${G}  Open files & connections:${NC}"
         lsof -i 2>/dev/null | head -20 || netstat -tuln 2>/dev/null | head -20
         echo -e "\n${G}  Top processes:${NC}"
         ps aux --sort=-%cpu 2>/dev/null | head -15 ;;
      6) echo -e "\n${G}  Auth log (last 20 lines):${NC}"
         sudo tail -20 /var/log/auth.log 2>/dev/null || sudo tail -20 /var/log/secure 2>/dev/null || echo "  (no auth log found)"
         echo -e "\n${G}  Failed SSH logins:${NC}"
         sudo grep -c "Failed password" /var/log/auth.log 2>/dev/null | xargs -I{} echo "  {} failed attempts" ;;
      0) return ;;
      *) echo -e "${R}  $(_t INVALID)${NC}" ;;
    esac
    press_enter
  done
}

# ── Privilege Escalation ──────────────────────────────────────────────────────
menu_privesc() {
  while true; do
    show_banner; show_box "  $(_t PRIVESC)"
    echo ""
    menu_item "1"  "SUID/SGID binaries"
    menu_item "2"  "Writable system paths"
    menu_item "3"  "Sudo permissions"
    menu_item "4"  "Cron jobs (all users)"
    menu_item "5"  "Capabilities (getcap)"
    menu_item "6"  "World-writable /etc files"
    menu_item "7"  "LinPEAS / run checker"
    menu_item "0"  "$(_t BACK)"
    echo ""
    echo -ne "  ${M}▶ $(_t CHOOSE): ${NC}"; read -r choice
    case "$choice" in
      1) echo -e "\n${G}  SUID binaries:${NC}"
         find / -perm -4000 -type f 2>/dev/null | head -30 | sed 's/^/  /'
         echo -e "\n${G}  SGID binaries:${NC}"
         find / -perm -2000 -type f 2>/dev/null | head -20 | sed 's/^/  /' ;;
      2) echo -e "\n${G}  Writable dirs in PATH:${NC}"
         IFS=: read -ra dirs <<< "$PATH"
         for d in "${dirs[@]}"; do [ -w "$d" ] && echo "  WRITABLE: $d"; done
         echo -e "\n${G}  Writable /etc files:${NC}"
         find /etc -writable -type f 2>/dev/null | head -20 | sed 's/^/  /' ;;
      3) sudo -l 2>/dev/null ;;
      4) echo -e "\n${G}  System cron jobs:${NC}"
         ls -la /etc/cron* /var/spool/cron 2>/dev/null
         cat /etc/crontab 2>/dev/null
         for u in $(cut -f1 -d: /etc/passwd); do
           crontab -u "$u" -l 2>/dev/null | grep -v "^#" | sed "s/^/  [$u] /"
         done ;;
      5) getcap -r / 2>/dev/null | sed 's/^/  /' ;;
      6) find /etc -perm -0002 -type f 2>/dev/null | sed 's/^/  /' ;;
      7) if command -v linpeas.sh &>/dev/null; then
           linpeas.sh 2>/dev/null | tee "$REPORT_DIR/linpeas_$(date +%s).txt"
         else
           echo -e "${Y}  Download linpeas:${NC}"
           echo "  curl -sL https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh"
         fi ;;
      0) return ;;
      *) echo -e "${R}  $(_t INVALID)${NC}" ;;
    esac
    press_enter
  done
}

# ── Settings & Themes ─────────────────────────────────────────────────────────
menu_settings() {
  while true; do
    show_banner; show_box "  $(_t SETTINGS)"
    echo ""
    menu_item "1"  "Theme: phantom (cyan/dark)    $([ "$THEME" = "phantom" ] && echo '✓' || echo '')"
    menu_item "2"  "Theme: matrix (green/black)   $([ "$THEME" = "matrix" ] && echo '✓' || echo '')"
    menu_item "3"  "Theme: blood (red/dark)       $([ "$THEME" = "blood" ] && echo '✓' || echo '')"
    menu_item "4"  "Theme: stealth (minimal gray) $([ "$THEME" = "stealth" ] && echo '✓' || echo '')"
    menu_item "5"  "Language: English / ภาษาไทย   [$(echo $LANG_CODE | tr a-z A-Z)]"
    menu_item "6"  "Open logs directory"
    menu_item "7"  "Clear session logs"
    menu_item "0"  "$(_t BACK)"
    echo ""
    echo -ne "  ${M}▶ $(_t CHOOSE): ${NC}"; read -r choice
    case "$choice" in
      1|2|3|4)
        themes=("" "phantom" "matrix" "blood" "stealth")
        THEME="${themes[$choice]}"
        echo "$THEME" > "$THEME_FILE"
        echo -e "${G}  Theme set: $THEME${NC}" ;;
      5) [ "$LANG_CODE" = "en" ] && LANG_CODE="th" || LANG_CODE="en"
         echo "$LANG_CODE" > "$LANG_FILE"
         echo -e "${G}  Language: $LANG_CODE${NC}" ;;
      6) ls -la "$LOG_DIR" ;;
      7) rm -f "$LOG_DIR"/*.log && echo -e "${G}  Logs cleared${NC}" ;;
      0) return ;;
    esac
    press_enter
  done
}

# ── About ─────────────────────────────────────────────────────────────────────
show_about() {
  show_banner; show_box "  $(_t ABOUT)"
  echo ""
  echo -e "  ${W}PhantomSec — Distro Feel Edition v${VERSION}${NC}"
  echo -e "  ${DIM}Termux/Linux cybersecurity toolkit${NC}"
  echo ""
  echo -e "  ${C}GitHub:${NC}   https://github.com/wippsanrinthailand80-commits/phantomsec-distro-feel"
  echo -e "  ${C}Real OS:${NC}  https://github.com/wippsanrinthailand80-commits/phantomsec-os"
  echo ""
  echo -e "  ${G}This version:${NC} Shell-based toolkit — runs anywhere Bash runs"
  echo -e "  ${G}Real distro:${NC}  C/C++ Linux from scratch with original security tools"
  echo ""
  echo -e "  ${DIM}ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น${NC}"
  echo -e "  ${DIM}For authorized security testing and research only.${NC}"
  echo ""
  press_enter
}

# ── Main loop ─────────────────────────────────────────────────────────────────
main() {
  while true; do
    show_banner
    show_box "  $(_t MAIN_MENU)"
    echo ""
    menu_item "1"  "$(_t NETWORK)"
    menu_item "2"  "$(_t OSINT)"
    menu_item "3"  "$(_t WEBEXPLOIT)"
    menu_item "4"  "$(_t CRYPTO)"
    menu_item "5"  "$(_t FORENSIC)"
    menu_item "6"  "$(_t PRIVESC)"
    echo ""
    menu_item "s"  "$(_t SETTINGS)"
    menu_item "a"  "$(_t ABOUT)"
    menu_item "0"  "$(_t EXIT)"
    echo ""
    echo -ne "  ${M}▶ $(_t CHOOSE): ${NC}"; read -r choice

    case "$choice" in
      1) menu_network ;;
      2) menu_osint ;;
      3) menu_webexploit ;;
      4) menu_crypto ;;
      5) menu_forensic ;;
      6) menu_privesc ;;
      s) menu_settings ;;
      a) show_about ;;
      0) show_banner
         echo -e "\n  ${C}${DIM}Phantom out. Stay invisible.${NC}\n"
         exit 0 ;;
      *) echo -e "${R}  $(_t INVALID)${NC}"; sleep 1 ;;
    esac
  done
}

main

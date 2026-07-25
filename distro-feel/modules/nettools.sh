#!/usr/bin/env bash
# PhantomSec — Network Tools Module (called by phantomsec.sh)
G='\033[0;32m' NC='\033[0m' C='\033[0;36m' Y='\033[1;33m'
echo -e "\n${G}[+] Network Interfaces${NC}"
ip addr 2>/dev/null | grep -E "inet |link/ether" | awk '{print "  "$1" "$2}' || ifconfig 2>/dev/null | grep -E "inet|ether"
echo -e "\n${G}[+] Default Gateway${NC}"
ip route 2>/dev/null | grep default || netstat -rn 2>/dev/null | head -5
echo -e "\n${G}[+] DNS Servers${NC}"
cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print "  "$2}'
echo -e "\n${G}[+] Open Ports${NC}"
ss -tuln 2>/dev/null | grep LISTEN | head -20 || netstat -tuln 2>/dev/null | grep LISTEN | head -20

#!/usr/bin/env bash
# PhantomSec — Password Generator
# Usage: ps-passgen [length] [count] [charset]

set -euo pipefail

LENGTH="${1:-16}"
COUNT="${2:-5}"
CHARSET="${3:-alphanumeric}"

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' Y='\033[1;33m' B='\033[1m'

echo -e "\n${G}[+] Password Generator${NC}"
echo -e "  ${C}Length: $LENGTH | Count: $COUNT | Charset: $CHARSET${NC}"
echo ""

case "$CHARSET" in
  lower)   chars='abcdefghijklmnopqrstuvwxyz' ;;
  upper)   chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ' ;;
  digits)  chars='0123456789' ;;
  symbols) chars='!@#$%^&*()-_=+[]{}|;:<>?/' ;;
  hex)     chars='0123456789abcdef' ;;
  all)     chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:<>?/' ;;
  *)       chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' ;;
esac

CSIZE=${#chars}

for i in $(seq 1 "$COUNT"); do
  pass=""
  for j in $(seq 1 "$LENGTH"); do
    idx=$(od -An -tu2 -N2 /dev/urandom 2>/dev/null | tr -d ' ')
    idx=$((idx % CSIZE))
    pass="${pass}${chars:$idx:1}"
  done
  echo -e "  ${B}$i:${NC} $pass"
done
echo ""

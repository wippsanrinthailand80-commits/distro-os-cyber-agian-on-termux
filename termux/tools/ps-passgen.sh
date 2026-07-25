#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec Termux — Password Generator
# Usage: ps-passgen [length] [count] [charset]

LENGTH="${1:-16}"
COUNT="${2:-5}"
CHARSET="${3:-alphanumeric}"

G='\033[0;32m' C='\033[0;36m' NC='\033[0m' Y='\033[1;33m'

echo -e "\n${G}[+] Password Generator${NC}"
echo "  Length: $LENGTH | Count: $COUNT | Charset: $CHARSET"

case "$CHARSET" in
  lower)     chars='abcdefghijklmnopqrstuvwxyz' ;;
  upper)     chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ' ;;
  digits)    chars='0123456789' ;;
  symbols)   chars='!@#$%^&*()-_=+[]{}|;:<>?/' ;;
  hex)       chars='0123456789abcdef' ;;
  all)       chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:<>?/' ;;
  *)         chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' ;;
esac

CSIZE=${#chars}
ENTROPY=$(echo "l($LENGTH * $CSIZE)/l(2)" | bc -l 2>/dev/null | cut -d. -f1)
echo "  Entropy: ~${ENTROPY:-?} bits\n"

for i in $(seq 1 "$COUNT"); do
  pass=""
  for j in $(seq 1 "$LENGTH"); do
    idx=$(($RANDOM % CSIZE))
    pass="${pass}${chars:$idx:1}"
  done
  echo "  $i: $pass"
done
echo ""

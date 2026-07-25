#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Matrix Rain Theme
# Run this for a cool matrix effect in terminal

R='\033[0;32m' NC='\033[0m'

cols=$(tput cols 2>/dev/null || echo 80)
chars="ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789ABCDEF"
len=${#chars}

echo -e "${R}"
trap 'echo -e "\033[0m"; exit 0' INT
while true; do
  for i in $(seq 1 $((cols / 2))); do
    printf "%s" "${chars:$((RANDOM % len)):1}"
    [ $((RANDOM % 3)) -eq 0 ] && printf " " || printf ""
  done
  echo ""
  sleep 0.05
done

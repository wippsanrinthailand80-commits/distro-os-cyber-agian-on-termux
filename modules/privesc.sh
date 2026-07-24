#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Privilege Escalation Recon Module (standalone)
# Usage: bash privesc.sh
#
# Checks for common local privilege escalation vectors.
# Works on Android/Termux and standard Linux environments.
# ⚠️  For educational / CTF / authorized testing only.

G='\033[0;32m' R='\033[0;31m' Y='\033[1;33m'
C='\033[0;36m' M='\033[0;35m' NC='\033[0m' DIM='\033[2m'

echo -e "${M}[PhantomSec PrivEsc Recon]${NC}"
echo "─────────────────────────────────────────────────────"

# ── 1. Current user info ───────────────────────────────────────────────
echo -e "\n${G}[+] Current User${NC}"
id 2>/dev/null
whoami 2>/dev/null

# ── 2. Sudo rights ────────────────────────────────────────────────────
echo -e "\n${G}[+] Sudo Privileges${NC}"
if command -v sudo &>/dev/null; then
  sudo -l 2>/dev/null | head -20 || echo -e "  ${Y}[!] Cannot list sudo rules${NC}"
else
  echo -e "  ${DIM}sudo not available${NC}"
fi

# ── 3. SUID binaries ──────────────────────────────────────────────────
echo -e "\n${G}[+] SUID Binaries (world-executable)${NC}"
# จำกัด maxdepth=8 และ exclude /proc /sys /dev เพื่อป้องกัน hang บน Android
find / -maxdepth 8 -perm -4000 -type f \
  ! -path "/proc/*" ! -path "/sys/*" ! -path "/dev/*" ! -path "/apex/*" \
  2>/dev/null | head -20 | while read -r bin; do
  echo -e "  ${Y}$bin${NC}"
done
echo -e "  ${DIM}(truncated to top 20, maxdepth=8, excluding /proc /sys /dev /apex)${NC}"

# ── 4. World-writable directories ─────────────────────────────────────
echo -e "\n${G}[+] World-Writable Directories${NC}"
find / -maxdepth 5 -type d -perm -o+w \
  ! -path "/proc/*" ! -path "/sys/*" ! -path "/dev/*" \
  2>/dev/null | head -10 | while read -r d; do
  echo -e "  ${Y}$d${NC}"
done

# ── 5. Interesting environment variables ──────────────────────────────
echo -e "\n${G}[+] Environment Variables (filtered)${NC}"
env 2>/dev/null | grep -iE "path|home|shell|user|pass|key|token|secret|api" | grep -v "^_=" | head -20

# ── 6. Cron jobs ──────────────────────────────────────────────────────
echo -e "\n${G}[+] Cron Jobs${NC}"
for f in /etc/crontab /etc/cron.d/* /var/spool/cron/crontabs/*; do
  [ -r "$f" ] 2>/dev/null && echo -e "  ${C}$f:${NC}" && grep -v "^#\|^$" "$f" 2>/dev/null | head -10
done
crontab -l 2>/dev/null | head -10

# ── 7. Network services ───────────────────────────────────────────────
echo -e "\n${G}[+] Listening Services${NC}"
ss -tuln 2>/dev/null | grep LISTEN | awk '{print "  "$1"\t"$5}' | head -15 \
  || netstat -tuln 2>/dev/null | grep LISTEN | head -15

# ── 8. Interesting files ──────────────────────────────────────────────
echo -e "\n${G}[+] Interesting Files${NC}"
for f in /etc/passwd /etc/shadow /etc/sudoers ~/.ssh/id_rsa ~/.bash_history ~/.zsh_history; do
  if [ -r "$f" ]; then
    echo -e "  ${G}[READABLE]${NC}  $f"
  elif [ -e "$f" ]; then
    echo -e "  ${Y}[EXISTS]  ${NC}  $f (not readable)"
  fi
done

# ── 9. OS & kernel info ───────────────────────────────────────────────
echo -e "\n${G}[+] OS / Kernel Info${NC}"
uname -a 2>/dev/null
cat /etc/os-release 2>/dev/null | grep -E "^NAME|^VERSION" || true

echo ""
echo -e "${Y}[✓] PrivEsc recon complete. Review the above for potential attack surfaces.${NC}"
echo -e "${DIM}    Always obtain written permission before testing systems you don't own.${NC}"
echo ""

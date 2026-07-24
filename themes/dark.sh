#!/data/data/com.termux/files/usr/bin/bash
# PhantomSec — Dark Theme Configurator
# Sets the terminal to a minimal dark colour scheme

echo -e "\033[0;35m[PhantomSec] Applying dark theme...\033[0m"

# Reset to dark background (works on most terminals)
printf '\033]11;#0d0d0d\007'  # background
printf '\033]10;#e0e0e0\007'  # foreground

# Print a preview swatch
echo ""
echo -e "\033[1;37m  ── Dark Theme Preview ──\033[0m"
echo -e "\033[0;31m  ▌ Red     \033[0m\033[0;32m▌ Green   \033[0m\033[1;33m▌ Yellow  \033[0m"
echo -e "\033[0;34m  ▌ Blue    \033[0m\033[0;35m▌ Magenta \033[0m\033[0;36m▌ Cyan    \033[0m"
echo -e "\033[1;37m  ▌ White   \033[0m\033[2m▌ Dim     \033[0m\033[1m▌ Bold    \033[0m"
echo ""
echo -e "\033[0;32m[✓] Dark theme applied.\033[0m"
echo -e "\033[2m    To make permanent, add 'bash themes/dark.sh' to ~/.bashrc\033[0m"
echo ""

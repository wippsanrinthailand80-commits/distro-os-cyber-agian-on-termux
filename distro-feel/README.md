# PhantomSec — Distro Feel Edition v2.5.2

> *The cybersecurity toolkit that makes your terminal feel like a distro — without needing one.*

[![Platform](https://img.shields.io/badge/platform-Termux%20%7C%20Linux%20%7C%20macOS-00d4ff?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux)
[![Language](https://img.shields.io/badge/language-Bash-00d4ff?style=flat-square)](phantomsec.sh)
[![Version](https://img.shields.io/badge/version-2.5.2-00d4ff?style=flat-square)](VERSION)

> **This is the Distro Feel Edition** — a lightweight shell toolkit that gives you the feel of a security distro without being one.  
> Looking for the full toolkit? → [Main Edition](../README.md)  
> Looking for the real C/C++ OS? → [PhantomSec OS](../os/README.md)

---

## ⚡ One-Line Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/distro-feel/install.sh)
```

---

## Features

| Module | What it does |
|--------|-------------|
| 🌐 **Network** | Interface info, host discovery, port scan, MAC vendor, traceroute |
| 🔍 **OSINT** | IP/domain/email/username, WHOIS, DNS, subdomains, SSL, Shodan |
| 🕸️ **Web Exploit** | Headers, dir brute-force, SQLi, XSS, JWT decoder, CORS, WAF |
| 🔐 **Crypto** | Hash, Base64, URL/hex encode, ROT13, OpenSSL encrypt, random key gen |
| 🧬 **Forensics** | File magic, strings, entropy analysis, pcap capture, process forensics |
| ⬆️ **PrivEsc** | SUID/SGID, writable paths, sudo perms, cron jobs, capabilities |
| ⚙️ **Settings** | 4 themes · EN/TH language toggle |

---

## Quick Start

```bash
# Termux (Android)
pkg update && pkg install git curl nmap python
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/distro-feel/install.sh)

# Linux / macOS
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/distro-feel/install.sh)
```

---

## Themes

| Theme | Style |
|-------|-------|
| `phantom` | Cyan / void black (default) |
| `matrix` | Green / black |
| `blood` | Red / dark |
| `stealth` | Minimal gray |

---

## Language / ภาษา

```bash
PHANTOMSEC_LANG=th bash phantomsec.sh   # Thai
PHANTOMSEC_LANG=en bash phantomsec.sh   # English (default)
```

---

← [Back to main project](../README.md)

MIT — for authorized security testing and educational research only.

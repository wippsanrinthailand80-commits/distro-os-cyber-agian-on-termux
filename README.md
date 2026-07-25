# PhantomSec v2.0.1

> *Cybersecurity toolkit — two editions, one repo.*

[![Platform](https://img.shields.io/badge/platform-Termux%20%7C%20Linux%20%7C%20macOS-00d4ff?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux)
[![Language](https://img.shields.io/badge/language-Bash-00d4ff?style=flat-square)](phantomsec.sh)
[![i18n](https://img.shields.io/badge/i18n-English%20%7C%20%E0%B8%A0%E0%B8%B2%E0%B8%A9%E0%B8%B2%E0%B9%84%E0%B8%97%E0%B8%A2-00d4ff?style=flat-square)](phantomsec.sh)
[![Version](https://img.shields.io/badge/version-2.0.1-00d4ff?style=flat-square)](VERSION)

---

## Two Editions

| | Main Edition | Distro Feel Edition |
|---|---|---|
| **Folder** | `/` (root) | `distro-feel/` |
| **What it is** | Full-featured cybersecurity toolkit | Same features, lighter feel — no real distro |
| **One-line install** | `bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/install.sh)` | `bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/distro-feel/install.sh)` |

---

## ⚡ One-Line Install

### Main Edition
```bash
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/install.sh)
```

### Distro Feel Edition
```bash
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/distro-feel/install.sh)
```

---

## Features

| Module | What it does |
|--------|-------------|
| 🌐 **Network** | Interface info, host discovery, port scan, MAC vendor, traceroute |
| 🔍 **OSINT** | Full OSINT (IP/domain/email/username), WHOIS, DNS, subdomains, SSL, Shodan |
| 🕸️ **Web Exploit** | Headers, dir brute-force, SQLi, XSS payloads, JWT decoder, CORS, WAF |
| 🔐 **Crypto** | Hash, Base64, URL/hex encode, ROT13, OpenSSL encrypt, random key gen |
| 🧬 **Forensics** | File magic, strings, entropy analysis, pcap capture, process forensics |
| ⬆️ **PrivEsc** | SUID/SGID, writable paths, sudo perms, cron jobs, capabilities |
| ⚙️ **Settings** | 4 themes, EN/TH language toggle |

---

## Quick Start

```bash
# Clone repo
git clone https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux
cd distro-os-cyber-agian-on-termux

# Main Edition
bash install.sh && phantomsec

# Distro Feel Edition
cd distro-feel && bash install.sh && phantomsec
```

### Termux (Android)
```bash
pkg update && pkg install git curl nmap python

# Main Edition
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/install.sh)

# Distro Feel Edition
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/distro-feel/install.sh)
```

---

## Update
```bash
cd ~/.phantomsec && git pull && bash install.sh
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

## License

MIT — for authorized security testing and research only.  
ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น

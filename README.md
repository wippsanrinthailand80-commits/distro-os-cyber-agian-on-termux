# PhantomSec — Distro Feel Edition v2.0

> *The cybersecurity toolkit that makes your terminal feel like a distro — without needing one.*

[![Platform](https://img.shields.io/badge/platform-Termux%20%7C%20Linux%20%7C%20macOS-00d4ff?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux)
[![Language](https://img.shields.io/badge/language-Bash-00d4ff?style=flat-square)](phantomsec.sh)
[![i18n](https://img.shields.io/badge/i18n-English%20%7C%20%E0%B8%A0%E0%B8%B2%E0%B8%A9%E0%B8%B2%E0%B9%84%E0%B8%97%E0%B8%A2-00d4ff?style=flat-square)](phantomsec.sh)
[![Version](https://img.shields.io/badge/version-2.0.0-00d4ff?style=flat-square)](CHANGELOG.md)

---

> Looking for the **real Linux distro**? → [phantomsec-os](https://github.com/wippsanrinthailand80-commits/phantomsec-os)
> That repo is the full C/C++ OS built from scratch.

---

## What is this?

**Distro Feel Edition** is a shell-based cybersecurity toolkit that gives you the *feel* of a dedicated security distro — on any device, with just Bash. Works on:

- 📱 **Termux** (Android) — the original home
- 🐧 **Linux** (Debian, Ubuntu, Arch, Kali, Parrot)
- 🍎 **macOS** (with Homebrew tools)

No kernel recompile. No virtual machine. Just `bash phantomsec.sh`.

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
# Clone
git clone https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux
cd distro-os-cyber-agian-on-termux

# Run directly
bash phantomsec.sh

# Or install properly
bash install.sh
phantomsec
```

### Termux (Android)

```bash
pkg update && pkg install git curl nmap python
git clone https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux
cd distro-os-cyber-agian-on-termux
bash install.sh
```

---

## Language / ภาษา

Switch between English and Thai inside the app via **Settings → Language**.

Or set before launch:
```bash
PHANTOMSEC_LANG=th bash phantomsec.sh   # Thai
PHANTOMSEC_LANG=en bash phantomsec.sh   # English (default)
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

## Two Repos Explained

| | This repo (Distro Feel) | [phantomsec-os](https://github.com/wippsanrinthailand80-commits/phantomsec-os) (Real Distro) |
|---|---|---|
| Language | Bash | C / C++ |
| Platform | Termux, Linux, macOS | Native Linux x86-64 |
| Runs on | Any device with Bash | Bare metal / VM |
| Tools | Wrappers + shell scripts | 5 original tools with novel algorithms |
| ISO | No | Yes (build with `distro/build.sh`) |
| Kernel | Host kernel | Custom hardened Linux 6.6 |

---

*สร้างด้วยใจในประเทศไทย | Built with ❤️ in Thailand*

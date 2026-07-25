<div align="center">

```
██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗███████╗███████╗ ██████╗
██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║██╔════╝██╔════╝██╔════╝
██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║███████╗█████╗  ██║
██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║╚════██║██╔══╝  ██║
██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║███████║███████╗╚██████╗
╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝ ╚═════╝
```

# **PhantomSec OS**
### Termux Cybersecurity Distro

[![Platform](https://img.shields.io/badge/Platform-Android%20%2F%20Termux-green?style=flat-square&logo=android)](https://termux.com)
[![Shell](https://img.shields.io/badge/Shell-Bash-blue?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.4.2-purple?style=flat-square)]()
[![Status](https://img.shields.io/badge/Status-Actively%20Maintained-brightgreen?style=flat-square&logo=github)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/commits/main)
[![Last Updated](https://img.shields.io/badge/Last%20Updated-July%202026-blue?style=flat-square)]()
[![Stars](https://img.shields.io/github/stars/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/stargazers)

**PhantomSec OS** turns your Android device + Termux into a full-featured cybersecurity research environment — with an interactive, colour-coded menu UI covering everything from recon to exploitation.

> ⚠️ **For educational and ethical use only.** Always get written permission before testing any system you don't own.

</div>

---

## ⚡ Quick Install

### One-Command (Recommended)

```bash
curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/bootstrap.sh | bash
```

> Requires Termux with internet access. The bootstrap script installs `git` if needed, clones the repo, and runs the full installer automatically.

### Manual Install

```bash
# 1. Clone the repository
git clone https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux
cd distro-os-cyber-agian-on-termux

# 2. Run the installer
bash install.sh

# 3. Launch PhantomSec
phantomsec
```

---

## 🔔 Project Status

> **โปรเจกต์นี้ยังคงอัพเดตอยู่อย่างต่อเนื่อง** — ติดตาม commits ล่าสุดได้ที่ [commits/main](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/commits/main)

| สิ่งที่ทำ | สถานะ |
|---|---|
| 🐞 แก้ syntax error ใน `run_ssl_inspect` (missing `fi`) | ✅ Done (v1.4.2) |
| 🔁 แก้ `menu_shells` ไม่มี while loop — กดอะไรก็ออก | ✅ Done (v1.4.2) |
| 🛡️ เพิ่ม tool guard ใน `run_hydra` / `run_sqlmap` | ✅ Done (v1.4.2) |
| 🔍 `tool_status` ตรวจ `~/.local/bin` + `~/go/bin` ด้วย | ✅ Done (v1.4.2) |
| 📦 Tool Manager ติดตั้งแบบ per-tool graceful skip | ✅ Done (v1.4.2) |
| 🐞 แก้ bug batch ใน v1.4.1 (curl timeouts, pip→pip3, seq loop) | ✅ Done (v1.4.1) |
| 🧩 เพิ่ม module ใหม่ (Social Engineering, PrivEsc) | 🔄 In Progress |
| 🎨 เพิ่ม themes ใหม่ | 🔄 In Progress |
| 📄 ปรับปรุง documentation | 🔄 In Progress |

> 📌 อัพเดตล่าสุด: **July 25, 2026** — v1.4.2 released  
> ดู [CHANGELOG.md](CHANGELOG.md) สำหรับรายละเอียดทุก version

---

## ✨ Features

| Module | Description |
|---|---|
| **[01] Information Gathering** | Nmap, Whois, DNS enum, GeoIP, Shodan, theHarvester, WhatWeb, subdomain scanner |
| **[02] Vulnerability Scanning** | Nmap vuln scripts, Nikto, WPScan, SSL checker, Nuclei |
| **[03] Web Exploitation** | SQLMap, XSS generator, LFI scanner, Directory bruteforce (Gobuster), CORS checker |
| **[04] Password Attacks** | Hydra, Hash identifier, Online hash cracker, Password generator, Wordlist manager |
| **[05] Network Analysis** | Packet capture, Port scanner, ARP scan, Traceroute, Ping sweep |
| **[06] Wireless Attacks** | WiFi scanning, Handshake capture, Aircrack-ng integration |
| **[07] Reverse Shells** | Payload generator (Bash/Python/NC/PowerShell), Netcat listener, Web shell templates |
| **[08] Forensics & Analysis** | File analysis, String extraction, Steganography, Log analyzer, Memory dump |
| **[09] Cryptography Tools** | Encode/decode (Base64/Hex/ROT13), Hash generator, Caesar cipher, OpenSSL wrapper |
| **[10] Tool Manager** | Check tool status, install/update tools, one-click batch install |
| **[11] Sessions & Reports** | Session logging, report viewer, auto-save scan results |
| **[12] Settings** | Theme selector, API key config, display options |
| **[13] Social Engineering** | Zphisher, Metasploit info, SET guide |
| **[14] Privilege Escalation** | SUID finder, sudo checker, cron job auditor, writable dir scanner |

---

## 📸 Preview

### Main Menu

```
╔══════════════════════════════════════════════════════════════════╗
║  ⚡ PhantomSec OS v1.4.2              [ Termux Cyber Distro ]  ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [01]  🔍 Information Gathering       Recon & OSINT             ║
║  [02]  🔓 Vulnerability Scanning      Exploit finding           ║
║  [03]  💉 Web Exploitation            SQLi, XSS, LFI            ║
║  [04]  🔑 Password Attacks            Brute force & cracking    ║
║  [05]  📡 Network Analysis            Sniffing & MITM           ║
║  [06]  📱 Wireless Attacks            WiFi & Bluetooth          ║
║  [07]  🐚 Reverse Shells              Payloads & listeners      ║
║  [08]  🛡️  Forensics & Analysis        Evidence & memory         ║
║  [09]  🔐 Cryptography Tools          Encode, decode, hash      ║
║  [10]  📦 Tool Manager                Install & update tools    ║
║  [11]  📋 Sessions & Reports          View saved results        ║
║  [12]  ⚙️  Settings                    Theme & API keys          ║
║  [13]  🎭 Social Engineering          Phishing & SET            ║
║  [14]  🔺 Privilege Escalation        PrivEsc checks            ║
║                                                                  ║
║  [0]   Exit                                                      ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 🔄 Update

```bash
# From inside the menu:
# Option 10 (Tool Manager) → Update PhantomSec

# Or run directly:
bash update.sh
```

---

## ❌ Uninstall

```bash
bash uninstall.sh
```

---

## 📋 Changelog Highlights

| Version | วันที่ | สิ่งที่เปลี่ยน |
|---|---|---|
| **v1.4.2** | Jul 25, 2026 | แก้ syntax error, menu_shells loop, tool guards, graceful install, pip3 fixes |
| **v1.4.1** | Jul 24, 2026 | แก้ curl timeouts, seq loops, SSL date parse, PATH สำหรับ gobuster |
| **v1.4.0** | Jul 2026 | เพิ่ม PrivEsc module, Social Engineering, bug fixes จาก v1.3.x |
| **v1.3.1** | Jun 2026 | เพิ่ม honeypot, session manager, themes |

> ดูรายละเอียดทั้งหมดที่ [CHANGELOG.md](CHANGELOG.md)

---

## 📁 Repository Structure

```
distro-os-cyber-agian-on-termux/
├── phantomsec.sh       # Main interactive menu (1886 lines)
├── install.sh          # Full installer
├── update.sh           # Updater (git stash → pull → pop)
├── uninstall.sh        # Clean uninstaller
├── bootstrap.sh        # One-command bootstrap (curl | bash)
├── VERSION             # Current version string
├── config/
│   └── settings.conf   # Default configuration
├── modules/
│   ├── osint.sh        # OSINT module
│   ├── privesc.sh      # Privilege escalation checks
│   ├── recon.sh        # Standalone recon script
│   ├── webexploit.sh   # Web exploitation helpers
│   └── nettools.sh     # Network tools
├── themes/
│   ├── matrix.sh       # Matrix green theme
│   ├── dark.sh         # Dark theme
│   └── classic.sh      # Classic theme
└── docs/
    ├── USAGE.md        # Usage guide & example workflows
    └── TOOLS.md        # Tool reference & command examples
```

---

## 📜 Legal Disclaimer

PhantomSec OS ออกแบบมาสำหรับ:
- ✅ Authorized penetration testing
- ✅ Security research and education
- ✅ CTF (Capture The Flag) competitions
- ✅ Learning cybersecurity concepts on your own systems

**คุณรับผิดชอบทั้งหมดในการใช้งานเครื่องมือนี้** การใช้งานโดยไม่ได้รับอนุญาตถือเป็นการกระทำที่ผิดกฎหมายในหลายประเทศ

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

<div align="center">
Made with ❤️ by <b>wippsanrinthailand80-commits</b> · Star ⭐ if you find it useful!
<br><br>
<sub>🔄 Actively maintained — latest: v1.4.2 · July 2026</sub>
</div>

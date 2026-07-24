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
[![Version](https://img.shields.io/badge/Version-1.4.0-purple?style=flat-square)]()
[![Status](https://img.shields.io/badge/Status-Actively%20Maintained-brightgreen?style=flat-square&logo=github)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/commits/main)
[![Last Updated](https://img.shields.io/badge/Last%20Updated-July%202026-blue?style=flat-square)]()
[![Stars](https://img.shields.io/github/stars/wippsanrinthailand80-commits/distro-os-cyber-again-on-termux?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-again-on-termux/stargazers)

**PhantomSec OS** turns your Android device + Termux into a full-featured cybersecurity research environment — with an interactive, colour-coded menu UI covering everything from recon to exploitation.

> ⚠️ **For educational and ethical use only.** Always get written permission before testing any system you don't own.

</div>

---

## 🔔 Project Status

> **โปรเจกต์นี้ยังคงอัพเดตอยู่อย่างต่อเนื่อง** — ติดตาม commits ล่าสุดได้ที่ [commits/main](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/commits/main)

| สิ่งที่กำลังทำอยู่ | สถานะ |
|---|---|
| 🧩 เพิ่ม module ใหม่ (Social Engineering, PrivEsc) | 🔄 In Progress |
| 🐞 แก้ไข bug จาก v1.3.0 | ✅ Done (v1.4.0) |
| 🎨 เพิ่ม themes ใหม่ | 🔄 In Progress |
| 📦 อัพเดต tool list ให้ครอบคลุมมากขึ้น | 🔄 In Progress |
| 📄 ปรับปรุง documentation | 🔄 In Progress |

> 📌 อัพเดตล่าสุด: **July 24, 2026** — v1.4.0 released  
> ดู [CHANGELOG.md](CHANGELOG.md) สำหรับรายละเอียดทุก version

---

## 📸 Preview

```
╔══════════════════════════════════════════════════════════════════╗
║                         MAIN MENU                                ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  [01]  🔍 Information Gathering      Recon & OSINT               ║
║  [02]  🔓 Vulnerability Scanning     Exploit finding             ║
║  [03]  💉 Web Exploitation           SQLi, XSS, LFI              ║
║  [04]  🔑 Password Attacks           Brute force & cracking      ║
║  [05]  📡 Network Analysis           Sniffing & MITM             ║
║  [06]  📱 Wireless Attacks           WiFi & Bluetooth            ║
║  [07]  🐚 Reverse Shells             Payloads & listeners        ║
║  [08]  🛡️  Forensics & Analysis       Evidence & memory           ║
║  [09]  🔐 Cryptography Tools         Encode, decode, hash        ║
║  [10]  📦 Tool Manager               Install & update            ║
║  [11]  📊 Session Manager            Logs & reports              ║
║  [12]  ⚙️  Settings                   Config & themes             ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## ⚡ Quick Install

### วิธีที่ 1 — One-Command (แนะนำ)

เปิด **Termux** แล้วรันคำสั่งเดียว:

```bash
curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/bootstrap.sh | bash
```

> Bootstrap จะ clone repo และรัน installer ให้อัตโนมัติ

---

### วิธีที่ 2 — Manual Install

```bash
pkg update -y && pkg install -y git
git clone https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux
cd distro-os-cyber-agian-on-termux
chmod +x install.sh
bash install.sh
```

After install, launch with:

```bash
phantomsec
```

---

## 🛠️ Tools & Modules

| Category | Tools |
|---|---|
| 🔍 **Recon / OSINT** | nmap, whois, dig, shodan, geoip, banner grabber, subdomain finder, whatweb, theHarvester |
| 🔓 **Vuln Scanning** | nikto, nmap --script vuln, CVE lookup, SSL checker, Nuclei |
| 💉 **Web Exploitation** | sqlmap, XSS generator, dir bruteforce, LFI tester, CORS checker, Gobuster |
| 🔑 **Password Attacks** | hydra, john, hash identifier, online hash cracker, password generator |
| 📡 **Network Analysis** | tcpdump, netstat, masscan, arp-scan, port scanner |
| 📱 **Wireless** | aircrack-ng, WiFi scanner, Bluetooth tools |
| 🐚 **Reverse Shells** | payload generator, netcat listener, msfvenom |
| 🛡️ **Forensics** | strings, binwalk, file carving, log analysis |
| 🔐 **Crypto** | hash tools, base64, Caesar cipher, encode/decode |
| 🎭 **Social Engineering** | Zphisher, Metasploit info, SET |

---

```bash
SHODAN_API_KEY="your_key_here"
VIRUSTOTAL_API_KEY="your_key_here"
CENSYS_API_ID="your_id"
CENSYS_API_SECRET="your_secret"
```

---

## 🔄 Update

```bash
cd distro-os-cyber-agian-on-termux
bash update.sh
```

Or inside the menu: **Option 10 → Update PhantomSec**

---

## ❌ Uninstall

```bash
bash uninstall.sh
```

---

## 📜 Legal Disclaimer

PhantomSec OS is designed for:
- ✅ Authorized penetration testing
- ✅ Security research and education
- ✅ CTF (Capture The Flag) competitions
- ✅ Learning cybersecurity concepts on your own systems

**You are entirely responsible for how you use this tool.** Unauthorized use against systems you do not own is illegal in most jurisdictions.

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

<div align="center">
Made with ❤️ by <b>wippsanrinthailand80-commits</b> · Star ⭐ if you find it useful!
<br><br>
<sub>🔄 Actively updated — last commit: July 2026</sub>
</div>
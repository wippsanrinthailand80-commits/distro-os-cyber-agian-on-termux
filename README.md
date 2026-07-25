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
[![Stars](https://img.shields.io/github/stars/wippsanrinthailand80-commits/distro-os-cyber-again-on-termux?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-again-on-termux/stargazers)

**PhantomSec OS** turns your Android device + Termux into a full-featured cybersecurity research environment — with an interactive, colour-coded menu UI covering everything from recon to exploitation.

> ⚠️ **For educational and ethical use only.** Always get written permission before testing any system you don't own.

</div>

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
║  [10]  📦 Tool Manager                Install & update          ║
║  [11]  📊 Session Manager             Logs & reports            ║
║  [12]  ⚙️  Settings                    Config & themes           ║
║  [13]  🎣 Social Engineering          Phishing & SE tools       ║
║  [14]  🍯 Honeypot                    Trap & log attackers      ║
║                                                                  ║
║  [00]  Exit PhantomSec                                          ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
  ▶ Select option:
```

### Sub-menu Examples

<details>
<summary>🔍 Information Gathering (13 tools)</summary>

```
╔══════════════════════════════════════════════════════════════════╗
║  🔍 INFORMATION GATHERING                                       ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [1]   Nmap Port Scanner           [INSTALLED]                  ║
║  [2]   Whois Lookup                [INSTALLED]                  ║
║  [3]   DNS Enumeration             (dig / nslookup)             ║
║  [4]   Subdomain Finder            (curl + wordlist)            ║
║  [5]   GeoIP Lookup                (ip-api.com)                 ║
║  [6]   HTTP Header Inspector       (curl)                       ║
║  [7]   Shodan Search               (API key required)           ║
║  [8]   Banner Grabbing             (nc / curl)                  ║
║  [9]   WhatWeb Fingerprint         [INSTALLED]                  ║
║  [10]  theHarvester OSINT          [INSTALLED]                  ║
║  [11]  Wayback Machine Lookup      (archive.org)                ║
║  [12]  SSL Certificate Inspector   (openssl)                    ║
║  [13]  Email OSINT                 (leaks & breach check)       ║
║                                                                  ║
║  [0]   Back                                                     ║
╚══════════════════════════════════════════════════════════════════╝
```
</details>

<details>
<summary>💉 Web Exploitation (6 tools)</summary>

```
╔══════════════════════════════════════════════════════════════════╗
║  💉 WEB EXPLOITATION                                            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [1]  SQLMap — SQL Injection        [INSTALLED]                 ║
║  [2]  XSS Payload Generator        (built-in)                   ║
║  [3]  Directory Bruteforce         (curl)                       ║
║  [4]  LFI Tester                   (built-in)                   ║
║  [5]  CORS & Security Headers      (built-in)                   ║
║  [6]  Gobuster Dir Scan            [INSTALLED]                  ║
║                                                                  ║
║  [0]  Back                                                      ║
╚══════════════════════════════════════════════════════════════════╝
```
</details>

<details>
<summary>🔑 Password Attacks (6 tools)</summary>

```
╔══════════════════════════════════════════════════════════════════╗
║  🔑 PASSWORD ATTACKS                                            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [1]  Hydra — Network Bruteforce   [INSTALLED]                  ║
║  [2]  Hash Identifier              (built-in)                   ║
║  [3]  Hash Cracker (online)        (hashes.com)                 ║
║  [4]  Password Generator           (built-in)                   ║
║  [5]  Wordlist Manager             (built-in)                   ║
║  [6]  John the Ripper              [INSTALLED]                  ║
║                                                                  ║
║  [0]  Back                                                      ║
╚══════════════════════════════════════════════════════════════════╝
```
</details>

<details>
<summary>🔓 Vulnerability Scanning (7 tools)</summary>

```
╔══════════════════════════════════════════════════════════════════╗
║  🔓 VULNERABILITY SCANNING                                      ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [1]  Nikto Web Scanner            [INSTALLED]                  ║
║  [2]  OpenVAS (via REST)           (external)                   ║
║  [3]  CVE Lookup                   (nvd.nist.gov)               ║
║  [4]  SSL/TLS Checker              (ssllabs)                    ║
║  [5]  Custom Nmap Vuln Script      (--script vuln)              ║
║  [6]  Nuclei Scanner               [INSTALLED]                  ║
║  [7]  OWASP Quick Check            (headers+dirs+methods)       ║
║                                                                  ║
║  [0]  Back                                                      ║
╚══════════════════════════════════════════════════════════════════╝
```
</details>

<details>
<summary>🐚 Reverse Shells (3 tools)</summary>

```
╔══════════════════════════════════════════════════════════════════╗
║  🐚 REVERSE SHELLS                                              ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [1]  Generate Payloads            (bash/python/nc/php/perl)    ║
║  [2]  Start Listener               (nc -lvnp)                   ║
║  [3]  Web Shell Generator          (PHP/Python)                 ║
║                                                                  ║
║  [0]  Back                                                      ║
╚══════════════════════════════════════════════════════════════════╝
```
</details>

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

หลังติดตั้งเสร็จ เปิดด้วย:

```bash
phantomsec
```

---

## 🛠️ Tools & Modules

| Category | Tools |
|---|---|
| 🔍 **Recon / OSINT** | nmap, whois, dig, geoip, banner grabber, subdomain finder, whatweb, theHarvester, email OSINT |
| 🔓 **Vuln Scanning** | nikto, nmap --script vuln, CVE lookup, SSL/TLS inspector, Nuclei, OWASP quick check |
| 💉 **Web Exploitation** | sqlmap, XSS generator, dir bruteforce, LFI tester, CORS checker, Gobuster |
| 🔑 **Password Attacks** | hydra, john, hash identifier, online hash lookup, wordlist manager, password generator |
| 📡 **Network Analysis** | tcpdump, netstat, masscan, ARP scan, port scanner, traceroute |
| 📱 **Wireless** | aircrack-ng, WiFi scanner, Bluetooth tools |
| 🐚 **Reverse Shells** | payload generator (bash/python/nc/php/perl), netcat listener, web shell templates |
| 🛡️ **Forensics** | strings, binwalk, file carving, log analysis, steghide |
| 🔐 **Crypto** | hash tools, base64, Caesar cipher, encode/decode |
| 🎭 **Social Engineering** | Zphisher, Metasploit info, SET |
| 🔺 **Privilege Escalation** | SUID finder, sudo check, kernel exploits, linpeas |

---

## 🔑 Optional API Keys

บาง module ต้องการ API key — ใส่ใน `~/.phantomsec/config.env`:

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

หรือเปิดใน menu: **Option 10 → Update PhantomSec**

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
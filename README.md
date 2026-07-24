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
[![Stars](https://img.shields.io/github/stars/wippsanrinthailand80-commits/distro-os-cyber-again-on-termux?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-again-on-termux/stargazers)

**PhantomSec OS** turns your Android device + Termux into a full-featured cybersecurity research environment — with an interactive, colour-coded menu UI covering everything from recon to exploitation.

> ⚠️ **For educational and ethical use only.** Always get written permission before testing any system you don't own.

</div>

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
| 🔓 **Vuln Scanning** | nikto, nmap --script vuln, CVE lookup, SSL checker |
| 💉 **Web Exploitation** | sqlmap, XSS generator, dir bruteforce, LFI tester, CORS checker |
| 🔑 **Password Attacks** | hydra, john, hash identifier, online hash cracker, password generator |
| 📡 **Network Analysis** | nmap, traceroute, ARP scan, tcpdump, port scanner |
| 📱 **Wireless** | termux-wifi-scaninfo, connection info |
| 🐚 **Reverse Shells** | Bash, Python, PHP, Perl, Netcat payloads + listener |
| 🛡️ **Forensics** | strings, xxd, md5sum, sha256sum, base64 |
| 🔐 **Crypto** | RSA key gen, hash functions, Caesar cipher, ROT13, token gen |
| 📦 **Tool Manager** | Install, update, status checker |

---

## 📁 File Structure

```
distro-os-cyber-agian-on-termux/
├── bootstrap.sh          # One-command installer (curl | bash)
├── install.sh            # Full installer with step counter & summary
├── phantomsec.sh         # Main interactive UI
├── update.sh             # Updater script
├── uninstall.sh          # Uninstaller
├── python_tools.sh       # Optional Python security libs
├── config/
│   └── settings.conf     # Configuration file
├── modules/
│   ├── recon.sh          # Standalone recon module
│   ├── webexploit.sh     # Standalone web exploit module
│   ├── nettools.sh       # Standalone network tools module
│   └── privesc.sh        # Privilege escalation recon module
├── themes/
│   ├── matrix.sh         # Matrix rain terminal effect
│   ├── dark.sh           # Dark colour theme
│   └── classic.sh        # Classic green-on-black theme
└── docs/
    ├── TOOLS.md          # Detailed tool reference
    └── USAGE.md          # Usage guide & examples
```

---

## 🎯 Standalone Modules

You can run individual modules without launching the full menu:

```bash
# Recon
bash modules/recon.sh example.com

# Web check
bash modules/webexploit.sh https://example.com

# Network tools
bash modules/nettools.sh 192.168.1.0/24

# Matrix theme (for fun)
bash themes/matrix.sh
```

---

## ⚙️ Requirements

| Requirement | Details |
|---|---|
| **OS** | Android 7+ with Termux |
| **Termux** | Latest from F-Droid (recommended) or Google Play |
| **Storage** | ~500MB for full tool install |
| **Internet** | Required during setup |
| **Root** | Optional (some features need root for packet capture, monitor mode) |

---

## 🔧 Configuration

Edit `~/.config/phantomsec/settings.conf` to set API keys:

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
</div>

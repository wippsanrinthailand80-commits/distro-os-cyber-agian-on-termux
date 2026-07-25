# PhantomSec v2.5.3

> *One project. Three tiers. From shell script to custom OS.*

[![Platform](https://img.shields.io/badge/platform-Termux%20%7C%20Linux%20%7C%20macOS-00d4ff?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux)
[![Version](https://img.shields.io/badge/version-2.5.3-00d4ff?style=flat-square)](VERSION)
[![Language](https://img.shields.io/badge/language-Bash%20%7C%20C%2FC%2B%2B-00d4ff?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux)
[![i18n](https://img.shields.io/badge/i18n-English%20%7C%20%E0%B8%A0%E0%B8%B2%E0%B8%A9%E0%B8%B2%E0%B9%84%E0%B8%97%E0%B8%A2-00d4ff?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux)

---

## Three Editions — Choose Yours

| | 🌀 Distro Feel | 💿 PhantomSec OS (Linux) | 📱 PhantomSec OS (Termux) |
|---|---|---|---|
| **Folder** | `distro-feel/` | `os/` | `termux/` |
| **Language** | Bash | C / C++ | C / C++ |
| **What it is** | Lightweight shell toolkit — distro feel without a real OS | Custom Linux OS built from scratch (bare metal / VM) | Real C/C++ OS tools built inside Ubuntu proot on Android |
| **Runs on** | Termux · Linux · macOS | x86-64 Linux bare metal / VM | Termux (Android) via proot-distro |
| **Install** | 1 curl command | 1 curl command | 1 curl command |

---

## ⚡ One-Line Install

### 🌀 Distro Feel Edition — Termux · Linux · macOS
```bash
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/distro-feel/install.sh)
```

### 💿 PhantomSec OS — Linux bare metal / VM (x86-64 only)
```bash
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/os/install.sh)
```

### 📱 PhantomSec OS on Termux — real C/C++ tools via proot-distro
```bash
bash <(curl -sL https://raw.githubusercontent.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux/main/termux/install.sh)
```

---

## Toolkit Features (Distro Feel)

| Module | What it does |
|--------|-------------|
| 🌐 **Network** | Interface info, host discovery, port scan, MAC vendor, traceroute |
| 🔍 **OSINT** | IP/domain/email/username, WHOIS, DNS, subdomains, SSL, Shodan |
| 🕸️ **Web Exploit** | Headers, dir brute-force, SQLi, XSS payloads, JWT decoder, CORS, WAF |
| 🔐 **Crypto** | Hash, Base64, URL/hex encode, ROT13, OpenSSL encrypt, random key gen |
| 🧬 **Forensics** | File magic, strings, entropy analysis, pcap capture, process forensics |
| ⬆️ **PrivEsc** | SUID/SGID, writable paths, sudo perms, cron jobs, capabilities |
| ⚙️ **Settings** | 4 themes · EN/TH language toggle |

---

## PhantomSec OS Tools (`os/tools/` · `termux/`)

| Tool | Description |
|------|-------------|
| `psh` | Custom POSIX shell |
| `netghost` | Stealth network scanner |
| `spectrscan` | Spectrum port/service analysis |
| `scdna` | Binary/shellcode DNA analyzer |
| `entropyd` | Entropy daemon for kernel randomness |

→ OS details: [`os/README.md`](os/README.md)

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
PHANTOMSEC_LANG=th bash phantomsec.sh   # Thai / ภาษาไทย
PHANTOMSEC_LANG=en bash phantomsec.sh   # English (default)
```

---

## Update

```bash
cd ~/.phantomsec && git pull && bash install.sh
```

---

## License

MIT — for authorized security testing and educational research only.  
ใช้เพื่อการศึกษาและการทดสอบที่ได้รับอนุญาตเท่านั้น

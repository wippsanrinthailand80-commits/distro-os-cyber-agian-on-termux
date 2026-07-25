# PhantomSec OS v2.5.0

> *A custom Linux distribution engineered from scratch in C/C++ for elite offensive and defensive security work.*

[![Language](https://img.shields.io/badge/language-C%2FC%2B%2B-00d4ff?style=flat-square)](https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux)
[![License](https://img.shields.io/badge/license-MIT-00d4ff?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.5.0--alpha-00d4ff?style=flat-square)](CHANGELOG.md)
[![i18n](https://img.shields.io/badge/i18n-English%20%7C%20%E0%B8%A0%E0%B8%B2%E0%B8%A9%E0%B8%B2%E0%B9%84%E0%B8%97%E0%B8%A2-00d4ff?style=flat-square)](i18n/)

---

PhantomSec OS is not a reskin of Kali Linux. It is not a pretty wrapper around existing tools. It is an **original Linux distribution built entirely in C/C++** — custom kernel configuration, custom init-style system, and five original security tools that nobody has published before.

**รุ่นใหม่ทั้งหมดเขียนด้วย C/C++ — ไม่ใช่ wrapper ของ Kali หรือ distro อื่น**

---

## Unique Tools

| Tool | ภาษา | คำอธิบาย |
|------|-------|-----------|
| **SpecterScan** | C | Passive firewall ACL reconstructor via TCP timing analysis — reconstructs firewall rules without triggering IDS |
| **EntropyWarden** | C | Real-time ransomware detector using inotify + Shannon entropy — catches encryption within milliseconds |
| **SyscallDNA** | C | Markov-chain behavioral fingerprinter via ptrace — creates DNA signatures from syscall sequences |
| **NetGhost** | C | Passive network topology mapper — reconstructs full network map without sending a single packet |
| **PhantomShell (psh)** | C | Custom OS shell with bilingual (EN/TH) interface and integrated security tools |

---

## Project Structure

```
phantomsec-src/
├── tools/
│   ├── spectrscan/     # Firewall ACL reconstructor
│   │   └── spectrscan.c
│   ├── entropyd/       # Ransomware entropy detector
│   │   └── entropyd.c
│   ├── scdna/          # Syscall DNA fingerprinter
│   │   └── scdna.c
│   ├── netghost/       # Passive network mapper
│   │   └── netghost.c
│   └── psh/            # PhantomSec shell
│       └── psh.c
├── i18n/
│   ├── i18n.h          # i18n dispatcher
│   ├── en.h            # English strings
│   └── th.h            # Thai strings (ภาษาไทย)
├── distro/
│   ├── build.sh        # Full distro build script (Linux from scratch)
│   └── kernel.config   # Hardened kernel configuration
├── Makefile            # Master build file
└── README.md
```

---

## Build Tools

```bash
# Install dependencies (Debian/Ubuntu)
sudo apt-get install gcc make libreadline-dev

# Build all tools
make all

# Install to /usr/local/bin
sudo make install

# Build in Thai language mode
make LANG=th all

# Build individual tool
make spectrscan
```

---

## Build the Full Distro ISO

> Requires ~10GB disk space, ~2 hours build time, Linux host

```bash
cd distro/
sudo chmod +x build.sh
sudo ./build.sh

# Test with QEMU
qemu-system-x86_64 -cdrom /tmp/phantomsec-2.5.0-x86_64.iso -m 512M
```

---

## Tool Usage

### SpecterScan — Firewall ACL Reconstructor

```bash
# Reconstruct firewall rules from timing patterns
sudo spectrscan -t 192.168.1.1 -p 1-1024

# Save report
sudo spectrscan -t 10.0.0.1 -p 1-65535 -o fw_report.csv

# Thai output
PHANTOMSEC_LANG=th sudo spectrscan -t 192.168.1.1 -p 80,443,22
```

### EntropyWarden — Ransomware Detector

```bash
# Watch /home and /var for entropy spikes
sudo entropyd -w /home -w /var

# Custom threshold (7.0 bits/byte = definitely encrypted)
sudo entropyd -w /home -t 7.0 -n 3 -W 5

# Verbose (show all files)
sudo entropyd -w /home -v
```

### SyscallDNA — Behavioral Fingerprinter

```bash
# Fingerprint a running process
sudo scdna -p $(pgrep sshd)

# Save baseline profile
sudo scdna -p $(pgrep nginx) -s /etc/phantomsec/profiles/nginx.dna

# Compare against baseline (anomaly detection)
sudo scdna -p 1234 -c /etc/phantomsec/profiles/nginx.dna
```

### NetGhost — Passive Topology Mapper

```bash
# Map network for 60 seconds (NO packets sent)
sudo netghost -i eth0 -t 60

# Infinite capture, show all hosts
sudo netghost -i wlan0 -t 0 -a

# Save topology report
sudo netghost -i eth0 -t 120 -o topology.csv
```

### PhantomShell (psh) — Custom Shell

```bash
# Start PhantomShell
psh

# Start in Thai mode
PHANTOMSEC_LANG=th psh

# Inside psh:
help           # Show help (bilingual)
tools          # List PhantomSec tools
entropy /home  # Check directory entropy
threat         # Live threat monitor
lang th        # Switch to Thai
lang en        # Switch to English
```

---

## i18n — Multilingual Support

All tools support English and Thai via `PHANTOMSEC_LANG` environment variable:

```bash
export PHANTOMSEC_LANG=th   # Thai (ภาษาไทย)
export PHANTOMSEC_LANG=en   # English (default)
```

Or compile with Thai as default:

```bash
make LANG=th all   # Compile with Thai strings baked in
```

---

## v1 vs v2 Comparison

| Feature | v1 (Termux/Shell) | v2 (PhantomSec OS C/C++) |
|---------|-------------------|--------------------------|
| Language | Shell script | C / C++ |
| Platform | Termux (Android) | Native Linux |
| Tools | Wrappers around existing tools | Original, never-before-seen tools |
| i18n | Partial Thai | Full EN/TH bilingual |
| Distro | No | Full custom Linux from scratch |
| Kernel | Android kernel | Custom hardened Linux 6.6 |
| Init | Android init | Custom C init system |

---

## Security Notice

These tools are for **authorized security testing and research only**. Use only on systems you own or have explicit written permission to test. The authors are not responsible for misuse.

---

*Built with ☠️ in Thailand | สร้างด้วยใจในประเทศไทย*


---

← [Back to main project](../README.md)

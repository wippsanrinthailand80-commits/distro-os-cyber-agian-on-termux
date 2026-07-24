# PhantomSec OS — Changelog

All notable changes to this project will be documented here.

---

## [1.3.0] — 2026-07-24

### Fixed
- **`phantomsec.sh`** — Header comment still showed `v1.0.0` — corrected to `v1.3.0`
- **`phantomsec.sh`** — Duplicate case patterns `10|10)`, `11|11)`, `12|12)` in main_menu — simplified to `10)`, `11)`, `12)`
- **`phantomsec.sh`** — `show_banner` IP fetch had no timeout, causing every menu load to hang — added `--max-time 3`
- **`phantomsec.sh`** — `run_xss_gen` Python URL-encoding broke on payloads containing single/double quotes — rewritten to use `printf '%s' "$p" | python3` pipeline (no shell quoting conflict)
- **`phantomsec.sh`** — Settings menu read config from `$HOME/.config/phantomsec/settings.conf` (never created by installer) — corrected to `$PHANTOMSEC_DIR/config/settings.conf`
- **`phantomsec.sh`** — `menu_vuln_scan` option `[2] OpenVAS` was displayed but missing from case statement — now shows a Termux note and redirects to Nuclei
- **`phantomsec.sh`** — `run_dirbust` and `run_lfi` curl calls had no timeout — added `--max-time 5`
- **`install.sh`** — Hardcoded `VERSION="1.1.0"` and header comment — updated to `1.3.0` and reads dynamically
- **`config/settings.conf`** — `VERSION="1.1.0"` — updated to `1.3.0`
- **`VERSION`** — Bumped to `1.3.0`

### Added
- **`phantomsec.sh`** — `[13] 🎣 Social Engineering` menu: Zphisher + Metasploit + SET info
- **`phantomsec.sh`** — `[9] WhatWeb Fingerprint` in Information Gathering (with curl fallback if not installed)
- **`phantomsec.sh`** — `[10] theHarvester OSINT` in Information Gathering (with crt.sh fallback)
- **`phantomsec.sh`** — `[6] Nuclei Scanner` in Vulnerability Scanning (critical/high/all/tech modes)
- **`phantomsec.sh`** — `[6] Gobuster Dir Scan` in Web Exploitation (dir/dns/vhost modes; curl fallback)
- **`phantomsec.sh`** — `[6] John the Ripper` in Password Attacks (wordlist/incremental/show modes)
- **`phantomsec.sh`** — `[7] Masscan Fast Scan` in Network Analysis
- **`phantomsec.sh`** — `[3] Aircrack-ng Capture` and `[4] Aircrack-ng Crack` in Wireless
- **`phantomsec.sh`** — New functions: `run_whatweb`, `run_harvester`, `run_nuclei`, `run_gobuster`, `run_john`, `run_masscan`, `run_aircrack_capture`, `run_aircrack_crack`, `run_zphisher`, `run_metasploit`, `menu_social`
- **`phantomsec.sh`** — Tool Manager check list updated to include: masscan, john, gobuster, nuclei, whatweb, aircrack-ng

---

## [1.2.0] — 2026-07-24 (internal)

### Fixed
- **`update.sh`** — `REPO` URL corrected spelling
- **`README.md`** / **`docs/USAGE.md`** — Clone URLs corrected

---

## [1.1.0] — 2026-07-24

### Fixed
- **`phantomsec.sh`** — Syntax bug in `run_dirbust()` draw_line call
- **`phantomsec.sh`** — Menus 06/08/09/11/12 missing `while` loops — converted to proper `while true` with `0) return`
- **`phantomsec.sh`** — Tool Manager option 4 was a no-op — now calls `update.sh`
- **`phantomsec.sh`** — Settings Shodan key saved duplicate lines — now uses `sed -i` replace
- **`phantomsec.sh`** — `md5sum`/`sha256sum` now properly quoted
- **`phantomsec.sh`** — Caesar cipher rewritten in Python3
- **`update.sh`** — REPO URL corrected
- **`README.md`** / **`docs/USAGE.md`** — URLs corrected

### Added
- `themes/dark.sh`, `themes/classic.sh`, `modules/privesc.sh`, `CHANGELOG.md`

---

## [1.0.0] — Initial Release

- Interactive Bash menu UI for Termux cybersecurity research
- Modules: Information Gathering, Vuln Scanning, Web Exploitation, Password Attacks, Network Analysis, Wireless, Reverse Shells, Forensics, Cryptography, Tool Manager, Sessions, Settings
- Standalone modules: `recon.sh`, `webexploit.sh`, `nettools.sh`
- Themes: `matrix.sh`
- One-command installer, updater, uninstaller

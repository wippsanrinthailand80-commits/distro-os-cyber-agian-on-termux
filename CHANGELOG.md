# CHANGELOG — PhantomSec OS

All notable changes to this project are documented here.
Format: `[version] — date` → sections: Added / Fixed / Changed / Removed

---

## [1.4.2] — 2026-07-25

### Fixed
- `phantomsec.sh`: version bump to v1.4.2
- `menu_shells`: ไม่มี `while true` loop → กดอะไรก็ออกเสมอ แก้เป็น proper menu พร้อม `[0] Back`
- `run_sqlmap`: ไม่เช็คว่า sqlmap ติดตั้งอยู่ → crash เมื่อไม่มี tool เพิ่ม `require_tool` guard
- `run_hydra`: ไม่เช็คว่า hydra ติดตั้งอยู่ → crash เพิ่ม guard + hint ติดตั้ง
- `tool_status`: เช็คแค่ `command -v` → ไม่พบ tool ที่ติดตั้งผ่าน pip/gem/go ใน `~/.local/bin` หรือ `~/go/bin`
- `run_hash_crack`: curl 2 calls ไม่มี `--max-time` → เพิ่ม `--max-time 10`
- `run_wordlist_mgr`: curl download ไม่มี `--max-time` → เพิ่ม `--max-time 30/60`
- `run_whatweb` fallback curl: เพิ่ม `--max-time 10`
- `run_harvester` install hint: `pip` → `pip3`
- `menu_tool_manager` [1] Check tools: เพิ่ม tool อีก 14 ตัว (theHarvester, tcpdump, traceroute, ssh, ftp, perl, ruby, figlet, lolcat, toilet, tmux, vim, jq, nc)
- `menu_tool_manager` [3] Install: เปลี่ยนจาก bulk install เป็น per-tool graceful skip พร้อม hint แต่ละตัว
- `install.sh`: `pip install sqlmap` → `pip3 install sqlmap`
- `install.sh`: hydra fallback ลอง `unstable-repo` ก่อน แล้วค่อย skip พร้อม hint
- `install.sh`: เพิ่ม theHarvester (pip3) ใน STEP 6
- `install.sh` version: 1.4.1 → 1.4.2
- `VERSION`: 1.4.1 → 1.4.2

### Added
- `require_tool()` helper function สำหรับทุก menu ที่ใช้ external tool
- `PATH` export ครอบ `~/.local/bin` และ `~/go/bin` ที่ startup
- `run_revshell_gen()`: Netcat OpenBSD + PowerShell payload (เพิ่มจาก menu_shells เดิม)
- `run_nc_listener()`: start netcat listener พร้อม port validation และ nc check
- `run_webshell_gen()`: PHP / Python web shell templates

---

## [1.4.1] — 2026-07-24

### Fixed
- `phantomsec.sh`: header comment `v1.3.1` → `v1.4.1`; fallback version string `1.3.1` → `v1.4.1`
- `run_passgen`: replaced `seq` loop with bash arithmetic `for ((i=1; i<=cnt; i++))` for portability
- `run_passgen`: added `LC_ALL=C` to `tr -dc` to prevent locale-related failures on some Android builds
- `run_geoip`: both `curl` calls were missing `--max-time 10` (could hang indefinitely)
- `run_headers` (`curl -sI`): missing `--max-time 10`
- `run_ssl_inspect`: `days_left` arithmetic now guarded — if `date` fails to parse expiry date (`exp_epoch=0`), skip calculation instead of producing a huge negative number
- `run_honeypot_multi`: `for p in $port_input` → `read -ra _ports <<< "$port_input"` to prevent word-splitting issues
- `run_subdomain`: added `command -v host` / `dig` check before scanning — shows friendly install hint if missing
- `menu_tool_manager`: Gobuster `go install` now exports `$HOME/go/bin` to PATH in the same shell so binary is immediately available
- `install.sh`: header + `VERSION` variable: `1.3.1` → `1.4.1`
- `install.sh`: progress bar replaced `seq` loops with bash arithmetic loops
- `update.sh`: `git pull` replaced with `git stash → git pull --rebase → git stash pop` to avoid failure when local changes exist
- `modules/privesc.sh`: both `find /` calls wrapped with `timeout 60` to prevent indefinite scanning on Android
- `VERSION`: 1.4.0 → 1.4.1

---

## [1.3.1] — 2026-07-24

### Fixed

| # | File | Bug | Fix |
|---|------|-----|-----|
| 1 | `phantomsec.sh` | VERSION fallback hardcoded as `1.2.0` — wrong version shown if VERSION file missing | Changed fallback to `1.3.1` |
| 2 | `phantomsec.sh` | `run_shodan()` — Python URL encoding used `python3 -c "...quote('$query')"` — queries containing `'` or `"` crashed the shell substitution | Rewrote as `printf '%s' "$query" \| python3 -c 'import sys,urllib.parse; ...'` (safe pipe pattern) |
| 3 | `phantomsec.sh` | `menu_settings` option 1 — config displayed from `$HOME/.config/phantomsec/settings.conf` (never created by installer) | Corrected to `$PHANTOMSEC_DIR/config/settings.conf`; also creates dir if missing |
| 4 | `phantomsec.sh` | `run_lfi()` — second `curl` call had no `--max-time`, hangs on slow targets | Added `--max-time 5` |
| 5 | `phantomsec.sh` | `run_cors()` — `curl -sI` had no timeout | Added `--max-time 8` |
| 6 | `phantomsec.sh` | `run_xss_gen()` — HTTP test `curl` had no timeout | Added `--max-time 5` |
| 7 | `phantomsec.sh` | `menu_crypto` Caesar cipher — shift value `$sh` interpolated directly into `python3 -c` without validation; non-numeric input threw unhandled Python exception | Added `[[ "$sh" =~ ^[0-9]+$ ]]` guard before calling Python |
| 8 | `phantomsec.sh` | `run_subdomain()` — `dig +short A $full` had unquoted variable | Quoted: `dig +short A "$full"` |
| 9 | `phantomsec.sh` | `menu_tool_manager` option 4 "Update PhantomSec" — used `bash "$(dirname "$0")/update.sh"` which resolves to `$PREFIX/bin/` when run as installed binary — update silently failed | Rewrote with fallback search across `$_SCRIPT_DIR`, `$HOME/distro-os-cyber-agian-on-termux`, `$HOME/phantomsec`, `$HOME/PhantomSec` |
| 10 | `phantomsec.sh` | `$PHANTOMSEC_DIR/config/` directory never created on startup | Added `config` to `mkdir -p "$PHANTOMSEC_DIR"/{logs,sessions,wordlists,reports,config}` |
| 11 | `install.sh` + `config/settings.conf` | VERSION still `1.3.0` after previous release | Updated to `1.3.1` |

### Added
- `menu_tool_manager` option **[5] Check for Updates** — fetches `VERSION` from GitHub and compares with installed version; shows update prompt if behind

---

## [1.3.0] — 2026-07-24

### Fixed
- `phantomsec.sh`: header comment `v1.0.0` → `v1.3.0`
- Duplicate case patterns `10|10)` `11|11)` `12|12)` → `10)` `11)` `12)`
- `show_banner`: IP fetch no timeout → `--max-time 3`
- `run_xss_gen`: Python quoting broke on payloads with quotes → printf pipeline
- Settings config path wrong → `$PHANTOMSEC_DIR/config/`
- `menu_vuln_scan` option 2 missing from case → added handler
- `run_dirbust` / `run_lfi`: curl no timeout → `--max-time 5`
- `install.sh` + `config/settings.conf`: hardcoded VERSION `1.1.0` → `1.3.0`

### Added
- [01] WhatWeb [9], theHarvester [10]
- [02] Nuclei [6]
- [03] Gobuster [6]
- [04] John the Ripper [6]
- [05] Masscan [7]
- [06] Aircrack-ng capture [3] + crack [4]
- [13] Social Engineering menu: Zphisher + Metasploit + SET info

---

## [1.1.0] — 2026-07-24

### Fixed
- `run_dirbust()`: draw_line syntax bug
- Menus 06/08/09/11/12 missing `while` loops
- Tool Manager option 4 was no-op stub
- Settings Shodan key duplicate line append
- `md5sum`/`sha256sum` unquoted arguments
- Caesar cipher rewritten in Python3
- `update.sh`: REPO URL spelling corrected
- `README.md` / `docs/USAGE.md`: clone URLs corrected

### Added
- `themes/dark.sh`, `themes/classic.sh`
- `modules/privesc.sh`
- `CHANGELOG.md`

---

## [1.0.0] — Initial Release

### Added
- Interactive Bash menu UI for Termux cybersecurity research
- Modules: Information Gathering, Vuln Scanning, Web Exploitation, Password Attacks, Network Analysis, Wireless, Reverse Shells, Forensics, Cryptography, Tool Manager, Sessions, Settings
- Standalone modules: `recon.sh`, `webexploit.sh`, `nettools.sh`
- Themes: `matrix.sh`
- One-command installer, updater, uninstaller

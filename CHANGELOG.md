# PhantomSec OS — Changelog

All notable changes to this project will be documented here.

---

## [1.3.1] — 2026-07-24 — Bug Fix Release

### Fixed

| # | File | Bug | Fix |
|---|------|-----|-----|
| 1 | `phantomsec.sh` | VERSION fallback hardcoded as `1.2.0` — wrong version shown if VERSION file missing | Changed fallback to `1.3.1` |
| 2 | `phantomsec.sh` | `run_shodan()` — Python URL encoding used `python3 -c "...quote('$query')"` — queries containing `'` or `"` crashed the shell substitution | Rewrote as `printf '%s' "$query" \| python3 -c 'import sys,urllib.parse; ...'` (same safe pipe pattern as XSS fix) |
| 3 | `phantomsec.sh` | `menu_settings` option 1 — config displayed from `$HOME/.config/phantomsec/settings.conf` (never created by installer) | Corrected to `$PHANTOMSEC_DIR/config/settings.conf`; also creates dir if missing |
| 4 | `phantomsec.sh` | `run_lfi()` — second `curl` call (prints vulnerable file content) had no `--max-time`, hangs on slow targets | Added `--max-time 5` |
| 5 | `phantomsec.sh` | `run_cors()` — `curl -sI` had no timeout, hangs on unresponsive servers | Added `--max-time 8` |
| 6 | `phantomsec.sh` | `run_xss_gen()` — HTTP test `curl` had no timeout | Added `--max-time 5` |
| 7 | `phantomsec.sh` | `menu_crypto` Caesar cipher — shift value `$sh` interpolated directly into `python3 -c` without validation; non-numeric input threw unhandled Python exception | Added `[[ "$sh" =~ ^[0-9]+$ ]]` guard before calling Python |
| 8 | `phantomsec.sh` | `run_subdomain()` — `dig +short A $full` had unquoted variable; subdomains with spaces or special chars broke the command | Quoted: `dig +short A "$full"` |
| 9 | `phantomsec.sh` | `menu_tool_manager` option 4 "Update PhantomSec" — used `bash "$(dirname "$0")/update.sh"` which resolves to `/data/data/com.termux/files/usr/bin/` when run from `$PREFIX/bin`, not the repo dir — update silently failed | Rewrote with fallback search across `$_SCRIPT_DIR`, `$HOME/distro-os-cyber-agian-on-termux`, `$HOME/phantomsec`, `$HOME/PhantomSec`; shows clear error + clone command if not found |
| 10 | `phantomsec.sh` | `$PHANTOMSEC_DIR/config/` directory never created on startup | Added `config` to `mkdir -p "$PHANTOMSEC_DIR"/{logs,sessions,wordlists,reports,**config**}` |
| 11 | `install.sh` + `config/settings.conf` | VERSION still `1.3.0` after previous release | Updated to `1.3.1` |

### Added

- **`phantomsec.sh`** — `menu_tool_manager` option **[5] Check for Updates** — fetches `VERSION` from GitHub and compares with installed version; shows update prompt if behind

---

## [1.3.0] — 2026-07-24

### Fixed
- `phantomsec.sh` header comment v1.0.0 → v1.3.0
- Duplicate case patterns `10|10)` `11|11)` `12|12)` → `10)` `11)` `12)`
- `show_banner` IP fetch no timeout → `--max-time 3`
- `run_xss_gen` Python quoting broke on payloads with quotes → printf pipeline
- Settings config path wrong → `$PHANTOMSEC_DIR/config/`
- `menu_vuln_scan` option 2 missing from case → added handler
- `run_dirbust` / `run_lfi` curl no timeout → `--max-time 5`
- `install.sh` + `config/settings.conf` hardcoded VERSION 1.1.0 → 1.3.0

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
- `run_dirbust()` draw_line syntax bug
- Menus 06/08/09/11/12 missing `while` loops
- Tool Manager option 4 was no-op stub
- Settings Shodan key duplicate line append
- `md5sum`/`sha256sum` unquoted arguments
- Caesar cipher rewritten in Python3
- `update.sh` REPO URL spelling corrected
- `README.md` / `docs/USAGE.md` clone URLs corrected

### Added
- `themes/dark.sh`, `themes/classic.sh`, `modules/privesc.sh`, `CHANGELOG.md`

---

## [1.0.0] — Initial Release

- Interactive Bash menu UI for Termux cybersecurity research
- Modules: Information Gathering, Vuln Scanning, Web Exploitation, Password Attacks, Network Analysis, Wireless, Reverse Shells, Forensics, Cryptography, Tool Manager, Sessions, Settings
- Standalone modules: `recon.sh`, `webexploit.sh`, `nettools.sh`
- Themes: `matrix.sh`
- One-command installer, updater, uninstaller

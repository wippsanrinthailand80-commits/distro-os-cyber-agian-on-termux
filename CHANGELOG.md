# PhantomSec OS — Changelog

All notable changes to this project will be documented here.

---

## [1.1.0] — 2026-07-24

### Fixed
- **`phantomsec.sh`** — Syntax bug: `draw_line "─" 66""` (extra empty string) in `run_dirbust()` — now `draw_line "─" 66`
- **`phantomsec.sh`** — Menus 06 (Wireless), 08 (Forensics), 09 (Crypto), 11 (Sessions), 12 (Settings) were missing `while` loops, so pressing `0` to go back did not work — all converted to proper `while true` loops with `0) return ;;`
- **`phantomsec.sh`** — Tool Manager option 4 "Update PhantomSec" was a no-op stub — now correctly calls `update.sh`
- **`phantomsec.sh`** — Settings option 2 (Set Shodan API key) was appending duplicate lines on every save — now uses `sed -i` to replace the existing entry, with append-only fallback for first-time use
- **`phantomsec.sh`** — `md5sum`/`sha256sum` in Forensics menu now properly quoted: `md5sum "$f"` instead of `md5sum $f`
- **`phantomsec.sh`** — Caesar cipher in Crypto menu rewritten to pure Python3 (avoids `tr` argument-length limits on long strings)
- **`update.sh`** — `REPO` URL was `distro-os-cyber-again-on-termux` (wrong spelling) — corrected to `distro-os-cyber-agian-on-termux`
- **`README.md`** — Install and update clone URLs corrected to match actual repository name
- **`docs/USAGE.md`** — Clone URL corrected to match actual repository name

### Added
- **`themes/dark.sh`** — Dark colour theme configurator (minimal dark background + colour swatch preview)
- **`themes/classic.sh`** — Classic green-on-black hacker terminal theme
- **`modules/privesc.sh`** — Standalone privilege escalation recon module: checks SUID binaries, sudo rules, world-writable directories, cron jobs, listening services, readable sensitive files, and kernel info
- **`CHANGELOG.md`** — This file

### Changed
- Version bumped from `1.0.0` → `1.1.0` across `phantomsec.sh`, `install.sh`, `config/settings.conf`, and `README.md` badge

---

## [1.0.0] — Initial Release

- Interactive Bash menu UI for Termux cybersecurity research
- Modules: Information Gathering, Vuln Scanning, Web Exploitation, Password Attacks, Network Analysis, Wireless, Reverse Shells, Forensics, Cryptography, Tool Manager, Sessions, Settings
- Standalone modules: `recon.sh`, `webexploit.sh`, `nettools.sh`
- Themes: `matrix.sh`
- One-command installer, updater, and uninstaller

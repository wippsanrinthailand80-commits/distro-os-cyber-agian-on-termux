# PhantomSec OS — Changelog

## v2.5.0 (2026-07-25)

### Added
- Full version bump across all editions (Distro Feel, OS, Termux) to 2.5.0
- `modules/osint.sh`: OSINT module now uses `jq` for JSON pretty-print with `python3` fallback — no longer fails when python3 is absent

### Fixed
- **Bug fix**: `modules/osint.sh` / `distro-feel/modules/osint.sh` — replaced hard `python3 -m json.tool` dependency with `jq` primary + `python3` fallback + raw `cat` last-resort; module no longer crashes on minimal Termux installs without python3
- **Version consistency**: unified version strings across `VERSION`, `distro-feel/VERSION`, all `README.md` files, `install.sh` scripts, and `phantomsec.sh`
- **os/README.md**: corrected `2.0.1-alpha` badge version to match unified 2.5.0 release

### Changed
- All edition version strings aligned to `2.5.0`

---

## v2.0.1 (2026-07-25)

### Fixed
- Minor version string corrections across Distro Feel edition

---

## v2.0.0-alpha (2026-07-25)

### Added
- Complete rewrite from Shell script to **C/C++**
- **SpecterScan** — Passive firewall ACL reconstructor via TCP timing analysis
- **EntropyWarden** — Real-time ransomware detector via inotify + Shannon entropy
- **SyscallDNA** — Markov-chain syscall behavioral fingerprinter via ptrace
- **NetGhost** — Passive network topology mapper (zero packets transmitted)
- **PhantomShell (psh)** — Custom bilingual shell for PhantomSec OS
- Full bilingual i18n system (English / ภาษาไทย)
- Custom Linux distro build system (build.sh — Linux from scratch)
- Hardened kernel configuration (kernel.config)
- Master Makefile with LANG=th support

### Changed
- Base: Termux/Android → Native Linux from scratch
- Modules: Shell wrappers → Original C tools with unique algorithms
- i18n: Partial → Full bilingual support in all tools

### Removed
- Python dependency (all functionality reimplemented in C)
- Termux-specific code paths

---

## v1.x (2026-07-24)

- Original Shell-based cybersecurity tool collection
- Modules: nettools, osint, privesc, recon, webexploit
- Themes: classic, dark, matrix
- Thai/English mixed interface
- Ran on Termux (Android)

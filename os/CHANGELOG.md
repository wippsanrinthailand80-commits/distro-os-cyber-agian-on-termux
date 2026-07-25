# PhantomSec OS — Changelog

## v2.5.2 (2026-07-25)

### Fixed
- **CRITICAL**: Termux installer — replaced `xxd` with `od` for rootfs gzip validation (xxd not installed by default, caused installer to always fail)
- **CRITICAL**: Termux installer — removed incompatible Alpine Linux fallback (Ubuntu APT config applied to Alpine rootfs = broken system)
- **CRITICAL**: distro-feel — fixed 3 shell injection vulnerabilities in password hash, JWT decoder, and entropy analysis (user input was interpolated directly into Python code)
- **CRITICAL**: os/ Makefile — fixed PREFIX mismatch with install.sh (tools installed to `/usr/local/name` instead of `/usr/local/bin/name`, not on PATH)
- **HIGH**: os/ Makefile — removed unnecessary `-lreadline` from psh build (code uses fgets, not readline; caused build failure without libreadline-dev)
- **HIGH**: os/ build.sh — fixed sed SYSROOT expansion (single-quotes prevented variable expansion, breaking BusyBox build)
- **HIGH**: distro-feel — created missing `wordlists/` directory with `common.txt` and `params.txt`
- **MEDIUM**: Termux — detect architecture for correct APT mirror (x86_64 was getting ARM64 packages)
- **MEDIUM**: os/ install.sh — renamed `LANG` to `PS_LANG` to avoid overwriting POSIX locale
- **MEDIUM**: os/ spectrscan.c — fixed `ntohs()` to `inet_ntoa()` for correct IP display
- **MEDIUM**: os/ build.sh — fixed `CONFIG_SYS_FS` to `CONFIG_SYSFS` (invalid kernel option)
- **MEDIUM**: distro-feel — added `jq`/`python3`/`cat` fallback chains for Shodan and GeoIP
- **MEDIUM**: distro-feel — fixed `require_tool` return value check in port scan
- **LOW**: Termux — added `$HOME:/root` bind-mount to per-tool launchers (was inconsistent with main launcher)
- **LOW**: Termux — fixed double checkmark in architecture message
- **LOW**: Termux — use `/tmp` for rootfs tarball with cleanup trap
- **LOW**: distro-feel — fixed duplicate PATH entries on re-install
- **LOW**: distro-feel — fixed blood.sh theme (all colors were identical red, no visual distinction)
- **LOW**: All version strings unified to v2.5.2 across every file

### Changed
- All edition version strings aligned to `2.5.2`
- Alpine Linux removed from Termux fallback URLs (incompatible with Ubuntu config)

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

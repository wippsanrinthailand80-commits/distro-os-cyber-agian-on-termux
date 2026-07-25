# PhantomSec OS — Changelog

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
- PhantomSec OS website (React + Vite, dark terminal aesthetic)

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

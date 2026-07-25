# phantom-proot

> PhantomSec user-space chroot — written from scratch in C, zero dependencies on proot-distro or any third-party proot code.

---

## What it does

`phantom-proot` lets you run a full Linux rootfs **without root** on Termux (Android) or any Linux machine. It works by:

1. **Forking** a child process that calls `PTRACE_TRACEME`.
2. **Intercepting every syscall** that touches a filesystem path using `ptrace`.
3. **Translating** each guest path (e.g. `/etc/passwd`) to its real host location (e.g. `~/rootfs/etc/passwd`) before the kernel sees it.
4. **De-translating** paths on the way back out (e.g. `getcwd`, `readlink`).

No kernel modules. No setuid. No root.

---

## Architecture

```
phantom-proot/
├── Makefile
├── README.md
└── src/
    ├── proot.h      — shared types, limits, prototypes
    ├── main.c       — argument parsing, fork, launch
    ├── arch.c       — ptrace register access (ARM64 + x86-64)
    ├── path.c       — guest↔host path translation
    ├── mount.c      — virtual bind-mount table
    ├── tracee.c     — ptrace event loop, process tracking
    └── syscall.c    — per-syscall enter/exit handlers
```

### Key design decisions

| Decision | Rationale |
|----------|-----------|
| ptrace-based | No root required; works in Termux user-space |
| Scratch area at SP−8192 | Kernel does not touch user stack during syscall; safe scratch without allocation |
| Longest-prefix bind lookup | O(n) but n ≤ 64; simpler than a trie for this scale |
| ARM64 primary, x86-64 secondary | Termux is ARM64; x86-64 support is a compile-time bonus |
| No libc chroot call | We never call the real chroot — we emulate it via ptrace |

---

## Build

### On Termux (Android, ARM64)
```bash
cd os/tools/proot
make
make install   # installs to ~/.local/bin/phantom-proot
```

### On Linux (x86-64)
```bash
cd os/tools/proot
make CC=gcc
```

### Cross-compile ARM64 → from x86-64 host
```bash
make CC=aarch64-linux-gnu-gcc
```

---

## Usage

```
phantom-proot -r <rootfs> [-b <host>:<guest> ...] [-w <cwd>] -- <cmd> [args...]
```

| Flag | Description |
|------|-------------|
| `-r <rootfs>` | Directory to use as fake root (required) |
| `-b <host>:<guest>` | Bind host path into guest (repeat for each mount) |
| `-w <dir>` | Initial working directory inside the guest (default: `/`) |
| `-h` | Help |

### Minimal example
```bash
phantom-proot -r ~/phantomsec-rootfs -- /bin/bash
```

### Recommended Termux setup (with /proc /dev /sys)
```bash
phantom-proot \
  -r ~/phantomsec-rootfs \
  -b /proc:/proc         \
  -b /dev:/dev           \
  -b /sys:/sys           \
  -b /data/data/com.termux/files/home:/root \
  -- /bin/bash --login
```

---

## Syscall coverage

All path-taking syscalls are intercepted:

| Category | Syscalls |
|----------|---------|
| Open/exec | `openat`, `execve`, `execveat` |
| Stat/access | `newfstatat`, `faccessat`, `faccessat2`, `statfs` |
| Directory | `mkdirat`, `unlinkat`, `renameat`, `renameat2` |
| Links | `linkat`, `symlinkat`, `readlinkat` |
| Permissions | `fchmodat`, `fchownat`, `utimensat`, `truncate` |
| Navigation | `chdir`, `chroot`, `getcwd` |
| Legacy x86-64 | `open`, `stat`, `lstat`, `access`, `mkdir`, `rmdir`, `unlink`, `rename`, `readlink`, `chmod`, `chown`, `link`, `symlink` |

---

## Limitations

- **No architecture emulation** — the binary inside the rootfs must match the host CPU.
- **No network namespace** — networking is shared with the host.
- **ptrace overhead** — every syscall causes a context switch into the tracer; suitable for interactive use, not high-throughput I/O loops.
- **Signal delivery** — signals sent directly to tracees work; signals to process groups may behave differently.

---

## Integration with PhantomSec OS

This proot replaces `proot-distro` in `termux/install.sh`.  
The installer can build it from source and use it to boot the PhantomSec rootfs:

```bash
# Build phantom-proot first
make -C os/tools/proot install

# Then launch
phantom-proot -r ~/.phantomsec-rootfs \
      -b /proc:/proc -b /dev:/dev -b /sys:/sys \
      -- /bin/bash --login
```

---

*PhantomSec phantom-proot — no root, no third-party proot, no compromises.*

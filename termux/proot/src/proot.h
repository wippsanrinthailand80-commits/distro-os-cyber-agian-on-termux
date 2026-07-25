/*
 * phantom-proot v2.8.0 — Custom proot from scratch
 * Minimal userspace implementation for Termux/Android aarch64
 *
 * Architecture:
 * - Register cache: read once per syscall event, write once at end
 * - Per-process root: each tracee tracks its own root
 * - Proper CWD normalization with .. resolution
 * - dirfd support for *at syscalls via /proc/self/fd/N
 */

#ifndef PHANTOM_PROOT_H
#define PHANTOM_PROOT_H

#include <stdint.h>
#include <sys/types.h>

/* ── Limits ─────────────────────────────────────────────────────────────── */

#define PP_MAX_PATH      4096
#define PP_MAX_BINDS     64
#define PP_MAX_TRACEES   256
#define PP_MAX_ARGS      6
#define PP_SCRATCH_SIZE  65536       /* 64KB scratch below SP */

/* ── Architecture ───────────────────────────────────────────────────────── */

#if defined(__aarch64__)

/* Register layout matches kernel's struct user_pt_regs */
typedef struct {
    uint64_t regs[31];
    uint64_t sp;
    uint64_t pc;
    uint64_t pstate;
} pp_regs_t;

/* aarch64 syscall ABI */
#define PP_REG_SYSNO    8   /* x8 */
#define PP_REG_RETVAL   0   /* x0 */
#define PP_REG_SP       31  /* sp = regs[31] */

/* aarch64 syscall numbers (Linux 5.x+) */
#define PP_SYS_chdir            49
#define PP_SYS_chroot           51
#define PP_SYS_openat           56
#define PP_SYS_faccessat        48
#define PP_SYS_faccessat2       439
#define PP_SYS_fchmodat         53
#define PP_SYS_fchownat         54
#define PP_SYS_mkdirat          34
#define PP_SYS_unlinkat         35
#define PP_SYS_symlinkat        36
#define PP_SYS_linkat           37
#define PP_SYS_renameat         38
#define PP_SYS_renameat2        276
#define PP_SYS_readlinkat       78
#define PP_SYS_newfstatat       79
#define PP_SYS_utimensat        88
#define PP_SYS_execve           221
#define PP_SYS_execveat         281
#define PP_SYS_statfs           43
#define PP_SYS_truncate         45
#define PP_SYS_getcwd           17

#elif defined(__x86_64__)

typedef struct {
    uint64_t r15, r14, r13, r12;
    uint64_t rbp, rbx;
    uint64_t r11, r10, r9, r8;
    uint64_t rax, rcx, rdx, rsi, rdi;
    uint64_t orig_rax;
    uint64_t rip, cs, eflags;
    uint64_t rsp, ss;
    uint64_t fs_base, gs_base, ds, es, fs, gs;
} pp_regs_t;

#define PP_REG_SYSNO    15  /* orig_rax */
#define PP_REG_RETVAL   13  /* rax */
#define PP_REG_SP       19  /* rsp */

/* x86-64 syscall numbers */
#define PP_SYS_open             2
#define PP_SYS_stat             4
#define PP_SYS_lstat            6
#define PP_SYS_access           21
#define PP_SYS_chdir            80
#define PP_SYS_chroot           161
#define PP_SYS_mkdir            83
#define PP_SYS_rmdir            84
#define PP_SYS_rename           82
#define PP_SYS_link             86
#define PP_SYS_unlink           87
#define PP_SYS_symlink          88
#define PP_SYS_readlink         89
#define PP_SYS_chmod            90
#define PP_SYS_chown            92
#define PP_SYS_openat           257
#define PP_SYS_faccessat        269
#define PP_SYS_fchmodat         268
#define PP_SYS_fchownat         260
#define PP_SYS_mkdirat          258
#define PP_SYS_unlinkat         263
#define PP_SYS_symlinkat        265
#define PP_SYS_linkat           264
#define PP_SYS_renameat         264
#define PP_SYS_renameat2        302
#define PP_SYS_readlinkat       267
#define PP_SYS_newfstatat       262
#define PP_SYS_utimensat        280
#define PP_SYS_execve           59
#define PP_SYS_execveat         322
#define PP_SYS_statfs           137
#define PP_SYS_truncate         76
#define PP_SYS_getcwd           79

#else
#error "Unsupported architecture"
#endif

/* AT_FDCWD as used by *at syscalls */
#define PP_AT_FDCWD     (-100)

/* ── Data Structures ────────────────────────────────────────────────────── */

/* Bind mount: host path ↔ guest path */
typedef struct {
    char host[PP_MAX_PATH];
    char guest[PP_MAX_PATH];
} pp_bind_t;

/* Per-process state */
typedef struct pp_proc {
    pid_t       pid;
    int         in_syscall;         /* 0 = enter next, 1 = exit next */
    long        saved_sysno;
    uint64_t    saved_arg[PP_MAX_ARGS];
    char        cwd[PP_MAX_PATH];   /* tracked guest CWD */
    char        root[PP_MAX_PATH];  /* per-process root (guest→host mapping) */
    /* Register cache: read once on ENTER, write once on EXIT */
    pp_regs_t   regs;
    int         regs_dirty;         /* 1 = regs modified, need to write back */
} pp_proc_t;

/* Global proot state */
typedef struct {
    char        root[PP_MAX_PATH];      /* fake root (host path) */
    pp_bind_t   binds[PP_MAX_BINDS];
    int         nbinds;
    pp_proc_t   procs[PP_MAX_TRACEES];
    int         nprocs;
    int         verbose;
} pp_state_t;

/* ── Global state ───────────────────────────────────────────────────────── */

extern pp_state_t g_pp;

/* ── Function prototypes ────────────────────────────────────────────────── */

/* mount.c */
int  mount_add(const char *host, const char *guest);
const pp_bind_t *mount_lookup(const char *guest_path);

/* path.c */
int  path_normalize(char *path);
int  path_translate(const char *root, const char *cwd,
                    const char *guest, char *out, size_t outsz);
int  path_detranslate(const char *root, const pp_bind_t *binds, int nbinds,
                      const char *host, char *out, size_t outsz);

/* mem.c */
int  mem_read(pid_t pid, uint64_t addr, void *buf, size_t len);
int  mem_write(pid_t pid, uint64_t addr, const void *buf, size_t len);
int  mem_read_str(pid_t pid, uint64_t addr, char *buf, size_t bufsz);
int  mem_write_str(pid_t pid, uint64_t addr, const char *str);

/* arch.c */
int  arch_get_regs(pid_t pid, pp_regs_t *regs);
int  arch_set_regs(pid_t pid, const pp_regs_t *regs);
int  arch_get_sysno(const pp_proc_t *proc, long *sysno);
int  arch_get_args(const pp_proc_t *proc, uint64_t args[PP_MAX_ARGS]);
int  arch_set_arg(pp_proc_t *proc, int argno, uint64_t val);
int  arch_get_retval(const pp_proc_t *proc, uint64_t *val);
int  arch_set_retval(pp_proc_t *proc, uint64_t val);
uint64_t arch_get_sp(const pp_proc_t *proc);

/* syscall.c */
void syscall_handle_enter(pp_proc_t *proc);
void syscall_handle_exit(pp_proc_t *proc);

/* proc.c */
pp_proc_t *proc_find(pid_t pid);
pp_proc_t *proc_add(pid_t pid, const char *cwd, const char *root);
void proc_remove(pid_t pid);
void proc_inherit(pp_proc_t *parent, pid_t child_pid);
void proc_event_loop(pid_t root_pid);

#endif /* PHANTOM_PROOT_H */

/* syscall.c — Per-syscall enter/exit handlers
 * PhantomSec phantom-proot
 *
 * On ENTER: intercept path arguments, translate guest→host,
 *           write translated string into tracee scratch memory,
 *           redirect the argument register to the new string.
 * On EXIT:  fix up any return-value paths (getcwd, readlink).
 *
 * Scratch strategy:
 *   We write translated strings to [SP - PP_SCRATCH_OFF].
 *   The kernel does not touch user stack during syscall execution
 *   on ARM64 or x86-64 for the syscalls we intercept, so this
 *   region is safe to use as temporary storage.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/ptrace.h>
#include <sys/types.h>

#include "proot.h"

/* ── ARM64 syscall numbers ──────────────────────────────── */
#if defined(__aarch64__)
#  define SYS_chdir      49
#  define SYS_chroot     51
#  define SYS_openat     56
#  define SYS_statfs     43
#  define SYS_truncate   45
#  define SYS_faccessat  48
#  define SYS_fchmodat   53
#  define SYS_fchownat   54
#  define SYS_mkdirat    34
#  define SYS_unlinkat   35
#  define SYS_symlinkat  36
#  define SYS_linkat     37
#  define SYS_renameat   38
#  define SYS_renameat2  276
#  define SYS_readlinkat 78
#  define SYS_newfstatat 79
#  define SYS_utimensat  88
#  define SYS_execve     221
#  define SYS_execveat   281
#  define SYS_faccessat2 439
#  define SYS_getcwd     17

/* ── x86-64 syscall numbers ─────────────────────────────── */
#elif defined(__x86_64__)
#  define SYS_chdir      80
#  define SYS_chroot     161
#  define SYS_openat     257
#  define SYS_statfs     137
#  define SYS_truncate   76
#  define SYS_faccessat  269
#  define SYS_fchmodat   268
#  define SYS_fchownat   260
#  define SYS_mkdirat    258
#  define SYS_unlinkat   263
#  define SYS_symlinkat  266
#  define SYS_linkat     265
#  define SYS_renameat   264
#  define SYS_renameat2  316
#  define SYS_readlinkat 267
#  define SYS_newfstatat 262
#  define SYS_utimensat  280
#  define SYS_execve     59
#  define SYS_execveat   322
#  define SYS_faccessat2 439
#  define SYS_getcwd     79
/* legacy (also valid on x86-64) */
#  define SYS_open       2
#  define SYS_stat       4
#  define SYS_lstat      6
#  define SYS_access     21
#  define SYS_mkdir      83
#  define SYS_rmdir      84
#  define SYS_unlink     87
#  define SYS_rename     82
#  define SYS_readlink   89
#  define SYS_chmod      90
#  define SYS_chown      92
#  define SYS_symlink    88
#  define SYS_link       86
#endif

/* ── Helpers: read/write tracee memory ──────────────────── */

/* Read a NUL-terminated string from tracee addr into local buf.
 * Returns bytes read (including NUL), or -1. */
static int mem_read_str(pid_t pid, unsigned long addr,
                        char *buf, size_t bufsz)
{
    size_t done = 0;
    while (done < bufsz - 1) {
        errno = 0;
        long word = ptrace(PTRACE_PEEKDATA, pid,
                           (void *)(addr + done), NULL);
        if (errno) return -1;
        /* copy up to 8 bytes, stop at NUL */
        unsigned char *b = (unsigned char *)&word;
        for (int i = 0; i < 8 && done < bufsz - 1; i++, done++) {
            buf[done] = (char)b[i];
            if (b[i] == 0) goto done;
        }
    }
done:
    buf[done] = '\0';
    return (int)done;
}

/* Write bytes to tracee addr (8 bytes at a time). */
static int mem_write(pid_t pid, unsigned long addr,
                     const void *src, size_t len)
{
    const unsigned char *s = src;
    size_t i = 0;
    /* aligned 8-byte writes */
    for (; i + 8 <= len; i += 8) {
        long word;
        memcpy(&word, s + i, 8);
        if (ptrace(PTRACE_POKEDATA, pid,
                   (void *)(addr + i), (void *)word) < 0)
            return -1;
    }
    /* remainder */
    if (i < len) {
        errno = 0;
        long word = ptrace(PTRACE_PEEKDATA, pid,
                           (void *)(addr + i), NULL);
        if (errno) return -1;
        unsigned char *wb = (unsigned char *)&word;
        size_t rem = len - i;
        memcpy(wb, s + i, rem);
        if (ptrace(PTRACE_POKEDATA, pid,
                   (void *)(addr + i), (void *)word) < 0)
            return -1;
    }
    return 0;
}

/* ── Core: rewrite a path argument ─────────────────────────
 *
 * Reads the string at tracee args[argno], translates it,
 * writes the result to the scratch area below SP, and
 * updates the argument register to point there.
 *
 * Returns 0 on success, -1 on error.
 */
static int rewrite_path_arg(pp_tracee_t *t, int argno)
{
    /* read original path from tracee */
    char orig[PP_MAX_PATH];
    unsigned long ptr = t->saved_arg[argno];
    if (!ptr) return 0;  /* NULL path — skip */

    if (mem_read_str(t->pid, ptr, orig, sizeof(orig)) < 0) {
        fprintf(stderr, "[proot] mem_read_str failed (pid %d arg %d)\n",
                t->pid, argno);
        return -1;
    }
    if (orig[0] == '\0') return 0;

    /* translate guest→host */
    char translated[PP_MAX_PATH];
    if (path_translate(g_pp.root, t->cwd, orig,
                       translated, sizeof(translated)) < 0)
        return -1;

    /* write translated string into tracee scratch area */
    unsigned long sp     = arch_get_sp(t->pid);
    unsigned long scratch = (sp - PP_SCRATCH_OFF) & ~(unsigned long)7;
    /* Each successive arg gets its own slot */
    scratch += (unsigned long)(argno * PP_MAX_PATH);

    size_t tlen = strlen(translated) + 1;
    if (mem_write(t->pid, scratch, translated, tlen) < 0) {
        fprintf(stderr, "[proot] mem_write failed (pid %d)\n", t->pid);
        return -1;
    }

    /* point the syscall argument at the scratch copy */
    arch_set_arg(t->pid, argno, scratch);
    return 0;
}

/* ── Syscall ENTER ──────────────────────────────────────── */
void syscall_handle_enter(pp_tracee_t *t)
{
    long sysno = t->saved_sysno;

    /*
     * For each syscall variant, rewrite the path argument(s).
     *
     * Notation: arg0..arg5 are the syscall arguments.
     * "fd" arguments (dirfd, AT_FDCWD) are NOT rewritten.
     * Only string (char*) path arguments are rewritten.
     */

    /* ── single path in arg0 ── */
    if (sysno == SYS_chdir   ||
        sysno == SYS_chroot  ||
        sysno == SYS_execve  ||
        sysno == SYS_statfs  ||
        sysno == SYS_truncate) {
        rewrite_path_arg(t, 0);
        return;
    }

#if defined(__x86_64__)
    /* legacy x86-64 single-path arg0 syscalls */
    if (sysno == SYS_open    ||
        sysno == SYS_stat    ||
        sysno == SYS_lstat   ||
        sysno == SYS_access  ||
        sysno == SYS_mkdir   ||
        sysno == SYS_rmdir   ||
        sysno == SYS_unlink  ||
        sysno == SYS_readlink||
        sysno == SYS_chmod   ||
        sysno == SYS_chown   ||
        sysno == SYS_symlink) {
        rewrite_path_arg(t, 0);
        return;
    }
    if (sysno == SYS_rename || sysno == SYS_link) {
        rewrite_path_arg(t, 0);
        rewrite_path_arg(t, 1);
        return;
    }
#endif

    /* ── *at syscalls: path is arg1 (arg0 = dirfd) ── */
    if (sysno == SYS_openat     ||
        sysno == SYS_faccessat  ||
        sysno == SYS_faccessat2 ||
        sysno == SYS_fchmodat   ||
        sysno == SYS_fchownat   ||
        sysno == SYS_mkdirat    ||
        sysno == SYS_unlinkat   ||
        sysno == SYS_readlinkat ||
        sysno == SYS_newfstatat ||
        sysno == SYS_utimensat  ||
        sysno == SYS_execveat) {
        rewrite_path_arg(t, 1);
        return;
    }

    /* ── renameat / linkat: two paths (arg1 and arg3) ── */
    if (sysno == SYS_renameat ||
        sysno == SYS_renameat2||
        sysno == SYS_linkat) {
        rewrite_path_arg(t, 1);
        rewrite_path_arg(t, 3);
        return;
    }

    /* ── symlinkat: target in arg0, newpath in arg2 ── */
    if (sysno == SYS_symlinkat) {
        rewrite_path_arg(t, 0);
        rewrite_path_arg(t, 2);
        return;
    }
}

/* ── Syscall EXIT ───────────────────────────────────────── */
void syscall_handle_exit(pp_tracee_t *t)
{
    long sysno = t->saved_sysno;
    long ret;
    if (arch_get_retval(t->pid, &ret) < 0) return;
    if (ret < 0) return;  /* syscall failed — nothing to fix */

    /* chdir succeeded: update our tracked guest cwd */
    if (sysno == SYS_chdir) {
        char orig[PP_MAX_PATH];
        unsigned long ptr = t->saved_arg[0];
        if (ptr && mem_read_str(t->pid, ptr, orig, sizeof(orig)) > 0) {
            char abs[PP_MAX_PATH];
            if (orig[0] == '/') {
                snprintf(abs, sizeof(abs), "%s", orig);
            } else {
                snprintf(abs, sizeof(abs), "%s/%s", t->cwd, orig);
            }
            /* normalize by re-translating and stripping root prefix */
            char host[PP_MAX_PATH];
            path_translate(g_pp.root, t->cwd, orig, host, sizeof(host));
            path_detranslate(g_pp.root, host, t->cwd, sizeof(t->cwd));
        }
        return;
    }

    /* chroot: update our fake root path */
    if (sysno == SYS_chroot) {
        /* The tracee tried to chroot — we intercepted the path arg
         * and already translated it to the host path on enter.
         * On exit, update g_pp.root to reflect the new fake root. */
        char orig[PP_MAX_PATH];
        unsigned long ptr = t->saved_arg[0];
        if (ptr && mem_read_str(t->pid, ptr, orig, sizeof(orig)) > 0) {
            char translated[PP_MAX_PATH];
            path_translate(g_pp.root, t->cwd, orig,
                           translated, sizeof(translated));
            snprintf(g_pp.root, sizeof(g_pp.root), "%s", translated);
        }
        return;
    }

    /* getcwd: the kernel wrote the real host path into the buffer.
     * We must de-translate it back to the guest path. */
    if (sysno == SYS_getcwd) {
        unsigned long buf  = t->saved_arg[0];
        unsigned long size = t->saved_arg[1];
        if (!buf || !size) return;

        char host_cwd[PP_MAX_PATH];
        if (mem_read_str(t->pid, buf, host_cwd, sizeof(host_cwd)) < 0)
            return;

        char guest_cwd[PP_MAX_PATH];
        path_detranslate(g_pp.root, host_cwd, guest_cwd, sizeof(guest_cwd));

        size_t glen = strlen(guest_cwd) + 1;
        if (glen > size) {
            arch_set_retval(t->pid, -ERANGE);
            return;
        }
        mem_write(t->pid, buf, guest_cwd, glen);
        arch_set_retval(t->pid, (long)glen);
        return;
    }

    /* readlinkat: the kernel wrote the real path into buf.
     * De-translate any path inside root. */
    if (sysno == SYS_readlinkat) {
        unsigned long buf   = t->saved_arg[2];
        unsigned long bufsz = t->saved_arg[3];
        if (!buf || !bufsz || ret <= 0) return;

        char host_lnk[PP_MAX_PATH];
        size_t readlen = (size_t)ret < bufsz ? (size_t)ret : bufsz;
        if (readlen >= sizeof(host_lnk)) return;
        if (mem_read_str(t->pid, buf, host_lnk, readlen + 1) < 0) return;
        host_lnk[readlen] = '\0';

        char guest_lnk[PP_MAX_PATH];
        if (path_detranslate(g_pp.root, host_lnk, guest_lnk,
                             sizeof(guest_lnk)) == 0) {
            size_t glen = strlen(guest_lnk);
            if (glen <= bufsz) {
                mem_write(t->pid, buf, guest_lnk, glen);
                arch_set_retval(t->pid, (long)glen);
            }
        }
        return;
    }
}

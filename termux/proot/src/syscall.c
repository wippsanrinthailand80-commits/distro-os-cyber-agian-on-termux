/*
 * syscall.c — Syscall interception and path rewriting
 *
 * Key improvements over old proot:
 * - dirfd support via /proc/self/fd/N for *at syscalls
 * - chroot is per-process (not global)
 * - chdir uses path_normalize for .. resolution
 * - getcwd properly de-translates through bind mounts
 * - readlinkat properly updates return value and clears leftover data
 * - Register cache: reads/writes regs via proc->regs, not raw ptrace
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ptrace.h>
#include "proot.h"

/* ── Helpers ────────────────────────────────────────────────────────────── */

/*
 * Resolve a dirfd to a guest path.
 * For AT_FDCWD, returns the process CWD.
 * For other fds, reads /proc/<pid>/fd/<dirfd> and de-translates.
 */
static int resolve_dirfd(pp_proc_t *proc, int dirfd, char *out, size_t outsz)
{
    if (dirfd == PP_AT_FDCWD) {
        snprintf(out, outsz, "%s", proc->cwd);
        return 0;
    }

    /* Read symlink /proc/<pid>/fd/<dirfd> to get host path */
    char fdlink[128];
    char host_path[PP_MAX_PATH];
    snprintf(fdlink, sizeof(fdlink), "/proc/%d/fd/%d", proc->pid, dirfd);

    ssize_t len = readlink(fdlink, host_path, sizeof(host_path) - 1);
    if (len < 0) {
        /* Fallback: use CWD */
        snprintf(out, outsz, "%s", proc->cwd);
        return 0;
    }
    host_path[len] = '\0';

    /* De-translate host path back to guest path */
    if (path_detranslate(proc->root, g_pp.binds, g_pp.nbinds,
                         host_path, out, outsz) < 0) {
        snprintf(out, outsz, "%s", proc->cwd);
    }
    return 0;
}

/*
 * Rewrite a path argument from the tracee's memory.
 * Reads the original guest path, translates to host, writes to scratch.
 * If argno involves a dirfd, resolves it first.
 */
static int rewrite_path_arg(pp_proc_t *proc, int argno, int dirfd_argno)
{
    uint64_t args[PP_MAX_ARGS];
    arch_get_args(proc, args);

    /* Read the guest path from tracee memory */
    char guest_path[PP_MAX_PATH];
    if (mem_read_str(proc->pid, args[argno], guest_path,
                     sizeof(guest_path)) < 0)
        return -1;

    /* Determine base directory */
    char base[PP_MAX_PATH];
    if (dirfd_argno >= 0) {
        resolve_dirfd(proc, (int)args[dirfd_argno], base, sizeof(base));
    } else {
        snprintf(base, sizeof(base), "%s", proc->cwd);
    }

    /* Translate guest path to host path */
    char host_path[PP_MAX_PATH];
    if (path_translate(proc->root, base, guest_path,
                       host_path, sizeof(host_path)) < 0)
        return -1;

    /* Write host path to scratch area below SP */
    uint64_t sp = arch_get_sp(proc);
    uint64_t scratch = sp - PP_SCRATCH_SIZE + (uint64_t)argno * PP_MAX_PATH;

    /* Align to 8 bytes */
    scratch &= ~(uint64_t)7;

    if (mem_write_str(proc->pid, scratch, host_path) < 0)
        return -1;

    /* Point the argument register to the scratch copy */
    arch_set_arg(proc, argno, scratch);

    return 0;
}

/*
 * Rewrite two path arguments (for renameat, linkat, etc.)
 */
static int rewrite_two_path_args(pp_proc_t *proc,
                                 int arg1, int dirfd1,
                                 int arg2, int dirfd2)
{
    if (rewrite_path_arg(proc, arg1, dirfd1) < 0)
        return -1;
    if (rewrite_path_arg(proc, arg2, dirfd2) < 0)
        return -1;
    return 0;
}

/* ── Syscall Enter ──────────────────────────────────────────────────────── */

void syscall_handle_enter(pp_proc_t *proc)
{
    long sysno;
    arch_get_sysno(proc, &sysno);

    switch (sysno) {

    /* Single path (arg0), CWD-relative */
    case PP_SYS_chdir:
    case PP_SYS_execve:
    case PP_SYS_statfs:
    case PP_SYS_truncate:
        rewrite_path_arg(proc, 0, -1);
        break;

    /* *at variant: path is arg1, dirfd is arg0 */
    case PP_SYS_openat:
    case PP_SYS_faccessat:
    case PP_SYS_faccessat2:
    case PP_SYS_fchmodat:
    case PP_SYS_fchownat:
    case PP_SYS_mkdirat:
    case PP_SYS_unlinkat:
    case PP_SYS_readlinkat:
    case PP_SYS_newfstatat:
    case PP_SYS_utimensat:
    case PP_SYS_execveat:
        rewrite_path_arg(proc, 1, 0);
        break;

    /* Two-path *at variants */
    case PP_SYS_renameat:
    case PP_SYS_renameat2:
        rewrite_two_path_args(proc, 1, 0, 3, 2);
        break;

    case PP_SYS_linkat:
        rewrite_two_path_args(proc, 1, 0, 3, 2);
        break;

    /* symlinkat: target in arg0, newpath in arg2 (with dirfd in arg1) */
    case PP_SYS_symlinkat:
        rewrite_path_arg(proc, 0, -1);  /* target: absolute or CWD-relative */
        rewrite_path_arg(proc, 2, 1);   /* newpath: dirfd-relative */
        break;

    /* chroot: rewrite path, but handled on exit */
    case PP_SYS_chroot:
        rewrite_path_arg(proc, 0, -1);
        break;

#if defined(__x86_64__)
    /* Legacy x86-64 single-path syscalls */
    case PP_SYS_open:
    case PP_SYS_stat:
    case PP_SYS_lstat:
    case PP_SYS_access:
    case PP_SYS_mkdir:
    case PP_SYS_rmdir:
    case PP_SYS_unlink:
    case PP_SYS_readlink:
    case PP_SYS_chmod:
    case PP_SYS_chown:
    case PP_SYS_symlink:
        rewrite_path_arg(proc, 0, -1);
        break;

    /* Legacy x86-64 two-path syscalls */
    case PP_SYS_rename:
    case PP_SYS_link:
        rewrite_two_path_args(proc, 0, -1, 1, -1);
        break;
#endif

    default:
        break;
    }
}

/* ── Syscall Exit ───────────────────────────────────────────────────────── */

void syscall_handle_exit(pp_proc_t *proc)
{
    long sysno;
    arch_get_sysno(proc, &sysno);

    long retval;
    arch_get_retval(proc, (uint64_t *)&retval);

    switch (sysno) {

    case PP_SYS_chdir: {
        /*
         * Fix: Use path_normalize to properly resolve .. in CWD.
         * saved_arg[0] has the ORIGINAL guest path (captured at ENTER,
         * before our rewrite replaced the pointer with a scratch address).
         */
        if (retval == 0) {
            char guest_path[PP_MAX_PATH];
            if (mem_read_str(proc->pid, proc->saved_arg[0],
                             guest_path, sizeof(guest_path)) > 0) {
                /* Build new CWD */
                char new_cwd[PP_MAX_PATH];
                if (guest_path[0] == '/') {
                    snprintf(new_cwd, sizeof(new_cwd), "%s", guest_path);
                } else {
                    snprintf(new_cwd, sizeof(new_cwd), "%s/%s",
                             proc->cwd, guest_path);
                }
                path_normalize(new_cwd);
                snprintf(proc->cwd, sizeof(proc->cwd), "%s", new_cwd);
            }
        }
        break;
    }

    case PP_SYS_chroot: {
        /*
         * Fix: chroot is PER-PROCESS, not global.
         * Only updates the calling process's root.
         */
        if (retval == 0) {
            char guest_path[PP_MAX_PATH];
            if (mem_read_str(proc->pid, proc->saved_arg[0],
                             guest_path, sizeof(guest_path)) > 0) {
                /* Translate the chroot path using current root */
                char host_path[PP_MAX_PATH];
                if (path_translate(proc->root, proc->cwd, guest_path,
                                   host_path, sizeof(host_path)) == 0) {
                    snprintf(proc->root, sizeof(proc->root), "%s", host_path);
                }
            }
        }
        break;
    }

    case PP_SYS_getcwd: {
        if (retval > 0) {
            uint64_t buf_addr = proc->saved_arg[0];
            uint64_t buf_size = proc->saved_arg[1];

            char host_cwd[PP_MAX_PATH];
            if (mem_read_str(proc->pid, buf_addr, host_cwd,
                             sizeof(host_cwd)) > 0) {
                char guest_cwd[PP_MAX_PATH];
                if (path_detranslate(proc->root, g_pp.binds, g_pp.nbinds,
                                     host_cwd, guest_cwd,
                                     sizeof(guest_cwd)) == 0) {
                    size_t glen = strlen(guest_cwd);

                    if (glen < buf_size) {
                        mem_write_str(proc->pid, buf_addr, guest_cwd);
                        arch_set_retval(proc, (uint64_t)glen);
                    }
                    snprintf(proc->cwd, sizeof(proc->cwd), "%s", guest_cwd);
                }
            }
        }
        break;
    }

    case PP_SYS_readlinkat: {
        /*
         * Fix: De-translate symlink targets inside the root.
         * Also update return value to match de-translated length.
         * Clear leftover data if de-translated path is shorter.
         *
         * IMPORTANT: At EXIT, x0 = return value, NOT args.
         * saved_arg[1] = dirfd, saved_arg[2] = buf, saved_arg[3] = bufsiz
         */
        if (retval > 0) {
            uint64_t buf_addr = proc->saved_arg[2];
            uint64_t buf_size = proc->saved_arg[3];

            char host_lnk[PP_MAX_PATH];

            int nread = mem_read_str(proc->pid, buf_addr, host_lnk,
                                     sizeof(host_lnk));
            if (nread > 0) {
                char guest_lnk[PP_MAX_PATH];
                if (path_detranslate(proc->root, g_pp.binds, g_pp.nbinds,
                                     host_lnk, guest_lnk,
                                     sizeof(guest_lnk)) == 0) {
                    size_t glen = strlen(guest_lnk);

                    /* Only rewrite if it fits */
                    if (glen < buf_size) {
                        /* Clear the old data if new path is shorter */
                        if ((int)glen < (int)retval) {
                            char zeros[PP_MAX_PATH] = {0};
                            mem_write(proc->pid, buf_addr, zeros,
                                      (size_t)retval - glen);
                        }

                        /* Write the de-translated path */
                        mem_write_str(proc->pid, buf_addr, guest_lnk);
                        arch_set_retval(proc, (uint64_t)glen);
                    }
                }
            }
        }
        break;
    }

    default:
        break;
    }
}

/* ============================================================
 * PhantomSec proot — phantom-proot
 * A minimal user-space chroot emulator using ptrace.
 * Targets: Linux ARM64 (primary), x86-64 (secondary)
 * No root required.  No third-party proot code used.
 * ============================================================ */

#pragma once

#include <stdint.h>
#include <sys/types.h>

/* ── Limits ─────────────────────────────────────────────── */
#define PP_MAX_PATH      4096
#define PP_MAX_BINDS     64       /* max bind-mount entries   */
#define PP_MAX_TRACEES   256      /* max simultaneous procs   */
#define PP_SCRATCH_OFF   32768    /* bytes below SP for scratch (needs room for
                                  * multiple path rewrites: argno * PP_MAX_PATH.
                                  * renameat/linkat rewrite arg1 + arg3, so we
                                  * need at least 4 * 4096 = 16384.  Use 32 KB. */

/* ── Mount entry ────────────────────────────────────────── */
typedef struct {
    char host[PP_MAX_PATH];   /* real path on host        */
    char guest[PP_MAX_PATH];  /* path as seen inside proot */
} pp_bind_t;

/* ── Per-tracee state ───────────────────────────────────── */
typedef struct pp_tracee {
    pid_t   pid;
    int     in_syscall;       /* 1 = we are on syscall-enter */
    long    saved_sysno;      /* syscall number saved on enter */
    unsigned long saved_arg[6]; /* original syscall arguments */
    char    cwd[PP_MAX_PATH]; /* guest cwd (tracked manually) */
} pp_tracee_t;

/* ── Global proot state ─────────────────────────────────── */
typedef struct {
    char      root[PP_MAX_PATH];   /* fake root directory     */
    pp_bind_t binds[PP_MAX_BINDS]; /* bind mounts             */
    int       nbinds;
    pp_tracee_t tracees[PP_MAX_TRACEES];
    int         ntracees;
} pp_state_t;

extern pp_state_t g_pp;

/* ── Function prototypes ────────────────────────────────── */

/* arch.c */
int  arch_get_sysno(pid_t pid, long *sysno);
int  arch_get_args(pid_t pid, unsigned long args[6]);
int  arch_get_retval(pid_t pid, long *retval);
int  arch_set_arg(pid_t pid, int argno, unsigned long val);
int  arch_set_retval(pid_t pid, long val);
unsigned long arch_get_sp(pid_t pid);
int  arch_set_sysno(pid_t pid, long sysno);

/* path.c */
int  path_translate(const char *root, const char *cwd,
                    const char *guest, char *out, size_t outsz);
int  path_detranslate(const char *root, const char *host,
                      char *out, size_t outsz);

/* mount.c */
void mount_add(const char *host, const char *guest);
const pp_bind_t *mount_lookup(const char *guest_path);

/* tracee.c */
pp_tracee_t *tracee_find(pid_t pid);
pp_tracee_t *tracee_add(pid_t pid);
void         tracee_remove(pid_t pid);
void         tracee_event_loop(pid_t root_pid);

/* syscall.c */
void syscall_handle_enter(pp_tracee_t *t);
void syscall_handle_exit(pp_tracee_t *t);

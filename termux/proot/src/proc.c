/*
 * proc.c — Tracee lifecycle and main ptrace event loop
 *
 * Key improvements over old proot:
 * - PTRACE_SETOPTIONS called for ALL children (including !t fallback)
 * - CWD and root inherited properly on clone/fork/vfork
 * - Register cache: read once on ENTER, write once on EXIT
 * - Clean signal delivery
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/ptrace.h>
#include "proot.h"

#define PP_PTRACE_OPTIONS \
    (PTRACE_O_TRACESYSGOOD | PTRACE_O_TRACECLONE | \
     PTRACE_O_TRACEFORK | PTRACE_O_TRACEVFORK | \
     PTRACE_O_TRACEEXEC | PTRACE_O_EXITKILL)

/* ── Process table ──────────────────────────────────────────────────────── */

pp_proc_t *proc_find(pid_t pid)
{
    for (int i = 0; i < g_pp.nprocs; i++) {
        if (g_pp.procs[i].pid == pid)
            return &g_pp.procs[i];
    }
    return NULL;
}

pp_proc_t *proc_add(pid_t pid, const char *cwd, const char *root)
{
    if (g_pp.nprocs >= PP_MAX_TRACEES) {
        fprintf(stderr, "phantom-proot: too many tracees (max %d)\n",
                PP_MAX_TRACEES);
        return NULL;
    }

    pp_proc_t *p = &g_pp.procs[g_pp.nprocs];
    memset(p, 0, sizeof(*p));
    p->pid = pid;
    snprintf(p->cwd,  sizeof(p->cwd),  "%s", cwd  ? cwd  : "/");
    snprintf(p->root, sizeof(p->root), "%s", root ? root : g_pp.root);
    g_pp.nprocs++;

    return p;
}

void proc_remove(pid_t pid)
{
    for (int i = 0; i < g_pp.nprocs; i++) {
        if (g_pp.procs[i].pid == pid) {
            /* Swap with last */
            g_pp.procs[i] = g_pp.procs[g_pp.nprocs - 1];
            g_pp.nprocs--;
            return;
        }
    }
}

void proc_inherit(pp_proc_t *parent, pid_t child_pid)
{
    pp_proc_t *child = proc_add(child_pid, parent->cwd, parent->root);
    if (child && g_pp.verbose)
        fprintf(stderr, "  proc: inherited pid=%d cwd=%s root=%s\n",
                child_pid, parent->cwd, parent->root);
}

/* ── Event Loop ─────────────────────────────────────────────────────────── */

void proc_event_loop(pid_t root_pid)
{
    /* Add root process */
    pp_proc_t *root = proc_add(root_pid, "/", g_pp.root);
    if (!root) {
        fprintf(stderr, "phantom-proot: failed to add root process\n");
        return;
    }

    /* Wait for child's initial SIGSTOP */
    int status;
    waitpid(root_pid, &status, 0);

    if (!WIFSTOPPED(status)) {
        fprintf(stderr, "phantom-proot: child did not stop\n");
        return;
    }

    /* Set ptrace options on root process */
    ptrace(PTRACE_SETOPTIONS, root_pid, NULL, PP_PTRACE_OPTIONS);

    /* Start tracing */
    ptrace(PTRACE_SYSCALL, root_pid, NULL, NULL);

    /* Main loop */
    while (g_pp.nprocs > 0) {
        pid_t pid = waitpid(-1, &status, __WALL);
        if (pid < 0) {
            if (errno == ECHILD)
                break;
            continue;
        }

        pp_proc_t *proc = proc_find(pid);

        /* ── Process exited or signaled ─────────────────────────────── */
        if (WIFEXITED(status) || WIFSIGNALED(status)) {
            if (proc)
                proc_remove(pid);
            continue;
        }

        if (!WIFSTOPPED(status))
            continue;

        int sig = WSTOPSIG(status);

        /* ── New process discovered (not yet in table) ──────────────── */
        if (!proc) {
            /* Try to find parent for CWD/root inheritance */
            pp_proc_t *parent = NULL;
            for (int i = 0; i < g_pp.nprocs; i++) {
                /* Check if this pid could be a child */
                char stat_path[64];
                snprintf(stat_path, sizeof(stat_path),
                         "/proc/%d/stat", pid);
                FILE *f = fopen(stat_path, "r");
                if (f) {
                    int ppid = 0;
                    /* Read past comm field (may contain spaces/parens) */
                    char line[1024];
                    if (fgets(line, sizeof(line), f)) {
                        char *p = strrchr(line, ')');
                        if (p) {
                            p += 2; /* skip ') ' */
                            /* fields: state ppid ... */
                            sscanf(p, "%*c %d", &ppid);
                        }
                    }
                    fclose(f);
                    if (ppid > 0)
                        parent = proc_find(ppid);
                }
                if (parent)
                    break;
            }

            if (parent)
                proc_inherit(parent, pid);
            else
                proc_add(pid, "/", g_pp.root);

            proc = proc_find(pid);
            if (!proc) {
                /* Table full: detach this child */
                ptrace(PTRACE_DETACH, pid, NULL, NULL);
                continue;
            }

            /* CRITICAL: Set ptrace options on new child */
            ptrace(PTRACE_SETOPTIONS, pid, NULL, PP_PTRACE_OPTIONS);
        }

        /* ── PTRACE_EVENT_EXEC ──────────────────────────────────────── */
        if (status >> 16 == PTRACE_EVENT_EXEC) {
            /*
             * Do NOT reset in_syscall here!
             *
             * PTRACE_EVENT_EXEC is a SEPARATE stop from the syscall-exit-stop.
             * The kernel delivers: ENTER → PTRACE_EVENT_EXEC → EXIT (3 stops).
             * After ENTER, in_syscall=1. The EXIT stop will toggle it to 0.
             * If we reset in_syscall here, the EXIT stop is misinterpreted as ENTER.
             */
            ptrace(PTRACE_SYSCALL, pid, NULL, NULL);
            continue;
        }

        /* ── Clone/Fork/Vfork events ───────────────────────────────── */
        if (status >> 16 == PTRACE_EVENT_CLONE ||
            status >> 16 == PTRACE_EVENT_FORK ||
            status >> 16 == PTRACE_EVENT_VFORK) {
            unsigned long child_pid_l;
            ptrace(PTRACE_GETEVENTMSG, pid, NULL, &child_pid_l);
            pid_t child_pid = (pid_t)child_pid_l;

            /* Inherit parent's CWD and root */
            proc_inherit(proc, child_pid);

            pp_proc_t *child = proc_find(child_pid);
            if (child) {
                ptrace(PTRACE_SETOPTIONS, child_pid, NULL, PP_PTRACE_OPTIONS);
            }

            ptrace(PTRACE_SYSCALL, pid, NULL, NULL);
            continue;
        }

        /* ── Syscall stop (SIGTRAP|0x80) ──────────────────────────── */
        if (sig == (SIGTRAP | 0x80)) {
            /* Read registers fresh from kernel every time */
            if (arch_get_regs(pid, &proc->regs) < 0) {
                ptrace(PTRACE_SYSCALL, pid, NULL, NULL);
                continue;
            }
            proc->regs_dirty = 0;

            long cur_sysno;
            arch_get_sysno(proc, &cur_sysno);

            if (!proc->in_syscall) {
                /* ── ENTER ──────────────────────────────────────── */
                proc->in_syscall = 1;

                /* Save syscall number and args before rewrite */
                proc->saved_sysno = cur_sysno;

                uint64_t args[PP_MAX_ARGS];
                arch_get_args(proc, args);
                memcpy(proc->saved_arg, args, sizeof(args));

                /* Rewrite path arguments */
                syscall_handle_enter(proc);

            } else {
                /* ── EXIT ───────────────────────────────────────── */
                proc->in_syscall = 0;

                /* Handle exit-side syscalls */
                syscall_handle_exit(proc);
            }

            /* Write back registers if modified */
            if (proc->regs_dirty) {
                arch_set_regs(pid, &proc->regs);
            }

            ptrace(PTRACE_SYSCALL, pid, NULL, NULL);
            continue;
        }

        /* ── Other signals: pass through ────────────────────────────── */
        if (sig != SIGTRAP)
            ptrace(PTRACE_SYSCALL, pid, NULL, (void *)(long)sig);
        else
            ptrace(PTRACE_SYSCALL, pid, NULL, NULL);
    }
}

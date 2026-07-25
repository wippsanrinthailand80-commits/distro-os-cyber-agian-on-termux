/* tracee.c — Process tracking and the main ptrace event loop
 * PhantomSec phantom-proot
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>

#include "proot.h"

/* ── Tracee table ───────────────────────────────────────── */

pp_tracee_t *tracee_find(pid_t pid)
{
    for (int i = 0; i < g_pp.ntracees; i++)
        if (g_pp.tracees[i].pid == pid)
            return &g_pp.tracees[i];
    return NULL;
}

pp_tracee_t *tracee_add(pid_t pid)
{
    if (g_pp.ntracees >= PP_MAX_TRACEES) {
        fprintf(stderr, "[proot] tracee table full\n");
        return NULL;
    }
    pp_tracee_t *t = &g_pp.tracees[g_pp.ntracees++];
    memset(t, 0, sizeof(*t));
    t->pid = pid;
    t->in_syscall = 0;
    snprintf(t->cwd, sizeof(t->cwd), "/");
    return t;
}

void tracee_remove(pid_t pid)
{
    for (int i = 0; i < g_pp.ntracees; i++) {
        if (g_pp.tracees[i].pid == pid) {
            g_pp.tracees[i] = g_pp.tracees[--g_pp.ntracees];
            return;
        }
    }
}

/* ── ptrace options we set on every new tracee ─────────── */
#define PP_PTRACE_OPTS \
    (PTRACE_O_TRACESYSGOOD   /* syscall stops have bit 7 set in signal */ \
   | PTRACE_O_TRACECLONE     /* follow clone() */                          \
   | PTRACE_O_TRACEFORK      /* follow fork()  */                          \
   | PTRACE_O_TRACEVFORK     /* follow vfork() */                          \
   | PTRACE_O_TRACEEXEC      /* notify on execve */                        \
   | PTRACE_O_EXITKILL)      /* kill all tracees if tracer dies */

/* ── Main event loop ────────────────────────────────────── */
void tracee_event_loop(pid_t root_pid)
{
    /* Register the initial child */
    pp_tracee_t *root = tracee_add(root_pid);
    if (!root) {
        fprintf(stderr, "[proot] could not add root tracee\n");
        return;
    }

    /* Wait for the child's initial SIGSTOP (from PTRACE_TRACEME) */
    int wstatus;
    waitpid(root_pid, &wstatus, 0);
    ptrace(PTRACE_SETOPTIONS, root_pid, 0, (void *)PP_PTRACE_OPTS);
    ptrace(PTRACE_SYSCALL,    root_pid, 0, 0);

    while (g_pp.ntracees > 0) {
        pid_t pid = waitpid(-1, &wstatus, 0);
        if (pid <= 0) {
            if (errno == EINTR) continue;
            break;
        }

        pp_tracee_t *t = tracee_find(pid);

        /* ── New process created by clone/fork/vfork ── */
        if (!t) {
            t = tracee_add(pid);
            if (!t) {
                /* out of slots — detach */
                ptrace(PTRACE_DETACH, pid, 0, 0);
                continue;
            }
            /* Inherit cwd and root from parent (best effort) */
            /* Parent lookup: not trivially available here; use root "/" */
        }

        /* ── Process exited ── */
        if (WIFEXITED(wstatus) || WIFSIGNALED(wstatus)) {
            tracee_remove(pid);
            continue;
        }

        if (!WIFSTOPPED(wstatus)) {
            ptrace(PTRACE_SYSCALL, pid, 0, 0);
            continue;
        }

        int sig  = WSTOPSIG(wstatus);
        int event = (wstatus >> 16) & 0xff;  /* PTRACE_EVENT_* */

        /* ── exec event: reset cwd to "/" ── */
        if (event == PTRACE_EVENT_EXEC) {
            snprintf(t->cwd, sizeof(t->cwd), "/");
            t->in_syscall = 0;
            ptrace(PTRACE_SETOPTIONS, pid, 0, (void *)PP_PTRACE_OPTS);
            ptrace(PTRACE_SYSCALL,    pid, 0, 0);
            continue;
        }

        /* ── New child appeared via clone/fork ── */
        if (event == PTRACE_EVENT_CLONE ||
            event == PTRACE_EVENT_FORK  ||
            event == PTRACE_EVENT_VFORK) {
            unsigned long new_pid = 0;
            ptrace(PTRACE_GETEVENTMSG, pid, 0, &new_pid);
            if (new_pid && !tracee_find((pid_t)new_pid)) {
                pp_tracee_t *child = tracee_add((pid_t)new_pid);
                if (child) {
                    /* inherit parent's cwd */
                    snprintf(child->cwd, sizeof(child->cwd), "%s", t->cwd);
                }
            }
            ptrace(PTRACE_SYSCALL, pid, 0, 0);
            continue;
        }

        /* ── Syscall stop: bit 7 of sig is set when TRACESYSGOOD ── */
        if (sig == (SIGTRAP | 0x80)) {
            if (!t->in_syscall) {
                /* ENTER */
                t->in_syscall = 1;
                if (arch_get_sysno(pid, &t->saved_sysno) == 0 &&
                    arch_get_args(pid, t->saved_arg)      == 0) {
                    syscall_handle_enter(t);
                }
            } else {
                /* EXIT */
                t->in_syscall = 0;
                syscall_handle_exit(t);
            }
            ptrace(PTRACE_SYSCALL, pid, 0, 0);
            continue;
        }

        /* ── Other signal: pass it through to the tracee ── */
        int inject = (sig == SIGTRAP) ? 0 : sig;
        ptrace(PTRACE_SYSCALL, pid, 0, inject);
    }
}

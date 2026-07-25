/* arch.c — Architecture-specific ptrace register access
 * Supports ARM64 (primary) and x86-64.
 * PhantomSec phantom-proot
 */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/ptrace.h>
#include <sys/uio.h>
#include <elf.h>

#include "proot.h"

/* ── ARM64 ──────────────────────────────────────────────── */
#if defined(__aarch64__)

#include <asm/ptrace.h>   /* struct user_pt_regs */

/* ARM64 user_pt_regs layout:
 *   regs[0..30]  — x0..x30
 *   sp           — stack pointer
 *   pc           — program counter
 *   pstate       — processor state
 *
 * On syscall entry:
 *   x8   (regs[8])  = syscall number
 *   x0-x5           = arg0..arg5
 * On syscall exit:
 *   x0   (regs[0])  = return value
 */

static int arm64_getregs(pid_t pid, struct user_pt_regs *regs)
{
    struct iovec iov = { regs, sizeof(*regs) };
    if (ptrace(PTRACE_GETREGSET, pid, (void *)NT_PRSTATUS, &iov) < 0) {
        perror("PTRACE_GETREGSET");
        return -1;
    }
    return 0;
}

static int arm64_setregs(pid_t pid, struct user_pt_regs *regs)
{
    struct iovec iov = { regs, sizeof(*regs) };
    if (ptrace(PTRACE_SETREGSET, pid, (void *)NT_PRSTATUS, &iov) < 0) {
        perror("PTRACE_SETREGSET");
        return -1;
    }
    return 0;
}

int arch_get_sysno(pid_t pid, long *sysno)
{
    struct user_pt_regs regs;
    if (arm64_getregs(pid, &regs) < 0) return -1;
    *sysno = (long)regs.regs[8];
    return 0;
}

int arch_get_args(pid_t pid, unsigned long args[6])
{
    struct user_pt_regs regs;
    if (arm64_getregs(pid, &regs) < 0) return -1;
    for (int i = 0; i < 6; i++)
        args[i] = (unsigned long)regs.regs[i];
    return 0;
}

int arch_get_retval(pid_t pid, long *retval)
{
    struct user_pt_regs regs;
    if (arm64_getregs(pid, &regs) < 0) return -1;
    *retval = (long)regs.regs[0];
    return 0;
}

int arch_set_arg(pid_t pid, int argno, unsigned long val)
{
    struct user_pt_regs regs;
    if (arm64_getregs(pid, &regs) < 0) return -1;
    regs.regs[argno] = val;
    return arm64_setregs(pid, &regs);
}

int arch_set_retval(pid_t pid, long val)
{
    struct user_pt_regs regs;
    if (arm64_getregs(pid, &regs) < 0) return -1;
    regs.regs[0] = (unsigned long)val;
    return arm64_setregs(pid, &regs);
}

unsigned long arch_get_sp(pid_t pid)
{
    struct user_pt_regs regs;
    if (arm64_getregs(pid, &regs) < 0) return 0;
    return (unsigned long)regs.sp;
}

int arch_set_sysno(pid_t pid, long sysno)
{
    struct user_pt_regs regs;
    if (arm64_getregs(pid, &regs) < 0) return -1;
    regs.regs[8] = (unsigned long)sysno;
    return arm64_setregs(pid, &regs);
}

/* ── x86-64 ─────────────────────────────────────────────── */
#elif defined(__x86_64__)

#include <sys/user.h>    /* struct user_regs_struct */

/* x86-64 syscall convention:
 *   orig_rax = syscall number
 *   rdi, rsi, rdx, r10, r8, r9 = arg0..arg5
 *   rax = return value
 */

static int x64_getregs(pid_t pid, struct user_regs_struct *regs)
{
    if (ptrace(PTRACE_GETREGS, pid, NULL, regs) < 0) {
        perror("PTRACE_GETREGS");
        return -1;
    }
    return 0;
}

static int x64_setregs(pid_t pid, struct user_regs_struct *regs)
{
    if (ptrace(PTRACE_SETREGS, pid, NULL, regs) < 0) {
        perror("PTRACE_SETREGS");
        return -1;
    }
    return 0;
}

int arch_get_sysno(pid_t pid, long *sysno)
{
    struct user_regs_struct regs;
    if (x64_getregs(pid, &regs) < 0) return -1;
    *sysno = (long)regs.orig_rax;
    return 0;
}

int arch_get_args(pid_t pid, unsigned long args[6])
{
    struct user_regs_struct regs;
    if (x64_getregs(pid, &regs) < 0) return -1;
    args[0] = regs.rdi;
    args[1] = regs.rsi;
    args[2] = regs.rdx;
    args[3] = regs.r10;
    args[4] = regs.r8;
    args[5] = regs.r9;
    return 0;
}

int arch_get_retval(pid_t pid, long *retval)
{
    struct user_regs_struct regs;
    if (x64_getregs(pid, &regs) < 0) return -1;
    *retval = (long)regs.rax;
    return 0;
}

int arch_set_arg(pid_t pid, int argno, unsigned long val)
{
    struct user_regs_struct regs;
    if (x64_getregs(pid, &regs) < 0) return -1;
    switch (argno) {
    case 0: regs.rdi = val; break;
    case 1: regs.rsi = val; break;
    case 2: regs.rdx = val; break;
    case 3: regs.r10 = val; break;
    case 4: regs.r8  = val; break;
    case 5: regs.r9  = val; break;
    }
    return x64_setregs(pid, &regs);
}

int arch_set_retval(pid_t pid, long val)
{
    struct user_regs_struct regs;
    if (x64_getregs(pid, &regs) < 0) return -1;
    regs.rax = (unsigned long long)val;
    return x64_setregs(pid, &regs);
}

unsigned long arch_get_sp(pid_t pid)
{
    struct user_regs_struct regs;
    if (x64_getregs(pid, &regs) < 0) return 0;
    return (unsigned long)regs.rsp;
}

int arch_set_sysno(pid_t pid, long sysno)
{
    struct user_regs_struct regs;
    if (x64_getregs(pid, &regs) < 0) return -1;
    regs.orig_rax = (unsigned long long)sysno;
    return x64_setregs(pid, &regs);
}

#else
#error "Unsupported architecture — only ARM64 and x86-64 are supported"
#endif

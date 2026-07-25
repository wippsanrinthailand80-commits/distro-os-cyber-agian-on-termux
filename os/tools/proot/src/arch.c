/* arch.c — Architecture-specific ptrace register access
 * Supports ARM64 (primary) and x86-64.
 * PhantomSec phantom-proot
 *
 * Structs are defined locally so the file compiles without
 * kernel headers (important for Termux / Android NDK).
 */

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <sys/ptrace.h>
#include <sys/uio.h>

#include "proot.h"

/* NT_PRSTATUS — ELF note type, value = 1 on all Linux arches */
#ifndef NT_PRSTATUS
#  define NT_PRSTATUS 1
#endif

/* ── ARM64 ──────────────────────────────────────────────── */
#if defined(__aarch64__)

/*
 * user_pt_regs as defined in Linux arch/arm64/include/uapi/asm/ptrace.h
 * Redefined here so we don't need kernel headers.
 *
 * Layout:
 *   regs[0..30]  x0..x30
 *   sp           stack pointer
 *   pc           program counter
 *   pstate       processor state
 *
 * On syscall entry:  x8 (regs[8]) = syscall number
 *                    x0-x5        = arg0..arg5
 * On syscall exit:   x0 (regs[0]) = return value
 */
struct pp_user_pt_regs {
    uint64_t regs[31];
    uint64_t sp;
    uint64_t pc;
    uint64_t pstate;
};

static int arm64_getregs(pid_t pid, struct pp_user_pt_regs *r)
{
    struct iovec iov = { r, sizeof(*r) };
    memset(r, 0, sizeof(*r));
    if (ptrace(PTRACE_GETREGSET, pid, (void *)(long)NT_PRSTATUS, &iov) < 0) {
        perror("PTRACE_GETREGSET");
        return -1;
    }
    return 0;
}

static int arm64_setregs(pid_t pid, struct pp_user_pt_regs *r)
{
    struct iovec iov = { r, sizeof(*r) };
    if (ptrace(PTRACE_SETREGSET, pid, (void *)(long)NT_PRSTATUS, &iov) < 0) {
        perror("PTRACE_SETREGSET");
        return -1;
    }
    return 0;
}

int arch_get_sysno(pid_t pid, long *sysno)
{
    struct pp_user_pt_regs r;
    if (arm64_getregs(pid, &r) < 0) return -1;
    *sysno = (long)r.regs[8];
    return 0;
}

int arch_get_args(pid_t pid, unsigned long args[6])
{
    struct pp_user_pt_regs r;
    if (arm64_getregs(pid, &r) < 0) return -1;
    for (int i = 0; i < 6; i++)
        args[i] = (unsigned long)r.regs[i];
    return 0;
}

int arch_get_retval(pid_t pid, long *retval)
{
    struct pp_user_pt_regs r;
    if (arm64_getregs(pid, &r) < 0) return -1;
    *retval = (long)r.regs[0];
    return 0;
}

int arch_set_arg(pid_t pid, int argno, unsigned long val)
{
    struct pp_user_pt_regs r;
    if (arm64_getregs(pid, &r) < 0) return -1;
    r.regs[argno] = (uint64_t)val;
    return arm64_setregs(pid, &r);
}

int arch_set_retval(pid_t pid, long val)
{
    struct pp_user_pt_regs r;
    if (arm64_getregs(pid, &r) < 0) return -1;
    r.regs[0] = (uint64_t)val;
    return arm64_setregs(pid, &r);
}

unsigned long arch_get_sp(pid_t pid)
{
    struct pp_user_pt_regs r;
    if (arm64_getregs(pid, &r) < 0) return 0;
    return (unsigned long)r.sp;
}

int arch_set_sysno(pid_t pid, long sysno)
{
    struct pp_user_pt_regs r;
    if (arm64_getregs(pid, &r) < 0) return -1;
    r.regs[8] = (uint64_t)sysno;
    return arm64_setregs(pid, &r);
}

/* ── x86-64 ─────────────────────────────────────────────── */
#elif defined(__x86_64__)

/*
 * user_regs_struct as in Linux arch/x86/include/uapi/asm/user_64.h
 * Redefined here so we don't need sys/user.h.
 *
 * On syscall entry:  orig_rax = syscall number
 *                    rdi, rsi, rdx, r10, r8, r9 = arg0..arg5
 * On syscall exit:   rax = return value
 */
struct pp_user_regs_struct {
    uint64_t r15, r14, r13, r12, rbp, rbx;
    uint64_t r11, r10, r9, r8;
    uint64_t rax, rcx, rdx, rsi, rdi;
    uint64_t orig_rax;
    uint64_t rip, cs, eflags, rsp, ss;
    uint64_t fs_base, gs_base, ds, es, fs, gs;
};

static int x64_getregs(pid_t pid, struct pp_user_regs_struct *r)
{
    if (ptrace(PTRACE_GETREGS, pid, NULL, r) < 0) {
        perror("PTRACE_GETREGS");
        return -1;
    }
    return 0;
}

static int x64_setregs(pid_t pid, struct pp_user_regs_struct *r)
{
    if (ptrace(PTRACE_SETREGS, pid, NULL, r) < 0) {
        perror("PTRACE_SETREGS");
        return -1;
    }
    return 0;
}

int arch_get_sysno(pid_t pid, long *sysno)
{
    struct pp_user_regs_struct r;
    if (x64_getregs(pid, &r) < 0) return -1;
    *sysno = (long)r.orig_rax;
    return 0;
}

int arch_get_args(pid_t pid, unsigned long args[6])
{
    struct pp_user_regs_struct r;
    if (x64_getregs(pid, &r) < 0) return -1;
    args[0] = r.rdi;
    args[1] = r.rsi;
    args[2] = r.rdx;
    args[3] = r.r10;
    args[4] = r.r8;
    args[5] = r.r9;
    return 0;
}

int arch_get_retval(pid_t pid, long *retval)
{
    struct pp_user_regs_struct r;
    if (x64_getregs(pid, &r) < 0) return -1;
    *retval = (long)r.rax;
    return 0;
}

int arch_set_arg(pid_t pid, int argno, unsigned long val)
{
    struct pp_user_regs_struct r;
    if (x64_getregs(pid, &r) < 0) return -1;
    switch (argno) {
    case 0: r.rdi = val; break;
    case 1: r.rsi = val; break;
    case 2: r.rdx = val; break;
    case 3: r.r10 = val; break;
    case 4: r.r8  = val; break;
    case 5: r.r9  = val; break;
    }
    return x64_setregs(pid, &r);
}

int arch_set_retval(pid_t pid, long val)
{
    struct pp_user_regs_struct r;
    if (x64_getregs(pid, &r) < 0) return -1;
    r.rax = (uint64_t)val;
    return x64_setregs(pid, &r);
}

unsigned long arch_get_sp(pid_t pid)
{
    struct pp_user_regs_struct r;
    if (x64_getregs(pid, &r) < 0) return 0;
    return (unsigned long)r.rsp;
}

int arch_set_sysno(pid_t pid, long sysno)
{
    struct pp_user_regs_struct r;
    if (x64_getregs(pid, &r) < 0) return -1;
    r.orig_rax = (uint64_t)sysno;
    return x64_setregs(pid, &r);
}

#else
#error "Unsupported architecture — only ARM64 and x86-64 are supported"
#endif

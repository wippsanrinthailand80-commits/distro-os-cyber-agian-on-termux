/*
 * arch.c — Architecture-specific register manipulation
 *
 * Key improvement: register cache. Each tracee stores its register state
 * in pp_proc_t.regs. We read once per syscall event, modify in-memory,
 * and write back only if regs_dirty is set.
 */

#include <stdio.h>
#include <string.h>
#include <sys/ptrace.h>
#include <sys/uio.h>
#include <elf.h>
#include "proot.h"

/* ── aarch64 ────────────────────────────────────────────────────────────── */

#if defined(__aarch64__)

int arch_get_regs(pid_t pid, pp_regs_t *regs)
{
    struct iovec iov = { regs, sizeof(*regs) };
    memset(regs, 0, sizeof(*regs));
    if (ptrace(PTRACE_GETREGSET, pid, NT_PRSTATUS, &iov) < 0)
        return -1;
    return 0;
}

int arch_set_regs(pid_t pid, const pp_regs_t *regs)
{
    struct iovec iov = { (void *)regs, sizeof(*regs) };
    if (ptrace(PTRACE_SETREGSET, pid, NT_PRSTATUS, &iov) < 0)
        return -1;
    return 0;
}

int arch_get_sysno(const pp_proc_t *proc, long *sysno)
{
    *sysno = (long)proc->regs.regs[PP_REG_SYSNO];
    return 0;
}

int arch_get_args(const pp_proc_t *proc, uint64_t args[PP_MAX_ARGS])
{
    for (int i = 0; i < PP_MAX_ARGS; i++)
        args[i] = proc->regs.regs[i];
    return 0;
}

int arch_get_retval(const pp_proc_t *proc, uint64_t *val)
{
    *val = proc->regs.regs[PP_REG_RETVAL];
    return 0;
}

int arch_set_arg(pp_proc_t *proc, int argno, uint64_t val)
{
    if (argno < 0 || argno >= 31)
        return -1;
    proc->regs.regs[argno] = val;
    proc->regs_dirty = 1;
    return 0;
}

int arch_set_retval(pp_proc_t *proc, uint64_t val)
{
    proc->regs.regs[PP_REG_RETVAL] = val;
    proc->regs_dirty = 1;
    return 0;
}

uint64_t arch_get_sp(const pp_proc_t *proc)
{
    return proc->regs.sp;
}

/* ── x86-64 ─────────────────────────────────────────────────────────────── */

#elif defined(__x86_64__)

int arch_get_regs(pid_t pid, pp_regs_t *regs)
{
    memset(regs, 0, sizeof(*regs));
    if (ptrace(PTRACE_GETREGS, pid, NULL, regs) < 0)
        return -1;
    return 0;
}

int arch_set_regs(pid_t pid, const pp_regs_t *regs)
{
    if (ptrace(PTRACE_SETREGS, pid, NULL, regs) < 0)
        return -1;
    return 0;
}

int arch_get_sysno(const pp_proc_t *proc, long *sysno)
{
    *sysno = (long)proc->regs.orig_rax;
    return 0;
}

int arch_get_args(const pp_proc_t *proc, uint64_t args[PP_MAX_ARGS])
{
    args[0] = proc->regs.rdi;
    args[1] = proc->regs.rsi;
    args[2] = proc->regs.rdx;
    args[3] = proc->regs.r10;
    args[4] = proc->regs.r8;
    args[5] = proc->regs.r9;
    return 0;
}

int arch_get_retval(const pp_proc_t *proc, uint64_t *val)
{
    *val = proc->regs.rax;
    return 0;
}

int arch_set_arg(pp_proc_t *proc, int argno, uint64_t val)
{
    switch (argno) {
    case 0: proc->regs.rdi = val; break;
    case 1: proc->regs.rsi = val; break;
    case 2: proc->regs.rdx = val; break;
    case 3: proc->regs.r10 = val; break;
    case 4: proc->regs.r8  = val; break;
    case 5: proc->regs.r9  = val; break;
    default: return -1;
    }
    proc->regs_dirty = 1;
    return 0;
}

int arch_set_retval(pp_proc_t *proc, uint64_t val)
{
    proc->regs.rax = val;
    proc->regs_dirty = 1;
    return 0;
}

uint64_t arch_get_sp(const pp_proc_t *proc)
{
    return proc->regs.rsp;
}

#endif

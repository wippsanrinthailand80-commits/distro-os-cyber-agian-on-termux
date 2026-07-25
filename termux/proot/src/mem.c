/*
 * mem.c — Safe ptrace memory read/write
 *
 * All operations are word-aligned (8 bytes on 64-bit) with proper
 * handling for unaligned tails via read-modify-write.
 */

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <sys/ptrace.h>
#include "proot.h"

#define WORD_SIZE sizeof(uint64_t)

int mem_read(pid_t pid, uint64_t addr, void *buf, size_t len)
{
    uint64_t *dst = (uint64_t *)buf;
    size_t nwords = len / WORD_SIZE;
    size_t tail   = len % WORD_SIZE;

    /* Read full words */
    errno = 0;
    for (size_t i = 0; i < nwords; i++) {
        long val = ptrace(PTRACE_PEEKDATA, pid, addr + i * WORD_SIZE, NULL);
        if (val == -1 && errno != 0)
            return -1;
        dst[i] = (uint64_t)val;
    }

    /* Read partial tail word if needed */
    if (tail > 0) {
        long val = ptrace(PTRACE_PEEKDATA, pid, addr + nwords * WORD_SIZE, NULL);
        if (val == -1 && errno != 0)
            return -1;
        memcpy((char *)dst + nwords * WORD_SIZE, &val, tail);
    }

    return 0;
}

int mem_write(pid_t pid, uint64_t addr, const void *buf, size_t len)
{
    const uint64_t *src = (const uint64_t *)buf;
    size_t nwords = len / WORD_SIZE;
    size_t tail   = len % WORD_SIZE;

    /* Write full words */
    for (size_t i = 0; i < nwords; i++) {
        if (ptrace(PTRACE_POKEDATA, pid, addr + i * WORD_SIZE, src[i]) == -1)
            return -1;
    }

    /* Read-modify-write partial tail */
    if (tail > 0) {
        errno = 0;
        long old = ptrace(PTRACE_PEEKDATA, pid, addr + nwords * WORD_SIZE, NULL);
        if (old == -1 && errno != 0)
            return -1;
        memcpy(&old, (const char *)src + nwords * WORD_SIZE, tail);
        if (ptrace(PTRACE_POKEDATA, pid, addr + nwords * WORD_SIZE, old) == -1)
            return -1;
    }

    return 0;
}

int mem_read_str(pid_t pid, uint64_t addr, char *buf, size_t bufsz)
{
    if (bufsz == 0)
        return -1;

    size_t total = 0;
    uint64_t word;

    while (total + WORD_SIZE <= bufsz) {
        if (mem_read(pid, addr + total, &word, WORD_SIZE) < 0)
            return -1;

        for (size_t i = 0; i < WORD_SIZE && total < bufsz; i++, total++) {
            buf[total] = ((const char *)&word)[i];
            if (buf[total] == '\0')
                return (int)total;
        }
    }

    /* Last partial word */
    if (total < bufsz) {
        if (mem_read(pid, addr + total, &word, 1) < 0)
            return -1;
        buf[total] = ((const char *)&word)[0];
        if (buf[total] == '\0')
            return (int)total;
        total++;
    }

    buf[bufsz - 1] = '\0';
    return (int)total;
}

int mem_write_str(pid_t pid, uint64_t addr, const char *str)
{
    size_t len = strlen(str) + 1; /* include NUL */
    return mem_write(pid, addr, str, len);
}

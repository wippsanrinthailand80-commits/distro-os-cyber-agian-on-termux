/*
 * SyscallDNA — Markov-Chain Behavioral Fingerprinter
 * PhantomSec OS v2.5.4 | Written in C
 *
 * UNIQUE TOOL: No existing open-source tool builds Markov chain transition
 * matrices from live ptrace syscall traces to fingerprint process behavior.
 * This is fundamentally different from strace (which just logs) or seccomp
 * (which filters). SyscallDNA creates a mathematical "DNA" signature of how
 * a process behaves over time and detects anomalies by comparing against a
 * known-clean baseline profile.
 *
 * Algorithm:
 *   1. Attach to target PID via ptrace
 *   2. Capture N consecutive syscall numbers (the "sequence")
 *   3. Build a Markov transition matrix M where M[a][b] = P(syscall b | prev syscall a)
 *   4. Compute a compact "DNA string" (top-N transitions hashed)
 *   5. Compare to saved baseline: similarity = 1 - KL_divergence(A, B)
 *   6. Anomaly if similarity < threshold
 *
 * Build: gcc -O2 -o scdna scdna.c -lm
 * Run:   sudo ./scdna -p 1234 -n 5000
 *        ./scdna -p 1234 --save-profile /etc/phantomsec/profiles/sshd.dna
 *        ./scdna -p 1234 --compare /etc/phantomsec/profiles/sshd.dna
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <math.h>
#include <signal.h>
#include <time.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <sys/user.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/uio.h>
#include <syscall.h>

#include "../../i18n/i18n.h"

/* Architecture-specific ptrace register access */
#if defined(__aarch64__)
#include <asm/ptrace.h>
typedef struct user_pt_regs scdna_regs_t;
static inline long get_syscall_nr(pid_t pid, scdna_regs_t *regs) {
    struct iovec io = { .iov_base = regs, .iov_len = sizeof(*regs) };
    if (ptrace(PTRACE_GETREGSET, pid, (void *)1, &io) < 0) return -1;
    return (long)regs->regs[8]; /* aarch64: syscall number in x8 */
}
#elif defined(__x86_64__)
typedef struct user_regs_struct scdna_regs_t;
static inline long get_syscall_nr(pid_t pid, scdna_regs_t *regs) {
    if (ptrace(PTRACE_GETREGS, pid, NULL, regs) < 0) return -1;
    return (long)regs->orig_rax;
}
#elif defined(__i386__)
typedef struct user_regs_struct scdna_regs_t;
static inline long get_syscall_nr(pid_t pid, scdna_regs_t *regs) {
    if (ptrace(PTRACE_GETREGS, pid, NULL, regs) < 0) return -1;
    return (long)regs->orig_eax;
}
#else
#error "Unsupported architecture for scdna"
#endif

#define SYSCALL_MAX       512
#define DEFAULT_CAPTURE   5000   /* default syscalls to capture */
#define ANOMALY_THRESHOLD 0.70   /* similarity below this = anomaly */
#define DNA_VERSION       2

/* Markov transition matrix: float M[from][to] */
typedef float markov_t[SYSCALL_MAX][SYSCALL_MAX];

/* Compact profile stored on disk */
typedef struct {
    uint32_t magic;      /* 0x444E4150 = "DNAPH" */
    uint32_t version;
    uint64_t syscall_count;
    uint32_t unique_syscalls;
    char     procname[256];
    float    matrix[SYSCALL_MAX][SYSCALL_MAX]; /* transition probabilities */
} dna_profile_t;

#define PROFILE_MAGIC 0x444E4150U

static volatile int g_stop = 0;
static void handle_sigint(int sig) { (void)sig; g_stop = 1; }

/* Linux syscall names (x86-64, first 350) */
static const char *SYSCALL_NAMES[SYSCALL_MAX] = {
    "read","write","open","close","stat","fstat","lstat","poll","lseek",
    "mmap","mprotect","munmap","brk","rt_sigaction","rt_sigprocmask",
    "rt_sigreturn","ioctl","pread64","pwrite64","readv","writev","access",
    "pipe","select","sched_yield","mremap","msync","mincore","madvise",
    "shmget","shmat","shmctl","dup","dup2","pause","nanosleep","getitimer",
    "alarm","setitimer","getpid","sendfile","socket","connect","accept",
    "sendto","recvfrom","sendmsg","recvmsg","shutdown","bind","listen",
    "getsockname","getpeername","socketpair","setsockopt","getsockopt",
    "clone","fork","vfork","execve","exit","wait4","kill","uname","semget",
    "semop","semctl","shmdt","msgget","msgsnd","msgrcv","msgctl","fcntl",
    "flock","fsync","fdatasync","truncate","ftruncate","getdents","getcwd",
    "chdir","fchdir","rename","mkdir","rmdir","creat","link","unlink",
    "symlink","readlink","chmod","fchmod","chown","fchown","lchown","umask",
    "gettimeofday","getrlimit","getrusage","sysinfo","times","ptrace",
    "getuid","syslog","getgid","setuid","setgid","geteuid","getegid",
    "setpgid","getppid","getpgrp","setsid","setreuid","setregid",
    "getgroups","setgroups","setresuid","getresuid","setresgid","getresgid",
    "getpgid","setfsuid","setfsgid","getsid","capget","capset","rt_sigpending",
    "rt_sigtimedwait","rt_sigqueueinfo","rt_sigsuspend","sigaltstack",
    "utime","mknod","uselib","personality","ustat","statfs","fstatfs",
    "sysfs","getpriority","setpriority","sched_setparam","sched_getparam",
    "sched_setscheduler","sched_getscheduler","sched_get_priority_max",
    "sched_get_priority_min","sched_rr_get_interval","mlock","munlock",
    "mlockall","munlockall","vhangup","modify_ldt","pivot_root","_sysctl",
    "prctl","arch_prctl","adjtimex","setrlimit","chroot","sync","acct",
    "settimeofday","mount","umount2","swapon","swapoff","reboot","sethostname",
    "setdomainname","iopl","ioperm","create_module","init_module",
    "delete_module","get_kernel_syms","query_module","quotactl","nfsservctl",
    "getpmsg","putpmsg","afs_syscall","tuxcall","security","gettid",
    "readahead","setxattr","lsetxattr","fsetxattr","getxattr","lgetxattr",
    "fgetxattr","listxattr","llistxattr","flistxattr","removexattr",
    "lremovexattr","fremovexattr","tkill","time","futex","sched_setaffinity",
    "sched_getaffinity","set_thread_area","io_setup","io_destroy","io_getevents",
    "io_submit","io_cancel","get_thread_area","lookup_dcookie","epoll_create",
    "epoll_ctl_old","epoll_wait_old","remap_file_pages","getdents64",
    "set_tid_address","restart_syscall","semtimedop","fadvise64","timer_create",
    "timer_settime","timer_gettime","timer_getoverrun","timer_delete",
    "clock_settime","clock_gettime","clock_getres","clock_nanosleep",
    "exit_group","epoll_wait","epoll_ctl","tgkill","utimes","vserver",
    "mbind","set_mempolicy","get_mempolicy","mq_open","mq_unlink",
    "mq_timedsend","mq_timedreceive","mq_notify","mq_getsetattr",
    "kexec_load","waitid","add_key","request_key","keyctl","ioprio_set",
    "ioprio_get","inotify_init","inotify_add_watch","inotify_rm_watch",
    "migrate_pages","openat","mkdirat","mknodat","fchownat","futimesat",
    "newfstatat","unlinkat","renameat","linkat","symlinkat","readlinkat",
    "fchmodat","faccessat","pselect6","ppoll","unshare","set_robust_list",
    "get_robust_list","splice","tee","sync_file_range","vmsplice",
    "move_pages","utimensat","epoll_pwait","signalfd","timerfd_create",
    "eventfd","fallocate","timerfd_settime","timerfd_gettime","accept4",
    "signalfd4","eventfd2","epoll_create1","dup3","pipe2","inotify_init1",
    "preadv","pwritev","rt_tgsigqueueinfo","perf_event_open","recvmmsg",
    "fanotify_init","fanotify_mark","prlimit64","name_to_handle_at",
    "open_by_handle_at","clock_adjtime","syncfs","sendmmsg","setns",
    "getcpu","process_vm_readv","process_vm_writev","kcmp","finit_module",
    "sched_setattr","sched_getattr","renameat2","seccomp","getrandom",
    "memfd_create","kexec_file_load","bpf","execveat","userfaultfd",
    "membarrier","mlock2","copy_file_range","preadv2","pwritev2",
    "pkey_mprotect","pkey_alloc","pkey_free","statx","io_pgetevents",
    "rseq", /* 334 */
};

static const char *syscall_name(long nr) {
    if (nr >= 0 && nr < SYSCALL_MAX && SYSCALL_NAMES[nr]) return SYSCALL_NAMES[nr];
    static char buf[32];
    snprintf(buf, sizeof(buf), "syscall_%ld", nr);
    return buf;
}

/* KL divergence between two probability distributions */
static double kl_divergence(const float *P, const float *Q, int n) {
    double kl = 0.0;
    for (int i = 0; i < n; i++) {
        if (P[i] > 1e-9 && Q[i] > 1e-9)
            kl += P[i] * log2((double)P[i] / (double)Q[i]);
    }
    return kl;
}

/* Matrix similarity: symmetric KL divergence normalized to [0,1] */
static double matrix_similarity(const dna_profile_t *A, const dna_profile_t *B) {
    double total_kl = 0.0;
    int n_rows = 0;
    for (int i = 0; i < SYSCALL_MAX; i++) {
        double row_kl = kl_divergence(A->matrix[i], B->matrix[i], SYSCALL_MAX) +
                        kl_divergence(B->matrix[i], A->matrix[i], SYSCALL_MAX);
        if (row_kl > 0.0) { total_kl += row_kl; n_rows++; }
    }
    if (n_rows == 0) return 1.0;
    double avg_kl = total_kl / n_rows;
    /* Map divergence to similarity: similarity = exp(-kl/2) */
    double sim = exp(-avg_kl / 2.0);
    return (sim > 1.0) ? 1.0 : sim;
}

static void build_profile(const uint64_t *counts, long last_syscall,
                          dna_profile_t *profile) {
    /* Normalize rows to probabilities */
    for (int from = 0; from < SYSCALL_MAX; from++) {
        double row_total = 0.0;
        for (int to = 0; to < SYSCALL_MAX; to++)
            row_total += profile->matrix[from][to];
        if (row_total > 0.0) {
            for (int to = 0; to < SYSCALL_MAX; to++)
                profile->matrix[from][to] /= (float)row_total;
        }
    }
    (void)counts; (void)last_syscall;
}

static void print_top_transitions(const dna_profile_t *profile, int top_n) {
    typedef struct { int from; int to; float prob; } entry_t;
    entry_t *entries = calloc(SYSCALL_MAX * SYSCALL_MAX, sizeof(entry_t));
    if (!entries) return;

    int ne = 0;
    for (int f = 0; f < SYSCALL_MAX; f++)
        for (int t = 0; t < SYSCALL_MAX; t++)
            if (profile->matrix[f][t] > 1e-6)
                entries[ne++] = (entry_t){f, t, profile->matrix[f][t]};

    /* Sort by probability descending (simple selection for top_n) */
    for (int i = 0; i < top_n && i < ne; i++) {
        int max_j = i;
        for (int j = i+1; j < ne; j++)
            if (entries[j].prob > entries[max_j].prob) max_j = j;
        if (max_j != i) { entry_t tmp = entries[i]; entries[i] = entries[max_j]; entries[max_j] = tmp; }
    }

    printf(PS_BOLD " %s (top %d):\n" PS_RESET, SD_TOP_TRANSITIONS, top_n);
    for (int i = 0; i < top_n && i < ne; i++) {
        printf("   " PS_CYAN "%-22s" PS_RESET " → " PS_GREEN "%-22s" PS_RESET "  %.4f\n",
               syscall_name(entries[i].from),
               syscall_name(entries[i].to),
               entries[i].prob);
    }
    free(entries);
}

static void print_usage(const char *prog) {
    printf(PS_BOLD "%s:" PS_RESET " %s [options]\n\n", I18N_USAGE, prog);
    printf(PS_BOLD "%s:\n" PS_RESET, I18N_OPTIONS);
    printf("  -p <pid>            Target PID to fingerprint\n");
    printf("  -n <count>          Syscalls to capture (default: %d)\n", DEFAULT_CAPTURE);
    printf("  -s <file>           Save DNA profile to file\n");
    printf("  -c <file>           Compare against saved profile\n");
    printf("  -T <threshold>      Anomaly threshold (default: %.2f)\n", ANOMALY_THRESHOLD);
    printf("  -h                  Show help\n\n");
    printf(PS_BOLD "%s:\n" PS_RESET, I18N_EXAMPLE);
    printf("  sudo %s -p 1234\n", prog);
    printf("  sudo %s -p 1234 -s /etc/phantomsec/sshd.dna\n", prog);
    printf("  sudo %s -p 5678 -c /etc/phantomsec/sshd.dna\n\n", prog);
}

int main(int argc, char *argv[]) {
    ps_lang_init();

    pid_t  target_pid = -1;
    int    n_capture  = DEFAULT_CAPTURE;
    char   save_file[256] = {0};
    char   cmp_file[256]  = {0};
    double threshold = ANOMALY_THRESHOLD;

    int opt;
    while ((opt = getopt(argc, argv, "p:n:s:c:T:h")) != -1) {
        switch (opt) {
            case 'p': target_pid = (pid_t)atoi(optarg); break;
            case 'n': n_capture  = atoi(optarg); break;
            case 's': strncpy(save_file, optarg, sizeof(save_file)-1); break;
            case 'c': strncpy(cmp_file,  optarg, sizeof(cmp_file)-1);  break;
            case 'T': threshold  = atof(optarg); break;
            case 'h': print_usage(argv[0]); return 0;
            default:  print_usage(argv[0]); return 1;
        }
    }

    ps_print_banner(SD_TOOL_NAME, SD_DESC);

    if (target_pid <= 0) {
        PS_ERR("%s", SD_NO_PID);
        return 1;
    }

    /* Attach via ptrace */
    if (ptrace(PTRACE_ATTACH, target_pid, NULL, NULL) < 0) {
        PS_ERR("%s: %s", SD_PTRACE_FAIL, strerror(errno));
        return 1;
    }

    /* Wait for process to stop */
    int status;
    waitpid(target_pid, &status, 0);
    PS_OK("%s (pid=%d)", SD_ATTACHING, (int)target_pid);
    PS_INFO("%s %d syscalls... %s", SD_CAPTURING, n_capture, I18N_PRESS_CTRL_C);

    signal(SIGINT, handle_sigint);

    dna_profile_t *profile = calloc(1, sizeof(dna_profile_t));
    if (!profile) { PS_ERR("Out of memory"); ptrace(PTRACE_DETACH, target_pid, NULL, NULL); return 1; }

    profile->magic   = PROFILE_MAGIC;
    profile->version = DNA_VERSION;

    /* Read process name */
    char comm_path[64];
    snprintf(comm_path, sizeof(comm_path), "/proc/%d/comm", (int)target_pid);
    FILE *cf = fopen(comm_path, "r");
    if (cf) {
        fgets(profile->procname, sizeof(profile->procname), cf);
        fclose(cf);
        size_t l = strlen(profile->procname);
        if (l > 0 && profile->procname[l-1] == '\n') profile->procname[l-1] = '\0';
    } else strncpy(profile->procname, "unknown", 7);

    long prev_syscall = -1;
    uint64_t captured = 0;
    uint64_t freq[SYSCALL_MAX] = {0};

    while (!g_stop && (int)captured < n_capture) {
        /* Run until next syscall entry/exit */
        if (ptrace(PTRACE_SYSCALL, target_pid, NULL, NULL) < 0) break;

        waitpid(target_pid, &status, 0);
        if (WIFEXITED(status) || WIFSIGNALED(status)) break;
        if (!WIFSTOPPED(status)) continue;

        scdna_regs_t regs;
        long syscall_nr = get_syscall_nr(target_pid, &regs);
        if (syscall_nr < 0) break;
        if (syscall_nr < 0 || syscall_nr >= SYSCALL_MAX) continue;

        freq[syscall_nr]++;
        captured++;

        /* Build Markov transition */
        if (prev_syscall >= 0) {
            profile->matrix[prev_syscall][syscall_nr] += 1.0f;
        }
        prev_syscall = syscall_nr;

        /* Progress */
        if ((captured % 500) == 0) {
            printf(PS_DIM "\r %s: %llu/%d  " PS_RESET,
                   SD_CAPTURING, (unsigned long long)captured, n_capture);
            fflush(stdout);
        }
    }

    printf("\n");
    ptrace(PTRACE_DETACH, target_pid, NULL, NULL);
    PS_OK("%s", SD_DETACHING);

    /* Count unique syscalls */
    uint32_t unique = 0;
    for (int i = 0; i < SYSCALL_MAX; i++) if (freq[i] > 0) unique++;
    profile->syscall_count  = captured;
    profile->unique_syscalls = unique;

    /* Normalize to probabilities */
    build_profile(freq, prev_syscall, profile);

    /* Print fingerprint summary */
    printf("\n" PS_BOLD PS_CYAN " === %s: %s ===\n\n" PS_RESET,
           SD_FINGERPRINT, profile->procname);
    printf(PS_DIM " %s: %llu | %s: %u\n" PS_RESET,
           SD_SYSCALLS, (unsigned long long)captured,
           SD_UNIQUE_SYSCALLS, unique);
    printf("\n");
    print_top_transitions(profile, 15);

    /* Save profile if requested */
    if (save_file[0]) {
        FILE *fp = fopen(save_file, "wb");
        if (!fp) {
            PS_ERR("Cannot write profile: %s", strerror(errno));
        } else {
            fwrite(profile, sizeof(dna_profile_t), 1, fp);
            fclose(fp);
            PS_OK("%s: %s", I18N_SAVED_TO, save_file);
        }
    }

    /* Compare against baseline if requested */
    if (cmp_file[0]) {
        FILE *fp = fopen(cmp_file, "rb");
        if (!fp) {
            PS_ERR("Cannot open profile: %s", strerror(errno));
        } else {
            dna_profile_t *baseline = malloc(sizeof(dna_profile_t));
            if (baseline && fread(baseline, sizeof(dna_profile_t), 1, fp) == 1) {
                if (baseline->magic != PROFILE_MAGIC) {
                    PS_ERR("Invalid profile file (bad magic)");
                } else {
                    PS_OK("%s '%s' (%s)", SD_PROFILE_LOADED, cmp_file, baseline->procname);
                    double sim = matrix_similarity(profile, baseline);
                    printf("\n " PS_BOLD "%s: " PS_RESET "%.1f%%\n", SD_SIMILARITY, sim * 100.0);

                    if (sim < threshold) {
                        printf("\n" PS_RED PS_BOLD
                               " ╔═══════════════════════════════════╗\n"
                               " ║  !! %s !!  ║\n"
                               " ╚═══════════════════════════════════╝\n"
                               PS_RESET, SD_ANOMALY);
                        printf(PS_RED " Similarity %.1f%% < threshold %.1f%%\n" PS_RESET,
                               sim * 100.0, threshold * 100.0);
                    } else {
                        PS_OK("%s (%.1f%% match)", SD_CLEAN, sim * 100.0);
                    }
                }
                free(baseline);
            }
            fclose(fp);
        }
    } else {
        PS_WARN("%s", SD_PROFILE_NONE);
    }

    free(profile);
    return 0;
}

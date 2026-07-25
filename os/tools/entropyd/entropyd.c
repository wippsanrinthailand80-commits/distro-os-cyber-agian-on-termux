/*
 * EntropyWarden — Real-time Ransomware Detector
 * PhantomSec OS v2.5.5 | Written in C
 *
 * UNIQUE TOOL: No existing open-source tool combines inotify + Shannon entropy
 * analysis + sliding-window statistical detection for ransomware.
 * Most AV solutions use signature matching; EntropyWarden uses pure mathematics.
 * Ransomware encrypts files → encrypted data has entropy ≈ 7.9-8.0 bits/byte.
 * Normal files (text, source, logs) have entropy ≈ 3.0-6.5 bits/byte.
 *
 * Algorithm:
 *   1. Watch target directories with inotify (IN_CLOSE_WRITE events)
 *   2. On each write event, sample the file and compute Shannon entropy
 *   3. Maintain a sliding time window of recent high-entropy writes
 *   4. If N high-entropy writes occur in T seconds → RANSOMWARE ALERT
 *   5. Identify the responsible process via /proc/[pid]/fd/ (Linux)
 *
 * Build: gcc -O2 -o entropyd entropyd.c -lm
 * Run:   sudo ./entropyd -w /home -w /var -t 6.8 -n 5 -W 10
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <math.h>
#include <time.h>
#include <signal.h>
#include <dirent.h>
#include <fcntl.h>
#include <sys/inotify.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <limits.h>

#include "../../i18n/i18n.h"

#define MAX_WATCH_DIRS   64
#define ENTROPY_BUF_SIZE (64 * 1024)   /* 64KB sample per file */
#define HIGH_ENTROPY_DEFAULT  6.8      /* bits/byte threshold */
#define WINDOW_DEFAULT_SEC    10       /* sliding window in seconds */
#define ALARM_COUNT_DEFAULT   5        /* high-entropy writes before alarm */
#define MAX_EVENTS_QUEUE      32
#define EVENT_BUF_LEN         (MAX_EVENTS_QUEUE * (sizeof(struct inotify_event) + NAME_MAX + 1))

static volatile int g_stop = 0;
static void handle_sigint(int sig) { (void)sig; g_stop = 1; }

/* High-entropy event record for sliding window */
typedef struct {
    time_t   timestamp;
    char     filepath[PATH_MAX];
    double   entropy;
    pid_t    pid;
    char     procname[256];
} entropy_event_t;

#define MAX_WINDOW_EVENTS 1024
static entropy_event_t g_window[MAX_WINDOW_EVENTS];
static int g_window_head = 0;
static int g_window_count = 0;

/* Watch descriptor → directory path map */
typedef struct {
    int  wd;
    char path[PATH_MAX];
} watch_entry_t;

static watch_entry_t g_watches[MAX_WATCH_DIRS];
static int g_watch_count = 0;

/* Config */
static double g_entropy_threshold = HIGH_ENTROPY_DEFAULT;
static int    g_window_sec        = WINDOW_DEFAULT_SEC;
static int    g_alarm_count       = ALARM_COUNT_DEFAULT;
static int    g_verbose           = 0;

/* Shannon entropy of a byte buffer */
static double shannon_entropy(const uint8_t *buf, size_t len) {
    if (len == 0) return 0.0;
    uint64_t freq[256] = {0};
    for (size_t i = 0; i < len; i++) freq[buf[i]]++;
    double entropy = 0.0;
    for (int i = 0; i < 256; i++) {
        if (freq[i] == 0) continue;
        double p = (double)freq[i] / (double)len;
        entropy -= p * log2(p);
    }
    return entropy;
}

/* Read up to ENTROPY_BUF_SIZE bytes from file, compute entropy */
static double file_entropy(const char *path) {
    static uint8_t buf[ENTROPY_BUF_SIZE];
    int fd = open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK);
    if (fd < 0) return -1.0;

    ssize_t n = read(fd, buf, sizeof(buf));
    close(fd);

    if (n <= 0) return -1.0;
    return shannon_entropy(buf, (size_t)n);
}

/* Try to find which process has the file open via /proc/PID/fd */
static pid_t find_file_owner(const char *filepath, char *procname, size_t pnlen) {
    DIR *proc_dir = opendir("/proc");
    if (!proc_dir) return -1;

    struct dirent *pd;
    pid_t found_pid = -1;

    while ((pd = readdir(proc_dir)) != NULL && found_pid < 0) {
        if (pd->d_type != DT_DIR) continue;
        pid_t pid = (pid_t)atoi(pd->d_name);
        if (pid <= 0) continue;

        char fd_dir[64];
        snprintf(fd_dir, sizeof(fd_dir), "/proc/%d/fd", (int)pid);
        DIR *fd_d = opendir(fd_dir);
        if (!fd_d) continue;

        struct dirent *fd_ent;
        while ((fd_ent = readdir(fd_d)) != NULL) {
            if (fd_ent->d_name[0] == '.') continue;
            char link_path[128];
            snprintf(link_path, sizeof(link_path), "/proc/%d/fd/%s",
                     (int)pid, fd_ent->d_name);
            char resolved[PATH_MAX];
            ssize_t r = readlink(link_path, resolved, sizeof(resolved)-1);
            if (r > 0) {
                resolved[r] = '\0';
                if (strcmp(resolved, filepath) == 0) {
                    found_pid = pid;
                    /* Read process name */
                    char comm_path[64];
                    snprintf(comm_path, sizeof(comm_path), "/proc/%d/comm", (int)pid);
                    FILE *cf = fopen(comm_path, "r");
                    if (cf) {
                        fgets(procname, (int)pnlen, cf);
                        fclose(cf);
                        size_t l = strlen(procname);
                        if (l > 0 && procname[l-1] == '\n') procname[l-1] = '\0';
                    } else {
                        strncpy(procname, "unknown", pnlen-1);
                    }
                    break;
                }
            }
        }
        closedir(fd_d);
    }
    closedir(proc_dir);
    return found_pid;
}

/* Count high-entropy events in the current sliding window */
static int count_recent_events(time_t now) {
    int count = 0;
    for (int i = 0; i < g_window_count; i++) {
        int idx = (g_window_head - g_window_count + i + MAX_WINDOW_EVENTS) % MAX_WINDOW_EVENTS;
        if ((now - g_window[idx].timestamp) <= g_window_sec) count++;
    }
    return count;
}

static void push_event(const entropy_event_t *ev) {
    g_window[g_window_head] = *ev;
    g_window_head = (g_window_head + 1) % MAX_WINDOW_EVENTS;
    if (g_window_count < MAX_WINDOW_EVENTS) g_window_count++;
}

static void fire_alarm(int recent_count) {
    printf("\n");
    printf(PS_RED PS_BOLD
           " ╔══════════════════════════════════════════════════╗\n"
           " ║  !! %s !!  ║\n"
           " ╚══════════════════════════════════════════════════╝\n"
           PS_RESET, EW_ENTROPY_ALARM);
    printf(PS_RED " %s: %d %s in %ds\n" PS_RESET,
           EW_FILES_IN_WINDOW, recent_count, EW_FILE_MODIFIED, g_window_sec);

    /* Show the offending events */
    time_t now = time(NULL);
    printf(PS_YELLOW " Recent high-entropy writes:\n" PS_RESET);
    for (int i = 0; i < g_window_count; i++) {
        int idx = (g_window_head - g_window_count + i + MAX_WINDOW_EVENTS) % MAX_WINDOW_EVENTS;
        entropy_event_t *e = &g_window[idx];
        if ((now - e->timestamp) > g_window_sec) continue;
        printf(PS_DIM "   [%ld] %.2f bits/byte  pid=%-6d  (%s)\n"
               "        %s\n" PS_RESET,
               (long)e->timestamp, e->entropy, (int)e->pid, e->procname, e->filepath);
        if (e->pid > 0) {
            printf(PS_MAGENTA "   %s: kill -9 %d  (or: %s)\n" PS_RESET,
                   EW_QUARANTINE, (int)e->pid, EW_QUARANTINE);
        }
    }
    printf("\n");
}

static void process_write_event(const char *dirpath, const char *filename) {
    char fullpath[PATH_MAX];
    snprintf(fullpath, sizeof(fullpath), "%s/%s", dirpath, filename);

    double ent = file_entropy(fullpath);
    if (ent < 0.0) return;

    time_t now = time(NULL);
    char ts[32];
    struct tm *tm_info = localtime(&now);
    strftime(ts, sizeof(ts), "%H:%M:%S", tm_info);

    if (ent >= g_entropy_threshold) {
        entropy_event_t ev = {0};
        ev.timestamp = now;
        ev.entropy   = ent;
        strncpy(ev.filepath, fullpath, PATH_MAX-1);
        ev.pid = find_file_owner(fullpath, ev.procname, sizeof(ev.procname));

        push_event(&ev);

        printf(PS_RED " [%s] %s" PS_RESET " — %.3f %s",
               ts, EW_ENTROPY_HIGH, ent, EW_BITS_PER_BYTE);
        if (ev.pid > 0)
            printf(PS_DIM "  (pid=%d %s)" PS_RESET, (int)ev.pid, ev.procname);
        printf("\n" PS_DIM "   %s\n" PS_RESET, fullpath);

        int recent = count_recent_events(now);
        if (recent >= g_alarm_count) fire_alarm(recent);

    } else if (g_verbose) {
        printf(PS_GREEN " [%s] %s" PS_RESET " — %.3f %s  %s\n" PS_DIM "   %s\n" PS_RESET,
               ts, EW_ENTROPY_NORMAL, ent, EW_BITS_PER_BYTE, PS_GRAY, fullpath);
    }
}

static void print_usage(const char *prog) {
    printf(PS_BOLD "%s:" PS_RESET " %s [options]\n\n", I18N_USAGE, prog);
    printf(PS_BOLD "%s:\n" PS_RESET, I18N_OPTIONS);
    printf("  -w <dir>    Watch directory (repeatable, max %d)\n", MAX_WATCH_DIRS);
    printf("  -t <val>    Entropy threshold (default: %.1f %s)\n",
           HIGH_ENTROPY_DEFAULT, EW_BITS_PER_BYTE);
    printf("  -n <count>  High-entropy files before alarm (default: %d)\n", ALARM_COUNT_DEFAULT);
    printf("  -W <sec>    Detection window in seconds (default: %d)\n", WINDOW_DEFAULT_SEC);
    printf("  -v          Verbose (show normal entropy too)\n");
    printf("  -h          Show help\n\n");
    printf(PS_BOLD "%s:\n" PS_RESET, I18N_EXAMPLE);
    printf("  %s -w /home -w /Documents\n", prog);
    printf("  %s -w / -t 7.0 -n 3 -W 5\n\n", prog);
    printf(PS_DIM " Entropy reference:\n"
           "   ~3.0-5.5 bits/byte → plaintext, source code, logs (normal)\n"
           "   ~6.0-7.5 bits/byte → compressed files (normal)\n"
           "   ~7.8-8.0 bits/byte → encrypted data (suspicious!)\n\n" PS_RESET);
}

int main(int argc, char *argv[]) {
    ps_lang_init();

    char watch_dirs[MAX_WATCH_DIRS][PATH_MAX];
    int  nwatch = 0;

    int opt;
    while ((opt = getopt(argc, argv, "w:t:n:W:vh")) != -1) {
        switch (opt) {
            case 'w':
                if (nwatch < MAX_WATCH_DIRS)
                    strncpy(watch_dirs[nwatch++], optarg, PATH_MAX-1);
                break;
            case 't': g_entropy_threshold = atof(optarg); break;
            case 'n': g_alarm_count       = atoi(optarg); break;
            case 'W': g_window_sec        = atoi(optarg); break;
            case 'v': g_verbose           = 1; break;
            case 'h': print_usage(argv[0]); return 0;
            default:  print_usage(argv[0]); return 1;
        }
    }

    if (nwatch == 0) {
        /* Default: watch /home */
        strncpy(watch_dirs[nwatch++], "/home", PATH_MAX-1);
    }

    ps_print_banner(EW_TOOL_NAME, EW_DESC);

    int ifd = inotify_init1(IN_NONBLOCK);
    if (ifd < 0) { PS_ERR("%s: %s", EW_INOTIFY_FAIL, strerror(errno)); return 1; }

    for (int i = 0; i < nwatch; i++) {
        int wd = inotify_add_watch(ifd, watch_dirs[i],
                                   IN_CLOSE_WRITE | IN_MOVED_TO | IN_CREATE);
        if (wd < 0) {
            PS_WARN("%s '%s': %s", EW_WATCH_FAIL, watch_dirs[i], strerror(errno));
            continue;
        }
        g_watches[g_watch_count].wd = wd;
        strncpy(g_watches[g_watch_count].path, watch_dirs[i], PATH_MAX-1);
        g_watch_count++;
        PS_OK("%s: %s", EW_WATCHING, watch_dirs[i]);
    }

    if (g_watch_count == 0) { PS_ERR("No valid watch directories"); return 1; }

    printf(PS_DIM "\n %s: %.1f %s | %s: %d events / %ds\n" PS_RESET,
           EW_THRESHOLD, g_entropy_threshold, EW_BITS_PER_BYTE,
           EW_WINDOW, g_alarm_count, g_window_sec);
    printf(PS_CYAN " %s\n\n" PS_RESET, I18N_PRESS_CTRL_C);

    signal(SIGINT, handle_sigint);

    static char event_buf[EVENT_BUF_LEN] __attribute__((aligned(__alignof__(struct inotify_event))));

    while (!g_stop) {
        ssize_t len = read(ifd, event_buf, sizeof(event_buf));
        if (len < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                usleep(50000); /* 50ms poll interval */
                continue;
            }
            if (errno == EINTR) continue;
            PS_ERR("read inotify: %s", strerror(errno));
            break;
        }

        const struct inotify_event *ev;
        for (char *ptr = event_buf; ptr < event_buf + len;
             ptr += sizeof(struct inotify_event) + ev->len) {
            ev = (const struct inotify_event *)ptr;
            if (ev->len == 0) continue;
            if (ev->mask & (IN_CLOSE_WRITE | IN_MOVED_TO)) {
                /* Find directory path for this watch descriptor */
                const char *dirpath = NULL;
                for (int i = 0; i < g_watch_count; i++) {
                    if (g_watches[i].wd == ev->wd) { dirpath = g_watches[i].path; break; }
                }
                if (dirpath) process_write_event(dirpath, ev->name);
            }
        }
    }

    PS_OK("%s", I18N_STOPPED);
    close(ifd);
    return 0;
}

/*
 * main.c — Entry point for phantom-proot
 *
 * Compatible with proot-distro: handles all standard proot options
 * (both short and long form), ignoring unsupported ones gracefully.
 *
 * CLI: phantom-proot [options] -- <command> [args...]
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <signal.h>
#include <sys/ptrace.h>
#include <sys/stat.h>
#include "proot.h"

static void usage(const char *argv0)
{
    fprintf(stderr,
        "phantom-proot v2.8.0 — Minimal proot from scratch\n"
        "\n"
        "Usage: %s [options] -- <command> [args...]\n"
        "\n"
        "Options:\n"
        "  -r, --rootfs=<path>        Fake root directory (required)\n"
        "  -b, --bind=<h>[:<g>]       Bind mount: host path to guest path\n"
        "  -w, --cwd=<dir>            Initial working directory inside guest\n"
        "  -v                         Verbose output\n"
        "  -h                         Show this help\n"
        "\n"
        "Ignored options (accepted for proot-distro compatibility):\n"
        "  --kill-on-exit  --link2symlink  --sysvipc  -L  -0  -p\n"
        "  --kernel-release=<str>  --change-id=<uid>:<gid>\n"
        "\n"
        "Examples:\n"
        "  %s -r ~/rootfs -b /proc:/proc -w /root -- /bin/bash\n"
        "  %s --rootfs=~/rootfs --bind=/dev --bind=/proc -- /bin/sh\n",
        argv0, argv0, argv0);
}

static int check_rootfs(const char *root)
{
    struct stat st;
    if (stat(root, &st) < 0) {
        fprintf(stderr, "phantom-proot: rootfs not found: %s\n", root);
        return -1;
    }
    if (!S_ISDIR(st.st_mode)) {
        fprintf(stderr, "phantom-proot: rootfs is not a directory: %s\n", root);
        return -1;
    }
    return 0;
}

/*
 * Parse a bind spec: "host:guest" or "host" (guest=host).
 * Handles both colon-separated and equals-separated formats.
 */
static int parse_bind(const char *spec)
{
    char host[PP_MAX_PATH];
    char guest[PP_MAX_PATH];

    const char *colon = strchr(spec, ':');
    if (colon) {
        size_t hlen = (size_t)(colon - spec);
        if (hlen >= sizeof(host))
            return -1;
        memcpy(host, spec, hlen);
        host[hlen] = '\0';
        snprintf(guest, sizeof(guest), "%s", colon + 1);
    } else {
        snprintf(host, sizeof(host), "%s", spec);
        snprintf(guest, sizeof(guest), "%s", spec);
    }

    return mount_add(host, guest);
}

/* Long option codes (values > 255 to not collide with short opts) */
enum {
    OPT_KILL_ON_EXIT = 256,
    OPT_LINK2SYMLINK,
    OPT_SYSVIPC,
    OPT_KERNEL_RELEASE,
    OPT_CHANGE_ID,
    OPT_ROOTFS,
    OPT_CWD,
    OPT_BIND,
    OPT_FORCE,
    OPT_SECCOMP,
    OPT_TRACERSYSGOOD,
};

static const struct option long_opts[] = {
    {"rootfs",           required_argument, NULL, 'r'},
    {"cwd",              required_argument, NULL, 'w'},
    {"bind",             required_argument, NULL, 'b'},
    {"kill-on-exit",     no_argument,       NULL, OPT_KILL_ON_EXIT},
    {"link2symlink",     no_argument,       NULL, OPT_LINK2SYMLINK},
    {"sysvipc",          no_argument,       NULL, OPT_SYSVIPC},
    {"kernel-release",   required_argument, NULL, OPT_KERNEL_RELEASE},
    {"change-id",        required_argument, NULL, OPT_CHANGE_ID},
    {"force",            no_argument,       NULL, OPT_FORCE},
    {"seccomp",          optional_argument, NULL, OPT_SECCOMP},
    {"help",             no_argument,       NULL, 'h'},
    {"verbose",          no_argument,       NULL, 'v'},
    {NULL, 0, NULL, 0}
};

int main(int argc, char *argv[])
{
    /* Initialize global state */
    memset(&g_pp, 0, sizeof(g_pp));
    snprintf(g_pp.root, sizeof(g_pp.root), "/");

    const char *init_cwd = "/";
    char *rootfs = NULL;
    int opt;

    /* Reset getopt state */
    optind = 1;

    while ((opt = getopt_long(argc, argv, "r:b:w:vhL0pS::s::",
                              long_opts, NULL)) != -1) {
        switch (opt) {
        case 'r':
            rootfs = optarg;
            break;
        case OPT_ROOTFS:
            rootfs = optarg;
            break;
        case 'b':
            if (parse_bind(optarg) < 0)
                return 1;
            break;
        case OPT_BIND:
            if (parse_bind(optarg) < 0)
                return 1;
            break;
        case 'w':
            init_cwd = optarg;
            break;
        case OPT_CWD:
            init_cwd = optarg;
            break;
        case 'v':
            g_pp.verbose = 1;
            break;
        case 'h':
            usage(argv[0]);
            return 0;

        /* Silently ignored options (proot-distro compatibility) */
        case OPT_KILL_ON_EXIT:
        case OPT_LINK2SYMLINK:
        case OPT_SYSVIPC:
        case OPT_KERNEL_RELEASE:
        case OPT_CHANGE_ID:
        case OPT_FORCE:
        case 'L':
        case '0':
        case 'p':
        case 'S':
        case 's':
            /* Accepted but not implemented */
            break;
        default:
            /* Unknown option — ignore instead of failing */
            break;
        }
    }

    /* Need at least a rootfs and a command */
    if (!rootfs) {
        fprintf(stderr, "phantom-proot: --rootfs is required\n");
        usage(argv[0]);
        return 1;
    }

    if (optind >= argc) {
        fprintf(stderr, "phantom-proot: no command specified\n");
        usage(argv[0]);
        return 1;
    }

    /* Strip trailing slash from rootfs (except bare "/") */
    size_t rlen = strlen(rootfs);
    if (rlen > 1 && rootfs[rlen - 1] == '/')
        rootfs[rlen - 1] = '\0';

    /* Validate rootfs exists */
    if (check_rootfs(rootfs) < 0)
        return 1;

    /* Set global root */
    snprintf(g_pp.root, sizeof(g_pp.root), "%s", rootfs);

    /* Command to execute (everything after --, or after all options) */
    char **cmd = &argv[optind];

    if (g_pp.verbose) {
        fprintf(stderr, "phantom-proot: root=%s cwd=%s cmd=%s\n",
                g_pp.root, init_cwd, cmd[0]);
        for (int i = 0; i < g_pp.nbinds; i++)
            fprintf(stderr, "  bind: %s -> %s\n",
                    g_pp.binds[i].host, g_pp.binds[i].guest);
    }

    /* Fork child */
    pid_t child = fork();
    if (child < 0) {
        perror("phantom-proot: fork");
        return 1;
    }

    if (child == 0) {
        /* ── Child ─────────────────────────────────────────────────── */
        ptrace(PTRACE_TRACEME, 0, NULL, NULL);
        raise(SIGSTOP);

        /* chdir to initial CWD (proot will intercept and translate) */
        chdir(init_cwd);

        /* exec the command (proot will intercept and translate) */
        execvp(cmd[0], cmd);
        perror("phantom-proot: execvp");
        _exit(127);
    }

    /* ── Parent (tracer) ───────────────────────────────────────────── */
    if (g_pp.verbose)
        fprintf(stderr, "phantom-proot: child pid=%d\n", child);

    proc_event_loop(child);

    return 0;
}

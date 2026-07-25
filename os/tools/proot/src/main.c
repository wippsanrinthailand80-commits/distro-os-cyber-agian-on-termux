/* main.c — Entry point for phantom-proot
 * PhantomSec phantom-proot
 *
 * Usage:
 *   proot -r <rootfs> [-b <host>:<guest> ...] -- <cmd> [args...]
 *
 * Example (Termux):
 *   proot -r ~/phantomsec-rootfs \
 *         -b /proc:/proc         \
 *         -b /dev:/dev           \
 *         -b /sys:/sys           \
 *         -- /bin/bash --login
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "proot.h"

/* ── Print usage ────────────────────────────────────────── */
static void usage(const char *argv0)
{
    fprintf(stderr,
        "phantom-proot — PhantomSec user-space chroot via ptrace\n"
        "Version: 2.5.3 | ARM64-primary | no root required\n"
        "\n"
        "Usage:\n"
        "  %s -r <rootfs> [-b <host>:<guest>] ... -- <cmd> [args...]\n"
        "\n"
        "Options:\n"
        "  -r <rootfs>        Fake root directory (required)\n"
        "  -b <host>:<guest>  Bind-mount host path to guest path\n"
        "                     (may be specified multiple times)\n"
        "  -w <dir>           Set initial working directory inside guest\n"
        "                     (default: /)\n"
        "  -h                 Show this help\n"
        "\n"
        "Examples:\n"
        "  # Minimal — run bash inside a rootfs\n"
        "  %s -r ~/rootfs -- /bin/bash\n"
        "\n"
        "  # With /proc /dev /sys bind-mounted (recommended for Termux)\n"
        "  %s -r ~/rootfs \\\n"
        "     -b /proc:/proc \\\n"
        "     -b /dev:/dev   \\\n"
        "     -b /sys:/sys   \\\n"
        "     -- /bin/bash --login\n"
        "\n",
        argv0, argv0, argv0);
}

/* ── Parse a bind spec "host:guest" ────────────────────── */
static int parse_bind(const char *spec)
{
    char buf[PP_MAX_PATH * 2];
    snprintf(buf, sizeof(buf), "%s", spec);
    char *colon = strchr(buf, ':');
    if (!colon) {
        fprintf(stderr, "[proot] bad bind spec (expected host:guest): %s\n",
                spec);
        return -1;
    }
    *colon = '\0';
    const char *host  = buf;
    const char *guest = colon + 1;
    mount_add(host, guest);
    return 0;
}

/* ── Validate rootfs directory ──────────────────────────── */
static int check_rootfs(const char *root)
{
    struct stat st;
    if (stat(root, &st) < 0) {
        fprintf(stderr, "[proot] rootfs not found: %s: %s\n",
                root, strerror(errno));
        return -1;
    }
    if (!S_ISDIR(st.st_mode)) {
        fprintf(stderr, "[proot] rootfs is not a directory: %s\n", root);
        return -1;
    }
    return 0;
}

/* ── Main ───────────────────────────────────────────────── */
int main(int argc, char *argv[])
{
    memset(&g_pp, 0, sizeof(g_pp));

    const char *rootfs  = NULL;
    const char *init_cwd = "/";
    int         opt;

    while ((opt = getopt(argc, argv, "+r:b:w:h")) != -1) {
        switch (opt) {
        case 'r':
            rootfs = optarg;
            break;
        case 'b':
            if (parse_bind(optarg) < 0)
                return 1;
            break;
        case 'w':
            init_cwd = optarg;
            break;
        case 'h':
            usage(argv[0]);
            return 0;
        default:
            usage(argv[0]);
            return 1;
        }
    }

    if (!rootfs) {
        fprintf(stderr, "[proot] -r <rootfs> is required\n\n");
        usage(argv[0]);
        return 1;
    }

    if (optind >= argc) {
        fprintf(stderr, "[proot] no command specified after --\n\n");
        usage(argv[0]);
        return 1;
    }

    if (check_rootfs(rootfs) < 0)
        return 1;

    /* Store fake root in global state */
    snprintf(g_pp.root, sizeof(g_pp.root), "%s", rootfs);
    /* Strip trailing slash (except bare "/") */
    {
        size_t rlen = strlen(g_pp.root);
        if (rlen > 1 && g_pp.root[rlen - 1] == '/')
            g_pp.root[rlen - 1] = '\0';
    }

    char **cmd     = &argv[optind];

    /* Translate the command path to a host path so the kernel can exec it */
    char translated_cmd[PP_MAX_PATH];
    if (path_translate(g_pp.root, init_cwd, cmd[0],
                       translated_cmd, sizeof(translated_cmd)) < 0) {
        fprintf(stderr, "[proot] cannot translate cmd path: %s\n", cmd[0]);
        return 1;
    }

    fprintf(stderr,
            "[proot] phantom-proot starting\n"
            "[proot]   root    : %s\n"
            "[proot]   command : %s -> %s\n"
            "[proot]   binds   : %d\n",
            g_pp.root, cmd[0], translated_cmd, g_pp.nbinds);

    /* ── Fork the tracee ── */
    pid_t child = fork();
    if (child < 0) {
        perror("fork");
        return 1;
    }

    if (child == 0) {
        /* Child: enable tracing then exec */
        if (ptrace(PTRACE_TRACEME, 0, NULL, NULL) < 0) {
            perror("PTRACE_TRACEME");
            _exit(1);
        }
        /* Raise SIGSTOP so the parent can set options before we exec */
        raise(SIGSTOP);

        /* Chdir to the host path of the guest initial cwd */
        char host_cwd[PP_MAX_PATH];
        if (path_translate(g_pp.root, "/", init_cwd,
                           host_cwd, sizeof(host_cwd)) == 0) {
            chdir(host_cwd);
        }

        execv(translated_cmd, cmd);
        perror("execv");
        _exit(127);
    }

    /* Parent: run the event loop */
    tracee_event_loop(child);

    fprintf(stderr, "[proot] all tracees exited\n");
    return 0;
}

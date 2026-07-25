/* path.c — Guest↔Host path translation
 * PhantomSec phantom-proot
 *
 * Guest paths are what the traced process sees (e.g. /etc/passwd).
 * Host paths are real filesystem paths (e.g. /data/.../rootfs/etc/passwd).
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>

#include "proot.h"

/* ── Normalize a path in-place ──────────────────────────────
 * Resolves . and .. components without hitting the filesystem.
 * Does NOT resolve symlinks. */
static void path_normalize(char *path)
{
    /* tokenise by '/', rebuild into buf */
    char  buf[PP_MAX_PATH];
    char *seg[PP_MAX_PATH / 2];
    int   nseg = 0;

    char *p = path;
    while (*p) {
        while (*p == '/') p++;
        if (!*p) break;
        char *end = p;
        while (*end && *end != '/') end++;
        size_t len = (size_t)(end - p);
        if (len == 1 && p[0] == '.') {
            /* skip */
        } else if (len == 2 && p[0] == '.' && p[1] == '.') {
            if (nseg > 0) nseg--;
        } else {
            seg[nseg++] = p;
            seg[nseg - 1][len] = '\0'; /* temporarily terminate */
        }
        p = end;
    }

    /* reassemble */
    buf[0] = '\0';
    for (int i = 0; i < nseg; i++) {
        strcat(buf, "/");
        strcat(buf, seg[i]);
    }
    if (buf[0] == '\0') strcpy(buf, "/");
    strcpy(path, buf);
}

/* ── Translate guest path → host path ───────────────────────
 *
 * root  : host path of the fake root (e.g. /home/user/rootfs)
 * cwd   : guest cwd (e.g. /usr/bin)
 * guest : the path the process passed to a syscall
 * out   : output buffer for the host path
 * outsz : size of out
 *
 * Returns 0 on success, -1 on error.
 */
int path_translate(const char *root, const char *cwd,
                   const char *guest, char *out, size_t outsz)
{
    char abs_guest[PP_MAX_PATH];

    /* --- make path absolute in guest namespace --- */
    if (guest[0] == '/') {
        snprintf(abs_guest, sizeof(abs_guest), "%s", guest);
    } else {
        /* relative — prepend guest cwd */
        snprintf(abs_guest, sizeof(abs_guest), "%s/%s", cwd, guest);
    }

    /* normalize (resolve . and ..) */
    path_normalize(abs_guest);

    /* --- check bind mounts first --- */
    const pp_bind_t *bind = mount_lookup(abs_guest);
    if (bind) {
        /* The guest path falls inside a bind mount.
         * Map guest path relative to bind->guest onto bind->host. */
        size_t glen = strlen(bind->guest);
        const char *rel = abs_guest + glen;
        if (*rel == '\0')
            snprintf(out, outsz, "%s", bind->host);
        else
            snprintf(out, outsz, "%s%s", bind->host, rel);
        return 0;
    }

    /* --- standard: prepend root --- */
    /* guard against escaping the root with too many ".." */
    snprintf(out, outsz, "%s%s", root, abs_guest);
    return 0;
}

/* ── Translate host path → guest path ───────────────────────
 *
 * Used for syscall exits that return paths (getcwd, readlink).
 *
 * Returns 0 on success, -1 if the host path is not inside root.
 */
int path_detranslate(const char *root, const char *host,
                     char *out, size_t outsz)
{
    size_t rlen = strlen(root);
    if (strncmp(host, root, rlen) == 0) {
        const char *rel = host + rlen;
        if (*rel == '\0')
            snprintf(out, outsz, "/");
        else
            snprintf(out, outsz, "%s", rel);
        return 0;
    }
    /* not inside root — return as-is */
    snprintf(out, outsz, "%s", host);
    return -1;
}

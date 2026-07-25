/* mount.c — Virtual bind-mount table
 * PhantomSec phantom-proot
 *
 * Tracks user-requested bind mounts (e.g. /proc, /dev, /sys).
 * No kernel involvement — purely a lookup table used by path.c.
 */

#include <stdio.h>
#include <string.h>
#include "proot.h"

pp_state_t g_pp;   /* global proot state — defined once here */

/* Add a bind mount entry.
 * host  = real directory on the host filesystem
 * guest = path inside the fake root where it should appear */
void mount_add(const char *host, const char *guest)
{
    if (g_pp.nbinds >= PP_MAX_BINDS) {
        fprintf(stderr, "[proot] bind-mount table full (max %d)\n",
                PP_MAX_BINDS);
        return;
    }
    pp_bind_t *b = &g_pp.binds[g_pp.nbinds++];
    snprintf(b->host,  sizeof(b->host),  "%s", host);
    snprintf(b->guest, sizeof(b->guest), "%s", guest);
}

/* Find the best (longest-prefix) matching bind mount for a guest path.
 * Returns NULL if no match. */
const pp_bind_t *mount_lookup(const char *guest_path)
{
    const pp_bind_t *best = NULL;
    size_t           best_len = 0;

    for (int i = 0; i < g_pp.nbinds; i++) {
        const pp_bind_t *b   = &g_pp.binds[i];
        size_t           glen = strlen(b->guest);

        if (strncmp(guest_path, b->guest, glen) != 0)
            continue;
        /* must match at a path boundary */
        char next = guest_path[glen];
        if (next != '\0' && next != '/')
            continue;
        if (glen > best_len) {
            best     = b;
            best_len = glen;
        }
    }
    return best;
}

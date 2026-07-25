/*
 * mount.c — Global state and bind mount management
 */

#include <stdio.h>
#include <string.h>
#include "proot.h"

pp_state_t g_pp;

int mount_add(const char *host, const char *guest)
{
    if (g_pp.nbinds >= PP_MAX_BINDS) {
        fprintf(stderr, "phantom-proot: too many bind mounts (max %d)\n",
                PP_MAX_BINDS);
        return -1;
    }

    pp_bind_t *b = &g_pp.binds[g_pp.nbinds];
    snprintf(b->host,  sizeof(b->host),  "%s", host);
    snprintf(b->guest, sizeof(b->guest), "%s", guest);
    g_pp.nbinds++;

    if (g_pp.verbose)
        fprintf(stderr, "  bind: %s -> %s\n", host, guest);

    return 0;
}

const pp_bind_t *mount_lookup(const char *guest_path)
{
    const pp_bind_t *best = NULL;
    size_t best_len = 0;

    for (int i = 0; i < g_pp.nbinds; i++) {
        const pp_bind_t *b = &g_pp.binds[i];
        size_t glen = strlen(b->guest);

        /* Exact match or prefix match at path boundary */
        if (strncmp(guest_path, b->guest, glen) == 0 &&
            (guest_path[glen] == '/' || guest_path[glen] == '\0')) {
            if (glen > best_len) {
                best = b;
                best_len = glen;
            }
        }
    }

    return best;
}

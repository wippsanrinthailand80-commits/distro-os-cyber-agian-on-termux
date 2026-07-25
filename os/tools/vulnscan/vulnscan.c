/*
 * VulnScan — Lightweight Vulnerability Scanner
 * PhantomSec OS v2.5.5 | Written in C
 *
 * Checks for common misconfigurations, weak permissions, outdated packages,
 * open ports with known vulnerable services, and SUID/SGID risks.
 *
 * Build: gcc -O2 -o vulnscan vulnscan.c
 * Run:   sudo ./vulnscan
 *        sudo ./vulnscan -a
 *        sudo ./vulnscan -f /etc/passwd
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>

#define MAX_FINDINGS 512
#define MAX_LINE     1024

typedef enum { SEV_INFO, SEV_LOW, SEV_MED, SEV_HIGH, SEV_CRIT } severity_t;

typedef struct {
    severity_t sev;
    char       category[64];
    char       finding[512];
    char       remediation[256];
} vuln_t;

static vuln_t g_findings[MAX_FINDINGS];
static int    g_nfind = 0;

static const char *SEV_STR[] = { "INFO", "LOW", "MEDIUM", "HIGH", "CRITICAL" };
static const char *SEV_COLOR[] = {
    "\033[0;37m",   /* INFO - white */
    "\033[0;36m",   /* LOW - cyan */
    "\033[1;33m",   /* MED - yellow */
    "\033[0;31m",   /* HIGH - red */
    "\033[1;31m"    /* CRIT - bold red */
};

static void add_finding(severity_t sev, const char *cat, const char *find, const char *fix) {
    if (g_nfind >= MAX_FINDINGS) return;
    vuln_t *v = &g_findings[g_nfind++];
    v->sev = sev;
    strncpy(v->category, cat, sizeof(v->category)-1);
    strncpy(v->finding, find, sizeof(v->finding)-1);
    strncpy(v->remediation, fix, sizeof(v->remediation)-1);
}

/* Check /etc/passwd for users with empty passwords */
static void check_empty_passwords(void) {
    FILE *fp = fopen("/etc/shadow", "r");
    if (!fp) return;
    char line[MAX_LINE];
    while (fgets(line, sizeof(line), fp)) {
        char *p = strchr(line, ':');
        if (!p) continue;
        char *pw = p + 1;
        if (*pw == ':' || *pw == '\n' || strncmp(pw, "!$", 2) == 0 || strncmp(pw, "*", 1) == 0) {
            if (*pw == ':') {
                *p = '\0';
                add_finding(SEV_CRIT, "Auth", line, "Set password or lock account: passwd -l <user>");
            }
        }
    }
    fclose(fp);
}

/* Check world-writable files in critical dirs */
static void check_world_writable(void) {
    const char *dirs[] = {"/etc", "/usr", "/var", "/bin", "/sbin", NULL};
    char path[MAX_LINE];
    struct stat st;

    for (int d = 0; dirs[d]; d++) {
        snprintf(path, sizeof(path), "find %s -type f -perm -0002 2>/dev/null", dirs[d]);
        FILE *fp = popen(path, "r");
        if (!fp) continue;
        char line[MAX_LINE];
        int count = 0;
        while (fgets(line, sizeof(line), fp) && count < 10) {
            line[strcspn(line, "\n")] = '\0';
            char msg[640];
            snprintf(msg, sizeof(msg), "%s is world-writable", line);
            add_finding(SEV_HIGH, "Permissions", msg, "chmod o-w <file>");
            count++;
        }
        pclose(fp);
    }
}

/* Check SUID binaries */
static void check_suid_binaries(void) {
    const char *safe_suid[] = {
        "/usr/bin/passwd", "/usr/bin/sudo", "/usr/bin/su", "/usr/bin/newgrp",
        "/usr/bin/chsh", "/usr/bin/chfn", "/usr/bin/gpasswd",
        "/usr/bin/mount", "/usr/bin/umount", "/usr/bin/fusermount",
        "/usr/lib/openssh/ssh-keysign", NULL
    };

    FILE *fp = popen("find / -perm -4000 -type f 2>/dev/null", "r");
    if (!fp) return;

    char line[MAX_LINE];
    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = '\0';
        int safe = 0;
        for (int i = 0; safe_suid[i]; i++) {
            if (strcmp(line, safe_suid[i]) == 0) { safe = 1; break; }
        }
        if (!safe) {
            char msg[640];
            snprintf(msg, sizeof(msg), "Unexpected SUID binary: %s", line);
            add_finding(SEV_MED, "PrivEsc", msg, "Review if SUID bit is needed: chmod u-s <file>");
        }
    }
    pclose(fp);
}

/* Check /tmp permissions */
static void check_tmp_sticky(void) {
    struct stat st;
    if (stat("/tmp", &st) == 0) {
        if (!(st.st_mode & 01000)) {
            add_finding(SEV_MED, "Config", "/tmp missing sticky bit", "chmod 1777 /tmp");
        }
    }
}

/* Check SSH config */
static void check_ssh_config(void) {
    FILE *fp = fopen("/etc/ssh/sshd_config", "r");
    if (!fp) return;

    char line[MAX_LINE];
    int root_login = 1, pass_auth = 1, protocol = 0;
    while (fgets(line, sizeof(line), fp)) {
        if (line[0] == '#') continue;
        if (strstr(line, "PermitRootLogin yes")) root_login = 0;
        if (strstr(line, "PasswordAuthentication yes")) pass_auth = 0;
        if (strstr(line, "Protocol 1")) protocol = 1;
    }
    fclose(fp);

    if (!root_login) add_finding(SEV_HIGH, "SSH", "Root login enabled", "Set PermitRootLogin no");
    if (!pass_auth)  add_finding(SEV_MED, "SSH", "Password auth enabled", "Use key-based auth only");
    if (protocol)    add_finding(SEV_CRIT, "SSH", "SSHv1 protocol enabled", "Set Protocol 2");
}

/* Check listening services */
static void check_listening_services(void) {
    FILE *fp = popen("ss -tuln 2>/dev/null | grep LISTEN", "r");
    if (!fp) return;

    char line[MAX_LINE];
    while (fgets(line, sizeof(line), fp)) {
        if (strstr(line, "0.0.0.0:") || strstr(line, "*:")) {
            /* Extract port */
            char *p = strrchr(line, ':');
            if (p) {
                int port = atoi(p + 1);
                if (port == 21 || port == 23 || port == 3389 || port == 445 || port == 135) {
                    char msg[256];
                    snprintf(msg, sizeof(msg), "Potentially risky service on port %d: %s", port, line);
                    add_finding(SEV_MED, "Network", msg, "Review if service is needed, restrict access");
                }
            }
        }
    }
    pclose(fp);
}

/* Check kernel version for known vulnerabilities */
static void check_kernel_version(void) {
    FILE *fp = popen("uname -r", "r");
    if (!fp) return;
    char ver[128] = {0};
    fgets(ver, sizeof(ver), fp);
    pclose(fp);
    ver[strcspn(ver, "\n")] = '\0';

    /* Basic check — real implementation would compare against CVE DB */
    int major = 0, minor = 0;
    sscanf(ver, "%d.%d", &major, &minor);
    if (major < 4 || (major == 4 && minor < 15)) {
        char msg[256];
        snprintf(msg, sizeof(msg), "Kernel %s may be outdated", ver);
        add_finding(SEV_LOW, "Kernel", msg, "Update to latest stable kernel");
    }
}

static int cmp_severity(const void *a, const void *b) {
    return ((vuln_t *)b)->sev - ((vuln_t *)a)->sev;
}

static void print_findings(int show_info) {
    qsort(g_findings, g_nfind, sizeof(vuln_t), cmp_severity);

    int counts[5] = {0};
    for (int i = 0; i < g_nfind; i++) counts[g_findings[i].sev]++;

    printf("\n  \033[1;36m╔═══════════════════════════════════════════════════════╗\033[0m\n");
    printf("  \033[1;36m║  VulnScan — Security Audit Report                    ║\033[0m\n");
    printf("  \033[1;36m╚═══════════════════════════════════════════════════════╝\033[0m\n\n");

    printf("  Summary: ");
    printf("\033[1;31m%d CRIT\033[0m  ", counts[SEV_CRIT]);
    printf("\033[0;31m%d HIGH\033[0m  ", counts[SEV_HIGH]);
    printf("\033[1;33m%d MED\033[0m  ", counts[SEV_MED]);
    printf("\033[0;36m%d LOW\033[0m  ", counts[SEV_LOW]);
    printf("\033[0;37m%d INFO\033[0m\n\n", counts[SEV_INFO]);

    for (int i = 0; i < g_nfind; i++) {
        vuln_t *v = &g_findings[i];
        if (!show_info && v->sev == SEV_INFO) continue;
        printf("  %s[%s]\033[0m \033[1m%-10s\033[0m %s\n",
               SEV_COLOR[v->sev], SEV_STR[v->sev], v->category, v->finding);
        if (v->remediation[0])
            printf("  \033[2m  → %s\033[0m\n", v->remediation);
    }
    printf("\n");
}

static void print_usage(const char *prog) {
    printf("Usage: %s [options]\n\n", prog);
    printf("Options:\n");
    printf("  -a          Show all findings including INFO\n");
    printf("  -f <file>   Check specific file permissions\n");
    printf("  -q          Quiet mode (summary only)\n");
    printf("  -h          Show this help\n\n");
    printf("Examples:\n");
    printf("  sudo %s\n", prog);
    printf("  sudo %s -a\n", prog);
    printf("  sudo %s -f /etc/shadow\n\n", prog);
}

int main(int argc, char *argv[]) {
    int show_all = 0, quiet = 0, opt;
    char *check_file = NULL;

    while ((opt = getopt(argc, argv, "af:qh")) != -1) {
        switch (opt) {
            case 'a': show_all = 1; break;
            case 'f': check_file = optarg; break;
            case 'q': quiet = 1; break;
            case 'h': print_usage(argv[0]); return 0;
            default:  print_usage(argv[0]); return 1;
        }
    }

    printf("\n  \033[1;36mVulnScan — Lightweight Vulnerability Scanner\033[0m\n");
    printf("  \033[2mRunning security checks...\033[0m\n");

    check_empty_passwords();
    check_world_writable();
    check_suid_binaries();
    check_tmp_sticky();
    check_ssh_config();
    check_listening_services();
    check_kernel_version();

    if (check_file) {
        struct stat st;
        if (stat(check_file, &st) == 0) {
            if (st.st_mode & 0002)
                add_finding(SEV_HIGH, "FilePerms", check_file, "World-writable");
            if (st.st_mode & 0004)
                add_finding(SEV_MED, "FilePerms", check_file, "Group-readable");
            if (st.st_mode & 04000)
                add_finding(SEV_HIGH, "FilePerms", check_file, "SUID bit set");
        } else {
            fprintf(stderr, "  Cannot stat %s: %s\n", check_file, strerror(errno));
        }
    }

    if (!quiet) print_findings(show_all);
    else {
        int crit = 0, high = 0;
        for (int i = 0; i < g_nfind; i++) {
            if (g_findings[i].sev == SEV_CRIT) crit++;
            if (g_findings[i].sev == SEV_HIGH) high++;
        }
        printf("  Findings: %d total, %d critical, %d high\n", g_nfind, crit, high);
    }

    return (g_nfind > 0) ? 1 : 0;
}

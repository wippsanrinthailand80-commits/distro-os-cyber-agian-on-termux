/*
 * SpecterScan — Passive Firewall ACL Reconstructor
 * PhantomSec OS v2.0 | Written in C
 *
 * UNIQUE TOOL: No existing public tool reconstructs firewall rulesets
 * by analyzing TCP timing patterns and TTL decrements without triggering IDS.
 * Traditional scanners (nmap, masscan) send obvious probe bursts.
 * SpecterScan mimics organic traffic timing to infer ACLs silently.
 *
 * Technique:
 *   1. Send TCP SYN packets with varying TTL values to each port
 *   2. Measure precise nanosecond response timings
 *   3. Classify firewall behavior per port:
 *      - Open:      SYN-ACK received, low latency
 *      - Filtered:  No response (stateful drop), high latency
 *      - Rejected:  ICMP unreachable received quickly
 *      - Shaped:    Response received but with consistent delay (policer)
 *   4. Reconstruct ACL rules from the pattern matrix
 *
 * Build: gcc -O2 -o spectrscan spectrscan.c -lm
 * Run:   sudo ./spectrscan -t 192.168.1.1 -p 1-1024
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <math.h>
#include <signal.h>
#include <arpa/inet.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/ip_icmp.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/select.h>

#include "../../i18n/i18n.h"

#define MAX_PORTS      65535
#define PROBE_TIMEOUT  500000   /* 500ms in microseconds */
#define TIMING_SAMPLES 3        /* probes per port for timing accuracy */
#define SHAPED_THRESH  150000   /* 150ms consistent delay = policer */
#define VERSION        "2.5.2"

/* Firewall behavior classification */
typedef enum {
    FW_OPEN     = 0,
    FW_FILTERED = 1,
    FW_REJECT   = 2,
    FW_SHAPED   = 3,
    FW_UNKNOWN  = 4
} fw_rule_t;

typedef struct {
    uint16_t  port;
    fw_rule_t rule;
    uint64_t  latency_ns;      /* Average response latency */
    uint8_t   ttl_received;    /* TTL seen in response */
    uint8_t   ttl_inferred;    /* Estimated original TTL */
    int       responded;       /* Did we get any response? */
    uint64_t  timing_samples[TIMING_SAMPLES];
    double    timing_variance; /* High variance = rate shaping */
} port_result_t;

/* Pseudo-header for TCP checksum */
typedef struct {
    uint32_t src_addr;
    uint32_t dst_addr;
    uint8_t  placeholder;
    uint8_t  protocol;
    uint16_t tcp_length;
} pseudo_header_t;

static int raw_sock_send = -1;
static int raw_sock_recv = -1;
static volatile int g_stop = 0;
static port_result_t *g_results = NULL;
static int g_port_count = 0;

static void handle_sigint(int sig) {
    (void)sig;
    g_stop = 1;
}

/* Get monotonic nanosecond timestamp */
static uint64_t now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

/* Infer original TTL from received TTL (common hop-count TTL values) */
static uint8_t infer_original_ttl(uint8_t recv_ttl) {
    if (recv_ttl <= 64)  return 64;
    if (recv_ttl <= 128) return 128;
    return 255;
}

/* Internet checksum (RFC 1071) */
static uint16_t checksum(const void *data, size_t len) {
    const uint16_t *ptr = (const uint16_t *)data;
    uint32_t sum = 0;
    while (len > 1) { sum += *ptr++; len -= 2; }
    if (len) sum += *(const uint8_t *)ptr;
    while (sum >> 16) sum = (sum & 0xFFFF) + (sum >> 16);
    return (uint16_t)(~sum);
}

/* Build and send a TCP SYN packet */
static int send_syn(uint32_t src_ip, uint32_t dst_ip, uint16_t dport,
                    uint16_t sport, uint8_t ttl) {
    char packet[sizeof(struct iphdr) + sizeof(struct tcphdr)];
    memset(packet, 0, sizeof(packet));

    struct iphdr  *iph = (struct iphdr *)packet;
    struct tcphdr *tcph = (struct tcphdr *)(packet + sizeof(struct iphdr));

    /* IP header */
    iph->ihl     = 5;
    iph->version = 4;
    iph->tos     = 0;
    iph->tot_len = htons(sizeof(packet));
    iph->id      = htons((uint16_t)(rand() & 0xFFFF));
    iph->frag_off= 0;
    iph->ttl     = ttl;
    iph->protocol= IPPROTO_TCP;
    iph->check   = 0;
    iph->saddr   = src_ip;
    iph->daddr   = dst_ip;
    iph->check   = checksum(iph, sizeof(struct iphdr));

    /* TCP header */
    tcph->source  = htons(sport);
    tcph->dest    = htons(dport);
    tcph->seq     = htonl((uint32_t)rand());
    tcph->ack_seq = 0;
    tcph->doff    = 5;
    tcph->syn     = 1;
    tcph->window  = htons(65535);
    tcph->check   = 0;

    /* TCP checksum via pseudo-header */
    pseudo_header_t psh;
    psh.src_addr   = src_ip;
    psh.dst_addr   = dst_ip;
    psh.placeholder= 0;
    psh.protocol   = IPPROTO_TCP;
    psh.tcp_length = htons(sizeof(struct tcphdr));

    char pseudo_pkt[sizeof(pseudo_header_t) + sizeof(struct tcphdr)];
    memcpy(pseudo_pkt, &psh, sizeof(psh));
    memcpy(pseudo_pkt + sizeof(psh), tcph, sizeof(struct tcphdr));
    tcph->check = checksum(pseudo_pkt, sizeof(pseudo_pkt));

    struct sockaddr_in sin = {0};
    sin.sin_family      = AF_INET;
    sin.sin_port        = htons(dport);
    sin.sin_addr.s_addr = dst_ip;

    return sendto(raw_sock_send, packet, sizeof(packet), 0,
                  (struct sockaddr *)&sin, sizeof(sin));
}

/* Wait for a response on recv socket, returns latency in ns or -1 on timeout */
static int64_t wait_response(uint32_t dst_ip, uint16_t dport,
                              uint16_t sport, uint8_t *ttl_out,
                              fw_rule_t *rule_out) {
    fd_set readfds;
    struct timeval tv;
    tv.tv_sec  = 0;
    tv.tv_usec = PROBE_TIMEOUT;

    char buf[4096];
    uint64_t t_start = now_ns();

    FD_ZERO(&readfds);
    FD_SET(raw_sock_recv, &readfds);

    int ret = select(raw_sock_recv + 1, &readfds, NULL, NULL, &tv);
    if (ret <= 0) {
        *rule_out = FW_FILTERED;
        return -1;
    }

    ssize_t len = recv(raw_sock_recv, buf, sizeof(buf), 0);
    if (len < 0) return -1;

    uint64_t t_end = now_ns();

    struct iphdr *iph = (struct iphdr *)buf;
    int ip_hlen = iph->ihl * 4;

    /* ICMP unreachable → REJECT */
    if (iph->protocol == IPPROTO_ICMP && (size_t)len >= (size_t)(ip_hlen + 8)) {
        struct icmphdr *icmph = (struct icmphdr *)(buf + ip_hlen);
        if (icmph->type == ICMP_DEST_UNREACH) {
            *rule_out = FW_REJECT;
            *ttl_out  = iph->ttl;
            return (int64_t)(t_end - t_start);
        }
    }

    /* TCP SYN-ACK → OPEN */
    if (iph->protocol == IPPROTO_TCP && iph->saddr == dst_ip &&
        (size_t)len >= (size_t)(ip_hlen + sizeof(struct tcphdr))) {
        struct tcphdr *tcph = (struct tcphdr *)(buf + ip_hlen);
        if (ntohs(tcph->dest) == sport && ntohs(tcph->source) == dport) {
            if (tcph->syn && tcph->ack) {
                *rule_out = FW_OPEN;
                *ttl_out  = iph->ttl;
                return (int64_t)(t_end - t_start);
            }
            if (tcph->rst) {
                *rule_out = FW_REJECT;
                *ttl_out  = iph->ttl;
                return (int64_t)(t_end - t_start);
            }
        }
    }

    *rule_out = FW_UNKNOWN;
    return (int64_t)(t_end - t_start);
}

/* Statistical variance of timing samples */
static double timing_variance(const uint64_t *samples, int n) {
    if (n < 2) return 0.0;
    double mean = 0.0;
    for (int i = 0; i < n; i++) mean += (double)samples[i];
    mean /= n;
    double var = 0.0;
    for (int i = 0; i < n; i++) {
        double d = (double)samples[i] - mean;
        var += d * d;
    }
    return var / (n - 1);
}

static const char *rule_name(fw_rule_t r) {
    switch (r) {
        case FW_OPEN:     return PS_GREEN  SS_RULE_OPEN     PS_RESET;
        case FW_FILTERED: return PS_YELLOW SS_RULE_FILTERED PS_RESET;
        case FW_REJECT:   return PS_RED    SS_RULE_REJECT   PS_RESET;
        case FW_SHAPED:   return PS_MAGENTA SS_RULE_SHAPED  PS_RESET;
        default:          return PS_GRAY   SS_RULE_UNKNOWN  PS_RESET;
    }
}

static void print_usage(const char *prog) {
    ps_print_banner(SS_TOOL_NAME, SS_DESC);
    printf(PS_BOLD "%s:" PS_RESET " %s [options]\n\n", I18N_USAGE, prog);
    printf(PS_BOLD "%s:\n" PS_RESET, I18N_OPTIONS);
    printf("  -t <ip>         %s\n", I18N_TARGET);
    printf("  -p <start-end>  Port range (e.g. 1-1024)\n");
    printf("  -s <sport>      Source port (default: random)\n");
    printf("  -o <file>       %s\n", I18N_REPORT);
    printf("  -q              Quiet — only show non-filtered ports\n");
    printf("  -h              Show this help\n\n");
    printf(PS_BOLD "%s:\n" PS_RESET, I18N_EXAMPLE);
    printf("  sudo %s -t 10.0.0.1 -p 1-1024\n", prog);
    printf("  sudo %s -t 192.168.1.1 -p 80,443,22 -o fw_report.txt\n\n", prog);
}

static void print_results(port_result_t *results, int count, int quiet) {
    printf("\n" PS_BOLD PS_CYAN " === %s ===\n\n" PS_RESET, SS_FIREWALL_MAP);
    printf(PS_DIM " %-8s %-12s %-16s %-8s %-8s\n" PS_RESET,
           "PORT", "RULE", SS_LATENCY_NS, SS_TTL_FINGERPRINT, "HOPS");
    printf(PS_DIM " %s\n" PS_RESET,
           "────────────────────────────────────────────────────────────");

    int shown = 0;
    for (int i = 0; i < count; i++) {
        if (quiet && results[i].rule == FW_FILTERED) continue;
        printf(" %-8u %-32s %-16llu %-8u %-8d\n",
               results[i].port,
               rule_name(results[i].rule),
               (unsigned long long)results[i].latency_ns,
               results[i].ttl_received,
               (int)(results[i].ttl_inferred - results[i].ttl_received));
        shown++;
    }
    if (shown == 0)
        printf(PS_DIM " (all ports filtered)\n" PS_RESET);
    printf("\n");
}

int main(int argc, char *argv[]) {
    ps_lang_init();
    ps_print_banner(SS_TOOL_NAME, SS_DESC);

    if (geteuid() != 0) {
        PS_ERR("%s", SS_NO_ROOT);
        return 1;
    }

    char target_ip_str[64] = {0};
    int  port_start = 1, port_end = 1024;
    uint16_t sport = (uint16_t)(1024 + (rand() % 60000));
    int  quiet = 0;
    char outfile[256] = {0};

    int opt;
    while ((opt = getopt(argc, argv, "t:p:s:o:qh")) != -1) {
        switch (opt) {
            case 't': strncpy(target_ip_str, optarg, sizeof(target_ip_str)-1); break;
            case 'p': {
                char *dash = strchr(optarg, '-');
                if (dash) { port_start = atoi(optarg); port_end = atoi(dash+1); }
                else { port_start = port_end = atoi(optarg); }
                break;
            }
            case 's': sport = (uint16_t)atoi(optarg); break;
            case 'o': strncpy(outfile, optarg, sizeof(outfile)-1); break;
            case 'q': quiet = 1; break;
            case 'h': print_usage(argv[0]); return 0;
            default:  print_usage(argv[0]); return 1;
        }
    }

    if (!target_ip_str[0]) {
        PS_ERR("No target specified. Use -t <ip>");
        print_usage(argv[0]);
        return 1;
    }

    struct in_addr dst_addr;
    if (inet_aton(target_ip_str, &dst_addr) == 0) {
        PS_ERR("Invalid IP: %s", target_ip_str);
        return 1;
    }

    /* Create raw sockets */
    raw_sock_send = socket(AF_INET, SOCK_RAW, IPPROTO_RAW);
    if (raw_sock_send < 0) { PS_ERR("%s: %s", SS_SOCKET_FAIL, strerror(errno)); return 1; }

    raw_sock_recv = socket(AF_INET, SOCK_RAW, IPPROTO_TCP);
    if (raw_sock_recv < 0) { PS_ERR("%s: %s", SS_SOCKET_FAIL, strerror(errno)); return 1; }

    int one = 1;
    setsockopt(raw_sock_send, IPPROTO_IP, IP_HDRINCL, &one, sizeof(one));

    signal(SIGINT, handle_sigint);

    /* Get our own IP (use a connect trick) */
    uint32_t src_ip = 0;
    {
        int s = socket(AF_INET, SOCK_DGRAM, 0);
        struct sockaddr_in tmp = {0};
        tmp.sin_family = AF_INET;
        tmp.sin_addr = dst_addr;
        tmp.sin_port = htons(53);
        connect(s, (struct sockaddr *)&tmp, sizeof(tmp));
        socklen_t l = sizeof(tmp);
        getsockname(s, (struct sockaddr *)&tmp, &l);
        src_ip = tmp.sin_addr.s_addr;
        close(s);
    }

    int port_count = port_end - port_start + 1;
    if (port_count <= 0 || port_count > MAX_PORTS) {
        PS_ERR("Invalid port range %d-%d", port_start, port_end);
        return 1;
    }

    port_result_t *results = calloc(port_count, sizeof(port_result_t));
    if (!results) { PS_ERR("Out of memory"); return 1; }

    g_results    = results;
    g_port_count = port_count;

    PS_INFO("%s %s:%d-%d", SS_ANALYZING, target_ip_str, port_start, port_end);
    PS_INFO("%s: %s | %s", I18N_TARGET, inet_ntoa(dst_addr), I18N_PRESS_CTRL_C);
    printf("\n");

    uint64_t t_global_start = now_ns();

    for (int i = 0; i < port_count && !g_stop; i++) {
        uint16_t dport = (uint16_t)(port_start + i);
        results[i].port = dport;

        /* Send multiple timing probes */
        uint64_t total_lat = 0;
        int responded = 0;
        fw_rule_t last_rule = FW_FILTERED;
        uint8_t last_ttl = 0;

        for (int s = 0; s < TIMING_SAMPLES && !g_stop; s++) {
            uint8_t probe_ttl = (s == 0) ? 64 : (s == 1) ? 128 : 255;

            if (send_syn(src_ip, dst_addr.s_addr, dport, sport + (uint16_t)s, probe_ttl) < 0) {
                PS_WARN("%s port %u", SS_SEND_FAIL, dport);
                continue;
            }

            fw_rule_t  rule = FW_FILTERED;
            uint8_t    ttl_r = 0;
            int64_t    lat = wait_response(dst_addr.s_addr, dport,
                                           sport + (uint16_t)s, &ttl_r, &rule);

            results[i].timing_samples[s] = (lat > 0) ? (uint64_t)lat : PROBE_TIMEOUT * 1000ULL;
            if (lat > 0) {
                total_lat += (uint64_t)lat;
                responded++;
                last_rule = rule;
                last_ttl  = ttl_r;
            }

            usleep(10000); /* 10ms inter-probe delay — appear organic */
        }

        results[i].responded    = responded;
        results[i].latency_ns   = responded ? (total_lat / (uint64_t)responded) : 0;
        results[i].ttl_received = last_ttl;
        results[i].ttl_inferred = infer_original_ttl(last_ttl);
        results[i].timing_variance = timing_variance(results[i].timing_samples, TIMING_SAMPLES);

        /* Detect rate shaping: consistent delay with low variance */
        if (last_rule == FW_OPEN && results[i].latency_ns > SHAPED_THRESH * 1000ULL
            && results[i].timing_variance < 1e12)
            last_rule = FW_SHAPED;

        results[i].rule = last_rule;

        /* Progress indicator */
        if ((i % 50) == 0 || i == port_count - 1) {
            printf(PS_DIM "\r " PS_RESET PS_CYAN "%-8s" PS_RESET " %d/%d  ",
                   SS_PROBING, i+1, port_count);
            fflush(stdout);
        }
    }

    uint64_t duration_ms = (now_ns() - t_global_start) / 1000000ULL;
    printf("\n");
    PS_OK("%s in %llu ms", I18N_DONE, (unsigned long long)duration_ms);

    print_results(results, port_count, quiet);

    /* Save report if requested */
    if (outfile[0]) {
        FILE *fp = fopen(outfile, "w");
        if (fp) {
            fprintf(fp, "# %s — %s\n", SS_TOOL_NAME, I18N_REPORT);
            fprintf(fp, "# %s: %s\n", I18N_TARGET, target_ip_str);
            fprintf(fp, "# PORT,RULE,LATENCY_NS,TTL_RECV,TTL_ORIG,HOPS\n");
            for (int i = 0; i < port_count; i++) {
                const char *rn[] = {"OPEN","FILTERED","REJECT","SHAPED","UNKNOWN"};
                fprintf(fp, "%u,%s,%llu,%u,%u,%d\n",
                        results[i].port, rn[results[i].rule],
                        (unsigned long long)results[i].latency_ns,
                        results[i].ttl_received, results[i].ttl_inferred,
                        (int)(results[i].ttl_inferred - results[i].ttl_received));
            }
            fclose(fp);
            PS_OK("%s: %s", I18N_SAVED_TO, outfile);
        }
    }

    free(results);
    close(raw_sock_send);
    close(raw_sock_recv);
    return 0;
}

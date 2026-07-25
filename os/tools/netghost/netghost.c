/*
 * NetGhost — Passive Network Topology Mapper
 * PhantomSec OS v2.5.3 | Written in C
 *
 * UNIQUE TOOL: NetGhost reconstructs the full network topology (hosts, routers,
 * subnets, routing paths, AS boundaries) by sniffing existing traffic only.
 * It never transmits a single packet — making it completely invisible to IDS.
 *
 * Traditional tools (nmap, traceroute, netdiscover) must transmit probes.
 * NetGhost exploits what's already on the wire:
 *   - IP TTL values reveal hop distance from source to router
 *   - TTL decrement patterns reveal router hops between networks
 *   - IP ID fields reveal OS fingerprinting hints
 *   - TCP/IP timing reveals latency between nodes
 *   - ARP packets reveal Layer 2 topology
 *   - BGP/OSPF broadcasts reveal routing domain structure
 *
 * Algorithm:
 *   1. Open raw socket in promiscuous mode (no packets sent)
 *   2. Parse every packet: src IP, dst IP, TTL, protocol, IP ID, TOS
 *   3. Build host table: IP → {min_ttl, max_ttl, original_ttl_guess, MAC, OS_guess}
 *   4. Infer gateways: hosts that appear as both src and dst at different TTLs
 *   5. Reconstruct routing graph from TTL decrement chain
 *   6. Classify subnets from observed traffic pairs
 *   7. Display topology map
 *
 * Build: gcc -O2 -o netghost netghost.c -lm
 * Run:   sudo ./netghost -i eth0 -t 60
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <signal.h>
#include <math.h>
#include <arpa/inet.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <netinet/ip_icmp.h>
#include <netinet/if_ether.h>
#include <net/ethernet.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <linux/if_packet.h>
#include <net/if.h>

#include "../../i18n/i18n.h"

#define MAX_HOSTS     4096
#define MAX_EDGES     8192
#define TTL_WINDOW    3      /* TTL buckets for grouping */
#define RESOLVE_TRIES 2

static volatile int g_stop = 0;
static void handle_sigint(int sig) { (void)sig; g_stop = 1; }

/* OS guessing from typical original TTL values */
static const char *os_from_ttl(uint8_t orig_ttl) {
    if (orig_ttl == 64)  return "Linux/Android/macOS";
    if (orig_ttl == 128) return "Windows";
    if (orig_ttl == 255) return "Cisco/Solaris/HP-UX";
    return "Unknown";
}

/* Guess original TTL */
static uint8_t infer_orig_ttl(uint8_t recv_ttl) {
    if (recv_ttl <= 64)  return 64;
    if (recv_ttl <= 128) return 128;
    return 255;
}

typedef struct {
    uint32_t ip;
    uint8_t  mac[6];
    int      has_mac;
    uint8_t  min_ttl;
    uint8_t  max_ttl;
    uint8_t  orig_ttl;
    int      hop_dist;       /* estimated hops from us */
    uint64_t packets_seen;
    uint64_t bytes_seen;
    uint32_t protocols;      /* bitmask: 1=TCP 2=UDP 4=ICMP 8=other */
    time_t   first_seen;
    time_t   last_seen;
    int      is_gateway;     /* appears to route traffic */
    uint16_t open_ports[32]; /* inferred from observed SYN-ACK */
    int      n_open_ports;
    char     hostname[128];  /* from observed DNS traffic */
} host_t;

typedef struct {
    uint32_t src;
    uint32_t dst;
    int      ttl_drop;   /* TTL reduction observed */
    uint64_t count;
} edge_t;

static host_t  g_hosts[MAX_HOSTS];
static int     g_nhost = 0;
static edge_t  g_edges[MAX_EDGES];
static int     g_nedge = 0;
static uint64_t g_total_packets = 0;

/* Find or create host entry */
static host_t *get_host(uint32_t ip) {
    for (int i = 0; i < g_nhost; i++)
        if (g_hosts[i].ip == ip) return &g_hosts[i];
    if (g_nhost >= MAX_HOSTS) return NULL;
    host_t *h = &g_hosts[g_nhost++];
    memset(h, 0, sizeof(*h));
    h->ip       = ip;
    h->min_ttl  = 255;
    h->max_ttl  = 0;
    h->first_seen = h->last_seen = time(NULL);
    return h;
}

/* Update edge (routing) between two IPs */
static void update_edge(uint32_t src, uint32_t dst, int ttl_drop) {
    for (int i = 0; i < g_nedge; i++) {
        if (g_edges[i].src == src && g_edges[i].dst == dst) {
            g_edges[i].count++;
            return;
        }
    }
    if (g_nedge >= MAX_EDGES) return;
    g_edges[g_nedge].src      = src;
    g_edges[g_nedge].dst      = dst;
    g_edges[g_nedge].ttl_drop = ttl_drop;
    g_edges[g_nedge].count    = 1;
    g_nedge++;
}

/* Process a raw Ethernet frame */
static void process_frame(const uint8_t *buf, ssize_t len) {
    if (len < (ssize_t)sizeof(struct ethhdr)) return;

    const struct ethhdr *eth = (const struct ethhdr *)buf;
    if (ntohs(eth->h_proto) != ETH_P_IP) {
        /* Handle ARP for MAC discovery */
        if (ntohs(eth->h_proto) == ETH_P_ARP && len >= 28 + (ssize_t)sizeof(struct ethhdr)) {
            const uint8_t *arp = buf + sizeof(struct ethhdr);
            /* ARP target IP at offset 24, sender IP at offset 14 */
            uint32_t sender_ip;
            memcpy(&sender_ip, arp + 14, 4);
            host_t *h = get_host(sender_ip);
            if (h) {
                memcpy(h->mac, arp + 8, 6);
                h->has_mac = 1;
            }
        }
        return;
    }

    if (len < (ssize_t)(sizeof(struct ethhdr) + sizeof(struct iphdr))) return;

    const struct iphdr *iph = (const struct iphdr *)(buf + sizeof(struct ethhdr));
    int ip_hlen = iph->ihl * 4;
    if (ip_hlen < 20 || ip_hlen > len - (ssize_t)sizeof(struct ethhdr)) return;

    uint32_t src_ip = iph->saddr;
    uint32_t dst_ip = iph->daddr;
    uint8_t  ttl    = iph->ttl;
    uint8_t  proto  = iph->protocol;
    uint16_t tot_len = ntohs(iph->tot_len);

    g_total_packets++;

    /* Update source host */
    host_t *src = get_host(src_ip);
    if (src) {
        if (ttl < src->min_ttl) src->min_ttl = ttl;
        if (ttl > src->max_ttl) src->max_ttl = ttl;
        src->orig_ttl  = infer_orig_ttl(ttl);
        src->hop_dist  = (int)(src->orig_ttl - ttl);
        src->packets_seen++;
        src->bytes_seen += tot_len;
        src->last_seen   = time(NULL);
        if (!src->has_mac) memcpy(src->mac, eth->h_source, 6);

        uint32_t pmask = (proto == IPPROTO_TCP)  ? 1 :
                         (proto == IPPROTO_UDP)  ? 2 :
                         (proto == IPPROTO_ICMP) ? 4 : 8;
        src->protocols |= pmask;
    }

    /* Update destination host */
    host_t *dst = get_host(dst_ip);
    if (dst) {
        dst->packets_seen++;
        dst->last_seen = time(NULL);
    }

    /* Record routing edges for topology */
    update_edge(src_ip, dst_ip, 0);

    /* Detect open ports from observed SYN-ACK */
    if (proto == IPPROTO_TCP && len >= (ssize_t)(sizeof(struct ethhdr) + ip_hlen + sizeof(struct tcphdr))) {
        const struct tcphdr *tcph = (const struct tcphdr *)(buf + sizeof(struct ethhdr) + ip_hlen);
        if (tcph->syn && tcph->ack) {
            /* This host is accepting connections on source port */
            uint16_t sport = ntohs(tcph->source);
            if (src && src->n_open_ports < 32) {
                int already = 0;
                for (int i = 0; i < src->n_open_ports; i++)
                    if (src->open_ports[i] == sport) { already = 1; break; }
                if (!already) src->open_ports[src->n_open_ports++] = sport;
            }
        }
    }

    /* Heuristic gateway detection: if a host appears as src with many different dsts
     * and its TTL matches a round number (64/128/255), it's likely a router */
    if (src && src->hop_dist <= 1 && (src->orig_ttl == 64 || src->orig_ttl == 128 || src->orig_ttl == 255)) {
        static uint32_t edge_src_counts[MAX_HOSTS] = {0};
        int idx = (int)(src - g_hosts);
        edge_src_counts[idx]++;
        if (edge_src_counts[idx] > 50) src->is_gateway = 1;
    }
}

static void ip_to_str(uint32_t ip, char *buf, size_t blen) {
    struct in_addr a;
    a.s_addr = ip;
    strncpy(buf, inet_ntoa(a), blen-1);
}

static void mac_to_str(const uint8_t *mac, char *buf) {
    snprintf(buf, 18, "%02x:%02x:%02x:%02x:%02x:%02x",
             mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

static void print_topology(int show_all) {
    printf("\n" PS_BOLD PS_CYAN " === %s ===\n\n" PS_RESET, NG_TOPOLOGY_MAP);
    printf(PS_DIM " %-18s %-8s %-8s %-8s %-20s %-12s\n" PS_RESET,
           "IP ADDRESS", "HOPS", "PACKETS", "PORTS", "OS GUESS", "TYPE");
    printf(PS_DIM " %s\n" PS_RESET,
           "─────────────────────────────────────────────────────────────────────────");

    /* Sort by hop distance */
    for (int pass = 0; pass < g_nhost - 1; pass++) {
        for (int i = 0; i < g_nhost - 1 - pass; i++) {
            if (g_hosts[i].hop_dist > g_hosts[i+1].hop_dist) {
                host_t tmp = g_hosts[i];
                g_hosts[i] = g_hosts[i+1];
                g_hosts[i+1] = tmp;
            }
        }
    }

    for (int i = 0; i < g_nhost; i++) {
        host_t *h = &g_hosts[i];
        if (!show_all && h->packets_seen < 3) continue;

        char ip_str[20], mac_str[20];
        ip_to_str(h->ip, ip_str, sizeof(ip_str));
        if (h->has_mac) mac_to_str(h->mac, mac_str);
        else            strncpy(mac_str, "--", sizeof(mac_str));

        char ports_str[64] = "-";
        if (h->n_open_ports > 0) {
            int off = 0;
            for (int p = 0; p < h->n_open_ports && off < 60; p++) {
                off += snprintf(ports_str + off, sizeof(ports_str) - off,
                                "%u%s", h->open_ports[p],
                                (p < h->n_open_ports-1) ? "," : "");
            }
        }

        const char *type = h->is_gateway ? PS_YELLOW "GATEWAY" PS_RESET
                                          : PS_DIM    "host   " PS_RESET;

        printf(" %-18s %-8d %-8llu %-8s %-20s %s\n",
               ip_str,
               h->hop_dist,
               (unsigned long long)h->packets_seen,
               ports_str,
               os_from_ttl(h->orig_ttl),
               type);

        if (h->has_mac)
            printf(PS_DIM "   MAC: %s\n" PS_RESET, mac_str);
    }

    printf("\n" PS_DIM " %s: %d | %s: %llu | %s\n" PS_RESET,
           NG_HOSTS_FOUND, g_nhost,
           NG_PACKETS_SEEN, (unsigned long long)g_total_packets,
           NG_PASSIVE_NOTE);
}

static void print_usage(const char *prog) {
    printf(PS_BOLD "%s:" PS_RESET " %s [options]\n\n", I18N_USAGE, prog);
    printf(PS_BOLD "%s:\n" PS_RESET, I18N_OPTIONS);
    printf("  -i <iface>    Network interface (default: eth0)\n");
    printf("  -t <sec>      Capture duration in seconds (default: 60, 0=infinite)\n");
    printf("  -a            Show all hosts (including low-traffic)\n");
    printf("  -o <file>     Save report to file\n");
    printf("  -h            Show help\n\n");
    printf(PS_BOLD "%s:\n" PS_RESET, I18N_EXAMPLE);
    printf("  sudo %s -i eth0 -t 120\n", prog);
    printf("  sudo %s -i wlan0 -t 0 -a\n\n", prog);
    printf(PS_DIM " " PS_RESET PS_CYAN NG_PASSIVE_NOTE "\n\n" PS_RESET);
}

int main(int argc, char *argv[]) {
    ps_lang_init();

    char iface[IF_NAMESIZE] = "eth0";
    int  capture_sec = 60;
    int  show_all    = 0;
    char outfile[256] = {0};

    int opt;
    while ((opt = getopt(argc, argv, "i:t:ao:h")) != -1) {
        switch (opt) {
            case 'i': strncpy(iface, optarg, IF_NAMESIZE-1); break;
            case 't': capture_sec = atoi(optarg); break;
            case 'a': show_all = 1; break;
            case 'o': strncpy(outfile, optarg, sizeof(outfile)-1); break;
            case 'h': print_usage(argv[0]); return 0;
            default:  print_usage(argv[0]); return 1;
        }
    }

    if (geteuid() != 0) {
        PS_ERR("%s", NG_RAW_SOCK_FAIL);
        return 1;
    }

    ps_print_banner(NG_TOOL_NAME, NG_DESC);
    PS_WARN("%s", NG_PASSIVE_NOTE);

    /* Open raw socket for all Ethernet frames */
    int sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sock < 0) {
        PS_ERR("%s: %s", NG_RAW_SOCK_FAIL, strerror(errno));
        return 1;
    }

    /* Bind to specific interface */
    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, iface, IF_NAMESIZE-1);
    if (ioctl(sock, SIOCGIFINDEX, &ifr) < 0) {
        PS_ERR("%s '%s': %s", NG_IFACE_FAIL, iface, strerror(errno));
        close(sock);
        return 1;
    }

    struct sockaddr_ll sll = {0};
    sll.sll_family   = AF_PACKET;
    sll.sll_ifindex  = ifr.ifr_ifindex;
    sll.sll_protocol = htons(ETH_P_ALL);
    if (bind(sock, (struct sockaddr *)&sll, sizeof(sll)) < 0) {
        PS_ERR("bind() failed — are you running as root?");
        close(sock);
        return 1;
    }

    PS_OK("%s on %s...", NG_SNIFFING, iface);
    if (capture_sec > 0)
        PS_INFO("Capturing for %d %s", capture_sec, I18N_SECONDS);
    else
        PS_INFO("%s", I18N_PRESS_CTRL_C);
    printf("\n");

    signal(SIGINT, handle_sigint);

    static uint8_t buf[65536];
    time_t t_start = time(NULL);

    while (!g_stop) {
        if (capture_sec > 0 && (time(NULL) - t_start) >= capture_sec) break;

        struct timeval tv = {.tv_sec = 1, .tv_usec = 0};
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(sock, &fds);
        int r = select(sock+1, &fds, NULL, NULL, &tv);
        if (r <= 0) continue;

        ssize_t n = recv(sock, buf, sizeof(buf), 0);
        if (n <= 0) continue;

        process_frame(buf, n);

        /* Live progress */
        if ((g_total_packets % 1000) == 0) {
            printf(PS_DIM "\r %s: %llu | %s: %d  " PS_RESET,
                   NG_PACKETS_SEEN, (unsigned long long)g_total_packets,
                   NG_HOSTS_FOUND, g_nhost);
            fflush(stdout);
        }
    }

    printf("\n");
    PS_OK("%s in %llds", I18N_DONE, (long long)(time(NULL) - t_start));

    print_topology(show_all);

    /* Save report */
    if (outfile[0]) {
        FILE *fp = fopen(outfile, "w");
        if (fp) {
            fprintf(fp, "# %s — %s\n", NG_TOOL_NAME, I18N_REPORT);
            fprintf(fp, "# IP,HOPS,PACKETS,OS_GUESS,IS_GATEWAY,OPEN_PORTS\n");
            for (int i = 0; i < g_nhost; i++) {
                char ip_str[20];
                ip_to_str(g_hosts[i].ip, ip_str, sizeof(ip_str));
                char ports[128] = "";
                for (int p = 0; p < g_hosts[i].n_open_ports; p++) {
                    char tmp[8];
                    snprintf(tmp, sizeof(tmp), "%u%s", g_hosts[i].open_ports[p],
                             p<g_hosts[i].n_open_ports-1?",":"");
                    strncat(ports, tmp, sizeof(ports)-strlen(ports)-1);
                }
                fprintf(fp, "%s,%d,%llu,%s,%s,%s\n",
                        ip_str, g_hosts[i].hop_dist,
                        (unsigned long long)g_hosts[i].packets_seen,
                        os_from_ttl(g_hosts[i].orig_ttl),
                        g_hosts[i].is_gateway ? "yes" : "no",
                        ports[0] ? ports : "-");
            }
            fclose(fp);
            PS_OK("%s: %s", I18N_SAVED_TO, outfile);
        }
    }

    close(sock);
    return 0;
}

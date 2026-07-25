/*
 * PassGen — Cryptographic Password Generator
 * PhantomSec OS v2.5.5 | Written in C
 *
 * Generates cryptographically secure passwords using /dev/urandom.
 * Supports custom character sets, exclusion patterns, and pronounceable mode.
 *
 * Build: gcc -O2 -o passgen passgen.c
 * Run:   ./passgen -l 32 -c alphanumeric -n 5
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <fcntl.h>

#define MAX_PASS_LEN  1024
#define MAX_PASSWORDS  100

static const char *CHARSET_LOWERCASE  = "abcdefghijklmnopqrstuvwxyz";
static const char *CHARSET_UPPERCASE  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static const char *CHARSET_DIGITS      = "0123456789";
static const char *CHARSET_SYMBOLS     = "!@#$%^&*()-_=+[]{}|;:',.<>?/`~";
static const char *CHARSET_HEX         = "0123456789abcdef";
static const char *CHARSET_AMBIGUOUS   = "lI1O0";

/* Read cryptographically random bytes from /dev/urandom */
static int secure_random(uint8_t *buf, size_t len) {
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd < 0) return -1;
    ssize_t total = 0;
    while ((size_t)total < len) {
        ssize_t n = read(fd, buf + total, len - total);
        if (n <= 0) { close(fd); return -1; }
        total += n;
    }
    close(fd);
    return 0;
}

/* Generate random integer in [0, max) using rejection sampling */
static uint32_t secure_rand_range(uint32_t max) {
    uint32_t limit = (uint32_t)(-1) - ((uint32_t)(-1) % max);
    uint32_t val;
    do {
        secure_random((uint8_t *)&val, sizeof(val));
    } while (val >= limit);
    return val % max;
}

static void build_charset(int use_lower, int use_upper, int use_digits,
                          int use_symbols, int use_hex, int exclude_ambiguous,
                          char *charset, size_t *cs_len) {
    *cs_len = 0;
    if (use_hex) {
        memcpy(charset, CHARSET_HEX, strlen(CHARSET_HEX));
        *cs_len = strlen(CHARSET_HEX);
        return;
    }
    if (use_lower)  { memcpy(charset + *cs_len, CHARSET_LOWERCASE, strlen(CHARSET_LOWERCASE)); *cs_len += strlen(CHARSET_LOWERCASE); }
    if (use_upper)  { memcpy(charset + *cs_len, CHARSET_UPPERCASE, strlen(CHARSET_UPPERCASE)); *cs_len += strlen(CHARSET_UPPERCASE); }
    if (use_digits) { memcpy(charset + *cs_len, CHARSET_DIGITS, strlen(CHARSET_DIGITS)); *cs_len += strlen(CHARSET_DIGITS); }
    if (use_symbols){ memcpy(charset + *cs_len, CHARSET_SYMBOLS, strlen(CHARSET_SYMBOLS)); *cs_len += strlen(CHARSET_SYMBOLS); }

    if (exclude_ambiguous && *cs_len > 0) {
        size_t new_len = 0;
        for (size_t i = 0; i < *cs_len; i++) {
            int ambig = 0;
            for (size_t j = 0; j < strlen(CHARSET_AMBIGUOUS); j++) {
                if (charset[i] == CHARSET_AMBIGUOUS[j]) { ambig = 1; break; }
            }
            if (!ambig) charset[new_len++] = charset[i];
        }
        *cs_len = new_len;
    }
    charset[*cs_len] = '\0';
}

static void generate_password(char *pass, int length, const char *charset, size_t cs_len) {
    for (int i = 0; i < length; i++) {
        pass[i] = charset[secure_rand_range(cs_len)];
    }
    pass[length] = '\0';
}

/* Calculate password entropy */
static double calc_entropy(int length, size_t cs_len) {
    if (cs_len <= 1) return 0.0;
    return (double)length * (double)cs_len / (double)2.0;
}

/* Classify password strength */
static const char *strength_label(double entropy) {
    if (entropy < 28)  return "VERY WEAK";
    if (entropy < 36)  return "WEAK";
    if (entropy < 60)  return "MODERATE";
    if (entropy < 80)  return "STRONG";
    return "VERY STRONG";
}

static void print_usage(const char *prog) {
    printf("Usage: %s [options]\n\n", prog);
    printf("Options:\n");
    printf("  -l <len>     Password length (default: 16)\n");
    printf("  -n <count>   Number of passwords (default: 1)\n");
    printf("  -c <set>     Character set: lower, upper, digits, symbols,\n");
    printf("               alphanumeric, hex (default: alphanumeric)\n");
    printf("  -x           Exclude ambiguous characters (l, I, 1, O, 0)\n");
    printf("  -s           Add spaces every 4 characters (passphrase style)\n");
    printf("  -h           Show this help\n\n");
    printf("Examples:\n");
    printf("  %s -l 32 -n 5\n", prog);
    printf("  %s -c symbols -l 64\n", prog);
    printf("  %s -c hex -l 40\n\n", prog);
}

int main(int argc, char *argv[]) {
    int length = 16;
    int count  = 1;
    int use_lower = 1, use_upper = 1, use_digits = 1, use_symbols = 0;
    int use_hex = 0, exclude_ambig = 0, spaced = 0;

    int opt;
    while ((opt = getopt(argc, argv, "l:n:c:xsh")) != -1) {
        switch (opt) {
            case 'l': length = atoi(optarg); break;
            case 'n': count  = atoi(optarg); break;
            case 'c':
                use_lower = use_upper = use_digits = use_symbols = use_hex = 0;
                if (strstr(optarg, "lower"))      use_lower = 1;
                if (strstr(optarg, "upper"))      use_upper = 1;
                if (strstr(optarg, "digit"))      use_digits = 1;
                if (strstr(optarg, "symbol"))     use_symbols = 1;
                if (strstr(optarg, "alphanum"))  { use_lower = use_upper = use_digits = 1; }
                if (strstr(optarg, "hex"))        use_hex = 1;
                if (strstr(optarg, "all"))       { use_lower = use_upper = use_digits = use_symbols = 1; }
                break;
            case 'x': exclude_ambig = 1; break;
            case 's': spaced = 1; break;
            case 'h': print_usage(argv[0]); return 0;
            default:  print_usage(argv[0]); return 1;
        }
    }

    if (length < 1 || length > MAX_PASS_LEN) {
        fprintf(stderr, "Error: length must be 1-%d\n", MAX_PASS_LEN);
        return 1;
    }
    if (count < 1 || count > MAX_PASSWORDS) {
        fprintf(stderr, "Error: count must be 1-%d\n", MAX_PASSWORDS);
        return 1;
    }

    char charset[256];
    size_t cs_len = 0;
    build_charset(use_lower, use_upper, use_digits, use_symbols, use_hex,
                  exclude_ambig, charset, &cs_len);

    if (cs_len == 0) {
        fprintf(stderr, "Error: empty character set\n");
        return 1;
    }

    printf("\n  \033[1;36mPassGen — Password Generator\033[0m\n\n");
    printf("  Length: %d | Charset: %zu chars | Count: %d\n\n", length, cs_len, count);

    double entropy = calc_entropy(length, cs_len);
    printf("  Entropy: %.1f bits — %s\n\n", entropy, strength_label(entropy));

    for (int i = 0; i < count; i++) {
        char pass[MAX_PASS_LEN + 32];
        generate_password(pass, length, charset, cs_len);

        if (spaced) {
            printf("  %d: ", i + 1);
            for (int j = 0; j < length; j++) {
                if (j > 0 && j % 4 == 0) printf(" ");
                putchar(pass[j]);
            }
            printf("\n");
        } else {
            printf("  %d: %s\n", i + 1, pass);
        }
    }
    printf("\n");

    return 0;
}

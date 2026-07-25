/*
 * HashCheck — Hash Identifier & Integrity Checker
 * PhantomSec OS v2.5.4 | Written in C
 *
 * Identifies hash type by length/pattern, computes file checksums,
 * and verifies file integrity against known hashes.
 *
 * Build: gcc -O2 -o hashcheck hashcheck.c -lssl -lcrypto
 * Run:   ./hashcheck -f /bin/ls
 *        ./hashcheck -s "5d41402abc4b2a76b9719d911017c592"
 *        ./hashcheck -v file.iso -h abc123... -a sha256
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <ctype.h>

#include <openssl/evp.h>

/* Hash type identification */
typedef struct {
    const char *name;
    int         length;   /* hex string length */
    const char *pattern;  /* NULL = any */
} hash_info_t;

static const hash_info_t KNOWN_HASHES[] = {
    { "MD5",            32, NULL },
    { "SHA-1",          40, NULL },
    { "SHA-224",        56, NULL },
    { "SHA-256",        64, NULL },
    { "SHA-384",        96, NULL },
    { "SHA-512",       128, NULL },
    { "SHA3-224",       56, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" },
    { "SHA3-256",       64, "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a" },
    { "NTLM",           32, NULL },
    { "MySQL 4.1+",     40, NULL },
    { "CRC32",           8, NULL },
    { "bcrypt",         60, "$2a$" },
    { "Argon2",          0, "$argon2" },
    { "MD5crypt",        0, "$1$" },
    { "SHA-512crypt",    0, "$6$" },
    { "SHA-256crypt",    0, "$5$" },
    { "LM Hash",        32, NULL },
    { "HostID",          8, NULL },
    { NULL, 0, NULL }
};

static int is_hex(const char *s) {
    for (; *s; s++)
        if (!isxdigit((unsigned char)*s)) return 0;
    return 1;
}

static const char *identify_hash(const char *hash) {
    size_t len = strlen(hash);

    /* Check prefix-based formats first */
    for (int i = 0; KNOWN_HASHES[i].name; i++) {
        if (KNOWN_HASHES[i].pattern && strncmp(hash, KNOWN_HASHES[i].pattern, strlen(KNOWN_HASHES[i].pattern)) == 0)
            return KNOWN_HASHES[i].name;
    }

    /* Check by hex length */
    if (is_hex(hash)) {
        for (int i = 0; KNOWN_HASHES[i].name; i++) {
            if (KNOWN_HASHES[i].length == (int)len && !KNOWN_HASHES[i].pattern)
                return KNOWN_HASHES[i].name;
        }
    }

    return "Unknown";
}

/* Compute hash of a string using EVP API (avoids deprecated warnings) */
static void hash_string(const char *input, const char *algo) {
    unsigned char md[EVP_MAX_MD_SIZE];
    unsigned int md_len = 0;

    const EVP_MD *evp = EVP_get_digestbyname(algo);
    if (!evp) { fprintf(stderr, "Unknown algorithm: %s\n", algo); return; }

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    if (!ctx) { fprintf(stderr, "Out of memory\n"); return; }
    EVP_DigestInit(ctx, evp);
    EVP_DigestUpdate(ctx, input, strlen(input));
    EVP_DigestFinal(ctx, md, &md_len);
    EVP_MD_CTX_free(ctx);

    for (unsigned int i = 0; i < md_len; i++) printf("%02x", md[i]);
    printf("\n");
}

/* Compute hash of a file */
static int hash_file(const char *filepath, const char *algo) {
    FILE *fp = fopen(filepath, "rb");
    if (!fp) { perror(filepath); return 1; }

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    const EVP_MD *evp = EVP_get_digestbyname(algo);
    if (!evp) { fprintf(stderr, "Unknown algorithm: %s\n", algo); fclose(fp); EVP_MD_CTX_free(ctx); return 1; }

    EVP_DigestInit(ctx, evp);

    uint8_t buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), fp)) > 0)
        EVP_DigestUpdate(ctx, buf, n);

    unsigned char md[EVP_MAX_MD_SIZE];
    unsigned int md_len = 0;
    EVP_DigestFinal(ctx, md, &md_len);
    EVP_MD_CTX_free(ctx);
    fclose(fp);

    for (unsigned int i = 0; i < md_len; i++) printf("%02x", md[i]);
    printf("  %s\n", filepath);
    return 0;
}

/* Verify file against expected hash */
static int verify_file(const char *filepath, const char *expected, const char *algo) {
    FILE *fp = fopen(filepath, "rb");
    if (!fp) { perror(filepath); return 1; }

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    const EVP_MD *evp = EVP_get_digestbyname(algo);
    if (!evp) { fprintf(stderr, "Unknown algorithm: %s\n", algo); fclose(fp); EVP_MD_CTX_free(ctx); return 1; }

    EVP_DigestInit(ctx, evp);

    uint8_t buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), fp)) > 0)
        EVP_DigestUpdate(ctx, buf, n);

    unsigned char md[EVP_MAX_MD_SIZE];
    unsigned int md_len = 0;
    EVP_DigestFinal(ctx, md, &md_len);
    EVP_MD_CTX_free(ctx);
    fclose(fp);

    char computed[EVP_MAX_MD_SIZE * 2 + 1] = {0};
    for (unsigned int i = 0; i < md_len; i++)
        sprintf(computed + i * 2, "%02x", md[i]);

    if (strncmp(computed, expected, md_len * 2) == 0) {
        printf("\033[0;32m  [OK]\033[0m %s matches %s (%s)\n", filepath, expected, algo);
        return 0;
    } else {
        printf("\033[0;31m  [FAIL]\033[0m %s\n", filepath);
        printf("    Expected: %s\n", expected);
        printf("    Computed: %s\n", computed);
        return 1;
    }
}

static void print_usage(const char *prog) {
    printf("Usage: %s [options]\n\n", prog);
    printf("Options:\n");
    printf("  -f <file>       Compute hash of file (default: sha256)\n");
    printf("  -a <algo>       Algorithm: md5, sha1, sha256, sha512 (default: sha256)\n");
    printf("  -s <string>     Hash a string\n");
    printf("  -v <file>       Verify file against expected hash\n");
    printf("  -e <hash>       Expected hash for verification\n");
    printf("  -i <hash>       Identify hash type\n");
    printf("  -h              Show this help\n\n");
    printf("Examples:\n");
    printf("  %s -f /bin/ls\n", prog);
    printf("  %s -f /bin/ls -a md5\n", prog);
    printf("  %s -s \"hello world\"\n", prog);
    printf("  %s -v file.iso -e abc123... -a sha256\n", prog);
    printf("  %s -i 5d41402abc4b2a76b9719d911017c592\n\n", prog);
}

int main(int argc, char *argv[]) {
    int opt;
    char *filepath = NULL, *algo = "sha256", *input = NULL;
    char *verify_hash = NULL, *identify = NULL;

    while ((opt = getopt(argc, argv, "f:a:s:v:e:i:h")) != -1) {
        switch (opt) {
            case 'f': filepath = optarg; break;
            case 'a': algo = optarg; break;
            case 's': input = optarg; break;
            case 'v': filepath = optarg; break;
            case 'e': verify_hash = optarg; break;
            case 'i': identify = optarg; break;
            case 'h': print_usage(argv[0]); return 0;
            default:  print_usage(argv[0]); return 1;
        }
    }

    printf("\n  \033[1;36mHashCheck — Hash Identifier & Checker\033[0m\n\n");

    if (identify) {
        const char *type = identify_hash(identify);
        printf("  Hash:   %s\n", identify);
        printf("  Length: %zu\n", strlen(identify));
        printf("  Type:   \033[1;32m%s\033[0m\n\n", type);
        return 0;
    }

    if (verify_hash && filepath) {
        return verify_file(filepath, verify_hash, algo);
    }

    if (input) {
        printf("  Input:  \"%s\"\n", input);
        printf("  %s: ", algo);
        hash_string(input, algo);
        printf("\n");
        return 0;
    }

    if (filepath) {
        printf("  File: %s\n", filepath);
        printf("  %s: ", algo);
        hash_file(filepath, algo);
        printf("\n");
        return 0;
    }

    print_usage(argv[0]);
    return 1;
}

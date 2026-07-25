/* PhantomSec OS — i18n dispatcher
 * Define LANG_TH before including this file to get Thai strings.
 * Default is English.
 *
 * Usage:
 *   // English (default):
 *   #include "i18n/i18n.h"
 *
 *   // Thai:
 *   #define LANG_TH
 *   #include "i18n/i18n.h"
 *
 *   // Runtime switch via environment:
 *   if (getenv("PHANTOMSEC_LANG") && strcmp(getenv("PHANTOMSEC_LANG"),"th")==0)
 *       // reopen with LANG_TH defined — or use i18n_get() below
 */
#ifndef PHANTOMSEC_I18N_H
#define PHANTOMSEC_I18N_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Runtime locale detection */
typedef enum { PS_LANG_EN = 0, PS_LANG_TH = 1 } ps_lang_t;

static ps_lang_t _ps_current_lang = PS_LANG_EN;

static inline void ps_lang_init(void) {
    const char *env = getenv("PHANTOMSEC_LANG");
    if (env && (strcmp(env, "th") == 0 || strcmp(env, "TH") == 0))
        _ps_current_lang = PS_LANG_TH;
}

static inline void ps_lang_set(const char *lang) {
    if (lang && (strcmp(lang, "th") == 0 || strcmp(lang, "TH") == 0))
        _ps_current_lang = PS_LANG_TH;
    else
        _ps_current_lang = PS_LANG_EN;
}

static inline ps_lang_t ps_lang_get(void) { return _ps_current_lang; }

/* Compile-time locale selection */
#ifdef LANG_TH
#include "th.h"
#else
#include "en.h"
#endif

/* ANSI color codes */
#define PS_RED     "\033[0;31m"
#define PS_GREEN   "\033[0;32m"
#define PS_YELLOW  "\033[1;33m"
#define PS_BLUE    "\033[0;34m"
#define PS_CYAN    "\033[0;36m"
#define PS_MAGENTA "\033[0;35m"
#define PS_WHITE   "\033[1;37m"
#define PS_GRAY    "\033[0;90m"
#define PS_BOLD    "\033[1m"
#define PS_RESET   "\033[0m"
#define PS_DIM     "\033[2m"

/* Print helpers */
#define PS_ERR(fmt, ...)  fprintf(stderr, PS_RED    "[!] " fmt PS_RESET "\n", ##__VA_ARGS__)
#define PS_WARN(fmt, ...) fprintf(stderr, PS_YELLOW "[*] " fmt PS_RESET "\n", ##__VA_ARGS__)
#define PS_OK(fmt, ...)   fprintf(stdout, PS_GREEN  "[+] " fmt PS_RESET "\n", ##__VA_ARGS__)
#define PS_INFO(fmt, ...) fprintf(stdout, PS_CYAN   "[-] " fmt PS_RESET "\n", ##__VA_ARGS__)
#define PS_DATA(fmt, ...) fprintf(stdout, PS_WHITE        fmt PS_RESET "\n", ##__VA_ARGS__)

/* Banner printer */
static inline void ps_print_banner(const char *tool_name, const char *tool_desc) {
    printf(PS_CYAN PS_BOLD
        "\n ██████╗ ██╗  ██╗ █████╗ ███╗  ██╗████████╗ ██████╗ ███╗  ███╗\n"
        " ██╔══██╗██║  ██║██╔══██╗████╗ ██║╚══██╔══╝██╔═══██╗████╗████║\n"
        " ██████╔╝███████║███████║██╔██╗██║   ██║   ██║   ██║██╔████╔██║\n"
        " ██╔═══╝ ██╔══██║██╔══██║██║╚████║   ██║   ██║   ██║██║╚██╔╝██║\n"
        " ██║     ██║  ██║██║  ██║██║ ╚███║   ██║   ╚██████╔╝██║ ╚═╝ ██║\n"
        " ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝\n"
        PS_RESET
    );
    printf(PS_DIM " %s — PhantomSec OS v2.5.2\n\n" PS_RESET, I18N_BUILT_WITH);
    printf(PS_BOLD " %s" PS_RESET " — " PS_GRAY "%s\n\n" PS_RESET, tool_name, tool_desc);
}

#endif /* PHANTOMSEC_I18N_H */

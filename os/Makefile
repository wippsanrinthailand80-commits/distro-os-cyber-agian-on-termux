# PhantomSec OS — Master Makefile
# Builds all C/C++ tools from source
# Usage: make all | make install | make clean | make LANG=th all

CC      = gcc
CFLAGS  = -O2 -Wall -Wextra -std=c11 -D_GNU_SOURCE
LDFLAGS = -lm
PREFIX  ?= /usr/local

# Language selection (default: en)
LANG ?= en
ifeq ($(LANG),th)
  CFLAGS += -DLANG_TH
endif

TOOLS = spectrscan entropyd scdna netghost psh

.PHONY: all clean install uninstall $(TOOLS)

all: $(TOOLS)
	@echo ""
	@echo "  ██████╗ ██╗  ██╗ █████╗ ███╗  ██╗████████╗ ██████╗ ███╗  ███╗"
	@echo "  ██╔══██╗██║  ██║██╔══██╗████╗ ██║╚══██╔══╝██╔═══██╗████╗████║"
	@echo "  ██████╔╝███████║███████║██╔██╗██║   ██║   ██║   ██║██╔████╔██║"
	@echo "  ██╔═══╝ ██╔══██║██╔══██║██║╚████║   ██║   ██║   ██║██║╚██╔╝██║"
	@echo "  ██║     ██║  ██║██║  ██║██║ ╚███║   ██║   ╚██████╔╝██║ ╚═╝ ██║"
	@echo "  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝"
	@echo ""
	@echo "  PhantomSec OS v2.5.5 — All tools built successfully"
	@echo "  Run 'make install' to install to $(PREFIX)"
	@echo ""

spectrscan:
	@echo "[+] Building spectrscan..."
	$(CC) $(CFLAGS) -o bin/$@ tools/spectrscan/spectrscan.c $(LDFLAGS)

entropyd:
	@echo "[+] Building entropyd..."
	$(CC) $(CFLAGS) -o bin/$@ tools/entropyd/entropyd.c $(LDFLAGS)

scdna:
	@echo "[+] Building scdna..."
	$(CC) $(CFLAGS) -o bin/$@ tools/scdna/scdna.c $(LDFLAGS)

netghost:
	@echo "[+] Building netghost..."
	$(CC) $(CFLAGS) -o bin/$@ tools/netghost/netghost.c $(LDFLAGS)

psh:
	@echo "[+] Building psh..."
	$(CC) $(CFLAGS) -o bin/$@ tools/psh/psh.c $(LDFLAGS)

install: all
	@echo "[*] Installing to $(PREFIX)..."
	@install -d $(PREFIX)
	@for t in $(TOOLS); do install -m 755 bin/$$t $(PREFIX)/$$t && echo "  installed: $(PREFIX)/$$t"; done
	@echo "[+] Installation complete"

uninstall:
	@for t in $(TOOLS); do rm -f $(PREFIX)/$$t && echo "  removed: $(PREFIX)/$$t"; done

clean:
	@rm -f $(addprefix bin/, $(TOOLS))
	@echo "[*] Cleaned build artifacts"

# Build bin directory if missing
bin:
	@mkdir -p bin

$(TOOLS): bin

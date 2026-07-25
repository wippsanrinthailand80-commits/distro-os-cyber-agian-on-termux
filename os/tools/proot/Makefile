# PhantomSec phantom-proot — Makefile
# Builds a self-contained proot binary from scratch (no third-party proot)
#
# Usage:
#   make            — build for the host arch (ARM64 on Termux)
#   make LANG=th    — build with Thai UI strings (reserved for future use)
#   make clean      — remove build artefacts
#   make install    — install to PREFIX (default: ~/.local/bin)
#   make help       — show targets

CC      ?= gcc
CFLAGS  = -O2 -Wall -Wextra -std=c11 -D_GNU_SOURCE -Isrc
LDFLAGS =

# Language selection (reserved — proot messages use English only for now)
LANG ?= en
ifeq ($(LANG),th)
  CFLAGS += -DLANG_TH
endif

PREFIX  ?= $(HOME)/.local/bin
TARGET   = proot

SRC = src/main.c \
      src/arch.c \
      src/path.c \
      src/mount.c \
      src/tracee.c \
      src/syscall.c

OBJ = $(SRC:.c=.o)

.PHONY: all clean install uninstall help

all: $(TARGET)
	@echo ""
	@echo "  ██████╗ ██████╗  ██████╗  ██████╗ ████████╗"
	@echo "  ██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝"
	@echo "  ██████╔╝██████╔╝██║   ██║██║   ██║   ██║   "
	@echo "  ██╔═══╝ ██╔══██╗██║   ██║██║   ██║   ██║   "
	@echo "  ██║     ██║  ██║╚██████╔╝╚██████╔╝   ██║   "
	@echo "  ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝   "
	@echo ""
	@echo "  phantom-proot v2.5.3 — built successfully"
	@echo "  Run: ./$(TARGET) -r <rootfs> -- /bin/bash"
	@echo ""

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

install: $(TARGET)
	@mkdir -p $(PREFIX)
	cp $(TARGET) $(PREFIX)/$(TARGET)
	@echo "[+] Installed to $(PREFIX)/$(TARGET)"

uninstall:
	rm -f $(PREFIX)/$(TARGET)
	@echo "[+] Removed $(PREFIX)/$(TARGET)"

clean:
	rm -f $(OBJ) $(TARGET)

help:
	@echo "Targets:"
	@echo "  all         Build phantom-proot (default)"
	@echo "  install     Install to PREFIX=$(PREFIX)"
	@echo "  uninstall   Remove from PREFIX"
	@echo "  clean       Remove build artefacts"

# phantom-proot Makefile
# Build from scratch for Termux/Android aarch64

CC      ?= gcc
CFLAGS  ?= -Wall -Wextra -Werror -O2 -std=c99 -D_GNU_SOURCE
PREFIX  ?= $(HOME)/.local/bin
TARGET  := phantom-proot

SRCS    := src/main.c src/mount.c src/path.c src/mem.c src/arch.c \
           src/syscall.c src/proc.c
OBJS    := $(SRCS:.c=.o)

.PHONY: all clean install

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^
	@echo "Built: $(TARGET)"

src/%.o: src/%.c src/proot.h
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)

install: $(TARGET)
	install -d $(PREFIX)
	install -m 755 $(TARGET) $(PREFIX)/$(TARGET)
	@echo "Installed: $(PREFIX)/$(TARGET)"

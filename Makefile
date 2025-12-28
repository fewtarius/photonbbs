# PhotonBBS Makefile
# Builds the PhotonBBS TTY wrapper with telnet protocol negotiation support
# Compatible with Linux and macOS systems

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99 -D_GNU_SOURCE
SRCDIR = src
BINDIR = sbin
TARGET = $(BINDIR)/photonbbs-tty
SOURCE = $(SRCDIR)/photonbbs-tty.c

# Detect operating system for proper library linking
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    # macOS: Use -lutil for openpty
    LDFLAGS = -lutil
else ifeq ($(UNAME_S),Linux)
    # Linux: Use -lutil for openpty  
    LDFLAGS = -lutil
else
    # FreeBSD and other Unix-like systems
    LDFLAGS = -lutil
endif

# Installation directories
PREFIX ?= /opt/photonbbs
INSTALL_BIN = $(PREFIX)/sbin
INSTALL_OWNER ?= root
INSTALL_GROUP ?= root

.PHONY: all clean install uninstall help check-deps

all: $(TARGET)

$(BINDIR):
	@echo "Creating build directory: $(BINDIR)"
	mkdir -p $(BINDIR)

$(TARGET): $(SOURCE) | $(BINDIR)
	@echo "Building PhotonBBS TTY wrapper with telnet negotiation..."
	@echo "  Source:   $(SOURCE)"
	@echo "  Target:   $(TARGET)"
	@echo "  Platform: $(UNAME_S)"
	@echo "  Flags:    $(CFLAGS)"
	@echo "  Libs:     $(LDFLAGS)"
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
	@echo "Build complete!"

clean:
	@echo "Cleaning build artifacts..."
	rm -f $(TARGET)
	@if [ -d $(BINDIR) ] && [ -z "$$(ls -A $(BINDIR))" ]; then rmdir $(BINDIR); fi
	@echo "Clean complete!"

# Check for required dependencies
check-deps:
	@echo "Checking build dependencies..."
	@command -v gcc >/dev/null 2>&1 || { echo "ERROR: gcc is required but not installed"; exit 1; }
	@echo "  ✓ gcc found: $$(gcc --version | head -n1)"
	@echo "Checking development headers..."
ifeq ($(UNAME_S),Darwin)
	@echo "  ✓ macOS: util.h should be available via Xcode Command Line Tools"
else
	@if [ -f /usr/include/pty.h ] || [ -f /usr/include/util.h ]; then \
		echo "  ✓ pty/util headers found"; \
	else \
		echo "  ⚠ WARNING: pty.h/util.h not found. You may need to install:"; \
		echo "    - Ubuntu/Debian: sudo apt-get install build-essential"; \
		echo "    - RHEL/CentOS: sudo yum install gcc glibc-devel"; \
		echo "    - Alpine: sudo apk add build-base linux-headers"; \
	fi
endif
	@echo "Dependencies check complete!"

# Install for local development/testing
install: $(TARGET) check-deps
	@echo "Installing PhotonBBS TTY wrapper..."
	@echo "  Creating installation directory: $(INSTALL_BIN)"
	install -d $(INSTALL_BIN)
	@echo "  Installing binary: $(TARGET) -> $(INSTALL_BIN)/photonbbs-tty"
	install -m 755 $(TARGET) $(INSTALL_BIN)/photonbbs-tty
	@echo "Installation complete!"
	@echo ""
	@echo "PhotonBBS TTY wrapper installed to: $(INSTALL_BIN)/photonbbs-tty"
	@echo "This provides telnet protocol negotiation for PhotonBBS connections."

# Production installation with proper security
secure-install: install
	@echo "Applying production security settings..."
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "WARNING: Not running as root. Ownership changes may fail."; \
		echo "Consider running: sudo make secure-install"; \
	fi
	chown $(INSTALL_OWNER):$(INSTALL_GROUP) $(INSTALL_BIN)/photonbbs-tty
	chmod 755 $(INSTALL_BIN)/photonbbs-tty
	@echo "Security settings applied!"

# Remove installed files
uninstall:
	@echo "Uninstalling PhotonBBS TTY wrapper..."
	rm -f $(INSTALL_BIN)/photonbbs-tty
	@echo "Uninstall complete!"

# Install with custom prefix
install-local: PREFIX = $(HOME)/.local
install-local: INSTALL_OWNER = $(shell id -un)
install-local: INSTALL_GROUP = $(shell id -gn)
install-local: install
	@echo ""
	@echo "Local installation complete!"
	@echo "Add $(HOME)/.local/sbin to your PATH if needed:"
	@echo "  export PATH=\"\$$HOME/.local/sbin:\$$PATH\""

# Development build with debug symbols
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)
	@echo "Debug build complete!"

# Show help information
help:
	@echo "PhotonBBS TTY Wrapper Build System"
	@echo "=================================="
	@echo ""
	@echo "This builds the PhotonBBS TTY wrapper which provides telnet protocol"
	@echo "negotiation support, replacing traditional telnetd for PhotonBBS."
	@echo ""
	@echo "Targets:"
	@echo "  all             Build photonbbs-tty (default)"
	@echo "  clean           Remove build artifacts"
	@echo "  check-deps      Verify build dependencies"
	@echo "  install         Install to $(PREFIX) (requires privileges)"
	@echo "  install-local   Install to $(HOME)/.local (user installation)"
	@echo "  secure-install  Install with production security settings"
	@echo "  uninstall       Remove installed files"
	@echo "  debug           Build with debug symbols"
	@echo "  help            Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX          Installation prefix (default: /opt/photonbbs)"
	@echo "  CC              C compiler (default: gcc)"
	@echo "  CFLAGS          Compiler flags"
	@echo ""
	@echo "Examples:"
	@echo "  make                          # Build the TTY wrapper"
	@echo "  make check-deps              # Check if dependencies are available"
	@echo "  make install-local           # Install to ~/.local/sbin"
	@echo "  sudo make install            # System-wide installation"
	@echo "  PREFIX=/usr/local make install  # Install to /usr/local"

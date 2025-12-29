# PhotonBBS Makefile
# Builds the PhotonBBS TTY wrapper with telnet protocol negotiation support
# Compatible with Linux and macOS systems
# Also provides Docker build and deployment targets

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99 -D_GNU_SOURCE
SRCDIR = src
BINDIR = sbin
TARGET = $(BINDIR)/photonbbs-tty
SOURCE = $(SRCDIR)/photonbbs-tty.c

# Docker configuration
DOCKER_IMAGE = fewtarius/photonbbs
DOCKER_COMPOSE = docker-compose
DOCKER_COMPOSE_FILE = docker/docker-compose.yml

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

.PHONY: all clean install uninstall help check-deps docker-build docker-up docker-down docker-logs docker-shell docker-clean

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
	@echo "PhotonBBS Build System"
	@echo "====================="
	@echo ""
	@echo "This builds PhotonBBS components and manages Docker deployment."
	@echo ""
	@echo "TTY Wrapper Targets:"
	@echo "  all             Build photonbbs-tty (default)"
	@echo "  clean           Remove build artifacts"
	@echo "  check-deps      Verify build dependencies"
	@echo "  install         Install to $(PREFIX) (requires privileges)"
	@echo "  install-local   Install to $(HOME)/.local (user installation)"
	@echo "  secure-install  Install with production security settings"
	@echo "  uninstall       Remove installed files"
	@echo "  debug           Build with debug symbols"
	@echo ""
	@echo "Docker Targets:"
	@echo "  docker-build    Build Docker image"
	@echo "  docker-up       Start PhotonBBS container (docker-compose up -d)"
	@echo "  docker-down     Stop PhotonBBS container"
	@echo "  docker-restart  Restart PhotonBBS container"
	@echo "  docker-logs     View container logs"
	@echo "  docker-shell    Open shell in running container"
	@echo "  docker-rebuild  Stop, rebuild, and restart container"
	@echo "  docker-clean    Remove container, image, and volumes (DESTRUCTIVE)"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX          Installation prefix (default: /opt/photonbbs)"
	@echo "  CC              C compiler (default: gcc)"
	@echo "  CFLAGS          Compiler flags"
	@echo "  DOCKER_IMAGE    Docker image name (default: fewtarius/photonbbs)"
	@echo ""
	@echo "Examples:"
	@echo "  make                          # Build the TTY wrapper"
	@echo "  make docker-build             # Build Docker image"
	@echo "  make docker-up                # Start PhotonBBS via Docker"
	@echo "  make docker-logs              # View logs"
	@echo "  sudo make install             # Install TTY wrapper system-wide"

# Docker build targets
docker-build:
	@echo "Building PhotonBBS Docker image..."
	cd docker && $(DOCKER_COMPOSE) build
	@echo "Docker image built successfully!"
	@echo ""
	@echo "To start PhotonBBS, run: make docker-up"

docker-up:
	@echo "Starting PhotonBBS container..."
	cd docker && $(DOCKER_COMPOSE) up -d
	@echo "PhotonBBS is starting up!"
	@echo ""
	@echo "View logs: make docker-logs"
	@echo "Access shell: make docker-shell"
	@echo "Connect via: telnet localhost 23"

docker-down:
	@echo "Stopping PhotonBBS container..."
	cd docker && $(DOCKER_COMPOSE) down
	@echo "PhotonBBS stopped"

docker-restart:
	@echo "Restarting PhotonBBS container..."
	cd docker && $(DOCKER_COMPOSE) restart
	@echo "PhotonBBS restarted"

docker-logs:
	@echo "PhotonBBS container logs (Ctrl+C to exit):"
	@echo "=========================================="
	cd docker && $(DOCKER_COMPOSE) logs -f

docker-shell:
	@echo "Opening shell in PhotonBBS container..."
	cd docker && $(DOCKER_COMPOSE) exec photonbbs /bin/bash

docker-rebuild:
	@echo "Rebuilding PhotonBBS (stop, build, start)..."
	cd docker && $(DOCKER_COMPOSE) down
	cd docker && $(DOCKER_COMPOSE) build
	cd docker && $(DOCKER_COMPOSE) up -d
	@echo "PhotonBBS rebuilt and restarted!"

docker-clean:
	@echo "WARNING: This will remove containers, images, and volumes!"
	@echo "Press Ctrl+C within 5 seconds to cancel..."
	@sleep 5
	cd docker && $(DOCKER_COMPOSE) down -v
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	@echo "PhotonBBS Docker environment cleaned"

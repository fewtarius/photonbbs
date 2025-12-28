#!/bin/bash

# PhotonBBS Installation Script
# Comprehensive installer for bare metal and virtual machine installations
# Compatible with Linux distributions and macOS
#
# Copyright (C) 2025 Fewtarius
# License: GPL v2

set -euo pipefail

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="PhotonBBS Installer"

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Installation configuration
PHOTONBBS_USER="${PHOTONBBS_USER:-photonbbs}"
PHOTONBBS_GROUP="${PHOTONBBS_GROUP:-photonbbs}"
PHOTONBBS_HOME="${PHOTONBBS_HOME:-/opt/photonbbs}"
PHOTONBBS_PORT="${PHOTONBBS_PORT:-23}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/opt}"
BUILD_USER="${SUDO_USER:-$(whoami)}"

# Feature flags
INSTALL_DOSEMU="${INSTALL_DOSEMU:-ask}"
INSTALL_SERVICE="${INSTALL_SERVICE:-yes}"
COMPILE_TTY="${COMPILE_TTY:-yes}"

# Logging
LOG_FILE="/tmp/photonbbs-install.log"
touch "$LOG_FILE"

# Show help information
show_help() {
    cat << EOF
PhotonBBS Installation Script v$SCRIPT_VERSION

USAGE:
    sudo ./install.sh [OPTIONS]

DESCRIPTION:
    Installs PhotonBBS BBS system with telnet negotiation support.
    Compatible with Linux distributions and macOS.

OPTIONS:
    -h, --help          Show this help message
    
ENVIRONMENT VARIABLES:
    PHOTONBBS_USER      System user name (default: photonbbs)
    PHOTONBBS_GROUP     System group name (default: photonbbs)  
    PHOTONBBS_HOME      Installation directory (default: /opt/photonbbs)
    PHOTONBBS_PORT      BBS port number (default: 23)
    INSTALL_DOSEMU      Install DOSEmu: yes|no|ask (default: ask)
    INSTALL_SERVICE     Install system service: yes|no (default: yes)
    COMPILE_TTY         Compile TTY wrapper: yes|no (default: yes)

EXAMPLES:
    # Standard installation
    sudo ./install.sh
    
    # Custom installation directory
    sudo PHOTONBBS_HOME=/usr/local/photonbbs ./install.sh
    
    # Install on custom port without DOSEmu
    sudo PHOTONBBS_PORT=2323 INSTALL_DOSEMU=no ./install.sh

SUPPORTED PLATFORMS:
    - Ubuntu/Debian (apt)
    - RHEL/CentOS/Rocky/Fedora (yum/dnf)
    - Arch Linux (pacman)
    - macOS (brew)
    - FreeBSD (pkg)

For more information, see INSTALL.md
EOF
}

# Utility functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE} $1${CYAN}$(printf "%*s" $((70-${#1})) "")║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}➤${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

prompt_user() {
    local prompt="$1"
    local default="${2:-}"
    local response
    
    if [[ -n "$default" ]]; then
        read -p "$(echo -e "${YELLOW}?${NC} $prompt [$default]: ")" response
        response="${response:-$default}"
    else
        read -p "$(echo -e "${YELLOW}?${NC} $prompt: ")" response
    fi
    
    echo "$response"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    case "$default" in
        y|Y|yes|Yes) prompt_text="$prompt [Y/n]" ;;
        *) prompt_text="$prompt [y/N]" ;;
    esac
    
    response=$(prompt_user "$prompt_text")
    case "${response:-$default}" in
        y|Y|yes|Yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

# System detection
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian) echo "debian" ;;
            rhel|centos|rocky|almalinux|fedora) echo "redhat" ;;
            arch|manjaro|steamos) echo "arch" ;;
            opensuse*|sles) echo "suse" ;;
            alpine) echo "alpine" ;;
            *)
                # Check ID_LIKE for additional compatibility
                case "$ID_LIKE" in
                    *arch*) echo "arch" ;;
                    *debian*) echo "debian" ;;
                    *rhel*|*fedora*) echo "redhat" ;;
                    *) echo "linux" ;;
                esac
                ;;
        esac
    elif command -v pkg >/dev/null 2>&1; then
        echo "freebsd"
    else
        echo "unknown"
    fi
}

detect_service_manager() {
    if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
        echo "systemd"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "launchd"
    elif command -v service >/dev/null 2>&1; then
        echo "sysv"
    else
        echo "none"
    fi
}

detect_package_manager() {
    case "$(detect_os)" in
        debian) echo "apt" ;;
        redhat) 
            if command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        arch) echo "pacman" ;;
        suse) echo "zypper" ;;
        alpine) echo "apk" ;;
        macos) 
            if command -v brew >/dev/null 2>&1; then
                echo "brew"
            else
                echo "none"
            fi
            ;;
        freebsd) echo "pkg" ;;
        *) echo "none" ;;
    esac
}

# Dependency checking and installation
check_dependencies() {
    print_header "Checking System Dependencies"
    
    local missing_deps=()
    local os_type=$(detect_os)
    local pkg_mgr=$(detect_package_manager)
    
    # Core system requirements
    local core_deps=("perl" "gcc" "make")
    
    # Platform-specific requirements
    case "$os_type" in
        debian)
            core_deps+=("build-essential" "perl-modules")
            ;;
        redhat)
            core_deps+=("gcc-c++" "glibc-devel" "perl-core")
            ;;
        arch)
            core_deps+=("base-devel")
            ;;
        macos)
            # Xcode command line tools provide gcc and make
            if ! xcode-select -p >/dev/null 2>&1; then
                missing_deps+=("xcode-command-line-tools")
            fi
            ;;
    esac
    
    # Check for required commands
    for cmd in perl gcc make; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_warning "Missing required command: $cmd"
            missing_deps+=("$cmd")
        else
            print_success "Found $cmd: $(command -v "$cmd")"
        fi
    done
    
    # Check Perl modules
    print_step "Checking required Perl modules..."
    local perl_modules=(
        "IO::Socket::INET"
        "POSIX"
        "File::Basename"
        "Time::HiRes"
        "File::Path"
        "Term::ANSIColor"
        "English"
        "threads"
        "Fcntl"
        "Storable"
        "Digest::SHA"
        "JSON::PP"
    )
    
    for module in "${perl_modules[@]}"; do
        if perl -M"$module" -e 'exit(0)' 2>/dev/null; then
            print_success "Perl module $module is available"
        else
            print_warning "Missing Perl module: $module"
            missing_deps+=("perl-$module")
        fi
    done
    
    return ${#missing_deps[@]}
}

install_dependencies() {
    print_header "Installing Dependencies"
    
    local os_type=$(detect_os)
    local pkg_mgr=$(detect_package_manager)
    
    if [[ "$pkg_mgr" == "none" ]]; then
        print_error "No supported package manager found. Please install dependencies manually."
        return 1
    fi
    
    print_step "Using package manager: $pkg_mgr"
    
    case "$pkg_mgr" in
        apt)
            print_step "Updating package lists..."
            sudo apt-get update
            
            print_step "Installing core dependencies..."
            sudo apt-get install -y \
                perl \
                build-essential \
                gcc \
                make \
                perl-modules-5.* \
                libio-socket-inet6-perl \
                libtime-hires-perl \
                libterm-ansicolor-perl \
                libstorable-perl \
                libdigest-sha-perl \
                libjson-pp-perl \
                git \
                wget \
                curl
            ;;
            
        dnf|yum)
            print_step "Installing core dependencies..."
            sudo "$pkg_mgr" install -y \
                perl \
                gcc \
                gcc-c++ \
                make \
                glibc-devel \
                perl-core \
                perl-IO-Socket-INET6 \
                perl-Time-HiRes \
                perl-Term-ANSIColor \
                perl-Storable \
                perl-Digest-SHA \
                perl-JSON-PP \
                git \
                wget \
                curl
            ;;
            
        pacman)
            print_step "Installing core dependencies..."
            sudo pacman -Sy --noconfirm \
                perl \
                base-devel \
                git \
                wget \
                curl
            ;;
            
        brew)
            print_step "Installing dependencies via Homebrew..."
            brew install perl gcc make git wget curl
            ;;
            
        pkg)
            print_step "Installing dependencies via pkg..."
            sudo pkg install -y \
                perl5 \
                gcc \
                gmake \
                git \
                wget \
                curl
            ;;
    esac
    
    # Install optional DOS emulation
    if [[ "$INSTALL_DOSEMU" == "yes" ]] || [[ "$INSTALL_DOSEMU" == "ask" && $(confirm "Install DOSEmu for door game support?") ]]; then
        install_dosemu "$pkg_mgr"
    fi
    
    print_success "Dependencies installation completed"
}

install_dosemu() {
    local pkg_mgr="$1"
    
    print_step "Installing DOSEmu for door game support..."
    
    case "$pkg_mgr" in
        apt)
            sudo apt-get install -y dosemu dosemu-freedos
            ;;
        dnf|yum)
            # DOSEmu might not be in standard repos
            print_warning "DOSEmu may need to be installed from EPEL or additional repositories"
            sudo "$pkg_mgr" install -y dosemu 2>/dev/null || print_warning "DOSEmu installation failed - install manually if needed"
            ;;
        *)
            print_warning "DOSEmu installation not automated for this package manager"
            print_warning "Please install DOSEmu manually if you need door game support"
            ;;
    esac
}

# User and group management
create_system_user() {
    print_header "Creating System User"
    
    # Check if user already exists
    if id "$PHOTONBBS_USER" >/dev/null 2>&1; then
        print_success "User $PHOTONBBS_USER already exists"
        return 0
    fi
    
    print_step "Creating system user: $PHOTONBBS_USER"
    
    case "$(detect_os)" in
        macos)
            # macOS user creation
            local max_uid=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1)
            local new_uid=$((max_uid + 1))
            
            sudo dscl . -create "/Users/$PHOTONBBS_USER"
            sudo dscl . -create "/Users/$PHOTONBBS_USER" UserShell /bin/bash
            sudo dscl . -create "/Users/$PHOTONBBS_USER" RealName "PhotonBBS System User"
            sudo dscl . -create "/Users/$PHOTONBBS_USER" UniqueID "$new_uid"
            sudo dscl . -create "/Users/$PHOTONBBS_USER" PrimaryGroupID 20
            sudo dscl . -create "/Users/$PHOTONBBS_USER" NFSHomeDirectory "$PHOTONBBS_HOME"
            ;;
        *)
            # Linux user creation
            sudo groupadd -r "$PHOTONBBS_GROUP" 2>/dev/null || true
            sudo useradd -r -g "$PHOTONBBS_GROUP" -d "$PHOTONBBS_HOME" -s /bin/bash -c "PhotonBBS System User" "$PHOTONBBS_USER"
            ;;
    esac
    
    print_success "System user $PHOTONBBS_USER created"
}

# Directory setup
setup_directories() {
    print_header "Setting Up Directory Structure"
    
    local directories=(
        "$PHOTONBBS_HOME"
        "$PHOTONBBS_HOME/data"
        "$PHOTONBBS_HOME/data/nodes"
        "$PHOTONBBS_HOME/data/users"
        "$PHOTONBBS_HOME/data/messages"
        "$PHOTONBBS_HOME/data/themes"
        "$PHOTONBBS_HOME/data/text"
        "$PHOTONBBS_HOME/doors"
        "$PHOTONBBS_HOME/doorexec"
        "$PHOTONBBS_HOME/sbin"
        "$PHOTONBBS_HOME/modules"
        "$PHOTONBBS_HOME/logs"
        "/var/log/photonbbs"
        "/dev/shm/photonbbs"
        "/dev/shm/photonbbs/data"
        "/dev/shm/photonbbs/data/nodes"
        "/dev/shm/photonbbs/data/messages"
    )
    
    for dir in "${directories[@]}"; do
        print_step "Creating directory: $dir"
        sudo mkdir -p "$dir"
    done
    
    # Set proper ownership
    print_step "Setting directory ownership..."
    sudo chown -R "$PHOTONBBS_USER:$PHOTONBBS_GROUP" "$PHOTONBBS_HOME"
    sudo chown -R "$PHOTONBBS_USER:$PHOTONBBS_GROUP" "/dev/shm/photonbbs"
    sudo chown "$PHOTONBBS_USER:$PHOTONBBS_GROUP" "/var/log/photonbbs"
    
    # Set proper permissions
    print_step "Setting directory permissions..."
    sudo chmod 755 "$PHOTONBBS_HOME"
    sudo chmod 750 "$PHOTONBBS_HOME/data"
    sudo chmod 750 "$PHOTONBBS_HOME/logs"
    sudo chmod 755 "/dev/shm/photonbbs"
    
    print_success "Directory structure created"
}

# Source code installation
install_source() {
    print_header "Installing PhotonBBS Source Code"
    
    local temp_dir="/tmp/photonbbs-install-$$"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    print_step "Creating temporary directory: $temp_dir"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Check if we're running from within the PhotonBBS repository
    if [[ -f "$script_dir/photonbbs" && -d "$script_dir/modules" && -f "$script_dir/install.sh" ]]; then
        print_step "Using source code from current directory: $script_dir"
        cp -r "$script_dir"/* .
    elif [[ -d "/Users/andrew/repositories/fewtarius/photonbbs" ]]; then
        print_step "Copying local source code..."
        cp -r "/Users/andrew/repositories/fewtarius/photonbbs"/* .
    else
        print_step "Cloning PhotonBBS repository..."
        git clone https://github.com/fewtarius/photonbbs.git .
    fi
    
    # Remove unnecessary files
    print_step "Cleaning source directory..."
    rm -rf .git* docker/ *.md tools/test-telnet-negotiation.py Dockerfile startscript appdeploy
    
    # Copy source to installation directory
    print_step "Installing source files to $PHOTONBBS_HOME..."
    sudo cp -r * "$PHOTONBBS_HOME/"
    
    # Set proper ownership
    sudo chown -R "$PHOTONBBS_USER:$PHOTONBBS_GROUP" "$PHOTONBBS_HOME"
    
    # Make scripts executable
    sudo chmod +x "$PHOTONBBS_HOME/photonbbs"
    sudo chmod +x "$PHOTONBBS_HOME"/sbin/*
    sudo chmod +x "$PHOTONBBS_HOME"/doorexec/*
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
    
    print_success "Source code installation completed"
}

# Compile photonbbs-tty
compile_tty_wrapper() {
    print_header "Compiling PhotonBBS TTY Wrapper"
    
    if [[ "$COMPILE_TTY" != "yes" ]]; then
        print_step "TTY wrapper compilation skipped"
        return 0
    fi
    
    cd "$PHOTONBBS_HOME"
    
    print_step "Compiling photonbbs-tty with telnet negotiation support..."
    
    # Build using the Makefile
    if sudo -u "$PHOTONBBS_USER" make clean && sudo -u "$PHOTONBBS_USER" make; then
        print_success "TTY wrapper compiled successfully"
        
        # Verify the binary
        if [[ -x "$PHOTONBBS_HOME/sbin/photonbbs-tty" ]]; then
            print_success "photonbbs-tty binary is ready"
            
            # Show binary info
            local binary_info=$(file "$PHOTONBBS_HOME/sbin/photonbbs-tty" 2>/dev/null || echo "Unknown")
            print_step "Binary info: $binary_info"
        else
            print_error "photonbbs-tty binary not found after compilation"
            return 1
        fi
    else
        print_error "TTY wrapper compilation failed"
        return 1
    fi
    
    # Clean up source artifacts but keep the compiled binary
    sudo rm -f "$PHOTONBBS_HOME/Makefile" "$PHOTONBBS_HOME/src" 2>/dev/null || true
}

# Configuration
setup_configuration() {
    print_header "Setting Up Configuration"
    
    # Copy default configuration
    print_step "Installing configuration files..."
    
    if [[ -f "$PHOTONBBS_HOME/configs/etc/default/photonbbs" ]]; then
        sudo mkdir -p /etc/default
        sudo cp "$PHOTONBBS_HOME/configs/etc/default/photonbbs" /etc/default/
    fi
    
    # Update configuration with installation-specific values
    print_step "Updating configuration..."
    
    local config_file="/etc/default/photonbbs"
    if [[ -f "$config_file" ]]; then
        sudo sed -i.bak \
            -e "s|home=\"[^\"]*\"|home=\"$PHOTONBBS_HOME\"|" \
            -e "s|unixuser=\"[^\"]*\"|unixuser=\"$PHOTONBBS_USER\"|" \
            -e "s|port=\"[^\"]*\"|port=\"$PHOTONBBS_PORT\"|" \
            "$config_file"
    fi
    
    # Set system name
    local system_name
    system_name=$(prompt_user "Enter BBS system name" "PhotonBBS")
    if [[ -n "$system_name" && -f "$config_file" ]]; then
        sudo sed -i "s|systemname=\"[^\"]*\"|systemname=\"$system_name\"|" "$config_file"
    fi
    
    # Set sysop name
    local sysop_name
    sysop_name=$(prompt_user "Enter sysop name" "SysOp")
    if [[ -n "$sysop_name" && -f "$config_file" ]]; then
        sudo sed -i "s|sysop=\"[^\"]*\"|sysop=\"$sysop_name\"|" "$config_file"
    fi
    
    print_success "Configuration completed"
}

# Service installation
install_service() {
    print_header "Installing System Service"
    
    if [[ "$INSTALL_SERVICE" != "yes" ]]; then
        print_step "Service installation skipped"
        return 0
    fi
    
    local service_mgr=$(detect_service_manager)
    
    case "$service_mgr" in
        systemd)
            install_systemd_service
            ;;
        launchd)
            install_launchd_service
            ;;
        sysv)
            install_sysv_service
            ;;
        *)
            print_warning "No supported service manager found"
            print_warning "You'll need to start PhotonBBS manually: $PHOTONBBS_HOME/photonbbs"
            return 1
            ;;
    esac
}

install_systemd_service() {
    print_step "Installing systemd service..."
    
    cat > /tmp/photonbbs.service << EOF
[Unit]
Description=PhotonBBS Daemon
After=network.target

[Service]
Type=simple
User=$PHOTONBBS_USER
Group=$PHOTONBBS_GROUP
WorkingDirectory=$PHOTONBBS_HOME
ExecStart=$PHOTONBBS_HOME/photonbbs --daemon
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$PHOTONBBS_HOME /dev/shm/photonbbs /var/log/photonbbs

[Install]
WantedBy=multi-user.target
EOF

    sudo mv /tmp/photonbbs.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable photonbbs.service
    
    print_success "Systemd service installed and enabled"
}

install_launchd_service() {
    print_step "Installing launchd service..."
    
    cat > /tmp/com.photonbbs.daemon.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.photonbbs.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PHOTONBBS_HOME/photonbbs</string>
        <string>--daemon</string>
    </array>
    <key>UserName</key>
    <string>$PHOTONBBS_USER</string>
    <key>WorkingDirectory</key>
    <string>$PHOTONBBS_HOME</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/photonbbs/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/photonbbs/stderr.log</string>
</dict>
</plist>
EOF

    sudo mv /tmp/com.photonbbs.daemon.plist /Library/LaunchDaemons/
    sudo launchctl load /Library/LaunchDaemons/com.photonbbs.daemon.plist
    
    print_success "Launchd service installed and loaded"
}

install_sysv_service() {
    print_step "Installing SysV init script..."
    
    cat > /tmp/photonbbs << 'EOF'
#!/bin/bash
# PhotonBBS        PhotonBBS BBS Daemon
# chkconfig: 35 80 20
# description: PhotonBBS BBS Daemon

. /etc/rc.d/init.d/functions

USER="$PHOTONBBS_USER"
DAEMON="photonbbs"
ROOT_DIR="$PHOTONBBS_HOME"

LOCK_FILE="/var/lock/subsys/photonbbs"

start() {
    if [ -f $LOCK_FILE ]; then
        echo "PhotonBBS is already running"
        return 1
    fi
    
    echo -n "Starting $DAEMON: "
    runuser -l "$USER" -c "$ROOT_DIR/photonbbs --daemon" > /dev/null 2>&1
    [ $? -eq 0 ] && touch $LOCK_FILE
    success
    echo
}

stop() {
    echo -n "Shutting down $DAEMON: "
    pid=$(ps -aefw | grep "$DAEMON" | grep -v " grep " | awk '{print $2}')
    kill -9 $pid > /dev/null 2>&1
    [ $? -eq 0 ] && success || failure
    rm -f $LOCK_FILE
    echo
}

restart() {
    stop
    start
}

status() {
    if [ -f $LOCK_FILE ]; then
        echo "$DAEMON is running."
    else
        echo "$DAEMON is stopped."
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: {start|stop|status|restart}"
        exit 1
        ;;
esac

exit $?
EOF

    # Substitute variables
    sed -i "s/\$PHOTONBBS_USER/$PHOTONBBS_USER/g" /tmp/photonbbs
    sed -i "s|\$PHOTONBBS_HOME|$PHOTONBBS_HOME|g" /tmp/photonbbs
    
    sudo mv /tmp/photonbbs /etc/init.d/
    sudo chmod +x /etc/init.d/photonbbs
    sudo chkconfig --add photonbbs
    sudo chkconfig photonbbs on
    
    print_success "SysV init script installed and enabled"
}

# Firewall configuration
configure_firewall() {
    print_header "Configuring Firewall"
    
    if ! confirm "Configure firewall to allow connections on port $PHOTONBBS_PORT?"; then
        print_step "Firewall configuration skipped"
        return 0
    fi
    
    local os_type=$(detect_os)
    
    case "$os_type" in
        debian|redhat|arch|suse)
            # Linux firewall configuration
            if command -v ufw >/dev/null 2>&1; then
                print_step "Configuring UFW firewall..."
                sudo ufw allow "$PHOTONBBS_PORT/tcp"
            elif command -v firewall-cmd >/dev/null 2>&1; then
                print_step "Configuring firewalld..."
                sudo firewall-cmd --permanent --add-port="$PHOTONBBS_PORT/tcp"
                sudo firewall-cmd --reload
            elif command -v iptables >/dev/null 2>&1; then
                print_step "Configuring iptables..."
                sudo iptables -A INPUT -p tcp --dport "$PHOTONBBS_PORT" -j ACCEPT
                # Save iptables rules (distribution-specific)
                if [[ -f /etc/debian_version ]]; then
                    sudo sh -c 'iptables-save > /etc/iptables/rules.v4'
                elif [[ -f /etc/redhat-release ]]; then
                    sudo service iptables save 2>/dev/null || true
                fi
            fi
            ;;
        macos)
            print_warning "macOS firewall configuration not automated"
            print_warning "You may need to configure the firewall manually in System Preferences"
            ;;
    esac
    
    print_success "Firewall configuration completed"
}

# Testing and validation
test_installation() {
    print_header "Testing Installation"
    
    # Test TTY wrapper
    if [[ -x "$PHOTONBBS_HOME/sbin/photonbbs-tty" ]]; then
        print_success "TTY wrapper is executable"
    else
        print_error "TTY wrapper is not executable"
        return 1
    fi
    
    # Test Perl syntax
    print_step "Testing Perl syntax..."
    if sudo -u "$PHOTONBBS_USER" perl -c "$PHOTONBBS_HOME/photonbbs" >/dev/null 2>&1; then
        print_success "Main daemon Perl syntax is valid"
    else
        print_error "Main daemon has Perl syntax errors"
        return 1
    fi
    
    # Test configuration loading
    print_step "Testing configuration loading..."
    if sudo -u "$PHOTONBBS_USER" perl -I"$PHOTONBBS_HOME/modules" -c "$PHOTONBBS_HOME/modules/pb-defaults" >/dev/null 2>&1; then
        print_success "Configuration loads successfully"
    else
        print_error "Configuration has syntax errors"
        return 1
    fi
    
    # Test permissions
    print_step "Testing file permissions..."
    if sudo -u "$PHOTONBBS_USER" test -w "$PHOTONBBS_HOME/data"; then
        print_success "Data directory is writable"
    else
        print_error "Data directory is not writable by PhotonBBS user"
        return 1
    fi
    
    print_success "Installation tests passed"
}

# Start services
start_service() {
    print_header "Starting PhotonBBS Service"
    
    if [[ "$INSTALL_SERVICE" != "yes" ]]; then
        print_step "Service not installed - starting manually for testing"
        if confirm "Start PhotonBBS daemon for testing?"; then
            print_step "Starting PhotonBBS daemon..."
            sudo -u "$PHOTONBBS_USER" "$PHOTONBBS_HOME/photonbbs" --debug &
            sleep 2
            print_success "PhotonBBS started in background (use jobs/fg to manage)"
        fi
        return 0
    fi
    
    local service_mgr=$(detect_service_manager)
    
    case "$service_mgr" in
        systemd)
            print_step "Starting PhotonBBS service..."
            sudo systemctl start photonbbs.service
            
            if sudo systemctl is-active --quiet photonbbs.service; then
                print_success "PhotonBBS service is running"
            else
                print_error "PhotonBBS service failed to start"
                print_step "Check logs with: sudo journalctl -u photonbbs.service"
                return 1
            fi
            ;;
        launchd)
            print_step "Starting PhotonBBS service..."
            sudo launchctl start com.photonbbs.daemon
            
            if sudo launchctl list | grep -q com.photonbbs.daemon; then
                print_success "PhotonBBS service is running"
            else
                print_error "PhotonBBS service failed to start"
                return 1
            fi
            ;;
        sysv)
            print_step "Starting PhotonBBS service..."
            sudo service photonbbs start
            ;;
    esac
}

# Final instructions
show_completion_info() {
    print_header "Installation Complete!"
    
    echo
    echo -e "${GREEN}PhotonBBS has been successfully installed!${NC}"
    echo
    echo -e "${CYAN}Installation Summary:${NC}"
    echo -e "  ${WHITE}Installation Path:${NC} $PHOTONBBS_HOME"
    echo -e "  ${WHITE}System User:${NC} $PHOTONBBS_USER"
    echo -e "  ${WHITE}Port:${NC} $PHOTONBBS_PORT"
    echo -e "  ${WHITE}Configuration:${NC} /etc/default/photonbbs"
    echo -e "  ${WHITE}Logs:${NC} /var/log/photonbbs/"
    
    echo
    echo -e "${CYAN}Next Steps:${NC}"
    echo
    echo -e "1. ${WHITE}Connect to your BBS:${NC}"
    echo -e "   ${BLUE}telnet localhost $PHOTONBBS_PORT${NC}"
    echo
    echo -e "2. ${WHITE}Create your sysop account:${NC}"
    echo -e "   Connect via telnet and create a user account"
    echo
    echo -e "3. ${WHITE}Set sysop privileges:${NC}"
    echo -e "   ${BLUE}sudo $PHOTONBBS_HOME/sbin/useredit${NC}"
    echo -e "   Set security level to 500 for sysop privileges"
    echo
    echo -e "4. ${WHITE}Service Management:${NC}"
    
    local service_mgr=$(detect_service_manager)
    case "$service_mgr" in
        systemd)
            echo -e "   Start:   ${BLUE}sudo systemctl start photonbbs${NC}"
            echo -e "   Stop:    ${BLUE}sudo systemctl stop photonbbs${NC}"
            echo -e "   Status:  ${BLUE}sudo systemctl status photonbbs${NC}"
            echo -e "   Logs:    ${BLUE}sudo journalctl -u photonbbs -f${NC}"
            ;;
        launchd)
            echo -e "   Start:   ${BLUE}sudo launchctl start com.photonbbs.daemon${NC}"
            echo -e "   Stop:    ${BLUE}sudo launchctl stop com.photonbbs.daemon${NC}"
            echo -e "   Logs:    ${BLUE}tail -f /var/log/photonbbs/*.log${NC}"
            ;;
        sysv)
            echo -e "   Start:   ${BLUE}sudo service photonbbs start${NC}"
            echo -e "   Stop:    ${BLUE}sudo service photonbbs stop${NC}"
            echo -e "   Status:  ${BLUE}sudo service photonbbs status${NC}"
            ;;
        *)
            echo -e "   Manual:  ${BLUE}sudo -u $PHOTONBBS_USER $PHOTONBBS_HOME/photonbbs --daemon${NC}"
            ;;
    esac
    
    echo
    echo -e "5. ${WHITE}Configuration:${NC}"
    echo -e "   ${BLUE}/etc/default/photonbbs${NC} - Main configuration"
    echo -e "   ${BLUE}$PHOTONBBS_HOME/data/main.mnu${NC} - Main menu"
    echo -e "   ${BLUE}$PHOTONBBS_HOME/data/external.mnu${NC} - External commands"
    echo
    echo -e "6. ${WHITE}Documentation:${NC}"
    echo -e "   ${BLUE}$PHOTONBBS_HOME/README.md${NC}"
    echo -e "   ${BLUE}$PHOTONBBS_HOME/INSTALL-TTY.md${NC}"
    echo
    echo -e "${GREEN}Enjoy your PhotonBBS installation!${NC}"
    echo -e "${YELLOW}For support, visit: https://github.com/fewtarius/photonbbs${NC}"
    echo
}

# Main installation workflow
main() {
    local start_time=$(date +%s)
    
    # Handle help option
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # Show simple header
    print_header "PhotonBBS Installation Script v$SCRIPT_VERSION"
    
    echo "This script will install PhotonBBS on your system with full telnet negotiation support."
    echo
    echo -e "${YELLOW}Installation Log:${NC} $LOG_FILE"
    echo
    
    # Check if running as root
    if [[ $EUID -eq 0 && -z "$SUDO_USER" ]]; then
        print_error "Please run this script with sudo, not as root directly"
        exit 1
    fi
    
    # Detect system
    local os_type=$(detect_os)
    local pkg_mgr=$(detect_package_manager)
    local service_mgr=$(detect_service_manager)
    
    echo -e "${CYAN}System Information:${NC}"
    echo -e "  Operating System: $os_type"
    echo -e "  Package Manager: $pkg_mgr"
    echo -e "  Service Manager: $service_mgr"
    echo
    
    # Confirm installation immediately after system detection
    if ! confirm "Proceed with PhotonBBS installation?" "y"; then
        echo "Installation cancelled."
        exit 0
    fi
    
    # Run installation steps
    log "Starting PhotonBBS installation"
    
    if check_dependencies; then
        print_success "All dependencies are already installed"
    else
        if confirm "Install missing dependencies?" "y"; then
            install_dependencies
        else
            print_error "Cannot proceed without required dependencies"
            exit 1
        fi
    fi
    
    create_system_user
    setup_directories
    install_source
    compile_tty_wrapper
    setup_configuration
    install_service
    configure_firewall
    test_installation
    start_service
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "PhotonBBS installation completed in $duration seconds"
    
    show_completion_info
}

# Error handling
trap 'print_error "Installation failed. Check $LOG_FILE for details."; exit 1' ERR

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

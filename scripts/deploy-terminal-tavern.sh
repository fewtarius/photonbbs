#!/bin/bash
#
# Terminal Tavern BBS Deployment Script for DediHOST VPS
# Rocky Linux 9.7 (RHEL-based)
#
# This script automates the complete deployment of PhotonBBS Terminal Tavern theme
# including security hardening, Docker installation, and BBS deployment.
#
# Usage: ./deploy-terminal-tavern.sh <server-ip>
#

set -e  # Exit on any error
set -u  # Exit on undefined variable

# Configuration
SERVER_IP="${1:-198.23.197.94}"
BBS_USER="photonbbs"
BBS_HOME="/opt/photonbbs"
SSH_PORT="22"
TELNET_PORT="23"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Create non-root user
create_bbs_user() {
    echo_info "Creating PhotonBBS user..."
    
    ssh root@${SERVER_IP} "
        # Create user if doesn't exist
        if ! id ${BBS_USER} &>/dev/null; then
            useradd -m -s /bin/bash ${BBS_USER}
            usermod -aG wheel ${BBS_USER}
            echo '${BBS_USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${BBS_USER}
            chmod 440 /etc/sudoers.d/${BBS_USER}
            echo_success 'User ${BBS_USER} created'
        else
            echo_info 'User ${BBS_USER} already exists'
        fi
        
        # Set up SSH key
        mkdir -p /home/${BBS_USER}/.ssh
        cp /root/.ssh/authorized_keys /home/${BBS_USER}/.ssh/authorized_keys || true
        chown -R ${BBS_USER}:${BBS_USER} /home/${BBS_USER}/.ssh
        chmod 700 /home/${BBS_USER}/.ssh
        chmod 600 /home/${BBS_USER}/.ssh/authorized_keys
    "
    
    echo_success "User ${BBS_USER} configured"
}

# Step 2: Install Docker and docker-compose
install_docker() {
    echo_info "Installing Docker on Rocky Linux 9.7..."
    
    ssh root@${SERVER_IP} "
        # Install Docker repository
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        
        # Install Docker
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # Start and enable Docker
        systemctl start docker
        systemctl enable docker
        
        # Add photonbbs user to docker group
        usermod -aG docker ${BBS_USER}
        
        # Verify installation
        docker --version
        docker compose version
    "
    
    echo_success "Docker installed and configured"
}

# Step 3: Configure firewalld
configure_firewall() {
    echo_info "Configuring firewalld..."
    
    ssh root@${SERVER_IP} "
        # Install firewalld if not present
        dnf install -y firewalld
        
        # Start and enable firewalld
        systemctl start firewalld
        systemctl enable firewalld
        
        # Allow SSH and Telnet
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-port=${TELNET_PORT}/tcp
        
        # Reload firewall
        firewall-cmd --reload
        
        # Show status
        firewall-cmd --list-all
    "
    
    echo_success "Firewall configured (SSH 22, Telnet 23)"
}

# Step 4: Harden SSH
harden_ssh() {
    echo_info "Hardening SSH configuration..."
    
    ssh root@${SERVER_IP} "
        # Backup original config
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        
        # Configure SSH hardening
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
        
        # Verify SSH config
        sshd -t
        
        echo 'SSH hardening applied - root login disabled, key-only authentication'
    "
    
    echo_warning "SSH will be hardened but NOT restarted yet - do this manually after testing"
    echo_warning "Test SSH with: ssh ${BBS_USER}@${SERVER_IP}"
    echo_warning "Then restart: sudo systemctl restart sshd"
}

# Step 5: Install fail2ban
install_fail2ban() {
    echo_info "Installing fail2ban..."
    
    ssh root@${SERVER_IP} "
        # Install fail2ban and enable EPEL for Rocky
        dnf install -y epel-release
        dnf install -y fail2ban fail2ban-systemd
        
        # Configure fail2ban for SSH
        cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
EOF
        
        # Start and enable fail2ban
        systemctl start fail2ban
        systemctl enable fail2ban
        
        # Show status
        fail2ban-client status
    "
    
    echo_success "fail2ban installed and configured"
}

# Step 6: Deploy PhotonBBS
deploy_photonbbs() {
    echo_info "Deploying PhotonBBS Terminal Tavern..."
    
    # Create deployment directory
    ssh ${BBS_USER}@${SERVER_IP} "
        sudo mkdir -p ${BBS_HOME}
        sudo chown ${BBS_USER}:${BBS_USER} ${BBS_HOME}
    "
    
    # Clone PhotonBBS repository
    echo_info "Cloning PhotonBBS repository..."
    ssh ${BBS_USER}@${SERVER_IP} "
        cd ${BBS_HOME}
        git clone https://github.com/fewtarius/photonbbs.git .
        git checkout terminal_tavern
    "
    
    # Build and start PhotonBBS
    echo_info "Building and starting PhotonBBS Docker container..."
    ssh ${BBS_USER}@${SERVER_IP} "
        cd ${BBS_HOME}/docker
        docker compose build --no-cache
        docker compose up -d
        
        # Wait for container to start
        sleep 5
        
        # Check status
        docker compose ps
        docker compose logs --tail=20
    "
    
    echo_success "PhotonBBS deployed and running"
}

# Main deployment flow
main() {
    echo_info "Starting Terminal Tavern BBS deployment to ${SERVER_IP}"
    echo_info "=============================================="
    
    # Step-by-step deployment
    create_bbs_user
    install_docker
    configure_firewall
    install_fail2ban
    deploy_photonbbs
    
    # SSH hardening is done last and requires manual verification
    echo_warning "SSH hardening NOT applied yet - will be done after verification"
    
    echo_success "=============================================="
    echo_success "Deployment complete!"
    echo_info ""
    echo_info "Next steps:"
    echo_info "1. Test telnet: telnet ${SERVER_IP} 23"
    echo_info "2. Test SSH as photonbbs user: ssh ${BBS_USER}@${SERVER_IP}"
    echo_info "3. Apply SSH hardening: ./scratch/harden-ssh.sh ${SERVER_IP}"
    echo_info "4. Configure DNS: bbs.terminaltavern.com -> ${SERVER_IP}"
    echo_info ""
    echo_success "Terminal Tavern BBS is now live at: telnet ${SERVER_IP}"
}

# Run main deployment
main

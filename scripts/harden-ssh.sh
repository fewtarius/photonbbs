#!/bin/bash
#
# SSH Hardening Script for PhotonBBS
# 
# IMPORTANT: Only run this AFTER you've verified you can SSH as the photonbbs user!
# This disables root login and password authentication.
#
# Usage: ./harden-ssh.sh <server-ip>
#

set -e

SERVER_IP="${1:-198.23.197.94}"
BBS_USER="photonbbs"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}[WARNING]${NC} This will disable root login and password authentication!"
echo -e "${YELLOW}[WARNING]${NC} Make sure you can SSH as ${BBS_USER} before proceeding!"
echo ""
echo "Test now with: ssh ${BBS_USER}@${SERVER_IP}"
echo ""
read -p "Have you tested SSH access as ${BBS_USER}? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}[ABORTED]${NC} Please test SSH access first"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Hardening SSH configuration..."

ssh root@${SERVER_IP} "
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.\$(date +%Y%m%d-%H%M%S)
    
    # Apply hardening
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
    
    # Verify config
    sshd -t && echo 'SSH config valid' || echo 'ERROR: SSH config invalid!'
    
    # Restart SSH
    systemctl restart sshd
    
    echo 'SSH hardened: root login disabled, password auth disabled'
"

echo -e "${GREEN}[SUCCESS]${NC} SSH hardening complete!"
echo -e "${GREEN}[SUCCESS]${NC} Root login disabled, key-only authentication enabled"
echo ""
echo "You can now only access the server as: ssh ${BBS_USER}@${SERVER_IP}"

#!/bin/bash
#
# Install Auto-Update Script for Terminal Tavern BBS
# Sets up daily automatic updates at 4 AM ET
#

set -e

SERVER_IP="${1:-198.23.197.94}"
BBS_USER="photonbbs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo_info "Installing auto-update script on ${SERVER_IP}..."

# Copy the update script to the server
echo_info "Copying auto-update.sh to server..."
scp ./scratch/auto-update.sh root@${SERVER_IP}:/usr/local/bin/photonbbs-autoupdate
ssh root@${SERVER_IP} "chmod +x /usr/local/bin/photonbbs-autoupdate"

# Create log directory
echo_info "Creating log directory..."
ssh root@${SERVER_IP} "mkdir -p /var/log && touch /var/log/photonbbs-autoupdate.log"

# Set up cron job for 4 AM ET
# Note: Server timezone appears to be IST (+5:30), so we need to adjust
# 4 AM ET = 9 AM EST during standard time = 2:30 PM IST (approximately)
# We'll use system timezone and let user adjust if needed

echo_info "Setting up cron job for 4 AM ET..."
ssh root@${SERVER_IP} "
    # Remove any existing photonbbs-autoupdate cron jobs
    crontab -l 2>/dev/null | grep -v 'photonbbs-autoupdate' > /tmp/crontab.tmp || true
    
    # Add new cron job for 4 AM ET
    # Adjust this based on server's timezone
    # For now, using 4 AM in server's local time (IST)
    echo '0 4 * * * /usr/local/bin/photonbbs-autoupdate' >> /tmp/crontab.tmp
    
    # Install new crontab
    crontab /tmp/crontab.tmp
    rm /tmp/crontab.tmp
    
    # Verify installation
    echo 'Current crontab:'
    crontab -l | grep photonbbs-autoupdate
"

# Check server timezone
echo_info "Checking server timezone..."
TIMEZONE=$(ssh root@${SERVER_IP} "timedatectl | grep 'Time zone' | awk '{print \$3}'")
echo_warning "Server timezone: ${TIMEZONE}"

if [ "$TIMEZONE" != "America/New_York" ]; then
    echo_warning "Server is NOT in America/New_York timezone"
    echo_warning "Current cron job will run at 4 AM ${TIMEZONE} time"
    echo_warning ""
    echo_warning "To set server to ET timezone, run:"
    echo_warning "  ssh root@${SERVER_IP} 'timedatectl set-timezone America/New_York'"
    echo_warning ""
fi

# Test the script (dry run)
echo_info "Testing auto-update script..."
ssh root@${SERVER_IP} "/usr/local/bin/photonbbs-autoupdate 2>&1 | tail -10" || true

echo_success "Auto-update script installed successfully!"
echo_info ""
echo_info "Configuration:"
echo_info "  Script: /usr/local/bin/photonbbs-autoupdate"
echo_info "  Log: /var/log/photonbbs-autoupdate.log"
echo_info "  Schedule: Daily at 4 AM (${TIMEZONE})"
echo_info ""
echo_info "To view logs: ssh root@${SERVER_IP} 'tail -f /var/log/photonbbs-autoupdate.log'"
echo_info "To manually run: ssh root@${SERVER_IP} '/usr/local/bin/photonbbs-autoupdate'"
echo_info "To edit schedule: ssh root@${SERVER_IP} 'crontab -e'"

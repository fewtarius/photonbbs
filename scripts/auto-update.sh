#!/bin/bash
#
# Terminal Tavern BBS Auto-Update Script
# Rocky Linux 9.7
#
# Automatically updates system packages and reboots at 4 AM ET daily
# This script is designed to run via cron
#

set -e

LOGFILE="/var/log/photonbbs-autoupdate.log"
LOCK_FILE="/var/run/photonbbs-autoupdate.lock"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1" | tee -a "$LOGFILE"
}

# Check if already running
if [ -f "$LOCK_FILE" ]; then
    log "Update already in progress (lock file exists)"
    exit 1
fi

# Create lock file
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

log "Starting automatic system update..."

# Update package metadata
log "Updating package metadata..."
dnf check-update >> "$LOGFILE" 2>&1 || true

# Check if updates are available
UPDATES=$(dnf check-update -q | grep -v "^$" | wc -l)

if [ "$UPDATES" -eq 0 ]; then
    log "No updates available. Skipping."
    exit 0
fi

log "Found $UPDATES updates available"

# Perform update
log "Installing updates..."
dnf -y upgrade >> "$LOGFILE" 2>&1

# Check if reboot is required
NEEDS_REBOOT=0

# Check for kernel updates
if rpm -q --last kernel | head -1 | grep -q "$(date +%Y-%m-%d)"; then
    log "Kernel updated - reboot required"
    NEEDS_REBOOT=1
fi

# Check for systemd updates
if dnf list installed systemd 2>/dev/null | grep -q "$(date +%Y%m%d)"; then
    log "Systemd updated - reboot recommended"
    NEEDS_REBOOT=1
fi

# Check for glibc updates
if dnf list installed glibc 2>/dev/null | grep -q "$(date +%Y%m%d)"; then
    log "glibc updated - reboot recommended"
    NEEDS_REBOOT=1
fi

if [ "$NEEDS_REBOOT" -eq 1 ]; then
    log "Rebooting system in 60 seconds..."
    log "Updates completed successfully"
    
    # Give PhotonBBS users a warning
    wall "SYSTEM UPDATE: Server will reboot in 60 seconds for maintenance"
    
    # Wait 60 seconds
    sleep 60
    
    log "Initiating reboot now"
    /sbin/reboot
else
    log "Updates completed successfully - no reboot required"
fi

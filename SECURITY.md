# PhotonBBS Security System Documentation

## Overview

PhotonBBS includes comprehensive security features to protect against dictionary attacks, brute-force login attempts, and other malicious activities. The security system includes:

1. **Failed Login Tracking** - Monitors and records failed login attempts
2. **Automatic IP Banning** - Auto-bans IPs after repeated failures
3. **Manual IP Management** - Sysop tools for managing bans
4. **Fail2Ban Integration** - Works with fail2ban for iptables blocking
5. **IP Whitelisting** - Protect trusted IPs from being banned

---

## Security Configuration

All security settings are in `modules/pb-defaults`:

```perl
## Security settings
sec_track_failed_logins => "1",      # Track failed login attempts (1 = Yes, 0 = No)
sec_failed_threshold => "5",          # Number of failed logins before auto-ban
sec_failed_window => "600",           # Time window in seconds (default: 10 minutes)
sec_autoban_duration => "3600",       # Auto-ban duration in seconds (default: 1 hour, 0 = permanent)
sec_log_failures => "1",              # Log failed login attempts (1 = Yes, 0 = No)
sec_whitelist_enabled => "0",         # Enable IP whitelist (1 = Yes, 0 = No)
```

### Configuration Options

- **sec_track_failed_logins**: Enable/disable tracking of failed logins
- **sec_failed_threshold**: Number of failures before auto-ban (default: 5)
- **sec_failed_window**: Time window for counting failures in seconds (default: 600 = 10 minutes)
- **sec_autoban_duration**: How long auto-bans last in seconds (0 = permanent, default: 3600 = 1 hour)
- **sec_log_failures**: Log failed attempts to syslog (default: enabled)
- **sec_whitelist_enabled**: Enable IP whitelist protection (default: disabled)

---

## How It Works

### 1. Failed Login Detection

When a user enters an incorrect password:

1. The attempt is logged to `/appdata/failed_logins`
2. Entry format: `timestamp|ip_address|username`
3. If syslog logging is enabled, event is logged to syslog

### 2. Automatic Banning

After each failed login:

1. System counts recent failures from that IP
2. If count exceeds `sec_failed_threshold` within `sec_failed_window`:
   - IP is added to `/appdata/banned_ip`
   - Ban entry includes: `ip|reason|expiry_timestamp`
   - Connection is immediately terminated
   - Event is logged to syslog

### 3. Ban Enforcement

When a connection is attempted:

1. PhotonBBS daemon checks `/appdata/banned_ip`
2. If IP matches (supports regex patterns):
   - Checks if ban has expired
   - If active, connection is rejected immediately
   - User sees "banned IP" message and is disconnected

### 4. Ban Expiration

Auto-bans can be temporary or permanent:

- **Temporary**: `sec_autoban_duration > 0` (e.g., 3600 = 1 hour)
- **Permanent**: `sec_autoban_duration = 0`

Expired bans are automatically ignored without requiring cleanup.

---

## Data Files

### `/appdata/banned_ip`

Format: `ip_address|reason|expiry_timestamp`

Example:
```
192.168.1.100|Auto-ban: 5 failed logins|1735603200
10.0.0.50|Manually banned by sysop|0
```

- **Field 1**: IP address or regex pattern
- **Field 2**: Reason for ban
- **Field 3**: Unix timestamp when ban expires (0 = never)

### `/appdata/failed_logins`

Format: `timestamp|ip_address|username`

Example:
```
1735599600|192.168.1.100|admin
1735599620|192.168.1.100|root
1735599640|192.168.1.100|sysop
```

Old entries are automatically cleaned up to prevent file growth.

### `/appdata/whitelist_ip`

Format: One IP or pattern per line (when enabled)

Example:
```
# Whitelist file
127.0.0.1
192.168.1.0/24
10.0.0.5
```

Whitelisted IPs are never banned, even if they trigger the threshold.

---

## Sysop Commands

### Security Dashboard

**Command**: Add to BBS menu or create door script

**Function**: `security_dashboard()` from `pb-security-admin` module

**Features**:
- View all banned IPs with reasons and expiry times
- See recent failed login attempts (last 20)
- View security statistics
- Access ban management commands

**Menu Entry Example**:
```
S:sysop_menu:Security Dashboard
INTERNAL:security_dashboard
```

### Available Commands in Dashboard

1. **(B)an IP** - Manually ban an IP address
   - Enter IP address or pattern
   - Specify reason
   - Set duration (seconds, 0 = permanent)

2. **(U)nban IP** - Remove an IP from ban list
   - Enter exact IP to unban
   - Immediately takes effect

3. **(W)hitelist** - Manage whitelisted IPs
   - View current whitelist
   - Add IP to whitelist
   - Enable/disable whitelist (requires config change)

4. **(R)efresh** - Reload dashboard data

5. **(Q)uit** - Return to main menu

---

## Fail2Ban Integration

PhotonBBS includes fail2ban jail and filter configurations for additional protection.

### Installation

1. **Copy jail configuration**:
   ```bash
   sudo cp configs/fail2ban/jail.d/photonbbs.conf /etc/fail2ban/jail.d/
   ```

2. **Copy filter configuration**:
   ```bash
   sudo cp configs/fail2ban/filter.d/photonbbs.conf /etc/fail2ban/filter.d/
   ```

3. **Test the configuration**:
   ```bash
   sudo fail2ban-client reload
   sudo fail2ban-client status photonbbs
   ```

### How Fail2Ban Works

1. Monitors syslog for PhotonBBS failed login messages
2. Counts failures per IP within time window
3. When threshold is exceeded:
   - Creates iptables rule to block IP
   - Blocks ALL ports (not just telnet)
   - Ban duration is independent of PhotonBBS auto-ban

### Fail2Ban Configuration

In `/etc/fail2ban/jail.d/photonbbs.conf`:

```ini
maxretry = 5       # Failures before ban
findtime = 600     # Time window (10 minutes)
bantime = 3600     # Ban duration (1 hour)
```

### Checking Fail2Ban Status

```bash
# View PhotonBBS jail status
sudo fail2ban-client status photonbbs

# View currently banned IPs
sudo fail2ban-client get photonbbs banned

# Manually unban an IP
sudo fail2ban-client set photonbbs unbanip 192.168.1.100
```

---

## Testing the Security System

### Test Auto-Ban

1. Connect via telnet to PhotonBBS
2. Try to login with wrong password 5 times
3. Should be auto-banned after 5th attempt
4. Try to reconnect - should be rejected immediately

### Test Ban Expiry

1. Set `sec_autoban_duration = 60` (1 minute)
2. Trigger auto-ban (5 failed logins)
3. Wait 61 seconds
4. Try to connect - should be allowed

### Test Whitelist

1. Set `sec_whitelist_enabled = 1` in config
2. Add your IP to `/appdata/whitelist_ip`
3. Try failed logins from that IP
4. Should not be banned

### View Security Logs

```bash
# View PhotonBBS security events in syslog
sudo grep "photonbbs.*SECURITY" /var/log/syslog

# View failed login attempts
sudo grep "photonbbs.*WARN.*incorrect password" /var/log/syslog

# View auto-ban events
sudo grep "photonbbs.*Auto-banned" /var/log/syslog
```

---

## Maintenance

### Clean Up Old Failed Login Attempts

Old entries are automatically cleaned during failed login tracking.
Manual cleanup is not normally required.

### Review Banned IPs

1. Use Security Dashboard (sysop command)
2. Or manually check `/appdata/banned_ip`

### Remove Expired Bans

Expired bans are automatically ignored and don't need removal.

For manual cleanup:
```bash
# Backup ban file
cp /appdata/banned_ip /appdata/banned_ip.backup

# Remove expired bans (manual script needed)
# Or use Security Dashboard to unban manually
```

---

## Security Best Practices

### Recommended Settings

For production BBS:
```perl
sec_track_failed_logins => "1",      # Always track
sec_failed_threshold => "5",          # Standard threshold
sec_failed_window => "600",           # 10 minute window
sec_autoban_duration => "3600",       # 1 hour temporary ban
sec_log_failures => "1",              # Always log
sec_whitelist_enabled => "1",         # Enable for trusted IPs
```

For high-security BBS:
```perl
sec_failed_threshold => "3",          # Stricter threshold
sec_failed_window => "900",           # 15 minute window
sec_autoban_duration => "0",          # Permanent bans
```

### Additional Recommendations

1. **Enable fail2ban** - Provides iptables-level blocking
2. **Monitor logs regularly** - Check for attack patterns
3. **Whitelist your IPs** - Prevent accidental lockout
4. **Review bans weekly** - Check for false positives
5. **Keep syslog enabled** - Essential for forensics

### Protecting Against Lockout

If you're worried about locking yourself out:

1. **Add your IP to whitelist**:
   ```bash
   echo "your.ip.address" >> /appdata/whitelist_ip
   ```

2. **Enable whitelist**:
   ```perl
   sec_whitelist_enabled => "1",
   ```

3. **Keep localhost whitelisted**:
   ```bash
   echo "127.0.0.1" >> /appdata/whitelist_ip
   ```

### Emergency Unban

If you're locked out:

```bash
# SSH to server
ssh your-server

# Remove your IP from ban list
sed -i '/your.ip.address/d' /appdata/banned_ip

# Or disable security temporarily
mv /appdata/banned_ip /appdata/banned_ip.disabled
```

---

## Troubleshooting

### "IP has been banned" message but IP not in banned_ip

- Check fail2ban: `sudo fail2ban-client status photonbbs`
- Your IP may be banned by fail2ban, not PhotonBBS
- Unban from fail2ban: `sudo fail2ban-client set photonbbs unbanip YOUR_IP`

### Failed logins not being tracked

- Check `sec_track_failed_logins = 1` in pb-defaults
- Verify pb-security module is loading
- Check file permissions on `/appdata/failed_logins`

### Auto-bans not working

- Verify threshold/window settings are correct
- Check that pb-security functions are being called
- Review syslog for security messages

### Whitelist not working

- Verify `sec_whitelist_enabled = 1`
- Check whitelist file exists: `/appdata/whitelist_ip`
- Ensure IP format is correct in whitelist file

---

## API Reference

### pb-security Module Functions

```perl
# Record a failed login attempt
# Returns 1 if IP should be auto-banned, 0 otherwise
my $banned = record_failed_login($ip, $username);

# Check if an IP is banned
# Returns (banned, reason, expires_at) or (0, undef, undef)
my ($is_banned, $reason, $expires) = check_ip_banned($ip);

# Manually ban an IP
# $expires: Unix timestamp or 0 for permanent
my $success = manual_ban_ip($ip, $reason, $expires);

# Unban an IP
my $success = unban_ip($ip);

# Get all banned IPs
# Returns array of hashrefs: { ip, reason, expires }
my @bans = get_banned_ips();

# Get failed login statistics
# Returns array of hashrefs: { timestamp, ip, username, ago }
my @attempts = get_failed_login_stats($limit);

# Check if IP is whitelisted
my $is_whitelisted = is_ip_whitelisted($ip);

# Clean up old login attempts
cleanup_old_login_attempts();
```

### pb-security-admin Module Functions

```perl
# Display security dashboard (sysop only)
security_dashboard();

# Ban IP via interactive prompt
ban_ip_command();

# Unban IP via interactive prompt
unban_ip_command();

# Manage whitelist via interactive menu
manage_whitelist();
```

---

## Version History

### v1.0 (January 2025)
- Initial security system implementation
- Failed login tracking
- Automatic IP banning with expiry
- Fail2ban integration
- Sysop security dashboard
- IP whitelist support

---

## Support

For issues or questions:
- GitHub: https://github.com/fewtarius/photonbbs
- BBS: telnet bbs.terminaltavern.com

## License

PhotonBBS Security System
Copyright (C) 2025 Fewtarius
GNU General Public License v2

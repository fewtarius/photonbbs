# PhotonBBS Hourly Maintenance Scripts

This directory contains scripts that run **every hour** at the top of the hour (when minutes = 00).

## Configuration

Hourly execution is triggered automatically by the PhotonBBS daemon every hour on the hour.

## How It Works

1. The PhotonBBS daemon monitors the system clock every 30 seconds
2. When the minute is 00 and the hour has changed from the last check
3. Each executable file in this directory is launched as the `nobody` user
4. Scripts run in separate threads and can execute in parallel

## Execution Logic

From `photonbbs` daemon (lines 575-578):
```perl
# Run hourly.d at the top of the hour
if ($min == 0 && $hour != $last_hour) {
    $last_hour = $hour;
    run_hourly_programs();
}
```

The `$last_hour` check ensures scripts run **only once per hour** even if the daemon checks multiple times during minute 00.

## Current Scripts

*No hourly maintenance scripts are currently configured.*

## Adding New Hourly Tasks

To add a new hourly maintenance task:

1. Create an executable script in this directory
2. Make it executable: `chmod +x hourly.d/your-script`
3. The script will run as user `nobody` with these environment variables:
   - `PHOTONBBS_HOME` - Path to PhotonBBS installation (default: /opt/photonbbs)
4. Scripts should be idempotent (safe to run multiple times)
5. Scripts should complete quickly (they run every hour)
6. Use proper logging for troubleshooting

## Example Script Template

```bash
#!/bin/bash
# PhotonBBS Hourly Maintenance: Your Task Name
# Description of what this script does

PHOTONBBS_HOME="${PHOTONBBS_HOME:-/opt/photonbbs}"

echo "[hourly.d] [your-task] Starting at $(date)"

# Your maintenance logic here

echo "[hourly.d] [your-task] Completed at $(date)"
exit 0
```

## Testing

To manually test an hourly script:
```bash
# As root or with sudo:
su -s /bin/sh nobody -c '/path/to/photonbbs/hourly.d/your-script'

# Or for development (as your user):
PHOTONBBS_HOME=. ./hourly.d/your-script
```

## Troubleshooting

- Scripts must be **executable** (`chmod +x`)
- Scripts run as user **nobody** (limited permissions)
- Check daemon logs for execution messages: `[bbsd] [HOURLY] Launching...`
- The directory is auto-created if missing (daemon creates it at startup)
- Scripts that crash or hang will be logged: `[bbsd] [HOURLY] ... exited with code X`

## Related Directories

- **services.d/** - Programs that run continuously (daemons)
- **hourly.d/** - Scripts that run every hour (this directory)
- **daily.d/** - Scripts that run once per day at midnight

# PhotonBBS Daily Maintenance Scripts

This directory contains scripts that run **once per day** at the configured hour (default: midnight).

## Configuration

The daily execution time is controlled by the `DAILY_RUN_HOUR` variable in the main `photonbbs` daemon:

```perl
my $DAILY_RUN_HOUR = 0; # 0 = Midnight, 1 = 1 AM, etc.
```

## How It Works

1. The PhotonBBS daemon monitors the system clock every 30 seconds
2. When the current hour matches `DAILY_RUN_HOUR` and the minute is 0
3. Each executable file in this directory is launched as the `nobody` user
4. Scripts run in separate threads and can execute in parallel

## Execution Logic

From `photonbbs` daemon (lines 579-583):
```perl
# Run daily.d at DAILY_RUN_HOUR (default: midnight)
if ($hour == $DAILY_RUN_HOUR && $min == 0 && $mday != $last_day) {
    $last_day = $mday;
    run_daily_programs();
}
```

The `$mday` check ensures scripts run **only once per day** even if the daemon is running at exactly midnight:00 for multiple check cycles.

## Current Scripts

- **reset-lastcallers** - Deletes the lastcallers file to reset the daily caller log

## Adding New Daily Tasks

To add a new daily maintenance task:

1. Create an executable script in this directory
2. Make it executable: `chmod +x daily.d/your-script`
3. The script will run as user `nobody` with these environment variables:
   - `PHOTONBBS_HOME` - Path to PhotonBBS installation (default: /opt/photonbbs)
4. Scripts should be idempotent (safe to run multiple times)
5. Scripts should handle missing files/directories gracefully
6. Use proper logging for troubleshooting

## Example Script Template

```bash
#!/bin/bash
# PhotonBBS Daily Maintenance: Your Task Name
# Description of what this script does

PHOTONBBS_HOME="${PHOTONBBS_HOME:-/opt/photonbbs}"

echo "[daily.d] [your-task] Starting at $(date)"

# Your maintenance logic here

echo "[daily.d] [your-task] Completed at $(date)"
exit 0
```

## Testing

To manually test a daily script:
```bash
# As root or with sudo:
su -s /bin/sh nobody -c '/path/to/photonbbs/daily.d/reset-lastcallers'

# Or for development (as your user):
PHOTONBBS_HOME=. ./daily.d/reset-lastcallers
```

## Troubleshooting

- Scripts must be **executable** (`chmod +x`)
- Scripts run as user **nobody** (limited permissions)
- Check daemon logs for execution messages: `[bbsd] [DAILY] Launching...`
- The directory is auto-created if missing (daemon creates it at startup)
- Scripts that crash or hang will be logged: `[bbsd] [DAILY] ... exited with code X`

## Related Directories

- **services.d/** - Programs that run continuously (daemons)
- **hourly.d/** - Scripts that run every hour (on the hour)
- **daily.d/** - Scripts that run once per day (this directory)

# AGENTS.md

**Version:** 1.0  
**Date:** 2026-02-16  
**Purpose:** Technical reference for PhotonBBS development (methodology in .clio/instructions.md)

---

## Project Overview

**PhotonBBS** is a comprehensive telnet-based bulletin board system (BBS) and multi-user dungeon (MUD) platform.

- **Language:** Perl 5 (no strict package declarations), C (TTY wrapper)
- **Architecture:** Multi-process daemon with modular Perl scripts
- **Deployment:** Docker containerized, telnet on port 23
- **License:** GPL v2+
- **Repository:** https://github.com/fewtarius/photonbbs

### Core Components

| Component | Description |
|-----------|-------------|
| **PhotonBBS** | BBS platform - chat, bulletins, door games, user management |
| **PhotonMUD** | Multi-user dungeon with procedural world generation |
| **photonmud-monsterai** | Monster AI and spawning system |
| **photonbbs-tty** | C-based telnet protocol negotiation wrapper |

---

## Quick Setup

```bash
# Clone repository
git clone https://github.com/fewtarius/photonbbs.git
cd photonbbs

# Build Docker image
make docker-build

# Start PhotonBBS
make docker-up

# View logs
make docker-logs

# Connect via telnet
telnet localhost 23

# Stop container
make docker-down

# Build TTY wrapper (local development)
make all
```

---

## Architecture

```
Telnet Connection (port 23)
    |
    v
photonbbs-tty (C wrapper - telnet negotiation)
    |
    v
photonbbs (Perl daemon)
    |
    +-- Fork per connection
    |
    v
photonbbs-client (Perl)
    |
    +-- pb-framework (core utilities)
    +-- pb-main (menu system, teleconference)
    +-- pb-doors (door game integration)
    +-- pb-security (auth/access control)
    |
    v
PhotonMUD (optional)
    |
    +-- pm-rooms (world/room management)
    +-- pm-combat (D&D-style combat)
    +-- pm-monsters (monster definitions)
    +-- pm-spells (magic system)
    +-- pm-player (character management)
    +-- pm-objects (items/equipment)
    |
    v
Data Persistence (Storable .dat files)
```

### Process Model

- **photonbbs**: Main daemon, binds port 23, forks per connection
- **photonbbs-client**: Per-user session process
- **photonmud**: MUD game engine (spawned from BBS)
- **photonmud-monsterai**: Background monster AI process

---

## Directory Structure

| Path | Purpose |
|------|---------|
| `modules/` | Core Perl modules (pb-* for BBS, pm-* for MUD) |
| `sbin/` | Executables (photonmud, photonbbs-client, photonbbs-tty) |
| `tools/` | Development utilities and importers |
| `data/` | Runtime data (menus, themes, bulletins) |
| `configs/` | Configuration files |
| `docker/` | Docker deployment files |
| `doorexec/` | Door game execution scripts |
| `doors/` | Door game configurations |
| `daily.d/` | Daily maintenance scripts |
| `hourly.d/` | Hourly maintenance scripts |
| `services.d/` | Service scripts (s6 init) |
| `src/` | C source code (photonbbs-tty.c) |
| `scripts/` | Utility scripts |
| `reference/` | Reference data (monster imports, etc.) |
| `scratch/` | Working documents (gitignored) |
| `ai-assisted/` | Session handoffs (gitignored) |

### Key Files

| File | Purpose |
|------|---------|
| `photonbbs` | Main daemon executable |
| `sbin/photonbbs-client` | Per-user client |
| `sbin/photonmud` | MUD game engine (~98K lines) |
| `sbin/photonmud-monsterai` | Monster AI daemon (~164K lines) |
| `sbin/photonmud-generator` | World generator (~244K lines) |
| `modules/pb-framework` | Core BBS utilities (~44K) |
| `modules/pb-main` | Main menu/teleconference (~59K) |
| `modules/pm-combat` | Combat system (~239K) |
| `modules/pm-rooms` | Room/world management (~93K) |

---

## Code Style

**Perl Conventions:**

- **No `package` declarations** - Modules run in `main::` namespace
- **No `use strict; use warnings;`** in modules - inherited from main
- Use `require_module()` for loading modules
- 4-space indentation (no tabs)
- End all modules with `1;`

**Module Template:**

```perl
#!/usr/bin/perl
# Module Name: pb-your-module
# Purpose: Brief description

# Access config via %config hash
# Access user via %info hash
# Use main::writeline() for output
# Use main::getline() for input

sub your_function {
    main::writeline($CLR, 0);  # Clear screen
    main::writeline($config{'themecolor'}."\nYour Screen".$RST, 1);
    main::writeline("", 1);
    
    my $input = main::getline('text', 50, "", 1);
    
    main::writeline($config{'systemcolor'}."Done".$RST, 1);
}

1;  # Module must return true
```

**Color/Theme System:**

```perl
# Available color variables from %config
$config{'themecolor'}   # Primary theme color
$config{'datacolor'}    # Data values
$config{'usercolor'}    # Usernames, highlights
$config{'systemcolor'}  # System messages
$config{'errorcolor'}   # Error messages
$config{'promptcolor'}  # Command keys
$config{'inputcolor'}   # User input
$config{'linecolor'}    # Separators

# Always reset colors
main::writeline($config{'themecolor'}."Text".$RST, 1);
```

**UI Formatting Rules (See PHOTONBBS_STYLE_GUIDE.md):**

- NO Unicode box drawing characters
- NO fancy ASCII art headers
- Use `key ... description` format for menus
- Simple, clean text formatting
- Follow existing teleconference/menu patterns

---

## Module Naming Conventions

| Prefix | Purpose | Examples |
|--------|---------|----------|
| `pb-` | BBS core functionality | pb-framework, pb-main, pb-doors, pb-security |
| `pm-` | MUD game logic | pm-combat, pm-rooms, pm-monsters, pm-spells |

### BBS Modules (pb-*)

| Module | Purpose |
|--------|---------|
| `pb-defaults` | Configuration defaults |
| `pb-framework` | Core utilities (I/O, locking, date/time) |
| `pb-main` | Main menu, teleconference, commands |
| `pb-doors` | External door game integration |
| `pb-security` | Authentication, access control |
| `pb-security-admin` | SysOp security tools |
| `pb-usertools` | User profile/account tools |
| `pb-oneliners` | Wall/oneliner system |
| `pb-lastcallers` | Recent caller tracking |

### MUD Modules (pm-*)

| Module | Purpose |
|--------|---------|
| `pm-defaults` | MUD configuration |
| `pm-rooms` | Room/world management, navigation |
| `pm-combat` | D&D-style combat system |
| `pm-monsters` | Monster definitions and AI |
| `pm-spells` | Magic system (20+ spells) |
| `pm-player` | Character management |
| `pm-objects` | Items, equipment, inventory |
| `pm-containers` | Container objects |
| `pm-market` | Trading/economy system |
| `pm-messaging` | In-game messaging |
| `pm-npcs` | Non-player characters |
| `pm-cache` | Data caching |
| `pm-utils` | MUD utilities |
| `pm-broker-client` | Inter-process communication |

---

## Testing

**Before Committing:**

```bash
# 1. Syntax check specific module
perl -c modules/pb-your-module

# 2. Check all modules
for f in modules/pb-* modules/pm-*; do perl -c "$f"; done

# 3. Check sbin executables
perl -c sbin/photonmud
perl -c sbin/photonbbs-client

# 4. Build TTY wrapper
make clean && make all

# 5. Docker integration test
make docker-rebuild
telnet localhost 23
```

**Test Environment:**

```bash
# Local development (without Docker)
./photonbbs --debug

# Docker testing
make docker-up
make docker-logs
make docker-shell  # Access container shell
```

**Test Checklist:**

1. All changed Perl files pass `perl -c`
2. TTY wrapper compiles (if modified)
3. Docker container starts
4. Can connect via telnet
5. BBS menus work
6. MUD functionality (if changed)

---

## Commit Format

```
Component: Brief description

Problem: What was broken/incomplete
Solution: How you fixed it
Testing: How you verified
```

**Components:**
- `PhotonBBS` - BBS functionality
- `PhotonMUD` - MUD functionality
- `docs` - Documentation
- `docker` - Container/deployment
- `security` - Security fixes

**Examples:**

```bash
# Feature
git commit -m "PhotonBBS: Add user preference menu

Problem: Users couldn't customize settings
Solution: Added pb-userprefs module with theme selection
Testing: Verified menu loads, settings persist"

# Security fix
git commit -m "security(critical): Fix command injection vulnerability

Problem: User input passed to shell unsanitized
Solution: Added input validation and quoting
Testing: Verified exploit no longer works"

# MUD change
git commit -m "PhotonMUD: Balance dragon combat damage

Problem: Dragons too powerful for mid-level players
Solution: Reduced damage dice from 3d12 to 2d10
Testing: Tested combat at levels 5-15"
```

---

## Development Tools

**Makefile Targets:**

```bash
# TTY wrapper
make all           # Build photonbbs-tty
make clean         # Clean build
make debug         # Build with debug symbols
make install       # System install
make install-local # User install (~/.local)

# Docker
make docker-build   # Build image
make docker-up      # Start container
make docker-down    # Stop container
make docker-restart # Restart
make docker-logs    # View logs
make docker-shell   # Shell into container
make docker-rebuild # Full rebuild
make docker-clean   # Remove everything

# Help
make help           # Show all targets
```

**Development Commands:**

```bash
# Search codebase
grep -r "pattern" modules/
grep -r "pattern" sbin/

# Find large modules
wc -l modules/* sbin/* | sort -rn | head -20

# Check module dependencies
grep "require" modules/pb-main

# Git operations
git status
git log --oneline -10
git diff
```

---

## Common Patterns

**File Locking (pb-framework):**

```perl
# Use global lock hash
our %GLOBAL_LOCK_FH;

# Lock file before access
open($GLOBAL_LOCK_FH{$file}, "+<", $file) or die;
flock($GLOBAL_LOCK_FH{$file}, LOCK_EX);

# ... do work ...

# Unlock
flock($GLOBAL_LOCK_FH{$file}, LOCK_UN);
close($GLOBAL_LOCK_FH{$file});
delete $GLOBAL_LOCK_FH{$file};
```

**Data Persistence (Storable):**

```perl
use Storable qw(store retrieve lock_store lock_retrieve);

# Write data
lock_store(\%data, "$config{'home'}/$config{'data'}/file.dat");

# Read data
my $data = lock_retrieve("$config{'home'}/$config{'data'}/file.dat");
```

**User Output:**

```perl
# writeline(text, newline_flag)
main::writeline($config{'themecolor'}."Hello".$RST, 1);  # With newline
main::writeline($config{'promptcolor'}."Enter: ".$RST);  # No newline

# getline(type, maxlen, default, echo)
my $input = main::getline('text', 50, "", 1);
my $pass = main::getline('password', 30, "", 0);  # No echo
```

**Menu Format:**

```perl
# Standard menu item format
main::writeline("  ".$config{'promptcolor'}."A".$config{'themecolor'}." ... ".$config{'usercolor'}."Action".$RST, 1);
main::writeline("  ".$config{'promptcolor'}."Q".$config{'themecolor'}." ... ".$config{'usercolor'}."Quit".$RST, 1);
```

**Error Handling:**

```perl
# Use eval for error catching
eval {
    # Risky operation
};
if ($@) {
    main::writeline($config{'errorcolor'}."Error: $@".$RST, 1);
    return;
}
```

---

## Documentation

### What Needs Documentation

| Change Type | Required Documentation |
|-------------|------------------------|
| New BBS feature | Update PHOTONBBS.md |
| New MUD feature | Update PHOTONMUD.md |
| UI changes | Update PHOTONBBS_STYLE_GUIDE.md |
| New module | Add header comments |
| API change | Update DEVELOPER.md |
| Security fix | Update SECURITY.md |

### Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| `README.md` | Project overview | Everyone |
| `PHOTONBBS.md` | BBS user/admin guide | Users, SysOps |
| `PHOTONMUD.md` | MUD gameplay guide | Players |
| `DEVELOPER.md` | Extension guide | Contributors |
| `SECURITY.md` | Security information | SysOps |
| `PHOTONBBS_STYLE_GUIDE.md` | UI/UX standards | Developers |

---

## Anti-Patterns (What NOT To Do)

| Anti-Pattern | Why It's Wrong | What To Do |
|--------------|----------------|------------|
| Skip `perl -c` before commit | Silent syntax errors | Always syntax check |
| Use Unicode box drawing | Breaks terminal compatibility | Use simple ASCII text |
| Add `use strict` to modules | Conflicts with main namespace | Rely on inherited pragmas |
| Create `package` declarations | Breaks module loading | Run in main:: namespace |
| Fork to `date` command | Expensive, use Perl | Use POSIX strftime |
| Raw `die` in modules | Crashes session ungracefully | Use eval and error messages |
| Commit ai-assisted/ files | Pollutes repository | Reset before commit |
| Skip Docker testing | Miss container issues | Test in Docker always |
| Create summary docs in root | Wrong location | Use scratch/ for working docs |

---

## Quick Reference

**Syntax Check:**
```bash
perl -c modules/pb-module
perl -c sbin/photonmud
```

**Docker:**
```bash
make docker-up      # Start
make docker-logs    # Logs
make docker-shell   # Shell
make docker-down    # Stop
```

**Connect:**
```bash
telnet localhost 23
```

**Search:**
```bash
grep -r "pattern" modules/ sbin/
```

**Git:**
```bash
git status
git add -A && git commit -m "Component: description"
```

**Build:**
```bash
make all            # Build TTY wrapper
make docker-rebuild # Full Docker rebuild
```

---

*For project methodology and workflow, see .clio/instructions.md*  
*For UI/UX standards, see PHOTONBBS_STYLE_GUIDE.md*

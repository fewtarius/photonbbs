# CLIO Project Instructions - PhotonBBS Development

**Project:** PhotonBBS - Telnet BBS and MUD Platform  
**Language:** Perl, shell scripts  
**Architecture:** Integrated telnet-based bulletin board system and multi-user dungeon  
**Repository:** https://github.com/fewtarius/photonbbs  

---

## CRITICAL: READ FIRST BEFORE ANY WORK

### The Unbroken Method (Core Principles)

This project follows **The Unbroken Method** for human-AI collaboration. This is the core operational framework that governs all development.

**The Seven Pillars:**

1. **Continuous Context** - Never break the conversation. Maintain momentum through collaboration checkpoints.
2. **Complete Ownership** - If you find a bug, fix it. No "out of scope."
3. **Investigation First** - Read code before changing it. Never assume.
4. **Root Cause Focus** - Fix problems, not symptoms.
5. **Complete Deliverables** - No partial solutions. Finish what you start.
6. **Structured Handoffs** - Document everything for the next session.
7. **Learning from Failure** - Document mistakes to prevent repeats.

**If you skip this, you will violate the project's core methodology.**

### Collaboration Checkpoint Discipline

**Use collaboration tool at EVERY key decision point:**

| Checkpoint | When | Purpose |
|-----------|------|---------|
| Session Start | Always | Confirm context & plan |
| After Investigation | Before implementation | Share findings, get approval |
| After Implementation | Before commit | Show results, get OK |
| Session End | When work complete | Summary & handoff |

**[FAIL]** Create documentation/implementations alone  
**[OK]** Investigate freely, but checkpoint before committing changes

---

## Quick Start for NEW DEVELOPERS

### Before Touching Code

1. **Understand the system:**
   ```bash
   cat README.md                    # Project overview
   cat DEVELOPER.md                 # Developer documentation
   cat PHOTONBBS.md                 # BBS documentation
   cat PHOTONMUD.md                 # MUD documentation
   cat PHOTONBBS_STYLE_GUIDE.md    # Coding standards
   ```

2. **Know the architecture:**
   - **BBS Platform**: Classic telnet bulletin board system with chat, doors, and menus
   - **MUD Integration**: PhotonMUD is seamlessly integrated with procedurally-generated worlds
   - **Menu System**: File-driven menus in `data/` with `.mnu` format
   - **Door Games**: Support for classic DOS games (Legend of the Red Dragon, Trade Wars 2002, etc.)
   - **Multi-node**: Supports multiple simultaneous connections with shared state

3. **Key standards:**
   - Perl files: `use strict; use warnings; use utf8;`
   - Shell scripts: Use consistent quoting and error handling
   - Menu format: Key|Description|Script|SecurityLevel|Hidden|Type|MaxUsers
   - Telnet protocol compliance: All output must be telnet-safe
   - Syntax check: `perl -c photonbbs` and `perl -c modules/ModuleName.pm`

4. **Use the toolchain:**
   ```bash
   telnet localhost 2323           # Test BBS connection
   ./photonbbs                      # Start BBS server
   git status                       # Always check before work
   git log --oneline -10            # Review recent changes
   ```

### Core Workflow

```
1. Read code first (investigation)
2. Use collaboration tool (get approval)
3. Make changes (implementation)
4. Test on telnet (verify BBS+MUD integration)
5. Commit with clear message (handoff)
```

---

## Key Directories & Files

### Core Files
| File | Purpose |
|------|---------|
| `photonbbs` | Main BBS server executable |
| `modules/*.pm` | Perl modules (core BBS functionality) |
| `startscript` | BBS startup script |
| `sbin/photonbbs-tty` | TTY interface handler |
| `docker/Dockerfile` | Container configuration |

### Key Directories
| Path | Purpose |
|------|---------|
| `modules/` | Core BBS and MUD modules (Phoenix, Room, Realm, Combat, etc.) |
| `data/` | Menu files, configuration data, room/realm data |
| `doors/` | Door game implementations and wrappers |
| `doorexec/` | Door execution environment |
| `scripts/` | Utility scripts and helpers |
| `configs/` | Configuration files |
| `services.d/` | Service definitions |
| `daily.d/` / `hourly.d/` | Scheduled tasks |
| `docker/` | Docker deployment configuration |
| `tools/` | Development and testing tools |
| `scratch/` | Development notes and reference materials |
| `reference/` | Reference documentation |

---

## Architecture Overview

```
Telnet User Connection
    v
BBS Server (photonbbs main loop)
    v
Session Manager (user login, persistence)
    v
Main Menu System (menu files in data/)
    ├─ Internal Commands (chat, mail, etc.)
    ├─ Door Games (tradewars, legend, etc.)
    ├─ Submenus (submenu navigation)
    └─ MUD Access (PhotonMUD integration)
    v
MUD Engine (PhotonMUD)
    ├─ Procedurally-generated realms
    ├─ Dynamic combat system
    ├─ Spell/ability system
    ├─ Multi-player interaction
    └─ Persistent state
    v
Data Persistence (disk storage)
```

---

## Code Standards: MANDATORY

### Perl Module Format
```perl
#!/usr/bin/perl

use strict;
use warnings;
use utf8;

=head1 NAME
ModuleName - Brief description

=head1 DESCRIPTION
Detailed description of what this module does

=head1 USAGE
Example code showing how to use the module

=cut

package YourPackage;

# Implementation...

1;  # MANDATORY: End every .pm file with 1;
```

### Shell Script Format
```bash
#!/bin/bash

# Brief description of what this script does

set -e  # Exit on error

# Implementation...

exit 0
```

### Telnet Output: UTF-8 and ANSI Safe
```perl
# CORRECT: All output must be telnet-safe
print "\r\n"; # Telnet line endings
print "\033[1;32m"; # ANSI color (green bold)
print "Message\r\n";
print "\033[0m"; # Reset

# FAIL: Unix line endings fail on telnet
print "\n";

# FAIL: Unescaped control characters
print $raw_binary_data;
```

### Debugging and Logging
```perl
# CORRECT: Use stderr for debug output
if ($ENV{DEBUG}) {
    print STDERR "[DEBUG] message\n";
}

# FAIL: Debug floods stdout/telnet
warn "message";
print "debug";
```

---

## Testing Requirements

### Before Committing Changes

```bash
# 1. Syntax check all modified Perl files
perl -c photonbbs
find modules -name "*.pm" -exec perl -c {} \;

# 2. Start BBS server (separate terminal/tmux)
./photonbbs

# 3. Test telnet connections and functionality
telnet localhost 2323
# Test: login, main menu, MUD access, commands

# 4. For door games: test via door interface
# For MUD: test movement, combat, spells

# 5. Check for obvious errors
grep -r "TODO\|FIXME\|HACK" modules/ --include="*.pm"
```

### Menu System Testing
- Verify menu files parse correctly
- Test user permissions/security levels
- Confirm door game launching
- Validate MUD access from main menu

### Integration Testing
- Test complete user journey: login -> menu -> doors -> MUD
- Multi-node testing: simultaneous connections
- State persistence: verify data saves/loads
- Telnet protocol compliance: special characters, line endings

---

## Commit Workflow

### Commit Message Format
```bash
type(scope): brief description

Problem: What was broken/incomplete
Solution: How you fixed it
Testing: How you verified the fix (telnet tested, etc.)
```

**Types:** feat, fix, refactor, docs, test, chore

**Example:**
```bash
git add -A
git commit -m "fix(menu-parsing): handle special characters in door descriptions

Problem: Menu entries with pipes (|) were breaking parser
Solution: Escape pipe characters in menu parsing, added validation
Testing: Telnet tested menu display with special characters, verified door launching"
```

### Before Committing: Checklist
- [ ] `perl -c` passes on all changed .pm files
- [ ] Telnet tested: can connect and navigate menus
- [ ] Door games/MUD still accessible from main menu
- [ ] No hardcoded debugging output
- [ ] POD documentation updated if API changed
- [ ] Commit message explains WHAT and WHY
- [ ] No `TODO`/`FIXME` comments (finish the work!)
- [ ] All changes are tested and working

---

## Anti-Patterns: NEVER DO THESE

| Anti-Pattern | Why | What To Do Instead |
|--------------|-----|-------------------|
| Skip syntax check before commit | Causes BBS startup failure | `perl -c` every Perl file |
| Use `\n` for telnet output | Line endings corrupt telnet display | Use `\r\n` for telnet, `\n` for logs |
| Assume code behavior without reading | Causes subtle bugs | Read the code, understand it |
| Label issues as "out of scope" | Harms code quality | Own the problem, fix it |
| Commit without telnet testing | Breaks user experience | Test via telnet before committing |
| Modify security levels without testing | Breaks access control | Test all permission levels |
| Bare `die` statements | Crashes BBS for all users | Use error handlers, notify gracefully |
| Giant subroutines (>50 lines) | Hard to maintain and debug | Split into focused functions |
| Binary data in telnet output | Corrupts connection | Ensure all telnet output is text |
| Ignore menu format specification | Breaks menu parsing | Follow Key\|Desc\|Script\|Level\|Hidden\|Type\|Max |

---

## PhotonBBS-Specific Guidelines

### Menu System
- Menu files are in `data/` with `.mnu` extension
- Format: `Key|Description|Script|SecurityLevel|Hidden|Type|MaxConcurrent`
- Types: `internal`, `external`, `submenu`
- Security levels control visibility and access
- Test menu changes immediately with telnet

### Door Games
- Door implementations in `doors/` directory
- Door execution via `doorexec/` environment
- Verify door compatibility with current system
- Test door game launching and completion

### MUD Integration
- PhotonMUD is core feature, not optional
- Must be accessible from BBS main menu
- Verify MUD commands work: LOOK, MOVE, ATTACK, INVENTORY, SPELLS, STATUS
- Test multi-player MUD scenarios when relevant

### Data Persistence
- Room/realm data in `data/` (`.dat` files)
- Menu configurations in `data/` (`.mnu` files)
- Configuration files in `configs/`
- All data changes must be tested for save/load

### Telnet Protocol Compliance
- All user output must use telnet line endings (`\r\n`)
- ANSI color codes are acceptable
- No binary data in user output
- Handle connection drops gracefully
- Test with actual telnet clients, not just `nc`

---

## Development Tools & Commands

### Common Testing Commands
```bash
# Start BBS server
./photonbbs

# Connect via telnet
telnet localhost 2323

# Test a specific module
perl -c modules/Phoenix.pm

# Search for patterns in code
grep -r "function_name" modules/ --include="*.pm"

# View recent changes
git log --oneline -10
git diff HEAD~1

# Check git status
git status

# Test menu loading
perl -e 'use lib "."; require "modules/Phoenix.pm"'
```

### Docker Testing
```bash
# Build container
docker build -t photonbbs -f docker/Dockerfile .

# Run container
docker run -p 2323:2323 photonbbs

# Test via telnet to container
telnet localhost 2323
```

---

## Known Issues and Gotchas

### Telnet Connection Issues
- Line endings must be `\r\n` (CRLF) for proper display
- Some telnet clients handle ANSI colors differently
- Terminal width varies by client - use conservative limits
- Connection drops can leave orphaned processes

### Menu System
- Menu parsing requires exact format (pipes are delimiters)
- Security levels must match user permission system
- Door concurrent user limits must be enforced
- Hidden menu items still require security check

### MUD Integration
- State must persist between BBS sessions
- Multi-player interactions require atomic updates
- Spell/combat balancing affects gameplay
- Realm generation affects procedural content

### Data Files
- Binary format varies by platform
- Corrupt `.dat` files can crash entire system
- Backup important data files before modifications
- Verify save/load cycle after any data structure change

---

## Session Handoff Procedures (MANDATORY)

### CRITICAL: Session Handoff Directory Structure

When ending a session, **ALWAYS** create a properly structured handoff directory:

```
ai-assisted/YYYYMMDD/HHMM/
├── CONTINUATION_PROMPT.md  [MANDATORY] - Next session's complete context
├── AGENT_PLAN.md           [MANDATORY] - Remaining priorities & blockers
├── CHANGELOG.md            [OPTIONAL]  - User-facing changes (if applicable)
└── NOTES.md                [OPTIONAL]  - Additional technical notes
```

**NEVER COMMIT** `ai-assisted/` directory to git. Always verify before committing:

```bash
git status  # Ensure no ai-assisted/ files staged
git add -A
git status  # Double-check
git commit -m "message"
```

**Handoff should include:**
- Current state of BBS/MUD functionality
- In-progress work and testing status
- Next steps for next session
- Key decisions made about game mechanics or BBS features
- Lessons learned from telnet testing
- Links to relevant Perl modules modified

---

## Session Handoff Notes (Deprecated - See Above)

When working across sessions, always:

1. **Document your context**: What are you working on? What's blocking?
2. **Create test cases**: Leave reproducible tests for any bugs
3. **Note gotchas**: Anything unusual or fragile
4. **Review recent commits**: `git log --oneline -20`
5. **Check branches**: Are there work-in-progress branches?

Use collaboration checkpoints to ensure handoffs are smooth between sessions.

---

## Additional Resources

- **README.md**: Project overview and demo info
- **PHOTONBBS.md**: Comprehensive BBS documentation
- **PHOTONMUD.md**: MUD features and gameplay
- **PHOTONBBS_STYLE_GUIDE.md**: Detailed code style guidelines
- **SECURITY.md**: Security considerations and best practices
- **Makefile**: Build and deployment targets
- **docker/Dockerfile**: Container deployment configuration

---

## Questions? Collaboration First!

When in doubt about implementation details, architecture decisions, or testing approach:

1. Use the collaboration tool to discuss findings
2. Present options with pros/cons
3. Get approval before major changes
4. Document the decision for future sessions

This ensures everyone understands the reasoning and can maintain consistency across the codebase.

# PhotonBBS Architecture

Technical reference for the PhotonBBS platform internals. For user documentation see [PHOTONBBS.md](PHOTONBBS.md), for MUD gameplay see [PHOTONMUD.md](PHOTONMUD.md), for development see [DEVELOPER.md](DEVELOPER.md).

---

## System Overview

PhotonBBS is a multi-process telnet BBS platform with an integrated MUD engine, native door games, and real-time messaging. The system runs inside a Docker container with persistent data on an external volume.

```
Internet (port 23)
    |
    v
photonbbs (Perl daemon)
    |--- accept() -> fork()
    |
    v
photonbbs-tty (C) -----> Telnet protocol negotiation (NAWS, Echo, SGA)
    |                     Creates PTY pair, relays I/O between socket and PTY
    v
photonbbs-client (Perl) ---> Per-user BBS session
    |
    +--- pb-framework       Core I/O, colors, locking, terminal
    +--- pb-main            Menus, teleconference, chat commands
    +--- pb-usertools       Authentication, user profiles
    +--- pb-doorlib         Door game framework (saves, scores, sessions)
    +--- pb-broker-client   Real-time messaging (BBS side)
    +--- pb-security        Bans, rate limiting, input validation
    |
    +--- Door Games (12 native)
    |    pb-door-reddragon, pb-door-startrader, pb-door-casino,
    |    pb-door-druglord, pb-door-seabattle, pb-door-startrek,
    |    pb-door-bigcatch, pb-door-atlantis, pb-door-1000miles,
    |    pb-door-propertywars, pb-door-diceshake, pb-door-mechwars
    |
    +--- PhotonMUD (exec, separate process)
    |    photonmud + pm-* modules (combat, rooms, spells, monsters, etc.)
    |
    +--- External Doors (exec via doorexec/ scripts)
         DOS doors via dosemu, drop file handoff

                          photonbbs-broker (Perl)
                              |
                              +--- Unix socket: /dev/shm/photonbbs/broker.sock
                              +--- Room-based pub/sub messaging
                              +--- Player registry, heartbeats, timeouts

                          photonmud-monsterai (Perl)
                              |
                              +--- Background daemon for monster AI
                              +--- Spawning, movement, combat initiation
                              +--- Boss persistence and confinement
```

## Process Model

### Connection Lifecycle

1. **photonbbs** (daemon) listens on port 23, accepts TCP connections
2. Reserves a node number from the node pool (1 to `totalnodes`)
3. Forks a child process for the session
4. Child drops privileges to `nobody` user
5. Redirects stdin/stdout/stderr to the client socket
6. Execs `photonbbs-tty` with args: `-L photonbbs-client TELNET <ip> <node>`

### photonbbs-tty (C binary)

The TTY wrapper handles telnet protocol before the Perl client starts:

- Negotiates telnet options (WILL ECHO, WILL SGA, DO NAWS)
- Processes IAC sequences, strips telnet commands from data stream
- Creates a PTY pair (openpty)
- Forks: child runs photonbbs-client on the slave PTY, parent relays I/O
- Handles NAWS (window size) updates via ioctl TIOCSWINSZ on the PTY
- Passes protocol, IP, and node ID as command-line arguments to the client

### photonbbs-client (Perl session)

Each user session is an independent Perl process:

```
Startup sequence:
  1. Load pb-defaults (config hash)
  2. Read /etc/default/photonbbs overrides
  3. Load pb-framework (core I/O, colors, terminal)
  4. Load pb-broker-client (messaging)
  5. Load pb-main (menus, teleconference)
  6. Load pb-doorlib, pb-doors (game framework)
  7. Load pb-security, pb-usertools, pb-oneliners, pb-lastcallers, etc.
  8. Load all pb-door-* game modules
  9. Display welcome screen, authenticate user
  10. Connect to broker (bbs-global room)
  11. Show last callers, bulletins, oneliners, who's online
  12. Enter teleconference or main menu (configurable)
```

Signal handlers restore terminal state (cbreak off) on SIGTERM/SIGHUP/SIGQUIT/SIGKILL.

### Node Management

The daemon tracks node assignments in memory (`%node_in_use`, `%pid_to_node`). Node files in the transient directory (`/dev/shm/photonbbs/data/nodes/`) contain pipe-delimited session info:

```
handle|location|pid|ip|protocol|ext|node
```

When a child exits, the daemon reaps it, frees the node number, and cleans up the node file. Periodic maintenance also sweeps for orphaned node files.

### Privilege Model

The daemon runs as root to bind port 23. Before execing the TTY wrapper, each forked child:
- Drops to `nobody:nobody` (configurable via `unixuser`)
- Redirects file descriptors to the client socket
- Sets HOME to `/opt/photonbbs`

The BBS, MUD, and all door games run as `nobody`. The broker and monsterai services also run as `nobody` via `su -s /bin/sh nobody -c`.

---

## Module Architecture

### Loading Model

All modules use `require` (not `use`) and run in the `main::` namespace. No `package` declarations, no `use strict/warnings` in modules (inherited from the loading script). Every module ends with `1;`.

```perl
# Modules are found via require_module() which searches:
#   1. /opt/photonbbs/modules/$mod  (system install)
#   2. ./modules/$mod               (local/development)
sub require_module {
    my ($mod) = @_;
    my $sys_path = "/opt/photonbbs/modules/$mod";
    my $local_path = "./modules/$mod";
    require (-e $sys_path ? $sys_path : $local_path);
}
```

Because everything shares `main::`, all subroutines, globals (`%config`, `%info`, `%theme`), and color variables (`$RST`, `$CLR`, etc.) are directly accessible across modules.

### Module Prefixes

| Prefix | Purpose | Loaded by |
|--------|---------|-----------|
| `pb-` | BBS core | photonbbs-client |
| `pm-` | MUD engine | photonmud |
| `mw-` | MechWars engine | pb-door-mechwars |
| `pb-door-` | Native door games | photonbbs-client |

### Key BBS Modules

| Module | Purpose |
|--------|---------|
| **pb-defaults** | Default `%config` hash values |
| **pb-framework** | Core I/O (`writeline`, `getline`, `waitkey`), terminal control (`cbreak`), file locking, color/theme/template substitution, atomic writes, UUID generation, session broker integration |
| **pb-main** | Menu system (`show_menu`), teleconference (`teleconf`), chat commands, channel management, whisper/page, who's online |
| **pb-broker-client** | BBS-side broker client: connect, join/leave room, send/poll messages, heartbeat |
| **pb-doorlib** | Door game framework: save/load, scores, credits, turns, sessions, multiplayer sync, card/dice/slot rendering |
| **pb-doors** | External door game integration (drop files, dosemu) |
| **pb-security** | Input validation, IP bans, rate limiting, failed login tracking |
| **pb-security-admin** | SysOp security dashboard |
| **pb-usertools** | `authenticate()`, `newuser()`, user profiles |
| **pb-oneliners** | Wall/oneliner system |
| **pb-lastcallers** | Recent caller display |
| **pb-render** | Markdown rendering for .md text files |
| **pb-activity** | Activity tracking |
| **pb-polls** | User polls |

### Key MUD Modules

| Module | Purpose |
|--------|---------|
| **pm-defaults** | MUD configuration defaults |
| **pm-combat** | D&D-style combat system |
| **pm-rooms** | Room/world management, navigation, exits |
| **pm-objects** | Items, equipment, inventory |
| **pm-monsters** | Monster definitions, stats, behavior |
| **pm-player** | Character management, stats, leveling |
| **pm-spells** | Magic system (20+ spells) |
| **pm-containers** | Container objects |
| **pm-market** | Trading/economy |
| **pm-npcs** | Non-player characters |
| **pm-cache** | Data caching layer |
| **pm-utils** | MUD utilities |
| **pm-messaging** | In-game messaging |
| **pm-broker-client** | MUD-side broker client (combat, room messages) |

### MechWars Modules

MechWars is a space combat/trading door game with its own module set, loaded by `pb-door-mechwars`:

| Module | Purpose |
|--------|---------|
| **mw-universe** | Galaxy map, sector management |
| **mw-player** | Ship stats, cargo, equipment |
| **mw-movement** | Navigation, warp, sector transitions |
| **mw-ui** | Display rendering, HUD, status screens |
| **mw-combat** | Ship-to-ship combat |
| **mw-economy** | Trading, ports, commodities |
| **mw-bases** | Player-owned bases |
| **mw-drones** | Automated drones |
| **mw-entities** | NPCs and AI ships |
| **mw-teams** | Alliances and team management |
| **mw-fortresses** | Defensive structures |
| **mw-planets** | Planetary systems |

---

## Message Broker

### Overview

The broker (`services.d/photonbbs-broker`) is a centralized pub/sub messaging server that enables real-time communication across all BBS processes. It runs as a standalone Perl daemon communicating via a Unix domain socket.

### Architecture

```
                    photonbbs-broker
                    (Unix socket server)
                          |
            /dev/shm/photonbbs/broker.sock
                          |
    +----------+----------+----------+----------+
    |          |          |          |          |
  Client1   Client2   Client3   MonsterAI   Door
  (session) (session) (teleconf) (combat)   (game)
```

Each BBS session, teleconference channel, and door game maintains its own socket connection to the broker. The broker tracks:

- **Client registry**: fd -> {type, id, player, room, last_activity, buffer}
- **Player registry**: player_name -> fd (for direct messages)
- **Room registry**: room_id -> {players: [names]} (for pub/sub)

### Room Model

Rooms are named channels that clients join/leave. Message types:

| Room Pattern | Purpose | Used by |
|-------------|---------|---------|
| `bbs-global` | System-wide broadcasts, pages | pb-framework |
| `tc-<channel>` | Teleconference channel chat | pb-main |
| `door-<game>` | Door game communication | pb-doorlib |
| `user-<handle>` | Direct messages to specific user | pb-main (whisper) |
| Various MUD rooms | Combat, room events | pm-broker-client |

### Client Types

Each BBS session maintains up to three broker connections:

1. **Session socket** (`$_BBS_BROKER_SOCK` in pb-framework): Joins `bbs-global`, receives pages and broadcasts
2. **Teleconf socket** (`$_TC_BROKER_SOCK` in pb-main): Joins `tc-<channel>`, receives channel chat messages
3. **Door socket** (`$_DOOR_BROKER_SOCK` in pb-doorlib): Joins `door-<game>`, used for multiplayer game sync

### Protocol

JSON messages over Unix socket. Each message is a JSON object followed by a newline:

```json
{"type": "register", "id": "user-handle", "player": "handle"}
{"type": "join_room", "room": "tc-main"}
{"type": "room_message", "room": "tc-main", "message": "Hello!"}
{"type": "direct_message", "target": "user-bob", "message": "Hi Bob"}
{"type": "heartbeat"}
{"type": "get_room_players", "room": "tc-main"}
{"type": "get_online_players"}
```

### Keepalive

The broker expires idle clients after `CLIENT_TIMEOUT` (120s). Clients send heartbeats every 30s. Door games call `_door_broker_keepalive()` which sends heartbeats on the BBS session and teleconf sockets to prevent them from expiring while the user is in a game.

### Broker Clients

Two separate broker client modules exist for the two main subsystems:

- **pb-broker-client**: Used by BBS sessions. Provides `broker_connect`, `broker_join_room`, `broker_send_room_message`, `broker_poll`, `broker_heartbeat`, etc.
- **pm-broker-client**: Used by MUD engine. Adds `broker_monster_attack`, `broker_combat_response`, `broker_combat_update`, `broker_combat_end` for real-time monster combat via the broker.

---

## Data Persistence

### Storage Model

All persistent data uses Perl's `Storable` module (`lock_store`/`lock_retrieve`) for binary serialization with file locking:

```perl
use Storable qw(store retrieve lock_store lock_retrieve);

# Write
lock_store(\%data, "$config{'home'}/$config{'data'}/file.dat");

# Read
my $data = lock_retrieve("path/to/file.dat");
```

### Data Locations

| Path | Type | Contents |
|------|------|----------|
| `/opt/photonbbs/data/users/` | Persistent | User profiles (.dat files per user) |
| `/opt/photonbbs/data/doors/<game>/` | Persistent | Door game saves, scores, sessions |
| `/opt/photonbbs/data/text/` | Persistent | ANSI art, welcome screens, custom headers |
| `/opt/photonbbs/data/themes/` | Persistent | Theme files (key=value format) |
| `/opt/photonbbs/data/photonmud/` | Persistent | MUD world data (rooms.dat, etc.) |
| `/dev/shm/photonbbs/` | Transient | Broker socket, node files, page files |
| `/dev/shm/photonbbs/data/nodes/` | Transient | Active session node files |
| `/dev/shm/photonbbs/doors/nodes/` | Transient | Door game drop files (DORINFOx.DEF) |
| `/dev/shm/photonmud/` | Transient | MUD room player tracking |

### Docker Volume Model

In Docker deployment, persistent data lives on an external volume:

```
Docker volume "appdata" mounted at /appdata
    |
    +--- startscript creates symlink: /opt/photonbbs/data -> /appdata
    |
    +--- First run: copies /opt/photonbbs/data/* to /appdata, touches .migrated
    +--- Subsequent runs: skips migration, just creates symlink
```

This means:
- Code changes via Docker rebuild update `/opt/photonbbs/` (modules, sbin, etc.)
- Data changes (themes, text files, user data) persist across rebuilds in `/appdata`
- To update theme/text files after rebuild: `docker cp <file> container:/appdata/...`

### Atomic Writes

Framework provides `atomic_write_file()` for safe data persistence:
1. Write to temporary file (same directory)
2. Rename tmp file to target (atomic on same filesystem)

This prevents corruption from interrupted writes or concurrent access.

---

## Door Game System

### Menu-Driven Launch

Door games are launched from the menu system via `run_menu_command()` in pb-main:

1. User selects a menu item (e.g., "B" for Red Dragon)
2. Menu file specifies type (`internal` or `external`) and script name
3. For **internal** doors: calls the subroutine directly (e.g., `reddragon_main()`)
4. For **external** doors: forks/execs the script from `sbin/` or `doorexec/`
5. Sets `iamat()` status, enables DND mode, disables event processing
6. Concurrency control via lock files (optional per-door limit)
7. On return: restores iamat, re-enables events, calls `doevents()`

### Internal vs External Doors

| Type | How it runs | Communication | Examples |
|------|------------|---------------|---------|
| **Internal** | Subroutine call in same process | Direct access to `%config`, `%info`, all framework functions | All pb-door-* games |
| **External** | `system()` fork/exec | Drop files (DORINFOx.DEF, fusiondoor), exit codes | photonmud, dosemu doors, useredit |

### Door Game Framework (pb-doorlib)

The doorlib provides shared infrastructure for all native door games:

**Data Management:**
- `door_save(game, data)` / `door_load(game)` - Per-user game saves (Storable)
- `door_submit_score(game, score, label)` - High score submission
- `door_get_scores(game, count)` / `door_show_scores(game)` - Score retrieval and display
- `door_get_credits(game)` / `door_add_credits(game, n)` / `door_sub_credits(game, n)` - In-game currency
- `door_check_turns(game, max)` / `door_use_turn(game)` - Daily turn limits

**UI Helpers:**
- `door_clear()` / `door_pause()` / `door_yesno()` / `door_noyes()` - Screen control
- `door_getnum(prompt, min, max)` - Numeric input with validation
- `door_menu(title, options)` - Quick menu display
- `door_money(n)` - Format number as currency
- `door_hrule()` - Horizontal rule
- `door_draw_cards(cards)` / `door_draw_dice(dice)` / `door_draw_slots(reels)` - Visual rendering

**Multiplayer Sessions:**
- `door_session_create(game, opts)` - Create a multiplayer session, wait for joiners
- `door_session_list(game)` - List open sessions
- `door_session_join(game, session_id)` - Join an existing session
- `door_session_poll(game, session_id)` - Check session state
- `door_session_update(game, session_id, data)` - Update shared state
- `door_session_wait(game, session_id, opts)` - Wait for players with countdown
- `door_session_destroy(game, session_id)` - Clean up session

**Real-Time Sync (via broker):**
- `door_broker_connect(game, room)` - Connect to broker for real-time messaging
- `door_game_room_join(room)` - Join a game-specific broker room
- `door_game_state_send(state)` - Broadcast game state to room
- `door_game_state_recv()` - Poll for incoming game state
- `door_game_wait_turn(game, opts)` - Wait for turn notification

### Native Door Games

| Game | Type | Multiplayer | Description |
|------|------|------------|-------------|
| Red Dragon | RPG | Async (shared world), Live duels | Fantasy RPG with forest, town, dragon |
| Star Trader | Trading | Async (shared economy) | Space commodity trading |
| Casino | Card/Dice | Solo | Blackjack, poker, craps, slots |
| Drug Lord | Trading | Async (price competition) | Street-level commodity trading |
| Sea Battle | Strategy | Live PvP (broker sync) | Naval grid combat |
| Star Trek | Exploration | Solo | Sector-based space exploration |
| Big Catch | Simulation | Async (tournaments) | Fishing with weather and seasons |
| Atlantis | Adventure | Solo | Underwater exploration and combat |
| 1000 Miles | Card | Live multiplayer (broker sync) | Racing card game, 2-4 players |
| Property Wars | Board | Live multiplayer (broker sync) | Property trading board game |
| Dice Shake | Dice | Live multiplayer (file sync) | Yahtzee-style dice scoring |
| MechWars | Strategy | MMO-style (persistent universe) | Space combat, trading, bases |

---

## MUD Engine

### Process Architecture

PhotonMUD runs as a separate process, launched from the BBS as an external door:

```
photonbbs-client
    |
    +-- run_menu_command("external", "photonmud")
    |       |
    |       +-- system("sbin/photonmud", home, node, handle)
    |
    v
photonmud (separate Perl process)
    |
    +-- Loads pm-defaults, pm-cache, pm-monsters, pm-rooms, pm-combat,
    |   pm-spells, pm-containers, pm-market, pm-npcs, pm-player,
    |   pm-objects, pm-utils, pm-messaging, pm-broker-client
    |
    +-- Reads DORINFOx.DEF + fusiondoor for session info
    +-- Connects to broker for real-time events
    +-- Enters main game loop
```

### World Generation

`photonmud-generator` procedurally generates the game world:
- Creates rooms with descriptions, exits, features
- Places towns, dungeons, wilderness areas
- Generates room connectivity (bidirectional exits)
- Output: `data/photonmud/rooms.dat` (Storable)

Generation runs once (via `services.d/photonmud-data`) if rooms.dat doesn't exist.

### Monster AI Daemon

`photonmud-monsterai` runs as a background service:

- **Boss placement**: Unique bosses in special rooms (vaults, towers, keeps)
- **Regular spawning**: Monsters distributed by room type (cave monsters in caves, etc.)
- **Movement**: Monsters roam within their assigned region/room type
- **Combat initiation**: Detects players in rooms, initiates combat via broker
- **Population balance**: Scaled to map size, max 3 monsters per room
- **Persistence**: Boss locations saved across restarts

Uses threads for parallel region management and combat processing.

### MUD Communication

The MUD uses the same broker infrastructure as the BBS but with additional message types:

- `monster_attack`: MonsterAI notifies a player's MUD session of combat
- `combat_response`: Player responds to combat actions
- `combat_update`: State changes during combat (damage, effects)
- `combat_end`: Combat resolution

---

## Color, Theme, and Template System

### Substitution Architecture

Four centralized functions in pb-framework handle all `@TOKEN` substitution. Each uses a hash lookup table and a single compiled regex for performance:

```perl
# 1. Color codes: @RST, @BLK, @RED, @GRN, @YEL, @BLU, @MAG, @CYN, @WHT
#    Plus bright variants: @BRD, @BGN, @BYL, @BBL, @BMA, @BCY, @BWH
_substitute_color_codes($text)

# 2. Theme colors: @SYSTEMCLR, @USERCLR, @INPUTCLR, @THEMECLR,
#    @PROMPTCLR, @ERRORCLR, @DATACLR, @LINECLR
_substitute_theme_codes($text)

# 3. Box drawing: @BOXHORIZ@, @BOXVERT@, @BOXTL@, @BOXTR@,
#    @BOXBL@, @BOXBR@, etc. (16 characters)
_substitute_box_codes($text)

# 4. Template variables: @USER, @SYSNM, @TIME, @DATE, @NODE, etc.
#    Plus escape sequences: \n, \r, \t, \e
_substitute_template_vars($text)
```

These are called by `applytheme()`, `readfile()`, `colorline()`, and `writeline()`. Inline `s///` chains are never used - all substitution goes through these functions.

### Theme Files

Theme files are key=value text files in `data/themes/<name>`:

```
login=\n@THEMECLRIf you already have a @DATACLRUser-ID@THEMECLR...
menuprompt=@THEMECLRMake your selection (@KEYS, ? for help, or ! to exit): 
mainmenuhdr=@THEMECLR\nMain Menu
cmd_teleconf=Teleconference
cmd_exit=Log Off and Exit
```

Theme keys control all user-facing text: login prompts, menu headers, error messages, oneliners display, last callers display, help screens, and command labels.

### Text File Priority

When displaying headers/footers (e.g., oneliners), the system checks:
1. `data/text/filename.<ext>` (e.g., `oneltop.ans` for ANSI terminals)
2. `data/text/filename.txt` (plain text fallback)
3. `$theme{'keyname'}` (theme string fallback)

This allows per-BBS customization without modifying theme files.

---

## Docker Deployment

### Container Build

```dockerfile
FROM rockylinux:9
# Install: perl, gcc, make, dosemu, openssh-server, socat, EPEL
COPY . /opt/photonbbs
RUN cd /opt/photonbbs && make    # Compiles photonbbs-tty from C source
COPY startscript /
EXPOSE 23
ENTRYPOINT ["/startscript"]
```

### Startup Sequence (startscript)

1. **Data migration**: If `/appdata/.migrated` doesn't exist, move `data/*` to `/appdata`
2. **Symlink creation**: `/opt/photonbbs/data -> /appdata`
3. **Directory setup**: Ensure photonmud data, doorexec, doors directories exist
4. **Transient directories**: Create `/dev/shm/photonbbs/`, `/dev/shm/photonmud/`
5. **Node symlinks**: Link node info into doors directory for drop file access
6. **DOSEMU setup**: Create drive mappings for DOS door games
7. **Config persistence**: Move `/etc/default/photonbbs` to `/appdata/default/`
8. **Permissions**: `chown -R nobody:nobody /appdata /opt/photonbbs/data`
9. **Optional SSH**: If `PHOTONBBS_SSH_ENABLE=1`, start sshd with BBS forced command
10. **Launch daemon**: Exec `photonbbs`

### Service Startup (services.d)

The daemon launches all executables in `services.d/` as detached threads running as `nobody`:

| Service | Purpose |
|---------|---------|
| `photonbbs-broker` | Message broker daemon |
| `photonmud-data` | World generation (runs once if rooms.dat missing) |
| `photonmud-monsterai` | Monster AI daemon |

### Scheduled Tasks

**Hourly (`hourly.d/`):**
- `broker-check`: Verifies broker socket exists, restarts if missing

**Daily (`daily.d/`):**
- `reset-lastcallers`: Clears the last callers list
- `bigcatch`: Resets daily fishing turns, rotates tournaments
- `casino`: Resets daily play limits
- `startrader`: Processes market price fluctuations
- `mechwars`: Universe maintenance, drone processing

### Docker Compose

```yaml
services:
  photonbbs:
    build: ..
    image: fewtarius/photonbbs
    network_mode: bridge
    ports: ["23:23/tcp"]
    privileged: true
    volumes: ["appdata:/appdata:rw"]
volumes:
  appdata:
```

The `appdata` volume persists all user data, themes, text files, game saves, and MUD world data across container rebuilds.

---

## Security Model

### Input Validation (pb-security)

- `validate_filename(name)`: Only allows `[a-zA-Z0-9_.-]`
- `validate_path(path)`: Blocks path traversal (`..`, leading `/`)
- `validate_username(name)`: Alphanumeric + spaces, length limits
- `validate_command_arg(arg)`: Safe characters only for menu command arguments
- `safe_open_read/write/append(path)`: Validated file operations
- `sanitize_for_shell(input)`: Escapes shell metacharacters

### Authentication

- Password hashing (in pb-usertools)
- Configurable retry limit (`authretries`, default 3)
- Failed login tracking with timestamps
- Automatic IP banning after threshold
- IP whitelist support

### IP Ban System

- `record_failed_login(ip)`: Tracks failed attempts with timestamps
- `count_recent_failures(ip)`: Counts failures within time window
- `auto_ban_ip(ip, reason, duration)`: Automatic bans after threshold
- `manual_ban_ip(ip, reason, duration)`: SysOp-initiated bans
- `check_ip_banned(ip)`: Returns (banned, reason, expiry)
- Configurable ban durations, permanent bans supported

### Process Isolation

- Each session runs as `nobody` in its own process
- Node files in shared memory prevent cross-session interference
- File locking (`flock`) prevents data corruption from concurrent access
- Door game concurrency limits prevent resource exhaustion
- Broker message routing ensures messages reach intended recipients only

### External Door Security

For external doors launched via `run_menu_command()`:
- Command arguments validated against `[a-zA-Z0-9_.-]` whitelist
- `system()` uses list form (no shell interpretation)
- Only executables in `sbin/` and `doorexec/` directories are launchable
- DND mode enabled during door execution (suppresses events)

---

## I/O System

### Terminal Control

pb-framework provides terminal management:

- **cbreak(on/off)**: Character-at-a-time mode via POSIX::Termios (with `stty` fallback)
- **Terminal size**: Detected via `ioctl(TIOCGWINSZ)` with environment variable fallback
- **END block**: Restores terminal state on any exit path

### Output Functions

| Function | Purpose |
|----------|---------|
| `writeline(text, newline)` | Primary output - applies color/theme/template substitution |
| `colorline(text)` | Apply color substitution only (no template vars) |
| `readfile(path)` | Display a text file with full substitution (.md files get markdown rendering) |

### Input Functions

| Function | Purpose |
|----------|---------|
| `waitkey()` | Read single character (no echo, no Enter required) |
| `getline(type, maxlen, default, echo)` | Read line with optional echo, type validation |
| `pause()` | Wait for keypress with "(Q)uit (C)ontinue" prompt |

### Rendering

- **Markdown**: `pb-render` provides `render_markdown()` for .md files, fired automatically by `readfile()`
- **Cards**: `door_draw_cards()` renders playing cards with ASCII art
- **Dice**: `door_draw_dice()` renders dice faces
- **Slots**: `door_draw_slots()` renders slot machine reels
- **Box characters**: `boxchar()` provides terminal-safe box drawing (no Unicode)

---

## File Structure Reference

```
photonbbs/
+-- photonbbs              # Main daemon (Perl)
+-- startscript            # Docker container init (bash)
+-- Dockerfile             # Container build
+-- Makefile               # Build targets (make all, docker-*)
+-- sbin/
|   +-- photonbbs-client   # Per-user session (Perl)
|   +-- photonbbs-tty      # Telnet wrapper (compiled C binary)
|   +-- photonmud          # MUD engine (Perl)
|   +-- photonmud-monsterai # Monster AI daemon (Perl)
|   +-- photonmud-generator # World generator (Perl)
|   +-- photonbbs-dooredit  # Door game data editor (Perl)
|   +-- useredit           # User account editor (Perl)
|   +-- bulledit           # Bulletin editor (Perl)
+-- src/
|   +-- photonbbs-tty.c    # TTY wrapper source
+-- modules/
|   +-- pb-defaults        # BBS config defaults
|   +-- pb-framework       # Core I/O, terminal, colors
|   +-- pb-main            # Menus, teleconference
|   +-- pb-broker-client   # BBS broker client
|   +-- pb-doorlib         # Door game framework
|   +-- pb-doors           # External door integration
|   +-- pb-security        # Auth, bans, validation
|   +-- pb-security-admin  # SysOp security tools
|   +-- pb-usertools       # User management
|   +-- pb-oneliners       # Wall system
|   +-- pb-lastcallers     # Caller tracking
|   +-- pb-render          # Markdown rendering
|   +-- pb-activity        # Activity tracking
|   +-- pb-polls           # User polls
|   +-- pb-logger          # Logging
|   +-- pb-door-*          # 12 native door games
|   +-- pm-*              # 14 MUD modules
|   +-- mw-*              # 12 MechWars modules
+-- services.d/
|   +-- photonbbs-broker   # Message broker service
|   +-- photonmud-data     # World generation (run-once)
|   +-- photonmud-monsterai # Monster AI service
+-- daily.d/               # Daily maintenance scripts
+-- hourly.d/              # Hourly maintenance scripts
+-- data/
|   +-- main.mnu           # Main menu definition
|   +-- games.mnu          # Games submenu definition
|   +-- text/              # ANSI art, welcome screens
|   +-- themes/            # Theme files
|   +-- photonmud/         # MUD world data
+-- configs/
|   +-- etc/default/photonbbs  # Config overrides
+-- docker/
|   +-- docker-compose.yml # Docker Compose definition
+-- doorexec/              # External door launch scripts
+-- doors/                 # Door game configurations
+-- scripts/               # Utility/deploy scripts
```

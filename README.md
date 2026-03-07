# PhotonBBS

A complete telnet BBS and MUD platform for Unix/Linux

Copyright (C) 2002-present, Fewtarius

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

The latest version of this software can be downloaded from:
https://github.com/fewtarius/photonbbs

## Terminal Tavern BBS

Join us at **Terminal Tavern** where you can chat, play games, and test out PhotonBBS and PhotonMUD!

```
telnet bbs.terminaltavern.com
```

Experience the full BBS, chat system, door games, and integrated MUD gameplay!

![PhotonBBS Screenshot](https://imgur.com/8gGLgnC.png)

## About

PhotonBBS is a comprehensive telnet-based bulletin board system (BBS) and multi-user dungeon (MUD) platform written in Perl. Originally created as a simple multi-node chat server, it has evolved into a full-featured platform combining classic BBS functionality with a modern, procedurally-generated MUD adventure.

### What Makes PhotonBBS Unique

**Integrated BBS and MUD**: PhotonBBS seamlessly combines traditional BBS features (chat, bulletins, door games) with PhotonMUD, a fully-featured multi-user dungeon with procedurally-generated worlds, dynamic combat, and persistent gameplay.

**Modular Architecture**: Built with extensibility in mind, PhotonBBS uses a modular Perl-based architecture that makes it easy to add new features, customize behavior, and integrate door games.

**13 Built-in Door Games**: Native Perl door games including MechWars, Red Dragon, Star Trader, Casino, Drug Lord, Sea Battle, Star Trek, Big Catch, Atlantis, 1000 Miles, Property Wars, Dice Shake, plus PhotonMUD - all with save/load, high scores, multiplayer support, and credits system.

**Modern Deployment**: Containerized deployment via Docker ensures easy installation and portability across Linux, macOS, and Windows.

## Core Components

### PhotonBBS - The BBS Platform

- Multi-user chat and teleconference system
- User account management and authentication
- System bulletins and oneliners
- Customizable menu system
- Theme support with ANSI colors
- 13 native door games with save/load, high scores, and multiplayer
- External BBS door game support (DOOR.SYS, DORINFO)
- Real-time multiplayer via broker system
- Door game operator tools (data editor, score management)
- Administrative tools and utilities

### PhotonMUD - The Multi-User Dungeon

- Procedurally-generated persistent worlds
- D&D-style combat system with dice mechanics
- Character classes, races, and progression
- Magic system with spells and abilities
- Monster AI with intelligent behavior
- Dynamic economy and trading
- Multiplayer exploration and interaction
- Unique world generation every campaign

### Native Door Games

PhotonBBS ships with 13 native Perl door games:

- **MechWars: Infinite Frontiers** - Space combat and trading (persistent universe, guilds, fortresses, economy)
- **Red Dragon** - Fantasy RPG (forest, combat, town, dragon boss, live PvP duels)
- **Star Trader** - Space trading (sectors, commodities, ship upgrades)
- **Casino** - Card and dice games (blackjack, poker, craps, slots, roulette)
- **Drug Lord** - Street empire (30-day campaign, buy/sell, police)
- **Sea Battle** - Naval combat (Battleship-style grid targeting, live PvP)
- **Star Trek** - Space exploration (galaxy navigation, Klingon combat)
- **Big Catch** - Fishing simulation (5 lakes, tackle shop, tournaments)
- **Atlantis** - Underwater adventure (diving, creatures, artifacts)
- **1000 Miles** - Racing card game (2-4 players, real-time multiplayer)
- **Property Wars** - Property trading board game (2-4 players, multiplayer)
- **Dice Shake** - Dice scoring game (Yahtzee-style, 2-4 players)
- **PhotonMUD** - Full multi-user dungeon (see PHOTONMUD.md)

Several games were inspired by door games from the [Synchronet BBS](https://synchro.net) (SBBS) project. All implementations are original Perl code. See individual game headers for specific credits.

### External Door Game Support

PhotonBBS also supports classic external BBS doors via drop files:
- DOOR.SYS
- DORINFO1.DEF
- DORINFOx.DEF

## Quick Start

### Using Pre-Built Container (Fastest)

```bash
# Pull and run the latest image
docker run -d --name photonbbs \
  -p 23:23 \
  --privileged \
  -v photonbbs-data:/appdata \
  ghcr.io/fewtarius/photonbbs:latest

# Connect via telnet
telnet localhost 23
```

Multi-architecture images (linux/amd64 and linux/arm64) are published automatically to [GitHub Container Registry](https://github.com/fewtarius/photonbbs/pkgs/container/photonbbs).

### Building from Source

```bash
# Clone the repository
git clone https://github.com/fewtarius/photonbbs.git
cd photonbbs

# Start PhotonBBS
make docker-up

# Connect via telnet
telnet localhost 23
```

That's it! PhotonBBS will build and start automatically.

### SSH Access (Optional)

PhotonBBS supports SSH access with public key authentication. Users manage their SSH keys from the BBS itself.

**Enable SSH:**

1. Set `PHOTONBBS_SSH_ENABLE=1` in your docker-compose environment
2. Expose port 22 inside the container (mapped to 2222 by default to avoid conflicts)
3. Restart the container

**User setup (from the BBS):**
```
/set sshkey           - Paste your public key to enable SSH login
/set sshkey remove    - Remove your SSH key
```

**Connect via SSH:**
```bash
ssh -p 2222 bbs@your-bbs-host
```

SSH users are automatically authenticated by their key - no password prompt. The connection is forced directly into the BBS client with no shell access.

### System Requirements

**For Docker deployment:**
- Docker Engine 20.10 or higher
- 512MB RAM minimum, 1GB+ recommended
- TCP port 23 available (or configure alternate port)

**Platform support:**
- Linux (any modern distribution)
- macOS with Docker Desktop
- Windows with Docker Desktop + WSL2

## Documentation

**For Users:**
- [PHOTONBBS.md](PHOTONBBS.md) - BBS commands and features
- [PHOTONMUD.md](PHOTONMUD.md) - MUD gameplay guide

**For Administrators and Developers:**
- [PHOTONBBS.md](PHOTONBBS.md) - Installation and configuration
- [DEVELOPER.md](DEVELOPER.md) - Extending and customizing

## Key Features

### BBS Platform Features

- Multi-node support with concurrent users
- Channel-based chat system
- Private messaging and broadcasts
- System bulletins and oneliners
- User profiles and preferences
- Security levels and permissions
- Customizable themes and colors
- ANSI terminal support
- IP-based access control

### MUD Gameplay Features

- Procedurally-generated unique worlds
- Multiple character classes and races
- D&D-style combat with dice rolls
- Magic system with 20+ spells
- Dynamic monster AI
- Equipment and inventory management
- Player vs Environment (PvE)
- Player vs Player (PvP) combat
- Persistent character progression
- Multiplayer exploration and cooperation

### Door Game Integration

- Support for classic DOS and Unix door games
- Multiple drop file format support
- Concurrent door execution limits
- Security level restrictions
- Easy door configuration

### Administration Features

- User account editor
- Bulletin editor
- Security management
- Session monitoring
- Scheduled task execution
- Maintenance automation
- Customizable menus
- Theme management

## Architecture

PhotonBBS is a multi-process system with several key components:

### Executables

| Component | Language | Purpose |
|-----------|----------|---------|
| **photonbbs** | Perl | Main daemon - binds port 23, manages nodes, forks per connection |
| **photonbbs-tty** | C | Telnet protocol negotiation wrapper (NAWS, echo, SGA) |
| **photonbbs-client** | Perl | Per-user session - menus, chat, door games, user management |
| **photonmud** | Perl | MUD game engine - world, combat, spells, NPCs, economy |
| **photonmud-monsterai** | Perl | Background daemon - monster spawning, AI behavior, boss management |
| **photonmud-generator** | Perl | World generator - procedural rooms, dungeons, terrain |
| **photonbbs-dooredit** | Perl | Operator tool - browse/edit door game player data and scores |
| **useredit** | Perl | Operator tool - user account administration |
| **bulledit** | Perl | Operator tool - bulletin management |

### Module Prefixes

| Prefix | Count | Purpose |
|--------|-------|---------|
| **pb-*** | 10+ | BBS core - framework, menus, chat, doors, security, user tools |
| **pm-*** | 12+ | MUD engine - combat, rooms, monsters, spells, objects, NPCs |
| **mw-*** | 12 | MechWars engine - universe, combat, economy, guilds, fortresses |
| **pb-door-*** | 12 | Native door games - each is a standalone game module |

### Key Technologies

- **Perl 5** for all BBS, MUD, and game logic (no strict/package declarations)
- **C** for the telnet protocol wrapper (photonbbs-tty)
- **Storable** for all data persistence (player saves, game state, scores)
- **Message broker** for real-time IPC (chat, multiplayer, door game sync)
- **Docker** for containerized deployment with s6 process supervision
- **flock()** for concurrent file access safety

For detailed architecture documentation including data flows, IPC mechanisms, and module interactions, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Development

### Building from Source

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

# Access shell
make docker-shell
```

### Using Pre-Built Images

Pre-built multi-architecture images are available from GitHub Container Registry:

```bash
# Pull the latest image
docker pull ghcr.io/fewtarius/photonbbs:latest

# Or pull a specific version
docker pull ghcr.io/fewtarius/photonbbs:20260307.1
```

See [GitHub Container Registry](https://github.com/fewtarius/photonbbs/pkgs/container/photonbbs) for all available tags.

### Makefile Targets

**Docker operations:**
- `make docker-build` - Build Docker image
- `make docker-up` - Start container
- `make docker-down` - Stop container
- `make docker-restart` - Restart container
- `make docker-logs` - View logs
- `make docker-shell` - Open shell in container
- `make docker-rebuild` - Full rebuild
- `make docker-clean` - Remove all containers and images

Run `make help` for complete documentation.

### Module Development

PhotonBBS uses a modular architecture with core modules in the modules directory.

**BBS Modules (pb-):** Framework, main functionality, doors, user tools, security

**MUD Modules (pm-):** Combat, rooms, monsters, spells, player management, objects

**MechWars Modules (mw-):** Universe, combat, economy, bases, drones, planets, fortresses, guilds, movement, UI

## Configuration

### Core Configuration

Main configuration is in `modules/pb-defaults`:
- BBS home directory and paths
- Port number
- Maximum nodes
- Maintenance settings
- Default theme
- System preferences

### Menu Configuration

Menus are defined in text files in `data/`:
- main.mnu - Main menu
- external.mnu - External commands and doors

### Menu Configuration

Menus are defined in text files in the data directory.

### MUD Configuration

PhotonMUD settings control world generation, combat balance, and monster spawning.
- photon - Default theme
- mbbs - Alternative theme
- terminal_tavern - Terminal Tavern BBS theme

Themes define system colors using @CODE variables for consistent appearance.

## Security

PhotonBBS implements several security features:

**Privilege Separation:**
- Daemon starts as root to bind port 23
- Client connections drop to configured BBS user
- Scheduled tasks run as "nobody" user

**Access Controls:**
- IP-based banning and whitelisting
- User security levels
- Permission-based feature access
- Optional duplicate IP prevention

**Data Protection:**
- Restricted file permissions
- Secure password storage
- Session isolation

## Community and Support

- **GitHub**: https://github.com/fewtarius/photonbbs
- **Issues**: Report bugs and feature requests via GitHub Issues
- **Terminal Tavern BBS**: telnet bbs.terminaltavern.com

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on a live system
5. Submit a pull request

## License

PhotonBBS is released under the GNU General Public License v2.

See LICENSE file for complete license text.

## Credits

**Original Author**: Fewtarius

**Contributors**: See GitHub contributors list

**Special Thanks**: The BBS and MUD communities for keeping these platforms alive

---

Made with care for the BBS and MUD communities.

Connect, explore, and adventure at Terminal Tavern: telnet bbs.terminaltavern.com

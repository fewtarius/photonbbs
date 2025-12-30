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

## Live Demo

Try PhotonBBS and PhotonMUD live at **Terminal Tavern**:

```
telnet bbs.terminaltavern.com
```

Experience the full BBS, chat system, door games, and integrated MUD gameplay!

![PhotonBBS Screenshot](https://imgur.com/8gGLgnC.png)

## About

PhotonBBS is a comprehensive telnet-based bulletin board system (BBS) and multi-user dungeon (MUD) platform written in Perl. Originally created as a simple multi-node chat server, it has evolved into a full-featured platform combining classic BBS functionality with a modern, procedurally-generated MUD adventure.

### What Makes PhotonBBS Unique

**Integrated BBS and MUD**: PhotonBBS seamlessly combines traditional BBS features (chat, bulletins, door games) with PhotonMUD, a fully-featured multi-user dungeon with procedurally-generated worlds, dynamic combat, and persistent gameplay.

**Modular Architecture**: Built with extensibility in mind, PhotonBBS uses a modular Perl-based architecture that makes it easy to add new features, customize behavior, and integrate external door games.

**Classic BBS Revival**: Support for traditional BBS door games like Legend of the Red Dragon, Trade Wars 2002, and many others, allowing preservation of classic DOS gaming.

**Modern Deployment**: Containerized deployment via Docker ensures easy installation and portability across Linux, macOS, and Windows.

## Core Components

### PhotonBBS - The BBS Platform

- Multi-user chat and teleconference system
- User account management and authentication
- System bulletins and oneliners
- Customizable menu system
- Theme support with ANSI colors
- Classic BBS door game support
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

### Door Game Support

PhotonBBS supports classic BBS door games through multiple drop file formats:
- DOOR.SYS
- DORINFO1.DEF
- DORINFOx.DEF

Pre-configured support for popular doors:
- Trade Wars 2002 - Space trading and combat
- Legend of the Red Dragon (LORD) - Fantasy RPG adventure
- Barren Realms Elite (BRE) - Space strategy
- Operation Overkill II - Post-apocalyptic combat
- And many more

## Quick Start

### Installation via Docker (Recommended)

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

PhotonBBS consists of several key components:

**photonbbs** - Main daemon handling connections, node management, and sessions
**photonbbs-client** - Client application for user interaction
**photonmud** - MUD game engine with world generation and combat
**photonmud-monsterai** - AI system for monster behavior and spawning
**pb-* modules** - Core BBS functionality (framework, doors, chat, etc.)
**pm-* modules** - MUD game logic (combat, spells, rooms, monsters, etc.)

The system uses:
- Perl for core BBS and MUD logic
- Storable for data persistence
- Docker for containerized deployment
- Shell scripts for door game integration

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
- **Live Demo**: telnet bbs.terminaltavern.com

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

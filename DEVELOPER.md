# PhotonBBS Developer Documentation

**Part of the PhotonBBS platform** - See [README.md](README.md) for project overview, [PHOTONBBS.md](PHOTONBBS.md) for BBS documentation, and [PHOTONMUD.md](PHOTONMUD.md) for MUD documentation.

---

## Menus and SysOp Menu Functionality

PhotonBBS features a flexible, file-driven menu system that allows both users and SysOps to access internal commands, external doors, and utilities. Menus are defined in plain text files (typically `.mnu`), and can be customized or extended by the SysOp.

### How Menus Work

- **Menu files** are located in the `data/` directory (or sometimes `menu/` depending on configuration) and use the `.mnu` extension.
- Each menu entry can launch an internal command, an external script/door, or a submenu.
- Menus are context-sensitive: users only see options for which they have sufficient security level.
- The menu system is hot-reloaded: changes to menu files take effect for new sessions without restarting the BBS.

### Menu File Format

Each line in a menu file (except comments starting with `#`) has the following format:

```
Key|Description|Script|Security Level|Hidden|Type|Max Concurrent Users
```

- **Key**: The command or shortcut key the user types to select this item.
- **Description**: Shown in the menu listing.
- **Script**: The script, subroutine, or submenu file to execute.
- **Security Level**: Minimum security level required to see/use this item.
- **Hidden**: If set to `1`, only visible to SysOps or higher.
- **Type**: `internal`, `external`, or `submenu`.
- **Max Concurrent Users**: For doors/utilities, limits how many users can run it at once (blank for submenus or internal commands).

**Example:**
```
TW2002|TradeWars 2002|tradewars.sh|100|0|external|1
USEREDIT|User Editor|useredit.pl|500|0|external|1
BULLEDIT|Bulletin Editor|bulledit.pl|500|0|external|1
DOS|FreeDOS Shell|dos.sh|500|0|external|1
SHELL|BASH Shell|shell.sh|500|0|external|1
UTILS|Utilities|utils.mnu|0|0|submenu|
```

### Internal Commands

PhotonBBS provides several built-in internal commands that can be included in menus:

| Key  | Description             | Command Handler         |
|------|-------------------------|------------------------|
| &    | Teleconference          | menu_teleconference    |
| #    | Who's online            | whosonline             |
| %    | Write on the wall       | oneliners              |
| @    | Read System Bulletins   | bulletins              |
| !    | Log Off and Exit        | menu_exit              |

You can add these to any menu by including the key and description.

### Submenus

To create a submenu, set the Type to `submenu` and the Script to the submenu filename (e.g., `utils.mnu`).  
Users can navigate back to the previous menu by typing `^`.

### SysOp Tips

- **Edit or create menu files** in the `data/` or `menu/` directory to add, remove, or reorder options.
- **Restrict access** to sensitive utilities by setting the Security Level or Hidden flag.
- **Add new doors/utilities** by creating scripts in `doorexec/` and referencing them in your menu files.
- **Menus are hot-reloaded**: changes take effect for new sessions without restarting the BBS.

### Accessing Menus

- Users can type `/MENU` or `/DOORS` at any time to access the main menu or doors menu.
- The menu system will display available commands, doors, and utilities based on the user's security level.

---

**Example: Adding a SysOp Utilities Menu**

Create `data/sysop.mnu` (or `menu/sysop.mnu` if your configuration uses a `menu/` directory):

```
USEREDIT|User Editor|useredit.pl|500|0|external|1
BULLEDIT|Bulletin Editor|bulledit.pl|500|0|external|1
DOS|FreeDOS Shell|dos.sh|500|0|external|1
SHELL|BASH Shell|shell.sh|500|0|external|1
@|Read System Bulletins|||internal|
!|Log Off and Exit|||internal|
```

Then add a link to it from your main menu:

```
SYSOP|SysOp Utilities|sysop.mnu|500|0|submenu|
```

Now, any user with security level 500+ will see "SysOp Utilities" in the main menu and can access all sysop tools from there.

---

## Native Door Game Development

PhotonBBS includes a framework for building native Perl door games that integrate directly with the BBS. No external executables or DOS emulation required.

### Architecture

```
sbin/photonbbs-client
  |-- modules/pb-doorlib     (shared library: saves, scores, credits)
  |-- modules/pb-door-*      (individual game modules)
  |-- data/games.mnu         (games submenu definition)
  |-- data/main.mnu          (main menu with all entries)
```

### Creating a New Door Game

1. **Create the module**: `modules/pb-door-yourgame`
2. **Define an entry point**: `sub yourgame_main { ... }`
3. **Add require**: In `sbin/photonbbs-client`, add `require ($config{'home'}."/modules/pb-door-yourgame");`
4. **Add menu entry**: In `data/games.mnu` and `data/main.mnu`, add `K|Your Game (Description)|yourgame_main|10|0|internal|0`

### Module Template

```perl
#!/usr/bin/perl
#
# PhotonBBS Door: Your Game
# Brief description
#

my $DOOR_NAME = "yourgame";

sub yourgame_main {
  iamat($info{'handle'}, "Playing Your Game");

  # Title screen
  door_clear();
  writeline($config{'themecolor'} . " Your Game Title" . $RST, 1);

  # Load saved data
  my $save = door_load($DOOR_NAME);

  # ... game logic ...

  # Save progress
  door_save($DOOR_NAME, { score => $score, level => $level });

  # Submit high score
  door_submit_score($DOOR_NAME, $score, { level => $level });

  # Broadcast achievement
  door_broadcast($DOOR_NAME, "$info{'handle'} scored $score!");

  door_pause("Press any key to return...");
  iamat($info{'handle'}, "Finished Your Game");
}

1;
```

### Doorlib API

The `pb-doorlib` module provides these functions:

| Function | Purpose |
|----------|---------|
| `door_save($game, \%data)` | Save player data (per-user, per-game) |
| `door_load($game)` | Load player data (returns hashref or undef) |
| `door_delete_save($game)` | Delete player save |
| `door_save_shared($game, $file, \%data)` | Save shared game data |
| `door_load_shared($game, $file)` | Load shared game data |
| `door_submit_score($game, $score, \%meta)` | Submit to high score board |
| `door_get_scores($game, $limit)` | Get top scores |
| `door_show_scores($game, $title, $label)` | Display score board |
| `door_get_credits($game)` | Get player's credit balance |
| `door_add_credits($game, $amount)` | Add credits |
| `door_sub_credits($game, $amount)` | Subtract credits (returns 0 if insufficient) |
| `door_check_turns($game, $max)` | Check remaining turns today |
| `door_use_turn($game)` | Consume a turn |
| `door_broadcast($game, $msg)` | Send message to all online users |
| `door_send_message($game, $user, $msg)` | Send message to specific user |
| `door_get_messages($game)` | Get pending messages for current player |
| `door_mark_messages_read($game)` | Mark messages as read |
| `door_show_messages($game)` | Display and clear pending messages |
| `door_get_online_players($game)` | List online players in this game |
| `door_get_all_players($game)` | List all players (ever) for this game |
| `door_load_player($game, $name)` | Load another player's save |
| `door_save_player($game, $name, \%data)` | Save another player's data |
| `door_chat_send($game, $msg)` | Send in-game chat message |
| `door_chat_poll($game)` | Poll for new chat messages (returns list) |
| `door_chat_input($game)` | Interactive chat prompt |
| `door_chat_display($game)` | Display and clear pending chat |
| `door_clear()` | Clear screen |
| `door_pause($msg)` | Wait for keypress |
| `door_yesno($prompt)` | Y/N prompt (default Y) |
| `door_noyes($prompt)` | Y/N prompt (default N) |
| `door_getnum($prompt, $min, $max)` | Numeric input |
| `door_getamount($prompt, $max)` | Monetary amount input |
| `door_menu(\@items, $prompt)` | Display menu and get selection |
| `door_money($amount)` | Format number as currency |
| `door_log_activity($game, $msg)` | Log to activity feed |

### Multiplayer Patterns

Door games can use the shared PhotonBBS message broker for real-time multiplayer:

```perl
# At game startup - connect to broker
door_broker_connect("mygame");

# In game loop - show pending chat from other players
my @chat = door_chat_poll("mygame");
for my $m (@chat) {
    writeline($config{'linecolor'} . $m . $RST, 1);
}

# Send in-game chat
door_chat_input("mygame");  # interactive
door_chat_send("mygame", "message");  # programmatic

# Broadcast to all BBS users (shows in teleconference pages)
door_broadcast("mygame", "$info{'handle'} scored 10000 points!");

# Send direct message to a player
door_send_message("mygame", "PlayerName", "You've been challenged!");

# See who's online in your game right now
my @online = door_get_online_players("mygame");

# At game exit
door_broker_disconnect();
```

The broker is optional - games degrade gracefully if it's unavailable. The file-based fallback (`.page` files) handles broadcasts when the broker is down.

### Data Storage

Door game data is stored in `data/doors/<gamename>/`:
- `<username>.dat` - Per-user save (Storable format)
- `scores.dat` - High score board (shared)
- `credits.dat` - Credit balances (shared)
- `news.dat` - Recent broadcast feed (shared, auto-trimmed to 25 items)
- `exchange.dat`, `universe.dat`, etc. - Game-specific shared state
- `chat.dat` - In-game chat buffer (shared, expires after 5 minutes)
- `messages_<username>.dat` - Pending messages for a player

All shared files use Storable `lock_store`/`lock_retrieve` for safe concurrent access.
Register your game's shared files in `sbin/photonbbs-dooredit` under the `shared` array.

### Existing Games

See `modules/pb-door-*` for working examples. Key patterns:
- All games start with `iamat()` to set user status
- Use `waitkey()` for single-key input, `getline()` for text/numbers
- Use theme colors: `$config{'themecolor'}`, `$config{'datacolor'}`, etc.
- End all modules with `1;`

---



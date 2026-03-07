# PhotonBBS Native Door Game Development Guide

**Last Updated:** March 6, 2026  
**Purpose:** Complete reference for building native door games in PhotonBBS  
**Audience:** Developers adding new games to the pb-door-* module collection

---

## Overview

PhotonBBS native door games are Perl modules (no `package` declarations) that run in the `main::` namespace. They use the doorlib framework for common operations (saves, scores, credits, turns, I/O) and integrate directly with the BBS menu system.

Existing games (as of March 2026): Red Dragon, Star Trader, Casino, Drug Lord, Sea Battle, Star Trek, Big Catch, Atlantis, 1000 Miles, MUD (via `pb-doors` for DOS-era games: TradeWars, etc.)

---

## File Organization

```
modules/
├── pb-doorlib          # Shared door game library (REQUIRED - read this first)
├── pb-door-casino      # Casino (cards, dice, slots)
├── pb-door-druglord    # Drug Lord (trading, territory)
├── pb-door-reddragon   # Red Dragon (RPG)
├── pb-door-1000miles   # 1000 Miles (card game, multiplayer)
├── pb-door-seabattle   # Sea Battle (naval combat)
├── pb-door-startrek    # Star Trek
├── pb-door-startrader  # Star Trader
├── pb-door-bigcatch    # Big Catch (fishing)
├── pb-door-atlantis    # Atlantis
data/doors/
├── casino/             # Per-game save data
├── druglord/
├── 1000miles/
└── ...
```

---

## Doorlib API Reference

All functions are provided by `pb-doorlib`. Import it via `require_module('pb-doorlib')`.

### I/O Functions

```perl
door_clear()                    # Clear screen
door_pause()                    # Press any key to continue
door_hrule($width)              # Horizontal rule separator (use boxchar)
door_yesno($prompt)             # Returns 1 for Y, 0 for N
door_noyes($prompt)             # Returns 1 for N, 0 for Y
door_getnum($prompt, $min, $max) # Validated number input
door_menu($prompt, @options)    # Single-key menu selection
door_money($prompt)             # Dollar amount input
door_draw_cards(@cards)         # Display playing card hand
door_draw_slots(@reels)         # Display slot machine reels
```

### Persistence Functions

```perl
# Save/load player game data (Storable)
door_save($game_name, \%data)        # Save player's game state
my $data = door_load($game_name)     # Load player's game state (undef if none)

# Scores
door_submit_score($game, $score, \%extra)  # Submit to leaderboard
door_get_scores($game, $limit)             # Get top scores array
door_show_scores($game, $limit)            # Display leaderboard
```

### Credits and Turns

```perl
my $credits = door_get_credits()        # Current credits balance
door_add_credits($amount)               # Add credits (winnings)
door_sub_credits($amount)               # Subtract credits (bets)
my $turns = door_check_turns($game)     # Turns remaining today
door_use_turn($game)                    # Consume one turn
```

### Multiplayer

```perl
door_broadcast($game, $message)         # Broadcast to all online users
door_send_message($user, $msg)          # Private message to user
my @online = door_get_online_players()  # List of online users
```

---

## Module Structure

Every door game module must:

1. Start with a header comment
2. Define constants (use `use constant` or variable declarations)
3. Have a `gamename_main()` entry point
4. Return `1;` at the end

```perl
#!/usr/bin/perl
# Module: pb-door-mygame
# Description: Brief one-liner

# Constants
use constant {
    TURNS_PER_DAY => 10,
    STARTING_CREDITS => 1000,
};

my $DOOR_NAME = 'mygame';  # Used for save/score data directory

# Entry point called from menu system
sub mygame_main {
    iamat($info{'handle'}, "Playing My Game");  # Status update

    # Load or init player state
    my $save = door_load($DOOR_NAME) // {
        score    => 0,
        games    => 0,
    };

    # Check turns
    unless (door_check_turns($DOOR_NAME)) {
        writeline($config{'errorcolor'} . " No turns remaining today." . $RST, 1);
        door_pause();
        return;
    }

    # Game loop
    my $playing = 1;
    while ($playing) {
        door_clear();
        writeline($config{'themecolor'} . " MY GAME" . $RST, 1);
        door_hrule(40);
        # ... show game state ...
        writeline("", 1);
        writeline($config{'systemcolor'} . " [P] Play  [Q] Quit " .
            $config{'promptcolor'} . "> " . $RST);
        my $cmd = uc(waitkey("")); writeline("", 1);

        if ($cmd eq 'Q') { $playing = 0; }
        elsif ($cmd eq 'P') { _play_round($save); }
    }

    # Save state
    door_save($DOOR_NAME, $save);
    iamat($info{'handle'}, "Finished My Game");
}

# Private helper (prefix with _ by convention)
sub _play_round {
    my ($save) = @_;
    door_use_turn($DOOR_NAME);
    # ... game logic ...
}

1;
```

---

## Menu Registration

To add a game to the games menu, edit `data/games.mnu`:

```
# Format: KEY|LABEL|COMMAND
M|My Game|mygame_main
```

And add the module to the require list in `sbin/photonbbs-client`:

```perl
require_module('pb-door-mygame');
```

---

## The Action Log Pattern (Multiplayer Games)

For games with multiple players (human + AIs), show what happened between turns using an action log. See full documentation in PHOTONBBS_STYLE_GUIDE.md section "[TURNS] ACTION LOG PATTERN".

**Quick reference:**

```perl
# In game struct init:
$g->{action_log} = [];

# In AI turn:
push @{$g->{action_log}}, "$name played $card";

# In human turn (start):
my @pending_log = @{$g->{action_log} // []};
$g->{action_log} = [];
# ... show @pending_log after board display ...
# Limit: scalar(@{$g->{players}}) - 1 entries max
```

**Important:** Don't log the human's own actions in action_log (they already know what they did). The draw is shown separately via the `$drawn` variable.

---

## 24-Line Terminal Budget

**This is the most critical constraint in door game UI design.**

Standard BBS terminals are 24 lines × 80 columns. Every screen must fit in 24 lines including the input prompt on the last line.

### Counting Lines

```
Header/title:    1-2 lines
Separator:       1 line per section break
Content rows:    variable
Blank lines:     use sparingly (1 between sections)
Prompt:          1 line (always the last thing)
```

### 4-Player 2-Column Board Budget (1000 Miles Example)

```
Title:                   1
Separator:               1
Player pair 1 (3 rows):  3
Separator:               1
Player pair 2 (3 rows):  3
Separator:               1
"Your Hand:" header:     1
Hand rows (7 cards/2):   4
Blank:                   1
Deck/discard:            1
= 17 lines board
Remaining: 7 lines for action log + draw + prompt
```

### Rules

- **Fixed block heights**: Status blocks must be fixed height. Move optional data (safeties, buffs) to the name line in brackets rather than adding optional rows.
- **2-column layout**: Use when you have 3+ entities to show simultaneously.
- **Dynamic max_log**: Limit action log to `num_players - 1` entries.

---

## 2-Column Player Layout Pattern

For games with 3+ players, use 2-column layout:

```perl
my $COL_W    = 38;   # visible width per column
my $FULL_W   = 75;   # separator width
my $h        = boxchar('horizontal');
my $vl       = " " . $config{'linecolor'} . boxchar('vertical') . $RST . " ";
my $sep_full = $config{'linecolor'} . " " . ($h x $FULL_W) . $RST;
my $use_cols = ($np > 2);

# Build player status block (returns array of padded strings)
my $_player_block = sub {
    my ($pi) = @_;
    my $p = $g->{players}[$pi];
    my @lines;  # each: [colored_string, visible_length]

    # Line 1: name + optional tags in brackets
    my $safe_tag = @safeties ? " [" . join(" ", @safeties) . "]" : "";
    my $name_vis = "> " . $p->{name} . $safe_tag;
    push @lines, [
        "> " . $config{'usercolor'} . $p->{name} . $RST .
        ($safe_tag ? $config{'promptcolor'} . $safe_tag . $RST : ""),
        length($name_vis)
    ];

    # Line 2: status bar
    # Line 3: game state

    # Pad to COL_W using visible length
    my @padded;
    for my $line (@lines) {
        my ($str, $vlen) = @$line;
        push @padded, $str . (" " x ($COL_W - $vlen));
    }
    while (@padded < 3) { push @padded, " " x $COL_W; }  # min height
    return @padded;
};

if ($use_cols) {
    for (my $pi = 0; $pi < $np; $pi += 2) {
        writeline($sep_full, 1);
        my @left  = $_player_block->($pi);
        my @right = ($pi + 1 < $np) ? $_player_block->($pi + 1) : ();
        my $nlines = @left > @right ? scalar @left : scalar @right;
        for my $li (0 .. $nlines - 1) {
            my $l = $left[$li]  // (" " x $COL_W);
            my $r = $right[$li] // "";
            writeline($l . $vl . $r, 1);
        }
    }
} else {
    for my $pi (0 .. $np - 1) {
        writeline($sep_full, 1);
        for my $line ($_player_block->($pi)) { writeline($line, 1); }
    }
}
writeline($sep_full, 1);
```

---

## Human vs AI Turn Architecture

For single-human multiplayer games (1 human + N AI):

```
Human is always player 0 (human_idx = 0)
Turn rotation: 0 -> 1 -> 2 -> ... -> N-1 -> 0 -> ...
(Starting player determined by dice roll, not always 0)

Each iteration:
  if ($p->{type} eq 'human') {
      _do_human_turn(\%game, $pi);  # Blocking - waits for input
  } else {
      _do_ai_turn(\%game, $pi);     # Instant - AI logic
  }
```

**AI turns are silent** - no board display during AI turns. The human sees all AI actions in their next turn's action log.

**Do NOT redisplay the board between AI turns** - this causes screen flicker and wastes screen redraws. Let all AI turns happen silently, then show the full state + action log when it's the human's turn.

---

## Save Data Format

Use `door_save()` and `door_load()` for per-player per-game state. Data is stored in `data/doors/GAMENAME/HANDLE.dat` as Storable.

```perl
# Save structure example (1000 Miles)
door_save($DOOR_NAME, {
    total        => $player->{total},    # Cumulative score
    hands_won    => $player->{games},    # Hands won
    hands_played => $game{hands_played}, # Total hands
});

# Score submission
door_submit_score($DOOR_NAME, $score, {
    hands => $hands_played,
    wins  => $wins,
});
```

---

## Testing Door Games

```bash
# Syntax check before deploying
perl -c modules/pb-door-mygame

# Deploy to dev server (zaphod)
scp modules/pb-door-mygame deck@zaphod:~/photonbbs/modules/
ssh deck@zaphod "docker cp ~/photonbbs/modules/pb-door-mygame \
    docker-photonbbs-1:/opt/photonbbs/modules/pb-door-mygame && \
    docker exec docker-photonbbs-1 chmod +x \
    /opt/photonbbs/modules/pb-door-mygame"

# Connect and test
telnet zaphod 23
```

**Important after deploying:** If you changed `data/games.mnu`, you must also copy it into the Docker volume:

```bash
# Copy menu file to persistent volume
ssh deck@zaphod "docker cp ~/photonbbs/data/games.mnu \
    docker-photonbbs-1:/appdata/games.mnu"
```

---

## Common Pitfalls

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Screen overflow | Variable-height blocks + action log exceeds 24 lines | Fixed-height blocks, put optional data on existing lines |
| Action log shows only last action | `last_action` string can't accumulate | Use `action_log` array |
| Action log shows wrong player's actions | Human actions in log + AI actions = too many | Don't log human actions; they see result via board |
| Scrolled-off content | Board too tall for 24-line terminal | Count lines, use 2-column layout, merge optional fields |
| No turns display after deploy | Menu file not copied to Docker volume | `docker cp data/games.mnu container:/appdata/games.mnu` |
| Color codes break column alignment | Using `length()` on colored strings | Track visible length separately from string |

---

## Reference: pb-doorlib Functions Signatures

```perl
# I/O
door_clear()
door_pause()
door_hrule($width)
door_yesno($prompt)                     # Returns 1 (Y) or 0 (N)
door_noyes($prompt)                     # Returns 1 (N) or 0 (Y)
door_getnum($prompt, $min, $max)        # Validated number
door_menu($prompt, @options)            # Single char menu
door_money($prompt)                     # Dollar amount

# Card/slot visuals
door_draw_cards(@card_indices)          # Display hand
door_draw_slots(@reel_symbols)          # Slot display

# Persistence
door_save($game, \%data)
my $data = door_load($game)             # undef if no save
door_submit_score($game, $score, \%extra)
my @scores = door_get_scores($game, $limit)
door_show_scores($game, $limit)

# Economy
my $bal = door_get_credits()
door_add_credits($amount)
door_sub_credits($amount)

# Turns
my $n = door_check_turns($game)         # 0 if no turns left
door_use_turn($game)

# Multiplayer
door_broadcast($game, $message)
door_send_message($user, $msg)
my @online = door_get_online_players()
```

---

*See also: PHOTONBBS_STYLE_GUIDE.md for UI/UX rules, AGENTS.md for codebase overview*

# PhotonBBS Module Development Style Guide

**Last Updated**: March 6, 2026  
**Purpose**: Standardize UI/UX across all PhotonBBS modules  

---

## 🎨 CORE PRINCIPLES

1. **NO UNICODE BOX DRAWING** - Use simple ASCII text
2. **NO FANCY ASCII ART** - Clean, readable text only
3. **FOLLOW EXISTING PATTERNS** - Match teleconference/menu systems
4. **USE THEME COLORS** - Consistent color scheme via `%config` hash
5. **SIMPLE AND CLEAN** - Let the content speak, not the formatting

---

## 📋 STANDARD COLOR USAGE

### Available Color Variables (from `%config` hash)
```perl
$config{'themecolor'}   # Primary theme color (labels, separators)
$config{'datacolor'}    # Data values and secondary info
$config{'usercolor'}    # Usernames and highlighted content
$config{'systemcolor'}  # System messages
$config{'errorcolor'}   # Error messages
$config{'promptcolor'}  # User input prompts
$config{'inputcolor'}   # User input text
$config{'linecolor'}    # Line separators
```

### When to Use Each Color

- **$config{'themecolor'}** - Section headers, descriptive text, labels
- **$config{'datacolor'}** - List headers, category names
- **$config{'usercolor'}** - Important values, highlighted items
- **$config{'promptcolor'}** - Command keys/letters (A, B, C, etc.)
- **$config{'systemcolor'}** - Status messages, confirmations
- **$config{'errorcolor'}** - Errors, warnings, denied access
- **$RST** - ALWAYS reset colors after colored text

---

## 📝 MENU/LIST FORMATTING

### Standard Menu Format
```perl
# Section Header (simple, no decoration)
main::writeline($config{'datacolor'}."Section Name".$RST, 1);

# Menu items (key ... description format)
main::writeline("  ".$config{'promptcolor'}."A".$config{'themecolor'}." ... ".$config{'usercolor'}."Description", 1);
main::writeline("  ".$config{'promptcolor'}."B".$config{'themecolor'}." ... ".$config{'usercolor'}."Another Item", 1);
```

### Example (From pb-main teleconference menu)
```perl
writeline($theme{'commandshdr'} // $config{'themecolor'}."\nCommands".$RST, 1);
writeline("  ".$config{'datacolor'}."&".$config{'themecolor'}." ... ".$config{'usercolor'}."Teleconference".$RST, 1);
writeline("  ".$config{'datacolor'}."#".$config{'themecolor'}." ... ".$config{'usercolor'}."Who's online".$RST, 1);
```

---

## 🗂️ DATA DISPLAY FORMATTING

### List Items with Details
```perl
# Section header
main::writeline($config{'datacolor'}."Item List".$RST, 1);

# Items (field ... value format)
main::writeline("  ".$config{'usercolor'}.$key.$config{'themecolor'}." ... ".$config{'datacolor'}.$value.$RST, 1);
```

### Example (Security Dashboard - CORRECT)
```perl
main::writeline($config{'datacolor'}."Banned IPs".$RST, 1);
foreach my $ban (@bans) {
    my $ip = $ban->{ip};
    my $reason = $ban->{reason};
    my $expires = $ban->{expires} > 0 ? scalar(localtime($ban->{expires})) : "Never";
    main::writeline("  ".$config{'usercolor'}.$ip.$config{'themecolor'}." ... ".$config{'datacolor'}.$reason.$config{'themecolor'}." (expires: ".$expires.")".$RST, 1);
}
```

### ❌ WRONG - DON'T DO THIS
```perl
# NO unicode box drawing
main::writeline("╔═══════════════════════════╗", 1);
main::writeline("║   BANNED IPS             ║", 1);
main::writeline("╚═══════════════════════════╝", 1);

# NO === headers
main::writeline("=== BANNED IPS ===", 1);

# NO table-style columnar formatting
main::writeline("IP Address          Reason                      Expires", 1);
main::writeline("-----------------------------------------------------------", 1);
```

---

## 🎯 STATISTICS/SUMMARY DISPLAY

### Standard Format
```perl
main::writeline($config{'datacolor'}."Statistics".$RST, 1);
main::writeline("  ".$config{'themecolor'}."Label: ".$config{'usercolor'}.$value.$RST, 1);
main::writeline("  ".$config{'themecolor'}."Another: ".$config{'usercolor'}.$value2.$RST, 1);
```

### Example
```perl
main::writeline($config{'datacolor'}."Statistics".$RST, 1);
main::writeline("  ".$config{'themecolor'}."Active bans: ".$config{'usercolor'}.$total_bans.$RST, 1);
main::writeline("  ".$config{'themecolor'}."Recent failed logins: ".$config{'usercolor'}.$total_failures.$RST, 1);
```

---

## 💬 USER PROMPTS

### Standard Prompt Format
```perl
main::writeline("", 1);  # Blank line for spacing
main::writeline($config{'promptcolor'}."Enter your choice: ".$RST);
my $input = main::getline('text', 50, "", 1);
```

### Command Menu Prompts
```perl
main::writeline($config{'datacolor'}."Commands".$RST, 1);
main::writeline("  ".$config{'promptcolor'}."A".$config{'themecolor'}." ... ".$config{'usercolor'}."Action", 1);
main::writeline("  ".$config{'promptcolor'}."Q".$config{'themecolor'}." ... ".$config{'usercolor'}."Quit", 1);
main::writeline("", 1);
main::writeline($config{'promptcolor'}."Enter command: ".$RST);
```

---

## 🖥️ SCREEN MANAGEMENT

### Clear Screen
```perl
# Use global $CLR variable (defined in pb-framework)
main::writeline($CLR, 0);  # 0 = no newline
```

### Page Headers
```perl
# Simple header (NO boxes or decorations)
main::writeline($CLR, 0);
main::writeline($config{'themecolor'}."\nPage Title".$RST, 1);
main::writeline("", 1);  # Blank line for spacing
```

---

## ⚠️ ERROR MESSAGES

### Standard Error Format
```perl
main::writeline($config{'errorcolor'}."Error: Description of error".$RST, 1);
```

### Access Denied
```perl
unless ($info{'security'} >= $config{'sec_sysop'}) {
    main::writeline($config{'errorcolor'}."Access denied. Sysop privileges required.".$RST, 1);
    return;
}
```

---

## ✅ SUCCESS/CONFIRMATION MESSAGES

### Standard Format
```perl
main::writeline($config{'systemcolor'}."Action completed successfully".$RST, 1);
```

### Example (From teleconference)
```perl
writeline($BWH."Entering channel ".$config{'usercolor'}.$channel.$BWH." ...\n",1);
```

---

## 📐 SPACING AND LAYOUT

### General Rules
```perl
# 1. Use blank lines for section spacing
main::writeline("", 1);

# 2. Indent list items with 2 spaces
main::writeline("  ".$config{'datacolor'}."Item", 1);

# 3. NO manual column formatting
# ❌ WRONG:
sprintf("%-20s %-30s %s", $col1, $col2, $col3);

# ✅ RIGHT:
main::writeline("  ".$config{'usercolor'}.$col1.$config{'themecolor'}." ... ".$config{'datacolor'}.$col2.$RST, 1);
```

---

## 🔧 MODULE STRUCTURE

### Standard Module Template
```perl
#!/usr/bin/perl
# Module Name: pb-your-module
# Purpose: Brief description
# NO package declaration - runs in main package

# NO strict/warnings - inherited from main
# NO separate require/logger - use main package's

sub your_function {
    # Use main:: prefix for pb-framework functions
    main::writeline($CLR, 0);
    main::writeline($config{'themecolor'}."\nYour Screen".$RST, 1);
    main::writeline("", 1);
    
    # Your code here
    my $input = main::getline('text', 50, "", 1);
    
    # Process and display
    main::writeline($config{'datacolor'}."Result".$RST, 1);
    main::writeline("  ".$config{'usercolor'}.$value.$RST, 1);
}

1;  # Module must return true
```

---

## 🎨 THEME INTEGRATION

### Using Theme Variables
```perl
# Prefer theme variables when available
writeline($theme{'mainmenuhdr'} // $config{'themecolor'}."\nMain Menu".$RST, 1);
writeline($theme{'invalidsel'} // $config{'errorcolor'}."Invalid selection.".$RST, 1);
```

### Fallback Pattern
```perl
$theme{'your_key'} // $config{'appropriate_color'}."Default Text".$RST
```

---

## 🧪 TESTING YOUR MODULE

### Visual Check Checklist
- [ ] No unicode box drawing characters
- [ ] No === or similar ASCII art headers
- [ ] Menu items use "key ... description" format
- [ ] Colors match existing BBS screens
- [ ] Spacing is clean and consistent
- [ ] All text ends with `.$RST`
- [ ] Blank lines separate sections

### Test via Telnet
```bash
# Deploy to Marvin
scp modules/pb-your-module fewtarius@marvin:/tmp/
ssh fewtarius@marvin "docker cp /tmp/pb-your-module docker-photonbbs-1:/opt/photonbbs/modules/"
ssh fewtarius@marvin "docker restart docker-photonbbs-1"

# Test
ssh fewtarius@marvin
telnet localhost 23
```

---

## 📚 REFERENCE IMPLEMENTATIONS

### Best Examples to Study
- `modules/pb-main` - Menu system (lines 270-297)
- `modules/pb-main` - Teleconference (lines 420-700)
- `modules/pb-security-admin` - Modern clean implementation

### Key Functions to Use
```perl
# Output (from pb-framework)
main::writeline($text, $newline)   # Display text
main::getline($type, $max, $default, $echo)  # Get input

# Colors (global variables)
$CLR                  # Clear screen
$RST                  # Reset colors
$config{'color'}      # Theme colors
```

---

## ⚡ QUICK REFERENCE

### Standard Screen Layout
```perl
# 1. Clear screen
main::writeline($CLR, 0);

# 2. Page title (simple, no decoration)
main::writeline($config{'themecolor'}."\nPage Title".$RST, 1);
main::writeline("", 1);

# 3. Data section
main::writeline($config{'datacolor'}."Section Name".$RST, 1);
main::writeline("  ".$config{'usercolor'}."item".$config{'themecolor'}." ... ".$config{'datacolor'}."value".$RST, 1);
main::writeline("", 1);

# 4. Commands section
main::writeline($config{'datacolor'}."Commands".$RST, 1);
main::writeline("  ".$config{'promptcolor'}."A".$config{'themecolor'}." ... ".$config{'usercolor'}."Action", 1);
main::writeline("  ".$config{'promptcolor'}."Q".$config{'themecolor'}." ... ".$config{'usercolor'}."Quit", 1);
main::writeline("", 1);

# 5. Prompt for input
main::writeline($config{'promptcolor'}."Enter command: ".$RST);
my $cmd = uc(main::getline('text', 1, "", 1));
```

---

## 🚫 COMMON MISTAKES

### ❌ DON'T
- Use unicode characters (╔═╗║─│)
- Create table-style headers with column alignment
- Use === or similar text decorations
- Forget `.$RST` after colored text
- Call `clearscreen()` (doesn't exist, use `$CLR`)
- Use `strict` or `warnings` in module files
- Create separate `require_module` or `logger` functions

### ✅ DO
- Use simple text headers
- Use "key ... description" format for lists
- Separate sections with blank lines
- Always end colored text with `.$RST`
- Use global `$CLR` variable for screen clear
- Run in main package namespace
- Use `main::` prefix for pb-framework functions

---

## 📖 STYLE PHILOSOPHY

**PhotonBBS is a classic BBS system** - it should look and feel like one. The beauty is in the **simplicity and readability**, not fancy graphics or complex layouts.

**When in doubt, look at existing screens**:
- Teleconference menus
- Main menu system
- User lists (`whosonline`)
- Bulletin boards

**Match the existing aesthetic** - users should feel like your module has always been part of the system.

---

**Remember**: Consistency is key. Every screen should feel like it belongs to the same system.

---

## 🎮 DOOR GAME UI PATTERNS

Door games use `pb-doorlib` helper functions and `boxchar()` for all visual elements. These provide consistent, CP437-compatible box drawing that works on both telnet (CP437) and terminal connections.

### Output Rules (door games)

| Situation | Use |
|-----------|-----|
| All text output | `writeline()` |
| Columnar data (fixed-width columns) | `writeline()` + `sprintf()` |
| Horizontal separator lines | `door_hrule($width)` |
| Playing cards | `door_draw_cards(\@cards, $color, $label)` |
| Slot machine reels | `door_draw_slots(\@reels, $winning)` |
| Box borders (headers, grids) | `boxchar('topleft')`, `boxchar('horizontal')` etc. |
| **Never** | `render_table()` - only for .md files via readfile() |
| **Never** | `"-" x N` raw dashes - use `door_hrule()` |
| **Never** | printf/format/write in door games - use writeline |

### Separator Lines

```perl
# WRONG - raw dashes
writeline($config{'linecolor'} . " " . ("-" x 50) . $RST, 1);

# RIGHT - boxchar horizontal rule
door_hrule(50);                    # linecolor by default
door_hrule(50, $config{'themecolor'});  # custom color
```

### Card Art (`door_draw_cards`)

Renders playing cards as 5-line tall box art, 9 chars wide each, side by side.

```perl
# Blackjack dealer hand (one face-down card)
door_draw_cards(
  [_casino_card_code($dealer[0]), '?'],   # '?' = face-down
  $config{'linecolor'},
  "Dealer:"
);

# Player hand with value
door_draw_cards(
  [map { _casino_card_code($_) } @player],
  $config{'linecolor'},
  "You: ($pval)"
);
```

Card format strings: `"AH"`, `"10D"`, `"KS"`, `"2C"`, `"?"` for face-down.

Card layout (9 wide x 5 tall):
```
┌───────┐
│ 9     │    rank top-left (%-2s then 4 spaces)
│      │    suit CP437 symbol centered
│     9 │    rank bottom-right (4 spaces then %2s+space)
└───────┘
```
- Hearts/Diamonds: `$config{'errorcolor'}` (red)
- Clubs/Spades: `$config{'datacolor'}`
- Hidden card `?`: all three corners use `?` at same offsets as a single-digit rank

### Slot Machine (`door_draw_slots`)

Renders a 3-reel slot machine with box-drawing borders.

```perl
door_draw_slots(\@reels, $winnings);   # $winnings > 0 highlights reels
```

Output:
```
┌─────────┬─────────┬─────────┐
│ Cherry   │  Bell   │  BAR   │
└─────────┴─────────┴─────────┘
```

### Box Borders (grids, frames)

Use `boxchar()` from pb-framework for all box-drawing characters.

```perl
# Box top
my $top = boxchar('topleft') . (boxchar('horizontal') x $width) . boxchar('topright');
# Box row
my $row = boxchar('vertical') . $content . boxchar('vertical');
# Box bottom
my $bot = boxchar('bottomleft') . (boxchar('horizontal') x $width) . boxchar('bottomright');
# T-junctions for multi-column
boxchar('tdown')   # ┬ - splits top border
boxchar('tup')     # ┴ - splits bottom border
boxchar('tright')  # ├ - left mid-divider
boxchar('tleft')   # ┤ - right mid-divider
```

### Screen Management in Door Games

**Rule: Never let output scroll past 24 lines.** Door games that loop must clear and redraw on each iteration.

```perl
# WRONG - accumulates output across turns
while ($playing) {
  writeline("Dealer: ...", 1);
  writeline("You: ...", 1);
  # prompt...
}

# RIGHT - clear and redraw each turn
while ($playing) {
  door_clear();
  writeline($config{'themecolor'} . " Game Title" . $RST, 1);
  door_hrule(50);
  writeline($config{'systemcolor'} . " Balance: ..." . $RST, 1);
  writeline("", 1);
  # draw game state...
  # prompt at bottom...
}
```

Games where this applies: Blackjack (clears each action), Slots (clears each spin), any game with a persistent loop.

### Door Game Checklist

- [ ] All separators use `door_hrule()` not `"-" x N`
- [ ] Card games use `door_draw_cards()` for hand display
- [ ] Slot machines use `door_draw_slots()`
- [ ] Box borders use `boxchar()` not `+---+` or Unicode
- [ ] Game loops call `door_clear()` at top to prevent scroll overflow
- [ ] All output through `writeline()` not `printf`/`print`
- [ ] No `render_table()` calls anywhere in door games

---

## [MULTI-PLAYER] MULTI-COLUMN BOARD LAYOUT

### When to Use Multi-Column Layouts

For multiplayer games with 3+ players, use a 2-column layout to show all player status on one screen. Single-column for 1-2 players.

```perl
my $use_cols = ($np > 2);  # 2-column for 3+ players
```

### Column Width Constraints (80-column terminal)

**Critical:** Total visible width must not exceed 78-79 characters.

```
[left col 38 chars] [separator " | " = 3] [right col 38 chars] = 79 total
```

```perl
my $COL_W   = 38;    # visible width per column
my $FULL_W  = 75;    # separator line width (leading space adds 1)
my $h       = boxchar('horizontal');
my $vl      = " " . $config{'linecolor'} . boxchar('vertical') . $RST . " ";
my $sep_full = $config{'linecolor'} . " " . ($h x $FULL_W) . $RST;
```

### Tracking Visible Width (Color Codes Are Invisible)

When building padded columns, track VISIBLE length separately from string length. Color codes add bytes but no visible width.

```perl
# Build lines as [colored_string, visible_length] pairs
my @lines;

# Example: "  Rolling" with color
my $vis_str = "  " . $battle_str;          # visible text
push @lines, [
    "  " . $status_clr . $battle_str . $RST,  # colored string
    length($vis_str)                            # visible length (no color codes)
];

# Pad to column width using visible length
my ($str, $vlen) = @$line;
my $pad = $COL_W - $vlen;
$pad = 0 if $pad < 0;
push @padded, $str . (" " x $pad);
```

### Fixed vs Variable Block Height

**CRITICAL:** Player status blocks MUST be fixed height. Variable-height blocks (e.g., showing safeties as a 4th line) cause the board to overflow 24 lines when safeties are played.

```perl
# WRONG: Optional 4th line for safeties
if (@safeties_played) {
    push @lines, ["  " . join(" ", @safeties) . $RST, $safe_vis_len];
}

# RIGHT: Merge optional data into existing lines
# Put safeties on the name line in brackets
my $safe_tag = @played ? " [" . join(" ", @played) . "]" : "";
my $name_vis = $marker . " " . $p->{name} . $tag . $safe_tag;
push @lines, [
    $marker . " " . $name_color . $p->{name} . $tag . $RST .
    ($safe_tag ? $config{'promptcolor'} . $safe_tag . $RST : ""),
    length($name_vis)
];

# Ensure minimum height padding
while (@padded < 3) { push @padded, " " x $COL_W; }
```

---

## [TURNS] ACTION LOG PATTERN (MULTIPLAYER DOOR GAMES)

### Problem

In multiplayer games, the human player only sees the board on their own turn. They miss what all AI/other players did between their turns. A single `$g->{last_action}` string can only show the most recent action.

### Solution: Persistent Action Log

Use an array `action_log` that accumulates all AI actions between human turns. Show the log at the start of each human turn, then clear it.

```perl
# Game init: start with empty log
$g->{action_log} = [];

# AI turn: push to log (ALWAYS push, even for discard)
sub _do_ai_turn {
    my ($g, $pi) = @_;
    # ... do AI move ...
    push @{$g->{action_log}}, "$name played " . $CARD_NAMES[$card];
}

# Human turn: snapshot, clear, display
sub _do_human_turn {
    my ($g, $pi) = @_;
    
    # Snapshot accumulated actions from other players
    my @pending_log = @{$g->{action_log} // []};
    $g->{action_log} = [];   # Clear for next round
    
    while (1) {
        _show_board($g, $pi);
        writeline("", 1);
        
        # Show recent AI actions (limit to fit in terminal)
        my $max_log = scalar(@{$g->{players}}) - 1;  # one per AI
        my @show_log = @pending_log > $max_log
            ? @pending_log[-$max_log..-1]
            : @pending_log;
        for my $act (@show_log) {
            writeline($config{'systemcolor'} . " " . $act . $RST, 1);
        }
        
        # Show human's own draw separately
        if ($drawn >= 0) {
            writeline($config{'systemcolor'} . " You drew: " . $CARD_NAMES[$drawn] . $RST, 1);
        }
        
        # ... rest of input handling ...
    }
}
```

### Key Rules

1. **Human actions go in action_log too** only if other players need to see them (e.g., in a hot-seat multiplayer game). For single-human vs AI, **don't log human actions** - they already know what they did.
2. **Limit display** to `num_players - 1` entries maximum to prevent terminal overflow.
3. **Clear on snapshot**, not on hand start (keeps actions visible across the full round).
4. **Reset on hand start** via `action_log = []` in the hand init function.

### 24-Line Terminal Math

Always count lines before adding action logs:

```
4-player 2-column game:
  Title line:          1
  Separator lines:     3  (one between each pair + one at bottom)
  Player pair rows:    6  (3 lines × 2 pairs)
  "Your Hand:" header: 1
  Hand card rows:      4  (7 cards in 2 cols = 4 rows)
  Blank line:          1
  Deck/discard status: 1
  ──────────────────── = 17 lines for board
  
  Remaining: 24 - 17 = 7 lines for:
    Blank before log:  1
    AI actions (×3):   3  (= num_players - 1)
    Draw line:         1
    Blank after log:   1
    Prompt:            1
    ──────────────── = 7 lines  ✓  (exactly fits!)
```

If your board exceeds 17 lines, reduce `max_log` accordingly.

---

## [MULTIPLAYER] HOT-SEAT AND NETWORK MULTI-PLAYER (PLANNED)

### Player Join Flow (Not Yet Implemented)

For games supporting multiple human players, the first player to start the game should:

1. Choose number of players (e.g., 2-4)
2. See a countdown: "Waiting for players... [60s] Press Y to fill with AI"
3. After timeout or when slots fill, start with AI filling empty slots

```perl
sub wait_for_players {
    my ($game, $max_players, $timeout) = @_;
    my $start = time();
    
    while (scalar(@{$game->{players}}) < $max_players) {
        my $elapsed = time() - $start;
        my $remaining = $timeout - $elapsed;
        
        if ($remaining <= 0) {
            # Ask if user wants to keep waiting
            writeline($config{'systemcolor'} . " Still waiting... Keep waiting? (Y=yes, N=fill with AI) " . $RST);
            my $ch = uc(waitkey(""));
            return unless $ch eq 'Y';
            $start = time();  # Reset timer
        }
        
        # Check for new players joining (via shared data file)
        my $joined = check_player_join($game->{session_id});
        if ($joined) {
            push @{$game->{players}}, $joined;
            writeline($config{'usercolor'} . " " . $joined->{name} . " joined!" . $RST, 1);
        }
        
        sleep(1);
        # Show countdown update
        writeline("\r" . $config{'systemcolor'} . " Waiting for players... [${remaining}s]" . $RST);
    }
}
```

**Implementation Note:** This requires a shared session file that other BBS users can discover and join. Use `door_broadcast()` to announce the waiting game. Store session state in `data/doors/GAMENAME/sessions/`.


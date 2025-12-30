# PhotonBBS Module Development Style Guide

**Last Updated**: December 30, 2025  
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

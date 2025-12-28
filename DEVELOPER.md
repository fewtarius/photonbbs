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

**Note:**  
- Menu files are typically found in `data/` but may be in `menu/` depending on your deployment or configuration.
- Internal commands and menu navigation are handled by the core [`pb-main`](modules/pb-main) module.
- For external doors/utilities, ensure your scripts are executable and located in the `doorexec/` directory.

---

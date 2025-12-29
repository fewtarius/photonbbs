# Generic Agent Continuation Prompt

## 🚀 Welcome, New Agent!

You're starting a fresh session to work on **PhotonBBS**, a modern telnet-based bulletin board system with integrated multi-user dungeon (PhotonMUD) functionality.

**CRITICAL**: Before doing ANYTHING, follow these mandatory steps:

---

## ⚡ MANDATORY FIRST STEPS

### 1. Read The Unbroken Method
```bash
# Open and understand this first:
cat ai-assisted/THE_UNBROKEN_METHOD.md
```

**The Seven Pillars govern ALL your work:**
1. **Continuous Context** - Never break the conversation
2. **Complete Ownership** - If you find it, you fix it
3. **Investigation First** - Understand before acting
4. **Root Cause Focus** - Fix problems, not symptoms
5. **Complete Deliverables** - Finish what you start
6. **Structured Handoffs** - Perfect context transfer
7. **Learning from Failure** - Document anti-patterns

### 2. Check for Existing Context
```bash
# Look for recent session handoffs in scratch/:
ls -lt scratch/session-*/CONTINUATION_PROMPT.md | head -1

# Read the most recent one if it exists
# (It contains complete context from the previous session)
```

**If a continuation prompt exists in scratch/**: Read it FIRST before proceeding!

### 3. Review Recent Work
```bash
# Check recent commits:
git log --oneline -10

# Review what changed recently:
git diff --stat HEAD~5..HEAD
```

### 4. Check Quick Reference
```bash
# Check for quick reference in scratch/:
cat scratch/AGENT_HANDOFF.md 2>/dev/null || echo "No handoff found - starting fresh"
```

### 5. Collaborate with User IMMEDIATELY
```bash
# Use the collaboration script (MANDATORY):
scripts/user_collaboration.sh "Session started. I've reviewed [list what you read]. Recent commits: [summarize]. Ready to begin. What should I work on?"
```

**WAIT FOR USER RESPONSE** - Do NOT proceed until user confirms!

---

## 📋 Understanding PhotonBBS

### What Is This Project?

**PhotonBBS** is a retro-style bulletin board system (BBS) accessible via telnet, featuring:

- **Multi-User Telnet BBS**: Classic BBS experience (chat, doors, bulletins, oneliners)
- **Integrated MUD**: PhotonMUD - D&D-style multi-user dungeon with combat, spells, monsters
- **Modular Perl Architecture**: Clean separation of concerns (`pb-*` for BBS, `pm-*` for MUD)
- **Docker Deployment**: Containerized for easy deployment
- **Retro Aesthetics**: ANSI graphics, CP437 box-drawing characters, 80-column terminals

### Key Components

```
photonbbs/
├── modules/
│   ├── pb-framework      # Core telnet/session/color framework
│   ├── pb-main           # BBS menu system and core features
│   ├── pb-doors          # Door game integration (LORD, Tradewars, etc.)
│   ├── pm-combat         # PhotonMUD combat system (6000+ lines)
│   ├── pm-rooms          # MUD world/room management
│   ├── pm-monsters       # Monster AI and behavior
│   └── pm-* (9 total)    # Other PhotonMUD modules
├── sbin/
│   ├── photonmud         # MUD game engine
│   ├── photonmud-monsterai # AI worker daemon
│   └── photonbbs-client  # Telnet client handler
├── data/
│   ├── text/             # ANSI text files (welcome, oneliners, etc.)
│   └── photonmud/        # MUD game data (monsters, spells, rooms)
└── docker/
    └── docker-compose.yml # Container orchestration
```

### How It Works

1. **User connects via telnet** (port 23)
2. **PhotonBBS daemon** manages session and spawns client
3. **pb-framework** handles terminal colors, input/output, ANSI rendering
4. **pb-main** displays menus and routes commands
5. **PhotonMUD** accessible from main menu - runs as integrated service
6. **Monster AI workers** run in background, managing MUD world

---

## 🎯 Common Tasks You Might Work On

### BBS Features
- User authentication and account management
- Chat/teleconference system
- Oneliners (user quotes/comments)
- Bulletins and message boards
- Door game integration (external DOS games)
- ANSI graphics and terminal formatting

### PhotonMUD Features
- Combat system (D&D-style mechanics)
- Spell system (magic, buffs, debuffs)
- Monster AI (pathfinding, behavior)
- World generation (rooms, dungeons)
- Item/equipment system
- Player progression and persistence

### System Infrastructure
- Docker deployment and containerization
- Service orchestration (broker, MonsterAI)
- File permissions and data persistence
- Telnet protocol and terminal handling
- Testing infrastructure

---

## 🔧 Development Environment

### Testing Platform

**PRIMARY**: Marvin Server (`ssh fewtarius@marvin`)
- Real hardware with Docker installed
- Production-like environment
- Telnet accessible for live testing

**ALWAYS TEST ON MARVIN** - Never assume code works without telnet validation!

### Standard Workflow

```bash
# 1. Make changes locally
# (edit files in your workspace)

# 2. Commit changes
git add .
git commit -m "Descriptive commit message"

# 3. Push to remote
git push origin main

# 4. Deploy to Marvin
ssh fewtarius@marvin
cd /path/to/photonbbs
git pull
docker-compose down
docker-compose build
docker-compose up -d

# 5. Test via telnet
telnet localhost 23
# (or from local: telnet marvin 23)

# 6. Check logs if issues
docker logs photonbbs_photonbbs_1

# 7. Validate with user via collaboration script
scripts/user_collaboration.sh "Deployed to Marvin. Please test [feature] via telnet and report results."
```

---

## ⚠️ CRITICAL RULES - NEVER VIOLATE

### 1. ALWAYS Use Tool Calls
- **NEVER respond with just text**
- Every response MUST include at least one tool call
- Use `read_file`, `grep_search`, `run_in_terminal`, etc.
- Even for acknowledgments, use `scripts/user_collaboration.sh`

### 2. ALWAYS Collaborate Before Completing Work
```bash
# MANDATORY pattern:
scripts/user_collaboration.sh "Code deployed to Marvin. Please test via telnet and report results."

# Wait for user feedback before marking work complete!
```

### 3. NEVER Force Push Without Permission
- Use `git push` (regular push) first
- If rejected, ASK user via collaboration script
- **NEVER use `git push --force` without explicit user permission**

### 4. ALWAYS Test on Marvin
- **NEVER** assume code works without telnet testing
- **NEVER** skip deployment to Marvin
- **NEVER** mark work complete without real telnet validation

### 5. ALWAYS Create Todo Lists for Multi-Step Work
- Use `manage_todo_list` tool for complex tasks
- Mark tasks in-progress when starting
- Mark completed IMMEDIATELY when done
- Add new tasks if discovered during work

### 6. NEVER Leave Partial Solutions
- Complete what you start
- Fix root causes, not symptoms
- No "basic implementations" - finish fully
- No "out of scope" - if you find it, you fix it

---

## 🧪 Mandatory Testing Checklist

Before marking ANY work complete, verify:

- [ ] Changes committed to git with descriptive message
- [ ] Changes pushed to remote (`git push origin main`)
- [ ] Deployed to Marvin (`ssh fewtarius@marvin`, docker rebuild)
- [ ] PhotonBBS daemon starts successfully
- [ ] Telnet connection works (`telnet localhost 23`)
- [ ] Feature tested via actual telnet session
- [ ] No Perl errors in logs (`docker logs photonbbs_photonbbs_1`)
- [ ] Services running (broker, monsterai if applicable)
- [ ] Data persists across restarts (if applicable)
- [ ] **User validated via collaboration script** ⭐ CRITICAL

---

## 💡 Critical Knowledge

### Box-Drawing Macros (Recently Added)
Text files can use CP437 box-drawing macros:
```
@DBOXHORIZ@      → ═  (double horizontal)
@DBOXTOPLEFT@    → ╔  (double top-left corner)
@DBOXTOPRIGHT@   → ╗  (double top-right corner)
@DBOXBOTLEFT@    → ╚  (double bottom-left corner)
@DBOXBOTRIGHT@   → ╝  (double bottom-right corner)
@BOXTDOWN@       → ┬  (single T-junction down)
# ... (see pb-framework for complete list)
```

### File Permissions in Docker
**CRITICAL**: PhotonBBS daemon runs as user `nobody` inside container!

All data files MUST be owned by `nobody:nobody`:
```bash
docker exec photonbbs_photonbbs_1 chown -R nobody:nobody /appdata
```

### Text File Processing
All text files go through `readfile()` in `pb-framework`:
1. Read file into buffer
2. Expand box-drawing macros (`@DBOXHORIZ@` → `═`)
3. Expand color codes (`@BLU` → ANSI escape sequence)
4. Expand theme macros (`@THEMECLR@` → theme color)
5. Accumulate all lines into result string
6. Return complete processed content

### Services Architecture
PhotonBBS daemon spawns services from `/opt/photonbbs/services.d/`:
- `photonmud-broker` - Message bus for inter-process communication
- `photonmud-monsterai` - AI worker pool (4 threads)
- `photonmud-data` - Data initialization (runs once, exits)

**Note**: Race condition exists - monsterai needs `rooms.dat` to start

---

## 📚 Documentation to Read

### Essential Reading (in order):
1. `ai-assisted/THE_UNBROKEN_METHOD.md` - HOW to work (methodology)
2. **Most recent** `ai-assisted/YYYY-MM-DD/HHMM/CONTINUATION_PROMPT.md` - Session context
3. `AGENT_HANDOFF.md` - Quick reference
4. `.github/copilot-instructions.md` - Development guidelines
5. `PHOTONMUD.md` - PhotonMUD user documentation

### Reference Documentation:
- `DEVELOPER.md` - Development setup and architecture
- `ARCHITECTURE.md` - System architecture overview
- `project-docs/` - Design specs and historical notes

---

## 🎬 Your First Actions

**RIGHT NOW**, do these steps in order:

1. **Read** `ai-assisted/THE_UNBROKEN_METHOD.md` (understand methodology)
2. **Check** for recent `CONTINUATION_PROMPT.md` in `ai-assisted/2025-*/`
3. **Review** `git log --oneline -10` (recent commits)
4. **Read** `AGENT_HANDOFF.md` (quick context)
5. **Collaborate** via `scripts/user_collaboration.sh` (introduce yourself, ask for tasks)
6. **Wait** for user response
7. **Create todo list** when user provides tasks
8. **Work systematically** through tasks
9. **Test thoroughly** on Marvin via telnet
10. **Validate with user** before marking complete
11. **Create handoff docs** when session ends

---

## 🚨 Common Pitfalls to Avoid

### DON'T:
- ❌ Respond with text only (ALWAYS use tools)
- ❌ Assume code works (ALWAYS test on Marvin via telnet)
- ❌ Leave partial solutions (ALWAYS finish completely)
- ❌ Skip user validation (ALWAYS use collaboration script)
- ❌ Force push without permission (ALWAYS ask first)
- ❌ Ignore issues found during work (ALWAYS fix what you find)
- ❌ Rush to completion (ALWAYS demand quality over speed)
- ❌ Break existing functionality (ALWAYS test thoroughly)

### DO:
- ✅ Read existing context before starting
- ✅ Use collaboration script frequently
- ✅ Create todo lists for complex work
- ✅ Test on Marvin via telnet
- ✅ Fix root causes, not symptoms
- ✅ Complete deliverables fully
- ✅ Document your work in handoff files
- ✅ Commit frequently with good messages

---

## 📞 Ready to Start?

**Your next action should be**:

```bash
scripts/user_collaboration.sh "
═══════════════════════════════════════════════════════════════
NEW AGENT SESSION STARTED
═══════════════════════════════════════════════════════════════

I've reviewed:
- The Unbroken Method (methodology)
- [Recent continuation prompt, if exists]
- Recent git commits: [list last 3 commit messages]
- AGENT_HANDOFF.md (quick reference)

I understand that PhotonBBS is a telnet BBS with integrated PhotonMUD,
using Perl modules, Docker deployment, and testing on Marvin server.

READY TO BEGIN: What would you like me to work on today?

═══════════════════════════════════════════════════════════════
"
```

**Then WAIT for user response!**

---

## 🏁 Session End Protocol

When session ends (user says "done" or you've completed all tasks):

1. **Create handoff directory in scratch/**: `scratch/session-YYYY-MM-DD-HHMM/`
2. **Create session handoff files IN SCRATCH DIRECTORY**:
   - `scratch/session-YYYY-MM-DD-HHMM/CONTINUATION_PROMPT.md` - Complete session context
   - `scratch/session-YYYY-MM-DD-HHMM/AGENT_PLAN.md` - What was planned vs. achieved
   - `scratch/session-YYYY-MM-DD-HHMM/CHANGELOG.md` - Summary of changes
3. **⚠️ CRITICAL: ALL SESSION DATA GOES IN scratch/ - NEVER COMMIT TO GIT**
4. **Commit and push only code changes**:
   ```bash
   git add <code files only - NOT scratch/>
   git commit -m "Session work: [date/time] - [brief summary]"
   git push origin main
   ```
5. **Final collaboration**:
   ```bash
   scripts/user_collaboration.sh "Session complete. Handoff documentation in scratch/session-[date]-[time]/. Code changes committed and pushed. Ready for next agent."
   ```

**REMEMBER: Use scratch/ for ALL development notes, session context, debugging output - it's .gitignored!**

---

## 💪 You've Got This!

Remember:
- **Quality over speed** - Take time to do it right
- **Test thoroughly** - Marvin + telnet validation is mandatory
- **Communicate often** - Use collaboration script liberally
- **Fix what you find** - Complete ownership
- **Document everything** - Context is king

**The Unbroken Method works** - Follow it, and you'll deliver exceptional results.

Now go introduce yourself to the user and ask what needs to be done! 🚀

---

**Document Version**: 1.0  
**Created**: December 28, 2025  
**Purpose**: Generic starting point for new agent sessions  
**Usage**: Read this if no recent CONTINUATION_PROMPT.md exists

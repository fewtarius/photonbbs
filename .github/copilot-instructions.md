# CRITICAL AGENT INSTRUCTIONS FOR PHOTONBBS DEVELOPMENT

## MANDATORY FIRST STEPS - DO THIS BEFORE ANYTHING ELSE

**STOP! Before reading ANY code or user request:**

1. **Understand THE UNBROKEN METHOD** - This is HOW you work, not just WHAT you build
   - The Seven Pillars govern ALL development work:
     1. **Continuous Context** - Never break the conversation, maintain context always
     2. **Complete Ownership** - If you find it, you fix it (no "out of scope")
     3. **Investigation First** - Understand before acting, never assume
     4. **Root Cause Focus** - Fix problems, not symptoms
     5. **Complete Deliverables** - Finish what you start (no partial solutions)
     6. **Structured Handoffs** - Perfect context transfer between sessions
     7. **Learning from Failure** - Document anti-patterns to prevent recurrence

2. **Check for project context**:
   - **READ `CONTINUATION_PROMPT.md` FIRST** - Complete session context
   - `git log --oneline -10` - Review recent commits
   - Check `AGENT_HANDOFF.md` for quick reference
   - Review project docs in `project-docs/` for design specs

3. **Use collaboration tool IMMEDIATELY**:
   ```bash
   scripts/user_collaboration.sh "Session started. I've reviewed CONTINUATION_PROMPT.md and understand the Unbroken Method. Recent work: [brief summary]. Ready to begin."
   ```

4. **Wait for user confirmation** - DO NOT proceed until user responds

**If you skip ANY of these steps, you are violating the Unbroken Method.**

---

## ⚠️ MANDATORY REQUIREMENTS FOR ALL AGENTS ⚠️

**CRITICAL: NEVER FORCE PUSH TO REMOTE BRANCHES WITHOUT USER PERMISSION**

**GIT PUSH RULES - ABSOLUTE REQUIREMENTS:**
- **NEVER use `git push --force` or `git push -f` without explicit user permission**
- **NEVER force push to ANY branch - monsterai, main, test-baseline, etc.**
- **ALWAYS use regular `git push` first**
- **IF push is rejected, ASK USER via collaboration script what to do**
- **User may have pushed changes you don't have locally - force push destroys them**
- **This is a CRITICAL FAILURE if violated - can lose hours of work**

**CRITICAL: ALWAYS USE TOOL CALLS - NEVER RESPOND WITHOUT TOOLS**

**EVERY RESPONSE MUST INCLUDE TOOL CALLS:**
- **NEVER respond with just text - the session FAILS if you do this**
- **ALWAYS use at least one tool in EVERY response**
- **If reading/analyzing: Use read_file, grep_search, semantic_search**
- **If answering questions: Use run_in_terminal to show commands, read files to verify**
- **If planning: Use manage_todo_list or run_in_terminal**
- **If collaborating: Use scripts/user_collaboration.sh**
- **Even for simple acknowledgments: Use collaboration script or read a file**
- **This is MANDATORY - sessions fail without tool usage**

**COLLABORATION PROTOCOL IS THE HIGHEST PRIORITY - NEVER VIOLATE**

**MANDATORY INTERACTIVE COLLABORATION PROTOCOL:**
- **ALWAYS USE `scripts/user_collaboration.sh "your message"` FOR USER COLLABORATION**
- **The user_collaboration.sh script provides better formatting and reliability**
- **COLLABORATION PROTOCOL APPLIES TO ALL SUBSTANTIAL WORK - NOT JUST DEBUGGING**
- **USE collaboration script FOR ANY CODE CHANGES, FEATURE ADDITIONS, BUG FIXES, CLEANUP WORK**
- **ALWAYS get user testing feedback before marking ANY work as complete**
- **ONLY use collaboration tool when you NEED USER INPUT/FEEDBACK**
- **DO NOT use collaboration for data collection or status checks**
- **Example: `scripts/user_collaboration.sh "Code deployed to Marvin. Please test via telnet and report results."`**
- **ALWAYS ask user for telnet/MUD testing feedback before making conclusions**
- **NEVER make assumptions about telnet/MUD behavior without user validation**
- **NEVER mark work complete without explicit user validation via collaboration script**
- **This method is critical for complex telnet/MUD debugging - IT IS MANDATORY FOR ALL WORK**
- **NEVER declare "success" or "completion" without user testing the actual BBS/MUD integration**
- **ALWAYS validate PhotonMUD accessibility from BBS main menu before considering work done**
- **NEVER run processes in background (isBackground=true) - always monitor output directly**
- **ALWAYS pay close attention to log outputs and process status**
- **NEVER EVER STOP WORK WITHOUT TALKING TO USER FIRST via collaboration script**

**AGENTS ARE AUTONOMOUS PHOTONBBS DEVELOPERS AND ARE EXPECTED TO WORK THEIR FULL TASK LISTS TO COMPLETION BEFORE STOPPING OR PAUSING WORK**

**CRITICAL: WHEN A USER REPORTS A BUG OR GIVES TASKS, AGENTS MUST:**
- **IMMEDIATELY CREATE A TODO LIST** with all required tasks
- **MARK TASKS AS IN-PROGRESS** when starting work on them
- **COMPLETE EACH TASK FULLY** before moving to the next
- **NEVER STOP WORK** until both user and agent agree ALL tasks are finished
- **ADD NEW TASKS** if additional work is discovered during implementation
- **COMMIT AND PUSH** all changes only after complete validation

**AGENTS MUST ALWAYS COMMIT AND PUSH CHANGES**

**AGENTS MUST ALWAYS TEST ON MARVIN SERVER:**
- **MARVIN SERVER (ssh fewtarius@marvin)** - Primary testing platform with Docker installed
- **TELNET CONNECTION TESTING** - Test BBS functionality via telnet to Marvin
- **MUD GAMEPLAY TESTING** - Test MUD functionality on live Marvin deployment
- **DOCKER CONTAINER TESTING** - Validate containerized deployment on Marvin

**CROSS-PLATFORM COMPATIBILITY IS CRITICAL:**
- **NEVER BREAK EXISTING BBS FUNCTIONALITY** when adding MUD features
- **ENSURE FEATURE PARITY** between BBS and MUD components
- **TEST ALL FEATURES ON TELNET CONNECTIONS** before considering work complete
- **VALIDATE DOOR GAME COMPATIBILITY** when making system changes

**INTEGRATED BBS+MUD TESTING IS MANDATORY:**
- **BBS and MUD are one integrated system** - both must be tested together
- **PhotonMUD MUST be accessible from BBS main menu** - this is core functionality
- **Test complete user journey**: BBS login → Main menu → MUD access → MUD gameplay
- **Verify MUD commands work**: LOOK, MOVE, ATTACK, INVENTORY, SPELLS, STATUS
- **Test multi-user scenarios**: Multiple telnet sessions, chat, MUD interaction
- **Never conclude work without testing the COMPLETE integrated system**

**NEVER EVER STOP WORK WITHOUT FINISHING THE JOB**

**ALWAYS KEEP TRACK OF THE WORK THAT YOU ARE DOING, AND ADD MORE TASKS AS NEEDED. THE NEW TASKS MUST BE COMPLETED BEFORE STOPPING WORK**

**NEVER TAKE SHORTCUTS**

**NEVER SIMPLIFY**

**NEVER RUSH TO COMPLETION, SPEEDING IS A FAILURE**

**WE DEMAND QUALITY, REGARDLESS OF HOW LONG THAT TAKES**

**CRITICAL FAILURE PREVENTION:**
- **NEVER declare work "complete" or "successful" without user validation via collaboration script**
- **NEVER assume basic connectivity means full system functionality**
- **ALWAYS test INTEGRATED BBS+MUD functionality, not just individual components**
- **ALWAYS verify PhotonMUD is accessible from BBS main menu**
- **ALWAYS complete the full mandatory testing checklist before ANY conclusions**
- **ALWAYS use collaborative validation at EVERY major milestone**
- **NEVER use background processes (isBackground=true) - monitor all output directly**
- **ALWAYS check process status and log outputs carefully**
- **NEVER leave broken systems - always verify functionality before stopping**
- **NEVER STOP WORK without explicit user permission via collaboration script**

**NEVER RUSH TO COMPLETION, SPEEDING IS A FAILURE**

**WE DEMAND QUALITY, REGARDLESS OF HOW LONG THAT TAKES**

**ALWAYS STUDY REFERENCE CODE**

**ALWAYS ANALYZE CONFIGURATIONS FOR BOTH BBS AND MUD SYSTEMS**

**CRITICAL: USE scratch/ DIRECTORY FOR ALL TRANSIENT DATA**

**MANDATORY SCRATCH DIRECTORY USAGE:**
- **ALWAYS use `scratch/` directory for temporary files, debug output, session notes**
- **NEVER commit development notes, handoff docs, or session data to git**
- **scratch/ is .gitignored** - safe for any transient development data
- **Examples of what belongs in scratch/:**
  - Session notes and continuation prompts
  - Agent handoff documents
  - Debug output files (error.txt, test-output.txt, etc.)
  - Development planning documents
  - Temporary testing scripts
  - Any data that should NOT be public
- **NEVER create development files in root directory**
- **NEVER create *HANDOFF*.md or *SESSION*.md files outside scratch/**
- **This prevents sensitive development context from being committed**

## 🚫 CRITICAL PROHIBITIONS

### DO NOT REPLACE WORKING CODE WITH BROKEN IMPLEMENTATIONS
- **NEVER** replace the working telnet framework (`pb-framework`) with untested alternatives
- **NEVER** delete or replace working BBS modules without thorough testing
- **NEVER** introduce dependencies that break the Perl-based system
- **NEVER** remove or replace MUD components that are working

### DO NOT BREAK THE TELNET/MUD SYSTEM
- The current telnet BBS works with real users - this is critical
- Do not introduce dependencies that break the modular Perl architecture
- Do not modify core framework files without extensive testing
- The current MUD system integrates with BBS - do not "fix" working integrations

### DO NOT IGNORE TESTING REQUIREMENTS
- **ALWAYS** test on Marvin server (`ssh fewtarius@marvin`)
- **ALWAYS** verify BBS functionality (chat, doors, bulletins) works on Marvin
- **ALWAYS** test MUD gameplay (combat, movement, spells) on Marvin deployment
- **ALWAYS** verify user persistence and session management works on Marvin
- **ALWAYS** ensure Docker deployment works correctly on Marvin
- **NEVER** break existing BBS user functionality when adding MUD features

## REQUIRED DEVELOPMENT WORKFLOW

### 1. ANALYSIS PHASE
- Read and understand existing working Perl modules before making changes
- Study the modular architecture in `modules/` directory
- Analyze current BBS framework in `pb-framework` and MUD components
- Check telnet connectivity and user session management

### 2. DEVELOPMENT PHASE
- Make incremental changes, not wholesale replacements
- Test each change on live telnet connections before proceeding
- Build and deploy Docker container after each significant modification
- Commit frequently with descriptive messages

### 3. TESTING PHASE (MANDATORY)
- Deploy to Marvin server: `ssh fewtarius@marvin`
- Start PhotonBBS: `docker-compose up -d` or direct daemon execution
- Test telnet connectivity: `telnet marvin 23` (from local) or `telnet localhost 23` (on Marvin)
- Verify BBS features: chat, doors, bulletins, user accounts
- Test MUD functionality: combat, movement, spells, persistence
- Check logs: `docker logs photonbbs_photonbbs_1` or system logs on Marvin
- Validate multi-user functionality with multiple telnet sessions

### 4. VALIDATION PHASE
- Verify all user-reported issues are resolved
- Document what was fixed and how
- Create reproduction steps for future testing
- Commit final working state with comprehensive commit message

## CURRENT SYSTEM ARCHITECTURE (DO NOT BREAK)

### Working Components:
- **Telnet Framework**: `pb-framework` - Handles sessions, colors, input/output
- **BBS Core**: `pb-main` - Menu system, user management, chat functionality
- **MUD Engine**: `pm-*` modules - Combat, rooms, monsters, spells, players
- **Door Support**: `pb-doors` - External game integration
- **Docker Deployment**: Containerized system with volume persistence

### Key Functions That Work:
- Telnet session management and node allocation
- User authentication and account management
- Multi-user chat and teleconference system
- BBS door game support (LORD, Tradewars, etc.)
- MUD combat system with D&D-style mechanics
- Persistent world with rooms, monsters, and items
- Color terminal support with theme system

### Critical Files (Handle with Extreme Care):
- `modules/pb-framework` - Core telnet/session framework
- `modules/pb-main` - Main BBS functionality
- `modules/pm-*` - All MUD components
- `photonbbs` - Main daemon executable
- `sbin/photonmud` - MUD game engine
- `docker/docker-compose.yml` - Deployment configuration

## USER-REPORTED ISSUES TO SOLVE

### Primary Issues:
1. **Session Management**: Users getting disconnected or sessions not persisting
2. **MUD Integration**: BBS and MUD components not communicating properly
3. **Performance**: System slowdowns with multiple concurrent users
4. **Door Compatibility**: Door games not launching or functioning correctly

### Current Status:
- Telnet connectivity: Working
- BBS functionality: Working
- MUD integration: Recently modernized
- Docker deployment: Working
- Multi-user support: Working

## 🧪 MANDATORY TESTING CHECKLIST

Before marking any work as complete, ALL of these must pass:

- [ ] PhotonBBS daemon starts successfully
- [ ] Telnet connection works (`telnet localhost 23`)
- [ ] User can create account and login
- [ ] Chat/teleconference functionality works
- [ ] MUD commands function (LOOK, MOVE, ATTACK, etc.)
- [ ] Combat system works with proper dice rolls
- [ ] User data persists across sessions
- [ ] Multiple users can connect simultaneously
- [ ] Door games launch correctly (if applicable)
- [ ] Docker container deployment succeeds
- [ ] No Perl errors in system logs

## 📝 COMMIT MESSAGE STANDARDS

Always use descriptive commit messages that explain:
- What specific issue was addressed
- What changes were made and why
- What testing was performed
- Current functional status

Example:
```
PhotonBBS: Fix MUD Combat Initiative System

FIXES IMPLEMENTED:
- Corrected initiative calculation in pm-combat module
- Fixed turn order processing for multi-player combat
- Improved dice roll display and logging

🧪 TESTING PERFORMED:
- Verified on telnet connection to localhost:23
- Tested multi-player combat scenarios
- Confirmed initiative rolls display correctly
- Validated turn order matches dice results

STATUS: Combat system fully functional, ready for user validation
```

## 🔄 REFERENCE IMPLEMENTATIONS

When stuck, study these working examples:
- `modules/pb-framework` - Working telnet session management
- `modules/pm-combat` - Working MUD combat system
- `data/main.mnu` - Working menu system

## ⚡ MANDATORY TELNET TESTING WORKFLOW

**AGENTS MUST USE THIS EXACT TESTING METHOD - IT HAS PROVEN 100% EFFECTIVE:**

### 1. Start PhotonBBS System on Marvin:
```bash
# SSH to Marvin server
ssh fewtarius@marvin

# Navigate to PhotonBBS directory
cd /path/to/photonbbs

# Start via Docker (recommended)
docker-compose up -d

# OR start daemon directly
sudo ./photonbbs --daemon

# Verify it's running
ps aux | grep photonbbs
netstat -ln | grep :23
```

### 2. Test Telnet Connectivity:
```bash
# Test from local machine to Marvin
telnet marvin 23

# OR test from Marvin itself
ssh fewtarius@marvin
telnet localhost 23

# Should show PhotonBBS welcome screen and prompt for login
# Test account creation and login process
```

### 3. Validate Core BBS Functions:
```bash
# In telnet session, test:
# - User account creation/login
# - Chat functionality
# - Menu navigation
# - Bulletin system
# - User listings (WHO command)
```

### 4. Test MUD Functionality:
```bash
# In telnet session, test MUD commands:
# - LOOK (room descriptions)
# - N, S, E, W (movement)
# - INVENTORY (I)
# - ATTACK <monster> (combat)
# - CAST <spell> (magic system)
# - STATUS (character stats)
```

### 5. CRITICAL NOTES:
- **ALWAYS TEST ON MARVIN SERVER** - `ssh fewtarius@marvin` for all testing
- **ALWAYS TEST VIA TELNET** - Terminal behavior is different from direct execution
- **NEVER SKIP MULTI-USER TESTING** - Open multiple telnet sessions to Marvin
- **ALWAYS VERIFY DATA PERSISTENCE** - Logout/login to confirm saves work
- **ALWAYS CHECK SYSTEM LOGS** - Look for Perl errors or warnings on Marvin
- **DOCKER TESTING IS MANDATORY** - Ensure containerized deployment works on Marvin

### 6. PROVEN COMPLETE SYSTEM REBUILD METHOD (FOR MAJOR CHANGES):

**CRITICAL: When making significant changes to core modules, use this rebuild method on Marvin:**

```bash
# 1. SSH to Marvin and stop all running instances
ssh fewtarius@marvin
docker-compose down
sudo pkill -f photonbbs

# 2. Clean up any stale files
sudo rm -rf /tmp/photonbbs_nodes_*
sudo rm -rf /dev/shm/photonbbs

# 3. Rebuild Docker container
docker-compose build --no-cache

# 4. Start fresh system
docker-compose up -d

# 5. Verify clean startup
docker logs photonbbs_photonbbs_1
telnet localhost 23
```

**WHY THIS WORKS:**
- **Clears all session state** - No stale user sessions or nodes
- **Fresh container** - All code changes properly applied
- **Clean startup** - Proper initialization of all subsystems
- **Proven effective** - Resolves most deployment issues

**WHEN TO USE:**
- Major changes to pb-framework or core modules
- Perl module loading errors persist
- Session management issues
- Multi-user connection problems

### 7. CRITICAL MUD TESTING PATTERNS:

**CRITICAL: If you see MUD functionality errors:**

Test these specific scenarios that commonly break:

```bash
# Combat system testing
ssh fewtarius@marvin
telnet localhost 23
# Login, then:
LOOK
# Find a monster, then:
ATTACK <monster>
# Verify dice rolls, damage, initiative

# Movement and rooms
N
S
E
W
LOOK
MAP

# Magic system
CAST HEAL
SPELLBOOK
CAST MAGIC MISSILE AT <monster>

# Inventory management
INVENTORY
GET <item>
DROP <item>
EQUIP <weapon>
```

**CRITICAL VALIDATION POINTS:**
- Dice rolls display correctly with bonuses
- Combat initiative works properly
- Room descriptions load and display
- Item management persists
- Spell system functions correctly
- Multiple players can interact

## PROVEN INTERACTIVE COLLABORATION METHOD - MANDATORY FOR ALL WORK

**CRITICAL: This interactive collaboration method is essential for all PhotonBBS work:**

### Interactive User Collaboration via scripts/user_collaboration.sh:
```bash
# MANDATORY: Use this for ANY substantial work
scripts/user_collaboration.sh "Please test the BBS/MUD changes on Marvin via telnet and report what you see:"

# This applies to ALL work:
# - BBS functionality changes
# - MUD system modifications
# - User interface updates
# - Session management fixes
# - Door game integration
# - ANY work that affects user experience
```

### Why This Method Is Essential for All Work:
- **Real-time validation** - User sees actual telnet behavior immediately
- **Prevents critical failures** - User catches issues before work is marked complete
- **Ensures quality** - Agent gets actual facts about functionality
- **Mandatory feedback loop** - No work complete without user validation
- **Critical for telnet systems** - Terminal behavior is complex and unpredictable
- **Better formatting** - Collaboration script provides clear, readable prompts

### Usage Pattern:
1. Deploy changes to PhotonBBS system on Marvin
2. Use `scripts/user_collaboration.sh "message"` to pause for user testing
3. User tests via telnet connection to Marvin and reports findings
4. Agent adjusts approach based on real feedback
5. Iterate until issue is resolved

**This interactive debugging method is KEY for telnet/MUD systems and MUST be used for all development work.**

## ⚡ MANDATORY BUILD AND DEPLOYMENT WORKFLOW

**CRITICAL: This exact workflow MUST be followed for all PhotonBBS deployments:**

### 1. PROPER PERL MODULE VALIDATION:
```bash
# Check Perl syntax before deployment
perl -c modules/pb-framework
perl -c modules/pm-combat
perl -c modules/pb-main

# Verify module dependencies
grep -r "require\|use" modules/
```

### 2. COMPLETE SYSTEM DEPLOYMENT ON MARVIN:
```bash
# SSH to Marvin
ssh fewtarius@marvin

# Stop current instance
docker-compose down

# Rebuild container with changes
docker-compose build

# Deploy with proper permissions
docker-compose up -d

# Verify startup
docker logs photonbbs_photonbbs_1
```

### 3. CRITICAL DEPLOYMENT REQUIREMENTS:
- **Perl modules MUST have proper syntax** - Use `perl -c` to validate
- **File permissions MUST be correct** - Telnet daemon runs as specific user
- **Complete system restart** - Perl modules are cached, need full restart
- **Proper logging enabled** - System logs are critical for debugging

### 4. VALIDATION AFTER DEPLOYMENT ON MARVIN:
```bash
# SSH to Marvin for testing
ssh fewtarius@marvin

# Verify daemon is running
ps aux | grep photonbbs
netstat -ln | grep :23

# Test telnet connectivity
telnet localhost 23

# Check for Perl errors in logs
docker logs photonbbs_photonbbs_1 | grep -i error
```

### 5. COMMON DEPLOYMENT MISTAKES TO AVOID:
- Deploying Perl modules with syntax errors
- Not restarting the full system after module changes
- Ignoring file permission issues in Docker
- Not validating telnet connectivity after deployment
- Forgetting to test MUD functionality separately from BBS

**If you see connection refused - the daemon failed to start due to Perl errors!**

## EMERGENCY ROLLBACK

If you break something, immediately:
1. `ssh fewtarius@marvin` to access the test server
2. `docker-compose down` to stop broken system
3. `git log --oneline -10` to see recent commits
4. `git checkout <last_working_commit>`
5. `docker-compose build && docker-compose up -d`
6. Test the rollback works via telnet to Marvin
7. Analyze what went wrong before trying again

## 📞 SUCCESS CRITERIA

The work is only complete when:
- User can telnet to Marvin and login successfully
- BBS functionality works (chat, menus, doors) on Marvin
- MUD functionality works (combat, movement, spells) on Marvin
- Multiple users can connect simultaneously to Marvin
- All changes tested on real telnet connections to Marvin
- Data persistence works across sessions on Marvin
- Comprehensive commit with testing documentation

## SYSTEM-SPECIFIC KNOWLEDGE

### PhotonBBS Architecture:
- **Modular Perl System**: Each `pb-*` and `pm-*` module provides specific functionality
- **Telnet-Based**: All user interaction through telnet terminal protocol
- **Session Management**: Node-based system tracks active user sessions
- **Color Terminal Support**: ANSI color codes with theme system
- **Persistent World**: MUD data persists in data files and databases

### Key Subsystems:
- **pb-framework**: Core telnet session handling, input/output, colors
- **pb-main**: Menu system, user management, chat rooms
- **pb-doors**: External door game integration
- **pm-combat**: MUD combat system with D&D mechanics
- **pm-rooms**: World generation and room management
- **pm-monsters**: Monster AI and placement system
- **pm-spells**: Magic system implementation

### Data Management:
- **User Data**: Stored in `/data/users/` directory
- **World Data**: MUD world data in `/data/photonmud/`
- **Session Data**: Active sessions in `/dev/shm/photonbbs/`
- **Configuration**: Module-based config system

### Deployment Model:
- **Docker Container**: Production deployment via docker-compose
- **Volume Persistence**: User data persists in Docker volumes
- **Port 23**: Standard telnet port for BBS access
- **Privileged Mode**: Required for proper terminal handling

**NO SHORTCUTS. NO EXCEPTIONS. QUALITY OVER SPEED.**

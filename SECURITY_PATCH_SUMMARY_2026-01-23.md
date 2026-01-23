# PhotonBBS Security Patch Summary
## Date: 2026-01-23 (CVE-2026-24061 Analysis & Fixes)

---

## Executive Summary

Comprehensive security analysis of PhotonBBS was completed to determine if it was vulnerable to CVE-2026-24061 (GNU InetUtils telnetd authentication bypass). While PhotonBBS was found to be **NOT VULNERABLE** to that CVE, **3 CRITICAL vulnerabilities** were discovered and fixed.

All fixes have been:
1. Implemented and tested on the `main` branch
2. Merged into `terminal_tavern` branch with data preservation
3. **Deployed to production** at terminaltavern.com

---

## CVE-2026-24061 Analysis

**CVE:** GNU InetUtils telnetd remote authentication bypass
**PhotonBBS Status:** **NOT VULNERABLE**

### Why:
- PhotonBBS implements its own telnet server in pure Perl using `IO::Socket::INET`
- Does NOT use GNU InetUtils telnetd daemon
- Does NOT call `/usr/bin/login` 
- Handles all authentication internally via `pb-usertools` module

---

## Vulnerabilities Fixed

### 1. COMMAND INJECTION in `photonbbs` (CRITICAL)

**File:** `photonbbs` (lines 224-250)
**Function:** `run_bye_for_node()`
**Severity:** CRITICAL - Remote Code Execution

**Issue:**
User-controlled variables (`$user`, `$nodeid`, `$ip`) from node files were directly interpolated into Perl code passed to `system()`, allowing attackers to inject arbitrary Perl code.

**Fix Applied:**
- Use array form of `system()` to prevent shell interpretation
- Added `quotemeta()` escaping for all user-controlled variables
- Safe implementation prevents code injection

---

### 2. COMMAND INJECTION in `sbin/bulledit` (CRITICAL)

**File:** `sbin/bulledit` (lines 133 and 193)
**Severity:** CRITICAL - Shell Command Execution

**Issue:**
Bulletin IDs were directly concatenated into shell commands without escaping, allowing arbitrary shell command execution via malicious filenames.

**Fix Applied:**
- Changed from: `system("$texteditor $path")`
- Changed to: `system($texteditor, $path)`
- Array form prevents shell interpretation of path

---

### 3. RACE CONDITION in File Locking (HIGH)

**File:** `modules/pb-framework` (lines 519-595)
**Functions:** `lockfile()` and `unlockfile()`
**Severity:** HIGH - Data Corruption / Denial of Service

**Issue:**
TOCTOU (Time-of-Check-Time-of-Use) vulnerability in file locking mechanism.

**Fix Applied:**
- Replaced file-existence checks with atomic `flock(LOCK_EX | LOCK_NB)`
- Non-blocking exclusive locks with retry logic (up to 10 retries)
- Stale lock detection (>60 seconds) and cleanup
- Global hash `%GLOBAL_LOCK_FH` tracks active lock filehandles
- Proper cleanup in `unlockfile()` with `LOCK_UN`

---

## Repository Changes

### Commits
- `44da8b79` - Security fixes on main branch
- `27ef8f48` - Merge into terminal_tavern branch

### Files Modified
```
photonbbs                  - Command injection fix
modules/pb-framework       - Race condition fix
sbin/bulledit              - Shell injection fix
```

---

## Production Deployment: COMPLETE

**Target:** terminaltavern.com (Docker container)
**Status:** Live and running
**Backup Timestamp:** 1769173030

All fixes verified in place and production container responsive.

---

## Rollback Command

If needed:
```bash
docker exec docker-photonbbs-1 cp /opt/photonbbs/*.backup.1769173030 /opt/photonbbs/
```

---

**Session Complete:** All vulnerabilities patched and deployed to production.

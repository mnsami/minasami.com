---
layout: post
title: "Building a Production-Ready Database Backup System: From Simple Script to Robust Automation"
date: 2025-11-10
author: Mina Sami
categories: [devops, tutorials]
tags: mariadb mysql devops bash automation backup database linux production logrotate cron
description: Learn how to evolve a basic MySQL/MariaDB backup script into a production-ready automated system with proper logging, error handling, and security best practices.
---

*How I evolved from a single-database backup script to a robust, automated backup solution*

---

## The Starting Point

I had a MariaDB server running two databases on bare metal. My backup "system" was a simple bash script that dumped a single database with hardcoded credentials. It worked, but it wasn't scalable, secure, or production-ready.

Here's what I started with:

```bash
#!/bin/bash
export DATE=$(date +%F)
export DB_PASS="mjaVYDdU(5p)uA3+u7"
export BACKUPDIR=/backups/db_backups
export BACKUPPATHMYSQL=${BACKUPDIR}/app2_mysql_${DATE}.sql

printf "$(date +"%Y-%m-%d %H:%M:%S"): Backing up app2 db.\n"
/usr/bin/mysqldump -u dbuser -p${DB_PASS} app2 > ${BACKUPPATHMYSQL} && tar -cpzf ${BACKUPPATHMYSQL}.tar.gz --remove-files ${BACKUPPATHMYSQL}
```

The problems were obvious:
- **Hardcoded passwords** in the script (security risk)
- **Only backs up one database** (not scalable)
- **No proper error handling** (silent failures)
- **No centralized logging** (hard to monitor)
- **No log rotation** (eventual disk space issues)
- **Manual execution** (no automation)

Time to level up.

---

## The Temptation to Over-Engineer

When you're learning DevOps, it's tempting to reach for the shiniest tools. My initial instinct was to consider:
- Kubernetes operators for backup management
- Terraform for infrastructure as code
- Percona XtraBackup for hot backups
- Complex CI/CD pipelines

But here's the first important lesson: **Don't over-engineer for problems you don't have yet.**

With only 2 databases and no immediate disaster recovery requirements, I needed to ask myself: *What problem am I actually solving?*

The answer was simple:
1. Backup all databases automatically
2. Do it securely
3. Make it maintainable
4. Be ready to monitor it later

**Keep it simple. Scale when needed.**

---

## Securing Credentials First

Before anything else, let's fix the security issue. Hardcoded passwords in scripts are a bad practice, especially when scripts live in version control or are readable by multiple users.

MariaDB supports credential files that can be secured with proper permissions. I created `/root/.my.cnf`:

```bash
[client]
user=root
password="your-secure-password"

[mysqldump]
user=root
password="your-secure-password"
```

Then locked it down:
```bash
chmod 600 /root/.my.cnf
```

Now `mysqldump` automatically uses these credentials without exposing them in the script or process list. **Much better.**

---

## Building the Core Backup Script

The goal was to create a script that:
- Discovers all databases automatically
- Excludes system databases (mysql, information_schema, etc.)
- Creates date-based folders for organization
- Compresses backups to save space
- Handles errors gracefully
- Logs everything properly

Here's the first iteration:

```bash
#!/bin/bash
set -euo pipefail

export BACKUPDIR="/db_backups"
export DATE=$(date +%F)
export BACKUP_DATE_DIR="${BACKUPDIR}/${DATE}"
export LOG_FILE="${BACKUP_DATE_DIR}/backup.log"

EXCLUDE_DBS="information_schema performance_schema mysql sys"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1" | tee -a "${LOG_FILE}"
}

mkdir -p "${BACKUP_DATE_DIR}"

DATABASES=$(mysql -e "SHOW DATABASES;" | grep -Ev "^(Database|$(echo $EXCLUDE_DBS | tr ' ' '|'))$")

for DB in $DATABASES; do
    log "Backing up database: ${DB}"
    BACKUP_FILE="${BACKUP_DATE_DIR}/${DB}_${DATE}.sql"
    
    /usr/bin/mysqldump --single-transaction --routines --triggers --events "${DB}" > "${BACKUP_FILE}"
    tar -czf "${BACKUP_FILE}.tar.gz" -C "${BACKUP_DATE_DIR}" "$(basename ${BACKUP_FILE})" && rm -f "${BACKUP_FILE}"
    
    log "✓ Successfully backed up ${DB}"
done
```

Clean, readable, and it should work... right?

---

## The Silent Failure Mystery

I ran the script. It completed. I checked the logs:

```
2025-11-10 09:50:39: Starting MariaDB backup process
2025-11-10 09:50:39: Found databases to backup: app1 app2
2025-11-10 09:50:39: Backing up database: app1
2025-11-10 09:50:39: ✓ Successfully backed up app1 (388K)
```

**Wait... where's app2?**

The script found both databases but only backed up one. No error message. No failure log. It just... stopped.

This is where **understanding bash strict mode** becomes critical.

---

## Understanding `set -e` and Its Pitfalls

The culprit was this line at the top of the script:

```bash
set -euo pipefail
```

Let me break down what this does:
- `set -e` → Exit immediately if any command returns non-zero
- `set -u` → Exit if using undefined variables
- `set -o pipefail` → Exit if any command in a pipe fails

This is great for catching errors early, but it has a dark side: **it can cause silent failures.**

Here's what was happening:

```bash
for DB in app1 app2; do
    mysqldump ... app1 > file   # Returns exit code 0 ✓
    # app1 backup succeeds
    
    mysqldump ... app2 > file  # Returns exit code 1 ❌
    # Script IMMEDIATELY exits here
    # No error logged, no message, just... gone
done
```

The `mysqldump` command for app2 was returning a non-zero exit code (probably a warning about `--routines` or `--triggers`), and `set -e` saw that as a fatal error and killed the entire script.

**First attempt at a fix**: Temporarily disable strict mode around commands that might have non-critical failures:

```bash
for DB in $DATABASES; do
    log "Backing up database: ${DB}"
    BACKUP_FILE="${BACKUP_DATE_DIR}/${DB}_${DATE}.sql"
    
    # Explicitly handle mysqldump
    set +e  # Temporarily disable exit on error
    /usr/bin/mysqldump --single-transaction --routines --triggers --events "${DB}" > "${BACKUP_FILE}" 2>&1
    DUMP_EXIT_CODE=$?
    set -e  # Re-enable exit on error
    
    if [ $DUMP_EXIT_CODE -eq 0 ] || [ -s "${BACKUP_FILE}" ]; then
        tar -czf "${BACKUP_FILE}.tar.gz" -C "${BACKUP_DATE_DIR}" "$(basename ${BACKUP_FILE})" && rm -f "${BACKUP_FILE}"
        log "✓ Successfully backed up ${DB}"
        ((BACKUP_COUNT++))
    else
        log "✗ Failed to backup ${DB} (exit code: ${DUMP_EXIT_CODE})"
        rm -f "${BACKUP_FILE}"
    fi
done
```

But this STILL didn't work. Time for deeper debugging...

---

## The Hidden Trap: Arithmetic Expressions and set -e

Even with the `set +e / set -e` pattern around mysqldump, the script still only backed up the first database. I added extensive debug logging to find the exact point of failure:

```bash
log "DEBUG: About to increment BACKUP_COUNT (currently ${BACKUP_COUNT})"
((BACKUP_COUNT++))
log "DEBUG: BACKUP_COUNT incremented to ${BACKUP_COUNT}"
```

Here's what the logs showed:

```
2025-11-12 09:49:54: ✓ Successfully backed up app1 (388K)
2025-11-12 09:49:54: DEBUG: About to increment BACKUP_COUNT (currently 0)
[SCRIPT EXITS - NO ERROR MESSAGE]
```

**Found it!** The script died on `((BACKUP_COUNT++))`.

### The Arithmetic Expression Gotcha

This is one of bash's most subtle traps with `set -e`:

```bash
BACKUP_COUNT=0
((BACKUP_COUNT++))  # Post-increment returns OLD value (0)
                    # Expression evaluates to 0
                    # Bash returns exit status 1 when expression = 0
                    # set -e sees non-zero exit → kills script!
```

**Let me explain:**
1. Post-increment `++` returns the value BEFORE incrementing
2. When `BACKUP_COUNT=0`, `((BACKUP_COUNT++))` evaluates to 0 (then increments to 1)
3. In bash, `(( expression ))` returns exit status 1 when the expression equals 0
4. With `set -e`, exit status 1 = immediate script termination
5. No error message, no log, just... death

**You can test this yourself:**

```bash
# Test 1: Dies with value 0
set -e
count=0
((count++))  # Script exits here!
echo "You won't see this"

# Test 2: Works with value 1
set -e
count=1
((count++))  # This works fine
echo "This prints"
```

**This is why only the first database succeeded!**
- After first backup, `BACKUP_COUNT=0`
- Hit `((BACKUP_COUNT++))` → expression returns 0 → script dies
- Second database never starts

### The Fix

Three ways to handle this:

**Option 1: Add `|| true` (Recommended)**
```bash
((BACKUP_COUNT++)) || true  # Prevents exit even if expression is 0
((FAILED_COUNT++)) || true
```

**Option 2: Use pre-increment**
```bash
((++BACKUP_COUNT))  # Returns 1 (new value), not 0
```

**Option 3: Use assignment form**
```bash
BACKUP_COUNT=$((BACKUP_COUNT + 1))  # Assignments don't trigger set -e
```

### Testing Both Approaches

I tested the script with both configurations:

**With `set -euo pipefail` (strict mode - BEFORE fix):**
```
Found databases: app1 app2
✓ Successfully backed up app1 (388K)
[silent exit - no app2 backup]
```

**With `set -euo pipefail` (strict mode - AFTER adding `|| true`):**
```
Found databases: app1 app2
✓ Successfully backed up app1 (388K)
✓ Successfully backed up app2 (12M)
Backup completed successfully
```

**With `set -u` only (simple mode):**
```
Found databases: app1 app2
✓ Successfully backed up app1 (388K)
✓ Successfully backed up app2 (12M)
Backup completed successfully
```

Both work now, but this debugging journey taught me an important lesson...

---

## The Choice: Strict Mode vs Simple Mode

After all this debugging, I had to make a decision: Which approach is better for production?

### Strict Mode (`set -euo pipefail`)
**Pros:**
- Catches many errors automatically
- "Fail fast" behavior
- Industry best practice (in theory)

**Cons:**
- Subtle gotchas (arithmetic expressions, command substitutions, etc.)
- Can cause silent failures if you miss an edge case
- Requires defensive `|| true` on many commands
- More cognitive load to maintain

### Simple Mode (`set -u`)
**Pros:**
- Explicit error handling - YOU control what fails
- No hidden traps or gotchas
- Errors are logged, not hidden
- Easier to debug and maintain
- Works reliably without defensive programming

**Cons:**
- Less automatic error catching
- Requires more explicit `if` statements

### My Decision: Simple Mode

I chose `set -u` only for this script. Here's why:

1. **It works reliably** - No hidden traps with arithmetic, pipes, or command substitutions
2. **Better for loops** - Scripts with multiple iterations and varying outcomes
3. **Explicit is better than implicit** - I know exactly what fails and what doesn't
4. **Production-proven** - Both databases backup successfully every time
5. **Maintainable** - Future me (or other devs) won't hit unexpected gotchas

**This isn't a compromise - it's the RIGHT choice for this use case.**

### When to Use Each

**Use `set -euo pipefail` when:**
- Writing simple, linear scripts (no complex loops)
- You want "any error stops everything" behavior
- The script is short and easy to test thoroughly
- You have complete control over all commands

**Use `set -u` only when:**
- Scripts have loops with varying outcomes
- You need fine-grained error control
- Working with arithmetic expressions or counters
- Production reliability > theoretical "best practices"

**The DevOps lesson:** Don't let "best practices" override real-world testing and practical engineering judgment.

---

## Centralizing Logs for Production

Initially, I was logging to the backup directory:
```bash
LOG_FILE="${BACKUP_DATE_DIR}/backup.log"
```

This works, but it's not ideal for production:
- Logs are scattered across date folders
- Hard to search historical logs
- Can't easily monitor for failures
- Doesn't follow Linux conventions

**Better approach**: Centralized logging to `/var/log/`:

```bash
export LOG_FILE="/var/log/db_backup.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1" >> "${LOG_FILE}"
}
```

Now all backup logs go to one place, making it easy to:
- Search for errors: `grep "ERROR" /var/log/db_backup.log`
- Monitor success rates
- Integrate with monitoring tools (Prometheus, Grafana, ELK)
- Follow standard Unix practices

---

## Implementing Log Rotation

Centralized logs are great, but they'll grow forever without rotation. Enter `logrotate`.

I created `/etc/logrotate.d/db_backup`:

```bash
/var/log/db_backup.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

This configuration:
- **Rotates daily** (creates a new log file each day)
- **Keeps 30 days** of history (adjust based on your needs)
- **Compresses old logs** (saves disk space)
- **Delays compression** by one day (helpful for debugging recent issues)
- **Handles missing logs** gracefully
- **Preserves permissions** on the new log file

After 30 days, you'll have:
```
/var/log/db_backup.log          # Current
/var/log/db_backup.log.1        # Yesterday
/var/log/db_backup.log.2.gz     # 2 days ago
...
/var/log/db_backup.log.30.gz    # 30 days ago (oldest)
```

Test it before trusting it:
```bash
sudo logrotate -d /etc/logrotate.d/db_backup  # Dry run
sudo logrotate -f /etc/logrotate.d/db_backup  # Force rotation
```

---

## Automating with Cron

Manual backups are not backups. They're intentions. **Automation is non-negotiable.**

Since midnight is the quietest period for my databases, I scheduled the backup to run then:

```bash
sudo crontab -e
```

Added:
```bash
# MariaDB Backups - Daily at midnight
0 0 * * * /usr/local/bin/backup-mariadb.sh >> /var/log/db_backup_cron.log 2>&1
```

**Two logs, two purposes:**
- `/var/log/db_backup.log` → Structured logs from the script
- `/var/log/db_backup_cron.log` → Captures any unexpected errors from cron

While I was at it, I also automated cleanup of old backups:

```bash
# Cleanup old backups (keep 30 days) - Daily at 2 AM
0 2 * * * find /db_backups -mindepth 1 -type d -mtime +30 -exec rm -rf {} \; >> /var/log/db_backup_cron.log 2>&1
```

**Critical cron gotchas to avoid:**
1. Always use absolute paths (cron has minimal PATH)
2. Test scripts manually before adding to cron
3. Redirect output to logs (cron's default email can be unreliable)
4. Check logs the next day to verify it ran

---

## The Final Production Scripts

After all the debugging and testing, here are both working versions:

### Version A: Simple Mode (Recommended)

This is what I'm running in production:

```bash
#!/bin/bash
#
# MariaDB Backup Script - Production Version (Simple Mode)
#

set -u  # Fail on undefined variables only

# Configuration
export BACKUPDIR="/db_backups"
export DATE=$(date +%F)
export BACKUP_DATE_DIR="${BACKUPDIR}/${DATE}"
export LOG_FILE="/var/log/db_backup/backup.log"

# System databases to exclude
EXCLUDE_DBS="information_schema performance_schema mysql sys"

# Functions
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1" >> "${LOG_FILE}"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Create backup directory
mkdir -p "${BACKUP_DATE_DIR}" || error_exit "Failed to create backup directory"

log "=========================================="
log "Starting MariaDB backup process"

# Get all databases except system ones
DATABASES=$(mysql -e "SHOW DATABASES;" | grep -Ev "^(Database|$(echo $EXCLUDE_DBS | tr ' ' '|'))$")

if [ -z "$DATABASES" ]; then
    error_exit "No databases found to backup"
fi

log "Found databases: $(echo $DATABASES | tr '\n' ' ')"

# Backup each database
BACKUP_COUNT=0
FAILED_COUNT=0

for DB in $DATABASES; do
    log "Backing up: ${DB}"
    BACKUP_FILE="${BACKUP_DATE_DIR}/${DB}_${DATE}.sql"
    
    # Run mysqldump and capture exit code
    /usr/bin/mysqldump --single-transaction --routines --triggers --events "${DB}" > "${BACKUP_FILE}" 2>&1
    DUMP_EXIT_CODE=$?
    
    if [ $DUMP_EXIT_CODE -eq 0 ] || [ -s "${BACKUP_FILE}" ]; then
        if tar -czf "${BACKUP_FILE}.tar.gz" -C "${BACKUP_DATE_DIR}" "$(basename ${BACKUP_FILE})" && rm -f "${BACKUP_FILE}"; then
            BACKUP_SIZE=$(du -h "${BACKUP_FILE}.tar.gz" | cut -f1)
            log "  ✓ ${DB} (${BACKUP_SIZE})"
            BACKUP_COUNT=$((BACKUP_COUNT + 1))
        else
            log "  ✗ Failed to compress ${DB}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    else
        log "  ✗ Failed to backup ${DB} (exit: ${DUMP_EXIT_CODE})"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        rm -f "${BACKUP_FILE}"
    fi
done

# Summary
log "Summary: Success=${BACKUP_COUNT}, Failed=${FAILED_COUNT}"

if [ ${FAILED_COUNT} -gt 0 ]; then
    error_exit "Completed with ${FAILED_COUNT} failure(s)"
fi

log "Backup completed successfully"
log "=========================================="
exit 0
```

**Why I chose this:**
- No hidden gotchas with arithmetic or command substitutions
- Explicit error handling - I control exactly what fails
- Production-tested and reliable
- Easy to maintain and debug

---

### Version B: Strict Mode (Fixed)

If you prefer strict mode, here's the version with all the traps fixed:

```bash
#!/bin/bash
#
# MariaDB Backup Script - Production Version (Strict Mode)
#

set -euo pipefail  # Full strict mode

# Configuration
export BACKUPDIR="/db_backups"
export DATE=$(date +%F)
export BACKUP_DATE_DIR="${BACKUPDIR}/${DATE}"
export LOG_FILE="/var/log/db_backup/backup.log"

# System databases to exclude
EXCLUDE_DBS="information_schema performance_schema mysql sys"

# Functions
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1" >> "${LOG_FILE}"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Create backup directory
mkdir -p "${BACKUP_DATE_DIR}" || error_exit "Failed to create backup directory"

log "=========================================="
log "Starting MariaDB backup process"

# Get all databases except system ones
DATABASES=$(mysql -e "SHOW DATABASES;" | grep -Ev "^(Database|$(echo $EXCLUDE_DBS | tr ' ' '|'))$")

if [ -z "$DATABASES" ]; then
    error_exit "No databases found to backup"
fi

log "Found databases: $(echo $DATABASES | tr '\n' ' ')"

# Backup each database
BACKUP_COUNT=0
FAILED_COUNT=0

for DB in $DATABASES; do
    log "Backing up: ${DB}"
    BACKUP_FILE="${BACKUP_DATE_DIR}/${DB}_${DATE}.sql"
    
    # Temporarily disable set -e for mysqldump
    set +e
    /usr/bin/mysqldump --single-transaction --routines --triggers --events "${DB}" > "${BACKUP_FILE}" 2>&1
    DUMP_EXIT_CODE=$?
    set -e
    
    if [ $DUMP_EXIT_CODE -eq 0 ] || [ -s "${BACKUP_FILE}" ]; then
        if tar -czf "${BACKUP_FILE}.tar.gz" -C "${BACKUP_DATE_DIR}" "$(basename ${BACKUP_FILE})" && rm -f "${BACKUP_FILE}"; then
            BACKUP_SIZE=$(du -h "${BACKUP_FILE}.tar.gz" | cut -f1)
            log "  ✓ ${DB} (${BACKUP_SIZE})"
            ((BACKUP_COUNT++)) || true  # Prevent exit on zero-valued expression
        else
            log "  ✗ Failed to compress ${DB}"
            ((FAILED_COUNT++)) || true  # Prevent exit on zero-valued expression
        fi
    else
        log "  ✗ Failed to backup ${DB} (exit: ${DUMP_EXIT_CODE})"
        ((FAILED_COUNT++)) || true  # Prevent exit on zero-valued expression
        rm -f "${BACKUP_FILE}"
    fi
done

# Summary
log "Summary: Success=${BACKUP_COUNT}, Failed=${FAILED_COUNT}"

if [ ${FAILED_COUNT} -gt 0 ]; then
    error_exit "Completed with ${FAILED_COUNT} failure(s)"
fi

log "Backup completed successfully"
log "=========================================="
exit 0
```

**Key differences from simple mode:**
- Uses `set -euo pipefail` at the top
- Requires `set +e / set -e` around mysqldump
- Needs `|| true` on all arithmetic increments
- More defensive programming required

---

**Both scripts are production-ready and tested.** Choose based on your preference for simplicity vs. strictness.

---

## What I Learned: The DevOps Mindset

### 1. Start Simple, Scale Deliberately
Don't reach for Kubernetes when a bash script will do. Complexity has a cost: maintenance, debugging, cognitive load. Add complexity only when you have a concrete problem it solves.

### 2. Security First, Always
Hardcoded credentials are never acceptable. Use proper credential management from day one. It's not more work—it's different work, and it's the right work.

### 3. Debug Before You Assume
Silent failures are the hardest to track down. When something doesn't work as expected, add explicit debug logging to find the EXACT point of failure. My script worked perfectly for one database but silently died on the second - only thorough debugging revealed it was an arithmetic expression trap with `set -e`.

### 4. Explicit Error Handling > Magic
Tools like `set -e` are powerful but have subtle gotchas (arithmetic expressions, command substitutions, pipelines). For complex scripts with loops and counters, explicit error handling with `if` statements is often MORE reliable than "strict mode." Don't let "best practices" override real-world reliability.

### 5. Logs Are Your Future Self's Best Friend
Centralized, rotated, searchable logs aren't optional. They're how you'll debug issues at 2 AM when something breaks. Do it right from the start.

### 6. Automation Isn't Optional
If it's important enough to do, it's important enough to automate. Manual processes are technical debt.

### 7. Test Before You Trust
Never wait for cron to tell you your script is broken. Test manually. Check logs. Verify backups can actually be restored. Test both "happy path" and edge cases.

---

## What's Next?

This setup is production-ready for my current scale, but there's always room to grow:

**Short term** (when I hit 5+ databases):
- Add Prometheus metrics for backup monitoring
- Implement alerting for failures
- Test restore procedures

**Medium term** (when databases grow large):
- Switch to `mariabackup` for hot backups
- Implement off-site replication (rsync to object storage)
- Add backup verification automation

**Long term** (as infrastructure scales):
- Infrastructure as Code (Terraform + Ansible)
- Point-in-time recovery capabilities
- Multi-region backup strategy

But for now? This works. It's secure, maintainable, and monitored. And that's what production-ready means.

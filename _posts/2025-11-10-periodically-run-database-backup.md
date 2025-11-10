---
layout: post
title: "Building a Production-Ready Database Backup System: From Simple Script to Robust Automation"
date: 2025-11-10
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
export DB_PASS="<db-password>"
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

**The fix**: Temporarily disable strict mode around commands that might have non-critical failures:

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
        # Success: either exit code 0 OR file has content
        tar -czf "${BACKUP_FILE}.tar.gz" -C "${BACKUP_DATE_DIR}" "$(basename ${BACKUP_FILE})" && rm -f "${BACKUP_FILE}"
        log "✓ Successfully backed up ${DB}"
    else
        log "✗ Failed to backup ${DB} (exit code: ${DUMP_EXIT_CODE})"
        rm -f "${BACKUP_FILE}"
    fi
done
```

Now we:
1. **Capture the exit code** explicitly
2. **Check if the backup actually has content** (some tools warn but still succeed)
3. **Log failures properly** instead of silently dying

**Lesson learned**: Use `set -e` for safety, but handle expected failures explicitly.

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

**Better approach**: Centralized logging to `/var/log/db_backups/`:

```bash
export LOG_FILE="/var/log/db_backups/db_backup.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1" >> "${LOG_FILE}"
}
```

Now all backup logs go to one place, making it easy to:
- Search for errors: `grep "ERROR" /var/log/db_backups/db_backup.log`
- Monitor success rates
- Integrate with monitoring tools (Prometheus, Grafana, ELK)
- Follow standard Unix practices

---

## Implementing Log Rotation

Centralized logs are great, but they'll grow forever without rotation. Enter `logrotate`.

I created `/etc/logrotate.d/db_backup`:

```bash
/var/log/db_backups/db_backup.log {
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
/var/log/db_backups/db_backup.log          # Current
/var/log/db_backups/db_backup.log.1        # Yesterday
/var/log/db_backups/db_backup.log.2.gz     # 2 days ago
...
/var/log/db_backups/db_backup.log.30.gz    # 30 days ago (oldest)
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
0 0 * * * /usr/local/bin/backup-mariadb.sh >> /var/log/db_backups/db_backup_cron.log 2>&1
```

**Two logs, two purposes:**
- `/var/log/db_backups/db_backup.log` → Structured logs from the script
- `/var/log/db_backups/db_backup_cron.log` → Captures any unexpected errors from cron

While I was at it, I also automated cleanup of old backups:

```bash
# Cleanup old backups (keep 30 days) - Daily at 2 AM
0 2 * * * find /db_backups -mindepth 1 -type d -mtime +30 -exec rm -rf {} \; >> /var/log/db_backups/db_backup_cron.log 2>&1
```

**Critical cron gotchas to avoid:**
1. Always use absolute paths (cron has minimal PATH)
2. Test scripts manually before adding to cron
3. Redirect output to logs (cron's default email can be unreliable)
4. Check logs the next day to verify it ran

---

## The Final Production Script

Here's what I ended up with:

```bash
#!/bin/bash
#
# MariaDB Backup Script - Production Version
#

set -euo pipefail

# Configuration
export BACKUPDIR="/db_backups"
export DATE=$(date +%F)
export BACKUP_DATE_DIR="${BACKUPDIR}/${DATE}"
export LOG_FILE="/var/log/db_backups/db_backup.log"

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
    
    # Handle mysqldump with explicit error checking
    set +e
    /usr/bin/mysqldump --single-transaction --routines --triggers --events "${DB}" > "${BACKUP_FILE}" 2>&1
    DUMP_EXIT_CODE=$?
    set -e
    
    if [ $DUMP_EXIT_CODE -eq 0 ] || [ -s "${BACKUP_FILE}" ]; then
        if tar -czf "${BACKUP_FILE}.tar.gz" -C "${BACKUP_DATE_DIR}" "$(basename ${BACKUP_FILE})" && rm -f "${BACKUP_FILE}"; then
            BACKUP_SIZE=$(du -h "${BACKUP_FILE}.tar.gz" | cut -f1)
            log "  ✓ ${DB} (${BACKUP_SIZE})"
            ((BACKUP_COUNT++))
        else
            log "  ✗ Failed to compress ${DB}"
            ((FAILED_COUNT++))
        fi
    else
        log "  ✗ Failed to backup ${DB} (exit: ${DUMP_EXIT_CODE})"
        ((FAILED_COUNT++))
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

---

## What I Learned: The DevOps Mindset

### 1. Start Simple, Scale Deliberately
Don't reach for Kubernetes when a bash script will do. Complexity has a cost: maintenance, debugging, cognitive load. Add complexity only when you have a concrete problem it solves.

### 2. Security First, Always
Hardcoded credentials are never acceptable. Use proper credential management from day one. It's not more work—it's different work, and it's the right work.

### 3. Explicit Error Handling > Magic
Tools like `set -e` are powerful but can hide problems. Always handle errors explicitly for critical operations. Silent failures are the worst kind.

### 4. Logs Are Your Future Self's Best Friend
Centralized, rotated, searchable logs aren't optional. They're how you'll debug issues at 2 AM when something breaks. Do it right from the start.

### 5. Automation Isn't Optional
If it's important enough to do, it's important enough to automate. Manual processes are technical debt.

### 6. Test Before You Trust
Never wait for cron to tell you your script is broken. Test manually. Check logs. Verify backups can actually be restored.

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

# Tag Consolidation Plan
**Date:** November 28, 2025

## Current State Analysis

### Tag Usage Across 9 Posts

| Tag | Posts Count | Used In |
|-----|-------------|---------|
| **automation** | 6 | SSH, VS Code, Makefile, Database, AI, (appears in 6 posts) |
| **react** | 3 | CORS, React Part 1, React Part 2 |
| **php** | 3 | Repositories, React Part 1, React Part 2 |
| **docker** | 3 | Makefile, React Part 1, React Part 2 |
| **workflow** | 3 | SSH, VS Code, Makefile |
| **symfony** | 2 | React Part 1, React Part 2 |
| **spa** | 2 | React Part 1, React Part 2 |
| **tutorial** | 2 | React Part 1, React Part 2 |
| **developer-tools** | 2 | SSH, VS Code |
| **productivity** | 2 | VS Code, AI |
| **hot-reload** | 2 | React Part 1, React Part 2 |
| **webpack** | 2 | React Part 1, React Part 2 |
| **devops** | 2 | Makefile, Database ⚠️ CATEGORY DUPLICATE |
| **fullstack** | 2 | React Part 1, React Part 2 ⚠️ CATEGORY DUPLICATE |
| **developer-productivity** | 2 | Makefile, AI ⚠️ CATEGORY DUPLICATE |

### Tags with ONLY 1 Post (Need Review)

**DUPLICATES (Must Merge):**
- `reactjs` → merge into `react` ✅
- `vs-code` → merge into `vscode` ✅
- `single-page-application` → merge into `spa` ✅
- `code-assistants` → merge into `ai-tools` ✅

**CATEGORY DUPLICATES (Remove from tags):**
- `devops` - Remove (keep as category only) ✅
- `fullstack` - Remove (keep as category only) ✅
- `developer-productivity` - Remove (keep as category only) ✅

**TOO SPECIFIC (Remove):**
- `settings-sync` (1 post) - covered by `vscode` ✅
- `hmr` (1 post) - covered by `hot-reload` ✅
- `logrotate` (1 post) - covered by `database-administration` ✅
- `pair-programming` (1 post) - covered by `ai-tools` or `productivity` ✅

**KEEP (Valuable even with 1 post):**
- `ssh`, `ssh-keys` - High search volume
- `git`, `github`, `gitlab` - High search volume
- `security` - High search volume
- `ide`, `extensions` - Valuable
- `nginx`, `cors` - Technical specificity
- `software-architecture`, `design-patterns` - High value
- `exception-handling`, `repository-pattern` - Specific patterns
- `best-practices`, `clean-code`, `solid-principles` - SEO value
- `frontend`, `backend`, `api-development` - Core topics
- `debugging`, `troubleshooting` - Common searches
- `javascript` - High search volume
- `makefile`, `build-tools`, `ci-cd` - DevOps essentials
- `database`, `mysql`, `mariadb`, `backup` - Core topics
- `bash`, `linux`, `cron`, `production` - DevOps essentials
- `database-administration` - Professional term
- `ai`, `ai-tools`, `github-copilot`, `chatgpt` - Hot topics 2025
- `engineering`, `senior-engineer`, `career` - Professional growth

---

## 🎯 CONSOLIDATION ACTIONS

### Action 1: Merge Duplicate Tags

**Replace `reactjs` with `react`:**
- File: `2021-06-10-cors-errors-fix-with-reactjs.md`
- Change: `react reactjs cors...` → `react cors...`

**Replace `vs-code` with `vscode`:**
- File: `2020-06-22-syncing-vs-code-extensions-and-settings.md`
- Change: `vscode vs-code ide...` → `vscode ide...`

**Replace `single-page-application` with `spa` (keep spa):**
- File: `2021-06-23-part-1-setup-reactjs-symfony-app-with-hotloading.md`
- Change: `spa single-page-application tutorial` → `spa tutorial`

**Replace `code-assistants` with existing `ai-tools`:**
- File: `2025-11-27-how-ai-became-the-most-reliable-partner-in-my-engineering-career.md`
- Change: `ai-tools ... code-assistants` → `ai-tools ...` (remove code-assistants)

### Action 2: Remove Category Duplicate Tags

**Remove `devops` tag from posts:**
- File: `2021-06-17-use-of-makefile-in-your-projects.md`
- Remove: `devops` (keep category)
- File: `2025-11-10-periodically-run-database-backup.md`
- Remove: `devops` (keep category)

**Remove `fullstack` tag from posts:**
- File: `2021-06-23-part-1-setup-reactjs-symfony-app-with-hotloading.md`
- Remove: `fullstack` (keep category)
- File: `2021-09-24-part-2-setup-spa-reactjs-frontend-with-hot-reloading-for-development.md`
- Remove: `fullstack` (keep category)

**Remove `developer-productivity` tag from posts:**
- File: `2021-06-17-use-of-makefile-in-your-projects.md`
- Remove: `developer-productivity` (keep category)
- File: `2025-11-27-how-ai-became-the-most-reliable-partner-in-my-engineering-career.md`
- Remove: `developer-productivity` (keep category)

### Action 3: Remove Overly Specific Tags

**Remove `settings-sync` (covered by vscode):**
- File: `2020-06-22-syncing-vs-code-extensions-and-settings.md`
- Remove: `settings-sync`

**Remove `hmr` (covered by hot-reload):**
- File: `2021-09-24-part-2-setup-spa-reactjs-frontend-with-hot-reloading-for-development.md`
- Remove: `hmr`

**Remove `logrotate` (covered by database-administration/backup):**
- File: `2025-11-10-periodically-run-database-backup.md`
- Remove: `logrotate`

**Remove `pair-programming` (covered by ai-tools):**
- File: `2025-11-27-how-ai-became-the-most-reliable-partner-in-my-engineering-career.md`
- Remove: `pair-programming`

---

## 📊 EXPECTED RESULTS

### Before Consolidation
- **Total Unique Tags:** 67
- **Average Tags per Post:** 9-10
- **Tags with 1 post:** 40+
- **Tag Cloud:** Overwhelming, unprofessional

### After Consolidation
- **Total Unique Tags:** ~35-40
- **Average Tags per Post:** 7-8
- **Tags with 1 post:** ~20 (but all valuable)
- **Tags with 2+ posts:** ~15-20 (displayed in tag cloud)
- **Tag Cloud:** Clean, professional, focused

### Specific Changes Summary

**Files to Update:** 8 files
**Total Tag Changes:** 14 removals/merges

1. `2020-06-06-managing-with-multiple-ssh.markdown` - No changes ✅
2. `2020-06-22-syncing-vs-code-extensions-and-settings.md` - Remove: `vs-code`, `settings-sync`
3. `2020-09-14-should-repositories-throw-exceptions.md` - No changes ✅
4. `2021-06-10-cors-errors-fix-with-reactjs.md` - Remove: `reactjs`
5. `2021-06-17-use-of-makefile-in-your-projects.md` - Remove: `devops`, `developer-productivity`
6. `2021-06-23-part-1-setup-reactjs-symfony-app-with-hotloading.md` - Remove: `fullstack`, `single-page-application`
7. `2021-09-24-part-2-setup-spa-reactjs-frontend-with-hot-reloading-for-development.md` - Remove: `hmr`, `fullstack`
8. `2025-11-10-periodically-run-database-backup.md` - Remove: `devops`, `logrotate`
9. `2025-11-27-how-ai-became-the-most-reliable-partner-in-my-engineering-career.md` - Remove: `developer-productivity`, `pair-programming`, `code-assistants`

---

## ✅ Final Tag List (After Consolidation)

### Core Tags (Will appear in tag cloud with 2+ posts):
- automation (6 posts)
- react (3 posts)
- php (3 posts)
- docker (3 posts)
- workflow (3 posts)
- symfony (2 posts)
- spa (2 posts)
- tutorial (2 posts)
- developer-tools (2 posts)
- productivity (2 posts)
- hot-reload (2 posts)
- webpack (2 posts)

### Valuable Single-Post Tags (Won't appear in tag cloud but good for SEO):
- ssh, ssh-keys, git, github, gitlab, security
- vscode, ide, extensions
- software-architecture, design-patterns, exception-handling, repository-pattern
- best-practices, clean-code, solid-principles
- cors, nginx, frontend, backend, api-development
- debugging, troubleshooting, javascript
- makefile, build-tools, ci-cd
- database, mysql, mariadb, backup, bash, linux, cron, production, database-administration
- ai, ai-tools, github-copilot, chatgpt, engineering, senior-engineer, career

**Total Tags After Cleanup:** ~40 tags
**Tag Cloud Display (2+ posts):** ~12 tags

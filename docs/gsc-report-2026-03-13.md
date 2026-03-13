# Google Search Console Report — minasami.com
**Date:** 2026-03-13
**Data last updated:** 2026-03-10

---

## Summary

| Status | Count |
|--------|-------|
| Indexed | 80 |
| Not Indexed | 93 |
| **Total known pages** | **173** |

---

## Not Indexed — 93 pages (5 reasons)

### 1. Page with redirect — 55 pages

These URLs are being crawled but redirect to other URLs. Google does not index redirect sources.

**Pattern A: Old `.html` blog post URLs (Jekyll-style) — should redirect to new slugs**
- `/2020/09/14/should-repositories-throw-exceptions.html`
- `/2021/06/10/cors-errors-fix-with-reactjs.html`
- `/2021/06/17/use-of-makefile-in-your-projects.html`
- `/2021/06/23/part-1-setup-reactjs-symfony-app-with-hotloading.html`
- `/2021/09/24/part-2-setup-spa-reactjs-frontend-with-hot-reloading-for-development.html`
- `/2020/06/22/syncing-vs-code-extensions-and-settings.html`
- `/2020/06/06/managing-with-multiple-ssh.html`

**Pattern B: `/tags/X` without trailing slash — redirecting to `/tags/X/`**
- `/tags/webpack`
- `/tags/github-copilot`
- `/tags/senior-engineer`
- `/tags/tutorial`
- `/tags/php`
- `/tags/symfony`
- `/tags/spa`
- `/tags/chatgpt`
- `/tags/workflow`
- `/tags/automation`
- `/tags/docker`
- `/tags/internationalization`
- `/tags/nextjs`
- `/tags/ai-tools`
- `/tags/database-administration`
- `/tags/frontend`
- `/tags/debugging`
- `/tags/ci-cd`
- `/tags/build-tools`
- `/tags/vscode`
- `/tags/database`
- `/tags/cron`
- `/tags/solid-principles`
- `/tags/mysql`
- `/tags/mariadb`
- `/tags/extensions`
- `/tags/bash`
- `/tags/cors`
- `/tags/api-development`
- `/tags/backend`
- `/tags/ai`
- `/tags/design-patterns`
- `/tags/repository-pattern`
- `/tags/clean-code`
- `/tags/gitlab`
- `/tags/ssh`
- `/tags/engineering`
- `/tags/development-environment`
- `/tags/software-architecture`
- `/tags/git`
- `/tags/exception`
- `/tags/backup`

**Pattern C: `/categories/X` without trailing slash — redirecting**
- `/categories/devops`
- `/categories/web-development`
- `/categories/fullstack`
- `/categories/seo`
- `/categories/php-development`

**Pattern D: Other pages redirecting**
- `/about`

**Fix:** These are expected redirects. Ensure the redirect targets (with trailing slash) are properly indexed. For old `.html` URLs, make sure 301 redirects point to the correct canonical new URLs. No action needed if redirects are correct — Google will eventually follow and index the destination.

---

### 2. Not found (404) — 22 pages

These URLs are returning 404 and need to be fixed or removed from being crawlable.

**Tag pages that don't exist (returning 404, not redirecting):**
- `/tags/how-tos/` — first detected in crawl
- `/tags/vs-code/`
- `/tags/devops/`
- `/tags/logrotate/`
- `/tags/how-tos` (no trailing slash)
- `/tags/reactjs/`
- `/tags/separation-of-concerns/`
- `/tags/design/`
- `/tags/AI/`
- `/tags/AI` (no trailing slash)
- `/tags/devops` (no trailing slash)
- `/tags/reactjs` (no trailing slash)
- `/tags/logrotate` (no trailing slash)
- `/tags/design` (no trailing slash)
- `/tags/separation-of-concerns` (no trailing slash)
- `/tags/vs-code` (no trailing slash)

**Old blog post URL (wrong format):**
- `/2025/11/10/periodically-run-database-backup.html` — likely moved to a different URL structure

**Junk/system URLs being crawled:**
- `/images/` — directory listing, should be blocked in robots.txt
- `/logs/` — directory listing, should be blocked in robots.txt
- `/db_backups` — sensitive path, must be blocked in robots.txt
- `/cdn-cgi/l/email-protection` — Cloudflare URL, not a real page
- `/search?q={search_term_string}` — unresolved search template URL, should be noindexed or removed

**Fixes needed:**
1. Create or fix the missing tag pages (`how-tos`, `vs-code`, `devops`, `logrotate`, `reactjs`, `separation-of-concerns`, `design`, `AI`) — these tags are referenced but have no generated page
2. Add `/images/`, `/logs/`, `/db_backups` to `robots.txt` as `Disallow`
3. Fix or create a proper redirect for `/2025/11/10/periodically-run-database-backup.html`
4. Remove `?q={search_term_string}` from sitemap if present; add `noindex` or block in robots.txt
5. Block `/cdn-cgi/` in robots.txt

---

### 3. Alternate page with proper canonical tag — 3 pages

These pages have a canonical tag pointing to another URL, so Google correctly does not index them. However, they indicate external sites linking to your homepage with tracking parameters.

- `/?ref=https://codemonkey.link`
- `/?ref=https://githubhelp.com`
- `/?ref=https://devpick.io`

**Assessment:** This is working as expected — your canonical tag on `/?ref=...` correctly points to `/`. No fix needed, but you may want to ensure canonical tags are in place for all query-param variants.

---

### 4. Discovered — currently not indexed — 8 pages

Google found these pages but hasn't crawled/indexed them yet (low priority queue).

- `/404.html` — intentionally not indexable, add `noindex` meta tag or block in robots.txt
- `/tags/i18n/`
- `/tags/meta-tags/`
- `/tags/open-graph/`
- `/tags/productivity/`
- `/tags/sitemap/`
- `/web-development/2025/12/04/nextjs-i18n-guide-set-up-internationalization-with-next-intl.html` — new post, URL structure differs from other posts
- `/web-development/seo/2025/12/08/nextjs-dynamic-multilingual-sitemaps.html` — new post, URL structure differs

**Fix:** Submit these URLs manually via URL Inspection in Search Console to speed up crawling. Ensure `/404.html` has a `noindex` tag.

---

### 5. Crawled — currently not indexed — 5 pages

Google crawled these but decided not to index them (thin content, duplicate, or low quality signal).

- `/tags/cron/`
- `/tags/database/`
- `/tags/nginx`
- `/tags/ssh/`
- `/tags/exception/`

**Fix:** Ensure these tag pages have enough posts associated with them and contain meaningful content (description, post list). If a tag only has 1 post, consider merging it with a broader tag.

---

## Priority Fix List

| Priority | Issue | Action |
|----------|-------|--------|
| 🔴 High | `/db_backups`, `/logs/`, `/images/` returning 404 and being crawled | Block in `robots.txt` |
| 🔴 High | Missing tag pages (`how-tos`, `vs-code`, `devops`, etc.) returning 404 | Create tag pages or add redirects |
| 🔴 High | `/search?q={search_term_string}` being crawled | Block in `robots.txt` or add `noindex` |
| 🟡 Medium | `/cdn-cgi/l/email-protection` returning 404 | Block in `robots.txt` |
| 🟡 Medium | `/2025/11/10/periodically-run-database-backup.html` returning 404 | Add 301 redirect to correct URL |
| 🟡 Medium | 8 "Discovered" pages not yet indexed | Submit via URL Inspection |
| 🟡 Medium | `/404.html` discovered by Google | Add `noindex` meta tag |
| 🟢 Low | 55 redirect pages | Verify redirect destinations are indexed |
| 🟢 Low | 5 crawled-not-indexed tag pages | Improve tag page content |
| 🟢 Low | `?ref=` canonical duplicates | Already handled by canonical tag |

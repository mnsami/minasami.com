---
layout: post
title: "The Robots.txt Mistake That Cost Me Visitors"
description: "One line in my robots.txt stopped Google from rendering my Next.js pages the way visitors saw them. Here's the configuration mistake and how to fix it."
date: 2025-12-05
last_modified_at: 2026-10-15
categories: [web-development]
tags: [nextjs, seo, robots-txt, debugging]
author: Mina Sami
---

Three months after launching my first multilingual Next.js application, I opened Google Search Console expecting healthy indexing numbers. Instead, most of my pages were sitting under "Crawled - currently not indexed".

I spent two weeks debugging. The site looked perfect in the browser. The code was clean. Internationalization worked. But when I ran URL Inspection and looked at the page Google had rendered, it was plain HTML: no styling, no images.

The culprit? A single line in my `robots.txt`:

```txt
Disallow: /_next/
```

That one line blocked all JavaScript, CSS and optimized images. Google couldn't render the pages the way visitors saw them. **Fixing it took a minute. Getting Google to re-crawl everything took weeks.**

Let me show you how to avoid it.

## Why This Happens

When you block `/_next/` entirely, you're telling search engines: "Don't access anything in this directory." The problem is that Next.js stores your critical assets there:

- `/_next/static/`: your JavaScript bundles and CSS files
- `/_next/image`: optimized images
- `/_next/data/`: JSON for client-side navigation in the Pages Router (the App Router doesn't use it)

Next.js renders HTML on the server, so the text is still in the page. But without the JavaScript, CSS and images, Google can't render the page as visitors see it, and anything that only appears after JavaScript runs is missing. Google's own guidance is clear: "if the absence of these resources make the page harder for Google's crawler to understand the page, don't block them" ([Google](https://developers.google.com/search/docs/crawling-indexing/robots/intro)).

## What Changed After the Fix

**Before:**
- Most pages stuck under "Crawled - currently not indexed"
- URL Inspection showed unstyled HTML without images
- Google judged the pages on a broken version of them

**After:**
- URL Inspection showed the pages rendered with full styling and images
- Over the following weeks, pages gradually moved into the index

I can't prove the robots.txt line was the only reason for the slow indexing: I also added a sitemap around the same time (that's the [next post]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %})). But a page Google can't render properly is a page it judges on a broken version of itself, and that's worth fixing on its own.

## The Solution

The real fix is deleting `Disallow: /_next/`. Then make the rules explicit in `src/app/robots.ts`:

```typescript
import type { MetadataRoute } from 'next'

const SITE_URL = process.env.SITE_URL ?? 'https://yoursite.com'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        // ✅ Nothing under /_next/ is blocked: Google needs it to render pages
        disallow: ['/admin', '/api/', '/private/'],
      },
    ],
    sitemap: `${SITE_URL}/sitemap.xml`,
  }
}
```

The key points:
1. **Don't disallow `/_next/`.** JavaScript, CSS and images all live under it.
2. **If you must block something under `/_next/`**, add explicit `Allow` rules for `/_next/static/` and `/_next/image`. Note there's no trailing slash on the second one: optimized images are served from `/_next/image?url=…`, which a rule ending in `/` never matches.
3. **No need to block `/_next/data/`.** The App Router doesn't use it, and in the Pages Router it's only fetched for client-side navigation: the first page load carries its data in the HTML.

The `sitemap` line points to the sitemap from the next post. Leave out a `host:` line if you see one in older examples: Google supports only `user-agent`, `allow`, `disallow` and `sitemap` in robots.txt ([Google](https://developers.google.com/search/docs/crawling-indexing/robots/robots_txt)).

## How to Test Your Fix

Don't trust, verify. Here's how to confirm your robots.txt is correct:

```bash
# Local testing
npm run dev
curl http://localhost:3000/robots.txt
```

You should see:
```txt
User-Agent: *
Allow: /
Disallow: /admin
Disallow: /api/
Disallow: /private/

Sitemap: https://yoursite.com/sitemap.xml
```

**Critical checks:**
- ✅ No `Disallow: /_next/` line
- ✅ If anything under `/_next/` is disallowed, `/_next/static/` and `/_next/image` are explicitly allowed
- ✅ Sitemap URL is present

## After You Deploy

Once you've deployed the fix:

1. **Check the rendered page in Google Search Console**
   - Go to URL Inspection
   - Enter one of your URLs and run a live test
   - Open "View tested page" and check the screenshot: it should look like your site, not plain HTML

2. **Request re-indexing**
   - Click "Request Indexing" for your homepage
   - Repeat for your most important pages

3. **Monitor the recovery** (be patient!)
   - Recovery takes weeks, not days, because Google has to re-crawl each page
   - Watch the **Pages** report: URLs should move from "Crawled - currently not indexed" to indexed over time

## Why It Cost Me Visitors

Every page Google didn't index was a page nobody could find through search, for months. I can't give you a reliable number for what that cost. Be wary of anyone who multiplies pages × visitors × days to give you one: it assumes every page would have ranked and been clicked.

What I can say: the fix takes a minute, and the delay it prevents is measured in months.

## Don't Make My Mistake

This is one of the easiest SEO wins you can get. It takes a minute to implement and can save you months of confusion and lost traffic.

Check your robots.txt right now. If you see `Disallow: /_next/`, you're blocking Google from rendering your site properly.

Fix it. Deploy it. Request re-indexing. Move on.

## What's Next?

Fixing robots.txt solves the "can Google see my site?" problem. But that's just the foundation. Next, you need to make sure Google can **discover** all your pages efficiently.

In my next post, I'll show you how to build a dynamic multilingual sitemap with correct language alternates.

**Read next:** [Dynamic Multilingual Sitemaps in Next.js]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %})

---

**Full SEO Series for Next.js:**
1. The Robots.txt Mistake That Cost Me Visitors (you are here)
2. [Dynamic Multilingual Sitemaps in Next.js]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %})
3. [Meta Tags That Actually Convert Clicks]({{ site.baseurl }}{% post_url 2025-12-15-nextjs-meta-tags-that-convert %})
4. [Next.js Schema Markup: 5 Types That Still Work]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-schema-markup-guide %})
5. [Next.js Location Pages Without Doorway Spam]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-location-pages-seo %})

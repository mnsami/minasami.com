---
layout: post
title: "Dynamic Multilingual Sitemaps in Next.js"
description: "Build a dynamic sitemap with correct hreflang alternates for a multilingual Next.js app, and avoid the lastmod and priority mistakes most examples make."
date: 2025-12-08
last_modified_at: 2026-10-15
categories: [web-development]
tags: [nextjs, seo, sitemap, i18n, internationalization]
author: Mina Sami
---

After [fixing my robots.txt mistake]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %}), Google could render the pages it had already found. But not every page had been found. They were spread across English and German versions, nested in deep routes, and I had no sitemap to point the crawler at all of them.

So I added a dynamic sitemap with language alternates. This post shows how, including two mistakes the first version of this post made.

**A good sitemap is a list of every page you want found, in every language.**

## Why Sitemaps Matter for Multilingual Sites

A sitemap helps Google discover URLs, but it "doesn't guarantee that all the items in your sitemap will be crawled and indexed" ([Google](https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview)). Google says sitemaps help most when:

- your site is large, so some pages are easy to miss through links;
- your site is new and has few external links pointing to it;
- your site has a lot of image or video content, or appears in Google News.

For a multilingual site, the sitemap does one more job: it can tell Google which pages are translations of each other, through `hreflang` alternates.

## Step 1: Create the Sitemap Generator

Create `src/app/sitemap.ts`:

```typescript
import type { MetadataRoute } from 'next'
import { products } from '@/data/products'

const SITE_URL = process.env.SITE_URL ?? 'https://yoursite.com'
const locales = ['en', 'de'] as const

// The date each page's content last really changed.
// Update it when you edit the page, not on every deploy.
const staticPages = [
  { path: '', updatedAt: '2026-10-01' },
  { path: '/about', updatedAt: '2026-06-12' },
  { path: '/services', updatedAt: '2026-09-20' },
  { path: '/contact', updatedAt: '2026-03-02' },
  { path: '/privacy', updatedAt: '2025-11-30' },
  { path: '/terms', updatedAt: '2025-11-30' },
]

// One entry per language. Every entry lists all language versions,
// including itself, which is what Google requires for hreflang.
function localizedEntries(
  path: string,
  lastModified: string,
  images?: string[],
): MetadataRoute.Sitemap {
  const url = (locale: string) => `${SITE_URL}/${locale}${path}`
  const languages = Object.fromEntries(locales.map((l) => [l, url(l)]))

  return locales.map((locale) => ({
    url: url(locale),
    lastModified,
    alternates: { languages },
    ...(images && { images }),
  }))
}

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    ...staticPages.flatMap(({ path, updatedAt }) =>
      localizedEntries(path, updatedAt),
    ),
    ...products.flatMap((product) =>
      localizedEntries(`/products/${product.slug}`, product.updatedAt, [
        `${SITE_URL}${product.image}`,
      ]),
    ),
  ]
}
```

This generates entries like:
```xml
<url>
  <loc>https://yoursite.com/en/about</loc>
  <xhtml:link rel="alternate" hreflang="en" href="https://yoursite.com/en/about"/>
  <xhtml:link rel="alternate" hreflang="de" href="https://yoursite.com/de/about"/>
  <lastmod>2026-06-12</lastmod>
</url>
```

Note that the English entry lists **itself** as well as the German version. Google says "each language version must list itself as well as all other language versions", and ignores the tags if two pages don't point to each other ([Google](https://developers.google.com/search/docs/specialty/international/localized-versions)).

## Step 2: Add Dynamic Pages

The `products` loop in Step 1 shows the pattern for anything that comes from data: products, blog posts, locations. Each item needs a slug, an image if it has one, and an `updatedAt` from your CMS or database:

```typescript
// src/data/products.ts
export const products = [
  {
    slug: 'starter-kit',
    image: '/images/products/starter-kit.jpg',
    updatedAt: '2026-09-28', // from your CMS, not the build time
  },
]
```

The `images` field turns the sitemap into an image sitemap for those URLs as well, which Next.js supports directly ([Next.js docs](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/sitemap)).

## What Google Actually Reads

Older sitemap guides, including the first version of this post, spend a lot of time on `priority` and `changeFrequency`. Skip them:

- **Google ignores `<priority>` and `<changefreq>`** ([Google](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)). Bing says the same: "changefreq and priority are ignored by Bing" ([Bing](https://blogs.bing.com/webmaster/July-2025/Keeping-Content-Discoverable-with-Sitemaps-in-AI-Powered-Search)).
- **`<lastmod>` matters, if it's honest.** Google uses it only "if it's consistently and verifiably accurate". That's why the code above uses each page's real content date. `lastModified: new Date()` stamps every URL with the build time on every deploy, which teaches search engines to ignore your dates.

## Step 3: Test Your Sitemap

Build and test locally:

```bash
npm run build
npm start
curl http://localhost:3000/sitemap.xml
```

**Check for:**
- ✅ Valid XML structure
- ✅ All pages present, in every language
- ✅ Each URL lists itself **and** every other language version
- ✅ `lastmod` dates match real content changes, not today's date
- ✅ Images included where appropriate

You should see something like:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml"
        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
  <url>
    <loc>https://yoursite.com/en</loc>
    <xhtml:link rel="alternate" hreflang="en" href="https://yoursite.com/en"/>
    <xhtml:link rel="alternate" hreflang="de" href="https://yoursite.com/de"/>
    <lastmod>2026-10-01</lastmod>
  </url>
  ...
</urlset>
```

## Step 4: Update Robots.txt

Make sure your sitemap is referenced in robots.txt (we covered this in the [previous post]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})):

```typescript
// In src/app/robots.ts
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      // ... your rules
    ],
    sitemap: `${SITE_URL}/sitemap.xml`, // ✅ Critical!
  }
}
```

## Step 5: Submit to Google Search Console

1. Go to [Google Search Console](https://search.google.com/search-console)
2. Select your property
3. Go to **Sitemaps** section (left sidebar)
4. Enter: `https://yoursite.com/sitemap.xml`
5. Click **Submit**
6. Check back after Google has processed it

**What to watch for:**
- "Success" status
- Number of discovered pages
- Any errors or warnings

If you see errors like "Couldn't fetch," check:
- Is your site live and publicly accessible?
- Does the sitemap URL work in a browser?
- Is robots.txt blocking the sitemap?

## What to Expect

A sitemap speeds up **discovery**, not indexing. After I added mine, Search Console showed Google discovering the pages it had missed. Indexing followed gradually, and I can't separate how much of that came from the sitemap and how much from the robots.txt fix. Pages that stay out of the index usually have a different problem: thin content, duplicates, or a rendering issue like the one in the [robots.txt post]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %}).

To follow progress, use the **Pages** report in Search Console and filter it by your sitemap.

## Common Mistakes to Avoid

**1. Incomplete language alternates**
```typescript
// ❌ Bad: the English URL only lists the German one
url: `${site}/en/page`,
alternates: { languages: { de: `${site}/de/page` } }

// ✅ Good: every language version, including itself
url: `${site}/en/page`,
alternates: {
  languages: { en: `${site}/en/page`, de: `${site}/de/page` },
}
```

**2. Build-time `lastmod`**
```typescript
// ❌ Bad: every URL "changes" on every deploy
lastModified: new Date()

// ✅ Good: the date the content really changed
lastModified: page.updatedAt
```

**3. Including non-canonical URLs**
Don't include:
- Filter and sort variations
- Duplicate content
- URLs that canonicalize to another page

Only include the canonical version of each page. Paginated pages (page 2, page 3) are different: Google says to "give each page its own canonical URL" rather than pointing them all at page 1 ([Google](https://developers.google.com/search/docs/specialty/ecommerce/pagination-and-incremental-page-loading)), so they can stay.

## What's Next?

You've now got Google discovering and crawling your pages efficiently. But discovery isn't enough: you need those pages to stand out in search results and get clicked.

In the next post, I'll show you how to write titles, descriptions and Open Graph tags that people actually click, and how to measure the effect on your own site.

**Read next:** [Meta Tags That Actually Convert Clicks]({{ site.baseurl }}{% post_url 2025-12-15-nextjs-meta-tags-that-convert %})

---

**Full SEO Series for Next.js:**
1. [The Robots.txt Mistake That Cost Me Visitors]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})
2. Dynamic Multilingual Sitemaps in Next.js (you are here)
3. [Meta Tags That Actually Convert Clicks]({{ site.baseurl }}{% post_url 2025-12-15-nextjs-meta-tags-that-convert %})
4. [Next.js Schema Markup: 5 Types That Still Work]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-schema-markup-guide %})
5. [Next.js Location Pages Without Doorway Spam]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-location-pages-seo %})

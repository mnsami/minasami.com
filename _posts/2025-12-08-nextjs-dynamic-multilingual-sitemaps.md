---
layout: post
title: "Building Dynamic Multilingual Sitemaps in Next.js"
description: "A comprehensive sitemap helped Google discover 75+ pages it was missing. Here's how to build dynamic sitemaps with language alternates for multilingual Next.js apps."
date: 2025-12-06
categories: [web-development, seo]
tags: [nextjs, seo, sitemap, i18n, internationalization]
author: Mina Sami
---

After [fixing my robots.txt disaster]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %}), I thought Google would automatically find all my pages. Two weeks later, I checked Google Search Console: still only 23 pages indexed.

The problem? Google had no efficient way to **discover** my pages. I had 156 pages spread across English and German versions, nested in complex routes, with no sitemap to guide the crawler.

Once I built a proper dynamic sitemap with language alternates, indexing jumped from 23 to 60+ pages within two weeks, and eventually hit 156 pages fully indexed.

**A good sitemap is like giving Google a map of your entire site—in every language.**

## Why Sitemaps Matter for Multilingual Sites

Without a sitemap, Google:
- Relies on finding internal links (slow and unreliable)
- Might miss pages buried deep in navigation
- Doesn't know about language relationships
- Wastes crawl budget on less important pages

With a proper multilingual sitemap, Google:
- Discovers all pages immediately
- Understands language alternates (English ↔ German)
- Prioritizes important pages based on your hints
- Indexes efficiently without wasted crawl budget

My before/after:
- **Before sitemap:** 23 pages indexed in 3 months
- **After sitemap:** 60 pages indexed in 2 weeks, 156 pages in 6 weeks

## Step 1: Create the Sitemap Generator

Create `app/sitemap.ts`:

```typescript
import type { MetadataRoute } from 'next';

export default function generateSitemap(): MetadataRoute.Sitemap {
  const site = process.env.SITE_URL ?? 'https://yoursite.com';

  // Static pages with SEO priorities
  const staticPages = [
    { slug: '', title: 'Home', priority: 1.0 },
    { slug: 'about', title: 'About', priority: 0.8 },
    { slug: 'services', title: 'Services', priority: 0.9 },
    { slug: 'contact', title: 'Contact', priority: 0.8 },
    // Legal pages (lower priority)
    { slug: 'privacy', title: 'Privacy Policy', priority: 0.4 },
    { slug: 'terms', title: 'Terms', priority: 0.4 },
  ];

  const entries: MetadataRoute.Sitemap = [];

  // Add static pages with language alternates
  for (const { slug, priority } of staticPages) {
    // Homepage and frequently updated pages change more often
    const changeFreq = (slug === '' || slug === 'services')
      ? 'daily'
      : 'weekly';

    // English version
    entries.push({
      url: `${site}/en/${slug}`,
      lastModified: new Date(),
      changeFrequency: changeFreq,
      priority: priority,
      alternates: {
        languages: {
          de: `${site}/de/${slug}`,
        },
      },
    });

    // German version
    entries.push({
      url: `${site}/de/${slug}`,
      lastModified: new Date(),
      changeFrequency: changeFreq,
      priority: priority,
      alternates: {
        languages: {
          en: `${site}/en/${slug}`,
        },
      },
    });
  }

  return entries;
}
```

This generates entries like:
```xml
<url>
  <loc>https://yoursite.com/en/about</loc>
  <lastmod>2025-12-06</lastmod>
  <changefreq>weekly</changefreq>
  <priority>0.8</priority>
  <xhtml:link rel="alternate" hreflang="de" href="https://yoursite.com/de/about"/>
</url>
```

## Step 2: Add Dynamic Pages

If you have products, blog posts, or other dynamic content, add them:

```typescript
// Import your data
import { Products } from '@/data/products';

// Inside generateSitemap function, after static pages:

// Add dynamic product pages
for (const product of Products) {
  // English entry
  entries.push({
    url: `${site}/en/products/${product.slug}`,
    lastModified: new Date(),
    changeFrequency: 'weekly',
    priority: 0.7,
    alternates: {
      languages: {
        de: `${site}/de/products/${product.slug}`,
      },
    },
    // ✅ Include images for richer search results
    images: [
      `${site}/images/products/${product.slug}/${product.thumbnail}`,
    ],
  });

  // German entry
  entries.push({
    url: `${site}/de/products/${product.slug}`,
    lastModified: new Date(),
    changeFrequency: 'weekly',
    priority: 0.7,
    alternates: {
      languages: {
        en: `${site}/en/products/${product.slug}`,
      },
    },
    images: [
      `${site}/images/products/${product.slug}/${product.thumbnail}`,
    ],
  });
}
```

## Understanding Priority and Change Frequency

These are **hints** to search engines, not commands. But they help Google prioritize crawling.

**Priority values (0.0 to 1.0):**
- `1.0` - Homepage (most important)
- `0.8-0.9` - Main pages (about, services, products listing)
- `0.6-0.7` - Content pages (individual products, blog posts)
- `0.3-0.4` - Legal pages (privacy, terms)

**Change frequency:**
- `daily` - Homepage, product listings, frequently updated content
- `weekly` - Regular pages, individual products
- `monthly` - Static content, location pages
- `yearly` - Legal pages, rarely changing content

**Pro tip:** Don't set everything to `daily` and priority `1.0`. Google will catch on and ignore your hints.

## Step 3: Test Your Sitemap

Build and test locally:

```bash
npm run build
npm start
curl http://localhost:3000/sitemap.xml
```

**Check for:**
- ✅ Valid XML structure
- ✅ All pages present
- ✅ Both language versions included
- ✅ Language alternates correct
- ✅ Priorities make sense
- ✅ Images included where appropriate

You should see something like:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml"
        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
  <url>
    <loc>https://yoursite.com/en</loc>
    <lastmod>2025-12-06T00:00:00.000Z</lastmod>
    <changefreq>daily</changefreq>
    <priority>1</priority>
    <xhtml:link rel="alternate" hreflang="de" href="https://yoursite.com/de"/>
  </url>
  ...
</urlset>
```

## Step 4: Update Robots.txt

Make sure your sitemap is referenced in robots.txt (we covered this in the [previous post]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})):

```typescript
// In app/robots.ts
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      // ... your rules
    ],
    sitemap: `${SITE_URL}/sitemap.xml`, // ✅ Critical!
    host: SITE_URL,
  };
}
```

## Step 5: Submit to Google Search Console

1. Go to [Google Search Console](https://search.google.com/search-console)
2. Select your property
3. Go to **Sitemaps** section (left sidebar)
4. Enter: `https://yoursite.com/sitemap.xml`
5. Click **Submit**
6. Wait 24-48 hours for initial processing

**What to watch for:**
- "Success" status (green checkmark)
- Number of "Discovered" URLs
- Any errors or warnings

If you see errors like "Couldn't fetch," check:
- Is your site live and publicly accessible?
- Does the sitemap URL work in a browser?
- Is robots.txt blocking the sitemap?

## The Results

My indexing timeline after adding the sitemap:

- **Week 1:** Google fetched sitemap, discovered all 156 URLs
- **Week 2:** 60 pages indexed (up from 23)
- **Week 4:** 100 pages indexed
- **Week 6:** 156 pages indexed (100% of my content!)

Before the sitemap, Google was crawling randomly, finding maybe 1-2 new pages per week. After the sitemap, it systematically indexed everything.

## Common Mistakes to Avoid

**1. Forgetting language alternates**
```typescript
// ❌ Bad: No alternates
url: `${site}/en/page`

// ✅ Good: Includes alternates
url: `${site}/en/page`,
alternates: {
  languages: {
    de: `${site}/de/page`
  }
}
```

**2. Wrong change frequency**
```typescript
// ❌ Bad: Everything is daily
changeFrequency: 'daily'  // Google won't believe you

// ✅ Good: Realistic frequencies
changeFrequency: slug === '' ? 'daily' : 'weekly'
```

**3. Including non-canonical URLs**
Don't include:
- Paginated pages (page=2, page=3)
- Filter/sort variations
- Duplicate content
- URLs with query parameters

Only include the canonical version of each page.

## What's Next?

You've now got Google discovering and crawling your pages efficiently. But discovery isn't enough—you need those pages to stand out in search results and drive clicks.

In the next post, I'll show you how to write meta tags and Open Graph tags that dramatically increase your click-through rate from search results. These tags took my CTR from 2.1% to 4.3%—more than doubling my organic traffic without changing rankings.

---

**Full SEO Series for Next.js:**
1. [The Robots.txt Mistake That Cost Me Visitors]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})
2. Building Dynamic Multilingual Sitemaps in Next.js (you are here)

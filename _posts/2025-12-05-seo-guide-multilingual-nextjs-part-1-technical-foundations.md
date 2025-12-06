---
layout: post
title: "SEO for Multilingual Next.js (Part 1): Technical Foundations"
description: "Learn how to implement core SEO infrastructure for multilingual Next.js applications. Step-by-step guide covering robots.txt, sitemaps, meta tags, schema markup, and hreflang tags for international audiences."
date: 2025-12-05
categories: [web-development, seo]
tags: [nextjs, seo, internationalization, i18n, schema-markup, tutorial]
author: Mina Sami
---

Building a multilingual website is one thing—making sure search engines properly index and rank it in multiple languages is another challenge entirely. In this two-part series, I'll walk you through implementing comprehensive SEO for a multilingual Next.js application.

**Part 1** (this post) covers the technical foundations you need to get started and see immediate results. **Part 2** will cover advanced optimization strategies including location-based SEO, performance optimization, and long-term monitoring.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [What We'll Build](#what-well-build)
3. [Robots.txt Configuration](#robotstxt-configuration)
4. [Dynamic Sitemap Generation](#dynamic-sitemap-generation)
5. [Meta Tags and Open Graph](#meta-tags-and-open-graph)
6. [Schema Markup (Structured Data)](#schema-markup-structured-data)
7. [Hreflang and Language Alternates](#hreflang-and-language-alternates)
8. [Testing Your Implementation](#testing-your-implementation)
9. [Next Steps](#next-steps)

## Prerequisites

Before diving in, ensure you have:

- A Next.js application with App Router (Next.js 13+)
- Internationalization set up (e.g., using `next-intl`)
- Multiple locales configured (e.g., English and German)
- Basic understanding of SEO concepts
- Node.js 18+ installed

If you haven't set up i18n yet, check out my previous guide: [Next.js i18n Guide: Set Up Internationalization with next-intl](https://minasami.com/2025/12/04/nextjs-i18n-guide-set-up-internationalization-with-next-intl.html)

## What We'll Build

By the end of this tutorial, you'll have implemented:

- ✅ Properly configured `robots.txt` that doesn't block essential assets
- ✅ Dynamic sitemap with language alternates for all pages
- ✅ Complete meta tags (title, description, Open Graph, Twitter)
- ✅ 6 types of schema markup for rich search results
- ✅ Proper hreflang tags for multilingual support
- ✅ Validation and testing procedures

**Expected timeline:** 4-6 hours to implement everything in this part.

## Robots.txt Configuration

The robots.txt file tells search engines which parts of your site to crawl. A common mistake is blocking essential Next.js assets, which prevents proper page rendering in search results.

### The Problem

Many developers block the entire `/_next/` directory:

```txt
# ❌ BAD - Blocks ALL Next.js assets
Disallow: /_next/
```

This prevents search engines from loading your JavaScript, CSS, and images, resulting in broken pages in search results.

### The Solution

Create `app/robots.ts` with precise allow/disallow rules:

```typescript
import type { MetadataRoute } from 'next';

const SITE_URL = process.env.SITE_URL ?? 'https://yoursite.com';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: [
          '/',
          '/images/',
          '/assets/',
          '/favicon.ico',
          // ✅ IMPORTANT: Allow static assets for proper rendering
          '/_next/static/',
          '/_next/image/',
        ],
        disallow: [
          '/admin',
          '/api/',
          '/private/',
          '/scripts/',
          '/logs/',
          // ✅ Only block _next/data directory (not needed for SEO)
          '/_next/data/',
          // Block build manifest files
          '/*_buildManifest.js',
          '/*_middlewareManifest.js',
          '/*_ssgManifest.js',
        ],
      }
    ],
    sitemap: `${SITE_URL}/sitemap.xml`,
    host: SITE_URL,
  };
}
```

### Why This Matters

**Before:**
- 23 pages blocked by robots.txt
- Search engines see unstyled HTML
- Poor user experience in search results

**After:**
- 0 pages blocked
- Pages render correctly with full styling
- JavaScript and CSS load properly
- Images display correctly

Test your robots.txt locally:

```bash
npm run dev
curl http://localhost:3000/robots.txt
```

## Dynamic Sitemap Generation

A comprehensive sitemap helps search engines discover all your pages efficiently, including all language versions.

### Step 1: Create the Sitemap

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
    const changeFreq = (slug === '' || slug === 'products')
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

### Step 2: Add Dynamic Pages

If you have dynamic content (products, blog posts, etc.), add them to the sitemap:

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

### Understanding Priorities and Change Frequencies

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

Test your sitemap:

```bash
npm run build
npm start
curl http://localhost:3000/sitemap.xml
```

## Meta Tags and Open Graph

Proper meta tags control how your pages appear in search results and when shared on social media.

### Step 1: Create SEO Helper Module

Create `app/src/components/common/seo/metadata.ts`:

```typescript
import { Metadata } from 'next'

type ValidLocale = 'en' | 'de'

interface SeoProps {
    title: string
    description: string
    ogImage?: string
    lang: ValidLocale
    url?: string
    alternateLocales?: ValidLocale[]
}

export const defaultSEOConfig = {
    en: {
        title: 'Your Company - Premium Services',
        description: 'Expert services for your business needs.',
    },
    de: {
        title: 'Ihr Unternehmen - Premium-Dienstleistungen',
        description: 'Professionelle Dienstleistungen für Ihre Geschäftsanforderungen.',
    }
}

export function generateSEOMetadata({
    title,
    description,
    ogImage = '/images/og-default.png',
    lang,
    url,
    alternateLocales = ['en', 'de'],
}: SeoProps): Metadata {
    const SITE_URL = process.env.SITE_URL ?? 'https://yoursite.com'
    const SITE_NAME = 'Your Company'

    // Ensure title includes site name
    const fullTitle = title.includes(SITE_NAME)
      ? title
      : `${title} | ${SITE_NAME}`

    // Build absolute URLs
    const canonicalUrl = url
      ? `${SITE_URL}${url}`
      : `${SITE_URL}/${lang}`

    const ogImageUrl = ogImage.startsWith('http')
      ? ogImage
      : `${SITE_URL}${ogImage}`

    // Build language alternates
    const languages: Record<string, string> = {}
    alternateLocales.forEach(locale => {
        if (url) {
            const altUrl = url.replace(`/${lang}/`, `/${locale}/`)
            languages[locale] = `${SITE_URL}${altUrl}`
        } else {
            languages[locale] = `${SITE_URL}/${locale}`
        }
    })

    return {
        metadataBase: new URL(SITE_URL),
        title: fullTitle,
        description,
        alternates: {
            canonical: canonicalUrl,
            languages: languages,
        },
        openGraph: {
            type: 'website',
            title: fullTitle,
            description,
            images: [
                {
                    url: ogImageUrl,
                    width: 1200,
                    height: 630,
                    alt: title
                }
            ],
            url: canonicalUrl,
            siteName: SITE_NAME,
            locale: lang === 'en' ? 'en_US' : 'de_DE',
        },
        twitter: {
            card: 'summary_large_image',
            title: fullTitle,
            description,
            images: [ogImageUrl],
        },
        robots: {
            index: true,
            follow: true,
            googleBot: {
                index: true,
                follow: true,
                'max-video-preview': -1,
                'max-image-preview': 'large',
                'max-snippet': -1,
            },
        },
    }
}
```

### Step 2: Use in Your Pages

In any page (e.g., `app/[lang]/about/page.tsx`):

```typescript
import { generateSEOMetadata } from '@/components/common/seo/metadata'
import { getTranslations } from 'next-intl/server'

export async function generateMetadata({
  params
}: {
  params: Promise<{ lang: string }>
}) {
  const { lang } = await params
  const t = await getTranslations({ locale: lang })

  return generateSEOMetadata({
    title: t('about.title'),
    description: t('about.description'),
    lang: lang as 'en' | 'de',
    url: `/${lang}/about`,
    ogImage: '/images/about-og.png',
  })
}

export default async function AboutPage() {
  // Your page content
  return <main>{/* Content */}</main>
}
```

### What Gets Generated

This creates comprehensive meta tags in your HTML:

```html
<title>About Us | Your Company</title>
<meta name="description" content="Learn about our company..." />
<link rel="canonical" href="https://yoursite.com/en/about" />
<link rel="alternate" hreflang="en" href="https://yoursite.com/en/about" />
<link rel="alternate" hreflang="de" href="https://yoursite.com/de/about" />

<!-- Open Graph -->
<meta property="og:title" content="About Us | Your Company" />
<meta property="og:description" content="Learn about our company..." />
<meta property="og:image" content="https://yoursite.com/images/about-og.png" />
<meta property="og:url" content="https://yoursite.com/en/about" />

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="About Us | Your Company" />
```

## Schema Markup (Structured Data)

Schema markup helps search engines understand your content and can result in rich snippets (enhanced search results with ratings, images, FAQs, etc.).

### Step 1: Create Schema Components

Create `app/src/components/common/seo/schemas.tsx`:

{% raw %}
```typescript
import React from 'react'

// Organization Schema - Use in root layout
export function OrganizationSchema({
  name,
  url,
  logo
}: {
  name: string
  url: string
  logo: string
}) {
  const schema = {
    "@context": "https://schema.org",
    "@type": "Organization",
    "name": name,
    "url": url,
    "logo": logo,
    "sameAs": [
      "https://facebook.com/yourpage",
      "https://twitter.com/yourhandle",
      "https://linkedin.com/company/yourcompany"
    ]
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  )
}

// Breadcrumb Schema - Use on all content pages
export function BreadcrumbSchema({
  breadcrumbs
}: {
  breadcrumbs: Array<{ name: string; url: string }>
}) {
  const schema = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": breadcrumbs.map((crumb, index) => ({
      "@type": "ListItem",
      "position": index + 1,
      "name": crumb.name,
      "item": crumb.url
    }))
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  )
}

// Product Schema - Use on product detail pages
export function ProductSchema({
  product
}: {
  product: {
    name: string
    description: string
    image: string
    url: string
    price?: number
    currency?: string
  }
}) {
  const schema = {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": product.name,
    "description": product.description,
    "image": product.image,
    "url": product.url,
    ...(product.price && {
      "offers": {
        "@type": "Offer",
        "price": product.price,
        "priceCurrency": product.currency || "EUR",
        "availability": "https://schema.org/InStock"
      }
    })
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  )
}

// FAQ Schema - Use on pages with Q&A content
export function FAQSchema({
  faqs
}: {
  faqs: Array<{ question: string; answer: string }>
}) {
  const schema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": faqs.map(faq => ({
      "@type": "Question",
      "name": faq.question,
      "acceptedAnswer": {
        "@type": "Answer",
        "text": faq.answer
      }
    }))
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  )
}

// ItemList Schema - Use on listing pages
export function ItemListSchema({
  items,
  url
}: {
  items: Array<{ name: string; url: string }>
  url: string
}) {
  const schema = {
    "@context": "https://schema.org",
    "@type": "ItemList",
    "url": url,
    "itemListElement": items.map((item, index) => ({
      "@type": "ListItem",
      "position": index + 1,
      "item": {
        "@type": "Thing",
        "name": item.name,
        "url": item.url
      }
    }))
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  )
}
```
{% endraw %}

### Step 2: Use Schema in Your Pages

**Root Layout** (`app/[lang]/layout.tsx`):

```typescript
import { OrganizationSchema } from '@/components/common/seo/schemas'

export default async function RootLayout({ children, params }) {
  return (
    <html>
      <body>
        <OrganizationSchema
          name="Your Company"
          url="https://yoursite.com"
          logo="https://yoursite.com/logo.png"
        />
        {children}
      </body>
    </html>
  )
}
```

**Product Detail Page** (`app/[lang]/products/[slug]/page.tsx`):

{% raw %}
```typescript
import {
  ProductSchema,
  BreadcrumbSchema,
  FAQSchema
} from '@/components/common/seo/schemas'

export default async function ProductPage({
  params
}: {
  params: Promise<{ lang: string; slug: string }>
}) {
  const { lang, slug } = await params
  const product = getProductBySlug(slug)

  const breadcrumbs = [
    { name: 'Home', url: `https://yoursite.com/${lang}` },
    { name: 'Products', url: `https://yoursite.com/${lang}/products` },
    { name: product.title, url: `https://yoursite.com/${lang}/products/${slug}` },
  ]

  const faqs = [
    {
      question: 'What is included?',
      answer: product.features.join(', ')
    },
    {
      question: 'How do I purchase?',
      answer: 'Click the buy button to add to cart.'
    },
  ]

  return (
    <>
      <BreadcrumbSchema breadcrumbs={breadcrumbs} />
      <ProductSchema product={{
        name: product.title,
        description: product.description,
        image: `https://yoursite.com${product.image}`,
        url: `https://yoursite.com/${lang}/products/${slug}`,
        price: product.price,
        currency: 'EUR'
      }} />
      <FAQSchema faqs={faqs} />

      <main>
        {/* Your page content */}
      </main>
    </>
  )
}
```
{% endraw %}

**Products Listing Page** (`app/[lang]/products/page.tsx`):

```typescript
import { ItemListSchema, BreadcrumbSchema } from '@/components/common/seo/schemas'
import { Products } from '@/data/products'

export default async function ProductsPage({ params }) {
  const { lang } = await params

  const items = Products.map(p => ({
    name: p.title,
    url: `https://yoursite.com/${lang}/products/${p.slug}`
  }))

  return (
    <>
      <ItemListSchema
        items={items}
        url={`https://yoursite.com/${lang}/products`}
      />

      <main>
        {/* Your products grid */}
      </main>
    </>
  )
}
```

## Hreflang and Language Alternates

Hreflang tags tell search engines about language and regional variations of your pages, preventing duplicate content issues and helping serve the right language to users.

### Step 1: Implement in Metadata

The hreflang tags are automatically generated from the `alternates.languages` in your metadata. In your `generateSEOMetadata` function (we created this earlier), we already included:

```typescript
alternates: {
    canonical: canonicalUrl,
    languages: {
        'en': `${SITE_URL}/en${url}`,
        'de': `${SITE_URL}/de${url}`,
        'x-default': `${SITE_URL}/en${url}`, // Default fallback
    },
}
```

### Step 2: Verify in Root Layout

Ensure your root layout passes the locale properly:

```typescript
// app/[lang]/layout.tsx
export async function generateMetadata({
  params
}: {
  params: Promise<{ lang: string }>
}) {
  const { lang } = await params

  return {
    other: {
      'og:locale': lang === 'en' ? 'en_US' : 'de_DE',
    }
  }
}
```

### What Gets Generated

Next.js automatically generates these tags in your HTML:

```html
<link rel="canonical" href="https://yoursite.com/en/about" />
<link rel="alternate" hreflang="en" href="https://yoursite.com/en/about" />
<link rel="alternate" hreflang="de" href="https://yoursite.com/de/about" />
<link rel="alternate" hreflang="x-default" href="https://yoursite.com/en/about" />
```

### Understanding x-default

The `x-default` hreflang indicates which version to show when:
- User's language preference doesn't match any available languages
- Search engine can't determine user's language
- Automatic fallback is needed

Best practice: Set `x-default` to your primary/default language (usually English).

## Testing Your Implementation

Now let's verify everything works correctly.

### Test 1: Robots.txt

```bash
# Local
curl http://localhost:3000/robots.txt

# Production
curl https://yoursite.com/robots.txt
```

Verify:
- ✅ `/_next/static/` is in Allow list
- ✅ `/_next/image/` is in Allow list
- ✅ Only `/_next/data/` is disallowed
- ✅ Sitemap URL is present

### Test 2: Sitemap

```bash
# Local
curl http://localhost:3000/sitemap.xml

# Production
curl https://yoursite.com/sitemap.xml
```

Verify:
- ✅ All pages are included
- ✅ Both language versions present (en and de)
- ✅ Language alternates are correct
- ✅ Priorities make sense
- ✅ Images are included where appropriate

### Test 3: Meta Tags

View page source for any page and verify:

```bash
# Check meta tags
curl -s https://yoursite.com/en/about | grep -E '<meta|<title'
```

Verify:
- ✅ `<title>` is present and unique
- ✅ Meta description is present
- ✅ Open Graph tags present (og:title, og:description, og:image)
- ✅ Twitter Card tags present
- ✅ Canonical URL is correct

### Test 4: Schema Markup

Use [Google's Rich Results Test](https://search.google.com/test/rich-results):

1. Go to https://search.google.com/test/rich-results
2. Enter your URL or paste HTML
3. Click "Test URL"

Verify:
- ✅ All schemas detected
- ✅ No validation errors
- ✅ All required properties present
- ✅ Preview looks correct

### Test 5: Hreflang Tags

```bash
# Check hreflang implementation
curl -s https://yoursite.com/en/about | grep hreflang
```

Verify:
- ✅ hreflang tags present for all languages
- ✅ URLs are absolute (not relative)
- ✅ x-default is present
- ✅ Self-referential (page links to itself in its own language)

### Test 6: Open Graph Preview

Test how your pages appear when shared:

- Facebook: [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/)
- Twitter: [Twitter Card Validator](https://cards-dev.twitter.com/validator)
- LinkedIn: Share privately and check preview
- Generic: [OpenGraph.xyz](https://www.opengraph.xyz/)

## Summary: What You've Accomplished

Congratulations! You've implemented the core SEO infrastructure for your multilingual Next.js application:

✅ **Robots.txt** - Properly configured to allow essential assets
✅ **Sitemap** - Dynamic generation with language alternates
✅ **Meta Tags** - Complete title, description, and Open Graph tags
✅ **Schema Markup** - 5 different schema types for rich results
✅ **Hreflang Tags** - Proper multilingual page relationship
✅ **Testing** - Validated all implementations

### Expected Results (First 30 Days)

Based on production implementation:
- Indexed pages will increase significantly
- Pages will appear correctly styled in search results
- Rich snippets may start appearing (takes 2-4 weeks)
- "Crawled but not indexed" issues will decrease

## Next Steps

In **Part 2** of this series, we'll cover:

- **Location-Based SEO** - Creating location landing pages for local search
- **Performance Optimization** - Font optimization, image lazy loading, Core Web Vitals
- **Google Search Console** - Setup, monitoring, and maintenance
- **Advanced Testing** - Comprehensive validation procedures
- **Real Results** - Detailed metrics from production implementation

The techniques in Part 1 provide the foundation. Part 2 will help you achieve 200-300% traffic increases through advanced optimization.

## Additional Resources

- [Next.js Metadata API](https://nextjs.org/docs/app/api-reference/functions/generate-metadata)
- [Google Search Central](https://developers.google.com/search)
- [Schema.org Documentation](https://schema.org/)
- [Google Rich Results Test](https://search.google.com/test/rich-results)

## Have Questions?

If you run into issues or have questions about implementing these SEO techniques, feel free to reach out or leave a comment below.

Happy optimizing! 🚀

---

**Continue to Part 2:** [SEO for Multilingual Next.js (Part 2): Advanced Optimization & Performance](coming-soon)

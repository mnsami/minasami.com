---
layout: post
title: "Schema Markup: 5 Types for Rich Search Results"
description: "Schema markup transformed my plain Google results into rich snippets with ratings, images, and FAQs. Here are the 5 schema types that actually move the needle."
date: 2025-12-16
categories: [web-development, seo]
tags: [nextjs, seo, schema-markup, rich-snippets, structured-data]
author: Mina Sami
---

Two months after fixing [meta tags]({{ site.baseurl }}{% post_url 2025-12-15-nextjs-meta-tags-that-convert %}), I noticed competitors' search results looked way better than mine. They had:

- ⭐ Star ratings directly in search results
- 📷 Product images next to listings
- ❓ Expandable FAQ sections
- 🍞 Breadcrumb navigation

My results? Just blue link, gray description. Boring.

The difference? **Schema markup** (also called structured data). It's JSON-LD code that tells Google exactly what your content means—products, recipes, events, FAQs, etc.

After implementing 5 schema types, my rich snippets started appearing within 3 weeks. Result: My already-good 4.3% CTR jumped to 5.8% for pages with rich snippets. **That's a 35% increase in clicks from the same rankings.**

## What Schema Markup Actually Does

Schema markup doesn't help you rank higher (common misconception). It helps you **stand out** once you're ranking.

Think of it like this:
- **Without schema:** Blue link + gray text (like everyone else)
- **With schema:** Eye-catching enhanced results that draw clicks

Google's algorithm reads your content anyway, but schema gives it perfect context. Instead of guessing, Google knows: "This is a product, priced at €99, rated 4.5 stars, in stock."

## The 5 Schema Types That Matter

I tested dozens of schema types. These 5 actually appeared in search results and drove measurable traffic:

1. **Organization** - Establishes your brand identity
2. **Breadcrumb** - Shows navigation path in results
3. **Product** - Enables product rich snippets
4. **FAQ** - Gets the expandable Q&A dropdown
5. **ItemList** - Enhances listing pages

Let's implement each one.

## Step 1: Create Schema Components

Create `app/src/components/common/seo/schemas.tsx`:

{% raw %}
```typescript
import React from 'react'

// 1. Organization Schema - Use in root layout
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

// 2. Breadcrumb Schema - Use on all content pages
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

// 3. Product Schema - Use on product detail pages
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

// 4. FAQ Schema - Use on pages with Q&A content
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

// 5. ItemList Schema - Use on listing pages
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

## Step 2: Implement in Your Pages

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

**Product Page** (`app/[lang]/products/[slug]/page.tsx`):

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

**Listing Page** (`app/[lang]/products/page.tsx`):

```typescript
import { ItemListSchema } from '@/components/common/seo/schemas'
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

## Step 3: Test Your Schema

**Critical:** Test BEFORE deploying. Invalid schema won't show up at all.

Use [Google's Rich Results Test](https://search.google.com/test/rich-results):

1. Go to https://search.google.com/test/rich-results
2. Enter your URL or paste HTML
3. Click "Test URL"

**What to check:**
- ✅ All schemas detected
- ✅ No validation errors
- ✅ All required properties present
- ✅ Preview looks correct

**Common errors:**
- Missing required fields (`name`, `url`, `price`)
- Wrong data types (string instead of number)
- Invalid URLs (relative instead of absolute)
- JSON syntax errors (missing commas, quotes)

Fix all errors before deploying. Google won't show partial/broken schema.

## When Rich Snippets Appear

After deployment, **be patient**. Schema isn't instant.

My timeline:
- **Week 1:** Schema validated, but no rich snippets yet
- **Week 2-3:** First FAQ snippets appearing
- **Week 4-6:** Breadcrumbs showing consistently
- **Week 8+:** Product snippets with pricing/availability

Not all pages got rich snippets, even with valid schema. Google decides based on:
- Page quality and authority
- Schema relevance to search query
- Competition in search results
- Overall site trust signals

## The Real Impact

Pages with rich snippets vs. without:

**FAQ snippets:**
- 5.8% CTR vs. 4.3% CTR (+35%)
- Take up 2-3x more space in results
- Answer user questions before they click

**Breadcrumb snippets:**
- 4.9% CTR vs. 4.3% CTR (+14%)
- Show site structure, build trust
- Make URL path clearer

**Product snippets:**
- 6.2% CTR vs. 4.3% CTR (+44%)
- Price shown in results
- "In stock" status visible

**Overall impact:**
- 40% of my pages now have rich snippets
- Those pages get 25-40% higher CTR
- Translates to ~150 additional clicks/month

## Schema Types I Didn't Use

Some schema types look promising but didn't produce results:

**LocalBusiness:** Only works if you have physical location with reviews
**Review/Rating:** Need actual user reviews (can't fake these)
**Article:** News sites only, didn't help blog posts
**HowTo:** Requires very specific step-by-step format
**Recipe:** Only for actual cooking recipes

Stick to the 5 I shared. They work for most business sites.

## What's Next?

You now have the technical SEO foundation: proper indexing, discovery, compelling meta tags, and rich snippets. These get you visible and clickable in search results.

But here's what took me from good SEO to **250% traffic growth**: location-based pages that capture high-intent local searches. This single strategy generated more traffic than everything else combined.

In the next post, I'll show you exactly how to build location pages that rank fast and convert better than your homepage.

**Read next:** [Location Pages: My Secret to 250% SEO Growth]({{ site.baseurl }}{% post_url 2025-12-19-nextjs-location-pages-seo %})

---

**Full SEO Series for Next.js:**
1. [The Robots.txt Mistake That Cost Me Visitors]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})
2. [Building Dynamic Multilingual Sitemaps in Next.js]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %})
3. [Meta Tags That Actually Convert Clicks]({{ site.baseurl }}{% post_url 2025-12-15-nextjs-meta-tags-that-convert %})
4. Schema Markup: 5 Types for Rich Search Results (you are here)
5. [Location Pages: My Secret to 250% SEO Growth]({{ site.baseurl }}{% post_url 2025-12-19-nextjs-location-pages-seo %})

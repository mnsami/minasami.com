---
layout: post
title: "Meta Tags That Actually Convert Clicks"
description: "How to write titles, descriptions and Open Graph images that people actually click, with a reusable multilingual metadata helper for the Next.js App Router."
date: 2025-12-15
last_modified_at: 2026-10-15
categories: [web-development]
tags: [nextjs, seo, meta-tags, open-graph, ctr-optimization]
author: Mina Sami
---

My pages were finally indexed ([robots.txt fixed]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})) and discoverable ([sitemap submitted]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %})). They were showing up in search results. But few people clicked.

Looking at my search results in incognito mode, I understood why. My titles were generic ("About Us \| Company"), descriptions were truncated mid-sentence, and when shared on social media, the preview looked broken: no image, weird formatting, random text snippets.

Fixing meta tags and Open Graph configuration made those results worth clicking. I'm not going to give you a CTR number for it, because the effect depends on your queries, your rankings and your competitors. Instead, this post includes a section on measuring it on your own site.

**Here's what I changed.**

## The Anatomy of a Great Meta Tag

When someone sees your site in search results or social media, they see three things:

1. **Title** (blue link they click)
2. **Description** (gray text below)
3. **Image** (when shared on social media)

Each one has specific rules for maximum impact:

### Title Tags: Keep Them Short

**Bad title (my original):**
```
About Us | Your Company
```

Why it's bad:
- Generic, could be anyone's about page
- Doesn't communicate unique value
- Boring, no reason to click

**Good title:**
```
Next.js Development, 10+ Years | Your Company
```

Why it works:
- Specific service (Next.js Development)
- A credential (10+ years), if it's true for you
- Still includes brand name
- 45 characters, so it usually shows in full. Google truncates title links to fit the device width rather than at a fixed character count ([Google](https://developers.google.com/search/docs/appearance/title-link)). A common rule of thumb is 50–60 characters at most.

**Formula:**
```
[Specific Value], [Differentiator] | [Brand]
```

### Description Tags: The 155-Character Story

**Bad description (my original):**
```
Learn about our company, our mission, our values, and what makes us different from competitors in the industry.
```

Why it's bad:
- Vague ("learn about," "different")
- No specific benefits
- No call to action

**Good description:**
```
We build and maintain production Next.js apps for SaaS teams. Fixed-price estimates, two-week sprints and support after launch. Ask for a quote.
```

Why it works:
- Specific about who it's for (SaaS teams)
- Concrete benefits (fixed-price estimates, support)
- Clear CTA (ask for a quote)
- 144 characters, so it usually fits (Google cuts snippets to fit the screen and may write its own)

**Formula:**
```
[What you do, for whom] + [Key benefits] + [Call to action]
```

## Step 1: Create an SEO Helper Module

Create `src/lib/seo.ts`:

{% raw %}
```typescript
import type { Metadata } from 'next'

export const locales = ['en', 'de'] as const
export type Locale = (typeof locales)[number]

export function isLocale(value: string): value is Locale {
  return (locales as readonly string[]).includes(value)
}

const SITE_URL = process.env.SITE_URL ?? 'https://yoursite.com'
const SITE_NAME = 'Your Company'
const OG_LOCALE: Record<Locale, string> = { en: 'en_US', de: 'de_DE' }

type SeoInput = {
  title: string
  description: string
  lang: Locale
  // Path without the locale prefix, e.g. '/about'. Use '' for the homepage.
  path: string
  // Only for pages without an opengraph-image file (see Step 3).
  ogImage?: string
}

export function generateSEOMetadata({
  title,
  description,
  lang,
  path,
  ogImage,
}: SeoInput): Metadata {
  const url = (locale: Locale) => `${SITE_URL}/${locale}${path}`
  const fullTitle = title.includes(SITE_NAME) ? title : `${title} | ${SITE_NAME}`

  return {
    metadataBase: new URL(SITE_URL),
    title: fullTitle,
    description,
    alternates: {
      canonical: url(lang),
      // Every language version, including this one.
      languages: Object.fromEntries(locales.map((l) => [l, url(l)])),
    },
    openGraph: {
      type: 'website',
      title: fullTitle,
      description,
      url: url(lang),
      siteName: SITE_NAME,
      locale: OG_LOCALE[lang],
      // Set images only when passed: an opengraph-image file in the
      // route is ignored if this page's metadata sets openGraph.images.
      ...(ogImage && {
        images: [{ url: ogImage, width: 1200, height: 630, alt: title }],
      }),
    },
    // Next.js copies title, description and image from openGraph.
    twitter: { card: 'summary_large_image' },
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
{% endraw %}

Passing the path **without** the locale (`'/about'`, not `'/en/about'`) lets the helper build every language URL the same way, including the homepage. The hreflang list includes the current page too: Google requires each language version to list itself as well as all the others ([Google](https://developers.google.com/search/docs/specialty/international/localized-versions)).

Two deliberate omissions: the helper sets `openGraph.images` only when you pass `ogImage` (Step 3 explains why), and it leaves the X card's title, description and image unset, because Next.js copies them from Open Graph.

## Step 2: Use in Your Pages

In any page (e.g., `src/app/[lang]/about/page.tsx`):

```typescript
import type { Metadata } from 'next'
import { notFound } from 'next/navigation'
import { generateSEOMetadata, isLocale } from '@/lib/seo'

export async function generateMetadata({
  params,
}: {
  params: Promise<{ lang: string }>
}): Promise<Metadata> {
  const { lang } = await params
  if (!isLocale(lang)) notFound()

  return generateSEOMetadata({
    title: 'Next.js Development, 10+ Years',
    description:
      'We build and maintain production Next.js apps for SaaS teams. Fixed-price estimates, two-week sprints and support after launch. Ask for a quote.',
    lang,
    path: '/about',
  })
}

export default async function AboutPage() {
  return <main>{/* Your content */}</main>
}
```

## Step 3: Create Compelling Open Graph Images

Open Graph images appear when your links are shared on social media. A page-specific image with the page title on it tells people what they'll get before they click; a generic logo doesn't.

**OG image guidelines:**
- **Dimensions:** 1200×630px (1.91:1 ratio)
- **File size:** aim for under 300KB
- **Format:** JPG or PNG
- **Safe zone:** keep text and logos away from the edges, since some platforms crop

**What makes a good OG image:**
- Clear, high-contrast text
- Professional photo or illustration
- Your logo (small, in corner)
- Specific to the page content

**Generating them in Next.js:** you don't need a design tool for every page. Add an `opengraph-image.tsx` next to the page, and Next.js renders it with `ImageResponse` from `next/og` ([Next.js docs](https://nextjs.org/docs/app/getting-started/metadata-and-og-images)). Because it lives under `[lang]`, it can render the headline in each language:

{% raw %}
```tsx
// src/app/[lang]/about/opengraph-image.tsx
import { ImageResponse } from 'next/og'

const headline = {
  en: 'Next.js Development, 10+ Years',
  de: 'Next.js-Entwicklung, 10+ Jahre',
} as const

export const alt = 'Next.js Development, 10+ Years | Your Company'
export const size = { width: 1200, height: 630 }
export const contentType = 'image/png'

export default async function Image({
  params,
}: {
  params: Promise<{ lang: string }>
}) {
  const { lang } = await params
  const text = lang === 'de' ? headline.de : headline.en

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          padding: 80,
          background: '#0f172a',
          color: '#ffffff',
        }}
      >
        <div style={{ fontSize: 72, fontWeight: 700 }}>{text}</div>
        <div style={{ fontSize: 36, marginTop: 24, opacity: 0.8 }}>
          Your Company
        </div>
      </div>
    ),
    size,
  )
}
```
{% endraw %}

Two catches:

- Next.js uses an `opengraph-image` file only when the same page's metadata doesn't set `openGraph.images` itself. That's why the helper adds `images` only when you pass `ogImage`.
- A page's `openGraph` object replaces the one it would inherit from a parent layout, images included. So a page **without** its own `opengraph-image` file must pass `ogImage`, for example a default image in `public/og-default.png` with `ogImage: '/og-default.png'`. Otherwise it ends up with no `og:image` at all. To try layouts quickly, use the [Vercel OG Playground](https://og-playground.vercel.app/).

## What Gets Generated

For the About page above, this creates meta tags like these in your HTML:

```html
<!-- Basic meta tags -->
<title>Next.js Development, 10+ Years | Your Company</title>
<meta name="description" content="We build and maintain production Next.js apps..." />
<link rel="canonical" href="https://yoursite.com/en/about" />
<link rel="alternate" hreflang="en" href="https://yoursite.com/en/about" />
<link rel="alternate" hreflang="de" href="https://yoursite.com/de/about" />

<!-- Open Graph (Facebook, LinkedIn) -->
<meta property="og:title" content="Next.js Development, 10+ Years | Your Company" />
<meta property="og:description" content="We build and maintain production..." />
<meta property="og:url" content="https://yoursite.com/en/about" />
<meta property="og:site_name" content="Your Company" />
<meta property="og:locale" content="en_US" />
<meta property="og:image" content="https://yoursite.com/en/about/opengraph-image?..." />
<meta property="og:image:type" content="image/png" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:image:alt" content="Next.js Development, 10+ Years | Your Company" />
<meta property="og:type" content="website" />

<!-- Twitter Card (copied from Open Graph) -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="Next.js Development, 10+ Years | Your Company" />
<meta name="twitter:description" content="We build and maintain production..." />
<meta name="twitter:image" content="https://yoursite.com/en/about/opengraph-image?..." />
```

## Step 4: Test Your Meta Tags

Before deploying, test how they look:

### Search Results Preview
- [Metatags.io](https://metatags.io/): shows Google, X, Facebook and LinkedIn previews
- Check title length (aim for 50–60 characters at most)
- Check description length (aim for under 155 characters)

### Social Media Preview
- [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/)
- [LinkedIn Post Inspector](https://www.linkedin.com/post-inspector/)
- [OpenGraph.xyz](https://www.opengraph.xyz/): all platforms
- **X (Twitter):** the Card Validator no longer shows previews. Paste the link into the post composer to see the card.

### Common Issues

**Title shows "undefined" or brand name only**
- Forgot to pass a title to `generateSEOMetadata`
- Check your translation keys

**Description truncated mid-sentence**
- Keep it under 155 characters
- Put key info in first 120 characters

**OG image not showing**
- Use absolute URLs, not relative
- Check image is publicly accessible and not blocked by robots.txt
- Keep the file small (under 300KB is a good target)
- Use 1200×630px

## Measure It on Your Own Site

You'll find plenty of posts promising a fixed CTR jump from better meta tags. Measure your own instead:

1. In Search Console → **Performance**, filter to the pages whose titles and descriptions you changed.
2. Start the "after" window once Google has re-crawled the page: URL Inspection shows the last crawl date.
3. Compare 28 days before the change with 28 days after. Four full weeks on each side keep weekday patterns out of the comparison.
4. Look at CTR together with average position. If position moved, the CTR change isn't only the meta tags.

Google may also rewrite a title or description it thinks matches the query better, so check what actually shows in the results, not just what you wrote.

## Writing Tips That Actually Work

**For titles:**
1. Lead with benefit, not brand
2. Use specific, true numbers (years, projects)
3. Include primary keyword
4. Keep the brand suffix short

**For descriptions:**
1. First sentence = main benefit
2. Second sentence = proof/credentials
3. End with CTA
4. Use active voice

**For Open Graph:**
1. Different image per page (not just logo)
2. Include text overlay with page title
3. High contrast, professional look
4. Test on actual social platforms

## What's Next?

Meta tags get people to click. The next step is **structured data**: the markup that makes your pages eligible for rich results such as product prices, breadcrumbs and your logo.

In the next post, I cover the 5 schema types Google still supports in 2026, which ones it has retired, and how to add them safely in Next.js.

**Read next:** [Next.js Schema Markup: 5 Types That Still Work]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-schema-markup-guide %})

---

**Full SEO Series for Next.js:**
1. [The Robots.txt Mistake That Cost Me Visitors]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})
2. [Dynamic Multilingual Sitemaps in Next.js]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %})
3. Meta Tags That Actually Convert Clicks (you are here)
4. [Next.js Schema Markup: 5 Types That Still Work]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-schema-markup-guide %})
5. [Next.js Location Pages Without Doorway Spam]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-location-pages-seo %})

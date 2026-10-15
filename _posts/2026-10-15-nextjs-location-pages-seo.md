---
layout: post
title: "Next.js Location Pages Without Doorway Spam"
description: "City pages can win local searches or get flagged as doorway spam. When a location page is legitimate, and how to build one in Next.js with i18n and hreflang."
date: 2026-10-15 12:00:00 +0200
categories: [web-development]
tags: [nextjs, seo, local-seo, location-pages, i18n]
author: Mina Sami
---

"[Service] in [city]" pages are one of the oldest local SEO tactics, and one of the most abused. Google's spam policy names them directly. "Having multiple domain names or pages targeted at specific regions or cities that funnel users to one page" is its first example of doorway abuse ([Google](https://developers.google.com/search/docs/essentials/spam-policies)).

That doesn't make location pages bad. A page about a city you really work in, with information that only applies there, is useful to someone searching for it. A page that swaps the city name into a template isn't. This post covers how to tell the two apart, and how to build the useful kind in a multilingual Next.js App Router project.

## Should This City Have a Page?

Build a page only if you can answer yes to all three:

1. **You really serve the city:** an office, people there, or clients you work with there.
2. **You have facts that only apply to it:** an address or service area, projects in that city, local response times, the languages you work in there.
3. **A visitor from that city gets something your general services page doesn't give them.**

If you can't fill a page with that, a single "Areas we serve" page that lists the cities is the honest alternative. It also avoids Google's second doorway example: "substantially similar pages that are closer to search results than a clearly defined, browseable hierarchy".

## Duplicate Content Isn't the Real Risk

You'll often read that near-identical city pages get a "duplicate content penalty". Google's spam policies don't describe one. The real risk is that a set of copy-paste city pages, built to rank for similar queries, matches Google's definition of doorway abuse. Sites that violate its spam policies "may rank lower in results or not appear in results at all".

So the fix isn't rewording the same paragraph five times. It's having something different to say about each city.

## Step 1: Make the Data Model Demand Local Content

The data model is where you stop template pages. Every field that a visitor reads is per language and written by hand, including the meta description:

```ts
// src/i18n/config.ts
export const locales = ['en', 'de'] as const
export type Locale = (typeof locales)[number]
export const defaultLocale: Locale = 'en'

export function isLocale(value: string): value is Locale {
  return (locales as readonly string[]).includes(value)
}
```

```ts
// src/data/locations.ts
import type { Locale } from '@/i18n/config'

type Localized<T> = Record<Locale, T>

export type Location = {
  slug: string
  name: Localized<string>
  // Written by hand for this city, never generated from a template.
  metaDescription: Localized<string>
  // What you actually do here, for whom, and since when.
  intro: Localized<string>
  // Checkable facts: address or service area, response times, languages.
  localFacts: Localized<string[]>
  // Real projects in this city, published with the client's permission.
  // Leave it empty rather than invent one.
  projects: { title: string; url?: string }[]
  image: { src: string; alt: Localized<string> }
  // Date of the last real content change, used as the sitemap's lastmod.
  updatedAt: string
}

export const locations: Location[] = [
  {
    slug: 'berlin',
    name: { en: 'Berlin', de: 'Berlin' },
    metaDescription: {
      en: '[One sentence on what you do in Berlin and for whom.]',
      de: '[Ein Satz dazu, was Sie in Berlin tun und für wen.]',
    },
    intro: {
      en: '[What you do in Berlin, for whom, and since when.]',
      de: '[Was Sie in Berlin tun, für wen und seit wann.]',
    },
    localFacts: {
      en: ['[Address or service area]', '[Typical response time]'],
      de: ['[Adresse oder Einzugsgebiet]', '[Übliche Reaktionszeit]'],
    },
    projects: [],
    image: {
      src: '/images/locations/berlin-project.jpg',
      alt: { en: '[What the photo shows]', de: '[Was das Foto zeigt]' },
    },
    updatedAt: '2026-10-15',
  },
]

export function getLocation(slug: string): Location | undefined {
  return locations.find((location) => location.slug === slug)
}
```

The brackets mark text only you can write. If you can't fill a field honestly for a city, that answers whether the city needs a page.

A photo from a real project in that city tells a visitor more than a stock skyline. And because `Localized<T>` is a `Record` over every locale, TypeScript refuses to build a city that is missing a translation.

## Step 2: The Page Template

{% raw %}
```tsx
// src/app/[lang]/locations/[slug]/page.tsx
import type { Metadata } from 'next'
import Image from 'next/image'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getLocation, locations } from '@/data/locations'
import { defaultLocale, isLocale, locales, type Locale } from '@/i18n/config'
import { SITE_URL } from '@/lib/site'

type Params = Promise<{ lang: string; slug: string }>

// Only the cities listed in the data exist; anything else is a 404.
export const dynamicParams = false

export function generateStaticParams() {
  return locales.flatMap((lang) =>
    locations.map((location) => ({ lang, slug: location.slug })),
  )
}

async function resolve(params: Params) {
  const { lang, slug } = await params
  const location = getLocation(slug)
  if (!isLocale(lang) || !location) notFound()
  return { lang, location }
}

const pathFor = (lang: Locale, slug: string) => `/${lang}/locations/${slug}`

export async function generateMetadata({
  params,
}: {
  params: Params
}): Promise<Metadata> {
  const { lang, location } = await resolve(params)

  return {
    title: `Next.js Development in ${location.name[lang]}`,
    description: location.metaDescription[lang],
    alternates: {
      canonical: `${SITE_URL}${pathFor(lang, location.slug)}`,
      languages: {
        ...Object.fromEntries(
          locales.map((l) => [l, `${SITE_URL}${pathFor(l, location.slug)}`]),
        ),
        'x-default': `${SITE_URL}${pathFor(defaultLocale, location.slug)}`,
      },
    },
  }
}

export default async function LocationPage({ params }: { params: Params }) {
  const { lang, location } = await resolve(params)
  const name = location.name[lang]

  return (
    <main>
      <h1>Next.js Development in {name}</h1>
      <p>{location.intro[lang]}</p>

      <Image
        src={location.image.src}
        alt={location.image.alt[lang]}
        width={1200}
        height={630}
        priority
      />

      <h2>Working with us in {name}</h2>
      <ul>
        {location.localFacts[lang].map((fact) => (
          <li key={fact}>{fact}</li>
        ))}
      </ul>

      {location.projects.length > 0 && (
        <>
          <h2>Projects in {name}</h2>
          <ul>
            {location.projects.map((project) =>
              project.url ? (
                <li key={project.title}>
                  <Link href={project.url}>{project.title}</Link>
                </li>
              ) : (
                <li key={project.title}>{project.title}</li>
              ),
            )}
          </ul>
        </>
      )}

      <p>
        <Link href={`/${lang}/services`}>All services</Link> ·{' '}
        <Link href={`/${lang}/locations`}>All locations</Link> ·{' '}
        <Link href={`/${lang}/contact`}>Contact</Link>
      </p>
    </main>
  )
}
```
{% endraw %}

What each part is for:

- **`dynamicParams = false`:** a slug that isn't in your data returns a 404, instead of rendering an empty "Next.js Development in undefined" page.
- **`resolve()`:** checks the language and the city once, for both the metadata and the page. `notFound()` never returns, so TypeScript knows `lang` is a valid locale and `location` exists after it.
- **hreflang:** Google requires that "each language version must list itself as well as all other language versions", or it ignores the tags ([Google](https://developers.google.com/search/docs/specialty/international/localized-versions)). Building the list from `locales` keeps that true as you add languages. `x-default` is optional but a sensible fallback.
- **The links at the bottom** put each city page inside a browsable hierarchy (services and a locations index) instead of a dead end.

Since Next.js 15, `params` is a Promise, so it's awaited.

## Step 3: Add the Pages to the Sitemap

```ts
// src/app/sitemap.ts
import type { MetadataRoute } from 'next'
import { locations } from '@/data/locations'
import { locales } from '@/i18n/config'
import { SITE_URL } from '@/lib/site'

export default function sitemap(): MetadataRoute.Sitemap {
  return locations.flatMap((location) => {
    const url = (lang: string) =>
      `${SITE_URL}/${lang}/locations/${location.slug}`

    return locales.map((lang) => ({
      url: url(lang),
      lastModified: location.updatedAt,
      alternates: {
        languages: Object.fromEntries(locales.map((l) => [l, url(l)])),
      },
      images: [`${SITE_URL}${location.image.src}`],
    }))
  })
}
```

Two things differ from most sitemap examples, including the [multilingual sitemaps post]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %}) in this series:

- **`lastModified` comes from the content, not `new Date()`.** Google uses `lastmod` only "if it's consistently and verifiably accurate" ([Google](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)). A build-time date that changes on every deploy teaches it to ignore yours.
- **No `priority` or `changeFrequency`.** Google says it ignores both.

## Step 4: LocalBusiness Markup, Only With a Real Address

Google's LocalBusiness markup requires a `name` and an `address`, and the address is "the physical location of the business" ([Google](https://developers.google.com/search/docs/appearance/structured-data/local-business)).

If you have an office in that city, add it with the `JsonLd` component from the [schema markup post]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-schema-markup-guide %}). If you only serve the city remotely, leave it out. An address you don't have isn't "a true representation of the page content".

## Measure It

After the pages have been live for a few weeks, check them in Search Console:

1. **Performance:** filter by page containing `/locations/`, then look at the **Queries** tab. Searches that include the city name show the pages are doing their job.
2. **Pages (indexing):** look for location URLs under "Duplicate without user-selected canonical", which means Google treats the page as a copy of another one. "Crawled - currently not indexed" means Google saw the page but chose not to index it. On near-identical city pages, that usually points to the same problem.

If several city pages land there, merge them into one "Areas we serve" page rather than rewording them.

---

**Full SEO Series for Next.js:**
1. [The Robots.txt Mistake That Cost Me Visitors]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})
2. [Building Dynamic Multilingual Sitemaps in Next.js]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %})
3. [Meta Tags That Actually Convert Clicks]({{ site.baseurl }}{% post_url 2025-12-15-nextjs-meta-tags-that-convert %})
4. [Next.js Schema Markup: 5 Types That Still Work]({{ site.baseurl }}{% post_url 2026-10-15-nextjs-schema-markup-guide %})
5. Next.js Location Pages Without Doorway Spam (you are here)

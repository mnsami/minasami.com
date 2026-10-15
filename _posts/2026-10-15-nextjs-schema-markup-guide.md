---
layout: post
title: "Next.js Schema Markup: 5 Types That Still Work"
description: "Google retired FAQ and HowTo rich results. Here are the 5 schema types that still earn rich results in 2026, with safe JSON-LD code for the Next.js App Router."
date: 2026-10-15
categories: [web-development]
tags: [nextjs, seo, schema-markup, rich-snippets, structured-data]
author: Mina Sami
---

The first draft of this post led with FAQ rich results: the expandable questions under a search result. Before I got round to publishing it, Google switched them off for every site.

That's the most useful thing to know about schema markup in 2026: the list of rich results Google shows keeps changing. So this post covers only the types Google still supports today, and the code to add them safely in a Next.js App Router project.

## What Schema Markup Does (and Doesn't Do)

Schema markup, or structured data, is a block of JSON-LD that tells search engines what a page is about: a product with a price, an article with an author and a date, an organization with a logo.

Two things to keep in mind:

- **It makes a page eligible for a rich result, nothing more.** Google's own policy says markup "*enables* a feature to be present, it does not *guarantee* that it will be present" ([Google](https://developers.google.com/search/docs/appearance/structured-data/sd-policies)).
- **It isn't a shortcut to higher rankings.** It helps Google understand the page and decide how to show it. Treat any promised ranking boost with suspicion.

## The 5 Types Worth Adding

For a typical company site, shop or blog built with Next.js, these five are the ones Google still supports and that most sites can actually use:

| Type | What it can change in Google | Where it goes |
| --- | --- | --- |
| **Organization** | Which logo Google shows for you, and details in your knowledge panel | Homepage (or About page) |
| **WebSite** | The site name shown above your results | Homepage |
| **BreadcrumbList** | The page path shown in results (desktop) | Every inner page |
| **Product** | Price and availability under the result | Single product pages only |
| **Article / BlogPosting** | Better title, image and date information | Article and blog post pages |

Sources: [Organization/logo](https://developers.google.com/search/docs/appearance/structured-data/logo), [site names](https://developers.google.com/search/docs/appearance/site-names), [breadcrumbs](https://developers.google.com/search/docs/appearance/structured-data/breadcrumb), [product snippets](https://developers.google.com/search/docs/appearance/structured-data/product-snippet), [articles](https://developers.google.com/search/docs/appearance/structured-data/article).

## Step 1: One Safe JSON-LD Component

Next.js recommends rendering JSON-LD as a plain `<script>` tag in your `layout.tsx` or `page.tsx` ([Next.js docs](https://nextjs.org/docs/app/guides/json-ld)). Most examples online, including my first draft, stop at `JSON.stringify`. That's a security hole: `JSON.stringify` doesn't escape `<`, so a product name like `</script><script>…` coming from your CMS can break out of the tag and run as code.

The fix is one `.replace()`. Put it in a single component and use that everywhere:

{% raw %}
```tsx
// src/components/seo/json-ld.tsx
import type { Thing, WithContext } from 'schema-dts'

export function JsonLd({ data }: { data: WithContext<Thing> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        // JSON.stringify doesn't escape "<", so a value like
        // "</script><script>..." could break out of the tag (XSS).
        __html: JSON.stringify(data).replace(/</g, '\\u003c'),
      }}
    />
  )
}
```
{% endraw %}

`<` is still a valid `<` inside JSON, so search engines read the same data.

The types come from [`schema-dts`](https://www.npmjs.com/package/schema-dts) (`npm i -D schema-dts`), which Next.js also suggests. It catches typos like `pirce` or a misspelled `@type` at build time instead of in Search Console weeks later.

## Step 2: Organization and WebSite on the Homepage

Google only needs these on the homepage, not on every page. Use `@id` so other pages can point to the same organization instead of repeating it:

{% raw %}
```tsx
// src/app/[lang]/page.tsx
import type { Organization, WebSite, WithContext } from 'schema-dts'
import { JsonLd } from '@/components/seo/json-ld'
import { SITE_NAME, SITE_URL } from '@/lib/site'

export default async function HomePage({
  params,
}: {
  params: Promise<{ lang: string }>
}) {
  const { lang } = await params

  const organization: WithContext<Organization> = {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    '@id': `${SITE_URL}/#organization`,
    name: SITE_NAME,
    url: SITE_URL,
    logo: `${SITE_URL}/logo-512.png`,
    sameAs: [
      'https://www.linkedin.com/company/your-company',
      'https://github.com/your-company',
    ],
  }

  const website: WithContext<WebSite> = {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: SITE_NAME,
    alternateName: ['example.com'],
    url: `${SITE_URL}/`,
    inLanguage: lang,
  }

  return (
    <>
      <JsonLd data={organization} />
      <JsonLd data={website} />
      <main>{/* homepage content */}</main>
    </>
  )
}
```
{% endraw %}

A few details that matter:

- The logo must be at least 112×112 px, crawlable, and look right on a white background.
- `WebSite.name` is your preferred site name. Google picks one automatically, so add `alternateName` as a fallback, with your domain last.
- Since Next.js 15, `params` is a Promise, so `await` it.

## Step 3: Breadcrumbs on Inner Pages

A small helper keeps breadcrumbs consistent across page types:

```ts
// src/lib/breadcrumbs.ts
import type { BreadcrumbList, WithContext } from 'schema-dts'

export function breadcrumbList(
  crumbs: { name: string; url: string }[],
): WithContext<BreadcrumbList> {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: crumbs.map((crumb, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: crumb.name,
      item: crumb.url,
    })),
  }
}
```

Use absolute URLs, and give each trail at least two items. Google currently shows breadcrumbs on desktop results.

## Step 4: Product, on Product Pages Only

Product snippets are for a page about **one** product. Category and listing pages ("all shoes") aren't eligible, so don't add Product markup there. Google requires `name` plus at least one of `offers`, `review` or `aggregateRating`:

{% raw %}
```tsx
// src/app/[lang]/products/[slug]/page.tsx
import type { Product, WithContext } from 'schema-dts'
import { JsonLd } from '@/components/seo/json-ld'
import { breadcrumbList } from '@/lib/breadcrumbs'
import { getProduct } from '@/lib/data'
import { SITE_URL } from '@/lib/site'

export default async function ProductPage({
  params,
}: {
  params: Promise<{ lang: string; slug: string }>
}) {
  const { lang, slug } = await params
  const product = await getProduct(slug)
  const url = `${SITE_URL}/${lang}/products/${slug}`

  const productLd: WithContext<Product> = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.title,
    description: product.description,
    image: `${SITE_URL}${product.image}`,
    url,
    offers: {
      '@type': 'Offer',
      price: product.price,
      priceCurrency: 'EUR',
      availability: product.inStock
        ? 'https://schema.org/InStock'
        : 'https://schema.org/OutOfStock',
      url,
    },
  }

  return (
    <>
      <JsonLd data={productLd} />
      <JsonLd
        data={breadcrumbList([
          { name: 'Home', url: `${SITE_URL}/${lang}` },
          { name: 'Products', url: `${SITE_URL}/${lang}/products` },
          { name: product.title, url },
        ])}
      />
      <main>{/* product content */}</main>
    </>
  )
}
```
{% endraw %}

Take `availability` from your real stock data. Hard-coding `InStock` breaks Google's rule that structured data "must be a true representation of the page content" ([Google](https://developers.google.com/search/docs/appearance/structured-data/sd-policies)).

## Step 5: Article on Blog Posts

Article markup isn't only for news sites. Google supports it for news, sports **and blog** articles, and it "can help Google understand more about the web page and show better title text, images, and date information". There are no required properties:

{% raw %}
```tsx
// src/app/[lang]/blog/[slug]/page.tsx
import type { BlogPosting, WithContext } from 'schema-dts'
import { JsonLd } from '@/components/seo/json-ld'
import { getPost } from '@/lib/data'
import { SITE_URL } from '@/lib/site'

export default async function BlogPostPage({
  params,
}: {
  params: Promise<{ lang: string; slug: string }>
}) {
  const { lang, slug } = await params
  const post = await getPost(slug)

  const article: WithContext<BlogPosting> = {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: post.title,
    image: [`${SITE_URL}${post.image}`],
    datePublished: post.publishedAt,
    dateModified: post.updatedAt,
    inLanguage: lang,
    author: {
      '@type': 'Person',
      name: 'Your Name',
      url: `${SITE_URL}/about`,
    },
    publisher: { '@id': `${SITE_URL}/#organization` },
  }

  return (
    <>
      <JsonLd data={article} />
      <article>{/* post content */}</article>
    </>
  )
}
```
{% endraw %}

Use full ISO 8601 dates with a timezone where you can, and only change `dateModified` when the content really changes.

## What Stopped Working (Skip These)

If you're following an older tutorial, these are the ones to drop:

- **FAQ rich results:** limited to well-known government and health sites since August 2023, and no longer shown at all since 7 May 2026 ([Google](https://developers.google.com/search/docs/appearance/structured-data/faqpage)). `FAQPage` markup no longer changes how your pages appear in Google.
- **HowTo rich results:** no longer in Google's [list of supported features](https://developers.google.com/search/docs/appearance/structured-data/search-gallery).
- **ItemList on listing pages:** a carousel only works for courses, movies, recipes and restaurants ([Google](https://developers.google.com/search/docs/appearance/structured-data/carousel)). A generic list of products or links gets no rich result.
- **Review stars on your own business:** reviews a business controls about itself, including embedded widgets, aren't eligible for star snippets on LocalBusiness or Organization markup ([Google](https://developers.google.com/search/docs/appearance/structured-data/review-snippet)).

## Test Before You Deploy

1. Paste the page's URL or HTML into the [Rich Results Test](https://search.google.com/test/rich-results). It shows which rich results the page is eligible for, and any errors.
2. Check the full schema.org vocabulary, including types Google doesn't use, with the [Schema Markup Validator](https://validator.schema.org/).
3. After deploying, watch the rich result reports in Search Console (under **Enhancements**, and **Shopping** for products). A page with a critical issue is marked invalid and isn't eligible for that rich result.

## Measure It on Your Own Site

You'll find plenty of posts promising a fixed CTR jump from schema markup. I'm not going to give you a number, because the effect depends on your queries, your competitors, and whether Google decides to show the rich result at all.

Measure it instead:

1. In Search Console → **Performance**, filter to the pages you added markup to.
2. Compare the 28 days before deployment with the 28 days after. Four full weeks on each side keep weekday patterns out of the comparison.
3. Look at CTR together with average position. If position moved, the CTR change isn't only the markup.

That gives you a number you can trust for your own site, which beats one from someone else's.

---

**Full SEO Series for Next.js:**
1. [The Robots.txt Mistake That Cost Me Visitors]({{ site.baseurl }}{% post_url 2025-12-05-nextjs-seo-robots-txt-mistake %})
2. [Building Dynamic Multilingual Sitemaps in Next.js]({{ site.baseurl }}{% post_url 2025-12-08-nextjs-dynamic-multilingual-sitemaps %})
3. [Meta Tags That Actually Convert Clicks]({{ site.baseurl }}{% post_url 2025-12-15-nextjs-meta-tags-that-convert %})
4. Next.js Schema Markup: 5 Types That Still Work (you are here)

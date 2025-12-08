---
layout: post
title: "Next.js i18n Guide: Set Up Internationalization with next-intl"
description: "Learn how to set up internationalization in Next.js using next-intl. Complete step-by-step guide with code examples, SEO best practices, and TypeScript support."
date: 2025-12-04
categories: [web-development]
tags: [nextjs, i18n, internationalization, tutorial]
author: Mina Sami
---

Internationalization (i18n) is essential for building modern web applications that serve a global audience. In this comprehensive guide, we'll walk through setting up a complete i18n solution for a Next.js application using `next-intl`, one of the most popular and feature-rich internationalization libraries for Next.js.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Project Structure](#project-structure)
4. [Configuration](#configuration)
5. [Setting Up Routes](#setting-up-routes)
6. [Creating Translation Files](#creating-translation-files)
7. [Using Translations in Components](#using-translations-in-components)
8. [Building a Language Switcher](#building-a-language-switcher)
9. [SEO Considerations](#seo-considerations)
10. [Best Practices](#best-practices)

## Prerequisites

Before we begin, make sure you have:

- A Next.js project (App Router) set up
- Node.js 18+ installed
- Basic knowledge of React and TypeScript

## Installation

First, install the `next-intl` package:

```bash
npm install next-intl
# or
yarn add next-intl
# or
pnpm add next-intl
```

## Project Structure

Let's organize our i18n setup with a clear structure:

```
your-project/
├── src/
│   ├── app/
│   │   ├── [locale]/
│   │   │   ├── layout.tsx
│   │   │   └── page.tsx
│   │   └── layout.tsx
│   └── i18n/
│       ├── config.ts
│       └── request.ts
├── messages/
│   ├── en.json
│   └── nl.json
└── next.config.ts
```

## Configuration

### Step 1: Create i18n Configuration

Create `src/i18n/config.ts` to define your supported locales:

```typescript
export const locales = ['en', 'nl'] as const;
export type Locale = (typeof locales)[number];

export const defaultLocale: Locale = 'en';

export const localeNames: Record<Locale, string> = {
  en: 'English',
  nl: 'Nederlands',
};
```

### Step 2: Create Request Configuration

Create `src/i18n/request.ts` to configure how `next-intl` loads messages:

```typescript
import { getRequestConfig } from 'next-intl/server';
import { locales, type Locale } from './config';

export default getRequestConfig(async ({ requestLocale }) => {
  // This typically corresponds to the `[locale]` segment
  let locale = await requestLocale;

  // Ensure that a valid locale is used
  if (!locale || !locales.includes(locale as Locale)) {
    locale = 'en';
  }

  return {
    locale,
    messages: (await import(`../../messages/${locale}.json`)).default,
  };
});
```

### Step 3: Update Next.js Config

Modify `next.config.ts` to integrate `next-intl`:

```typescript
import type { NextConfig } from "next";
import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./src/i18n/request.ts');

const nextConfig: NextConfig = {
  // Your existing config...
};

export default withNextIntl(nextConfig);
```

## Setting Up Routes

### Root Layout

Create `src/app/layout.tsx` as a minimal root layout:

```typescript
import type React from "react"
import "@/assets/styles/globals.css"

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return children
}
```

### Locale Layout

Create `src/app/[locale]/layout.tsx` to handle locale-specific layouts:

```typescript
import type React from "react";
import { NextIntlClientProvider } from 'next-intl';
import { getMessages } from 'next-intl/server';

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const messages = await getMessages();

  return (
    <html lang={locale} suppressHydrationWarning>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
```

### Generate Metadata with Translations

You can also generate locale-aware metadata:

```typescript
import { getTranslations } from 'next-intl/server';

export async function generateMetadata({
  params
}: {
  params: Promise<{ locale: string }>
}) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'metadata' });

  return {
    title: t('title'),
    description: t('description'),
    alternates: {
      canonical: `${baseUrl}/${locale}`,
      languages: {
        'en': `${baseUrl}/en`,
        'nl': `${baseUrl}/nl`,
        'x-default': `${baseUrl}/en`,
      },
    },
  };
}
```

## Creating Translation Files

Create JSON files for each locale in the `messages/` directory.

### English (`messages/en.json`)

```json
{
  "metadata": {
    "title": "My Website",
    "description": "Welcome to my website"
  },
  "nav": {
    "home": "Home",
    "about": "About",
    "contact": "Contact"
  },
  "hero": {
    "title": "Welcome",
    "subtitle": "Building amazing experiences"
  }
}
```

### Dutch (`messages/nl.json`)

```json
{
  "metadata": {
    "title": "Mijn Website",
    "description": "Welkom op mijn website"
  },
  "nav": {
    "home": "Home",
    "about": "Over Ons",
    "contact": "Contact"
  },
  "hero": {
    "title": "Welkom",
    "subtitle": "Geweldige ervaringen bouwen"
  }
}
```

## Using Translations in Components

### Server Components

In server components, use `getTranslations`:

```typescript
import { getTranslations } from 'next-intl/server';

export default async function Page() {
  const t = await getTranslations('hero');
  
  return (
    <div>
      <h1>{t('title')}</h1>
      <p>{t('subtitle')}</p>
    </div>
  );
}
```

### Client Components

In client components, use the `useTranslations` hook:

```typescript
'use client';

import { useTranslations } from 'next-intl';

export function Hero() {
  const t = useTranslations('hero');
  
  return (
    <div>
      <h1>{t('title')}</h1>
      <p>{t('subtitle')}</p>
    </div>
  );
}
```

### Using Namespaces

You can organize translations into namespaces:

```typescript
// Access nested translations
const t = useTranslations('nav');
const homeLabel = t('home'); // Gets "nav.home"

// Or use a specific namespace
const tHero = useTranslations('hero');
const title = tHero('title'); // Gets "hero.title"
```

### Dynamic Translations with Parameters

You can pass parameters to translations:

```json
{
  "footer": {
    "copyright": "© {year} My Company. All rights reserved."
  }
}
```

```typescript
const t = useTranslations('footer');
const currentYear = new Date().getFullYear();
const copyright = t('copyright', { year: currentYear });
```

## Building a Language Switcher

Create a language switcher component to allow users to switch between locales:

```typescript
'use client';

import { useParams, usePathname } from "next/navigation";
import Link from "next/link";
import { locales, localeNames, type Locale } from "@/i18n/config";

export function LanguageSwitcher() {
  const pathname = usePathname();
  const params = useParams();
  const currentLocale = (params?.locale as Locale) || "en";

  // Get the path without the locale prefix
  const pathWithoutLocale = pathname?.replace(`/${currentLocale}`, "") || "/";

  return (
    <div className="flex items-center gap-2">
      {locales.map((locale) => (
        <Link 
          key={locale} 
          href={`/${locale}${pathWithoutLocale}`}
          className={currentLocale === locale ? 'font-bold' : ''}
        >
          {localeNames[locale]}
        </Link>
      ))}
    </div>
  );
}
```

## SEO Considerations

### 1. Language Alternates

Add language alternates to your metadata:

```typescript
export async function generateMetadata({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  const baseUrl = 'https://yoursite.com';

  return {
    alternates: {
      canonical: `${baseUrl}/${locale}`,
      languages: {
        'en': `${baseUrl}/en`,
        'nl': `${baseUrl}/nl`,
        'x-default': `${baseUrl}/en`,
      },
    },
  };
}
```

### 2. HTML Lang Attribute

Make sure to set the `lang` attribute in your HTML:

```typescript
<html lang={locale}>
```

### 3. Structured Data

Consider adding locale-specific structured data for better SEO.

## Best Practices

### 1. Organize Translation Files

Keep your translation files organized by feature or page:

```json
{
  "common": { ... },
  "homepage": { ... },
  "about": { ... },
  "contact": { ... }
}
```

### 2. Use TypeScript for Type Safety

You can create types for your translations:

```typescript
type Messages = typeof import('./messages/en.json');
declare global {
  interface IntlMessages extends Messages {}
}
```

### 3. Handle Missing Translations

`next-intl` will show the translation key if a translation is missing. In development, you might want to log warnings:

```typescript
// In your request.ts
return {
  locale,
  messages: (await import(`../../messages/${locale}.json`)).default,
  onError(error) {
    if (process.env.NODE_ENV === 'development') {
      console.error('Translation error:', error);
    }
  },
};
```

### 4. Pluralization

`next-intl` supports pluralization:

```json
{
  "items": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

```typescript
const t = useTranslations();
const count = 5;
const text = t('items', { count }); // "5 items"
```

### 5. Date and Number Formatting

Use Next.js's built-in formatting:

```typescript
import { useFormatter } from 'next-intl';

function Component() {
  const format = useFormatter();
  const date = new Date();
  
  return (
    <div>
      <p>{format.dateTime(date, { dateStyle: 'long' })}</p>
      <p>{format.number(1234.56, { style: 'currency', currency: 'USD' })}</p>
    </div>
  );
}
```

### 6. Middleware for Locale Detection

You can add middleware to detect user locale from headers:

```typescript
// middleware.ts
import createMiddleware from 'next-intl/middleware';
import { locales, defaultLocale } from './src/i18n/config';

export default createMiddleware({
  locales,
  defaultLocale,
  localePrefix: 'always' // or 'as-needed'
});

export const config = {
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)']
};
```

## Common Pitfalls

1. **Forgetting to wrap client components**: Make sure `NextIntlClientProvider` wraps your app in the locale layout.

2. **Incorrect path structure**: Ensure your routes are under `[locale]` directory.

3. **Missing translation keys**: Always provide translations for all keys in all locales.

4. **Not handling locale fallback**: Always provide a fallback to your default locale.

## Conclusion

Setting up internationalization in Next.js with `next-intl` provides a robust, type-safe, and SEO-friendly solution for multi-language applications. By following this guide, you'll have a solid foundation for building applications that serve a global audience.

Remember to:
- Keep translation files organized
- Test all locales thoroughly
- Consider SEO implications
- Provide fallbacks for missing translations
- Use TypeScript for type safety

Happy coding! 🌍

## Resources

- [next-intl Documentation](https://next-intl.dev/)
- [Next.js Internationalization](https://nextjs.org/docs/app/building-your-application/routing/internationalization)
- [MDN: Internationalization](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl)

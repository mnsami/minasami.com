---
layout: post
title:  "Tips & tricks: Sync VS-Code extensions list, editor settings and add it to source control."
categories: [developer-productivity]
tags: vscode ide extensions automation developer-tools productivity workflow
description: "Sync VS Code settings and extensions across multiple machines using Settings Sync. Complete setup guide with cloud backup and restore."
---

As a back-end developer, PHP focused, I use <a href="https://www.jetbrains.com/phpstorm/" target="_blank" rel="noopener">PhpStorm</a> as my favorite IDE, because of all its powerful features list, beside that I have my own personal preferred UI customization settings that I apply like color theme, font and code templates. And since it is my personal customization, I use a PhpStorm feature to either sync the settings to my JetBrains account or you can export them and you manage that yourself, and I do that because I have invested a lot of time, finding the perfect font, theme color and settings to increase my productivity with code templates adjustments and make it comfortable for myself and eye since I spend on it a lot of time.

But for all my front-end and DevOps projects (like [building React SPAs]({{ site.baseurl }}{% post_url 2021-06-23-part-1-setup-reactjs-symfony-app-with-hotloading %}) or [automating workflows with Makefiles]({{ site.baseurl }}{% post_url 2021-06-17-use-of-makefile-in-your-projects %})), I use <a href="https://code.visualstudio.com/" target="_blank" rel="noopener">VS-Code</a> as the extensions to manage such projects are more powerful, but then after spending and investing some time to make it feel like what I wanted it to be, I started thinking okay, I have done so many customization, but I need to save those settings somewhere, this is where I found that VS-Code doesn't support such a thing natively yet.

After searching for a way on how to achieve that goal, I found this simple but yet powerful extension where you can find it in the market place which is called <a href="https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync" target="_blank" rel="noopener">Settings Sync</a>, this awesome extension enables you to not only sync your UI customization settings but also installed extensions, which in my opinion very handy so that you don't have to do that manually, and as mentioned on the extension page, there is a whole list of items that are synced as well i.e.:

<blockquote class="blockquote">
  <p class="mb-0">
    All extensions and complete User Folder that Contains
    <ol>
        <li>Settings File</li>
        <li>Keybinding File</li>
        <li>Launch File</li>
        <li>Snippets Folder</li>
        <li>VSCode Extensions & Extensions Configurations</li>
        <li>Workspaces Folder</li>
    </ol>
  </p>
</blockquote>
{:.section}

### How does the extension work?

The extension requires you have:
1. <a href="https://github.com/" target="_blank" rel="noopener">Github</a> account.
2. Create a github access token for the plugin.
3. Create `Gist` for the extension and provide its `Id` in the config to be used to upload your settings.

Next, you configure the plugin and supply the `GistId` and your github access token, restart VS-Code then it will work out of the box to upload existing settings and/or download already existing ones.

You can find more about the setup of the extension on its page <a href="https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync" target="_blank" rel="noopener">Settings Sync page</a>.
{:.section}

### Why use this plugin?

Personally, beside of having everything automatically synced when you change any settings in your VS-Code,I see an added benefit which is that you have all your extensions list and settings source controlled with a different `commit` for every change you make and that gives you the added benefit of when you mess up something, you can rollback.

This kind of automation thinking - where you eliminate repetitive setup work - is the same mindset that drives me to use [AI tools to amplify my engineering effectiveness]({{ site.baseurl }}{% post_url 2025-11-27-how-ai-became-the-most-reliable-partner-in-my-engineering-career %}). Whether it's syncing settings or automating code reviews, the goal is to focus on solving real problems, not fighting tooling.

<b>NOTE:</b> At the time of writing this blog, I found that VS-Code team are working on <a href="https://code.visualstudio.com/docs/editor/settings-sync" target="_blank" rel="noopener">syncing the settings</a> natively but currently it is only available for the daily builds as <a href="https://code.visualstudio.com/insiders/" target="_blank" rel="noopener">insiders edition</a>.
{:.section}

---

**Looking to build better development workflows?** I offer [mentorship](/mentorship/) for engineers who want to level up their productivity and automation skills.

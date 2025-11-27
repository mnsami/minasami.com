---
layout: post
title: "How AI Became My Best Brainstorming Partner: Lessons from Building Real Solutions"
date: 2025-11-27
author: Mina Sami
categories: [ai, development]
tags: ai automation
description: "Discover how AI code assistants changed my problem-solving approach. Real examples of debugging silent failures, choosing the right tools, and refactoring messy code through collaborative AI sessions."
---

<img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/ai-collab.png" | relative_url }}" alt="collaborating with ai" width="310" height="235" />

I used to think AI code assistants were fancy autocomplete. Type a comment, get some boilerplate, move on. That lasted about a week.

Then I hit a bug that had no error message, no Stack Overflow match, and no obvious cause. My bash script was silently dying after backing up one database instead of two. No logs. No failures. Just... nothing.

That's when I realized: **this isn't about getting answers faster. It's about having a thought partner who can see what you're missing.**

Six months later, I'm using AI for everything from debugging silent failures to validating technical architecture decisions to making code production-ready. Not because it writes perfect code, but because it helps me **think through problems I wouldn't solve the same way on my own.**

Here's what I've learned about the patterns that actually work.
{:.section}

## Pattern 1: The "What Am I Not Seeing?" Debug Session

**The situation:** That database backup script. Worked perfectly for one database, completely ignored the second. Zero errors in logs.

**Old approach:** Google "bash script stops in loop," Stack Overflow → 47 results, none matching my exact problem, spend an hour trying random fixes.

<img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/ai-debug.png" | relative_url }}" alt="what am i not seeing?" width="310" height="235" />

**AI approach:**
```
Me: [paste code] "This only backs up the first database"
Claude: "Let me look at your set -euo pipefail..."
```

Within 10 minutes: **Found it.** The script was dying on a post-increment arithmetic expression that returned zero, which bash interprets as a failure with `set -e`.

**The key insight:** Claude didn't just tell me "set -e is tricky" - it looked at MY specific code and said "your problem is likely here, and here's why."

**What I learned:**
- Show the actual code, not a minimal example
- Describe the symptom, not what you think the problem is
- When the first suggestion doesn't work, say why - the iteration is where the value is

**Time saved:** ~2 hours of trial-and-error debugging
{:.section}

## Pattern 2: The "Which Tool Actually Fits?" Architecture Decision

**The situation:** Building a GitLab CI/CD pipeline that checks code coverage for changed files in merge requests. Need to parse XML, match file paths, and fail the pipeline if coverage drops below 80%.

**Old approach:** "Everyone uses bash for CI/CD scripts, so I should too." Start writing bash, fight with XML parsing, struggle with quote escaping, spend hours on path matching edge cases.

**With AI:** Laid out my specific situation—what I was trying to do, where I was struggling, what constraints I had. Then asked: "Given these specific pain points, should I continue or switch?"

The AI didn't just say "use X instead." It walked through my exact problems and showed how they'd look in both tools. Not theoretical comparisons—but my specific use case in each approach.

<img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/ai-choose-tool.png" | relative_url }}" alt="Which Tool Actually Fits?" width="310" height="235" />

**The result:** Switched tools. The new version was cleaner, easier to maintain, and actually solved my problems. What would've been 200 lines of workarounds became 80 lines of straightforward code.

**The insight:** "Industry standard" doesn't mean "right for your problem." Sometimes the best decision is to change direction, and AI can help you see that objectively.

**Time saved:** 6-8 hours of fighting with the wrong tool, plus future maintenance headaches.
{:.section}

## Pattern 3: The "Clean Up This Mess" Refactoring Session

<img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/ai-refactor.png" | relative_url }}" alt="Clean Up This Mess" width="310" height="235" />

**The situation:** API with messy error handling. Same error-checking pattern copy-pasted across 20+ different places. Every time I added a new feature, I had to update all of them. Classic technical debt.

**Old me:** "This works. I'll clean it up later." (Narrator: He never cleaned it up.)

**With AI:** "I have this same pattern repeated everywhere. How can I do this better?"
The AI didn't just say "extract it into a function." It recognized the underlying code smell and suggested a pattern that would:

- Eliminate all the repetition.
- Make the error responses consistent.
- Put all the error handling logic in one place.
- Make future changes way easier.

**The result:** Deleted 200+ lines of redundant code. Now when I need to change error handling, I change it once, not 20+ times.

**The insight:** AI is surprisingly good at recognizing code smells and suggesting cleaner patterns. You just have to show it the mess and ask.

**Time saved:** About 4 hours of refactoring, plus eliminated a huge maintenance burden.
{:.section}

## The Mindset Shift That Changed Everything

After months of this, I realized: **I'm not using AI as a search engine. I'm using it as a thinking partner.**

### What AI is really good at:

1. **Seeing patterns you're too close to see**
   - "Your problem is probably in the error handling, not the logic"
   - "You're repeating this pattern 20 times - let's extract it"

2. **Asking the questions you forgot to ask**
   - "What's your deployment environment?"
   - "Have you considered edge case X?"
   - "Why did you choose bash over Python?"

3. **Doing the comparison work**
   - Technology comparisons with YOUR constraints
   - Before/after code quality analysis
   - Tradeoff discussions specific to your context

4. **Providing context-aware suggestions**
   - Not "here's how to do X"
   - But "here's how to do X given your constraints Y and Z"

### What AI is not good at:

1. **Making decisions for you**
   - It'll give options and tradeoffs
   - You still choose based on your priorities

2. **Knowing your business context**
   - You have to provide constraints
   - "Best practice" means nothing without context

3. **Writing production code end-to-end**
   - Great for snippets, patterns, starting points
   - You still need to understand, test, and maintain it
{:.section}

## The Three Questions I Always Ask

After dozens of these sessions, I've developed a framework:

### 1. "What am I missing?"
Use for: Debugging, code review, finding edge cases  
Example: "This should work but doesn't - what am I not seeing?"

### 2. "What are my options?"
Use for: Tool selection, architecture decisions, approach comparison  
Example: "Should I continue with bash or switch to Python for this CI script?"

### 3. "How can I clean this up?"
Use for: Refactoring, pattern extraction, code quality improvements  
Example: "I have this repeated 20 times - suggest a better pattern"
{:.section}

## Practical Tips for Getting Started

### Start Small
Pick ONE type of problem. I started with debugging. Now I use it for architecture decisions and refactoring too.

### Provide Context
Don't: "Should I use bash or Python?"  
Do: "I'm building a GitLab CI coverage checker. Here's my bash script [paste]. I'm struggling with XML parsing and path matching. Should I continue with bash or switch to Python?"

### Iterate, Don't Copy-Paste
The value is in the conversation, not the first answer.
- First suggestion doesn't work? Say why
- Need more explanation? Ask for it
- Want to understand the why? Request deeper explanation

### Test Everything
AI suggestions are starting points, not gospel. Test in your environment with your constraints.

### Keep a Learning Log
I save important debugging sessions and refactoring discussions. They're reference material for similar future problems.
{:.section}

## What Changed for Me

**Before AI collaboration:**
- Debugging: Trial and error until something worked
- Tool selection: Use what everyone else uses
- Code quality: "I'll clean it up later" (never do)
- Refactoring: Too time-consuming, skip it

**After AI collaboration:**
- Debugging: Systematic approach with targeted experiments
- Tool selection: Choose based on specific requirements, not popularity
- Code quality: Continuous improvement through pattern recognition
- Refactoring: Regular discussions about cleaner approaches

**Time saved monthly:** 15-20 hours  
**Code quality improvement:** 200+ lines of redundant code eliminated  
**Maintenance burden:** Significantly reduced with cleaner patterns
{:.section}

## The Future I See

We're moving from:
- "Search for solutions" → "Collaborate on solutions"
- "Use what's popular" → "Choose what fits your constraints"
- "Copy-paste from Stack Overflow" → "Discuss tradeoffs with context"
- "Technical debt accumulates" → "Regular refactoring conversations"

But the fundamentals don't change: **You still need to think, decide, and take ownership.** AI just makes it easier to think through more possibilities, faster.

That database backup script is now running in production, reliably backing up all databases every night. It took 2 hours of back-and-forth debugging with Claude, but I understand bash error handling now in a way I never would from reading docs.

**None of these outcomes came from AI giving me "the answer."** They came from AI helping me ask better questions, see blind spots, and think through tradeoffs I wouldn't have considered on my own.
{:.section}

## Your Turn

Are you using AI in your development workflow? What patterns have worked for you? What hasn't?

I'd especially love to hear:
- Unexpected use cases you've found
- Moments where AI helped you see something you missed
- Times when it led you astray (we learn from failures too)

Drop a comment or reach out - I'm always curious how other developers are approaching this.

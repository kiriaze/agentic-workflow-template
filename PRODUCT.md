# PRODUCT.md

Design context for [Project Name]. Read before any UI work. Update via `impeccable teach` once the product vision is settled.

---

## Product purpose

> Who uses this? What are they trying to do? What frustration does this product remove?
> Describe 1–2 distinct user archetypes and what each needs. 3–6 sentences.

[Fill in: describe who the product serves, what job they're doing, and what pain they currently have]

---

## Register

> How formal or casual should the UI feel? This sets the tone for all copy, empty states, and error messages.

[Fill in: e.g. "Tool-first — the UI serves the work. Clarity and density over expression."]

---

## Visual direction

**Theme:** [e.g. Light-first; dark mode as a full-quality toggle, not an afterthought]

**Roundness:** [e.g. Restrained — 4px–8px corners. Nothing pill-shaped unless it's a badge.]

**Density:** [e.g. Productivity tool — information density is respected; whitespace for rhythm, not decoration]

**Color strategy:** [e.g. Tinted neutrals + one accent at ≤10% of the surface. Color carries meaning, not decoration.]

**Typography:** [e.g. Clean sans-serif, strong hierarchy, secondary metadata muted]

---

## Tone of voice

**In one phrase:** [e.g. "Neutral + warm, never chatty"]

Write clearly. Describe what happened. Be human at emotional moments (empty states, errors, onboarding). Never lecture, over-explain, or use marketing-speak.

**Examples:**

| Situation | Write | Not |
|---|---|---|
| Success | "[Action] saved. [Count] items." | "Great job! Your [thing] has been saved successfully!" |
| Empty state | "No [items] yet. [Action to start]." | "It's looking a little empty in here 👀" |
| Error | "Couldn't [action] — [brief reason]." | "Uh oh! Something went wrong." |

---

## Anti-references

> Products this is NOT trying to look or feel like. Naming the anti-pattern prevents drift.

- [Competitor / product A] — [what to avoid from it, e.g. "flat list of URLs with no hierarchy"]
- [Competitor / product B] — [e.g. "table-based, developer-tool aesthetic, no personality"]

---

## Differentiators

> What does this product do differently? What are the design implications?

- **[Differentiator 1]** — [design implication, e.g. "no backend cost → UI should reinforce user data ownership"]
- **[Differentiator 2]** — [design implication]

---

## Accessibility baseline

- All interactive elements: semantic HTML (`button`, `a`), keyboard navigable, visible focus ring
- Color is never the only indicator of state — always pair with label or icon
- No text below 12px; secondary text muted, not invisible
- Dark mode respects `prefers-color-scheme` as initial default before user sets a preference

---

## What success looks like

> Describe the 30-second test: what should a first-time user be able to do without reading docs?

[Fill in: e.g. "A user opens the dashboard and immediately knows X, Y, and Z. They can [key action] in under 3 seconds without documentation."]

The design test: [fill in a heuristic, e.g. "if someone mistakes this for a native OS app, it passed"]

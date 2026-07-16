# Conventions

## Coding

- **No `any`** — strict TypeScript throughout; prefer explicit interfaces or inferred types.
- **Named exports only** — no default exports for components or hooks; makes refactoring and imports consistent.
- **Named imports over namespace** — always use named imports; never the namespace form (`React.useState`). Exception: packages that only ship a default export.
- **Extract repeated logic** — shared logic goes into a custom hook under `src/hooks/` or a utility in `src/lib/`; don't duplicate across components.
- **No new state libraries** — state lives in custom hooks. Don't introduce Zustand, React Query, etc. without discussion.
- **Component Slot Architecture** – Complex components must use a children prop or named slots (e.g., renderHeader, renderFooter). Avoid passing 20+ props to a single file.
- **Semantic Markup as a Requirement** – No div buttons. All interactive elements must use semantic HTML (button, a, summary) and include appropriate aria- labels.

## Control flow

- **Guard clauses first** — return early on invalid or edge cases instead of nesting the happy path. Prefer flat over deep: two levels of nesting is a smell, three needs a reason.
- **Extract only real complexity** — give branch logic its own named function when it is genuinely complex or reused. There is no mechanical "N lines → extract" trigger — single-use helpers that just relocate code violate "Simplicity first".
- **Ternaries only when simple** — one condition, short arms. Never nested.

## File structure

- **300-line soft ceiling** — aim to keep every file under ~300 lines. Files that grow past this are usually doing too much and should be split. This is a quality signal, not a hard rule.
- **One exported component per file** — each component file exports exactly one component. Private sub-components (used only within that file, never imported elsewhere) may live in the same file if they are small and tightly coupled to the parent. If a sub-component is imported by any other file, it must have its own file.
- **Co-location** — a component that is used in only one place lives next to that place. When it grows to be used in multiple places, extract it to a shared location.

## UI and Design

- **shadcn/ui first** — use primitives from `src/components/ui/` for all interactive elements (dialogs, buttons, tabs, dropdowns). Only build custom if shadcn doesn't cover the case.
- **Tailwind only** — no CSS modules, no `style={{}}` objects unless the value is truly dynamic and can't be expressed as a utility class.
- **4pt spacing scale** — use values from the sequence 4, 8, 12, 16, 24, 32, 48, 64, 96px (`p-1`, `p-2`, `p-3`, `p-4`, `p-6`, `p-8`, etc.). Avoid arbitrary values like `p-[13px]`.
- **The "Token-Only" Styling Rule** – All colors, spacing, and shadows must come from the tailwind.config.js or theme.ts. Never use bg-[#f3f3f3] or p-[11px].
- Tailwind uses CSS variables for theming (`--background`, `--foreground`, etc.) defined in `globals.css`. Dark mode is `class`-based.
- **"Skeleton-First" States** – Every new UI component must include a defined Loading/Skeleton state and an Error Boundary.
- **Visual Regression "Self-Checks"** – After a UI change, run a screenshot comparison test. If the visual diff is >5%, flag for human review.
- Path alias: `@/*` → `src/*`.

## Design context

Design decisions for this project are governed by `PRODUCT.md` (brand, users, principles) and `DESIGN.md` (tokens, typography, components) at the project root.
Read both before doing any significant UI work.

_[fill in: key brand or visual constraints that differ from generic Tailwind defaults — e.g. primary color, radius, motion policy, icon set. Run `impeccable teach` (or equivalent) to generate PRODUCT.md and DESIGN.md, then summarize them here.]_

---

> **This file is AI-updatable.** After choosing a stack or adding a major library, ask Claude: "update docs/conventions.md to reflect the current codebase." It reads the existing code and rewrites this file to match.

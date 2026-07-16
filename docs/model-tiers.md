# Model Tiers, Skill-less Fallbacks & Task Decomposition

`docs/agent-roster.json` names the models; this file says what each tier can safely carry,
how to run every skill step without a Skill tool, and how to scope a task so a mid-tier
model succeeds. The whole workflow must be executable by a model with zero skills — every
mandatory skill step below has a fallback.

---

## Capability tiers

| Tier | Roster models | Safe for |
|---|---|---|
| **Frontier** | Opus-class CC model, top Codex model | Architecture, cross-cutting refactors, unknown-root-cause bugs, novel security analysis |
| **Mid** | Sonnet-class CC model, mid Codex model | Scoped implementation, review, UI work, well-specced bug fixes |
| **Small** | Haiku-class CC model, mini Codex model | Docs/config, research/summarization, mechanical single-file edits; implementation only with a spec meeting the complexity ceiling below |

## Model floors by task type

The floor is the minimum viable tier. Delegating below the floor is a spec bug, not a model
failure — fix the spec or move up a tier.

| Task type (`agent-roster.json`) | Floor | Condition |
|---|---|---|
| `architecture` | Frontier | Never delegate below floor |
| `security_review` | Mid | Frontier when auth or key handling is novel rather than pattern-following |
| `implementation` | Mid | Small allowed only when the spec meets every line of the complexity ceiling |
| `ui_visual` | Mid | `PRODUCT.md`/`DESIGN.md` must be in the task context |
| `docs_config` | Small | — |
| `research` | Small | Read-only |

---

## Skill-less fallbacks

**Cross-harness** skills live in `~/.agents/skills/` and are callable from Claude Code and
(via adapters) Codex-style agents. **CC-only** skills are Claude Code built-ins with no
cross-harness copy. On any harness without the Skill tool, use the fallback column verbatim
as an instruction. Never skip a mandatory step because the skill is unavailable — and never
claim a skill ran when the fallback was used; say which one you used.

| Skill step | Availability | Skill-less fallback |
|---|---|---|
| `using-superpowers` (session start) | CC-only | Skip. Read `HANDOFF.md` + `docs/AGENT_TASKS.md`; state current task and proposed next action. |
| `simplify` (after non-trivial diff) | CC-only | "Review this diff for unnecessary complexity, dead code, speculative abstraction, and duplicated logic. List concrete removals, then apply the safe ones." |
| `security-review` | CC-only | "Review this diff for security issues: secrets or keys in code/config, injection, missing input validation at trust boundaries, authorization gaps, unsafe storage of user data. Report each finding with file:line and severity, then fix or escalate." |
| `claude-api` (AI-provider code) | CC-only | Read the existing provider code before editing. Preserve prompt-caching structure (system blocks, cache-control markers) exactly. Take model IDs and parameters from the official provider docs, never from memory. |
| `test-driven-development` | Cross-harness | Write the failing test first, named after the failure case. Confirm it fails, implement, run the full suite. |
| `impeccable:shape` (design brief) | Cross-harness (Codex adapter ships) | Write a ≤1-page brief from `PRODUCT.md`/`DESIGN.md`: user goal, layout, loading/empty/error states, tokens to use. Confirm it before coding. |
| `impeccable:audit` | Cross-harness | "Audit this UI against PRODUCT.md/DESIGN.md: hierarchy, spacing scale, token-only colors, loading/empty/error states, keyboard access and aria labels. List violations with fixes." |
| `impeccable:harden` | Cross-harness | "Walk every user-visible state of this feature: empty, loading, error, overflow, slow network, revoked permission. List unhandled states and fix them." |
| `frontend-design-system` | Cross-harness | Follow the UI rules in `docs/conventions.md` and the tokens in `DESIGN.md`. |
| `subagent-driven-development` | CC-only orchestration | Dispatch tasks sequentially: one spec file per implementer, review each diff against its spec before dispatching the next. |
| `finishing-a-development-branch` | Cross-harness | Run quality gates, push the branch, open a draft PR with the template body, stop — the human merges. |
| Stack-specific skills (`vercel-*`, `supabase`, …) | Cross-harness | Follow `docs/conventions.md`; if the skill is genuinely unavailable, state that in the PR body instead of guessing. |

---

## Task decomposition for mid/small-tier models

A task delegated at or below Mid tier must satisfy **all** of the following. This generalizes
the Codex scoping rules in `docs/multi-agent.md` to every delegated implementer.

- **Exact file list** — every file to touch, with what changes in each. No "and related files".
- **Do-not-touch list** — explicitly named files and directories.
- **Concrete acceptance criteria** — checkable by running a command or observing a specific behavior, not by judgment.
- **No open-ended exploration** — research happens upstream (Researcher role); its summary is embedded in the spec.
- **Complexity ceiling** — ≤5 files touched, ≤~300 changed lines, ≤3–4 large files of read context, exactly one outcome. One spec file = one session.
- **No new abstractions** — a task that needs a new pattern or abstraction is `architecture` (Frontier floor).

If a task exceeds any line above: split it or raise the tier. Never assume the model copes.
The Codex 272K/220K token ceiling in `docs/multi-agent.md` is the cost budget; this ceiling is
the working-memory budget that keeps mid-tier output reliable.

---

## Validation matrix

Columns reflect the models in `agent-roster.json` as of its `last_verified` date — the roster
governs; refresh this matrix when the roster changes.
Rows: every skill trigger and mandatory workflow step in `AGENTS.md` / `docs/workflow.md`.
**as-is** = works without fallback. **FB** = use the fallback table above. **N/A** = below the
model floor for that step — do not assign. Claude models run inside Claude Code (Skill tool
available); GPT models run in Codex-style harnesses (cross-harness skills only).

| Step | Opus 4.8 | Sonnet 4.6 | Haiku 4.5 | gpt-5.5 | gpt-5.4 | gpt-5.4-mini |
|---|---|---|---|---|---|---|
| Session start (`using-superpowers`) | as-is | as-is | as-is | FB | FB | FB |
| Session brief (hook or direct read of HANDOFF/AGENT_TASKS) | as-is | as-is | as-is | as-is | as-is | as-is |
| Trivial fast path ("No plan needed: <reason>") | as-is | as-is | as-is | as-is | as-is | as-is |
| Plan >3-file change (`planning-template.md`) | as-is | as-is | N/A (floor) | as-is | as-is | N/A (floor) |
| Register task at plan approval (row + spec) | as-is | as-is | as-is | as-is | as-is | as-is |
| Design brief (`impeccable:shape`) | as-is | as-is | N/A (floor) | FB/adapter | FB/adapter | N/A (floor) |
| `test-driven-development` | as-is | as-is | as-is | FB | FB | FB |
| `claude-api` trigger | as-is | as-is | FB (follow fallback text) | FB | FB | FB |
| `frontend-design-system` trigger | as-is | as-is | N/A (floor) | FB | FB | N/A (floor) |
| Quality gates before commit | as-is | as-is | as-is | as-is | as-is | as-is |
| `simplify` post-diff | as-is | as-is | FB (prompt) | FB | FB | FB |
| `impeccable:audit` | as-is | as-is | N/A (floor) | FB/adapter | FB/adapter | N/A (floor) |
| `impeccable:harden` | as-is | as-is | N/A (floor) | FB/adapter | FB/adapter | N/A (floor) |
| `security-review` | as-is | as-is | N/A (floor) | FB | FB | N/A (floor) |
| Orchestrate (`subagent-driven-development`) | as-is | as-is | N/A (floor) | FB | N/A (floor) | N/A (floor) |
| Finish branch (`finishing-a-development-branch`) | as-is | as-is | as-is | FB | FB | FB |
| Draft PR with evidence (template body) | as-is | as-is | as-is | as-is | as-is | as-is |
| Worktree isolation for writes | as-is | as-is | as-is | as-is | as-is | as-is |
| Destructive-action guard (hook + rule) | as-is | as-is | as-is | as-is | as-is | as-is |
| HANDOFF.md update at ~50-60% context | as-is | as-is | as-is | as-is | as-is | as-is |

No unresolved "needs fallback" cells: every FB points at a row in the fallback table above.

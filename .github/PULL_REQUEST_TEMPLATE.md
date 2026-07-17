## Summary

<!-- 1-3 bullet points. What changed and why. -->

-

## Evidence

<!--
Required evidence by change type — delete rows that don't apply:

| Change type         | Required                                                              |
| ------------------- | --------------------------------------------------------------------- |
| Bug fix             | Name the test(s) added + one-line description of what each catches    |
| UI / visual change  | Before screenshot + after screenshot (CC: use preview_screenshot)     |
| New feature (UI)    | Screenshot of golden path; edge cases noted                           |
| New feature (logic) | Test names + example request/response or log output                   |
| Refactor            | "Behaviour unchanged" — test pass count before and after              |
| Docs / config       | Describe what changed and why (no media required)                     |
-->

## UI evidence (required for any change a user can see — delete section otherwise)

<!-- Embed the actual media here. Screenshots for static changes; a GIF (browser tooling /
     gif_creator) or exact reproduction steps for interaction flows.
     Codex-implemented UI tasks: CC captures these during review, before the PR opens. -->

Before:

After:

## Checklist

- [ ] Type-check passes (e.g. `npx tsc --noEmit`)
- [ ] Lint passes (e.g. `npm run lint`)
- [ ] All tests pass (e.g. `npm test`)
- [ ] Bug fix: failing test written before the fix
- [ ] UI change: Before/After media is **embedded in the section above** — do not tick this box without it; a UI PR without media fails review
- [ ] New env var: documented in `docs/environment.md`

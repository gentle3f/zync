# Zync — Prompt-Format Root-Cause Fix Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Root cause being fixed

The 48-card stratified QA proved that model-facing compiler formatting was
leaking internal metadata into generated art.

Examples:
- `VISUAL VARIANT (heat_room):` -> rendered "HEAT ROOM"
- `VISUAL VARIANT (immersion_ritual):` -> rendered "IMMERSION_RITUAL"
- `VISUAL VARIANT` itself -> garbled visible caption

This affected both standard FLUX and Klein, so it is a compiler-format issue,
not primarily a model-routing issue.

## Compiler fix

`tools/card_art/src/buildPromptV1.js`

The compiled image prompt now:
- uses natural prose instead of all-caps section headers;
- does not expose raw archetype ids;
- does not expose raw visual-variant ids;
- does not expose raw subcategory ids;
- keeps those ids only in structured compiler/manifest fields;
- adds a fail-closed regression guard against the old title-like header pattern;
- adds a fail-closed guard against underscore-style internal ids leaking into
  model-facing prompt text.

## Reference-guidance cleanup

The old text-only runner removed reference guidance by string-matching the
`REFERENCE STYLE:` header.

That dependency is now removed.

Reference guidance is no longer part of the compiled prompt at all.
`generateCompiledBatch.js` carries it as a separate structured field and only
appends it for explicit `/edit` model routes.

Therefore:
- standard FLUX text-to-image never sees reference guidance;
- Klein text-to-image never sees reference guidance;
- edit routes still receive it when intentionally used.

## Targeted 8-card validation

Batch:
`tools/card_art/catalog/prompt_format_validation_v1.json`

Output:
`tools/card_art/output/prompt_format_v1/`

Routes intentionally preserve the prior model allocation to isolate the
prompt-format change.

### Standard FLUX — 7

- wellness.sauna
- wellness.hot_springs
- learning.philosophy
- sports.gravel_cycling
- food.yum_cha
- gaming.escape_room_design
- sports.american_football

### Klein negative-prompt — 1

- learning.book_genre.booktok

Estimated first-pass cost:
**US$0.0989**

Commands:

```bash
cd tools/card_art
npm run audit-prompt-format-v1
npm run generate-prompt-format-v1
```

## Validation questions

The audit must confirm:
- 8/8 compile successfully;
- no old compiler header pattern remains;
- no raw archetype / visual_variant / subcategory id appears in model-facing
  prompt text;
- no reference guidance appears on text-only routes.

Visual QA must check:
- no literal compiler labels or ids;
- no hobby-title caption / poster title;
- no card/poster chrome;
- no unrelated readable text;
- hobby remains recognizable;
- no logo/trademark leakage.

Do not auto-reroll failures.

If the four strongest caption-format cases clean up
(sauna, hot springs, philosophy, BookTok), the root-cause fix is validated.

The other four standard-FLUX cards test whether removing the metadata-like
format also reduces ordinary suppression failures before permanently
re-routing them to Klein.

Do not scale to 100 cards until this 8-card gate is reviewed.

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.
Do not expose or commit FAL_KEY.

# Claude Code — Next Task

Read these first:

1. `tools/card_art/specs/ZYNC_CARD_ART_PROMPT_SYSTEM_V1.md`
2. `tools/card_art/specs/global_style_v1.json`
3. `tools/card_art/specs/archetypes_v1.json`
4. `tools/card_art/specs/category_modifiers_v1.json`
5. `tools/card_art/specs/subcategory_modifiers_v1.json`
6. `tools/card_art/specs/qa_rubric_v1.json`

These files are authoritative.

## Task
Convert the current pilot card-art pipeline to this structured V1 prompt architecture.

Do NOT generate 3000 cards yet.

## Required implementation
Create:
- `tools/card_art/catalog/hobby_recipes_v1.jsonl`
- `tools/card_art/catalog/hobby_overrides_v1.json`
- `tools/card_art/catalog/flagship_overrides_v1.json`
- `tools/card_art/generated/compiled_prompts_v1.jsonl`

Update the prompt builder so each final prompt is compiled from:
- global style
- archetype
- category
- subcategory
- hobby recipe
- optional override
- global negatives

Convert the existing 15-card pilot into this schema first.

## Important
Do not collapse the 15 archetypes back into a smaller generic set.
Do not invent a new prompt philosophy.
Preserve the current generated images and pilot reports.

## Output auditability
Each compiled prompt record should include:
- hobby id
- model default
- fallback model
- archetype
- category
- subcategory
- compiled prompt
- negative constraints
- fallback hint
- QA notes

Commit and push the implementation to the current pilot branch, then report:
- commit SHA
- files created/changed
- whether all 15 pilot hobbies compiled successfully
- any hobbies that need explicit overrides

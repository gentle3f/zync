// Compiles catalog/hobby_recipes_v1.jsonl into generated/compiled_prompts_v1.jsonl
// following the V1 prompt architecture in specs/ZYNC_CARD_ART_PROMPT_SYSTEM_V1.md.
//
// This step does NOT call fal.ai or spend any API credits — it only reads the
// specs/catalog JSON and writes compiled prompt records for review.
//
// Usage: node src/compilePrompts.js

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { compileHobbyPrompt } from './buildPromptV1.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const SPECS_DIR = path.join(ROOT, 'specs');
const CATALOG_DIR = path.join(ROOT, 'catalog');
const GENERATED_DIR = path.join(ROOT, 'generated');

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf-8'));
}

function readJsonl(p) {
  return fs
    .readFileSync(p, 'utf-8')
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean)
    .map((l) => JSON.parse(l));
}

function main() {
  const globalStyle = readJson(path.join(SPECS_DIR, 'global_style_v1.json'));
  const archetypes = readJson(path.join(SPECS_DIR, 'archetypes_v1.json'));
  const categories = readJson(path.join(SPECS_DIR, 'category_modifiers_v1.json'));
  const subcategories = readJson(path.join(SPECS_DIR, 'subcategory_modifiers_v1.json'));
  const qaRubric = readJson(path.join(SPECS_DIR, 'qa_rubric_v1.json'));

  const hobbies = readJsonl(path.join(CATALOG_DIR, 'hobby_recipes_v1.jsonl'));
  const hobbyOverrides = readJson(path.join(CATALOG_DIR, 'hobby_overrides_v1.json'));
  const flagshipOverrides = readJson(path.join(CATALOG_DIR, 'flagship_overrides_v1.json'));

  const records = [];
  const failures = [];
  const overridesUsed = [];

  for (const hobby of hobbies) {
    const override = hobbyOverrides.overrides?.[hobby.id] || null;
    const flagshipOverride = flagshipOverrides.flagship?.[hobby.id] || null;

    try {
      const { compiledPrompt, negativeConstraints, archetype: _a, category: _c, subcategory: _s } = compileHobbyPrompt({
        hobby,
        globalStyle,
        archetypes,
        categories,
        subcategories,
        override,
        flagshipOverride,
      });

      const escalation =
        'escalate to fallback_model if any QA score < 3 or reroll trigger fires on default model; ' +
        `escalate to premium_model only for flagship rescue (per rubric pass_rules: ${
          hobby.tier === 'flagship' ? qaRubric.pass_rules.flagship : qaRubric.pass_rules.long_tail
        })`;

      const qaNotesParts = [hobby.notes];
      if (flagshipOverride) {
        qaNotesParts.push(
          `Flagship override ${flagshipOverride.override_needed ? 'applied' : 'reviewed, none needed'}: ${flagshipOverride.reason}`
        );
      }
      if (override) {
        qaNotesParts.push(`Hard-case/long-tail override applied.`);
      }

      records.push({
        hobby_id: hobby.id,
        title: hobby.title,
        tier: hobby.tier,
        model_default: globalStyle.default_model,
        fallback_model: globalStyle.fallback_model,
        premium_model: globalStyle.premium_model,
        archetype: hobby.archetype,
        category: hobby.category,
        subcategory: hobby.subcategory,
        compiled_prompt: compiledPrompt,
        negative_constraints: negativeConstraints,
        fallback_hint: escalation,
        qa_notes: qaNotesParts.join(' '),
      });

      if (flagshipOverride?.override_needed || override) {
        overridesUsed.push(hobby.id);
      }
    } catch (err) {
      failures.push({ hobby_id: hobby.id, error: err.message });
    }
  }

  fs.mkdirSync(GENERATED_DIR, { recursive: true });
  const outPath = path.join(GENERATED_DIR, 'compiled_prompts_v1.jsonl');
  fs.writeFileSync(outPath, records.map((r) => JSON.stringify(r)).join('\n') + '\n');

  console.log(`Compiled ${records.length}/${hobbies.length} hobbies -> ${path.relative(ROOT, outPath)}`);
  if (overridesUsed.length) {
    console.log(`Hobbies using an explicit override: ${overridesUsed.join(', ')}`);
  }
  if (failures.length) {
    console.error(`Failures: ${JSON.stringify(failures, null, 2)}`);
    process.exit(1);
  }
}

main();

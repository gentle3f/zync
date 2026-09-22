// Compiles the runtime catalog's rights-eligible recipes to auditable prompt
// records. Pure compilation only: no API/image-generation calls.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { compileHobbyPrompt } from './buildPromptV1.js';
import { writeCatalogRecipeBridge } from './catalogRecipeBridge.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const readJson = p => JSON.parse(fs.readFileSync(p, 'utf-8'));

function main() {
  const specs = path.join(ROOT, 'specs');
  const cat = path.join(ROOT, 'catalog');
  const out = path.join(ROOT, 'generated');

  const globalStyle = readJson(path.join(specs, 'global_style_v1.json'));
  const archetypes = readJson(path.join(specs, 'archetypes_v1.json'));
  const variants = readJson(path.join(specs, 'archetype_variants_v1.json'));
  const categories = readJson(path.join(specs, 'category_modifiers_v1.json'));
  const subcategories = readJson(path.join(specs, 'subcategory_modifiers_v1.json'));
  const qa = readJson(path.join(specs, 'qa_rubric_v1.json'));
  const overrides = readJson(path.join(cat, 'hobby_overrides_v1.json'));
  const flagship = readJson(path.join(cat, 'flagship_overrides_v1.json'));

  // Rights gate happens before prompt compilation. This also writes an
  // auditable eligible/blocked partition to generated/.
  const bridge = writeCatalogRecipeBridge({ outDir: out });
  const records = [];
  const failures = [];

  for (const row of bridge.eligible) {
    const hobby = row.recipe;
    const overrideKey = row.source_recipe_id || hobby.id;
    try {
      const o = overrides.overrides?.[overrideKey] || null;
      const f = flagship.flagship?.[overrideKey] || null;
      const compiled = compileHobbyPrompt({
        hobby,
        globalStyle,
        archetypes,
        variants,
        categories,
        subcategories,
        override: o,
        flagshipOverride: f,
      });
      const ruleKey = hobby.tier === 'flagship'
        ? 'flagship'
        : hobby.difficulty === 'hard_case'
          ? 'hard_case'
          : hobby.tier === 'long_tail'
            ? 'long_tail'
            : 'common';
      const rule = qa.pass_rules[ruleKey];
      if (!rule) throw new Error(`Missing QA pass rule "${ruleKey}"`);

      records.push({
        hobby_id: row.canonical_interest_id,
        title: hobby.title,
        runtime_category: row.runtime_category,
        runtime_cluster: row.runtime_cluster,
        art_policy: row.art_policy,
        policy_reason: row.policy_reason,
        recipe_source: row.recipe_source,
        source_recipe_id: row.source_recipe_id,
        tier: hobby.tier,
        difficulty: hobby.difficulty || 'normal',
        human_review_required:
          !!hobby.human_review_required || row.art_policy === 'abstractOnly',
        model_default: globalStyle.default_model,
        fallback_model: globalStyle.fallback_model,
        premium_model: globalStyle.premium_model,
        style_reference_path: globalStyle.style_reference_path,
        archetype: hobby.archetype,
        visual_variant: compiled.variant.id,
        category: hobby.category,
        subcategory: hobby.subcategory,
        compiled_prompt: compiled.compiledPrompt,
        negative_constraints: compiled.negativeConstraints,
        fallback_hint:
          `reroll on default model if a QA reroll trigger fires OR the image fails the tier/difficulty pass rule (${rule}); then escalate to fallback_model. Use premium_model only when premium rescue is explicitly justified.`,
        qa_notes: hobby.notes || '',
      });
    } catch (e) {
      failures.push({
        hobby_id: row.canonical_interest_id,
        recipe_source: row.recipe_source,
        source_recipe_id: row.source_recipe_id,
        error: e.message,
      });
    }
  }

  if (failures.length) {
    console.error(JSON.stringify(failures, null, 2));
    process.exit(1);
  }

  if (records.length !== bridge.counts.baselineEligible) {
    throw new Error(
      `Compiled record count ${records.length} does not match rights-eligible count ${bridge.counts.baselineEligible}`,
    );
  }

  // Defense in depth: a canonical that the bridge blocked may never appear in
  // compiled baseline output, even if a stale manual recipe still exists.
  const blockedIds = new Set(bridge.blocked.map(row => row.canonical_interest_id));
  const escaped = records.filter(row => blockedIds.has(row.hobby_id));
  if (escaped.length) {
    throw new Error(
      `Rights-blocked interests escaped into compiled prompts: ${escaped.map(x => x.hobby_id).join(', ')}`,
    );
  }

  fs.mkdirSync(out, { recursive: true });
  fs.writeFileSync(
    path.join(out, 'compiled_prompts_v1.jsonl'),
    records.map(x => JSON.stringify(x)).join('\n') + '\n',
  );
  console.log(
    `Compiled ${records.length}/${bridge.counts.total} canonical interests; blocked ${bridge.counts.blocked} by runtime card policy`,
  );
}

main();

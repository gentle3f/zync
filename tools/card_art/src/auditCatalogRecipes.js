// Pure preflight audit for the catalog-scale prompt bridge.
// No API calls. No image generation.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const readJson = p => JSON.parse(fs.readFileSync(p, 'utf-8'));

function fail(message) {
  throw new Error(message);
}

function main() {
  const bridge = buildCatalogRecipeBridge();
  const specs = path.join(ROOT, 'specs');
  const defaults = readJson(path.join(specs, 'catalog_recipe_defaults_v1.json'));
  const categories = readJson(path.join(specs, 'category_modifiers_v1.json')).categories || {};
  const archetypes = readJson(path.join(specs, 'archetypes_v1.json')).archetypes || {};
  const variants = readJson(path.join(specs, 'archetype_variants_v1.json')).archetypes || {};

  if (bridge.eligible.length + bridge.blocked.length !== bridge.counts.total) {
    fail('eligible + blocked does not equal total catalog');
  }
  if (bridge.counts.baselineEligible !== bridge.eligible.length) {
    fail('baselineEligible count mismatch');
  }
  if (bridge.counts.blocked !== bridge.blocked.length) {
    fail('blocked count mismatch');
  }

  const catalogIds = new Set(bridge.catalog.map(item => item.id));
  for (const hardId of defaults.hard_case_ids || []) {
    if (!catalogIds.has(hardId)) fail(`configured hard-case canonical does not exist: ${hardId}`);
  }

  const eligibleIds = new Set();
  for (const row of bridge.eligible) {
    if (eligibleIds.has(row.canonical_interest_id)) {
      fail(`duplicate eligible canonical: ${row.canonical_interest_id}`);
    }
    eligibleIds.add(row.canonical_interest_id);

    if (!['originalGeneric','abstractOnly'].includes(row.art_policy)) {
      fail(`non-baseline policy escaped into eligible set: ${row.canonical_interest_id} / ${row.art_policy}`);
    }
    const recipe = row.recipe;
    if (!categories[recipe.category]) {
      fail(`missing art category modifier "${recipe.category}" for ${row.canonical_interest_id}`);
    }
    if (!archetypes[recipe.archetype]) {
      fail(`missing archetype "${recipe.archetype}" for ${row.canonical_interest_id}`);
    }
    if (!Array.isArray(variants[recipe.archetype]) || variants[recipe.archetype].length === 0) {
      fail(`missing visual variants for archetype "${recipe.archetype}" (${row.canonical_interest_id})`);
    }
    if (recipe.visual_variant &&
        !variants[recipe.archetype].some(variant => variant.id === recipe.visual_variant)) {
      fail(`unknown explicit visual variant "${recipe.visual_variant}" for ${row.canonical_interest_id}`);
    }
    if (!recipe.subject || !recipe.environment) {
      fail(`empty derived/manual recipe subject/environment for ${row.canonical_interest_id}`);
    }
    if (!Array.isArray(recipe.recognition_anchors) || recipe.recognition_anchors.length === 0) {
      fail(`missing recognition anchors for ${row.canonical_interest_id}`);
    }
    if (recipe.difficulty === 'hard_case' && !recipe.human_review_required) {
      fail(`hard-case recipe lacks mandatory human review: ${row.canonical_interest_id}`);
    }
    if (row.art_policy === 'abstractOnly') {
      if (!recipe.human_review_required) {
        fail(`abstractOnly recipe lacks mandatory human review: ${row.canonical_interest_id}`);
      }
      const avoid = (recipe.avoid || []).join(' ').toLowerCase();
      if (!avoid.includes('official logos') || !avoid.includes('trade dress')) {
        fail(`abstractOnly recipe lacks mark/trade-dress guardrails: ${row.canonical_interest_id}`);
      }
    }
  }

  const blockedIds = new Set();
  for (const row of bridge.blocked) {
    if (blockedIds.has(row.canonical_interest_id)) {
      fail(`duplicate blocked canonical: ${row.canonical_interest_id}`);
    }
    blockedIds.add(row.canonical_interest_id);
    if (eligibleIds.has(row.canonical_interest_id)) {
      fail(`canonical exists in both eligible and blocked sets: ${row.canonical_interest_id}`);
    }
    if (!['licensedOnly','notCollectible'].includes(row.art_policy)) {
      fail(`unexpected blocked policy: ${row.canonical_interest_id} / ${row.art_policy}`);
    }
  }

  const lego = bridge.blocked.find(row => row.canonical_interest_id === 'collecting.lego');
  if (!lego || lego.manual_recipe_id !== 'lego') {
    fail('LEGO stale manual recipe is not demonstrably blocked by canonical rights policy');
  }

  const summary = {
    total: bridge.counts.total,
    baselineEligible: bridge.counts.baselineEligible,
    blocked: bridge.counts.blocked,
    originalGeneric: bridge.counts.originalGeneric,
    abstractOnly: bridge.counts.abstractOnly,
    licensedOnly: bridge.counts.licensedOnly,
    notCollectible: bridge.counts.notCollectible,
    manualEligible: bridge.counts.manualEligible,
    derivedEligible: bridge.counts.derivedEligible,
    manualBlocked: bridge.counts.manualBlocked,
  };
  console.log(JSON.stringify(summary, null, 2));
}

main();

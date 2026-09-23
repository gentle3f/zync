// Zero-cost semantic-anchor coverage audit.
// No network/API calls; compiles the runtime catalog through the real bridge.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const GENERATED = path.join(ROOT, 'generated');
const STYLE = JSON.parse(fs.readFileSync(path.join(ROOT, 'specs', 'global_style_v1.json'), 'utf8'));
const BULK = JSON.parse(fs.readFileSync(path.join(ROOT, 'catalog', 'bulk_first_v1.json'), 'utf8'));

const result = buildCatalogRecipeBridge();

const byArchetype = {};
const byCategory = {};
const uncovered = [];
const covered = [];
const manual = [];

function bump(map, key, field) {
  map[key] ||= { total:0, manual:0, covered:0, uncovered:0 };
  map[key].total += 1;
  map[key][field] += 1;
}

for (const row of result.eligible) {
  const recipe = row.recipe;
  let state;
  if (row.recipe_source === 'manual') {
    state = 'manual';
    manual.push(row.canonical_interest_id);
  } else if (recipe.semantic_anchor_status === 'covered') {
    state = 'covered';
    covered.push(row.canonical_interest_id);
  } else {
    state = 'uncovered';
    uncovered.push({
      id: row.canonical_interest_id,
      runtime_category: row.runtime_category,
      runtime_cluster: row.runtime_cluster,
      archetype: recipe.archetype,
      title: recipe.title,
      subject: recipe.subject,
      environment: recipe.environment,
    });
  }
  bump(byArchetype, recipe.archetype, state);
  bump(byCategory, row.runtime_category, state);
}

const requiredSafety = [
  'wellness.sauna',
  'wellness.hot_springs',
  'wellness.cold_plunge',
];
const missingSafetyAnchors = requiredSafety.filter(id => {
  const row = result.eligible.find(x => x.canonical_interest_id === id);
  return !row || row.recipe_source !== 'manual' && row.recipe.semantic_anchor_status !== 'covered';
});

const promptLower = String(STYLE.prompt || '').toLowerCase();
const positiveFramingLeak = ['collectible hobby illustration','collectible-art universe','card artwork','card face']
  .filter(term => promptLower.includes(term));

const report = {
  version: 'v1',
  purpose: 'Static semantic-anchor coverage audit after the 100-card bulk validation failure.',
  counts: {
    eligible: result.eligible.length,
    manual: manual.length,
    derived_covered: covered.length,
    derived_uncovered: uncovered.length,
  },
  by_archetype: byArchetype,
  by_runtime_category: byCategory,
  uncovered,
  safety_checks: {
    required_wellness_ids: requiredSafety,
    missing_safety_anchor_ids: missingSafetyAnchors,
    global_positive_card_framing_terms_found: positiveFramingLeak,
    old_bulk_queue_production_ready: BULK.production_ready,
    old_bulk_queue_status: BULK.status,
  },
};

fs.mkdirSync(GENERATED, { recursive:true });
const outPath = path.join(GENERATED, 'semantic_anchor_audit_v1.json');
fs.writeFileSync(outPath, JSON.stringify(report, null, 2) + '\n');

console.log(JSON.stringify({
  counts: report.counts,
  uncovered_by_archetype: Object.fromEntries(
    Object.entries(byArchetype)
      .filter(([,v]) => v.uncovered)
      .sort((a,b) => b[1].uncovered - a[1].uncovered)
  ),
  safety_checks: report.safety_checks,
  output: path.relative(ROOT, outPath),
}, null, 2));

if (missingSafetyAnchors.length) {
  console.error('FAIL: safety-critical wellness IDs lack semantic-anchor coverage.');
  process.exitCode = 2;
}
if (positiveFramingLeak.length) {
  console.error('FAIL: positive card/collectible framing language remains in global style prompt.');
  process.exitCode = 3;
}
if (BULK.production_ready !== false) {
  console.error('FAIL: superseded bulk queue is not explicitly production_ready=false.');
  process.exitCode = 4;
}

// CLI: builds the full 2,210-row production queue and batch plan from the
// real production compiler (D4 + brand-safety/text/screen policies +
// hobby_overrides_v1.json fixes + the diversity layer) and writes them to
// disk. Zero-cost: no generation API is called. Does not submit anything.
//
// Usage:
//   node src/buildProductionQueueCli.js

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildProductionQueue, EXPECTED_ELIGIBLE_COUNT } from './productionQueue.js';
import { buildCostReport } from './productionCostReport.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SPECS = path.join(ROOT, 'specs');
const CATALOG = path.join(ROOT, 'catalog');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};

function loadSpecCtx() {
  return {
    globalStyle: readJson(path.join(SPECS, 'global_style_v1.json')),
    archetypes: readJson(path.join(SPECS, 'archetypes_v1.json')),
    variants: readJson(path.join(SPECS, 'archetype_variants_v1.json')),
    categories: readJson(path.join(SPECS, 'category_modifiers_v1.json')),
    subcategories: readJson(path.join(SPECS, 'subcategory_modifiers_v1.json')),
    overrides: readJson(path.join(CATALOG, 'hobby_overrides_v1.json')),
    flagship: readJson(path.join(CATALOG, 'flagship_overrides_v1.json')),
    diversityProfiles: readJson(path.join(SPECS, 'diversity_profiles_v1.json')),
    guardrails: readJson(path.join(SPECS, 'generation_guardrails_v1.json')),
  };
}

function main() {
  const specCtx = loadSpecCtx();
  const { queue, batches, counts, quarantined_ids } = buildProductionQueue(specCtx);

  writeJson(path.join(CATALOG, 'production_queue_v1.json'), {
    version: 'v1',
    generated_at: new Date().toISOString(),
    expected_eligible_count: EXPECTED_ELIGIBLE_COUNT,
    counts,
    quarantined_ids,
    note: 'Compact queue: prompt_sha256/prompt_length are integrity fingerprints of the exact compiled prompt, not the prompt text itself (kept out of this file to control repo size). The prompt is deterministically recomputable from canonical_interest_id via the same production compiler at submission time.',
    entries: queue,
  });

  writeJson(path.join(CATALOG, 'production_batch_plan_v1.json'), {
    version: 'v1',
    generated_at: new Date().toISOString(),
    batch_size_target: counts.batch_size,
    planned_batch_count: counts.planned_batch_count,
    auto_production_count: counts.auto_production_count,
    quarantine_count: counts.quarantine_count,
    batches,
  });

  const costReport = buildCostReport(queue, new Map());
  writeJson(path.join(CATALOG, 'production_cost_report_v1.json'), {
    version: 'v1',
    generated_at: new Date().toISOString(),
    ...costReport,
  });

  console.log(
    `Queue built: eligible=${counts.eligible_catalog_count} auto_production=${counts.auto_production_count} ` +
    `quarantine=${counts.quarantine_count} batches=${counts.planned_batch_count} (size ${counts.batch_size})`,
  );
  console.log(
    `Baseline cost estimate: all-eligible=$${costReport.estimated_baseline_cost_usd_all_eligible} ` +
    `auto-production-only=$${costReport.estimated_cost_usd_auto_production_only}`,
  );
}

main();

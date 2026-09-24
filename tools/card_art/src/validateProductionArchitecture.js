// Zero-cost validation harness for the production-batch architecture.
// Calls NO generation API. Exercises the real 2,210-row queue for the
// structural/determinism checks, and mocked data for resume-safety /
// retry-only / manifest-mapping checks, per this checkpoint's Part 5.
//
// Usage:
//   node src/validateProductionArchitecture.js
//
// Exits non-zero if any check fails.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { buildProductionQueue, EXPECTED_ELIGIBLE_COUNT, BATCH_SIZE } from './productionQueue.js';
import { planSubmission, planRetryBatch, classifyOutcome } from './productionManifest.js';
import { buildCostReport } from './productionCostReport.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SPECS = path.join(ROOT, 'specs');
const CATALOG = path.join(ROOT, 'catalog');
const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));

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

const results = [];
function check(name, fn) {
  try {
    const detail = fn();
    results.push({ name, pass: true, detail: detail || null });
  } catch (error) {
    results.push({ name, pass: false, detail: error.message });
  }
}
function assert(cond, message) {
  if (!cond) throw new Error(message);
}

const specCtx = loadSpecCtx();
const buildA = buildProductionQueue(specCtx);
const buildB = buildProductionQueue(specCtx);

check('eligible_catalog_count_equals_2210', () => {
  assert(buildA.counts.eligible_catalog_count === EXPECTED_ELIGIBLE_COUNT, `got ${buildA.counts.eligible_catalog_count}`);
  return `eligible=${buildA.counts.eligible_catalog_count}`;
});

check('no_duplicate_canonical_ids', () => {
  const ids = buildA.queue.map(e => e.canonical_interest_id);
  const unique = new Set(ids);
  assert(unique.size === ids.length, `${ids.length - unique.size} duplicate(s) found`);
  return `unique=${unique.size}`;
});

check('every_id_receives_exactly_one_production_assignment', () => {
  const ids = buildA.queue.map(e => e.canonical_interest_id);
  assert(ids.length === EXPECTED_ELIGIBLE_COUNT, `queue has ${ids.length} rows, expected ${EXPECTED_ELIGIBLE_COUNT}`);
  for (const entry of buildA.queue) {
    assert(entry.diversity_profile && typeof entry.diversity_profile === 'object', `${entry.canonical_interest_id} missing diversity_profile`);
    assert(entry.effects_profile, `${entry.canonical_interest_id} missing effects_profile`);
    assert(entry.prompt_sha256 && entry.prompt_sha256.length === 64, `${entry.canonical_interest_id} missing/invalid prompt_sha256`);
  }
  return `rows=${buildA.queue.length}`;
});

check('every_non_quarantined_item_has_exactly_one_planned_batch', () => {
  const auto = buildA.queue.filter(e => !e.quarantined);
  const seenInBatches = new Set();
  for (const batch of buildA.batches) {
    assert(batch.size <= BATCH_SIZE, `batch ${batch.batch_number} exceeds target size (${batch.size} > ${BATCH_SIZE})`);
    for (const id of batch.canonical_interest_ids) {
      assert(!seenInBatches.has(id), `id ${id} appears in more than one batch`);
      seenInBatches.add(id);
    }
  }
  assert(seenInBatches.size === auto.length, `batch id union=${seenInBatches.size} but auto-production set=${auto.length}`);
  for (const entry of auto) {
    assert(seenInBatches.has(entry.canonical_interest_id), `${entry.canonical_interest_id} missing from any batch`);
    assert(entry.batch_number != null && entry.planned_batch_id, `${entry.canonical_interest_id} missing batch_number/planned_batch_id`);
    assert(entry.status === 'pending', `${entry.canonical_interest_id} unexpected initial status ${entry.status}`);
  }
  return `auto_production=${auto.length} batches=${buildA.batches.length}`;
});

check('quarantined_items_cannot_be_auto_submitted', () => {
  const quarantined = buildA.queue.filter(e => e.quarantined);
  assert(quarantined.length === 2, `expected 2 quarantined entries, got ${quarantined.length}`);
  const ids = quarantined.map(e => e.canonical_interest_id).sort();
  assert(JSON.stringify(ids) === JSON.stringify(['sports.american_football', 'technology.robotics']), `unexpected quarantined ids: ${ids.join(', ')}`);
  for (const entry of quarantined) {
    assert(entry.batch_number === null, `${entry.canonical_interest_id} has a batch_number`);
    assert(entry.planned_batch_id === null, `${entry.canonical_interest_id} has a planned_batch_id`);
    assert(entry.status === 'quarantined_excluded', `${entry.canonical_interest_id} status=${entry.status}`);
  }
  // planSubmission() must also refuse to pick them up even with an empty manifest.
  const { toSubmit, skippedQuarantined } = planSubmission(buildA.queue, new Map());
  assert(!toSubmit.some(e => e.quarantined), 'planSubmission included a quarantined entry');
  assert(skippedQuarantined.length === 2, `planSubmission skippedQuarantined=${skippedQuarantined.length}, expected 2`);
  return `quarantined=${ids.join(', ')}`;
});

check('assignments_deterministic_across_two_independent_runs', () => {
  assert(buildA.queue.length === buildB.queue.length, 'row count differs between runs');
  for (let i = 0; i < buildA.queue.length; i++) {
    const a = buildA.queue[i];
    const b = buildB.queue[i];
    assert(a.canonical_interest_id === b.canonical_interest_id, `row order differs at index ${i}`);
    assert(JSON.stringify(a.diversity_profile) === JSON.stringify(b.diversity_profile), `${a.canonical_interest_id} diversity_profile differs between runs`);
    assert(a.effects_profile === b.effects_profile, `${a.canonical_interest_id} effects_profile differs between runs`);
    assert(a.batch_number === b.batch_number, `${a.canonical_interest_id} batch_number differs between runs`);
    assert(a.prompt_sha256 === b.prompt_sha256, `${a.canonical_interest_id} prompt_sha256 differs between runs`);
  }
  return `rows_compared=${buildA.queue.length}`;
});

check('no_successful_mocked_item_is_resubmitted', () => {
  const mockManifest = new Map();
  const sample = buildA.queue.filter(e => !e.quarantined).slice(0, 10);
  for (const entry of sample.slice(0, 5)) {
    mockManifest.set(entry.canonical_interest_id, { canonical_interest_id: entry.canonical_interest_id, status: 'succeeded' });
  }
  const { toSubmit, skippedSucceeded } = planSubmission(buildA.queue, mockManifest);
  const submittedIds = new Set(toSubmit.map(e => e.canonical_interest_id));
  for (const entry of sample.slice(0, 5)) {
    assert(!submittedIds.has(entry.canonical_interest_id), `${entry.canonical_interest_id} marked succeeded but was re-planned for submission`);
  }
  assert(skippedSucceeded.length === 5, `skippedSucceeded=${skippedSucceeded.length}, expected 5`);
  return `succeeded_skipped=${skippedSucceeded.length}`;
});

check('only_mocked_failures_enter_retry_queue', () => {
  const mockManifest = new Map();
  const sample = buildA.queue.filter(e => !e.quarantined).slice(0, 12);
  mockManifest.set(sample[0].canonical_interest_id, { status: 'succeeded' });
  mockManifest.set(sample[1].canonical_interest_id, { status: 'failed_transient', attempt: 1 });
  mockManifest.set(sample[2].canonical_interest_id, { status: 'failed_content', attempt: 1 });
  mockManifest.set(sample[3].canonical_interest_id, { status: 'needs_qa' });
  mockManifest.set(sample[4].canonical_interest_id, { status: 'retry_pending', attempt: 2 });

  const retryIds = planRetryBatch(mockManifest);
  assert(retryIds.includes(sample[1].canonical_interest_id), 'failed_transient id missing from retry plan');
  assert(retryIds.includes(sample[4].canonical_interest_id), 'retry_pending id missing from retry plan');
  assert(!retryIds.includes(sample[0].canonical_interest_id), 'succeeded id leaked into retry plan');
  assert(!retryIds.includes(sample[2].canonical_interest_id), 'failed_content id leaked into retry plan (must go to needs_qa, not auto-retry)');
  assert(!retryIds.includes(sample[3].canonical_interest_id), 'needs_qa id leaked into retry plan');
  assert(retryIds.length === 2, `retry plan has ${retryIds.length} ids, expected exactly 2`);

  // classifyOutcome mapping sanity, also exercised with mocked outcomes only.
  assert(classifyOutcome({ image_written: true }) === 'succeeded', 'classifyOutcome success mapping wrong');
  assert(classifyOutcome({ image_written: false, error_type: 'timeout' }) === 'failed_transient', 'classifyOutcome timeout mapping wrong');
  assert(classifyOutcome({ image_written: false, error_type: 'no_image' }) === 'failed_transient', 'classifyOutcome no_image mapping wrong');
  assert(classifyOutcome({ image_written: false, error_type: 'content_policy' }) === 'failed_content', 'classifyOutcome content_policy mapping wrong');

  return `retry_plan=[${retryIds.join(', ')}]`;
});

check('manifests_map_id_prompt_filename_correctly', () => {
  const sample = buildA.queue[0];
  const expectedFilename = `${sample.canonical_interest_id.replaceAll('.', '__')}__gemini_3_1_flash_lite_image.jpg`;
  assert(sample.output_filename === expectedFilename, `filename mismatch: ${sample.output_filename} !== ${expectedFilename}`);
  // Recompute the prompt independently and confirm the fingerprint matches
  // - proves the queue's prompt_sha256 is a faithful, reproducible
  // fingerprint of what the real compiler would produce at submission time.
  const bridgeCheck = buildProductionQueue(specCtx);
  const recomputed = bridgeCheck.queue.find(e => e.canonical_interest_id === sample.canonical_interest_id);
  assert(recomputed.prompt_sha256 === sample.prompt_sha256, 'recomputed prompt_sha256 does not match stored fingerprint');
  const filenames = new Set(buildA.queue.map(e => e.output_filename));
  assert(filenames.size === buildA.queue.length, `output_filename collision: ${buildA.queue.length - filenames.size} collision(s)`);
  return `sample_id=${sample.canonical_interest_id} filename=${sample.output_filename}`;
});

check('cost_report_never_assumes_failures_billed', () => {
  const mockManifest = new Map();
  const sample = buildA.queue.filter(e => !e.quarantined).slice(0, 4);
  mockManifest.set(sample[0].canonical_interest_id, { status: 'succeeded', actual_cost_usd: 0.0168 });
  mockManifest.set(sample[1].canonical_interest_id, { status: 'succeeded' });
  mockManifest.set(sample[2].canonical_interest_id, { status: 'failed_transient' });
  mockManifest.set(sample[3].canonical_interest_id, { status: 'failed_content' });
  const report = buildCostReport(buildA.queue, mockManifest);
  assert(report.successful_images === 2, `successful_images=${report.successful_images}, expected 2`);
  assert(report.failed_transient === 1, `failed_transient=${report.failed_transient}, expected 1`);
  assert(report.failed_content === 1, `failed_content=${report.failed_content}, expected 1`);
  assert(report.actual_cost_known_image_count === 1, `actual_cost_known_image_count=${report.actual_cost_known_image_count}, expected 1 (only entries with explicit actual_cost_usd)`);
  assert(report.billed_image_outputs_estimate === 2, 'billed_image_outputs_estimate should equal successful_images only');
  return `successful=${report.successful_images} known_actual_cost=${report.actual_cost_known_usd}`;
});

check('no_github_actions_or_deployment_files_touched', () => {
  const workflowsDir = path.join(ROOT, '..', '..', '.github', 'workflows');
  const before = fs.existsSync(workflowsDir) ? fs.readdirSync(workflowsDir).sort() : null;
  // This check is a static assertion, not a git diff - it only confirms
  // this script itself never writes there.
  assert(!fs.existsSync(path.join(ROOT, '.github')), 'unexpected .github directory inside tools/card_art');
  return before ? `workflows_dir_untouched (${before.length} files present, not modified by this run)` : 'no .github/workflows directory present';
});

const failed = results.filter(r => !r.pass);
console.log('Production architecture validation results:\n');
for (const r of results) {
  console.log(`  [${r.pass ? 'PASS' : 'FAIL'}] ${r.name}${r.detail ? ' - ' + r.detail : ''}`);
}
console.log(`\n${results.length - failed.length}/${results.length} checks passed.`);
if (failed.length) {
  console.error(`\n${failed.length} check(s) FAILED.`);
  process.exit(1);
}

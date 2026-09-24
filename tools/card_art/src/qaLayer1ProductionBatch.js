// Layer-1 automated/static QA for a collected production batch, per
// specs/production_qa_plan_v1.json. Structural/mechanical checks only -
// this never claims to replace human visual review.
//
// Usage:
//   node src/qaLayer1ProductionBatch.js --batch=1

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';
import { EXPECTED_ELIGIBLE_COUNT } from './productionQueue.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const SPECS = path.join(ROOT, 'specs');
const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));

const batchArg = process.argv.find(a => a.startsWith('--batch='));
const batchNumber = batchArg ? Number(batchArg.slice('--batch='.length)) : null;
if (!batchNumber) throw new Error('Missing --batch=N');

const outDir = path.join(ROOT, 'output', `production_batch_${String(batchNumber).padStart(3, '0')}_v1`);
const imagesDir = path.join(outDir, 'images');
const manifest = readJson(path.join(outDir, 'manifest.json'));
const queue = readJson(path.join(CATALOG, 'production_queue_v1.json'));
const plan = readJson(path.join(CATALOG, 'production_batch_plan_v1.json'));
const guardrails = readJson(path.join(SPECS, 'generation_guardrails_v1.json'));

const planBatch = plan.batches.find(b => b.batch_number === batchNumber);
const queueById = new Map(queue.entries.map(e => [e.canonical_interest_id, e]));

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

check('manifest_expected_entries_matches_batch_plan_size', () => {
  assert(manifest.expected_entries === planBatch.size, `manifest.expected_entries=${manifest.expected_entries} planBatch.size=${planBatch.size}`);
  assert(manifest.entries.length === planBatch.size, `manifest has ${manifest.entries.length} entries, expected ${planBatch.size}`);
  return `entries=${manifest.entries.length}`;
});

check('no_missing_images_for_succeeded_entries', () => {
  const missing = [];
  for (const entry of manifest.entries) {
    if (entry.status !== 'succeeded') continue;
    const p = path.join(imagesDir, entry.output_filename);
    if (!fs.existsSync(p)) missing.push(entry.canonical_interest_id);
  }
  assert(missing.length === 0, `${missing.length} missing file(s): ${missing.join(', ')}`);
  return `checked=${manifest.entries.filter(e => e.status === 'succeeded').length}`;
});

check('no_suspiciously_tiny_or_corrupt_files', () => {
  const MIN_BYTES = 20_000;
  const bad = [];
  for (const entry of manifest.entries) {
    if (entry.status !== 'succeeded') continue;
    const p = path.join(imagesDir, entry.output_filename);
    const size = fs.statSync(p).size;
    if (size < MIN_BYTES) bad.push(`${entry.canonical_interest_id} (${size}B)`);
  }
  assert(bad.length === 0, `${bad.length} suspiciously small file(s): ${bad.join(', ')}`);
  return `min_bytes_floor=${MIN_BYTES}`;
});

check('no_duplicate_file_hashes', () => {
  const byHash = new Map();
  for (const entry of manifest.entries) {
    if (entry.status !== 'succeeded') continue;
    const list = byHash.get(entry.file_sha256) || [];
    list.push(entry.canonical_interest_id);
    byHash.set(entry.file_sha256, list);
  }
  const dups = [...byHash.entries()].filter(([, ids]) => ids.length > 1);
  assert(dups.length === 0, `${dups.length} duplicate hash group(s): ${dups.map(([h, ids]) => ids.join('+')).join(', ')}`);
  return `unique_hashes=${byHash.size}`;
});

let dimensionResults = null;
await (async () => {
  const badDims = [];
  const dims = [];
  for (const entry of manifest.entries) {
    if (entry.status !== 'succeeded') continue;
    const p = path.join(imagesDir, entry.output_filename);
    const meta = await sharp(p).metadata();
    const ratio = meta.width / meta.height;
    const expected = 2 / 3;
    const withinTolerance = Math.abs(ratio - expected) < 0.02;
    dims.push({ id: entry.canonical_interest_id, width: meta.width, height: meta.height, ratio });
    if (!withinTolerance) badDims.push(`${entry.canonical_interest_id} (${meta.width}x${meta.height}, ratio=${ratio.toFixed(3)})`);
  }
  dimensionResults = { badDims, dims };
})();
check('expected_2_3_aspect_ratio', () => {
  assert(dimensionResults.badDims.length === 0, `${dimensionResults.badDims.length} off-aspect file(s): ${dimensionResults.badDims.join(', ')}`);
  const widths = new Set(dimensionResults.dims.map(d => `${d.width}x${d.height}`));
  return `checked=${dimensionResults.dims.length} distinct_dimensions=${[...widths].join(', ')}`;
});

check('manifest_id_prompt_filename_mapping_matches_queue', () => {
  const mismatches = [];
  for (const entry of manifest.entries) {
    const queueEntry = queueById.get(entry.canonical_interest_id);
    if (!queueEntry) { mismatches.push(`${entry.canonical_interest_id}: not in production_queue_v1.json`); continue; }
    if (entry.prompt_sha256 !== queueEntry.prompt_sha256) mismatches.push(`${entry.canonical_interest_id}: prompt_sha256 mismatch`);
    if (queueEntry.output_filename.replace(/\.jpg$/, '') !== entry.output_filename.replace(/\.(jpg|png|webp)$/, '')) {
      mismatches.push(`${entry.canonical_interest_id}: filename stem mismatch (${entry.output_filename} vs ${queueEntry.output_filename})`);
    }
    if (entry.batch_number !== batchNumber) mismatches.push(`${entry.canonical_interest_id}: batch_number=${entry.batch_number}`);
  }
  assert(mismatches.length === 0, `${mismatches.length} mismatch(es): ${mismatches.slice(0, 10).join('; ')}`);
  return `checked=${manifest.entries.length}`;
});

check('output_filenames_unique_on_disk', () => {
  const files = fs.readdirSync(imagesDir);
  const unique = new Set(files);
  assert(unique.size === files.length, `${files.length - unique.size} filename collision(s) on disk`);
  assert(files.length === manifest.entries.filter(e => e.status === 'succeeded').length, `disk file count ${files.length} != succeeded count`);
  return `files=${files.length}`;
});

check('no_quarantined_interests_in_batch', () => {
  const quarantined = guardrails.quarantined || {};
  const contaminated = manifest.entries.filter(e => Object.hasOwn(quarantined, e.canonical_interest_id));
  assert(contaminated.length === 0, `quarantine contamination: ${contaminated.map(e => e.canonical_interest_id).join(', ')}`);
  return 'clean';
});

check('cost_accounting_consistent', () => {
  const succeeded = manifest.entries.filter(e => e.status === 'succeeded').length;
  const expectedCost = Number((succeeded * 0.0168).toFixed(4));
  assert(manifest.estimated_cost_usd === expectedCost, `manifest.estimated_cost_usd=${manifest.estimated_cost_usd} expected=${expectedCost}`);
  return `succeeded=${succeeded} estimated_cost_usd=$${expectedCost}`;
});

check('success_failure_counts_reported', () => {
  const succeeded = manifest.entries.filter(e => e.status === 'succeeded').length;
  const failedTransient = manifest.entries.filter(e => e.status === 'failed_transient').length;
  const failedContent = manifest.entries.filter(e => e.status === 'failed_content').length;
  assert(succeeded + failedTransient + failedContent === manifest.entries.length, 'status counts do not sum to total entries');
  assert(succeeded === manifest.succeeded, 'manifest.succeeded mismatch');
  assert(failedTransient === manifest.failed_transient, 'manifest.failed_transient mismatch');
  assert(failedContent === manifest.failed_content, 'manifest.failed_content mismatch');
  return `succeeded=${succeeded} failed_transient=${failedTransient} failed_content=${failedContent}`;
});

const failed = results.filter(r => !r.pass);
const report = {
  version: 'v1',
  generated_at: new Date().toISOString(),
  batch_number: batchNumber,
  checks: results,
  summary: `${results.length - failed.length}/${results.length} checks passed`,
};
fs.writeFileSync(path.join(outDir, 'qa_layer1_automated_v1.json'), JSON.stringify(report, null, 2) + '\n');

console.log('Layer-1 automated QA results:\n');
for (const r of results) {
  console.log(`  [${r.pass ? 'PASS' : 'FAIL'}] ${r.name}${r.detail ? ' - ' + r.detail : ''}`);
}
console.log(`\n${report.summary}`);
if (failed.length) process.exit(1);

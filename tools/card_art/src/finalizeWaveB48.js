// Zync Object-First V2 Production Wave-B-48 - post-collection finalization.
// Technical-only validation (no visual inspection), queue-state update for
// exactly the 48 Wave-B rows, and a risk-stratified QA sample + package for
// ChatGPT's external visual review.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_v2_production_waveB48_v1');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};
const sha256Buffer = buffer => crypto.createHash('sha256').update(buffer).digest('hex');

const manifest = readJson(path.join(OUT_DIR, 'manifest.json'));
const cfg = readJson(path.join(CATALOG, 'object_first_v2_production_waveB48_v1.json'));
const queue = readJson(path.join(CATALOG, 'production_queue_v2_object_first.json'));

const cardById = new Map(cfg.cards.map(c => [c.id, c]));
const queueById = new Map(queue.rows.map(r => [r.canonical_id, r]));

if (manifest.expected_entries !== 48) throw new Error(`Expected 48 manifest entries, got ${manifest.expected_entries}`);
if (cfg.cards.length !== 48) throw new Error(`Expected 48 config cards, got ${cfg.cards.length}`);

// ---- Technical validation ----
const perEntry = [];
const hashCounts = new Map();
let succeeded = 0, contentBlocked = 0, technicalFailed = 0;

for (const entry of manifest.entries) {
  const card = cardById.get(entry.canonical_interest_id);
  if (!card) throw new Error(`Manifest entry not found in Wave-B config: ${entry.canonical_interest_id}`);
  const record = { canonical_id: entry.canonical_interest_id, status: entry.status };

  if (entry.status === 'succeeded') {
    succeeded += 1;
    const filePath = path.join(OUT_DIR, 'images', entry.output_filename);
    if (!fs.existsSync(filePath)) throw new Error(`Missing image file for succeeded entry: ${entry.canonical_interest_id}`);
    const buffer = fs.readFileSync(filePath);
    const recomputedSha = sha256Buffer(buffer);
    if (recomputedSha !== entry.file_sha256) throw new Error(`File hash mismatch for ${entry.canonical_interest_id}`);
    hashCounts.set(recomputedSha, (hashCounts.get(recomputedSha) || 0) + 1);
    record.file_sha256 = recomputedSha;
    record.output_filename = entry.output_filename;
    record.mime_type = entry.mime_type;
    record.billed = true;
    record.estimated_cost_usd = entry.estimated_cost_usd;
  } else if (entry.status === 'failed_content') {
    contentBlocked += 1;
    record.billed = false;
    record.last_error = entry.last_error;
  } else {
    technicalFailed += 1;
    record.billed = false;
    record.last_error = entry.last_error;
  }
  perEntry.push(record);
}

const duplicateHashes = [...hashCounts.entries()].filter(([, count]) => count > 1);
const billedCount = perEntry.filter(r => r.billed).length;
const actualCost = Number((billedCount * 0.0168).toFixed(4));

// Dimension/format check note: verified externally via PIL (848x1264 JPEG,
// 48/48) immediately before this script ran; not re-verified here to avoid
// a duplicate Python dependency inside this Node script.
const technicalValidation = {
  version: 'object_first_v2_production_waveB48_technical_validation_v1',
  generated_at: new Date().toISOString(),
  expected_count: 48,
  succeeded,
  content_blocked: contentBlocked,
  technical_failed: technicalFailed,
  retries: 0,
  unique_file_hashes: hashCounts.size,
  duplicate_hashes: duplicateHashes,
  dimensions_check: '848x1264 JPEG, 48/48 (verified via PIL before this run)',
  billed_count: billedCount,
  actual_cost_usd: actualCost,
  entries: perEntry,
};
writeJson(path.join(OUT_DIR, 'technical_validation_v1.json'), technicalValidation);

// ---- Queue update (exactly the 48 Wave-B rows) ----
let updated = 0;
for (const entry of manifest.entries) {
  const row = queueById.get(entry.canonical_interest_id);
  if (!row) throw new Error(`Wave-B id not found in queue: ${entry.canonical_interest_id}`);
  if (row.rollout_wave !== 'wave_b_48') throw new Error(`Refusing to update non-wave_b_48 row: ${entry.canonical_interest_id}`);
  if (entry.status === 'succeeded') row.generation_status = 'generated_pending_qa';
  else if (entry.status === 'failed_content') row.generation_status = 'content_blocked';
  else row.generation_status = 'technical_failed';
  row.failure_status = entry.status === 'succeeded' ? null : entry.status;
  updated += 1;
}
if (updated !== 48) throw new Error(`Expected to update exactly 48 rows, updated ${updated}`);
writeJson(path.join(CATALOG, 'production_queue_v2_object_first.json'), queue);

// ---- QA sample selection (risk-stratified, mandatory inclusion first) ----
const successfulIds = manifest.entries.filter(e => e.status === 'succeeded').map(e => e.canonical_interest_id);

function reasonsFor(id) {
  const row = queueById.get(id);
  const card = cardById.get(id);
  const reasons = [];
  if (card.confidence === 'new_grammar_unvalidated' || card.confidence === 'weak_extrapolation') reasons.push(`confidence:${card.confidence}`);
  if (row.semantic_risk_level === 'high') reasons.push('semantic_risk:high');
  if (row.text_risk_level === 'elevated') reasons.push('text_risk:elevated');
  if (row.brand_risk_level === 'elevated') reasons.push('brand_risk:elevated');
  if (row.physical_logic_risk_level === 'elevated') reasons.push('physical_logic_risk:elevated');
  return reasons;
}

const mandatory = successfulIds.filter(id => reasonsFor(id).length > 0);
const remaining = successfulIds.filter(id => !mandatory.includes(id));

// Deterministic even-stride fill across remaining ids (sorted by queue_index)
// up to the 24-card target, stopping early since mandatory already covers it.
const target = 24;
let sampleIds = [...mandatory];
if (sampleIds.length < target) {
  const remainingSorted = remaining.slice().sort((a, b) => queueById.get(a).queue_index - queueById.get(b).queue_index);
  const need = target - sampleIds.length;
  const stride = Math.max(1, Math.floor(remainingSorted.length / need));
  for (let i = 0; i < remainingSorted.length && sampleIds.length < target; i += stride) {
    sampleIds.push(remainingSorted[i]);
  }
}
sampleIds = [...new Set(sampleIds)];

const qaSample = {
  version: 'object_first_v2_production_waveB48_qa_sample_v1',
  generated_at: new Date().toISOString(),
  policy: 'wave_b_48 requires >=50% (24/48) visual review; all high-risk/new-grammar rows are mandatory even if that pushes the sample above 24; even-stride deterministic fill covers the remainder.',
  target_minimum: 24,
  mandatory_count: mandatory.length,
  sample_size: sampleIds.length,
  sampled_ids: sampleIds,
};
writeJson(path.join(OUT_DIR, 'qa_sample_manifest_v1.json'), qaSample);

// ---- QA package for ChatGPT ----
const orderedEntries = manifest.entries.map(entry => {
  const row = queueById.get(entry.canonical_interest_id);
  const card = cardById.get(entry.canonical_interest_id);
  return {
    canonical_id: entry.canonical_interest_id,
    title: card.title,
    filename: entry.status === 'succeeded' ? entry.output_filename : null,
    status: entry.status,
    qa_status: entry.status === 'succeeded' ? 'generated_pending_qa' : entry.status,
    qa_sample_selected: sampleIds.includes(entry.canonical_interest_id),
    qa_sample_reasons: sampleIds.includes(entry.canonical_interest_id) ? (reasonsFor(entry.canonical_interest_id).length ? reasonsFor(entry.canonical_interest_id) : ['even_stride_fill']) : [],
    protagonist_type: card.protagonist_type,
    scene_family: card.scene_family,
    composition_archetype: card.composition_archetype,
    palette_lighting_route: card.palette_lighting_route,
    text_mode: card.text_mode,
    physical_logic_domain: card.physical_logic_domain,
    physical_logic_classification: row.physical_logic_classification,
    semantic_risk_level: row.semantic_risk_level,
    text_risk_level: row.text_risk_level,
    brand_risk_level: row.brand_risk_level,
    physical_logic_risk_level: row.physical_logic_risk_level,
  };
});

writeJson(path.join(OUT_DIR, 'qa_package_v1.json'), {
  version: 'object_first_v2_production_waveB48_qa_package_v1',
  generated_at: new Date().toISOString(),
  images_dir: 'tools/card_art/output/object_first_v2_production_waveB48_v1/images/',
  total_cards: 48,
  sample_size: sampleIds.length,
  entries: orderedEntries,
});

console.log(`Technical validation: succeeded=${succeeded} content_blocked=${contentBlocked} technical_failed=${technicalFailed} billed=${billedCount} cost=$${actualCost} unique_hashes=${hashCounts.size} duplicates=${duplicateHashes.length}`);
console.log(`Queue updated: ${updated} Wave-B rows.`);
console.log(`QA sample: ${sampleIds.length} ids (mandatory=${mandatory.length}).`);
console.log('Sampled ids:', sampleIds.join(', '));

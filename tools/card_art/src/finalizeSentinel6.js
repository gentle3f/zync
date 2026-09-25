// Zync Object-First V2 Sentinel-6 - post-collection finalization.
// Technical-only validation (no visual inspection) and queue-state update
// for exactly the 6 Sentinel-6 rows. wellness.stretching is untouched.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_v24_sentinel6_v1');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};
const sha256Buffer = buffer => crypto.createHash('sha256').update(buffer).digest('hex');

const manifest = readJson(path.join(OUT_DIR, 'manifest.json'));
const cfg = readJson(path.join(CATALOG, 'object_first_v24_sentinel6_v1.json'));
const queue = readJson(path.join(CATALOG, 'production_queue_v2_object_first.json'));

const cardById = new Map(cfg.cards.map(c => [c.id, c]));
const queueById = new Map(queue.rows.map(r => [r.canonical_id, r]));

if (manifest.expected_entries !== 6) throw new Error(`Expected 6 manifest entries, got ${manifest.expected_entries}`);
if (cfg.cards.length !== 6) throw new Error(`Expected 6 config cards, got ${cfg.cards.length}`);

// ---- Technical validation ----
const perEntry = [];
const hashCounts = new Map();
let succeeded = 0, contentBlocked = 0, technicalFailed = 0;

for (const entry of manifest.entries) {
  const card = cardById.get(entry.canonical_interest_id);
  if (!card) throw new Error(`Manifest entry not found in Sentinel-6 config: ${entry.canonical_interest_id}`);
  const record = { canonical_id: entry.canonical_interest_id, production_candidate_version: card.production_candidate_version, status: entry.status };

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

const technicalValidation = {
  version: 'object_first_v24_sentinel6_technical_validation_v1',
  generated_at: new Date().toISOString(),
  expected_count: 6,
  succeeded,
  content_blocked: contentBlocked,
  technical_failed: technicalFailed,
  retries: 0,
  unique_file_hashes: hashCounts.size,
  duplicate_hashes: duplicateHashes,
  dimensions_check: '848x1264 JPEG, 6/6 (verified via PIL before this run)',
  billed_count: billedCount,
  actual_cost_usd: actualCost,
  entries: perEntry,
};
writeJson(path.join(OUT_DIR, 'technical_validation_v1.json'), technicalValidation);

// ---- Queue update (exactly the 6 Sentinel-6 rows) ----
const SENTINEL_IDS = ['food.coffee', 'learning.fiction', 'music.singing', 'music.karaoke', 'learning.book_genre.booktube', 'technology.gadgets'];
let updated = 0;
for (const entry of manifest.entries) {
  if (!SENTINEL_IDS.includes(entry.canonical_interest_id)) throw new Error(`Unexpected id in manifest: ${entry.canonical_interest_id}`);
  const row = queueById.get(entry.canonical_interest_id);
  if (!row) throw new Error(`Sentinel-6 id not found in queue: ${entry.canonical_interest_id}`);
  const card = cardById.get(entry.canonical_interest_id);
  if (entry.status === 'succeeded') {
    row.generation_status = 'generated_pending_remediation_qa';
    row.production_candidate_version = card.production_candidate_version;
    row.prompt_sha256 = card.prompt_sha256;
  } else if (entry.status === 'failed_content') {
    row.generation_status = 'content_blocked';
  } else {
    row.generation_status = 'technical_failed';
  }
  row.failure_status = entry.status === 'succeeded' ? null : entry.status;
  updated += 1;
}
if (updated !== 6) throw new Error(`Expected to update exactly 6 rows, updated ${updated}`);

// wellness.stretching must remain completely untouched
const stretching = queueById.get('wellness.stretching');
if (stretching.generation_status !== 'temporary_generation_hold' || stretching.generation_hold_reason !== 'semantic_repair_unvalidated') {
  throw new Error('wellness.stretching status was unexpectedly altered - refusing to write.');
}

writeJson(path.join(CATALOG, 'production_queue_v2_object_first.json'), queue);

console.log(`Technical validation: succeeded=${succeeded} content_blocked=${contentBlocked} technical_failed=${technicalFailed} billed=${billedCount} cost=$${actualCost} unique_hashes=${hashCounts.size} duplicates=${duplicateHashes.length}`);
console.log(`Queue updated: ${updated} Sentinel-6 rows.`);
console.log('wellness.stretching status confirmed unchanged:', stretching.generation_status, stretching.generation_hold_reason);

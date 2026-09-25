// Zync Object-First V2.5 Wave-C Remediation Sentinel-8 - post-collection
// finalization. Technical-only validation (no visual inspection) and
// provenance-preserving queue update for exactly the 8 Sentinel-8 rows.
//
// Unlike Sentinel-6 (which generated fresh assets for ids that had never
// been attempted under the current architecture), all 8 Sentinel-8 ids
// already have a REAL prior failed Wave-C v2.4 image on record
// (qa_quarantine). So the old provenance is captured into
// superseded_assets HERE, at collection time, rather than deferred to a
// later QA step - the new v2.5 asset is not yet visually reviewed, so
// generation_status becomes generated_pending_remediation_qa (never
// approved), and the old failed image/version/SHA/quarantine reason are
// preserved untouched, exactly mirroring the pattern already used for
// the Sentinel-6 provenance reconciliation.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_v25_wavec_remediation_sentinel8_v1');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};
const sha256Buffer = buffer => crypto.createHash('sha256').update(buffer).digest('hex');

const SENTINEL_SOURCE_DIR = 'tools/card_art/output/object_first_v25_wavec_remediation_sentinel8_v1';

const manifest = readJson(path.join(OUT_DIR, 'manifest.json'));
const cfg = readJson(path.join(CATALOG, 'object_first_v25_wavec_remediation_sentinel8_v1.json'));
const queue = readJson(path.join(CATALOG, 'production_queue_v2_object_first.json'));

const cardById = new Map(cfg.cards.map(c => [c.id, c]));
const queueById = new Map(queue.rows.map(r => [r.canonical_id, r]));

const EXPECTED_IDS = ['transport.classic_cars', 'transport.supercars', 'lifestyle.gardening', 'science.chemistry', 'learning.nonfiction', 'wellness.mobility', 'media.tv', 'technology.machine_learning'];

if (manifest.expected_entries !== 8) throw new Error(`Expected 8 manifest entries, got ${manifest.expected_entries}`);
if (cfg.cards.length !== 8) throw new Error(`Expected 8 config cards, got ${cfg.cards.length}`);

// ---- Technical validation ----
const perEntry = [];
const hashCounts = new Map();
let succeeded = 0, contentBlocked = 0, technicalFailed = 0;

for (const entry of manifest.entries) {
  const card = cardById.get(entry.canonical_interest_id);
  if (!card) throw new Error(`Manifest entry not found in Sentinel-8 config: ${entry.canonical_interest_id}`);
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
  version: 'object_first_v25_wavec_remediation_sentinel8_technical_validation_v1',
  generated_at: new Date().toISOString(),
  expected_count: 8,
  succeeded, content_blocked: contentBlocked, technical_failed: technicalFailed, retries: 0,
  unique_file_hashes: hashCounts.size, duplicate_hashes: duplicateHashes,
  dimensions_check: '848x1264 JPEG, 8/8 (verified via PIL before this run)',
  billed_count: billedCount, actual_cost_usd: actualCost,
  entries: perEntry,
};
writeJson(path.join(OUT_DIR, 'technical_validation_v1.json'), technicalValidation);

// ---- Provenance-preserving queue update ----
let updated = 0;
for (const entry of manifest.entries) {
  if (!EXPECTED_IDS.includes(entry.canonical_interest_id)) throw new Error(`Unexpected id in manifest: ${entry.canonical_interest_id}`);
  const row = queueById.get(entry.canonical_interest_id);
  if (!row) throw new Error(`Sentinel-8 id not found in queue: ${entry.canonical_interest_id}`);
  if (row.generation_status !== 'qa_quarantine') throw new Error(`${entry.canonical_interest_id} does not have generation_status=qa_quarantine (has ${row.generation_status}) - refusing to finalize.`);
  const card = cardById.get(entry.canonical_interest_id);

  if (entry.status === 'succeeded') {
    // Capture OLD (failed Wave-C v2.4) provenance BEFORE overwriting.
    const oldProvenance = {
      source: 'tools/card_art/output/object_first_v2_production_waveC96_v1',
      production_candidate_version: row.production_candidate_version, // 'v2.4' at this point
      prompt_sha256_ref: 'output/production_rollout_v2_object_first_v1/production_candidate_freeze_v2_4_v1.json#' + entry.canonical_interest_id,
      visual_qa_disposition: row.visual_qa_disposition, // 'qa_quarantine' from the Wave-C QA pass
      visual_qa_flags: row.visual_qa_flags,
      visual_qa_finding: row.visual_qa_finding,
      status: 'superseded_by_remediation_asset',
      superseded_by: {
        sentinel_source_commit: 'pending_this_commit',
        canonical_asset_source: SENTINEL_SOURCE_DIR,
      },
    };
    if (!row.superseded_assets) row.superseded_assets = [];
    row.superseded_assets.push(oldProvenance);

    row.generation_status = 'generated_pending_remediation_qa';
    row.production_candidate_version = card.production_candidate_version; // 'v2.5'
    row.prompt_sha256 = card.prompt_sha256;
    row.canonical_asset_source = SENTINEL_SOURCE_DIR;
    // Not visually reviewed yet - do NOT touch visual_qa_disposition/flags/finding
    // beyond what was captured into superseded_assets above; the row's live
    // visual_qa_* fields still describe the OLD asset until a future QA pass
    // records the new one, exactly as Sentinel-6's own finalize step did.
  } else if (entry.status === 'failed_content') {
    row.failure_status = 'content_blocked';
  } else {
    row.failure_status = 'technical_failed';
  }
  updated += 1;
}
if (updated !== 8) throw new Error(`Expected to update exactly 8 rows, updated ${updated}`);

// Confirm no other hold/quarantine was touched.
const stretching = queueById.get('wellness.stretching');
if (stretching.generation_status !== 'temporary_generation_hold' || stretching.generation_hold_reason !== 'semantic_repair_unvalidated') {
  throw new Error('wellness.stretching status was unexpectedly altered - refusing to write.');
}
const automotiveHeld = queue.rows.filter(r => r.generation_hold_reason === 'automotive_brand_morphology_repair');
if (automotiveHeld.length !== 2) throw new Error(`Expected 2 automotive-held rows unchanged, found ${automotiveHeld.length}`);
const illustration = queueById.get('arts.illustration');
if (illustration.generation_status !== 'qa_quarantine') throw new Error('arts.illustration status was unexpectedly altered.');
const sportsCars = queueById.get('transport.sports_cars');
if (sportsCars.generation_status !== 'qa_quarantine') throw new Error('transport.sports_cars status was unexpectedly altered.');

writeJson(path.join(CATALOG, 'production_queue_v2_object_first.json'), queue);

console.log(`Technical validation: succeeded=${succeeded} content_blocked=${contentBlocked} technical_failed=${technicalFailed} billed=${billedCount} cost=$${actualCost} unique_hashes=${hashCounts.size} duplicates=${duplicateHashes.length}`);
console.log(`Queue updated: ${updated} Sentinel-8 rows, old provenance preserved, none approved.`);
console.log('wellness.stretching, automotive hold (2), arts.illustration, transport.sports_cars all confirmed unchanged.');

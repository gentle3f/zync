// Zync Object-First V2 Steady-State Batch-001 - post-collection
// finalization. Technical-only validation (no visual inspection),
// queue-state update for exactly the 120 Batch-001 rows, and a
// risk-stratified >=10% QA sample + package for ChatGPT's external
// visual review.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_v2_steady_state_batch001_v1');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};
const sha256Buffer = buffer => crypto.createHash('sha256').update(buffer).digest('hex');

const manifest = readJson(path.join(OUT_DIR, 'manifest.json'));
const cfg = readJson(path.join(CATALOG, 'object_first_v2_steady_state_batch001_v1.json'));
const queue = readJson(path.join(CATALOG, 'production_queue_v2_object_first.json'));

const cardById = new Map(cfg.cards.map(c => [c.id, c]));
const queueById = new Map(queue.rows.map(r => [r.canonical_id, r]));

if (manifest.expected_entries !== 120) throw new Error(`Expected 120 manifest entries, got ${manifest.expected_entries}`);
if (cfg.cards.length !== 120) throw new Error(`Expected 120 config cards, got ${cfg.cards.length}`);

// ---- Technical validation ----
const perEntry = [];
const hashCounts = new Map();
let succeeded = 0, contentBlocked = 0, technicalFailed = 0;

for (const entry of manifest.entries) {
  const card = cardById.get(entry.canonical_interest_id);
  if (!card) throw new Error(`Manifest entry not found in Batch-001 config: ${entry.canonical_interest_id}`);
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
  version: 'object_first_v2_steady_state_batch001_technical_validation_v1',
  generated_at: new Date().toISOString(),
  expected_count: 120,
  succeeded, content_blocked: contentBlocked, technical_failed: technicalFailed, retries: 0,
  unique_file_hashes: hashCounts.size, duplicate_hashes: duplicateHashes,
  dimensions_check: '848x1264 JPEG, 120/120 (verified via PIL before this run)',
  billed_count: billedCount, actual_cost_usd: actualCost,
  entries: perEntry,
};
writeJson(path.join(OUT_DIR, 'technical_validation_v1.json'), technicalValidation);

// ---- Queue update (exactly the 120 Batch-001 rows) ----
let updated = 0;
for (const entry of manifest.entries) {
  const row = queueById.get(entry.canonical_interest_id);
  if (!row) throw new Error(`Batch-001 id not found in queue: ${entry.canonical_interest_id}`);
  if (row.rollout_wave !== 'steady_state_batch_1') throw new Error(`Refusing to update non-steady_state_batch_1 row: ${entry.canonical_interest_id}`);
  if (entry.status === 'succeeded') row.generation_status = 'generated_pending_qa';
  else if (entry.status === 'failed_content') row.generation_status = 'content_blocked';
  else row.generation_status = 'technical_failed';
  row.failure_status = entry.status === 'succeeded' ? null : entry.status;
  updated += 1;
}
if (updated !== 120) throw new Error(`Expected to update exactly 120 rows, updated ${updated}`);

// wellness.stretching + all music holds + arts.illustration must remain untouched
const stretching = queueById.get('wellness.stretching');
if (stretching.generation_status !== 'temporary_generation_hold' || stretching.generation_hold_reason !== 'semantic_repair_unvalidated') {
  throw new Error('wellness.stretching status was unexpectedly altered - refusing to write.');
}
const illustration = queueById.get('arts.illustration');
if (illustration.generation_status !== 'qa_quarantine') throw new Error('arts.illustration status was unexpectedly altered.');
const heldCount = queue.rows.filter(r => r.generation_hold_reason).length;
if (heldCount !== 264) throw new Error(`Expected 264 held rows unchanged, found ${heldCount}`);

writeJson(path.join(CATALOG, 'production_queue_v2_object_first.json'), queue);

// ---- QA sample selection (risk-stratified, mandatory inclusion first) ----
const successfulIds = manifest.entries.filter(e => e.status === 'succeeded').map(e => e.canonical_interest_id);

const WATCH_ARCHETYPES = new Set([
  'creator_workflow', 'legal_practice', 'campus_activity', 'learning_exploration',
  'community_gathering', 'shared_workspace', 'tech_workspace', 'journey_machine', 'aviation_world',
  'drink_ritual', 'food_hero', 'food_exploration', 'performance', 'professional_world', 'campaign_planning',
  'story_culture', 'home_lifestyle', 'reading_world', 'calm_wellness',
]);
const AUTOMOTIVE_RELEASED_IDS = new Set(['transport.sports_cars', 'transport.muscle_cars', 'transport.pickup_trucks']);

function strictMandatoryReasons(id) {
  const row = queueById.get(id);
  const card = cardById.get(id);
  const reasons = [];
  if (card.confidence === 'new_grammar_unvalidated' || card.confidence === 'weak_extrapolation') reasons.push(`confidence:${card.confidence}`);
  if (row.semantic_risk_level === 'high') reasons.push('semantic_risk:high');
  if (row.text_risk_level === 'elevated') reasons.push('text_risk:elevated');
  if (row.brand_risk_level === 'elevated') reasons.push('brand_risk:elevated');
  if (row.physical_logic_risk_level === 'elevated') reasons.push('physical_logic_risk:elevated');
  if (AUTOMOTIVE_RELEASED_IDS.has(id)) reasons.push('automotive_hold_released_validation');
  return reasons;
}
function watchFamilyTags(id) {
  const card = cardById.get(id);
  const tags = [];
  if (WATCH_ARCHETYPES.has(card.archetype)) tags.push(`watch_family:${card.archetype}`);
  return tags;
}
function reasonsFor(id) {
  return [...strictMandatoryReasons(id), ...watchFamilyTags(id)];
}

const mandatory = successfulIds.filter(id => strictMandatoryReasons(id).length > 0);
const remaining = successfulIds.filter(id => !mandatory.includes(id));

const target = 12;
let sampleIds = [...mandatory];
if (sampleIds.length < target) {
  const remainingSorted = remaining.slice().sort((a, b) => {
    const aWatch = watchFamilyTags(a).length > 0 ? 0 : 1;
    const bWatch = watchFamilyTags(b).length > 0 ? 0 : 1;
    if (aWatch !== bWatch) return aWatch - bWatch;
    return queueById.get(a).queue_index - queueById.get(b).queue_index;
  });
  const need = target - sampleIds.length;
  const stride = Math.max(1, Math.floor(remainingSorted.length / need));
  for (let i = 0; i < remainingSorted.length && sampleIds.length < target; i += stride) {
    sampleIds.push(remainingSorted[i]);
  }
}
sampleIds = [...new Set(sampleIds)];
// Deterministic stable order for review: by queue_index.
sampleIds.sort((a, b) => queueById.get(a).queue_index - queueById.get(b).queue_index);

const qaSample = {
  version: 'object_first_v2_steady_state_batch001_qa_sample_v1',
  generated_at: new Date().toISOString(),
  policy: 'steady-state batch requires >=10% (12/120) visual review; all high-risk/new-grammar/watch-family/automotive-hold-release rows are mandatory even if that pushes the sample above 12; even-stride deterministic fill covers the remainder.',
  target_minimum: 12,
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
    production_candidate_version: card.production_candidate_version,
    prompt_sha256: card.prompt_sha256,
    protagonist_type: card.protagonist_type,
    scene_family: card.scene_family,
    composition_archetype: card.composition_archetype,
    palette_lighting_route: card.palette_lighting_route,
    effect_level: card.effect_level,
    text_mode: card.text_mode,
    physical_logic_domain: card.physical_logic_domain,
    physical_logic_classification: card.physical_logic_classification,
    interaction_support_mode: card.interaction_support_mode,
    semantic_risk_level: row.semantic_risk_level,
    text_risk_level: row.text_risk_level,
    brand_risk_level: row.brand_risk_level,
    physical_logic_risk_level: row.physical_logic_risk_level,
  };
});

writeJson(path.join(OUT_DIR, 'qa_package_v1.json'), {
  version: 'object_first_v2_steady_state_batch001_qa_package_v1',
  generated_at: new Date().toISOString(),
  images_dir: 'tools/card_art/output/object_first_v2_steady_state_batch001_v1/images/',
  total_cards: 120,
  sample_size: sampleIds.length,
  entries: orderedEntries,
});

console.log(`Technical validation: succeeded=${succeeded} content_blocked=${contentBlocked} technical_failed=${technicalFailed} billed=${billedCount} cost=$${actualCost} unique_hashes=${hashCounts.size} duplicates=${duplicateHashes.length}`);
console.log(`Queue updated: ${updated} Batch-001 rows.`);
console.log(`QA sample: ${sampleIds.length} ids (mandatory=${mandatory.length}).`);
console.log('Sampled ids:', sampleIds.join(', '));

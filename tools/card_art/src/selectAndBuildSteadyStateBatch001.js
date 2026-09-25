// Zync Object-First V2 Steady-State Batch-001 selection + frozen-prompt
// bundle build. Uses the pre-existing stratified steady_state_batch_1
// assignment (116 rows, not 120 - some were already reassigned to
// earlier waves as shortfall replacements), drops any row no longer
// eligible (held/decided), explicitly force-includes the 3 rows just
// returned to eligibility by the automotive hold release
// (transport.sports_cars, transport.muscle_cars, transport.pickup_trucks -
// the whole point of releasing them now is to validate that decision at
// scale, per the task's own QA-sample priority list), and fills any
// remaining shortfall deterministically from the next eligible row (by
// queue_index) in the later steady-state pool - the same pattern already
// used and proven for Wave-B/Wave-C.
//
// Zero-cost. No image generated.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_ROLLOUT = path.join(ROOT, 'output', 'production_rollout_v2_object_first_v1');
const OUT_BATCH = path.join(ROOT, 'output', 'object_first_v2_steady_state_batch001_v1');
const AUDIT_DIR_V24 = path.join(ROOT, 'output', 'object_first_v2_4_full_catalog_audit_v1');
const AUDIT_DIR_V25 = path.join(ROOT, 'output', 'object_first_v2_5_full_catalog_audit_v1');

const QUEUE_PATH = path.join(CATALOG, 'production_queue_v2_object_first.json');
const FREEZE_V24_PATH = path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_4_v1.json');
const FREEZE_V25_PATH = path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_5_v1.json');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};
const sha256Text = text => crypto.createHash('sha256').update(text, 'utf8').digest('hex');

const FORCE_INCLUDE_IDS = ['transport.sports_cars', 'transport.muscle_cars', 'transport.pickup_trucks'];

function main() {
  const queue = readJson(QUEUE_PATH);
  const freezeV24 = readJson(FREEZE_V24_PATH);
  const freezeV25 = readJson(FREEZE_V25_PATH);
  const freezeV24ById = new Map(freezeV24.rows.map(r => [r.canonical_interest_id, r]));
  const freezeV25ById = new Map(freezeV25.rows.map(r => [r.canonical_interest_id, r]));
  const queueById = new Map(queue.rows.map(r => [r.canonical_id, r]));

  const isEligible = row => row.generation_status === 'pending_generation' && !row.generation_hold_reason;

  const preAssigned = queue.rows.filter(r => r.rollout_wave === 'steady_state_batch_1');
  const kept = preAssigned.filter(isEligible);
  const droppedIds = preAssigned.filter(r => !isEligible(r)).map(r => r.canonical_id);

  const keptIds = new Set(kept.map(r => r.canonical_id));

  // Force-include the 3 automotive rows just released back to eligibility.
  const forced = [];
  for (const id of FORCE_INCLUDE_IDS) {
    const row = queueById.get(id);
    if (!row) throw new Error(`Force-include id not found in queue: ${id}`);
    if (!isEligible(row)) throw new Error(`Force-include id is not eligible: ${id} (status=${row.generation_status}, hold=${row.generation_hold_reason})`);
    if (keptIds.has(id)) continue; // already in the pre-assigned set, no duplicate
    forced.push(row);
    keptIds.add(id);
  }

  const target = 120;
  const eligiblePool = queue.rows
    .filter(r => String(r.rollout_wave).startsWith('steady_state_batch_') && r.rollout_wave !== 'steady_state_batch_1')
    .filter(isEligible)
    .sort((a, b) => a.queue_index - b.queue_index);

  const alreadySelectedCount = kept.length + forced.length;
  const shortfall = target - alreadySelectedCount;
  const replacements = [];
  for (let i = 0; i < shortfall; i++) {
    const next = eligiblePool.find(r => !keptIds.has(r.canonical_id) && !replacements.some(x => x.canonical_id === r.canonical_id));
    if (!next) throw new Error(`No deterministic replacement available for Batch-001 shortfall slot ${i}`);
    replacements.push(next);
    keptIds.add(next.canonical_id);
  }

  const finalBatch = [...kept, ...forced, ...replacements];
  if (finalBatch.length !== 120) throw new Error(`Batch-001 selection did not resolve to exactly 120 rows (got ${finalBatch.length})`);
  if (new Set(finalBatch.map(r => r.canonical_id)).size !== 120) throw new Error('Batch-001 selection contains duplicate ids');

  const FORBIDDEN_IDS = new Set(['business.startups', 'music.rock', 'motorsport.cars', 'sports.american_football', 'technology.robotics', 'wellness.stretching', 'arts.illustration']);
  for (const row of finalBatch) {
    if (FORBIDDEN_IDS.has(row.canonical_id)) throw new Error(`Forbidden/held/quarantined id leaked into Batch-001 selection: ${row.canonical_id}`);
    if (row.generation_hold_reason) throw new Error(`Held id leaked into Batch-001 selection: ${row.canonical_id}`);
  }

  // Assign rollout_wave: dropped pre-assigned ids get unassigned; the
  // whole final batch gets tagged steady_state_batch_1.
  const droppedIdSet = new Set(droppedIds);
  for (const row of queue.rows) {
    if (droppedIdSet.has(row.canonical_id)) row.rollout_wave = null;
  }
  for (const row of finalBatch) row.rollout_wave = 'steady_state_batch_1';

  // Build cards + frozen prompts, sourcing each row from its CURRENT
  // authoritative freeze (v2.5 if the row's queue-recorded version is
  // v2.5, else v2.4) - per-row versioning preserved, never flattened.
  const compiledV24 = fs.readFileSync(path.join(AUDIT_DIR_V24, 'compiled_prompts_v1.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  const compiledV25 = fs.readFileSync(path.join(AUDIT_DIR_V25, 'compiled_prompts_v1.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  const compiledV24ById = new Map(compiledV24.map(l => [l.canonical_interest_id, l]));
  const compiledV25ById = new Map(compiledV25.map(l => [l.canonical_interest_id, l]));

  const cards = [];
  const frozenPrompts = [];
  for (const row of finalBatch) {
    const version = row.production_candidate_version;
    if (version !== 'v2.4' && version !== 'v2.5') throw new Error(`Unexpected production_candidate_version for ${row.canonical_id}: ${version}`);
    const freezeRow = (version === 'v2.5' ? freezeV25ById : freezeV24ById).get(row.canonical_id);
    if (!freezeRow) throw new Error(`Batch-001 id missing from its ${version} freeze: ${row.canonical_id}`);
    const compiled = (version === 'v2.5' ? compiledV25ById : compiledV24ById).get(row.canonical_id);
    if (!compiled) throw new Error(`Batch-001 id missing from its ${version} compiled_prompts_v1.jsonl: ${row.canonical_id}`);

    const liveSha = sha256Text(compiled.final_compiled_prompt);
    if (liveSha !== freezeRow.prompt_sha256) throw new Error(`SHA256 mismatch (freeze vs compiled) for ${row.canonical_id} at ${version}`);
    if (liveSha !== row.prompt_sha256) throw new Error(`SHA256 mismatch (queue vs compiled) for ${row.canonical_id} at ${version}`);

    cards.push({
      id: row.canonical_id,
      queue_index: row.queue_index,
      title: freezeRow.title,
      archetype: freezeRow.archetype,
      production_candidate_version: version,
      protagonist_type: freezeRow.protagonist_type,
      structural_containment_rule_id: freezeRow.structural_containment_rule_id,
      confidence: freezeRow.confidence,
      composition_archetype: freezeRow.composition_archetype,
      palette_lighting_route: freezeRow.palette_lighting_route,
      effect_level: freezeRow.effect_level,
      scene_family: freezeRow.scene_family,
      text_mode: freezeRow.text_mode,
      physical_logic_domain: freezeRow.physical_logic_domain,
      physical_logic_classification: freezeRow.physical_logic_classification,
      interaction_support_mode: freezeRow.interaction_support_mode || null,
      semantic_risk_level: row.semantic_risk_level,
      text_risk_level: row.text_risk_level,
      brand_risk_level: row.brand_risk_level,
      physical_logic_risk_level: row.physical_logic_risk_level,
      runtime_category: row.runtime_category,
      prompt_sha256: liveSha,
    });
    frozenPrompts.push({ canonical_interest_id: row.canonical_id, final_compiled_prompt: compiled.final_compiled_prompt });
  }

  if (cards.length !== 120) throw new Error(`Expected 120 Batch-001 cards, got ${cards.length}`);

  writeJson(path.join(CATALOG, 'object_first_v2_steady_state_batch001_v1.json'), {
    version: 'object_first_v2_steady_state_batch001_v1',
    generated_at: new Date().toISOString(),
    total_cards: cards.length,
    expected_max_cost_usd: Number((cards.length * 0.0168).toFixed(4)),
    dropped_from_preassignment: droppedIds,
    force_included_automotive_ids: forced.map(r => r.canonical_id),
    deterministic_replacements: replacements.map(r => ({ canonical_id: r.canonical_id, from_wave: r.rollout_wave, queue_index: r.queue_index })),
    cards,
  });
  writeJson(path.join(OUT_BATCH, 'frozen_prompts_v1.json'), frozenPrompts);

  writeJson(QUEUE_PATH, queue);

  console.log(`Batch-001: ${cards.length} cards selected. Dropped from pre-assignment: ${droppedIds.join(', ') || '(none)'}.`);
  console.log(`Force-included automotive: ${forced.map(r => r.canonical_id).join(', ') || '(none)'}`);
  console.log(`Replacements: ${replacements.map(r => r.canonical_id).join(', ') || '(none)'}`);
  console.log('Version distribution:', JSON.stringify(cards.reduce((acc, c) => { acc[c.production_candidate_version] = (acc[c.production_candidate_version] || 0) + 1; return acc; }, {})));
}

main();

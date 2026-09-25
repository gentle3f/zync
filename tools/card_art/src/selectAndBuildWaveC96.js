// Zync Object-First V2 Production Wave-C-96 selection + frozen-prompt
// bundle build. Uses the pre-existing stratified wave_c_96 assignment
// (built in the zero-cost rollout-engineering checkpoint, commit 3ca31bd),
// dropping any row that is no longer eligible (held, quarantined, or
// otherwise non-pending) and deterministically filling the shortfall from
// the next eligible row (by queue_index) in the steady-state pool - the
// same pattern already used and proven for the Wave-B-48 music.pop
// replacement.
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
const OUT_WAVEC = path.join(ROOT, 'output', 'object_first_v2_production_waveC96_v1');
const AUDIT_DIR = path.join(ROOT, 'output', 'object_first_v2_4_full_catalog_audit_v1');
const AUDIT_DIR_241 = path.join(ROOT, 'output', 'object_first_v2_4_1_full_catalog_audit_v1');

const QUEUE_PATH = path.join(CATALOG, 'production_queue_v2_object_first.json');
const FREEZE_V24_PATH = path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_4_v1.json');
const FREEZE_V241_PATH = path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_4_1_v1.json');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};
const sha256Text = text => crypto.createHash('sha256').update(text, 'utf8').digest('hex');

function main() {
  const queue = readJson(QUEUE_PATH);
  const freezeV24 = readJson(FREEZE_V24_PATH);
  const freezeV241 = readJson(FREEZE_V241_PATH);
  const freezeV24ById = new Map(freezeV24.rows.map(r => [r.canonical_interest_id, r]));
  const freezeV241ById = new Map(freezeV241.rows.map(r => [r.canonical_interest_id, r]));

  const isEligible = row => row.generation_status === 'pending_generation' && !row.generation_hold_reason;

  const preAssigned = queue.rows.filter(r => r.rollout_wave === 'wave_c_96');
  const kept = preAssigned.filter(isEligible);
  const droppedIds = preAssigned.filter(r => !isEligible(r)).map(r => r.canonical_id);

  const keptIds = new Set(kept.map(r => r.canonical_id));
  const eligiblePool = queue.rows
    .filter(r => String(r.rollout_wave).startsWith('steady_state_batch_'))
    .filter(isEligible)
    .sort((a, b) => a.queue_index - b.queue_index);

  // Shortfall = 96 minus however many pre-assigned rows are still
  // eligible - this covers both rows dropped for being newly held/
  // quarantined AND the pre-existing 1-row shortfall in the wave_c_96
  // pre-assignment itself (one row, collecting.stamps, was already
  // reassigned to wave_b_48 as its music.pop replacement in an earlier
  // checkpoint, leaving only 95 pre-assigned instead of 96).
  const target = 96;
  const shortfall = target - kept.length;
  const replacements = [];
  for (let i = 0; i < shortfall; i++) {
    const next = eligiblePool.find(r => !keptIds.has(r.canonical_id) && !replacements.some(x => x.canonical_id === r.canonical_id));
    if (!next) throw new Error(`No deterministic replacement available for Wave-C shortfall slot ${i}`);
    replacements.push(next);
    keptIds.add(next.canonical_id);
  }

  const finalWaveC = [...kept, ...replacements];
  if (finalWaveC.length !== 96) throw new Error(`Wave-C selection did not resolve to exactly 96 rows (got ${finalWaveC.length})`);
  if (new Set(finalWaveC.map(r => r.canonical_id)).size !== 96) throw new Error('Wave-C selection contains duplicate ids');

  // Hard exclusion re-verification (belt-and-suspenders on top of isEligible()).
  const FORBIDDEN_IDS = new Set(['business.startups', 'music.rock', 'motorsport.cars', 'sports.american_football', 'technology.robotics', 'wellness.stretching',
    'food.coffee', 'learning.fiction', 'music.singing', 'music.karaoke', 'learning.book_genre.booktube', 'technology.gadgets']);
  for (const row of finalWaveC) {
    if (FORBIDDEN_IDS.has(row.canonical_id)) throw new Error(`Forbidden/already-decided id leaked into Wave-C selection: ${row.canonical_id}`);
    if (row.generation_hold_reason) throw new Error(`Held id leaked into Wave-C selection: ${row.canonical_id}`);
  }

  // Assign rollout_wave; dropped ids get unassigned (they keep whatever
  // hold/quarantine/non-pending state already explains their exclusion).
  const droppedIdSet = new Set(droppedIds);
  for (const row of queue.rows) {
    if (droppedIdSet.has(row.canonical_id)) row.rollout_wave = null;
  }
  for (const row of finalWaveC) row.rollout_wave = 'wave_c_96';

  // Build cards + frozen prompts, sourcing each row from its CURRENT
  // authoritative freeze (v2.4.1 if the row's queue-recorded version is
  // v2.4.1, else v2.4) - per-row versioning is preserved, never flattened.
  const compiledV24 = fs.readFileSync(path.join(AUDIT_DIR, 'compiled_prompts_v1.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  const compiledV241 = fs.readFileSync(path.join(AUDIT_DIR_241, 'compiled_prompts_v1.jsonl'), 'utf8').trim().split('\n').map(JSON.parse);
  const compiledV24ById = new Map(compiledV24.map(l => [l.canonical_interest_id, l]));
  const compiledV241ById = new Map(compiledV241.map(l => [l.canonical_interest_id, l]));

  const cards = [];
  const frozenPrompts = [];
  for (const row of finalWaveC) {
    const version = row.production_candidate_version;
    if (version !== 'v2.4' && version !== 'v2.4.1') throw new Error(`Unexpected production_candidate_version for ${row.canonical_id}: ${version}`);
    const freezeRow = (version === 'v2.4.1' ? freezeV241ById : freezeV24ById).get(row.canonical_id);
    if (!freezeRow) throw new Error(`Wave-C id missing from its ${version} freeze: ${row.canonical_id}`);
    const compiled = (version === 'v2.4.1' ? compiledV241ById : compiledV24ById).get(row.canonical_id);
    if (!compiled) throw new Error(`Wave-C id missing from its ${version} compiled_prompts_v1.jsonl: ${row.canonical_id}`);

    const liveSha = sha256Text(compiled.final_compiled_prompt);
    if (liveSha !== freezeRow.prompt_sha256) throw new Error(`SHA256 mismatch (freeze vs compiled) for ${row.canonical_id} at ${version}`);
    if (liveSha !== row.prompt_sha256) throw new Error(`SHA256 mismatch (queue vs compiled) for ${row.canonical_id} at ${version}`);

    cards.push({
      id: row.canonical_id,
      title: freezeRow.title,
      archetype: freezeRow.archetype,
      production_candidate_version: version,
      protagonist_type: freezeRow.protagonist_type,
      object_first_status: freezeRow.object_first_status,
      structural_containment_rule_id: freezeRow.structural_containment_rule_id,
      confidence: freezeRow.confidence,
      composition_archetype: freezeRow.composition_archetype,
      palette_lighting_route: freezeRow.palette_lighting_route,
      effect_level: freezeRow.effect_level,
      scene_family: freezeRow.scene_family,
      text_mode: freezeRow.text_mode,
      physical_logic_domain: freezeRow.physical_logic_domain,
      physical_logic_classification: freezeRow.physical_logic_classification,
      semantic_risk_level: row.semantic_risk_level,
      text_risk_level: row.text_risk_level,
      brand_risk_level: row.brand_risk_level,
      physical_logic_risk_level: row.physical_logic_risk_level,
      runtime_category: row.runtime_category,
      prompt_sha256: liveSha,
    });
    frozenPrompts.push({ canonical_interest_id: row.canonical_id, final_compiled_prompt: compiled.final_compiled_prompt });
  }

  if (cards.length !== 96) throw new Error(`Expected 96 Wave-C cards, got ${cards.length}`);

  writeJson(path.join(CATALOG, 'object_first_v2_production_waveC96_v1.json'), {
    version: 'object_first_v2_production_waveC96_v1',
    generated_at: new Date().toISOString(),
    total_cards: cards.length,
    expected_max_cost_usd: Number((cards.length * 0.0168).toFixed(4)),
    dropped_from_preassignment: droppedIds,
    deterministic_replacements: replacements.map(r => ({ canonical_id: r.canonical_id, from_wave: 'steady_state', queue_index: r.queue_index })),
    cards,
  });
  writeJson(path.join(OUT_WAVEC, 'frozen_prompts_v1.json'), frozenPrompts);

  writeJson(QUEUE_PATH, queue);

  console.log(`Wave-C-96: ${cards.length} cards selected. Dropped from pre-assignment: ${droppedIds.join(', ') || '(none)'}. Replacements: ${replacements.map(r => r.canonical_id).join(', ') || '(none)'}.`);
  console.log('Version distribution:', JSON.stringify(cards.reduce((acc, c) => { acc[c.production_candidate_version] = (acc[c.production_candidate_version] || 0) + 1; return acc; }, {})));
}

main();

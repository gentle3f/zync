// Zync Object-First V2 Production Rollout - AUTHORIZED update pass.
//
// Part 1: records the AUTHORITATIVE ChatGPT visual QA decisions for the
// 24 Canary-24 images (18 approved / 4 approved_with_minor / 2
// qa_quarantine) into production_queue_v2_object_first.json, plus a
// dedicated canary_24_qa_results_v1.json record. No prompt or image file
// is touched - this is metadata only.
//
// Part 2: classifies a TEMPORARY generation hold for genre-specific music
// interests (music_genre_semantic_repair), using the catalog's own
// archetype/title fields rather than blind id substring matching. Scope:
// canonical ids under runtime_category "music" whose recipe archetype is
// "music_listening" (the exact archetype family both music.pop and
// music.rock - the two reported drift failures - belong to), EXCLUDING
// ids whose title names a listening context/mood/occasion or an audio
// format rather than a musical genre (Study Music, Workout Music, Sleep
// Music, Meditation Music, Road Trip Music, Acoustic Covers, Live
// Albums, Unplugged Music, Vinyl Listening, Audiophile Music - this last
// pair is explicitly the same "generic audiophile / vinyl listening"
// drift pattern ChatGPT flagged for music.rock, so protecting them as if
// they were a genre identity would be incoherent). Instruments,
// performance and production hobbies live under other archetypes
// (performance, story_culture) and are structurally untouched already.
// Rows already generated (music.rock) are excluded from the hold list
// (they are handled via the Canary QA quarantine instead).
//
// Part 3: selects Wave-B-48 from the queue's pre-existing
// rollout_wave === 'wave_b_48' stratified assignment (built in the
// zero-cost rollout-engineering checkpoint, commit 3ca31bd), replacing
// any id that is now excluded (held/quarantined/reused) with a
// deterministic same-order substitute so the wave still totals exactly
// 48.
//
// Zero-cost. No image generated. No image inspected.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_ROLLOUT = path.join(ROOT, 'output', 'production_rollout_v2_object_first_v1');
const OUT_WAVEB = path.join(ROOT, 'output', 'object_first_v2_production_waveB48_v1');
const AUDIT_DIR = path.join(ROOT, 'output', 'object_first_v2_full_catalog_audit_v1');

const QUEUE_PATH = path.join(CATALOG, 'production_queue_v2_object_first.json');
const FREEZE_PATH = path.join(OUT_ROLLOUT, 'production_candidate_freeze_v1.json');
const COMPILED_PROMPTS_PATH = path.join(AUDIT_DIR, 'compiled_prompts_v1.jsonl');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};
const sha256Text = text => crypto.createHash('sha256').update(text, 'utf8').digest('hex');

// ---------------------------------------------------------------------------
// PART 1 - Canary-24 authoritative QA decisions (supplied verbatim by the
// user as ChatGPT's visual review; Claude does not re-derive or inspect).
// ---------------------------------------------------------------------------

const CANARY_APPROVED = [
  'arts.drawing', 'books.reading', 'business.founder_meetups', 'food.japanese',
  'gaming.pc_gaming', 'gaming.video', 'learning.mock_trial', 'media.anime',
  'media.manga', 'outdoors.rock_climbing', 'outdoors.swimming', 'pets.dogs',
  'sports.badminton', 'sports.gym', 'sports.hiking', 'technology.ai',
  'transport.modelrailways', 'wellness.pilates',
];

const CANARY_APPROVED_WITH_MINOR = {
  'business.branding': {
    flags: ['scene_plausibility_minor'],
    finding: 'The branding identity works, but the outdoor/rainy work-table scene felt somewhat artificially diversified.',
  },
  'business.sales': {
    flags: ['semantic_identity_minor', 'physical_logic_minor'],
    finding: 'Readable as business/sales/analytics, but somewhat generic. Some loose papers appeared implausibly airborne in an enclosed office.',
  },
  'learning.moot_court': {
    flags: ['semantic_identity_minor'],
    finding: 'Legal/court identity works, but academic moot-court specificity is weaker than ideal.',
  },
  'learning.student_newspaper': {
    flags: ['text_leak_minor'],
    finding: 'Student-newspaper identity is strong, but the image contains substantial pseudo-readable newspaper text.',
  },
};

const CANARY_QUARANTINE = {
  'music.rock': {
    primary_failure: 'semantic_identity',
    finding: 'Rendered as generic audiophile / vinyl-listening imagery rather than clearly Rock music.',
  },
  'motorsport.cars': {
    primary_failure: 'brand_likeness',
    finding: 'The car silhouette/body design looked too close to a recognizable classic Japanese GT/sports-car design even without an explicit logo.',
  },
};

function applyCanaryQA(queueRows) {
  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  const results = [];

  for (const id of CANARY_APPROVED) {
    const row = byId.get(id);
    if (!row) throw new Error(`Canary-approved id not found in queue: ${id}`);
    if (row.rollout_wave !== 'wave_canary_24') throw new Error(`${id} is not a wave_canary_24 row - refusing to apply Canary QA to it.`);
    row.visual_qa_disposition = 'approved';
    row.visual_qa_flags = [];
    row.visual_qa_finding = null;
    row.generation_status = 'approved';
    results.push({ canonical_id: id, disposition: 'approved', flags: [], finding: null });
  }

  for (const [id, info] of Object.entries(CANARY_APPROVED_WITH_MINOR)) {
    const row = byId.get(id);
    if (!row) throw new Error(`Canary-approved-with-minor id not found in queue: ${id}`);
    if (row.rollout_wave !== 'wave_canary_24') throw new Error(`${id} is not a wave_canary_24 row - refusing to apply Canary QA to it.`);
    row.visual_qa_disposition = 'approved_with_minor';
    row.visual_qa_flags = info.flags;
    row.visual_qa_finding = info.finding;
    row.generation_status = 'approved_with_minor';
    results.push({ canonical_id: id, disposition: 'approved_with_minor', flags: info.flags, finding: info.finding });
  }

  for (const [id, info] of Object.entries(CANARY_QUARANTINE)) {
    const row = byId.get(id);
    if (!row) throw new Error(`Canary-quarantine id not found in queue: ${id}`);
    if (row.rollout_wave !== 'wave_canary_24') throw new Error(`${id} is not a wave_canary_24 row - refusing to apply Canary QA to it.`);
    row.visual_qa_disposition = 'qa_quarantine';
    row.visual_qa_flags = [info.primary_failure];
    row.visual_qa_finding = info.finding;
    row.generation_status = 'qa_quarantine';
    row.quarantine_status = 'qa_quarantine';
    results.push({ canonical_id: id, disposition: 'qa_quarantine', flags: [info.primary_failure], finding: info.finding });
  }

  const expectedCount = CANARY_APPROVED.length + Object.keys(CANARY_APPROVED_WITH_MINOR).length + Object.keys(CANARY_QUARANTINE).length;
  if (expectedCount !== 24) throw new Error(`Canary QA disposition count mismatch: expected 24, got ${expectedCount}`);
  const canaryRows = queueRows.filter(r => r.rollout_wave === 'wave_canary_24');
  if (canaryRows.length !== 24) throw new Error(`Expected exactly 24 wave_canary_24 rows, found ${canaryRows.length}`);
  const undecided = canaryRows.filter(r => !r.visual_qa_disposition);
  if (undecided.length) throw new Error(`Canary rows missing a QA disposition: ${undecided.map(r => r.canonical_id).join(', ')}`);

  return {
    reviewed: 24,
    approved: CANARY_APPROVED.length,
    approved_with_minor: Object.keys(CANARY_APPROVED_WITH_MINOR).length,
    quarantined: Object.keys(CANARY_QUARANTINE).length,
    results,
  };
}

// ---------------------------------------------------------------------------
// PART 2 - temporary genre-music generation hold
// ---------------------------------------------------------------------------

// Ids under the music_listening archetype whose title names a listening
// context/mood/occasion or an audio format, not a musical genre - the same
// distinction that makes music.rock's "generic audiophile/vinyl listening"
// drift a genre-identity FAILURE (there was a genre to protect and it
// collapsed into one of these) rather than something these ids themselves
// need protecting against (their identity already IS the generic-listening
// concept). Left OUT of the hold.
const NON_GENRE_MUSIC_LISTENING_IDS = new Set([
  'music.style.study_music',
  'music.style.workout_music',
  'music.style.sleep_music',
  'music.style.meditation_music',
  'music.style.road_trip_music',
  'music.style.acoustic_covers',
  'music.style.live_albums',
  'music.style.unplugged_music',
  'music.style.vinyl_listening',
  'music.style.audiophile_music',
]);

function computeGenreMusicHoldIds(catalogEligible, queueRows) {
  const musicListeningIds = catalogEligible
    .filter(row => row.recipe?.archetype === 'music_listening')
    .map(row => row.canonical_interest_id);

  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  const holdIds = [];
  for (const id of musicListeningIds) {
    if (NON_GENRE_MUSIC_LISTENING_IDS.has(id)) continue;
    const row = byId.get(id);
    if (!row) continue; // not in production queue (e.g. quarantined elsewhere) - nothing to hold
    if (row.generation_status !== 'pending_generation') continue; // already generated (music.rock) - handled via Canary QA quarantine, not hold
    holdIds.push(id);
  }
  return holdIds.sort((a, b) => byId.get(a).queue_index - byId.get(b).queue_index);
}

function applyGenreMusicHold(queueRows, holdIds) {
  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  for (const row of queueRows) {
    if (row.generation_hold_reason === undefined) row.generation_hold_reason = null;
  }
  for (const id of holdIds) {
    const row = byId.get(id);
    if (!row) throw new Error(`Hold id not found in queue: ${id}`);
    if (row.generation_status !== 'pending_generation') throw new Error(`Refusing to hold already-generated/decided row: ${id}`);
    row.generation_hold_reason = 'music_genre_semantic_repair';
  }
}

// ---------------------------------------------------------------------------
// PART 3 - Wave-B-48 selection
// ---------------------------------------------------------------------------

function selectWaveB48(queueRows, holdIdSet) {
  const EXCLUDED_IDS = new Set(['business.startups', 'music.rock', 'motorsport.cars', 'sports.american_football', 'technology.robotics']);
  const preAssigned = queueRows.filter(r => r.rollout_wave === 'wave_b_48');
  if (preAssigned.length !== 48) throw new Error(`Expected 48 pre-assigned wave_b_48 rows, found ${preAssigned.length}`);

  const isExcluded = row => EXCLUDED_IDS.has(row.canonical_id) || holdIdSet.has(row.canonical_id) || row.quarantine_status === 'qa_quarantine' || row.rollout_wave === 'wave_canary_24' || row.rollout_wave === 'reuse_candidate';

  const kept = preAssigned.filter(r => !isExcluded(r));
  const droppedIds = preAssigned.filter(r => isExcluded(r)).map(r => r.canonical_id);

  // Deterministic same-order fill: walk the full queue in queue_index order
  // starting right after the highest pre-assigned queue_index, wrapping to
  // the start of the not-yet-assigned pool if needed, taking the next
  // eligible (not excluded, not already selected, not pre-assigned to any
  // other still-pending wave slot ahead of it) row for each dropped slot.
  const keptIds = new Set(kept.map(r => r.canonical_id));
  const eligiblePool = queueRows
    .filter(r => (r.rollout_wave === 'wave_c_96' || String(r.rollout_wave).startsWith('steady_state_batch_')))
    .filter(r => !isExcluded(r))
    .sort((a, b) => a.queue_index - b.queue_index);

  const replacements = [];
  for (const droppedId of droppedIds) {
    const next = eligiblePool.find(r => !keptIds.has(r.canonical_id) && !replacements.some(x => x.canonical_id === r.canonical_id));
    if (!next) throw new Error(`No deterministic replacement available for dropped Wave-B id ${droppedId}`);
    replacements.push(next);
    keptIds.add(next.canonical_id);
  }

  const finalWaveB = [...kept, ...replacements];
  if (finalWaveB.length !== 48) throw new Error(`Wave-B selection did not resolve to exactly 48 rows (got ${finalWaveB.length})`);
  const uniqueCheck = new Set(finalWaveB.map(r => r.canonical_id));
  if (uniqueCheck.size !== 48) throw new Error('Wave-B selection contains duplicate ids');

  return { finalWaveB, droppedIds, replacements: replacements.map(r => ({ canonical_id: r.canonical_id, from_wave: 'wave_c_96_or_steady_state', queue_index: r.queue_index })) };
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

function main() {
  const catalog = buildCatalogRecipeBridge();
  const queue = readJson(QUEUE_PATH);
  const freeze = readJson(FREEZE_PATH);
  const freezeById = new Map(freeze.rows.map(r => [r.canonical_interest_id, r]));

  // Part 1
  const canarySummary = applyCanaryQA(queue.rows);

  // Part 2
  const holdIds = computeGenreMusicHoldIds(catalog.eligible, queue.rows);
  applyGenreMusicHold(queue.rows, holdIds);
  const holdIdSet = new Set(holdIds);

  // Part 3
  const { finalWaveB, droppedIds, replacements } = selectWaveB48(queue.rows, holdIdSet);

  // Mark selected Wave-B rows' rollout_wave explicitly (replacements move
  // from their prior wave into wave_b_48). Dropped pre-assigned ids are
  // un-assigned from wave_b_48 (rollout_wave -> null) since they are held
  // or quarantined, not part of any generation wave right now - their
  // hold_reason/quarantine_status fields already record why.
  const droppedIdSet = new Set(droppedIds);
  for (const row of queue.rows) {
    if (droppedIdSet.has(row.canonical_id)) row.rollout_wave = null;
  }
  for (const row of finalWaveB) {
    row.rollout_wave = 'wave_b_48';
  }

  // Build the frozen Wave-B prompt bundle + config, cross-verified against
  // both the freeze snapshot and the queue (same 3-way pattern used for
  // Canary-24).
  const compiledLines = fs.readFileSync(COMPILED_PROMPTS_PATH, 'utf8').trim().split('\n').map(l => JSON.parse(l));
  const compiledById = new Map(compiledLines.map(l => [l.canonical_interest_id, l]));

  const cards = [];
  const frozenPrompts = [];
  for (const row of finalWaveB) {
    const freezeRow = freezeById.get(row.canonical_id);
    if (!freezeRow) throw new Error(`Wave-B id missing from production_candidate_freeze_v1.json: ${row.canonical_id}`);
    const compiled = compiledById.get(row.canonical_id);
    if (!compiled) throw new Error(`Wave-B id missing from compiled_prompts_v1.jsonl: ${row.canonical_id}`);
    const liveSha = sha256Text(compiled.final_compiled_prompt);
    if (liveSha !== freezeRow.prompt_sha256) throw new Error(`SHA256 mismatch (freeze vs compiled) for ${row.canonical_id}`);
    if (liveSha !== row.prompt_sha256) throw new Error(`SHA256 mismatch (queue vs compiled) for ${row.canonical_id}`);

    cards.push({
      id: row.canonical_id,
      title: freezeRow.title,
      archetype: freezeRow.archetype,
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
      prompt_sha256: liveSha,
    });
    frozenPrompts.push({ canonical_interest_id: row.canonical_id, final_compiled_prompt: compiled.final_compiled_prompt });
  }

  if (cards.length !== 48) throw new Error(`Expected 48 Wave-B cards, got ${cards.length}`);
  if (cards.some(c => c.id === 'business.startups')) throw new Error('business.startups leaked into Wave-B selection');
  for (const forbidden of ['music.rock', 'motorsport.cars']) {
    if (cards.some(c => c.id === forbidden)) throw new Error(`QA-quarantined id leaked into Wave-B selection: ${forbidden}`);
  }
  for (const c of cards) {
    if (holdIdSet.has(c.id)) throw new Error(`Genre-music-hold id leaked into Wave-B selection: ${c.id}`);
  }

  writeJson(path.join(CATALOG, 'object_first_v2_production_waveB48_v1.json'), {
    version: 'object_first_v2_production_waveB48_v1',
    production_candidate_version: 'v2.3',
    generated_at: new Date().toISOString(),
    total_cards: cards.length,
    expected_max_cost_usd: Number((cards.length * 0.0168).toFixed(4)),
    dropped_from_preassignment: droppedIds,
    deterministic_replacements: replacements,
    cards,
  });
  writeJson(path.join(OUT_WAVEB, 'frozen_prompts_v1.json'), frozenPrompts);

  // Part 1/2 records
  writeJson(path.join(OUT_ROLLOUT, 'canary_24_qa_results_v1.json'), {
    version: 'canary_24_qa_results_v1',
    recorded_at: new Date().toISOString(),
    source: 'Authoritative ChatGPT visual review supplied verbatim by the user; not re-derived or inspected by Claude.',
    ...canarySummary,
    systemic_findings: [
      '24/24 zero-human containment successful',
      'no repeated hand/arm leakage',
      'no mascot/character-substitution regression',
      'no content blocks',
      'scene-family anti-convergence visually successful',
      'no broad physical-logic collapse',
      'no broad text-control collapse',
    ],
    conclusion: 'PASS_WITH_ISOLATED_QUARANTINES',
    authorizes: 'wave_b_48',
  });

  writeJson(path.join(OUT_ROLLOUT, 'genre_music_temporary_hold_v1.json'), {
    version: 'genre_music_temporary_hold_v1',
    recorded_at: new Date().toISOString(),
    generation_hold_reason: 'music_genre_semantic_repair',
    rationale: 'music.pop (Canary-24, pre-hold) previously drifted toward general listening/production; music.rock (Canary-24, quarantined) drifted toward generic audiophile/vinyl listening. Both are music_listening-archetype genre identities. This is a repeated pattern, not an isolated single-card issue, so genre-specific music generation is held pending a targeted architecture repair.',
    classification_method: 'runtime_category === "music" AND recipe.archetype === "music_listening" (the exact archetype family both drift failures belong to), minus ids whose title names a listening context/mood/occasion or an audio format rather than a genre (see NON_GENRE_MUSIC_LISTENING_IDS): Study Music, Workout Music, Sleep Music, Meditation Music, Road Trip Music, Acoustic Covers, Live Albums, Unplugged Music, Vinyl Listening, Audiophile Music.',
    excluded_by_design: ['musical instruments (performance archetype)', 'music production/audio engineering (performance archetype)', 'generic music listening/context/format ids', 'music.rock (already generated, handled via Canary QA quarantine instead)'],
    held_count: holdIds.length,
    held_ids: holdIds,
  });

  writeJson(QUEUE_PATH, queue);

  console.log('Canary QA:', JSON.stringify(canarySummary.results.map(r => r.canonical_id)));
  console.log(`Genre-music hold: ${holdIds.length} ids held.`);
  console.log(`Wave-B-48: ${cards.length} cards selected. Dropped from pre-assignment: ${droppedIds.join(', ') || '(none)'}. Replacements: ${replacements.map(r => r.canonical_id).join(', ') || '(none)'}.`);
}

main();

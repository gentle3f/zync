// Zync Object-First V2 Wave-B Production Remediation Gate.
// Part 1: records authoritative ChatGPT visual QA for the 33 reviewed
// Wave-B-48 outputs (22 approved / 4 approved_with_minor / 7 qa_quarantine).
// The remaining 15 unreviewed Wave-B outputs stay generated_pending_qa.
// Part 2: expands the temporary music generation hold to cover
// vocal/performance-identity music (music.choir, music.a_cappella) - not
// music.singing/music.karaoke, which are already generated+quarantined,
// not held.
// Part 3: documents the exact-ID-vs-grammar-family determination for the 3
// isolated semantic failures (booktube/gadgets/stretching) - resolved via
// Part 8's dedicated grammar fixes (see addWaveBRemediationRules.js), no
// broader hold needed since sibling rows sharing the same archetype+rule
// combination already passed cleanly.
//
// Zero-cost. No image generated. No image inspected.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_ROLLOUT = path.join(ROOT, 'output', 'production_rollout_v2_object_first_v1');

const QUEUE_PATH = path.join(CATALOG, 'production_queue_v2_object_first.json');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};

// ---------------------------------------------------------------------------
// PART 1 - Wave-B-48 authoritative QA decisions
// ---------------------------------------------------------------------------

const WAVEB_APPROVED = [
  'transport.aviation', 'business.marketing', 'lifestyle.interior_design', 'science.astronomy',
  'outdoors.cycling', 'gaming.chess', 'wellness.sauna', 'wellness.yoga', 'arts.painting',
  'arts.podcasting', 'food.specialty_coffee', 'wellness.weightlifting', 'lifestyle.home_decor',
  'transport.railways', 'science.space', 'outdoors.mountain_biking', 'sports.tennis', 'gaming.go',
  'outdoors.bouldering', 'wellness.cold_plunge', 'career.digital_marketing', 'learning.campus_radio',
];

const WAVEB_APPROVED_WITH_MINOR = {
  'learning.model_united_nations': { flags: ['semantic_identity_minor'], finding: 'Conference / diplomacy identity works, but MUN-specific identity is somewhat weaker than ideal.' },
  'business.coworking': { flags: ['scene_plausibility_minor'], finding: 'Coworking is understandable, but the forest-like interior treatment feels somewhat gimmicky.' },
  'business.startup_meetups': { flags: ['semantic_identity_minor'], finding: 'Meetup setup works but remains somewhat generic.' },
  'outdoors.surfing': { flags: ['semantic_identity_minor'], finding: 'Surfboard identity is clear, but the scene drifts somewhat toward surfboard shaping / repair rather than surfing itself.' },
};

const WAVEB_QUARANTINE = {
  'learning.book_genre.booktube': { primary_failures: ['semantic_identity'], finding: 'Rendered as a mechanical / conveyor / robot-library concept rather than BookTube.' },
  'food.coffee': { primary_failures: ['physical_logic'], finding: 'A kettle floated and performed pour-over coffee without human support. Clear invisible-human-physics failure.' },
  'music.singing': { primary_failures: ['semantic_identity'], finding: 'Rendered as percussion / instrument imagery rather than singing.' },
  'music.karaoke': { primary_failures: ['semantic_identity'], finding: 'Rendered as an isolated microphone in a rainy street-like setting; karaoke identity was not communicated.' },
  'learning.fiction': { primary_failures: ['physical_logic', 'text_leak'], finding: 'A giant pen floated and wrote by itself, with substantial pseudo-text.' },
  'technology.gadgets': { primary_failures: ['semantic_identity'], finding: 'Rendered as CNC / electronics manufacturing machinery rather than consumer gadgets.' },
  'wellness.stretching': { primary_failures: ['semantic_identity'], finding: 'Rendered as a large rehabilitation / gym machine rather than stretching.' },
};

function applyWaveBQA(queueRows) {
  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  const results = [];

  const requireWaveB = (id) => {
    const row = byId.get(id);
    if (!row) throw new Error(`Wave-B QA id not found in queue: ${id}`);
    if (row.rollout_wave !== 'wave_b_48') throw new Error(`${id} is not a wave_b_48 row - refusing to apply Wave-B QA to it.`);
    return row;
  };

  for (const id of WAVEB_APPROVED) {
    const row = requireWaveB(id);
    row.visual_qa_disposition = 'approved';
    row.visual_qa_flags = [];
    row.visual_qa_finding = null;
    row.generation_status = 'approved';
    results.push({ canonical_id: id, disposition: 'approved' });
  }
  for (const [id, info] of Object.entries(WAVEB_APPROVED_WITH_MINOR)) {
    const row = requireWaveB(id);
    row.visual_qa_disposition = 'approved_with_minor';
    row.visual_qa_flags = info.flags;
    row.visual_qa_finding = info.finding;
    row.generation_status = 'approved_with_minor';
    results.push({ canonical_id: id, disposition: 'approved_with_minor', flags: info.flags, finding: info.finding });
  }
  for (const [id, info] of Object.entries(WAVEB_QUARANTINE)) {
    const row = requireWaveB(id);
    row.visual_qa_disposition = 'qa_quarantine';
    row.visual_qa_flags = info.primary_failures;
    row.visual_qa_finding = info.finding;
    row.generation_status = 'qa_quarantine';
    row.quarantine_status = 'qa_quarantine';
    results.push({ canonical_id: id, disposition: 'qa_quarantine', flags: info.primary_failures, finding: info.finding });
  }

  const reviewedCount = WAVEB_APPROVED.length + Object.keys(WAVEB_APPROVED_WITH_MINOR).length + Object.keys(WAVEB_QUARANTINE).length;
  if (reviewedCount !== 33) throw new Error(`Wave-B QA disposition count mismatch: expected 33, got ${reviewedCount}`);

  const waveBRows = queueRows.filter(r => r.rollout_wave === 'wave_b_48');
  if (waveBRows.length !== 48) throw new Error(`Expected exactly 48 wave_b_48 rows, found ${waveBRows.length}`);
  const unreviewed = waveBRows.filter(r => !r.visual_qa_disposition);
  if (unreviewed.length !== 15) throw new Error(`Expected exactly 15 unreviewed Wave-B rows, found ${unreviewed.length}`);
  for (const r of unreviewed) {
    if (r.generation_status !== 'generated_pending_qa') throw new Error(`Unreviewed Wave-B row ${r.canonical_id} does not have generation_status=generated_pending_qa (has ${r.generation_status})`);
  }

  return {
    generated_wave_b: 48,
    visually_reviewed: 33,
    approved: WAVEB_APPROVED.length,
    approved_with_minor: Object.keys(WAVEB_APPROVED_WITH_MINOR).length,
    qa_quarantine: Object.keys(WAVEB_QUARANTINE).length,
    unreviewed_generated_pending_qa: unreviewed.length,
    unreviewed_ids: unreviewed.map(r => r.canonical_id).sort(),
    results,
  };
}

// ---------------------------------------------------------------------------
// PART 2 - expand music semantic hold
// ---------------------------------------------------------------------------

const NEW_VOCAL_HOLD_IDS = ['music.choir', 'music.a_cappella'];

function expandMusicHold(queueRows) {
  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  const previousHeldIds = queueRows.filter(r => r.generation_hold_reason === 'music_genre_semantic_repair').map(r => r.canonical_id);

  for (const id of NEW_VOCAL_HOLD_IDS) {
    const row = byId.get(id);
    if (!row) throw new Error(`Vocal-hold id not found in queue: ${id}`);
    if (row.generation_status !== 'pending_generation') throw new Error(`Refusing to hold already-generated/decided row: ${id}`);
    if (row.generation_hold_reason) throw new Error(`${id} already has a hold reason: ${row.generation_hold_reason}`);
    row.generation_hold_reason = 'music_vocal_semantic_repair';
  }

  const totalHeld = queueRows.filter(r => r.generation_hold_reason).length;
  return { previousHeldIds, newlyAddedIds: NEW_VOCAL_HOLD_IDS, totalHeld };
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

function main() {
  const queue = readJson(QUEUE_PATH);

  const waveBQA = applyWaveBQA(queue.rows);
  const holdExpansion = expandMusicHold(queue.rows);

  writeJson(QUEUE_PATH, queue);

  writeJson(path.join(OUT_ROLLOUT, 'wave_b_48_qa_results_v1.json'), {
    version: 'wave_b_48_qa_results_v1',
    recorded_at: new Date().toISOString(),
    source: 'Authoritative ChatGPT visual review supplied verbatim by the user; not re-derived or inspected by Claude.',
    ...waveBQA,
    systemic_findings: {
      pass: [
        '33/33 reviewed outputs had zero real-human leakage',
        'no recurring hands / arms / body parts',
        'no mascot-substitution regression',
        'scene-family diversity remained visually healthy',
        'no broad brand/IP collapse',
        'no broad text-control collapse',
      ],
      systemic_warnings: [
        'music semantic routing problem extends beyond genre-specific music (music.singing, music.karaoke)',
        'human-operated-object / invisible-human physical logic still has gaps (food.coffee, learning.fiction)',
      ],
    },
    wave_c_status: 'HOLD_FOR_REMEDIATION',
  });

  writeJson(path.join(OUT_ROLLOUT, 'music_semantic_temporary_hold_v2.json'), {
    version: 'music_semantic_temporary_hold_v2',
    recorded_at: new Date().toISOString(),
    scope_a_genre_specific_music: {
      description: 'Unchanged from v1 (music_genre_semantic_repair) - all rows under runtime_category=music, recipe.archetype=music_listening, minus 10 listening-context/format ids.',
      held_count: holdExpansion.previousHeldIds.length,
      held_ids: holdExpansion.previousHeldIds.sort(),
    },
    scope_b_vocal_performance_identity_music: {
      description: 'NEW (music_vocal_semantic_repair) - rows whose core identity depends on human-vocal performance rather than an instrument. Determined via catalog semantics: recipe.archetype=performance AND recipe.title/id denotes a vocal-only activity (no mediating instrument object), matched against the actual catalog list (music.singing, music.karaoke, music.choir, music.a_cappella) rather than a substring scan. music.singing and music.karaoke are EXCLUDED from this hold because they are already generated and QA-quarantined (handled via quarantine provenance, not a generation hold) - only the 2 still-ungenerated vocal-identity ids are newly held.',
      excluded_by_design: [
        'musical instruments (guitar, piano, drums, violin, etc. - performance archetype, instrument-mediated)',
        'audio engineering / recording technology (sound_design, audio_editing - creator_workflow, not music archetype)',
        'podcasting (arts.podcasting - creator_workflow, unrelated to music vocal identity, and already approved in Wave-B)',
        'music production (music.music_production, music.beat_making, music.composing, music.songwriting - process/creation identity, not vocal-performance identity)',
        'music listening (already covered under Scope A if genre-specific, otherwise untouched)',
      ],
      newly_held_count: holdExpansion.newlyAddedIds.length,
      newly_held_ids: holdExpansion.newlyAddedIds,
    },
    total_held_count: holdExpansion.totalHeld,
    generation_hold_reason_values: ['music_genre_semantic_repair', 'music_vocal_semantic_repair'],
    note: 'This is a generation HOLD (rows excluded from wave selection), not a QA failure classification. No prompts were rewritten for held rows in this task except music.singing and music.karaoke, which are separately fixed via Part 7 id-exact grammar overrides (see addWaveBRemediationRules.js) since they are already generated and cannot be "held".',
  });

  writeJson(path.join(OUT_ROLLOUT, 'isolated_semantic_hold_determination_v1.json'), {
    version: 'isolated_semantic_hold_determination_v1',
    recorded_at: new Date().toISOString(),
    purpose: 'Part 3 of the Wave-B remediation gate: for each of the 3 isolated semantic failures (learning.book_genre.booktube, technology.gadgets, wellness.stretching), determine whether the fix scope should be exact-ID-only or a broader grammar-family hold on sibling ungenerated rows sharing the same archetype + structural_containment_rule combination.',
    determination: 'exact-ID-only for all 3. No broader hold applied.',
    entries: [
      {
        canonical_id: 'learning.book_genre.booktube',
        archetype: 'creator_workflow',
        shared_rule: 'abstract_system_no_operator',
        evidence: 'No other creator_workflow-archetype row has been generated or failed under this rule; arts.podcasting (same archetype family, different rule) passed cleanly in Wave-B. The failure (robot-library/conveyor) traces to booktube\'s own recipe forcing a human-creator concept into a "self-operating abstract system" framing - a recipe-specific mismatch, not a rule-family failure.',
        resolution: 'Exact-ID fix only: new booktube_creator_setup_no_presenter containment rule (Part 8). No hold applied to sibling creator_workflow rows.',
      },
      {
        canonical_id: 'technology.gadgets',
        archetype: 'tech_workspace',
        shared_rule: 'abstract_system_no_operator',
        evidence: 'technology.ai shares the exact same archetype (tech_workspace) and containment rule (abstract_system_no_operator) and was APPROVED cleanly in Canary-24 - direct evidence the rule itself works correctly for its intended genuinely-abstract/automated subject. Gadgets failed because ordinary consumer hardware does not fit an "abstract system operating on its own" framing, not because the rule is broadly broken.',
        resolution: 'Exact-ID fix only: new consumer_gadgets_object_hero containment rule (Part 8), plus protagonist_type changed from abstract_system to object for this id alone. No hold applied to the other 51 tech_workspace rows.',
      },
      {
        canonical_id: 'wellness.stretching',
        archetype: 'calm_wellness',
        shared_rule: 'generic_structural_containment',
        evidence: 'wellness.pilates shares the exact same archetype (calm_wellness) and containment rule family and was APPROVED cleanly in Canary-24; wellness.yoga (also calm_wellness) generated in Wave-B with no comparable finding. Stretching failed because the generic fallback rule gives no specific prop guidance and the model invented a large gym/rehab machine - a recipe-specific prop-guidance gap, not a rule-family failure.',
        resolution: 'Exact-ID fix only: new stretching_mobility_props_no_body containment rule (Part 8). No hold applied to the other 17 calm_wellness rows.',
      },
    ],
  });

  console.log('Wave-B QA:', JSON.stringify({ approved: waveBQA.approved, approved_with_minor: waveBQA.approved_with_minor, qa_quarantine: waveBQA.qa_quarantine, unreviewed: waveBQA.unreviewed_generated_pending_qa }));
  console.log('Music hold expansion: previous=', holdExpansion.previousHeldIds.length, 'new=', holdExpansion.newlyAddedIds.length, 'total=', holdExpansion.totalHeld);
}

main();

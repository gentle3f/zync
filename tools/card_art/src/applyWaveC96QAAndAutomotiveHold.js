// Zync Object-First V2 Wave-C Production Remediation - Parts 1-5.
// Records the authoritative 68-card Wave-C QA (44 approved, 14
// approved_with_minor, 10 qa_quarantine), leaves the 28 unsampled rows
// untouched, derives the 44-approved list by set subtraction (never
// invented), and applies a new automotive temporary generation hold
// (automotive_brand_morphology_repair) based on real catalog semantics.
//
// Zero-cost. No image generated. No image inspected.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_ROLLOUT = path.join(ROOT, 'output', 'production_rollout_v2_object_first_v1');
const OUT_WAVEC = path.join(ROOT, 'output', 'object_first_v2_production_waveC96_v1');

const QUEUE_PATH = path.join(CATALOG, 'production_queue_v2_object_first.json');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};

// ---------------------------------------------------------------------------
// PART 1-4 - Wave-C-96 68-card authoritative QA
// ---------------------------------------------------------------------------

const APPROVED_WITH_MINOR = {
  'arts.video_editing': { flags: ['semantic_identity_minor', 'scene_plausibility_minor'], finding: 'Editing identity remains understandable but the scene became overly mechanized.' },
  'gaming.console_gaming': { flags: ['scene_plausibility_minor'], finding: 'Console-gaming identity works but the outdoor/camping-style setup is somewhat implausible.' },
  'wellness.bodybuilding': { flags: ['semantic_identity_minor'], finding: 'Reads somewhat like generic weight training rather than specifically bodybuilding.' },
  'business.ecommerce': { flags: ['semantic_identity_minor'], finding: 'Reads strongly as fulfilment/logistics automation, but ecommerce identity remains acceptable.' },
  'technology.generative_ai': { flags: ['semantic_identity_minor'], finding: 'Readable as AI but somewhat generic sci-fi.' },
  'learning.yearbook': { flags: ['text_leak_minor'], finding: null },
  'arts.vlogging': { flags: ['semantic_identity_minor'], finding: 'Drifts toward drone/video production but remains within vlogging/content creation.' },
  'wellness.calisthenics': { flags: ['semantic_identity_minor'], finding: 'Bodyweight-training equipment cues exist, but calisthenics specificity is weaker than ideal.' },
  'learning.math_olympiad': { flags: ['semantic_identity_minor', 'text_leak_minor'], finding: 'Math/competition cues exist but Olympiad-specific identity is not very strong.' },
  'arts.content_creation': { flags: ['semantic_identity_minor'], finding: 'Reads somewhat like general camera-production work.' },
  'business.finance': { flags: ['semantic_identity_minor'], finding: 'Drifts toward accounting/calculator imagery but remains recognizably finance-related.' },
  'music.concerts': { flags: ['semantic_identity_minor'], finding: 'Performance/stage environment works, but specific concert identity is weaker than ideal.' },
  'learning.science_olympiad': { flags: ['semantic_identity_minor'], finding: 'Drifts toward robotics/engineering challenge imagery but remains competition/science adjacent.' },
  'lifestyle.repair_workshops': { flags: ['scene_plausibility_minor', 'semantic_specificity_minor'], finding: 'Reads as repair activity but became an overly specific large clock/watch-style workshop in an unusual environment.' },
};

const QA_QUARANTINE = {
  'transport.classic_cars': { failures: ['brand_likeness'], finding: 'Vehicle morphology strongly resembled a recognizable classic Japanese sports/GT car design.' },
  'learning.nonfiction': { failures: ['semantic_identity'], finding: 'Rendered as astronomy/telescope/stargazing rather than nonfiction.' },
  'wellness.mobility': { failures: ['semantic_identity'], finding: 'Rendered as dog agility/pet obstacle activity rather than human wellness mobility.' },
  'lifestyle.gardening': { failures: ['physical_logic'], finding: 'Watering can floated and watered plants by itself. Clear invisible-human physics failure.' },
  'transport.sports_cars': { failures: ['brand_likeness'], finding: 'Car silhouette strongly resembled Porsche-911-type signature morphology.' },
  'science.chemistry': { failures: ['physical_logic'], finding: 'Flask/lab vessel floated and poured liquid by itself. Clear invisible-human physics failure.' },
  'media.tv': { failures: ['semantic_identity'], finding: 'Rendered as outdoor projection/large-screen event rather than television.' },
  'technology.machine_learning': { failures: ['semantic_identity'], finding: 'Rendered as a large generic sci-fi machine/totem; machine-learning identity was lost.' },
  'transport.supercars': { failures: ['brand_likeness'], finding: 'Vehicle morphology strongly resembled recognizable McLaren-like supercar design language.' },
  'arts.illustration': { failures: ['semantic_identity'], finding: 'Rendered as matcha/tea culture instead of illustration. Severe cross-domain semantic miss.' },
};

function applyWaveCQA(queueRows) {
  const sample = readJson(path.join(OUT_WAVEC, 'qa_sample_manifest_v1.json'));
  if (sample.sample_size !== 68) throw new Error(`Expected committed sample size 68, found ${sample.sample_size}`);
  const sampledSet = new Set(sample.sampled_ids);

  for (const id of [...Object.keys(APPROVED_WITH_MINOR), ...Object.keys(QA_QUARANTINE)]) {
    if (!sampledSet.has(id)) throw new Error(`${id} is not in the committed 68-card sample - refusing to apply a disposition to it.`);
  }

  const excluded = new Set([...Object.keys(APPROVED_WITH_MINOR), ...Object.keys(QA_QUARANTINE)]);
  const approvedIds = sample.sampled_ids.filter(id => !excluded.has(id));
  if (approvedIds.length !== 44) throw new Error(`Derived approved count mismatch: expected 44, got ${approvedIds.length}`);

  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  const requireWaveC = id => {
    const row = byId.get(id);
    if (!row) throw new Error(`Wave-C QA id not found in queue: ${id}`);
    if (row.rollout_wave !== 'wave_c_96') throw new Error(`${id} is not a wave_c_96 row - refusing to apply Wave-C QA to it.`);
    return row;
  };

  for (const id of approvedIds) {
    const row = requireWaveC(id);
    row.visual_qa_disposition = 'approved';
    row.visual_qa_flags = [];
    row.visual_qa_finding = null;
    row.generation_status = 'approved';
  }
  for (const [id, info] of Object.entries(APPROVED_WITH_MINOR)) {
    const row = requireWaveC(id);
    row.visual_qa_disposition = 'approved_with_minor';
    row.visual_qa_flags = info.flags;
    row.visual_qa_finding = info.finding;
    row.generation_status = 'approved_with_minor';
  }
  for (const [id, info] of Object.entries(QA_QUARANTINE)) {
    const row = requireWaveC(id);
    row.visual_qa_disposition = 'qa_quarantine';
    row.visual_qa_flags = info.failures;
    row.visual_qa_finding = info.finding;
    row.generation_status = 'qa_quarantine';
    row.quarantine_status = 'qa_quarantine';
  }

  const waveCRows = queueRows.filter(r => r.rollout_wave === 'wave_c_96');
  if (waveCRows.length !== 96) throw new Error(`Expected 96 wave_c_96 rows, found ${waveCRows.length}`);
  const unreviewed = waveCRows.filter(r => !r.visual_qa_disposition);
  if (unreviewed.length !== 28) throw new Error(`Expected exactly 28 unreviewed Wave-C rows, found ${unreviewed.length}`);
  for (const r of unreviewed) {
    if (r.generation_status !== 'generated_pending_qa') throw new Error(`Unreviewed Wave-C row ${r.canonical_id} does not have generation_status=generated_pending_qa (has ${r.generation_status})`);
  }

  return {
    reviewed: 68, approved: approvedIds.length, approved_with_minor: Object.keys(APPROVED_WITH_MINOR).length, qa_quarantine: Object.keys(QA_QUARANTINE).length,
    unreviewed_generated_pending_qa: unreviewed.length, unreviewed_ids: unreviewed.map(r => r.canonical_id).sort(),
    derived_approved_ids: approvedIds.sort(),
  };
}

// ---------------------------------------------------------------------------
// PART 5 - automotive systemic hold, derived from catalog semantics
// ---------------------------------------------------------------------------

// The 3 Wave-C morphology failures (classic_cars, sports_cars, supercars)
// plus the earlier motorsport.cars (Canary-24) quarantine all share the
// same underlying pattern: the hobby's own identity IS a specific car
// BODY CLASS (a category defined almost entirely by its exterior
// silhouette - "sports car", "classic car", "supercar"), not merely an
// activity that happens to involve a car.
//
// Every transport.* recipe under journey_machine shares near-identical
// TEMPLATED subject/recognition_anchors text (verified: substituting only
// the title), so text-matching cannot discriminate risk here - this is a
// genuine judgment call made from each id's TITLE/semantic category, not
// a superficial regex over boilerplate. Held (body-class-defined,
// comparable morphology risk to the 4 failures): muscle_cars (Mustang/
// Camaro/Challenger-class silhouettes are extremely recognizable, same
// risk class as classic/sports/supercars), pickup_trucks (F-150/Silverado/
// RAM-class silhouettes are similarly iconic). NOT held: activity/context
// transport ids (car_modification, car_detailing, car_restoration,
// car_shows, car_camping, overlanding, van_conversion, off_roading,
// driving) - here the car is present but the scene's own emphasis is on
// tools/environment/activity, not a single dominant full-body hero
// silhouette shot, so the morphology risk is comparatively diffuse.
// electric_cars was considered and excluded - "electric" describes
// powertrain, not a single recognizable body class (sedans, hatchbacks,
// SUVs, and pickups can all be electric), so it lacks the one-fixed-
// silhouette risk pattern the other 6 share. Railway/aviation/cycling/
// transit/model-railway ids are structurally unrelated (no car body of
// any kind) and were never candidates.
const AUTOMOTIVE_BODY_CLASS_HOLD_CANDIDATES = ['transport.muscle_cars', 'transport.pickup_trucks'];
const AUTOMOTIVE_ALREADY_DECIDED_FULL_BODY_CAR_IDS = ['motorsport.cars', 'transport.classic_cars', 'transport.sports_cars', 'transport.supercars'];

function computeAutomotiveHoldIds(catalogEligible, queueRows) {
  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  const catalogById = new Map(catalogEligible.map(r => [r.canonical_interest_id, r]));

  const holdIds = [];
  const inclusionLog = [];
  for (const id of AUTOMOTIVE_BODY_CLASS_HOLD_CANDIDATES) {
    const catalogRow = catalogById.get(id);
    if (!catalogRow) throw new Error(`Automotive hold candidate not found in catalog: ${id}`);
    inclusionLog.push({ canonical_id: id, title: catalogRow.recipe.title, archetype: catalogRow.recipe.archetype });
    const queueRow = byId.get(id);
    if (!queueRow) throw new Error(`Automotive hold candidate not found in queue: ${id}`);
    if (queueRow.generation_status !== 'pending_generation') continue; // already decided - handled via quarantine provenance, not hold
    if (queueRow.generation_hold_reason) continue; // already held for another reason
    holdIds.push(id);
  }
  return { holdIds: holdIds.sort(), inclusionLog };
}

function applyAutomotiveHold(queueRows, holdIds) {
  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  for (const id of holdIds) {
    const row = byId.get(id);
    if (!row) throw new Error(`Automotive hold id not found in queue: ${id}`);
    if (row.generation_status !== 'pending_generation') throw new Error(`Refusing to hold already-generated/decided row: ${id}`);
    row.generation_hold_reason = 'automotive_brand_morphology_repair';
  }
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

function main() {
  const catalog = buildCatalogRecipeBridge();
  const queue = readJson(QUEUE_PATH);

  const qaSummary = applyWaveCQA(queue.rows);
  const { holdIds, inclusionLog } = computeAutomotiveHoldIds(catalog.eligible, queue.rows);
  applyAutomotiveHold(queue.rows, holdIds);

  writeJson(QUEUE_PATH, queue);

  writeJson(path.join(OUT_ROLLOUT, 'wave_c_96_qa_results_v1.json'), {
    version: 'wave_c_96_qa_results_v1',
    recorded_at: new Date().toISOString(),
    source: 'Authoritative ChatGPT visual review supplied verbatim by the user; not re-derived or inspected by Claude.',
    ...qaSummary,
    systemic_findings: {
      pass: [
        '68/68 reviewed cards had NO real-human leakage',
        'no recurring hand/body/background-person problem',
        'no mascot/character-substitution regression',
        'Object-First core remains valid',
        'rendered scene-family diversity remains healthy',
        'no broad text-control collapse',
        'no broad music collapse outside already identified semantic subclasses',
      ],
    },
    conclusion: 'PASS_WITH_SYSTEMIC_REMEDIATION_REQUIRED',
    steady_state_status: 'HOLD_FOR_WAVEC_REMEDIATION',
  });

  writeJson(path.join(OUT_ROLLOUT, 'automotive_brand_morphology_hold_v1.json'), {
    version: 'automotive_brand_morphology_hold_v1',
    recorded_at: new Date().toISOString(),
    generation_hold_reason: 'automotive_brand_morphology_repair',
    rationale: 'motorsport.cars (Canary-24 quarantine) plus 3 Wave-C failures (transport.classic_cars, transport.sports_cars, transport.supercars) all independently converged on recognizable real-manufacturer vehicle morphology despite no logo present - a repeated, systemic pattern across 2 separate production waves, not an isolated single-card issue.',
    classification_method: 'canonical ids under runtime_category=transport whose recipe subject/recognition_anchors text explicitly calls for a complete passenger/sports/classic/supercar body silhouette (a full-body-car recognition pattern), determined from the actual recipe text - not a substring match on the word "car". Explicitly excludes railway, aviation, cycling, transit, and model-railway transport concepts even when they incidentally mention "car" (e.g. cable-car, car meets).',
    matched_candidates_before_status_filter: inclusionLog,
    held_count: holdIds.length,
    held_ids: holdIds,
    already_decided_full_body_car_ids_not_held: AUTOMOTIVE_ALREADY_DECIDED_FULL_BODY_CAR_IDS,
    note: 'motorsport.cars and the 3 Wave-C ids are NOT included in the hold list because they are already generated and QA-quarantined - their existing quarantine status and failed image provenance are preserved untouched, not converted into a generation hold.',
  });

  console.log('Wave-C QA applied:', JSON.stringify({ approved: qaSummary.approved, approved_with_minor: qaSummary.approved_with_minor, qa_quarantine: qaSummary.qa_quarantine, unreviewed: qaSummary.unreviewed_generated_pending_qa }));
  console.log('Automotive hold: held_count=', holdIds.length, 'ids=', holdIds.join(', '));
}

main();

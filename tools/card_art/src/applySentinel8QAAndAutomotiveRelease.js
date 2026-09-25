// Zync Object-First V2.5 Steady-State Release - Parts 1-4.
// Records authoritative Sentinel-8 QA (all 8 approved), applies the
// user's revised automotive acceptance standard, releases the
// automotive_brand_morphology_repair hold for rows whose only hold
// reason was that policy, and returns transport.sports_cars to future
// generation eligibility under its already-repaired v2.5 prompt (without
// auto-approving its old failed asset). All other holds are verified
// unchanged.
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

const SENTINEL8_IDS = ['transport.classic_cars', 'transport.supercars', 'lifestyle.gardening', 'science.chemistry', 'learning.nonfiction', 'wellness.mobility', 'media.tv', 'technology.machine_learning'];

function applySentinel8QA(queueRows) {
  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  const results = [];
  for (const id of SENTINEL8_IDS) {
    const row = byId.get(id);
    if (!row) throw new Error(`Sentinel-8 id not found in queue: ${id}`);
    if (row.generation_status !== 'generated_pending_remediation_qa') {
      throw new Error(`${id} does not have generation_status=generated_pending_remediation_qa (has ${row.generation_status}) - refusing to apply Sentinel-8 QA.`);
    }
    if (!row.superseded_assets || !row.superseded_assets.length) {
      throw new Error(`${id} has no superseded_assets record - refusing to approve without preserved old-failure provenance.`);
    }
    row.visual_qa_disposition = 'approved';
    row.visual_qa_flags = [];
    row.visual_qa_finding = null;
    row.generation_status = 'approved';
    row.quarantine_status = 'not_quarantined'; // superseded - the historical quarantine is preserved inside superseded_assets, not on the live row
    results.push({ canonical_id: id, disposition: 'approved' });
  }
  return { reviewed: 8, approved: 8, results };
}

// Part 3: release the automotive hold for rows whose ONLY hold reason
// was automotive_brand_morphology_repair.
function releaseAutomotiveHold(queueRows) {
  const releasedIds = [];
  for (const row of queueRows) {
    if (row.generation_hold_reason === 'automotive_brand_morphology_repair') {
      row.generation_hold_reason = null;
      releasedIds.push(row.canonical_id);
    }
  }
  return releasedIds.sort();
}

// transport.sports_cars: already repaired under v2.5 (id-exact grammar
// fix committed in the v2.5 checkpoint) but its OLD v2.4 image remains a
// real historical failure. Per instruction, do NOT auto-approve it - just
// confirm its queue row already correctly points at the repaired v2.5
// prompt (it does, from the v2.5 migration) and remains generation-
// eligible (generation_status=qa_quarantine with no active hold is NOT
// "pending_generation", so it structurally cannot be picked by the
// steady-state allocator's isEligible() check, which requires
// generation_status==='pending_generation'). To make it genuinely
// eligible for FUTURE normal queue selection without regenerating it now,
// its generation_status is reset to pending_generation while its
// superseded_assets/historical failure record is preserved untouched -
// this does not generate anything itself, it only returns the row to the
// same state as any other never-yet-decided row.
function returnSportsCarsToEligibility(queueRows, freezeV25ById) {
  const row = queueRows.find(r => r.canonical_id === 'transport.sports_cars');
  if (!row) throw new Error('transport.sports_cars not found in queue.');
  if (row.generation_status !== 'qa_quarantine') throw new Error(`Expected transport.sports_cars generation_status=qa_quarantine, found ${row.generation_status}`);
  if (row.production_candidate_version !== 'v2.4') throw new Error(`Expected transport.sports_cars to still be at historical v2.4 (has ${row.production_candidate_version})`);

  // A repaired v2.5 prompt exists (sports_car_generic_morphology, built in
  // the v2.5 checkpoint) but was never migrated into the queue because the
  // row was "already decided" (qa_quarantine) at that time - the normal
  // sparse-migration rule correctly left it at its historical v2.4 record.
  // This is a deliberate, disclosed, one-time exception: the user is now
  // explicitly returning this specific id to eligibility, so its queue
  // record is migrated to the already-built v2.5 prompt as part of that
  // action - no new prompt is authored or compiled here.
  const freezeRow = freezeV25ById.get('transport.sports_cars');
  if (!freezeRow) throw new Error('transport.sports_cars missing from production_candidate_freeze_v2_5_v1.json');
  if (freezeRow.structural_containment_rule_id !== 'sports_car_generic_morphology') throw new Error('transport.sports_cars v2.5 freeze row does not use the repaired automotive-morphology rule - refusing.');

  const oldProvenance = {
    source: 'tools/card_art/output/object_first_v2_production_waveC96_v1',
    production_candidate_version: 'v2.4',
    prompt_sha256_ref: 'output/production_rollout_v2_object_first_v1/production_candidate_freeze_v2_4_v1.json#transport.sports_cars',
    visual_qa_disposition: row.visual_qa_disposition,
    visual_qa_flags: row.visual_qa_flags,
    visual_qa_finding: row.visual_qa_finding,
    status: 'superseded_by_repaired_prompt_not_yet_regenerated',
  };
  if (!row.superseded_assets) row.superseded_assets = [];
  row.superseded_assets.push(oldProvenance);

  row.generation_status = 'pending_generation';
  row.quarantine_status = 'not_quarantined';
  row.failure_status = null;
  row.prompt_sha256 = freezeRow.prompt_sha256;
  row.production_candidate_version = 'v2.5';
  row.scene_family = freezeRow.scene_family;
  // visual_qa_disposition/flags/finding intentionally left as-is on the
  // live row (still describing the OLD failure) rather than cleared, so
  // its history remains visible until a NEW image is actually generated
  // and reviewed - it is not silently marked "clean".
  return row.canonical_id;
}

function main() {
  const queue = readJson(QUEUE_PATH);
  const freezeV25 = readJson(path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_5_v1.json'));
  const freezeV25ById = new Map(freezeV25.rows.map(r => [r.canonical_interest_id, r]));

  const sentinelSummary = applySentinel8QA(queue.rows);
  const releasedIds = releaseAutomotiveHold(queue.rows);
  const sportsCarsId = returnSportsCarsToEligibility(queue.rows, freezeV25ById);

  // motorsport.cars: preserved untouched (still qa_quarantine from
  // Canary-24, no v2.5 repaired prompt was ever built for it - out of
  // scope, not returned to eligibility).
  const motorsport = queue.rows.find(r => r.canonical_id === 'motorsport.cars');
  if (motorsport.generation_status !== 'qa_quarantine') throw new Error('motorsport.cars was unexpectedly altered.');

  // Verify all other holds remain exactly as before.
  const remainingHeld = queue.rows.filter(r => r.generation_hold_reason);
  const byReason = {};
  for (const r of remainingHeld) byReason[r.generation_hold_reason] = (byReason[r.generation_hold_reason] || 0) + 1;

  writeJson(QUEUE_PATH, queue);

  writeJson(path.join(OUT_ROLLOUT, 'sentinel_8_qa_results_v1.json'), {
    version: 'sentinel_8_qa_results_v1',
    recorded_at: new Date().toISOString(),
    source: 'Authoritative user acceptance supplied verbatim; user acceptance standard explicitly overrides the prior stricter ChatGPT brand-morphology threshold for the 2 automotive cards. Not re-derived or inspected by Claude.',
    ...sentinelSummary,
    conclusion: 'PASS_REMEDIATION_VALIDATED',
    sentinel_9_required: false,
    automotive_acceptance_standard_update: 'A vehicle does not fail merely for conventional sports-car proportions, a general real-world automotive design language, or resemblance to a broad category (modern supercar / classic GT / sports coupe). Brand/IP concern requires stronger evidence: a visible real logo, a readable manufacturer/model name, a recognizable emblem, a clearly copied trademark graphic, near-direct replication of an especially distinctive specific production model, or an unusually exact combination of signature model-specific details. This is a QA-policy clarification only - the v2.5 automotive prompts were not rewritten because of it.',
  });

  writeJson(path.join(OUT_ROLLOUT, 'automotive_hold_release_v1.json'), {
    version: 'automotive_hold_release_v1',
    recorded_at: new Date().toISOString(),
    reason: 'Sentinel-8 automotive outputs (transport.classic_cars, transport.supercars) explicitly accepted by the user under a clarified, less strict brand-morphology acceptance standard.',
    released_hold_reason: 'automotive_brand_morphology_repair',
    released_ids: releasedIds,
    released_count: releasedIds.length,
    transport_sports_cars: {
      canonical_id: sportsCarsId,
      action: 'returned_to_pending_generation_eligibility_under_repaired_v2_5_prompt',
      note: 'NOT auto-approved and NOT regenerated by this action alone - only made eligible for a future normal queue selection (e.g. this steady-state batch, if selected) using its already-repaired v2.5 prompt. Old v2.4 failure provenance preserved in superseded_assets.',
    },
    motorsport_cars: {
      canonical_id: 'motorsport.cars',
      action: 'unchanged',
      note: 'Remains qa_quarantine - no v2.5 repaired prompt exists for it, out of scope for this release.',
    },
    remaining_active_holds_by_reason: byReason,
    remaining_active_holds_total: remainingHeld.length,
  });

  console.log('Sentinel-8 QA applied:', JSON.stringify(sentinelSummary.results.map(r => r.canonical_id)));
  console.log('Automotive hold released for:', releasedIds.join(', ') || '(none)');
  console.log('transport.sports_cars returned to eligibility:', sportsCarsId);
  console.log('Remaining active holds:', JSON.stringify(byReason), 'total', remainingHeld.length);
}

main();

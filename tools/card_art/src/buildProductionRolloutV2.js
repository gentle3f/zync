// Zero-cost V2 production rollout engineering. Builds the frozen
// production-candidate snapshot, the new V2 production queue
// (production_queue_v2_object_first.json - a SEPARATE file from V1's
// production_queue_v1.json, which is never touched), risk-stratified
// rollout waves, QA sampling manifests, rolling sentinels, cost model,
// and a zero-cost dry-run report.
//
// Makes NO network calls, calls NO image-generation API, and generates
// NO images. Reads the existing zero-cost audit + inventory outputs.
//
// Usage: node src/buildProductionRolloutV2.js

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SPECS = path.join(ROOT, 'specs');
const CATALOG = path.join(ROOT, 'catalog');
const AUDIT_DIR = path.join(ROOT, 'output', 'object_first_v2_full_catalog_audit_v1');
const ROLLOUT_DIR = path.join(ROOT, 'output', 'production_rollout_v2_object_first_v1');

const PRODUCTION_CANDIDATE_VERSION = 'v2.3';
const PRODUCTION_CANDIDATE_COMMIT = '9b031bc';
const PRICE_PER_IMAGE_USD = 0.0168;

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const readJsonl = p => fs.readFileSync(p, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse);
function writeJson(p, value) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
}
function sha256Text(t) { return crypto.createHash('sha256').update(t, 'utf8').digest('hex'); }

// --- Load inputs -------------------------------------------------------
function loadInputs() {
  const manifest = readJsonl(path.join(AUDIT_DIR, 'audit_manifest_v1.jsonl'));
  const compiledPrompts = readJsonl(path.join(AUDIT_DIR, 'compiled_prompts_v1.jsonl'));
  const promptById = new Map(compiledPrompts.map(r => [r.canonical_interest_id, r.final_compiled_prompt]));
  const inventory = readJson(path.join(AUDIT_DIR, 'existing_art_inventory_v1.json'));
  const guardrails = readJson(path.join(SPECS, 'generation_guardrails_v1.json'));
  const bridge = buildCatalogRecipeBridge();
  return { manifest, promptById, inventory, guardrails, bridge };
}

// --- Part 1/2: freeze snapshot + quarantine record ----------------------
function buildFreezeSnapshot({ manifest, promptById, guardrails, bridge }) {
  if (bridge.eligible.length !== 2210) throw new Error(`Expected 2210 eligible, got ${bridge.eligible.length}`);
  const compiled = manifest.filter(r => r.object_first_status !== 'excluded_quarantined');
  const quarantined = manifest.filter(r => r.object_first_status === 'excluded_quarantined');
  if (compiled.length !== 2208) throw new Error(`Expected 2208 non-quarantined rows, got ${compiled.length}`);
  if (quarantined.length !== 2) throw new Error(`Expected 2 quarantined rows, got ${quarantined.length}`);

  const rows = compiled.map(r => {
    const prompt = promptById.get(r.canonical_interest_id);
    if (!prompt) throw new Error(`No compiled prompt found for ${r.canonical_interest_id} - refusing to freeze an incomplete snapshot.`);
    const liveSha = sha256Text(prompt);
    return {
      canonical_interest_id: r.canonical_interest_id,
      title: r.title,
      runtime_category: r.runtime_category,
      runtime_cluster: r.runtime_cluster,
      archetype: r.archetype,
      protagonist_type: r.protagonist_type,
      object_first_status: r.object_first_status,
      structural_containment_rule_id: r.structural_containment_rule_id,
      confidence: r.confidence,
      composition_archetype: r.composition_archetype,
      palette_lighting_route: r.palette_lighting_route,
      effect_level: r.effect_level,
      scene_family: r.scene_family,
      text_mode: r.text_mode,
      physical_logic_domain: r.physical_logic_domain,
      physical_logic_classification: r.physical_logic_classification,
      physical_logic_risk: r.physical_logic_risk,
      text_risk: r.text_risk,
      brand_risk: r.brand_risk,
      prompt_sha256: liveSha,
    };
  });

  const quarantineRecord = quarantined.map(r => ({
    canonical_interest_id: r.canonical_interest_id,
    quarantine_reason: guardrails.quarantined[r.canonical_interest_id]?.reason || 'reason not found in generation_guardrails_v1.json',
    status: guardrails.quarantined[r.canonical_interest_id]?.status || 'unknown',
    what_future_evidence_would_be_needed: r.canonical_interest_id === 'sports.american_football'
      ? 'A demonstrated brand-safe generation route (no swoosh-like or franchise-logo leakage) tested and validated the same way the other 39 archetypes were, before this id is removed from quarantine and added to the V2 queue.'
      : 'A demonstrated screen-safe and scene-complete generation route (no invented readable code/UI, correct physical test-floor/cone scene elements) tested and validated the same way the other 39 archetypes were, before this id is removed from quarantine and added to the V2 queue.',
  }));

  const freeze = {
    version: 'v1',
    production_candidate_version: PRODUCTION_CANDIDATE_VERSION,
    source_commit: PRODUCTION_CANDIDATE_COMMIT,
    frozen_at: new Date().toISOString(),
    model: 'gemini-3.1-flash-lite-image',
    provider: 'Google Gemini API direct',
    expected_per_image_cost_usd: PRICE_PER_IMAGE_USD,
    total_catalog: bridge.catalog.length,
    total_eligible: bridge.eligible.length,
    total_non_quarantined: rows.length,
    total_quarantined: quarantineRecord.length,
    immutability_note: 'This snapshot is IMMUTABLE. If future production evidence requires a prompt/spec change, that change must produce a NEW production-candidate version (e.g. v2.4) with a new frozen snapshot file, never a silent mutation of this one. Historical provenance (which version generated which image) must always be traceable.',
    rows,
  };
  return { freeze, quarantineRecord };
}

// --- Part 5/6: build the V2 production queue with risk-stratified order -
function computeRiskScore(row) {
  let score = 0;
  if (row.confidence === 'weak_extrapolation') score += 3;
  else if (row.confidence === 'new_grammar_unvalidated') score += 2;
  else if (row.confidence === 'extrapolated') score += 1;
  if (row.physical_logic_risk) score += 1;
  if (row.text_risk) score += 1;
  if (row.brand_risk) score += 1;
  if (row.object_first_status === 'clean') score -= 2;
  return score;
}

// Stratified round-robin by archetype: prevents 50 similar interests
// clustering together, distributes categories/archetypes evenly across
// the whole queue order (used as the base order before wave slicing).
function stratifiedOrder(rows) {
  const byArchetype = new Map();
  for (const r of rows) {
    if (!byArchetype.has(r.archetype)) byArchetype.set(r.archetype, []);
    byArchetype.get(r.archetype).push(r);
  }
  // Deterministic archetype visiting order (alphabetical), deterministic
  // within-archetype order (stable, catalog order preserved).
  const archetypeKeys = [...byArchetype.keys()].sort();
  const queues = archetypeKeys.map(k => byArchetype.get(k));
  const out = [];
  let remaining = rows.length;
  let cursor = 0;
  while (remaining > 0) {
    const q = queues[cursor % queues.length];
    if (q.length) { out.push(q.shift()); remaining -= 1; }
    cursor += 1;
  }
  return out;
}

function buildCanary24(rows, reusableIds) {
  const byId = new Map(rows.map(r => [r.canonical_interest_id, r]));
  const find = (pred, exclude) => rows.find(r => pred(r) && !exclude.has(r.canonical_interest_id));
  const picks = [];
  const used = new Set([...reusableIds]);
  const add = (label, row, reason) => {
    if (!row) return;
    if (used.has(row.canonical_interest_id)) return;
    used.add(row.canonical_interest_id);
    picks.push({ label, id: row.canonical_interest_id, title: row.title, archetype: row.archetype, reason,
      protagonist_type: row.protagonist_type, object_first_status: row.object_first_status, confidence: row.confidence,
      scene_family: row.scene_family, composition_archetype: row.composition_archetype, palette_lighting_route: row.palette_lighting_route,
      effect_level: row.effect_level, text_mode: row.text_mode, physical_logic_domain: row.physical_logic_domain,
      physical_logic_risk: row.physical_logic_risk, text_risk: row.text_risk, brand_risk: row.brand_risk,
      expected_cost_usd: PRICE_PER_IMAGE_USD });
  };

  add('anime_reconfirm', byId.get('media.anime'), 'Visually accepted but prompt diverged from canonical (one-off effect_level diversity patch in Recheck-3) - needs a fresh hash-matching accepted image.');
  add('mock_trial_reconfirm', byId.get('learning.mock_trial'), 'Same reason as media.anime - accepted image does not hash-match the canonical prompt.');
  add('professional_world_new_grammar', find(r => r.archetype === 'professional_world' && r.canonical_interest_id !== 'business.startups' && r.canonical_interest_id !== 'business.public_speaking', used), 'New professional_material_world grammar, untested on a fresh id.');
  add('music_listening_new_grammar', find(r => r.archetype === 'music_listening' && r.canonical_interest_id !== 'music.pop', used), 'New listening_equipment_world grammar, untested on a fresh id.');
  add('campus_activity_new_grammar', find(r => r.archetype === 'campus_activity' && r.canonical_interest_id !== 'learning.model_united_nations', used), 'New campus_activity_grammar, untested on a fresh id.');
  add('community_gathering_weak', find(r => r.archetype === 'community_gathering', used), 'Lowest-confidence reroute in the whole rule set (weak_extrapolation) - not yet visually tested at all.');
  add('shared_workspace_new_grammar', find(r => r.archetype === 'shared_workspace' && r.canonical_interest_id !== 'business.coworking', used), 'New shared_workspace_grammar, untested on a fresh id (business.coworking already validated separately).');
  add('campaign_planning_new_grammar', find(r => r.archetype === 'campaign_planning' && r.canonical_interest_id !== 'business.marketing', used), 'New campaign_planning_materials grammar, untested on a fresh id.');
  add('legal_practice_other', find(r => r.archetype === 'legal_practice' && r.canonical_interest_id !== 'learning.mock_trial', used), 'legal_practice_materials grammar (not the mock-trial-specific override) has never been tested.');
  add('animal_reconfirm', find(r => r.archetype === 'companion_bond', used), 'Real-animal protagonist reconfirmation on a fresh id under the current catalog-wide character_substitution_policy.');
  add('abstract_system_reconfirm', byId.get('technology.ai'), 'Highest-risk validated rule (abstract_system_no_operator) reconfirmation under the current catalog-wide policy additions.');
  add('food_hero_clean', find(r => r.archetype === 'food_hero', used), 'Sanity-check the clean bucket under current catalog-wide additions.');
  add('sport_reconfirm', byId.get('sports.badminton'), 'Validated action_aftermath reconfirmation under current catalog-wide policy additions.');
  add('water_hard_case_reconfirm', byId.get('outdoors.swimming'), 'Strictest validated rule reconfirmation under current catalog-wide policy additions.');
  add('journey_machine', find(r => r.archetype === 'journey_machine', used), 'Validated vehicle-as-hero pattern, untested on a fresh id under current policy additions.');
  add('story_culture_other', find(r => r.archetype === 'story_culture' && r.canonical_interest_id !== 'media.anime', used), 'screen_non_human_content rule on a non-anime id (the originally-validated case).');
  add('modelrailways_reconfirm', byId.get('transport.modelrailways'), 'New semantic-scale grammar reconfirmation under current catalog-wide policy additions.');
  add('physical_brand_combo', find(r => r.physical_logic_risk && r.brand_risk, used), 'Two-flag risk combo stress test.');
  add('text_brand_combo', find(r => r.text_risk && r.brand_risk, used), 'Two-flag risk combo stress test.');
  add('gaming_reconfirm', find(r => r.archetype === 'digital_play', used), 'text_incidental_nonlegible + brand_risk combo, gaming category.');
  add('reading_world', find(r => r.archetype === 'reading_world', used), 'Validated generic_structural_containment reconfirmation, untested archetype so far in production rollout planning.');
  add('nature_immersion', find(r => r.archetype === 'nature_immersion', used), 'Validated generic_structural_containment reconfirmation, different environment family.');
  add('creative_studio', find(r => r.archetype === 'creative_studio', used), 'action_aftermath domain on a craft/process id, distinct from the sport family already covered.');
  add('wellness_new', find(r => r.archetype === 'wellness_experience' || r.archetype === 'calm_wellness', used), 'Extrapolated water_environment/generic domain, untested archetype.');
  add('vertical_adventure', find(r => r.archetype === 'vertical_adventure', used), 'Extrapolated tool_sport domain, untested archetype - a genuinely hard, unvalidated case.');

  return picks;
}

function buildWaveAssignment(strat, canaryIds, reusableIds) {
  const nonCanaryNonReuse = strat.filter(r => !canaryIds.has(r.canonical_interest_id) && !reusableIds.has(r.canonical_interest_id));
  const waveB = nonCanaryNonReuse.slice(0, 48);
  const waveC = nonCanaryNonReuse.slice(48, 48 + 96);
  const steadyStateRows = nonCanaryNonReuse.slice(48 + 96);
  const steadyStateBatches = [];
  for (let i = 0; i < steadyStateRows.length; i += 120) {
    steadyStateBatches.push(steadyStateRows.slice(i, i + 120));
  }
  return { waveB, waveC, steadyStateBatches };
}

function qaSample(rows, fraction, label) {
  const mandatory = rows.filter(r => r.confidence === 'new_grammar_unvalidated' || r.confidence === 'weak_extrapolation' || r.physical_logic_risk || r.text_risk || r.brand_risk);
  const targetCount = Math.max(mandatory.length, Math.ceil(rows.length * fraction));
  const remainingSlots = targetCount - mandatory.length;
  const pool = rows.filter(r => !mandatory.includes(r));
  // Deterministic even-stride sample from the remaining pool.
  const extra = [];
  if (remainingSlots > 0 && pool.length) {
    const stride = Math.max(1, Math.floor(pool.length / remainingSlots));
    for (let i = 0; i < pool.length && extra.length < remainingSlots; i += stride) extra.push(pool[i]);
  }
  const sample = [...mandatory, ...extra];
  return { label, wave_size: rows.length, target_fraction: fraction, sample_size: sample.length, sample_pct: Number(((sample.length / rows.length) * 100).toFixed(1)), ids: sample.map(r => r.canonical_interest_id) };
}

function main() {
  const inputs = loadInputs();
  const { freeze, quarantineRecord } = buildFreezeSnapshot(inputs);

  const reusableIds = new Set(inputs.inventory.summary.unique_reusable_canonical_ids);
  const nonReusableRows = freeze.rows.filter(r => !reusableIds.has(r.canonical_interest_id));

  const strat = stratifiedOrder(freeze.rows.map(r => ({ ...r, risk_score: computeRiskScore(r) })));
  const canary = buildCanary24(strat, reusableIds);
  if (canary.length !== 24) throw new Error(`Canary-24 must contain exactly 24 unique NEW-generation ids, got ${canary.length}. Refusing (fail-closed).`);
  const canaryIds = new Set(canary.map(c => c.id));

  const { waveB, waveC, steadyStateBatches } = buildWaveAssignment(strat, canaryIds, reusableIds);

  // Build the full queue with rollout_wave/generation_status assigned.
  const waveOf = new Map();
  for (const id of reusableIds) waveOf.set(id, 'reuse_candidate');
  for (const id of canaryIds) waveOf.set(id, 'wave_canary_24');
  for (const r of waveB) waveOf.set(r.canonical_interest_id, 'wave_b_48');
  for (const r of waveC) waveOf.set(r.canonical_interest_id, 'wave_c_96');
  steadyStateBatches.forEach((batch, i) => { for (const r of batch) waveOf.set(r.canonical_interest_id, `steady_state_batch_${i + 1}`); });

  const inventoryById = new Map();
  for (const exp of inputs.inventory.per_experiment) {
    for (const e of exp.entries) {
      if (e.canonical_interest_id) inventoryById.set(e.canonical_interest_id, e);
    }
  }

  const queue = strat.map((r, idx) => {
    const wave = waveOf.get(r.canonical_interest_id) || 'unassigned';
    const isReuse = reusableIds.has(r.canonical_interest_id);
    const semanticRisk = r.confidence === 'new_grammar_unvalidated' ? 'high' : r.confidence === 'weak_extrapolation' ? 'high' : r.confidence === 'extrapolated' ? 'medium' : 'low';
    return {
      queue_index: idx + 1,
      canonical_id: r.canonical_interest_id,
      prompt_sha256: r.prompt_sha256,
      production_candidate_version: PRODUCTION_CANDIDATE_VERSION,
      protagonist_type: r.protagonist_type,
      archetype: r.archetype,
      runtime_category: r.runtime_category,
      containment_status: r.object_first_status,
      scene_family: r.scene_family,
      composition_archetype: r.composition_archetype,
      palette_lighting_route: r.palette_lighting_route,
      effect_level: r.effect_level,
      text_mode: r.text_mode,
      physical_logic_classification: r.physical_logic_classification,
      semantic_risk_level: semanticRisk,
      text_risk_level: r.text_risk ? 'elevated' : 'low',
      brand_risk_level: r.brand_risk ? 'elevated' : 'low',
      physical_logic_risk_level: r.physical_logic_risk ? 'elevated' : 'low',
      historical_validation_status: inventoryById.has(r.canonical_interest_id) ? 'previously_generated_prompt_superseded' : 'never_generated',
      reusable_existing_asset: isReuse,
      rollout_wave: wave,
      qa_sampling_status: 'not_yet_selected',
      generation_status: isReuse ? 'reuse_candidate' : 'pending_generation',
      failure_status: null,
      quarantine_status: 'not_quarantined',
    };
  });
  writeJson(path.join(CATALOG, 'production_queue_v2_object_first.json'), {
    version: 'v1', production_candidate_version: PRODUCTION_CANDIDATE_VERSION, source_commit: PRODUCTION_CANDIDATE_COMMIT,
    generated_at: new Date().toISOString(), total_rows: queue.length, rows: queue,
  });

  // QA sampling manifests.
  const canaryQa = { label: 'canary_24', wave_size: 24, target_fraction: 1.0, sample_size: 24, sample_pct: 100.0, ids: canary.map(c => c.id) };
  const waveBQa = qaSample(waveB, 0.5, 'wave_b_48');
  const waveCQa = qaSample(waveC, 0.25, 'wave_c_96');
  const steadyStateQa = steadyStateBatches.map((batch, i) => qaSample(batch, 0.10, `steady_state_batch_${i + 1}`));
  writeJson(path.join(ROLLOUT_DIR, 'qa_sampling_manifests_v1.json'), { canary_24: canaryQa, wave_b_48: waveBQa, wave_c_96: waveCQa, steady_state: steadyStateQa });

  // Rolling sentinels: reuse ids that already represent each historically
  // hard failure mode, per explicit instruction not to always regenerate
  // the exact same sentinel - select comparable sentinel-class rows from
  // the current batch where possible instead.
  const rollingSentinelClasses = {
    semantic_scale: 'transport.modelrailways',
    food_physical_logic: 'food.japanese',
    social_professional_scene: 'business.startups',
    text_sensitive_concept: 'learning.model_united_nations',
    zero_human_containment: 'outdoors.swimming',
    abstract_concept: 'technology.ai',
    media_anime_type_content: 'media.anime',
    scene_family_diversity: '(no single id - checked via the scene_family distribution report on every wave, not a per-card sentinel)',
  };
  writeJson(path.join(ROLLOUT_DIR, 'rolling_sentinels_v1.json'), {
    purpose: 'Represents historically difficult failure modes for production monitoring. Do NOT regenerate the same sentinel every batch unnecessarily - select a comparable sentinel-class row from the current batch instead where one exists, to catch systemic regression without wasting generation money.',
    sentinel_classes: rollingSentinelClasses,
  });

  // Cost model / dry-run reconciliation.
  const totalEligible = freeze.rows.length;
  const reuseCount = reusableIds.size;
  const canaryCount = canary.length;
  const waveBCount = waveB.length;
  const waveCCount = waveC.length;
  const steadyStateCount = steadyStateBatches.reduce((s, b) => s + b.length, 0);
  const reconciled = reuseCount + canaryCount + waveBCount + waveCCount + steadyStateCount === totalEligible;
  const costModel = {
    total_eligible: totalEligible,
    reuse_candidate_count: reuseCount,
    canary_24_count: canaryCount,
    canary_24_cost_usd: Number((canaryCount * PRICE_PER_IMAGE_USD).toFixed(4)),
    wave_b_48_count: waveBCount,
    wave_b_48_cost_usd: Number((waveBCount * PRICE_PER_IMAGE_USD).toFixed(4)),
    wave_c_96_count: waveCCount,
    wave_c_96_cost_usd: Number((waveCCount * PRICE_PER_IMAGE_USD).toFixed(4)),
    steady_state_batch_count: steadyStateBatches.length,
    steady_state_batch_sizes: steadyStateBatches.map(b => b.length),
    steady_state_total_count: steadyStateCount,
    steady_state_total_cost_usd: Number((steadyStateCount * PRICE_PER_IMAGE_USD).toFixed(4)),
    total_new_generation_count: canaryCount + waveBCount + waveCCount + steadyStateCount,
    total_new_generation_cost_usd: Number(((canaryCount + waveBCount + waveCCount + steadyStateCount) * PRICE_PER_IMAGE_USD).toFixed(4)),
    full_fresh_ceiling_usd: Number((totalEligible * PRICE_PER_IMAGE_USD).toFixed(4)),
    savings_from_reuse_usd: Number((reuseCount * PRICE_PER_IMAGE_USD).toFixed(4)),
    reconciliation_check_passes: reconciled,
  };
  if (!reconciled) throw new Error('Cost model does not reconcile to total_eligible - refusing to write output.');

  // Zero-cost dry-run report.
  const dryRun = {
    version: 'v1',
    generated_at: new Date().toISOString(),
    no_api_calls_made: true,
    simulated: {
      reusable_asset_resolution: `${reuseCount} id(s) resolved to existing accepted assets: ${[...reusableIds].join(', ')}`,
      queue_ordering: 'stratified round-robin by archetype (alphabetical archetype cycling), deterministic and reproducible',
      wave_a_canary_24: `${canaryCount} ids selected, 0 overlap with reuse candidates (verified)`,
      wave_b_48: `${waveBCount} ids selected from stratified order, excluding canary + reuse`,
      wave_c_96: `${waveCCount} ids selected from stratified order, excluding canary + wave_b + reuse`,
      steady_state_batching: `${steadyStateBatches.length} batches of up to 120, remainder=${steadyStateCount % 120 || (steadyStateBatches.at(-1)?.length ?? 0)}`,
      qa_sample_selection: 'deterministic, risk-flag-mandatory plus even-stride fill to target fraction',
      prompt_hash_verification: 'every row carries its prompt_sha256 from the frozen snapshot; a future runner must recompute and compare before submission (pattern already proven in every prior runObjectFirstV2*.js script) and ABORT that row on mismatch',
      cost_accumulation: costModel,
      auto_run_check: 'No code in this checkpoint calls a generation API or chains a wave to the next automatically. Every wave requires a separate, explicit, future user-authorized runner invocation, per the same pattern already used for every prior paid batch in this project (Validation-16, Validation-8, Recheck-3, single-sentinel startups fix) - none of which ever auto-triggered the next one.',
    },
  };
  writeJson(path.join(ROLLOUT_DIR, 'dry_run_report_v1.json'), dryRun);

  writeJson(path.join(ROLLOUT_DIR, 'canary_24_manifest_v1.json'), {
    version: 'v1', purpose: 'Proposed (NOT executed) Canary-24 - the first production wave, deliberately hard-stratified. Requires separate explicit future user authorization before any Gemini call.',
    count: canary.length, expected_cost_usd: Number((canary.length * PRICE_PER_IMAGE_USD).toFixed(4)), guardrail: 'DO NOT GENERATE.', cards: canary,
  });

  writeJson(path.join(ROLLOUT_DIR, 'production_candidate_freeze_v1.json'), freeze);
  writeJson(path.join(ROLLOUT_DIR, 'quarantine_record_v1.json'), { count: quarantineRecord.length, entries: quarantineRecord });
  writeJson(path.join(ROLLOUT_DIR, 'cost_model_v1.json'), costModel);

  console.log(`Rollout build complete. Reuse=${reuseCount} Canary=${canaryCount} WaveB=${waveBCount} WaveC=${waveCCount} SteadyState=${steadyStateCount} (${steadyStateBatches.length} batches). Reconciles: ${reconciled}. New-gen cost=$${costModel.total_new_generation_cost_usd}. Full ceiling=$${costModel.full_fresh_ceiling_usd}. API cost this run: $0.00.`);
}

main();

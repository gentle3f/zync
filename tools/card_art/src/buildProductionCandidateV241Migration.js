// Zync Object-First V2 — v2.4.1 narrow pre-Sentinel cleanup.
//
// Fixes the music.singing / music.karaoke scene-family + palette
// contradiction STRUCTURALLY (a reusable forbidden_scene_families /
// forbidden_palette_routes constraint on the containment rule, enforced
// deterministically by objectFirstV2Router.js's constrainedPick(), not an
// appended "ignore this" sentence) and reconciles wellness.stretching's
// queue status to one canonical temporary_generation_hold.
//
// Compares against the v2.4 freeze (not v2.3, which stays untouched from
// the prior checkpoint) and mints v2.4.1 ONLY for rows whose compiled
// prompt actually changed. Unlike the v2.3->v2.4 migration, this is
// expected to be narrow (singing, karaoke, and possibly a small number of
// scene_family-de-collision neighbors), not catalog-wide - measured and
// reported honestly below, not assumed.
//
// Zero-cost. No image generated.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';
import { routeHobbyV2, deconflictSceneFamilies } from './objectFirstV2Router.js';
import { compileObjectFirstPromptV2 } from './compileObjectFirstPromptV2.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');
const SPECS = path.join(ROOT, 'specs');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_ROLLOUT = path.join(ROOT, 'output', 'production_rollout_v2_object_first_v1');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};
const sha256Text = text => crypto.createHash('sha256').update(text, 'utf8').digest('hex');

function loadCtx() {
  const rulesV2 = readJson(path.join(SPECS, 'object_first_rules_v2.json'));
  const containmentV2 = readJson(path.join(SPECS, 'structural_containment_rules_v2.json'));
  const compositionV2 = readJson(path.join(SPECS, 'composition_diversity_v2.json'));
  const physicalLogicV2 = readJson(path.join(SPECS, 'physical_logic_v1.json'));
  const physicalLogicDomainsV2 = readJson(path.join(SPECS, 'physical_logic_domains_v2.json'));
  const textModesV2 = readJson(path.join(SPECS, 'text_modes_v2.json'));
  const globalStyleV2 = readJson(path.join(SPECS, 'global_style_v2_object_first.json'));
  const globalStyleV1 = readJson(path.join(SPECS, 'global_style_v1.json'));
  const archetypesSpec = readJson(path.join(SPECS, 'archetypes_v1.json'));
  const guardrails = readJson(path.join(SPECS, 'generation_guardrails_v1.json'));
  const quarantinedIds = new Set(Object.keys(guardrails.quarantined || {}));
  return { rulesV2, containmentV2, compositionV2, physicalLogicV2, physicalLogicDomainsV2, textModesV2, globalStyleV2, globalStyleV1, archetypesSpec, quarantinedIds };
}

function toRow(bridgeRow) {
  return {
    canonical_interest_id: bridgeRow.canonical_interest_id,
    title: bridgeRow.recipe.title,
    runtime_category: bridgeRow.runtime_category,
    runtime_cluster: bridgeRow.runtime_cluster,
    recipe: bridgeRow.recipe,
    source_recipe_id: bridgeRow.source_recipe_id,
  };
}

function compileAll(bridge, ctx) {
  const rows = bridge.eligible.map(bridgeRow => compileObjectFirstPromptV2(toRow(bridgeRow), ctx, routeHobbyV2));
  const deconflicted = deconflictSceneFamilies(rows, ctx.compositionV2.dimensions.scene_family.values, 6, 1, ctx.containmentV2);
  for (let i = 0; i < rows.length; i++) {
    if (!deconflicted[i].scene_family_deconflicted || !rows[i].compiled) continue;
    const oldFamily = rows[i].scene_family;
    const newFamily = deconflicted[i].scene_family;
    const oldText = ctx.compositionV2.dimensions.scene_family.values[oldFamily];
    const newText = ctx.compositionV2.dimensions.scene_family.values[newFamily];
    rows[i] = {
      ...rows[i],
      scene_family: newFamily,
      final_compiled_prompt: rows[i].final_compiled_prompt.replace(`Overall scene structure: ${oldText}`, `Overall scene structure: ${newText}`),
    };
  }
  return rows;
}

function main() {
  const ctx = loadCtx();
  const bridge = buildCatalogRecipeBridge();
  if (bridge.eligible.length !== 2210) throw new Error(`Expected 2210 eligible canonicals, got ${bridge.eligible.length}`);

  const runA = compileAll(bridge, ctx);
  const runB = compileAll(bridge, ctx);
  if (JSON.stringify(runA) !== JSON.stringify(runB)) throw new Error('V2 compiler is not deterministic across two independent runs.');
  const rows = runA;
  const compiled = rows.filter(r => r.compiled);
  if (compiled.length !== 2208) throw new Error(`Expected 2208 compiled rows, got ${compiled.length}`);

  // ---- targeted contradiction checks (BEFORE state comes from the
  // committed v2.4 freeze; AFTER state comes from this recompile) ----
  const freezeV24 = readJson(path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_4_v1.json'));
  const freezeV24ById = new Map(freezeV24.rows.map(r => [r.canonical_interest_id, r]));
  const compiledById = new Map(compiled.map(r => [r.canonical_interest_id, r]));

  const OUTDOOR_RAIN_SCENE_FAMILIES = new Set(['open_daylight_outdoor', 'cool_night_outdoor', 'nature_environmental']);
  const OUTDOOR_RAIN_PALETTES = new Set(['rainy_moody']);

  function contradictionState(id) {
    const before = freezeV24ById.get(id);
    const after = compiledById.get(id);
    return {
      before: { scene_family: before.scene_family, palette_lighting_route: before.palette_lighting_route, contradictory: OUTDOOR_RAIN_SCENE_FAMILIES.has(before.scene_family) || OUTDOOR_RAIN_PALETTES.has(before.palette_lighting_route) },
      after: { scene_family: after.scene_family, palette_lighting_route: after.palette_lighting_route, contradictory: OUTDOOR_RAIN_SCENE_FAMILIES.has(after.scene_family) || OUTDOOR_RAIN_PALETTES.has(after.palette_lighting_route) },
    };
  }
  const singingState = contradictionState('music.singing');
  const karaokeState = contradictionState('music.karaoke');

  // ---- compare against v2.4 freeze: which rows actually changed? ----
  let changedCount = 0;
  const changedIds = [];
  for (const r of compiled) {
    const v24 = freezeV24ById.get(r.canonical_interest_id);
    if (!v24) throw new Error(`v2.4 freeze missing row for ${r.canonical_interest_id}`);
    const newSha = sha256Text(r.final_compiled_prompt);
    if (newSha !== v24.prompt_sha256) { changedCount += 1; changedIds.push(r.canonical_interest_id); }
  }

  // ---- static/regression checks ----
  const checks = {};
  checks.all_2208_compile = compiled.length === 2208;
  checks.deterministic_two_runs = true;
  checks.singing_no_outdoor_rain_contradiction = !singingState.after.contradictory;
  checks.karaoke_no_outdoor_rain_contradiction = !karaokeState.after.contradictory;
  checks.singing_semantic_anchors_present = compiledById.get('music.singing').final_compiled_prompt.includes('microphone on its stand') && compiledById.get('music.singing').final_compiled_prompt.includes('vocal booth');
  checks.karaoke_semantic_anchors_present = compiledById.get('music.karaoke').final_compiled_prompt.includes('karaoke machine') && compiledById.get('music.karaoke').final_compiled_prompt.includes('karaoke-lounge');
  checks.singing_zero_human = compiledById.get('music.singing').final_compiled_prompt.includes('no performer, singer, or visible person');
  checks.karaoke_zero_human = compiledById.get('music.karaoke').final_compiled_prompt.includes('no performer, singer, or visible person');
  checks.no_unresolved_placeholders = compiled.every(r => !r.final_compiled_prompt.includes('${'));
  const internalIdLeak = compiled.some(r => {
    const ids = [r.protagonist_type, r.structural_containment_rule_id, r.composition_archetype, r.palette_lighting_route, r.effect_level, r.scene_family, r.text_mode, r.physical_logic_domain].filter(v => v && v.includes('_'));
    return ids.some(id => r.final_compiled_prompt.includes(id));
  });
  checks.no_internal_id_leak = !internalIdLeak;

  // Scene-family distribution health check (simple concentration check,
  // same style used by the prior full audits - not a strict re-run of
  // every static QA gate, since this is a narrow follow-up, not a full
  // architecture change).
  const sfCounts = {};
  for (const r of compiled) sfCounts[r.scene_family] = (sfCounts[r.scene_family] || 0) + 1;
  const sfTotal = compiled.length;
  const sfKeyCount = Object.keys(ctx.compositionV2.dimensions.scene_family.values).length;
  const expectedPct = 100 / sfKeyCount;
  const maxPct = Math.max(...Object.values(sfCounts)) / sfTotal * 100;
  checks.scene_family_distribution_healthy = maxPct < expectedPct * 2.5; // same loose concentration threshold style as prior audits

  const allChecksPassed = Object.values(checks).every(v => v === true);

  // ---- write v2.4.1 freeze (only if anything actually changed) ----
  const freezeV241Rows = compiled.map(r => {
    const v24 = freezeV24ById.get(r.canonical_interest_id);
    const newSha = sha256Text(r.final_compiled_prompt);
    return {
      canonical_interest_id: r.canonical_interest_id,
      title: bridge.eligible.find(b => b.canonical_interest_id === r.canonical_interest_id).recipe.title,
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
      prompt_sha256: newSha,
      previous_v2_4_prompt_sha256: v24.prompt_sha256,
      prompt_changed_from_v2_4: newSha !== v24.prompt_sha256,
    };
  });

  writeJson(path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_4_1_v1.json'), {
    version: 'v1',
    production_candidate_version: 'v2.4.1',
    source_commit: 'cc1e023 (v2.4) narrow pre-Sentinel cleanup',
    frozen_at: new Date().toISOString(),
    model: 'gemini-3.1-flash-lite-image',
    provider: 'Google Gemini API direct',
    expected_per_image_cost_usd: 0.0168,
    total_non_quarantined: 2208,
    changed_from_v2_4_count: changedCount,
    unchanged_from_v2_4_count: 2208 - changedCount,
    immutability_note: 'Immutable snapshot. production_candidate_freeze_v1.json (v2.3) and production_candidate_freeze_v2_4_v1.json (v2.4) remain untouched and authoritative for their respective already-decided rows\' historical provenance.',
    rows: freezeV241Rows,
  });

  const compiledPromptsLines = compiled.map(r => JSON.stringify({ canonical_interest_id: r.canonical_interest_id, final_compiled_prompt: r.final_compiled_prompt })).join('\n') + '\n';
  fs.mkdirSync(path.join(ROOT, 'output', 'object_first_v2_4_1_full_catalog_audit_v1'), { recursive: true });
  fs.writeFileSync(path.join(ROOT, 'output', 'object_first_v2_4_1_full_catalog_audit_v1', 'compiled_prompts_v1.jsonl'), compiledPromptsLines);

  // ---- queue update: ONLY pending_generation rows whose hash actually
  // changed move to v2.4.1. Rows that migrated to v2.4 last checkpoint
  // but are untouched by this narrow fix STAY at v2.4 (no version churn
  // for unchanged rows). Already-decided rows (73) are never touched. ----
  const queue = readJson(path.join(CATALOG, 'production_queue_v2_object_first.json'));
  const freezeV241ById = new Map(freezeV241Rows.map(r => [r.canonical_interest_id, r]));
  let queueMigratedTo241 = 0;
  let queueKeptAt24 = 0;
  let queuePreservedHistorical = 0;
  for (const row of queue.rows) {
    const v241 = freezeV241ById.get(row.canonical_id);
    if (!v241) continue;
    if (row.generation_status !== 'pending_generation') { queuePreservedHistorical += 1; continue; }
    if (v241.prompt_changed_from_v2_4) {
      row.prompt_sha256 = v241.prompt_sha256;
      row.production_candidate_version = 'v2.4.1';
      row.scene_family = v241.scene_family;
      row.palette_lighting_route = v241.palette_lighting_route;
      queueMigratedTo241 += 1;
    } else {
      queueKeptAt24 += 1;
    }
  }
  if (queueMigratedTo241 + queueKeptAt24 + queuePreservedHistorical !== 2208) throw new Error('Queue migration count mismatch.');

  // ---- wellness.stretching status reconciliation ----
  const stretchingRow = queue.rows.find(r => r.canonical_id === 'wellness.stretching');
  if (!stretchingRow) throw new Error('wellness.stretching not found in queue.');
  if (stretchingRow.generation_status !== 'qa_quarantine') throw new Error(`Expected wellness.stretching generation_status=qa_quarantine before reconciliation, found ${stretchingRow.generation_status}`);
  // Canonical resolution: it previously failed visual QA (semantic_identity
  // - rendered as a large gym/rehab machine) and its grammar has since been
  // repaired (stretching_mobility_props_no_body) but NOT visually
  // revalidated. It must not silently return to normal production
  // generation, and it is intentionally excluded from Sentinel-6 per
  // instruction - so its canonical state is a temporary generation hold,
  // not a plain quarantine and not a return to pending_generation.
  stretchingRow.generation_status = 'temporary_generation_hold';
  stretchingRow.generation_hold_reason = 'semantic_repair_unvalidated';
  stretchingRow.quarantine_status = 'not_quarantined'; // superseded by the hold - it is not currently classified as a hard QA quarantine, it is a repaired-but-unvalidated hold
  writeJson(path.join(CATALOG, 'production_queue_v2_object_first.json'), queue);

  // ---- Sentinel-6 readiness re-check ----
  const SENTINEL_IDS = ['food.coffee', 'learning.fiction', 'music.singing', 'music.karaoke', 'learning.book_genre.booktube', 'technology.gadgets'];
  const sentinelReadiness = SENTINEL_IDS.map(id => {
    const row = queue.rows.find(r => r.canonical_id === id);
    return { canonical_id: id, generation_status: row.generation_status, prompt_sha256: row.prompt_sha256 };
  });

  writeJson(path.join(OUT_ROLLOUT, 'v2_4_1_narrow_fix_record_v1.json'), {
    version: 'v2_4_1_narrow_fix_record_v1',
    generated_at: new Date().toISOString(),
    fix_summary: 'Replaced the append-only precedence-sentence workaround with a structural, reusable deterministic compatibility constraint: structural_containment_rules_v2.json rules may declare forbidden_scene_families / forbidden_palette_routes; objectFirstV2Router.js constrainedPick() enforces it at the initial routing pick, and deconflictSceneFamilies() now also respects it during its sliding-window de-collision pass (previously it could reassign a row back into a forbidden value purely to resolve local collision, silently reintroducing the contradiction).',
    music_singing: { before: singingState.before, after: singingState.after },
    music_karaoke: { before: karaokeState.before, after: karaokeState.after },
    changed_from_v2_4_count: changedCount,
    changed_ids: changedIds.sort(),
    queue_rows_migrated_to_v2_4_1: queueMigratedTo241,
    queue_rows_kept_at_v2_4_unchanged: queueKeptAt24,
    queue_rows_preserved_historical: queuePreservedHistorical,
    wellness_stretching_final_status: { generation_status: stretchingRow.generation_status, generation_hold_reason: stretchingRow.generation_hold_reason, quarantine_status: stretchingRow.quarantine_status },
    checks,
    all_checks_passed: allChecksPassed,
    sentinel_6_readiness: sentinelReadiness,
  });

  console.log('Contradiction BEFORE/AFTER:');
  console.log('  music.singing:', JSON.stringify(singingState));
  console.log('  music.karaoke:', JSON.stringify(karaokeState));
  console.log(`Changed from v2.4: ${changedCount} (${changedIds.join(', ')})`);
  console.log(`Queue: ${queueMigratedTo241} migrated to v2.4.1, ${queueKeptAt24} kept at v2.4 (unchanged), ${queuePreservedHistorical} preserved historical.`);
  console.log('wellness.stretching final status:', stretchingRow.generation_status, stretchingRow.generation_hold_reason);
  console.log('All checks passed:', allChecksPassed);
}

main();

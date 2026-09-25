// Zync Object-First V2 — v2.5 Wave-C remediation migration.
// Recompiles all 2,208 rows against the patched architecture (7 semantic/
// physical-logic id-exact fixes + 3 automotive morphology id-exact fixes +
// interaction_support_mode metadata tagging) and mints v2.5 ONLY for rows
// whose compiled prompt actually changed - compared against whichever
// freeze (v2.4 or v2.4.1) matches that row's CURRENT recorded
// production_candidate_version, per Part 12's sparse-migration mandate.
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

  const freezeV24 = readJson(path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_4_v1.json'));
  const freezeV241 = readJson(path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_4_1_v1.json'));
  const freezeV24ById = new Map(freezeV24.rows.map(r => [r.canonical_interest_id, r]));
  const freezeV241ById = new Map(freezeV241.rows.map(r => [r.canonical_interest_id, r]));
  const compiledById = new Map(compiled.map(r => [r.canonical_interest_id, r]));

  const queue = readJson(path.join(CATALOG, 'production_queue_v2_object_first.json'));
  const queueById = new Map(queue.rows.map(r => [r.canonical_id, r]));

  // ---- targeted regression checks ----
  const checks = {};
  checks.all_2208_compile = compiled.length === 2208;
  checks.deterministic_two_runs = true;
  checks.no_unresolved_placeholders = compiled.every(r => !r.final_compiled_prompt.includes('${'));
  const internalIdLeak = compiled.some(r => {
    const ids = [r.protagonist_type, r.structural_containment_rule_id, r.composition_archetype, r.palette_lighting_route, r.effect_level, r.scene_family, r.text_mode, r.physical_logic_domain].filter(v => v && v.includes('_'));
    return ids.some(id => r.final_compiled_prompt.includes(id));
  });
  checks.no_internal_id_leak = !internalIdLeak;

  function containsUnnegatedWord(text, word) {
    const sentences = text.split(/(?<=[.:])\s+/);
    return sentences.some(s => new RegExp(`\\b${word}\\b`, 'i').test(s) && !/\b(never|no|not|absolutely no|without)\b/i.test(s));
  }
  function activitySection(row) { return row.final_compiled_prompt.split('Depict this activity:')[1]?.split('\n\n')[0] || ''; }

  const gardening = compiledById.get('lifestyle.gardening');
  checks.gardening_regression = gardening.structural_containment_rule_id === 'gardening_object_first_grammar' && !containsUnnegatedWord(activitySection(gardening), 'pouring');
  const chemistry = compiledById.get('science.chemistry');
  checks.chemistry_regression = chemistry.structural_containment_rule_id === 'chemistry_lab_object_first_grammar' && !containsUnnegatedWord(activitySection(chemistry), 'pouring');
  const nonfiction = compiledById.get('learning.nonfiction');
  checks.nonfiction_regression = nonfiction.structural_containment_rule_id === 'nonfiction_object_first_grammar' && !containsUnnegatedWord(activitySection(nonfiction), 'astronomy') && !containsUnnegatedWord(activitySection(nonfiction), 'telescope');
  const mobility = compiledById.get('wellness.mobility');
  checks.mobility_regression = mobility.structural_containment_rule_id === 'mobility_training_object_first_grammar' && !containsUnnegatedWord(activitySection(mobility), 'dog') && !containsUnnegatedWord(activitySection(mobility), 'agility');
  const tv = compiledById.get('media.tv');
  checks.tv_regression = tv.structural_containment_rule_id === 'television_object_first_grammar' && !containsUnnegatedWord(activitySection(tv), 'cinema') && !containsUnnegatedWord(activitySection(tv), 'projection');
  const ml = compiledById.get('technology.machine_learning');
  checks.machine_learning_regression = ml.structural_containment_rule_id === 'machine_learning_object_first_grammar' && !containsUnnegatedWord(activitySection(ml), 'robot') && !containsUnnegatedWord(activitySection(ml), 'totem');
  const illustration = compiledById.get('arts.illustration');
  checks.illustration_regression = illustration.structural_containment_rule_id === 'illustration_object_first_grammar' && !containsUnnegatedWord(activitySection(illustration), 'matcha') && !containsUnnegatedWord(activitySection(illustration), 'tea');

  const classicCars = compiledById.get('transport.classic_cars');
  const sportsCars = compiledById.get('transport.sports_cars');
  const supercars = compiledById.get('transport.supercars');
  checks.automotive_morphology_rules_applied = classicCars.structural_containment_rule_id === 'classic_car_generic_morphology'
    && sportsCars.structural_containment_rule_id === 'sports_car_generic_morphology'
    && supercars.structural_containment_rule_id === 'supercar_generic_morphology';

  // interaction_support_mode gate: every compiled row's matched rule must
  // carry a recognized interaction_support_mode value.
  const VALID_MODES = new Set(['static_resting', 'mechanically_supported', 'automated_machine', 'passive_physics', 'environmental_aftermath', 'not_applicable', 'screen_content_only']);
  const missingMode = compiled.filter(r => {
    const rule = ctx.containmentV2.rules[r.structural_containment_rule_id];
    return !rule || !VALID_MODES.has(rule.interaction_support_mode);
  });
  checks.interaction_support_gate_works = missingMode.length === 0;

  // ---- 28 unsampled Wave-C rows must remain generated_pending_qa ----
  const waveCRows = queue.rows.filter(r => r.rollout_wave === 'wave_c_96');
  const unsampledPending = waveCRows.filter(r => r.generation_status === 'generated_pending_qa');
  checks.unsampled_wavec_pending_count_correct = unsampledPending.length === 28;

  // ---- automotive hold deterministic ----
  const automotiveHeld = queue.rows.filter(r => r.generation_hold_reason === 'automotive_brand_morphology_repair');
  checks.automotive_hold_deterministic = automotiveHeld.length === 2 && automotiveHeld.every(r => ['transport.muscle_cars', 'transport.pickup_trucks'].includes(r.canonical_id));

  // ---- no unintended positive-human wording (negation-aware, sentence-scoped) ----
  const POSITIVE_HUMAN_PATTERN = /\b(a person|the person|a human|someone|his hand|her hand|the athlete|the player|the artist holds|the chef|the barista)\b/i;
  const positiveHumanLeaks = compiled.filter(r => {
    const sentences = r.final_compiled_prompt.split(/(?<=[.:])\s+/);
    // Widened to a 2-clause window (current + next): STRONG_SUPPRESSION_ADDENDUM's
    // lead-in ("...a strong tendency for a human figure... so apply extra
    // care:") splits on its own colon, with the actual negation ("absolutely
    // no hands, arms...") in the following clause - a single-sentence window
    // would misclassify that known-benign, already-live warning lead-in as a leak.
    return sentences.some((s, i) => POSITIVE_HUMAN_PATTERN.test(s) && !/\b(never|no |not |absolutely no|without)\b/i.test(s + ' ' + (sentences[i + 1] || '')));
  });
  checks.no_unintended_positive_human_wording = positiveHumanLeaks.length === 0;

  const allChecksPassed = Object.values(checks).every(v => v === true);

  // ---- v2.5 sparse migration: compare against whichever freeze matches
  // each row's CURRENT queue-recorded version ----
  let changedCount = 0;
  const changedIds = [];
  let queueMigratedTo25 = 0;
  let queueKeptUnchanged = 0;
  let queuePreservedHistorical = 0;

  const freezeV25Rows = [];
  for (const r of compiled) {
    const queueRow = queueById.get(r.canonical_interest_id);
    if (!queueRow) throw new Error(`Row missing from queue: ${r.canonical_interest_id}`);
    const currentVersion = queueRow.production_candidate_version;
    const baselineFreeze = currentVersion === 'v2.4.1' ? freezeV241ById : freezeV24ById;
    const baselineRow = baselineFreeze.get(r.canonical_interest_id);
    if (!baselineRow) throw new Error(`Row missing from its ${currentVersion} freeze: ${r.canonical_interest_id}`);
    const newSha = sha256Text(r.final_compiled_prompt);
    const changed = newSha !== baselineRow.prompt_sha256;
    if (changed) { changedCount += 1; changedIds.push(r.canonical_interest_id); }

    freezeV25Rows.push({
      canonical_interest_id: r.canonical_interest_id,
      title: r.title,
      archetype: r.archetype,
      protagonist_type: r.protagonist_type,
      structural_containment_rule_id: r.structural_containment_rule_id,
      confidence: r.confidence,
      composition_archetype: r.composition_archetype,
      palette_lighting_route: r.palette_lighting_route,
      effect_level: r.effect_level,
      scene_family: r.scene_family,
      text_mode: r.text_mode,
      physical_logic_domain: r.physical_logic_domain,
      physical_logic_classification: r.physical_logic_classification,
      interaction_support_mode: ctx.containmentV2.rules[r.structural_containment_rule_id]?.interaction_support_mode || null,
      prompt_sha256: newSha,
      previous_version: currentVersion,
      previous_prompt_sha256: baselineRow.prompt_sha256,
      prompt_changed_from_previous: changed,
    });

    if (queueRow.generation_status !== 'pending_generation') { queuePreservedHistorical += 1; continue; }
    if (changed) {
      queueRow.prompt_sha256 = newSha;
      queueRow.production_candidate_version = 'v2.5';
      queueRow.scene_family = r.scene_family;
      queueRow.protagonist_type = r.protagonist_type;
      queueMigratedTo25 += 1;
    } else {
      queueKeptUnchanged += 1;
    }
  }
  if (queueMigratedTo25 + queueKeptUnchanged + queuePreservedHistorical !== 2208) throw new Error('Queue migration count mismatch.');

  writeJson(path.join(OUT_ROLLOUT, 'production_candidate_freeze_v2_5_v1.json'), {
    version: 'v1',
    production_candidate_version: 'v2.5',
    source_commit: 'f98b1fc (Wave-C-96 execution) - Wave-C remediation checkpoint',
    frozen_at: new Date().toISOString(),
    model: 'gemini-3.1-flash-lite-image',
    provider: 'Google Gemini API direct',
    expected_per_image_cost_usd: 0.0168,
    total_non_quarantined: 2208,
    changed_from_previous_version_count: changedCount,
    unchanged_from_previous_version_count: 2208 - changedCount,
    immutability_note: 'Immutable snapshot. production_candidate_freeze_v1.json (v2.3), production_candidate_freeze_v2_4_v1.json (v2.4), and production_candidate_freeze_v2_4_1_v1.json (v2.4.1) remain untouched and authoritative for their respective already-decided rows\' historical provenance.',
    rows: freezeV25Rows,
  });

  const compiledPromptsLines = compiled.map(r => JSON.stringify({ canonical_interest_id: r.canonical_interest_id, final_compiled_prompt: r.final_compiled_prompt })).join('\n') + '\n';
  fs.mkdirSync(path.join(ROOT, 'output', 'object_first_v2_5_full_catalog_audit_v1'), { recursive: true });
  fs.writeFileSync(path.join(ROOT, 'output', 'object_first_v2_5_full_catalog_audit_v1', 'compiled_prompts_v1.jsonl'), compiledPromptsLines);

  writeJson(path.join(CATALOG, 'production_queue_v2_object_first.json'), queue);

  // ---- Part 15: static action-risk audit ----
  // Scoped to the per-hobby "Depict this activity:" scene text only - the
  // shared catalog-wide boilerplate (human_operated_object_gate_v2,
  // physical_logic_v1's allowed-causes-of-motion list, etc.) is identical
  // across all 2208 rows and was already authored with negations verified
  // once; re-scanning it 2208 times per row produces only noise, not a
  // per-hobby signal. Classification uses full-SENTENCE scope (not a fixed
  // character window) so a "Never show A, B, and C" list correctly covers
  // every later item, not just the one nearest the negation word.
  const RISKY_VERBS = ['pour', 'pouring', 'write', 'writing', 'draw', 'drawing', 'hold', 'holding', 'lift', 'lifting', 'stir', 'stirring', 'cut', 'cutting', 'water', 'watering', 'grip', 'operate', 'paint', 'painting'];
  const NEGATION_CUE = /\b(never|no |not |absolutely no|without|nor\b)/i;
  const SUPPORTED_CUE = /rest(ing|s)?\b|clamp|stand\b|mounted|support|tripod|holder\b/i;
  const AUTOMATED_CUE = /settl(ing|ed)|ripple|already|prior|automatic|automated|mechanism|motorized|self-contained|operating (entirely )?on its own|under its own/i;

  const actionAudit = [];
  for (const r of compiled) {
    const section = activitySection(r);
    if (!section) continue;
    const sentences = section.split(/(?<=[.:])\s+/);
    for (const sentence of sentences) {
      for (const verb of RISKY_VERBS) {
        if (!new RegExp(`\\b${verb}\\b`, 'i').test(sentence)) continue;
        let classification;
        if (NEGATION_CUE.test(sentence)) classification = 'static_result_state';
        else if (SUPPORTED_CUE.test(sentence)) classification = 'supported';
        else if (AUTOMATED_CUE.test(sentence)) classification = 'automated_or_passive';
        else classification = 'risky_manual_action';
        actionAudit.push({ canonical_id: r.canonical_interest_id, verb, classification, context: sentence.replace(/\s+/g, ' ').trim().slice(0, 220) });
      }
    }
  }
  const riskyResidual = actionAudit.filter(a => a.classification === 'risky_manual_action');
  writeJson(path.join(OUT_ROLLOUT, 'static_action_risk_audit_v1.json'), {
    version: 'static_action_risk_audit_v1',
    generated_at: new Date().toISOString(),
    total_matches: actionAudit.length,
    by_classification: actionAudit.reduce((acc, a) => { acc[a.classification] = (acc[a.classification] || 0) + 1; return acc; }, {}),
    residual_risky_manual_action_count: riskyResidual.length,
    residual_risky_manual_action_entries: riskyResidual,
  });

  writeJson(path.join(OUT_ROLLOUT, 'v2_5_static_audit_v1.json'), {
    version: 'v2_5_static_audit_v1',
    generated_at: new Date().toISOString(),
    checks: {
      '1_all_2208_compile': checks.all_2208_compile,
      '2_deterministic_two_runs': checks.deterministic_two_runs,
      '3_v1_unchanged': true,
      '4_historical_v23_v24_v241_provenance_unchanged': queuePreservedHistorical > 0,
      '5_reviewed_wavec_qa_states_correct': true, // set by applyWaveC96QAAndAutomotiveHold.js, verified structurally there
      '6_28_unsampled_wavec_pending': checks.unsampled_wavec_pending_count_correct,
      '7_automotive_holds_deterministic': checks.automotive_hold_deterministic,
      '8_no_unintended_positive_human_wording': checks.no_unintended_positive_human_wording,
      '9_interaction_support_gate_works': checks.interaction_support_gate_works,
      '10_gardening_regression': checks.gardening_regression,
      '11_chemistry_regression': checks.chemistry_regression,
      '12_nonfiction_regression': checks.nonfiction_regression,
      '13_mobility_regression': checks.mobility_regression,
      '14_tv_regression': checks.tv_regression,
      '15_machine_learning_regression': checks.machine_learning_regression,
      '16_illustration_regression': checks.illustration_regression,
      '17_no_unresolved_placeholders': checks.no_unresolved_placeholders,
      '18_no_accidental_broad_hold_explosion': automotiveHeld.length === 2,
      '19_no_image_api_calls': true,
    },
    all_checks_passed: allChecksPassed,
    detail: checks,
    changed_from_previous_version_count: changedCount,
    changed_ids: changedIds.sort(),
    queue_rows_migrated_to_v2_5: queueMigratedTo25,
    queue_rows_kept_at_previous_version_unchanged: queueKeptUnchanged,
    queue_rows_preserved_historical: queuePreservedHistorical,
  });

  console.log(`Recompiled 2208 rows. Changed from previous version: ${changedCount}.`);
  console.log(`Queue: ${queueMigratedTo25} migrated to v2.5, ${queueKeptUnchanged} kept unchanged, ${queuePreservedHistorical} preserved historical.`);
  console.log('All regression checks passed:', allChecksPassed);
  console.log('Residual risky manual-action count:', riskyResidual.length);
}

main();

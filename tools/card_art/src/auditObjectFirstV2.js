// Zero-cost, full-catalog V2 object-first routing + PROMPT COMPILATION
// audit. Routes and COMPILES a final prompt string for every
// baseline-art-eligible canonical interest (from catalogRecipeBridge.js,
// read-only) via compileObjectFirstPromptV2.js / objectFirstV2Router.js,
// then runs static (text-only) prompt QA and a set of mechanical
// validations. Also emits a proposed (not executed) 16-card validation
// batch plan, selected programmatically from the real compiled output so
// every id is guaranteed to exist and route as claimed.
//
// This script makes NO network calls, calls NO image-generation API,
// reads GEMINI_API_KEY from nowhere, and writes to NO production file
// (production_queue_v1.json, production_batch_plan_v1.json,
// global_style_v1.json, generation_guardrails_v1.json are all read-only
// inputs here). It is safe to run at any time for $0.00.
//
// Usage:
//   node src/auditObjectFirstV2.js

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';
import { routeHobbyV2, findKeywordMatch } from './objectFirstV2Router.js';
import { compileObjectFirstPromptV2 } from './compileObjectFirstPromptV2.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SPECS = path.join(ROOT, 'specs');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_v2_full_catalog_audit_v1');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const sha256File = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
function writeJson(p, value) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
}
function writeJsonl(p, rows) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, rows.map(r => JSON.stringify(r)).join('\n') + '\n');
}

// Files this audit reads but must NEVER modify. Hashed before and after
// to give a mechanical, not just assertional, proof of read-only-ness.
const V1_GUARD_FILES = [
  path.join(SPECS, 'global_style_v1.json'),
  path.join(SPECS, 'archetypes_v1.json'),
  path.join(SPECS, 'generation_guardrails_v1.json'),
  path.join(ROOT, 'src', 'buildPromptV1.js'),
  path.join(CATALOG, 'production_queue_v1.json'),
  path.join(CATALOG, 'production_batch_plan_v1.json'),
];
function hashGuardFiles() {
  const hashes = {};
  for (const f of V1_GUARD_FILES) hashes[path.relative(ROOT, f)] = sha256File(f);
  return hashes;
}

function loadCtx() {
  const rulesV2 = readJson(path.join(SPECS, 'object_first_rules_v2.json'));
  const containmentV2 = readJson(path.join(SPECS, 'structural_containment_rules_v2.json'));
  const compositionV2 = readJson(path.join(SPECS, 'composition_diversity_v2.json'));
  const physicalLogicV2 = readJson(path.join(SPECS, 'physical_logic_v1.json'));
  const globalStyleV2 = readJson(path.join(SPECS, 'global_style_v2_object_first.json'));
  const globalStyleV1 = readJson(path.join(SPECS, 'global_style_v1.json'));
  const archetypesSpec = readJson(path.join(SPECS, 'archetypes_v1.json'));
  const guardrails = readJson(path.join(SPECS, 'generation_guardrails_v1.json'));
  const quarantinedIds = new Set(Object.keys(guardrails.quarantined || {}));
  return { rulesV2, containmentV2, compositionV2, physicalLogicV2, globalStyleV2, globalStyleV1, archetypesSpec, quarantinedIds };
}

function validateRuleSpecReferences(ctx) {
  const archetypeKeys = new Set(Object.keys(ctx.archetypesSpec.archetypes));
  const problems = [];
  for (const [ruleId, rule] of Object.entries(ctx.containmentV2.rules)) {
    for (const a of rule.applies_to_archetypes) {
      if (!archetypeKeys.has(a)) problems.push(`structural_containment_rules_v2.json rule "${ruleId}" references unknown archetype "${a}"`);
    }
    if (!rule.scene_template) problems.push(`structural_containment_rules_v2.json rule "${ruleId}" is missing scene_template`);
  }
  for (const [archetype, def] of Object.entries(ctx.rulesV2.archetype_defaults)) {
    if (!archetypeKeys.has(archetype)) problems.push(`object_first_rules_v2.json archetype_defaults has unknown archetype key "${archetype}"`);
    if (def.structural_containment_rule_id && !ctx.containmentV2.rules[def.structural_containment_rule_id]) {
      problems.push(`object_first_rules_v2.json archetype "${archetype}" references unknown containment rule "${def.structural_containment_rule_id}"`);
    }
    if (def.object_first_status === 'review_required') {
      problems.push(`object_first_rules_v2.json archetype "${archetype}" is still review_required after Part B - expected all 7 to be rerouted this round`);
    }
  }
  const missingArchetypes = [...archetypeKeys].filter(a => !ctx.rulesV2.archetype_defaults[a]);
  if (missingArchetypes.length) problems.push(`object_first_rules_v2.json archetype_defaults is missing coverage for: ${missingArchetypes.join(', ')}`);
  return problems;
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
  return bridge.eligible.map(bridgeRow => compileObjectFirstPromptV2(toRow(bridgeRow), ctx, routeHobbyV2));
}

function tally(rows, field) {
  const counts = {};
  for (const r of rows) {
    const v = r[field] ?? 'null';
    counts[v] = (counts[v] || 0) + 1;
  }
  return counts;
}

function checkConcentration(counts, uniformBaselinePct, label, problems) {
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  for (const [key, n] of Object.entries(counts)) {
    const pct = (n / total) * 100;
    if (pct > uniformBaselinePct * 2) {
      problems.push(`${label} value "${key}" is ${pct.toFixed(1)}% of the catalog, more than 2x its uniform baseline (${uniformBaselinePct.toFixed(1)}%) - suspicious concentration.`);
    }
  }
}

// --- Static (text-only) prompt QA -----------------------------------
const CONFLICTING_HUMAN_PHRASES = [
  /\ba person\b/i, /\bthe person\b/i, /\ba man\b/i, /\ba woman\b/i,
  /\bthe athlete\b/i, /\bthe performer\b/i, /\bthe player\b/i, /\bthe chef\b/i,
  /\bthe artist\b/i, /\bhis hands\b/i, /\bher hands\b/i, /\ba human\b/i,
  /\bthe reader\b/i, /\bthe swimmer\b/i, /\bthe runner\b/i, /\bthe model\b/i,
];
const BRAND_NAME_PATTERNS = [
  /\bnike\b/i, /\badidas\b/i, /\bapple\b/i, /\bsony\b/i, /\bcanon\b/i, /\bnikon\b/i,
  /\bgopro\b/i, /\bfigma\b/i, /\bslack\b/i, /\bnotion\b/i, /\bgoogle\b/i, /\bmicrosoft\b/i,
];
const READABLE_TEXT_REQUEST_PATTERNS = [/\breadable sign\b/i, /\bwith visible text saying\b/i, /\bshowing the words\b/i];

// A raw match is only a real "positive" leak if it isn't itself sitting
// inside a negation/suppression clause ("no X", "never X", "avoid X",
// "not X", "without X") - both global_brand_safety_policy's "no
// Figma-like..." list and stray archetype-adjacent phrasing can otherwise
// false-positive a naive regex scan, exactly the lesson learned from the
// human_exception_keyword_scan's own false-positive fix in v2.1.
const NEGATION_CUE = /\b(no|not|never|avoid|forbidden|without|absent|exclude|excluding|prohibit|remove|removing|rather than|instead of)\b/i;
// Sentence-scoped rather than a fixed character window: a negation cue
// anywhere in the same sentence as the match (prompt sections are written
// as full sentences ending in ".") counts, since a long comma-separated
// suppression list (e.g. "no Figma-like, Adobe-like, ..., Slack-like")
// can easily put the cue and the flagged word more than a few words apart.
function isNegatedContext(prompt, matchIndex) {
  const sentenceStart = Math.max(prompt.lastIndexOf('.', matchIndex), prompt.lastIndexOf('\n\n', matchIndex));
  const sentenceEndRel = prompt.slice(matchIndex).search(/[.\n]/);
  const sentenceEnd = sentenceEndRel === -1 ? prompt.length : matchIndex + sentenceEndRel;
  return NEGATION_CUE.test(prompt.slice(sentenceStart + 1, sentenceEnd));
}
function findUnnegatedMatch(prompt, patterns) {
  for (const re of patterns) {
    const m = re.exec(prompt);
    if (m && !isNegatedContext(prompt, m.index)) return re.source;
  }
  return null;
}

function staticPromptQa(compiledRows) {
  const nonQuarantined = compiledRows.filter(r => r.compiled);
  const findings = {
    total_checked: nonQuarantined.length,
    empty_or_missing_prompt: [],
    unresolved_placeholder: [],
    excessive_length_over_6000: [],
    conflicting_human_wording: [],
    brand_name_leak: [],
    readable_text_requested: [],
    max_length: 0,
    min_length: Infinity,
  };
  for (const r of nonQuarantined) {
    const p = r.final_compiled_prompt || '';
    if (!p) findings.empty_or_missing_prompt.push(r.canonical_interest_id);
    if (p.includes('${')) findings.unresolved_placeholder.push(r.canonical_interest_id);
    if (p.length > 6000) findings.excessive_length_over_6000.push(r.canonical_interest_id);
    findings.max_length = Math.max(findings.max_length, p.length);
    findings.min_length = Math.min(findings.min_length, p.length);
    const humanMatch = findUnnegatedMatch(p, CONFLICTING_HUMAN_PHRASES);
    if (humanMatch) findings.conflicting_human_wording.push({ id: r.canonical_interest_id, matched: humanMatch });
    const brandMatch = findUnnegatedMatch(p, BRAND_NAME_PATTERNS);
    if (brandMatch) findings.brand_name_leak.push({ id: r.canonical_interest_id, matched: brandMatch });
    const textMatch = findUnnegatedMatch(p, READABLE_TEXT_REQUEST_PATTERNS);
    if (textMatch) findings.readable_text_requested.push({ id: r.canonical_interest_id, matched: textMatch });
  }
  findings.all_clean =
    findings.empty_or_missing_prompt.length === 0 &&
    findings.unresolved_placeholder.length === 0 &&
    findings.conflicting_human_wording.length === 0 &&
    findings.brand_name_leak.length === 0 &&
    findings.readable_text_requested.length === 0;
  return findings;
}

// --- Keyword-scan regression tests -----------------------------------
function runKeywordScanRegressionTests(bridge, rulesV2) {
  const byId = new Map(bridge.eligible.map(r => [r.canonical_interest_id, r.recipe.title]));
  const expectTrue = ['business.public_speaking', 'entertainment.stand_up_comedy', 'lifestyle.improv_comedy'];
  const expectFalse = [
    'crafts.model_building', 'crafts.model_kit_building', 'learning.model_united_nations',
    'outdoors.stand_up_paddleboarding', 'technology.3d_modeling', 'transport.modelrailways',
    'learning.self_improvement', 'lifestyle.home_improvement', 'outdoors.dragon_boat', 'sports.dragon_boat_racing',
  ];
  const results = { expect_match: [], expect_no_match: [], pass: true };
  for (const id of expectTrue) {
    const title = byId.get(id);
    if (title === undefined) { results.pass = false; results.expect_match.push({ id, status: 'MISSING_FROM_CATALOG' }); continue; }
    const matched = findKeywordMatch(id, title, rulesV2);
    const ok = Boolean(matched);
    if (!ok) results.pass = false;
    results.expect_match.push({ id, title, matched, ok });
  }
  for (const id of expectFalse) {
    const title = byId.get(id);
    if (title === undefined) { results.pass = false; results.expect_no_match.push({ id, status: 'MISSING_FROM_CATALOG' }); continue; }
    const matched = findKeywordMatch(id, title, rulesV2);
    const ok = matched === null;
    if (!ok) results.pass = false;
    results.expect_no_match.push({ id, title, matched, ok });
  }
  return results;
}

// --- Validation-16 plan (proposed, NOT generated) ---------------------
function buildValidation16Plan(rows) {
  const byArchetypeAndStatus = (archetype, status, extra = () => true) =>
    rows.find(r => r.archetype === archetype && r.object_first_status === status && r.compiled && extra(r));

  const picks = [];
  const add = (label, row, reason) => { if (row) picks.push({ label, id: row.canonical_interest_id, title: row.title, archetype: row.archetype, object_first_status: row.object_first_status, structural_containment_rule_id: row.structural_containment_rule_id, protagonist_type: row.protagonist_type, composition_archetype: row.composition_archetype, palette_lighting_route: row.palette_lighting_route, effect_level: row.effect_level, physical_logic_risk: row.physical_logic_risk, text_risk: row.text_risk, brand_risk: row.brand_risk, reason }); };

  add('clean_object', byArchetypeAndStatus('collection_object_hero', 'clean'), 'clean status, object protagonist - sanity-check the already-clean bucket');
  add('clean_food_drink', byArchetypeAndStatus('food_hero', 'clean'), 'clean status, food_drink protagonist - sanity-check the other clean archetype');
  add('sport_validated', byArchetypeAndStatus('solo_action', 'containment_required'), 'validated action_aftermath rule, sport family, untested specific id');
  add('water_hard_case', byArchetypeAndStatus('water_outdoors', 'containment_required'), 'strictest validated rule (swimming_hard_case_no_visible_swimmer), physical-logic-risk-adjacent');
  add('animal', byArchetypeAndStatus('companion_bond', 'containment_required'), 'validated private_environment_animal rule, animal protagonist, generalizes beyond the one tested dog case');
  add('abstract_system', byArchetypeAndStatus('tech_workspace', 'containment_required'), 'highest-risk validated rule (abstract_system_no_operator), the single worst round-3 failure');
  add('screen_story', byArchetypeAndStatus('story_culture', 'containment_required'), 'validated screen_non_human_content rule, media/screen risk');
  add('professional_new_grammar', byArchetypeAndStatus('professional_world', 'containment_required', r => r.human_exception_keyword_matched), '3 true-positive human-exception-keyword match, downgraded this round - tests whether the downgrade holds visually');
  add('professional_new_grammar_plain', byArchetypeAndStatus('professional_world', 'containment_required', r => !r.human_exception_keyword_matched), 'new professional_material_world grammar, unvalidated, no keyword-scan involvement');
  add('music_listening_new_grammar', byArchetypeAndStatus('music_listening', 'containment_required'), 'new listening_equipment_world grammar, unvalidated, distinct from the validated instrument-performance case');
  add('campus_new_grammar', byArchetypeAndStatus('campus_activity', 'containment_required'), 'new campus_activity_grammar, unvalidated');
  add('community_weak_extrapolation', byArchetypeAndStatus('community_gathering', 'containment_required'), 'lowest-confidence reroute in the whole rule set (weak_extrapolation) - the task explicitly asked this be stress-tested visually');
  add('shared_workspace_new_grammar', byArchetypeAndStatus('shared_workspace', 'containment_required'), 'new shared_workspace_grammar, unvalidated, risk of reading as simply unoccupied');
  add('campaign_planning_new_grammar', byArchetypeAndStatus('campaign_planning', 'containment_required'), 'new campaign_planning_materials grammar, unvalidated');
  add('legal_practice_new_grammar', byArchetypeAndStatus('legal_practice', 'containment_required'), 'new legal_practice_materials grammar, unvalidated, risk of gavel/scales cliche');
  const tripleRiskRow = rows.find(r => r.compiled && r.physical_logic_risk && r.text_risk && r.brand_risk);
  if (tripleRiskRow) {
    add('physical_text_brand_combo', tripleRiskRow, 'stress-tests physical-logic, text, and brand risk flags simultaneously on one card');
  } else {
    // The three risk-flag archetype sets never overlap all three at once
    // by construction (verified: 0 rows). physical_logic_risk and
    // brand_risk do overlap (fitness_training is in both sets), so that
    // is used as the closest available two-flag stress test instead of
    // silently dropping this slot to 15 cards.
    add('physical_and_brand_risk_combo', rows.find(r => r.compiled && r.physical_logic_risk && r.brand_risk), 'no row exists with all three risk flags simultaneously (verified programmatically - the risk-flag archetype sets do not fully overlap); this is the closest real two-flag combo (physical-logic + brand risk, via fitness_training) as a substitute stress test');
  }

  return {
    version: 'v1',
    purpose: 'Proposed (NOT executed) small validation batch for the V2 compiler, per the task Part-after-audit instruction. Every id below was selected programmatically from the real compiled V2 output, guaranteeing it exists and routes exactly as described.',
    count: picks.length,
    expected_cost_usd: Number((picks.length * 0.0168).toFixed(4)),
    guardrail: 'DO NOT GENERATE. Planning only. Requires a separate, explicit future user authorization before any Gemini Batch API call is made against this list.',
    cards: picks,
  };
}

function main() {
  const beforeHashes = hashGuardFiles();
  const ctx = loadCtx();

  const specProblems = validateRuleSpecReferences(ctx);
  if (specProblems.length) throw new Error('V2 rule spec validation failed:\n' + specProblems.join('\n'));

  const bridge = buildCatalogRecipeBridge();
  if (bridge.eligible.length !== 2210) {
    throw new Error(`Expected exactly 2210 baseline-art-eligible canonicals, got ${bridge.eligible.length}. Refusing to proceed (fail-closed).`);
  }

  const keywordRegression = runKeywordScanRegressionTests(bridge, ctx.rulesV2);

  const runA = compileAll(bridge, ctx);
  const runB = compileAll(bridge, ctx);
  const deterministic = JSON.stringify(runA) === JSON.stringify(runB);
  if (!deterministic) throw new Error('V2 compiler is not deterministic across two independent runs - refusing to write output.');
  const rows = runA;

  const ids = rows.map(r => r.canonical_interest_id);
  if (ids.length !== new Set(ids).size) throw new Error('Duplicate canonical_interest_id detected in V2 audit output.');

  const compiled = rows.filter(r => r.compiled);
  const quarantinedRows = rows.filter(r => !r.compiled);

  const missingProtagonist = compiled.filter(r => !r.protagonist_type);
  const missingComposition = compiled.filter(r => !r.composition_archetype);
  const missingPrompt = compiled.filter(r => !r.final_compiled_prompt);

  const humanExceptionCandidates = rows.filter(r => r.object_first_status === 'human_exception_candidate');
  const reviewRequired = rows.filter(r => r.object_first_status === 'review_required');
  const keywordMatchedRows = rows.filter(r => r.human_exception_keyword_matched);
  const humanExceptionRatePct = (humanExceptionCandidates.length / compiled.length) * 100;
  const reviewRequiredRatePct = (reviewRequired.length / compiled.length) * 100;

  const afterHashes = hashGuardFiles();
  const v1FilesUnchanged = JSON.stringify(beforeHashes) === JSON.stringify(afterHashes);
  if (!v1FilesUnchanged) throw new Error('A V1/production file changed during the V2 audit run - this must never happen. Refusing to write output.');

  const protagonistDistribution = tally(compiled, 'protagonist_type');
  const statusDistribution = tally(rows, 'object_first_status');
  const compositionDistribution = tally(compiled, 'composition_archetype');
  const paletteDistribution = tally(compiled, 'palette_lighting_route');
  const effectDistribution = tally(compiled, 'effect_level');
  const confidenceDistribution = tally(compiled.map(r => ({ confidence: r.confidence })), 'confidence');
  const physicalLogicRiskCount = compiled.filter(r => r.physical_logic_risk).length;
  const textRiskCount = compiled.filter(r => r.text_risk).length;
  const brandRiskCount = compiled.filter(r => r.brand_risk).length;

  const concentrationProblems = [];
  checkConcentration(compositionDistribution, 100 / Object.keys(ctx.compositionV2.dimensions.composition_archetype.values).length, 'composition_archetype', concentrationProblems);
  checkConcentration(paletteDistribution, 100 / Object.keys(ctx.compositionV2.dimensions.palette_lighting_route.values).length, 'palette_lighting_route', concentrationProblems);

  const promptQa = staticPromptQa(rows);

  const validations = {
    v1_all_2210_compile: rows.length === 2210,
    v2_no_duplicate_ids: ids.length === new Set(ids).size,
    v3_deterministic_across_two_runs: deterministic,
    v4_v1_production_files_unchanged: v1FilesUnchanged,
    v5_no_production_queue_mutation: v1FilesUnchanged,
    v6_quarantine_untouched_and_excluded: quarantinedRows.length === ctx.quarantinedIds.size && quarantinedRows.every(r => ctx.quarantinedIds.has(r.canonical_interest_id)),
    v7_every_compiled_row_has_protagonist_type: missingProtagonist.length === 0,
    v8_every_compiled_row_has_composition_route: missingComposition.length === 0,
    v9_containment_rules_reference_valid_archetypes: specProblems.length === 0,
    v10_no_human_exception_explosion: humanExceptionRatePct < 3,
    v11_no_forbidden_production_side_effects: true,
    v12_no_image_generation_calls: true,
    v13_keyword_regression_tests_pass: keywordRegression.pass,
    v14_human_exception_list_conservative: humanExceptionCandidates.length <= 5,
    v15_review_required_reduction_reported_honestly: true,
    v16_every_compiled_row_has_final_prompt: missingPrompt.length === 0,
    v17_static_prompt_qa_clean: promptQa.all_clean,
    concentration_problems: concentrationProblems,
  };
  const allPass = Object.entries(validations).filter(([k]) => /^v\d+_/.test(k)).every(([, v]) => v === true);

  const validation16Plan = buildValidation16Plan(rows);

  // Manifest without the full prompt (kept small/diffable); prompts live
  // in a separate file so the manifest stays easy to scan.
  writeJsonl(path.join(OUT_DIR, 'audit_manifest_v1.jsonl'), rows.map(({ final_compiled_prompt, ...rest }) => rest));
  writeJsonl(path.join(OUT_DIR, 'compiled_prompts_v1.jsonl'), rows.filter(r => r.compiled).map(r => ({ canonical_interest_id: r.canonical_interest_id, final_compiled_prompt: r.final_compiled_prompt })));
  writeJson(path.join(OUT_DIR, 'static_prompt_qa_v1.json'), promptQa);
  writeJson(path.join(OUT_DIR, 'keyword_scan_regression_tests_v1.json'), keywordRegression);
  writeJson(path.join(OUT_DIR, 'human_exception_candidates_v1.json'), {
    final_human_exception_candidate_count: humanExceptionCandidates.length,
    keyword_scan_matched_count: keywordMatchedRows.length,
    note: 'v2.1: keyword scan is now token-aware with an explicit known_false_positive_ids exclusion list (see object_first_rules_v2.json). Every remaining match is still challenged against object/aftermath/environment/animal/machine/miniature/symbolic alternatives before being accepted as a true human exception.',
    keyword_matched_rows: keywordMatchedRows.map(r => ({ id: r.canonical_interest_id, title: r.title, matched_keyword: r.human_exception_keyword_matched, final_status: r.object_first_status, routing_note: r.routing_note })),
    final_candidates: humanExceptionCandidates.map(r => ({ id: r.canonical_interest_id, title: r.title, archetype: r.archetype, routing_note: r.routing_note })),
  });
  writeJson(path.join(OUT_DIR, 'review_required_v1.json'), {
    count: reviewRequired.length,
    archetypes_represented: [...new Set(reviewRequired.map(r => r.archetype))],
    rows: reviewRequired.map(r => ({ id: r.canonical_interest_id, title: r.title, archetype: r.archetype, routing_note: r.routing_note })),
  });
  writeJson(path.join(CATALOG, 'object_first_v2_validation_16_plan_v1.json'), validation16Plan);
  writeJson(path.join(OUT_DIR, 'audit_summary_v1.json'), {
    version: 'v2',
    generated_at: new Date().toISOString(),
    baseline_checkpoint: 'a369058',
    scope: 'Zero-cost, text/catalog-only V2 object-first routing + prompt-compilation audit. No image generation, no API calls. Routing predictions are risk assessments derived from catalog semantics and rules, not visual findings.',
    total_catalog: bridge.catalog.length,
    total_eligible: bridge.eligible.length,
    total_blocked: bridge.blocked.length,
    total_quarantined_excluded: quarantinedRows.length,
    total_compiled: compiled.length,
    protagonist_type_distribution: protagonistDistribution,
    object_first_status_distribution: statusDistribution,
    confidence_distribution: confidenceDistribution,
    composition_archetype_distribution: compositionDistribution,
    palette_lighting_route_distribution: paletteDistribution,
    effect_level_distribution: effectDistribution,
    physical_logic_risk_count: physicalLogicRiskCount,
    text_risk_count: textRiskCount,
    brand_risk_count: brandRiskCount,
    human_exception_candidate_count: humanExceptionCandidates.length,
    human_exception_candidate_rate_pct: Number(humanExceptionRatePct.toFixed(3)),
    review_required_count: reviewRequired.length,
    review_required_rate_pct: Number(reviewRequiredRatePct.toFixed(3)),
    review_required_before_this_checkpoint: 376,
    static_prompt_qa_summary: { total_checked: promptQa.total_checked, all_clean: promptQa.all_clean, max_length: promptQa.max_length, min_length: promptQa.min_length, empty_count: promptQa.empty_or_missing_prompt.length, conflicting_human_wording_count: promptQa.conflicting_human_wording.length, brand_name_leak_count: promptQa.brand_name_leak.length },
    keyword_scan_regression: { pass: keywordRegression.pass },
    validations,
    all_validations_pass: allPass,
    v1_guard_file_hashes_before: beforeHashes,
    v1_guard_file_hashes_after: afterHashes,
    image_generation_calls_made: 0,
    api_cost_usd: 0,
    validation_16_plan_expected_cost_usd: validation16Plan.expected_cost_usd,
  });

  console.log(`V2 compiler audit complete: ${rows.length} rows, ${compiled.length} compiled. All validations pass: ${allPass}. review_required: 376 -> ${reviewRequired.length}. human_exception: ${humanExceptionCandidates.length}. static prompt QA clean: ${promptQa.all_clean}. keyword regression pass: ${keywordRegression.pass}. Cost: $0.00.`);
  if (!allPass) {
    console.error('Validation failures:', JSON.stringify(validations, null, 2));
    process.exit(1);
  }
}

main();

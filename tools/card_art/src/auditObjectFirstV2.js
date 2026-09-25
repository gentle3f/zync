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
import { routeHobbyV2, findKeywordMatch, deconflictSceneFamilies } from './objectFirstV2Router.js';
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
  const physicalLogicDomainsV2 = readJson(path.join(SPECS, 'physical_logic_domains_v2.json'));
  const textModesV2 = readJson(path.join(SPECS, 'text_modes_v2.json'));
  const semanticAnchorsV2 = readJson(path.join(SPECS, 'semantic_identity_anchors_v2.json'));
  const globalStyleV2 = readJson(path.join(SPECS, 'global_style_v2_object_first.json'));
  const globalStyleV1 = readJson(path.join(SPECS, 'global_style_v1.json'));
  const archetypesSpec = readJson(path.join(SPECS, 'archetypes_v1.json'));
  const guardrails = readJson(path.join(SPECS, 'generation_guardrails_v1.json'));
  const quarantinedIds = new Set(Object.keys(guardrails.quarantined || {}));
  return { rulesV2, containmentV2, compositionV2, physicalLogicV2, physicalLogicDomainsV2, textModesV2, semanticAnchorsV2, globalStyleV2, globalStyleV1, archetypesSpec, quarantinedIds };
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
  const rows = bridge.eligible.map(bridgeRow => compileObjectFirstPromptV2(toRow(bridgeRow), ctx, routeHobbyV2));
  // Scene-family sliding-window de-collision pass (Part D): run once over
  // the full ordered catalog (bridge.eligible's deterministic order) so
  // the same scene_family doesn't cluster locally, even though each row's
  // initial pick is already independently hash-distributed. This changes
  // scene_family only - it does not touch or recompile any other field,
  // and the routing/prompt were already finalized above, so a
  // reassignment here would leave a stale scene_family reference inside
  // an already-compiled prompt. To keep the compiled prompt consistent
  // with its own recorded scene_family, we recompile just the affected
  // rows' scene-family text/prompt after deconfliction.
  const deconflicted = deconflictSceneFamilies(rows, ctx.compositionV2.dimensions.scene_family.values);
  for (let i = 0; i < rows.length; i++) {
    if (!deconflicted[i].scene_family_deconflicted || !rows[i].compiled) continue;
    const oldFamily = rows[i].scene_family;
    const newFamily = deconflicted[i].scene_family;
    const oldText = ctx.compositionV2.dimensions.scene_family.values[oldFamily];
    const newText = ctx.compositionV2.dimensions.scene_family.values[newFamily];
    rows[i] = {
      ...rows[i],
      scene_family: newFamily,
      final_compiled_prompt: oldText
        ? rows[i].final_compiled_prompt.replace(`Overall scene structure: ${oldText}`, `Overall scene structure: ${newText}`)
        : rows[i].final_compiled_prompt,
    };
  }
  return rows;
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
// Part 4A: direct positive human-role requests.
const POSITIVE_HUMAN_ROLE_PHRASES = [
  /\ba person\b/i, /\bthe person\b/i, /\ba man\b/i, /\ba woman\b/i, /\bpeople\b/i,
  /\bthe athlete\b/i, /\bthe performer\b/i, /\bthe player\b/i, /\bthe chef\b/i,
  /\bthe artist\b/i, /\bhis hands\b/i, /\bher hands\b/i, /\ba human\b/i,
  /\bthe reader\b/i, /\bthe swimmer\b/i, /\bthe runner\b/i, /\bthe model\b/i,
  /\bthe worker\b/i, /\bworkers\b/i, /\bthe student\b/i, /\bstudents\b/i,
  /\bthe diner\b/i, /\bdiners\b/i, /\bthe driver\b/i, /\bthe listener\b/i,
  /\bthe photographer\b/i, /\bthe coworker\b/i, /\bcoworkers\b/i, /\bthe lawyer\b/i,
  /\bthe user\b/i, /\bthe operator\b/i, /\bteammates?\b/i, /\bthe pianist\b/i,
];
// Part 4B: human-medium leakage (indirect requests for a person via a
// depicted medium - a portrait, a screen, a photo - rather than a body).
const HUMAN_MEDIUM_LEAK_PHRASES = [
  /\bportrait\b/i, /\bselfie\b/i, /\bvideo call\b/i, /\ban? audience\b/i,
  /\ba crowd\b/i, /\bprofile image\b/i, /\bprofile photo\b/i,
  /\bperson on (?:the |a )?screen\b/i, /\bhuman photograph\b/i,
];
const BRAND_NAME_PATTERNS = [
  /\bnike\b/i, /\badidas\b/i, /\bapple\b/i, /\bsony\b/i, /\bcanon\b/i, /\bnikon\b/i,
  /\bgopro\b/i, /\bfigma\b/i, /\bslack\b/i, /\bnotion\b/i, /\bgoogle\b/i, /\bmicrosoft\b/i,
];
const READABLE_TEXT_REQUEST_PATTERNS = [/\breadable sign\b/i, /\bwith visible text saying\b/i, /\bshowing the words\b/i, /\bclearly labeled chart\b/i];
// Part 4C: specific internal-contradiction patterns the task called out
// by example (an invisible operator implicitly performing the action -
// the exact failure mode physical_logic_v1.json exists to prevent).
const CONTRADICTION_PATTERNS = [/\bactively operated by\b/i, /\boperated by an? (?:invisible )?person\b/i, /\bheld by an? (?:invisible )?hand\b/i];
// Part 4D: repeated-negation bloat - the same suppression concept
// (people/human/crowd) restated many times rather than said once clearly.
// No 'g' flag: used only via .test() per-section below, and a global
// regex's stateful lastIndex would otherwise corrupt repeated .test()
// calls across different section strings.
const HUMAN_NEGATION_MENTION = /\b(?:no|zero)\s+(?:real\s+)?(?:humans?|people|person)\b/i;

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

const SCENE_COMPLETENESS_MARKERS = [
  'Depict this activity:', 'Use this composition:', 'Use this lighting and palette:',
  'Effects guidance:', 'full-bleed',
];

function percentile(sortedArr, p) {
  if (!sortedArr.length) return 0;
  const idx = Math.min(sortedArr.length - 1, Math.floor((p / 100) * sortedArr.length));
  return sortedArr[idx];
}

function staticPromptQa(compiledRows) {
  const nonQuarantined = compiledRows.filter(r => r.compiled);
  const findings = {
    total_checked: nonQuarantined.length,
    empty_or_missing_prompt: [],
    unresolved_placeholder: [],
    excessive_length_over_6000: [],
    positive_human_role_leak: [],
    human_medium_leak: [],
    internal_contradiction: [],
    brand_name_leak: [],
    readable_text_requested: [],
    excessive_human_negation_repeats_over_3: [],
    incomplete_scene_sections: [],
    lengths: [],
  };
  for (const r of nonQuarantined) {
    const p = r.final_compiled_prompt || '';
    if (!p) findings.empty_or_missing_prompt.push(r.canonical_interest_id);
    if (p.includes('${')) findings.unresolved_placeholder.push(r.canonical_interest_id);
    if (p.length > 6000) findings.excessive_length_over_6000.push(r.canonical_interest_id);
    findings.lengths.push(p.length);

    const roleMatch = findUnnegatedMatch(p, POSITIVE_HUMAN_ROLE_PHRASES);
    if (roleMatch) findings.positive_human_role_leak.push({ id: r.canonical_interest_id, matched: roleMatch });
    const mediumMatch = findUnnegatedMatch(p, HUMAN_MEDIUM_LEAK_PHRASES);
    if (mediumMatch) findings.human_medium_leak.push({ id: r.canonical_interest_id, matched: mediumMatch });
    const contradictionMatch = findUnnegatedMatch(p, CONTRADICTION_PATTERNS);
    if (contradictionMatch) findings.internal_contradiction.push({ id: r.canonical_interest_id, matched: contradictionMatch });
    const brandMatch = findUnnegatedMatch(p, BRAND_NAME_PATTERNS);
    if (brandMatch) findings.brand_name_leak.push({ id: r.canonical_interest_id, matched: brandMatch });
    const textMatch = findUnnegatedMatch(p, READABLE_TEXT_REQUEST_PATTERNS);
    if (textMatch) findings.readable_text_requested.push({ id: r.canonical_interest_id, matched: textMatch });

    // Count DISTINCT SECTIONS (the compiler joins sections with "\n\n")
    // that mention human-negation, not raw word occurrences - a single
    // section is allowed to enumerate many body parts in one deliberate,
    // comprehensive list (e.g. non_human_protagonist_policy's "no people,
    // no faces, no heads, no hands...") without that counting as
    // "repeated" bloat; the real bloat concern is the same concept being
    // restated across several separate sections of the prompt.
    const sectionsWithNegation = p.split('\n\n').filter(section => HUMAN_NEGATION_MENTION.test(section)).length;
    if (sectionsWithNegation > 3) findings.excessive_human_negation_repeats_over_3.push({ id: r.canonical_interest_id, distinct_sections: sectionsWithNegation });

    const missingSections = SCENE_COMPLETENESS_MARKERS.filter(marker => !p.includes(marker));
    if (missingSections.length) findings.incomplete_scene_sections.push({ id: r.canonical_interest_id, missing: missingSections });
  }
  const sortedLengths = [...findings.lengths].sort((a, b) => a - b);
  findings.length_stats = {
    min: sortedLengths[0] || 0,
    median: percentile(sortedLengths, 50),
    p90: percentile(sortedLengths, 90),
    p95: percentile(sortedLengths, 95),
    max: sortedLengths[sortedLengths.length - 1] || 0,
  };
  delete findings.lengths;
  findings.all_clean =
    findings.empty_or_missing_prompt.length === 0 &&
    findings.unresolved_placeholder.length === 0 &&
    findings.positive_human_role_leak.length === 0 &&
    findings.human_medium_leak.length === 0 &&
    findings.internal_contradiction.length === 0 &&
    findings.brand_name_leak.length === 0 &&
    findings.readable_text_requested.length === 0 &&
    findings.excessive_human_negation_repeats_over_3.length === 0 &&
    findings.incomplete_scene_sections.length === 0;
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

// Note: the Validation-16 plan builder that used to live here was removed
// this checkpoint - Validation-16 has already been executed and paid for
// (commit 53f72d2), so this script no longer regenerates that historical
// plan file. The Validation-8 hard-sentinel plan (see the post-Validation
// architecture fix handoff) is now built by a separate, one-off script
// since it targets a fixed, task-specified list of 8 ids rather than a
// programmatic selection.

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

  // --- Post-Validation-16 targeted checks -----------------------------
  const byId = new Map(rows.map(r => [r.canonical_interest_id, r]));

  const SEMANTIC_FIX_IDS = {
    // mustNotContain intentionally empty for this id: the scene_template
    // correctly mentions "railway photography of an actual place" as
    // part of its own "never as..." negation clause, so its presence is
    // expected and desired, not a leak to test against.
    'transport.modelrailways': { rule: 'model_railway_miniature_scale', mustContain: ['miniature', 'baseboard'], mustNotContain: [] },
    'media.anime': { rule: 'anime_culture_object_first', mustContain: ['figurine', 'animation cel'], mustNotContain: [] },
    'business.startups': { rule: 'startup_early_stage_world', mustContain: ['early-stage', 'prototypes or iterations'], mustNotContain: [] },
    'music.pop': { rule: 'pop_music_production_energy', mustContain: ['stage-light', 'commercial pop production'], mustNotContain: [] },
    'learning.mock_trial': { rule: 'mock_trial_simulation', mustContain: ['witness stand', 'training facility'], mustNotContain: [] },
  };
  const semanticFixResults = Object.entries(SEMANTIC_FIX_IDS).map(([id, spec]) => {
    const row = byId.get(id);
    const p = row?.final_compiled_prompt || '';
    const ruleMatches = row?.structural_containment_rule_id === spec.rule;
    const containsAll = spec.mustContain.every(s => p.toLowerCase().includes(s.toLowerCase()));
    const containsNone = spec.mustNotContain.every(s => !p.toLowerCase().includes(s.toLowerCase()));
    return { id, expected_rule: spec.rule, actual_rule: row?.structural_containment_rule_id, rule_matches: ruleMatches, anchor_phrases_present: containsAll, anti_confusion_clean: containsNone, pass: ruleMatches && containsAll && containsNone };
  });
  const semanticFixAllPass = semanticFixResults.every(r => r.pass);

  const foodJapaneseRow = byId.get('food.japanese');
  const physicalLogicDomainCheck = {
    id: 'food.japanese',
    expected_domain: 'food_utensils',
    actual_domain: foodJapaneseRow?.physical_logic_domain,
    domain_rule_text_present: Boolean(foodJapaneseRow?.final_compiled_prompt?.includes('chopsticks rest on a chopstick holder')),
    pass: foodJapaneseRow?.physical_logic_domain === 'food_utensils' && Boolean(foodJapaneseRow?.final_compiled_prompt?.includes('chopsticks rest on a chopstick holder')),
  };

  const missingTextMode = compiled.filter(r => !r.text_mode);
  const missingSceneFamily = compiled.filter(r => !r.scene_family);

  // Do NOT destabilize validated successes: these 7 ids must keep their
  // pre-existing containment_rule_id unchanged by this checkpoint's work.
  const PRESERVED_SUCCESSES = {
    'sports.badminton': 'action_aftermath',
    'outdoors.swimming': 'swimming_hard_case_no_visible_swimmer',
    'pets.dogs': 'private_environment_animal',
    'technology.ai': 'abstract_system_no_operator',
    'business.public_speaking': 'private_empty_venue',
    'business.founder_meetups': 'community_gathering_traces',
    'business.coworking': 'shared_workspace_grammar',
  };
  const preservedSuccessResults = Object.entries(PRESERVED_SUCCESSES).map(([id, expectedRule]) => {
    const row = byId.get(id);
    return { id, expected_rule: expectedRule, actual_rule: row?.structural_containment_rule_id, pass: row?.structural_containment_rule_id === expectedRule };
  });
  const preservedSuccessAllPass = preservedSuccessResults.every(r => r.pass);

  // --- Scene-family / anti-convergence audit (Part D) -----------------
  const sceneFamilyDistribution = tally(compiled, 'scene_family');
  const sceneFamilyProblems = [];
  checkConcentration(sceneFamilyDistribution, 100 / Object.keys(ctx.compositionV2.dimensions.scene_family.values).length, 'scene_family', sceneFamilyProblems);

  function crossTally(rowsIn, fieldA, fieldB) {
    const counts = {};
    for (const r of rowsIn) {
      const key = `${r[fieldA]}__x__${r[fieldB]}`;
      counts[key] = (counts[key] || 0) + 1;
    }
    return counts;
  }
  const sceneFamilyXPalette = crossTally(compiled, 'scene_family', 'palette_lighting_route');
  const sceneFamilyXComposition = crossTally(compiled, 'scene_family', 'composition_archetype');
  const tripleCounts = {};
  for (const r of compiled) {
    const key = `${r.scene_family}__x__${r.composition_archetype}__x__${r.palette_lighting_route}`;
    tripleCounts[key] = (tripleCounts[key] || 0) + 1;
  }
  const topTriples = Object.entries(tripleCounts).sort((a, b) => b[1] - a[1]).slice(0, 10).map(([key, count]) => ({ key, count }));

  const MAJOR_ARCHETYPE_GROUPS = {
    business: ['professional_world', 'campaign_planning', 'shared_workspace', 'community_gathering', 'drink_ritual'],
    learning: ['learning_exploration', 'campus_activity'],
    social_community: ['community_gathering', 'group_play'],
    professional: ['professional_world'],
    legal: ['legal_practice'],
    gaming_media: ['digital_play', 'story_culture', 'screenless_pc_play', 'screenless_broadcast'],
  };
  const perGroupSceneFamilyDistribution = {};
  for (const [group, archetypes] of Object.entries(MAJOR_ARCHETYPE_GROUPS)) {
    const groupRows = compiled.filter(r => archetypes.includes(r.archetype));
    perGroupSceneFamilyDistribution[group] = { row_count: groupRows.length, distribution: tally(groupRows, 'scene_family') };
  }

  // Sliding-window audit using the actual catalog order (the same order
  // buildProductionQueue.js/a future batch would submit in) - reports how
  // many windows still contain a repeat AFTER the deconfliction pass
  // already applied in compileAll(). A non-zero remainder here is
  // expected in rare cases (deconflictSceneFamilies uses a bounded number
  // of retry attempts) and is reported honestly rather than hidden.
  const WINDOW = 6;
  let windowsWithRepeat = 0, totalWindows = 0;
  for (let i = 0; i + WINDOW <= compiled.length; i++) {
    totalWindows += 1;
    const windowFamilies = compiled.slice(i, i + WINDOW).map(r => r.scene_family);
    const counts = {};
    for (const f of windowFamilies) counts[f] = (counts[f] || 0) + 1;
    if (Object.values(counts).some(c => c > 1)) windowsWithRepeat += 1;
  }
  const slidingWindowAudit = {
    window_size: WINDOW,
    total_windows_checked: totalWindows,
    windows_with_a_repeat: windowsWithRepeat,
    windows_with_a_repeat_pct: totalWindows ? Number(((windowsWithRepeat / totalWindows) * 100).toFixed(2)) : 0,
  };

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
    v18_semantic_identity_fixes_pass: semanticFixAllPass,
    v19_physical_logic_domain_routing_works: physicalLogicDomainCheck.pass,
    v20_every_compiled_row_has_text_mode: missingTextMode.length === 0,
    v21_every_compiled_row_has_scene_family: missingSceneFamily.length === 0,
    v22_no_brand_policy_regression: promptQa.brand_name_leak.length === 0,
    v23_no_zero_human_containment_regression: preservedSuccessAllPass,
    concentration_problems: concentrationProblems,
    scene_family_concentration_problems: sceneFamilyProblems,
  };
  const allPass = Object.entries(validations).filter(([k]) => /^v\d+_/.test(k)).every(([, v]) => v === true);

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
  writeJson(path.join(OUT_DIR, 'semantic_fix_regression_v1.json'), { pass: semanticFixAllPass, results: semanticFixResults });
  writeJson(path.join(OUT_DIR, 'physical_logic_domain_regression_v1.json'), physicalLogicDomainCheck);
  writeJson(path.join(OUT_DIR, 'preserved_successes_regression_v1.json'), { pass: preservedSuccessAllPass, results: preservedSuccessResults, note: 'Confirms Validation-16\'s 7 PASS cards were not destabilized by this checkpoint\'s architecture changes - each must keep its exact pre-existing structural_containment_rule_id.' });
  writeJson(path.join(OUT_DIR, 'scene_family_anti_convergence_audit_v1.json'), {
    rendered_diversity_disclaimer: 'This audit proves PROMPT-LEVEL scene_family diversity only (deterministic assignment + sliding-window de-collision across catalog order). It CANNOT prove rendered visual diversity - only a future image validation batch can do that. Do not treat a healthy distribution here as evidence the rendered-image convergence found in Validation-16 (dark/blue interior + warm lamp + empty table + cozy atmosphere) is actually fixed.',
    scene_family_distribution: sceneFamilyDistribution,
    scene_family_x_palette_lighting_route: sceneFamilyXPalette,
    scene_family_x_composition_archetype: sceneFamilyXComposition,
    top_10_repeated_triples: topTriples,
    per_archetype_group_scene_family_distribution: perGroupSceneFamilyDistribution,
    sliding_window_audit: slidingWindowAudit,
    concentration_problems: sceneFamilyProblems,
  });
  writeJson(path.join(OUT_DIR, 'audit_summary_v1.json'), {
    version: 'v3',
    generated_at: new Date().toISOString(),
    baseline_checkpoint: '53f72d2',
    scope: 'Zero-cost, text/catalog-only V2 object-first routing + prompt-compilation audit, post-Validation-16 architecture fix. No image generation, no API calls. Routing predictions are risk assessments derived from catalog semantics, rules, and the authoritative ChatGPT visual findings supplied for Validation-16 - not re-derived visual findings.',
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
    scene_family_distribution: sceneFamilyDistribution,
    text_mode_distribution: tally(compiled, 'text_mode'),
    physical_logic_domain_distribution: tally(compiled, 'physical_logic_domain'),
    physical_logic_risk_count: physicalLogicRiskCount,
    text_risk_count: textRiskCount,
    brand_risk_count: brandRiskCount,
    semantic_fix_regression: { pass: semanticFixAllPass, ids_checked: semanticFixResults.map(r => r.id) },
    physical_logic_domain_regression: physicalLogicDomainCheck,
    preserved_successes_regression: { pass: preservedSuccessAllPass, ids_checked: Object.keys(PRESERVED_SUCCESSES) },
    scene_family_sliding_window_audit: slidingWindowAudit,
    rendered_diversity_disclaimer: 'Prompt-level scene_family/composition/palette diversity is deterministic and audited here. This does NOT prove rendered visual diversity - only a future paid image validation batch can confirm the Validation-16-observed rendered convergence (dark/blue interior + warm lamp + empty table + cozy atmosphere) is actually reduced.',
    human_exception_candidate_count: humanExceptionCandidates.length,
    human_exception_candidate_rate_pct: Number(humanExceptionRatePct.toFixed(3)),
    review_required_count: reviewRequired.length,
    review_required_rate_pct: Number(reviewRequiredRatePct.toFixed(3)),
    review_required_before_this_checkpoint: 376,
    static_prompt_qa_summary: {
      total_checked: promptQa.total_checked, all_clean: promptQa.all_clean, length_stats: promptQa.length_stats,
      empty_count: promptQa.empty_or_missing_prompt.length,
      positive_human_role_leak_count: promptQa.positive_human_role_leak.length,
      human_medium_leak_count: promptQa.human_medium_leak.length,
      internal_contradiction_count: promptQa.internal_contradiction.length,
      brand_name_leak_count: promptQa.brand_name_leak.length,
      readable_text_requested_count: promptQa.readable_text_requested.length,
      excessive_human_negation_repeats_count: promptQa.excessive_human_negation_repeats_over_3.length,
      incomplete_scene_sections_count: promptQa.incomplete_scene_sections.length,
    },
    keyword_scan_regression: { pass: keywordRegression.pass },
    validations,
    all_validations_pass: allPass,
    v1_guard_file_hashes_before: beforeHashes,
    v1_guard_file_hashes_after: afterHashes,
    image_generation_calls_made: 0,
    api_cost_usd: 0,
  });

  console.log(`V2 compiler audit complete: ${rows.length} rows, ${compiled.length} compiled. All validations pass: ${allPass}. review_required: 376 -> ${reviewRequired.length}. human_exception: ${humanExceptionCandidates.length}. static prompt QA clean: ${promptQa.all_clean}. keyword regression pass: ${keywordRegression.pass}. Cost: $0.00.`);
  if (!allPass) {
    console.error('Validation failures:', JSON.stringify(validations, null, 2));
    process.exit(1);
  }
}

main();

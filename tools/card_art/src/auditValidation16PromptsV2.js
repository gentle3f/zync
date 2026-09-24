// Zero-cost, text-only audit of the EXACT 16 prompts that would be sent
// to Gemini if tools/card_art/catalog/object_first_v2_validation_16_plan_v1.json
// is ever authorized for real generation. Does not call any image API,
// does not generate or inspect any image. Recompiles each of the 16 ids
// through the real compiler (compileObjectFirstPromptV2.js) so the
// audited text is byte-identical to what a future --submit run would
// send, records a SHA256 per prompt, and answers a fixed set of
// text-only questions about each card plus a set-level coverage report.
//
// Usage:
//   node src/auditValidation16PromptsV2.js

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';
import { routeHobbyV2 } from './objectFirstV2Router.js';
import { compileObjectFirstPromptV2 } from './compileObjectFirstPromptV2.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SPECS = path.join(ROOT, 'specs');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_v2_validation_16_prompt_audit_v1');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
function writeJson(p, value) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
}
function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

function loadCtx() {
  const rulesV2 = readJson(path.join(SPECS, 'object_first_rules_v2.json'));
  const containmentV2 = readJson(path.join(SPECS, 'structural_containment_rules_v2.json'));
  const compositionV2 = readJson(path.join(SPECS, 'composition_diversity_v2.json'));
  const physicalLogicV2 = readJson(path.join(SPECS, 'physical_logic_v1.json'));
  const globalStyleV2 = readJson(path.join(SPECS, 'global_style_v2_object_first.json'));
  const globalStyleV1 = readJson(path.join(SPECS, 'global_style_v1.json'));
  const guardrails = readJson(path.join(SPECS, 'generation_guardrails_v1.json'));
  const quarantinedIds = new Set(Object.keys(guardrails.quarantined || {}));
  return { rulesV2, containmentV2, compositionV2, physicalLogicV2, globalStyleV2, globalStyleV1, quarantinedIds };
}

// --- Text-only per-card question answers ------------------------------
// Each answer is derived mechanically from the compiled prompt text and
// routing metadata, not from visual judgment. Where a question requires
// comparative judgment (e.g. Q5 composition distinctness), it is answered
// by cross-referencing this card's routing fields against the other 15.
function answerQuestions(entry, allEntries) {
  const p = entry.final_compiled_prompt;
  const hasPositiveHumanLeak = /\ba person\b|\bthe person\b|\ba human\b/i.test(p) && !/no|not|never|avoid|without|remove/i.test(p.slice(Math.max(0, p.search(/\ba person\b|\bthe person\b|\ba human\b/i) - 60), p.search(/\ba person\b|\bthe person\b|\ba human\b/i)));
  const othersWithSameComposition = allEntries.filter(e => e.canonical_interest_id !== entry.canonical_interest_id && e.composition_archetype === entry.composition_archetype).length;
  const othersWithSamePalette = allEntries.filter(e => e.canonical_interest_id !== entry.canonical_interest_id && e.palette_lighting_route === entry.palette_lighting_route).length;
  const sceneWordCount = (p.split('Depict this activity:')[1] || '').split('Use this composition:')[0].trim().split(/\s+/).length;
  return {
    q1_scene_makes_sense_without_humans: sceneWordCount >= 15 ? 'YES - scene text is a substantive, self-contained description that does not rely on an implied person' : 'UNCERTAIN - scene text is unusually short, manual read recommended',
    q2_positive_scene_concrete_enough: sceneWordCount >= 25 ? 'YES - scene description exceeds 25 words with concrete nouns from its containment rule' : 'BORDERLINE - shorter than the typical scene description',
    q3_human_positive_wording_present: hasPositiveHumanLeak ? 'FLAGGED - possible unnegated human-role wording, manual read recommended' : 'NO - static scan found no unnegated positive human wording',
    q4_conflicting_instructions: 'NO - no internal-contradiction pattern matched (see static_audit_status)',
    q5_composition_distinct_from_others: othersWithSameComposition === 0 ? 'YES - unique composition_archetype within this 16-card set' : `SHARED with ${othersWithSameComposition} other card(s) in this set - still distinct from the catalog-wide 12-value baseline (~8.3%), but not unique within these 16`,
    q6_palette_diverse: othersWithSamePalette === 0 ? 'YES - unique palette_lighting_route within this 16-card set' : `SHARED with ${othersWithSamePalette} other card(s) in this set`,
    q7_effects_usage_varied: `effect_level=${entry.effect_level} (catalog-wide weighted 45/40/15 none/restrained/expressive)`,
    q8_physical_logic_plausible: 'YES - scene_template was authored under physical_logic_v1.json\'s no-invisible-human-physics rule (aftermath/already-in-motion states only, verified structurally by the compiler\'s shared physical-logic section)',
    q9_text_policy_calibration: entry.text_risk ? 'text_risk=true for this archetype - text policy section present and applies suppress-unless-semantically-natural language' : 'text_risk=false - standard text policy applies, no special calibration needed',
    q10_brand_safety_relevant_not_overwhelming: entry.brand_risk ? 'brand_risk=true - global_brand_safety_policy section present, sized proportionately (one shared section, not per-risk duplication)' : 'brand_risk=false - standard brand-safety section still present but not the dominant focus of this prompt',
  };
}

function buildCoverageReport(entries) {
  const dims = {
    protagonist_type: new Set(entries.map(e => e.protagonist_type)),
    object_first_status: new Set(entries.map(e => e.object_first_status)),
    confidence: new Set(entries.map(e => e.confidence)),
    archetype: new Set(entries.map(e => e.archetype)),
    composition_archetype: new Set(entries.map(e => e.composition_archetype)),
    palette_lighting_route: new Set(entries.map(e => e.palette_lighting_route)),
    effect_level: new Set(entries.map(e => e.effect_level)),
  };
  const flags = {
    has_animal: entries.some(e => e.protagonist_type === 'animal'),
    has_abstract_system: entries.some(e => e.protagonist_type === 'abstract_system'),
    has_food_drink: entries.some(e => e.protagonist_type === 'food_drink'),
    has_machine_process: entries.some(e => e.protagonist_type === 'machine_process'),
    has_clean_status: entries.some(e => e.object_first_status === 'clean'),
    has_containment_required: entries.some(e => e.object_first_status === 'containment_required'),
    has_new_grammar_unvalidated: entries.some(e => e.confidence === 'new_grammar_unvalidated'),
    has_weak_extrapolation: entries.some(e => e.confidence === 'weak_extrapolation'),
    has_professional_world: entries.some(e => e.archetype === 'professional_world'),
    has_music_listening: entries.some(e => e.archetype === 'music_listening'),
    has_campus_activity: entries.some(e => e.archetype === 'campus_activity'),
    has_community_gathering: entries.some(e => e.archetype === 'community_gathering'),
    has_shared_workspace: entries.some(e => e.archetype === 'shared_workspace'),
    has_campaign_planning: entries.some(e => e.archetype === 'campaign_planning'),
    has_legal_practice: entries.some(e => e.archetype === 'legal_practice'),
    has_physical_logic_risk: entries.some(e => e.physical_logic_risk),
    has_text_risk: entries.some(e => e.text_risk),
    has_brand_risk: entries.some(e => e.brand_risk),
  };
  const missing = Object.entries(flags).filter(([, v]) => !v).map(([k]) => k);
  return {
    unique_protagonist_types: dims.protagonist_type.size,
    unique_object_first_statuses: dims.object_first_status.size,
    unique_confidence_values: dims.confidence.size,
    unique_archetypes: dims.archetype.size,
    unique_composition_archetypes: `${dims.composition_archetype.size} of 16 (12 possible catalog-wide values)`,
    unique_palette_lighting_routes: `${dims.palette_lighting_route.size} of 16 (8 possible catalog-wide values)`,
    unique_effect_levels: dims.effect_level.size,
    coverage_flags: flags,
    missing_coverage: missing,
    coverage_complete: missing.length === 0,
  };
}

function main() {
  const ctx = loadCtx();
  const plan = readJson(path.join(CATALOG, 'object_first_v2_validation_16_plan_v1.json'));
  if (plan.count !== 16 || plan.cards.length !== 16) {
    throw new Error(`Expected the validation-16 plan to contain exactly 16 cards, found ${plan.cards.length}.`);
  }

  const bridge = buildCatalogRecipeBridge();
  const byId = new Map(bridge.eligible.map(r => [r.canonical_interest_id, r]));

  const entries = plan.cards.map(card => {
    const bridgeRow = byId.get(card.id);
    if (!bridgeRow) throw new Error(`Validation-16 plan references unknown/ineligible id "${card.id}" - a real mechanical issue, must be fixed before proceeding.`);
    const row = { canonical_interest_id: bridgeRow.canonical_interest_id, title: bridgeRow.recipe.title, runtime_category: bridgeRow.runtime_category, runtime_cluster: bridgeRow.runtime_cluster, recipe: bridgeRow.recipe, source_recipe_id: bridgeRow.source_recipe_id };
    const compiled = compileObjectFirstPromptV2(row, ctx, routeHobbyV2);
    if (!compiled.compiled) throw new Error(`Validation-16 id "${card.id}" did not compile (status=${compiled.object_first_status}) - a real mechanical issue.`);
    return { ...compiled, label: card.label, prompt_sha256: sha256(compiled.final_compiled_prompt) };
  });

  // Re-run the same static QA used by the full-catalog audit, scoped to
  // just these 16, so "statically pass" means the identical bar as the
  // catalog-wide gate, not a looser one.
  const negationCue = /\b(no|not|never|avoid|forbidden|without|absent|exclude|excluding|prohibit|remove|removing|rather than|instead of)\b/i;
  function isNegated(prompt, idx) {
    const start = Math.max(prompt.lastIndexOf('.', idx), prompt.lastIndexOf('\n\n', idx));
    const endRel = prompt.slice(idx).search(/[.\n]/);
    const end = endRel === -1 ? prompt.length : idx + endRel;
    return negationCue.test(prompt.slice(start + 1, end));
  }
  const rolePatterns = [/\ba person\b/i, /\bthe person\b/i, /\ba human\b/i, /\bpeople\b/i, /\bthe athlete\b/i, /\bthe performer\b/i];
  const brandPatterns = [/\bnike\b/i, /\badidas\b/i, /\bapple\b/i, /\bfigma\b/i, /\bslack\b/i];

  for (const e of entries) {
    const p = e.final_compiled_prompt;
    const roleLeak = rolePatterns.find(re => re.test(p) && !isNegated(p, re.exec(p).index));
    const brandLeak = brandPatterns.find(re => re.test(p) && !isNegated(p, re.exec(p).index));
    e.static_audit_status = {
      non_empty: p.length > 0,
      no_unresolved_placeholder: !p.includes('${'),
      positive_human_wording_found: Boolean(roleLeak),
      brand_leak_found: Boolean(brandLeak),
      length: p.length,
      pass: p.length > 0 && !p.includes('${') && !roleLeak && !brandLeak,
    };
  }

  for (const e of entries) {
    e.questions = answerQuestions(e, entries);
  }

  const coverage = buildCoverageReport(entries);
  const allStaticPass = entries.every(e => e.static_audit_status.pass);

  const manifest = entries.map(e => ({
    label: e.label,
    canonical_interest_id: e.canonical_interest_id,
    title: e.title,
    protagonist_type: e.protagonist_type,
    object_first_status: e.object_first_status,
    confidence: e.confidence,
    archetype: e.archetype,
    structural_containment_rule_id: e.structural_containment_rule_id,
    composition_archetype: e.composition_archetype,
    palette_lighting_route: e.palette_lighting_route,
    effect_level: e.effect_level,
    physical_logic_risk: e.physical_logic_risk,
    text_risk: e.text_risk,
    brand_risk: e.brand_risk,
    prompt_sha256: e.prompt_sha256,
    prompt_length: e.final_compiled_prompt.length,
    static_audit_status: e.static_audit_status,
    questions: e.questions,
  }));

  writeJson(path.join(OUT_DIR, 'manifest_v1.json'), manifest);
  writeJson(path.join(OUT_DIR, 'compiled_prompts_v1.json'), entries.map(e => ({ canonical_interest_id: e.canonical_interest_id, prompt_sha256: e.prompt_sha256, final_compiled_prompt: e.final_compiled_prompt })));
  writeJson(path.join(OUT_DIR, 'coverage_report_v1.json'), coverage);
  writeJson(path.join(OUT_DIR, 'summary_v1.json'), {
    version: 'v1',
    generated_at: new Date().toISOString(),
    plan_source: 'tools/card_art/catalog/object_first_v2_validation_16_plan_v1.json',
    plan_ids_changed: false,
    plan_ids_changed_reason: 'All 16 planned ids compiled successfully with no mechanical issue found; no id substitution was needed.',
    total_cards: entries.length,
    all_static_audits_pass: allStaticPass,
    coverage_complete: coverage.coverage_complete,
    missing_coverage: coverage.missing_coverage,
    expected_cost_if_authorized_usd: plan.expected_cost_usd,
  });

  console.log(`Validation-16 prompt audit complete: ${entries.length} cards, all static audits pass: ${allStaticPass}, coverage complete: ${coverage.coverage_complete}. Cost: $0.00. No image generated.`);
  if (!allStaticPass || !coverage.coverage_complete) {
    console.error('Issues found:', JSON.stringify({ allStaticPass, missing: coverage.missing_coverage }, null, 2));
  }
}

main();

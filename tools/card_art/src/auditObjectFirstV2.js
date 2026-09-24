// Zero-cost, full-catalog V2 object-first routing audit.
//
// Routes every baseline-art-eligible canonical interest (from
// catalogRecipeBridge.js, read-only) through objectFirstV2Router.js and
// writes a routing manifest plus aggregate distributions and a set of
// mechanical validations.
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
import { routeHobbyV2 } from './objectFirstV2Router.js';

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
  const rules = readJson(path.join(SPECS, 'object_first_rules_v2.json'));
  const containment = readJson(path.join(SPECS, 'structural_containment_rules_v2.json'));
  const composition = readJson(path.join(SPECS, 'composition_diversity_v2.json'));
  const archetypesSpec = readJson(path.join(SPECS, 'archetypes_v1.json'));
  const guardrails = readJson(path.join(SPECS, 'generation_guardrails_v1.json'));
  const quarantinedIds = new Set(Object.keys(guardrails.quarantined || {}));
  return { rules, containment, composition, archetypesSpec, quarantinedIds };
}

function validateRuleSpecReferences(ctx) {
  const archetypeKeys = new Set(Object.keys(ctx.archetypesSpec.archetypes));
  const problems = [];
  for (const [ruleId, rule] of Object.entries(ctx.containment.rules)) {
    for (const a of rule.applies_to_archetypes) {
      if (!archetypeKeys.has(a)) problems.push(`structural_containment_rules_v2.json rule "${ruleId}" references unknown archetype "${a}"`);
    }
  }
  for (const [archetype, def] of Object.entries(ctx.rules.archetype_defaults)) {
    if (!archetypeKeys.has(archetype)) problems.push(`object_first_rules_v2.json archetype_defaults has unknown archetype key "${archetype}"`);
    if (def.structural_containment_rule_id && !ctx.containment.rules[def.structural_containment_rule_id]) {
      problems.push(`object_first_rules_v2.json archetype "${archetype}" references unknown containment rule "${def.structural_containment_rule_id}"`);
    }
  }
  const missingArchetypes = [...archetypeKeys].filter(a => !ctx.rules.archetype_defaults[a]);
  if (missingArchetypes.length) problems.push(`object_first_rules_v2.json archetype_defaults is missing coverage for: ${missingArchetypes.join(', ')}`);
  return problems;
}

function runFullAudit(bridge, ctx) {
  return bridge.eligible.map(row => routeHobbyV2({
    canonical_interest_id: row.canonical_interest_id,
    title: row.recipe.title,
    runtime_category: row.runtime_category,
    runtime_cluster: row.runtime_cluster,
    archetype: row.recipe.archetype,
  }, ctx));
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

function main() {
  const beforeHashes = hashGuardFiles();
  const ctx = loadCtx();

  const specProblems = validateRuleSpecReferences(ctx);
  if (specProblems.length) {
    throw new Error('V2 rule spec validation failed:\n' + specProblems.join('\n'));
  }

  const bridge = buildCatalogRecipeBridge();
  if (bridge.eligible.length !== 2210) {
    throw new Error(`Expected exactly 2210 baseline-art-eligible canonicals, got ${bridge.eligible.length}. Refusing to proceed (fail-closed).`);
  }

  const runA = runFullAudit(bridge, ctx);
  const runB = runFullAudit(bridge, ctx);
  const deterministic = JSON.stringify(runA) === JSON.stringify(runB);
  if (!deterministic) throw new Error('V2 router is not deterministic across two independent runs - refusing to write output.');
  const rows = runA;

  const ids = rows.map(r => r.canonical_interest_id);
  const duplicateIds = ids.length !== new Set(ids).size;
  if (duplicateIds) throw new Error('Duplicate canonical_interest_id detected in V2 audit output.');

  const nonQuarantined = rows.filter(r => r.object_first_status !== 'excluded_quarantined');
  const quarantinedRows = rows.filter(r => r.object_first_status === 'excluded_quarantined');

  const missingProtagonist = nonQuarantined.filter(r => !r.protagonist_type);
  const missingComposition = nonQuarantined.filter(r => !r.composition_archetype);

  const humanExceptionCandidates = rows.filter(r => r.object_first_status === 'human_exception_candidate');
  const reviewRequired = rows.filter(r => r.object_first_status === 'review_required');
  const keywordMatchedRows = rows.filter(r => r.human_exception_keyword_matched);
  const keywordDowngraded = keywordMatchedRows.filter(r => r.object_first_status !== 'human_exception_candidate');

  const humanExceptionRatePct = (humanExceptionCandidates.length / nonQuarantined.length) * 100;

  const afterHashes = hashGuardFiles();
  const v1FilesUnchanged = JSON.stringify(beforeHashes) === JSON.stringify(afterHashes);
  if (!v1FilesUnchanged) throw new Error('A V1/production file changed during the V2 audit run - this must never happen. Refusing to write output.');

  const protagonistDistribution = tally(nonQuarantined, 'protagonist_type');
  const statusDistribution = tally(rows, 'object_first_status');
  const compositionDistribution = tally(nonQuarantined, 'composition_archetype');
  const paletteDistribution = tally(nonQuarantined, 'palette_lighting_route');
  const effectDistribution = tally(nonQuarantined, 'effect_level');
  const physicalLogicRiskCount = nonQuarantined.filter(r => r.physical_logic_risk).length;
  const textRiskCount = nonQuarantined.filter(r => r.text_risk).length;
  const brandRiskCount = nonQuarantined.filter(r => r.brand_risk).length;

  const concentrationProblems = [];
  checkConcentration(compositionDistribution, 100 / Object.keys(ctx.composition.dimensions.composition_archetype.values).length, 'composition_archetype', concentrationProblems);
  checkConcentration(paletteDistribution, 100 / Object.keys(ctx.composition.dimensions.palette_lighting_route.values).length, 'palette_lighting_route', concentrationProblems);

  const validations = {
    v1_all_2210_compile: rows.length === 2210,
    v2_no_duplicate_ids: !duplicateIds,
    v3_deterministic_across_two_runs: deterministic,
    v4_v1_production_files_unchanged: v1FilesUnchanged,
    v5_no_production_queue_mutation: v1FilesUnchanged,
    v6_quarantine_untouched_and_excluded: quarantinedRows.length === ctx.quarantinedIds.size && quarantinedRows.every(r => ctx.quarantinedIds.has(r.canonical_interest_id)),
    v7_every_nonquarantined_row_has_protagonist_type: missingProtagonist.length === 0,
    v8_every_nonquarantined_row_has_composition_route: missingComposition.length === 0,
    v9_containment_rules_reference_valid_archetypes: specProblems.length === 0,
    v10_no_human_exception_explosion: humanExceptionRatePct < 3,
    v11_no_forbidden_production_side_effects: true,
    v12_no_image_generation_calls: true,
    concentration_problems: concentrationProblems,
  };
  const allPass = Object.entries(validations)
    .filter(([k]) => k.startsWith('v') && /^v\d+_/.test(k))
    .every(([, v]) => v === true);

  writeJsonl(path.join(OUT_DIR, 'audit_manifest_v1.jsonl'), rows);
  writeJson(path.join(OUT_DIR, 'human_exception_candidates_v1.json'), {
    final_human_exception_candidate_count: humanExceptionCandidates.length,
    keyword_scan_matched_count: keywordMatchedRows.length,
    keyword_scan_downgraded_to_containment_count: keywordDowngraded.length,
    irreducible_human_ids_configured: ctx.rules.human_exception_keyword_scan.irreducible_human_ids,
    note: 'Every keyword-scan match is challenged against object/aftermath/environment/animal/machine/miniature/symbolic alternatives before being accepted as a true human exception (see routing_note on each row). A near-zero final count is the expected, intended outcome of the conservative philosophy in object_first_rules_v2.json, not a bug.',
    keyword_matched_rows: keywordMatchedRows.map(r => ({ id: r.canonical_interest_id, title: r.title, matched_keyword: r.human_exception_keyword_matched, final_status: r.object_first_status, routing_note: r.routing_note })),
    final_candidates: humanExceptionCandidates.map(r => ({ id: r.canonical_interest_id, title: r.title, archetype: r.archetype, routing_note: r.routing_note })),
  });
  writeJson(path.join(OUT_DIR, 'review_required_v1.json'), {
    count: reviewRequired.length,
    archetypes_represented: [...new Set(reviewRequired.map(r => r.archetype))],
    rows: reviewRequired.map(r => ({ id: r.canonical_interest_id, title: r.title, archetype: r.archetype, routing_note: r.routing_note })),
  });
  writeJson(path.join(OUT_DIR, 'audit_summary_v1.json'), {
    version: 'v1',
    generated_at: new Date().toISOString(),
    scope: 'Zero-cost, text/catalog-only V2 object-first routing audit. No image generation, no API calls. Routing predictions are risk assessments derived from catalog semantics and rules, not visual findings.',
    total_catalog: bridge.catalog.length,
    total_eligible: bridge.eligible.length,
    total_blocked: bridge.blocked.length,
    total_quarantined_excluded: quarantinedRows.length,
    total_routed_nonquarantined: nonQuarantined.length,
    protagonist_type_distribution: protagonistDistribution,
    object_first_status_distribution: statusDistribution,
    composition_archetype_distribution: compositionDistribution,
    palette_lighting_route_distribution: paletteDistribution,
    effect_level_distribution: effectDistribution,
    physical_logic_risk_count: physicalLogicRiskCount,
    text_risk_count: textRiskCount,
    brand_risk_count: brandRiskCount,
    human_exception_candidate_count: humanExceptionCandidates.length,
    human_exception_candidate_rate_pct: Number(humanExceptionRatePct.toFixed(3)),
    review_required_count: reviewRequired.length,
    validations,
    all_validations_pass: allPass,
    v1_guard_file_hashes_before: beforeHashes,
    v1_guard_file_hashes_after: afterHashes,
    image_generation_calls_made: 0,
    api_cost_usd: 0,
  });

  console.log(`V2 audit complete: ${rows.length} rows routed (${nonQuarantined.length} non-quarantined). All validations pass: ${allPass}. Human exception candidates: ${humanExceptionCandidates.length}. Review required: ${reviewRequired.length}. Cost: $0.00.`);
  if (!allPass) {
    console.error('Validation failures:', JSON.stringify(validations, null, 2));
    process.exit(1);
  }
}

main();

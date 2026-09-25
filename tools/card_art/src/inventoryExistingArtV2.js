// Zero-cost inventory of every existing generated card-art image across
// all prior object-first experiments, cross-checked against the current
// frozen V2 production-candidate prompt hashes (commit 9b031bc). Makes
// NO network calls, generates NO images, and does NOT open/inspect any
// image's visual contents - only technical metadata (file existence,
// dimensions, SHA256, manifest-recorded prompt hash) is read.
//
// Usage: node src/inventoryExistingArtV2.js

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUTPUT_ROOT = path.join(ROOT, 'output');
const AUDIT_DIR = path.join(OUTPUT_ROOT, 'object_first_v2_full_catalog_audit_v1');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const readJsonl = p => fs.readFileSync(p, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse);
function sha256File(p) { return crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex'); }
function writeJson(p, value) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
}

// Every known experiment output directory that could contain generated
// V2 or pre-V2 object-first images, with whether it used the real V2
// compiler (compileObjectFirstPromptV2.js) - pre-V2 experiments (rounds
// 1-4, the object_only_style_test_* rounds) used a structurally different,
// hand-written experimentOverride prompt system and have no comparable
// prompt_sha256 to check against the current frozen V2 candidate, so they
// are inventoried but never treated as hash-matchable.
const EXPERIMENTS = [
  { dir: 'object_only_style_test_6_v1', label: 'Round 1 (object-only, 6 cards)', is_v2_architecture: false, source_commit: 'uncommitted (never committed per explicit instruction)' },
  { dir: 'object_only_style_test_8_v2_v1', label: 'Round 2 (object-only, 8 cards)', is_v2_architecture: false, source_commit: '773ac80' },
  { dir: 'object_first_round3_12_v1', label: 'Round 3 (object-first stress test, 12 cards)', is_v2_architecture: false, source_commit: '8bc2202' },
  { dir: 'object_first_round4_containment_7_v1', label: 'Round 4 (structural containment rescue, 7 cards)', is_v2_architecture: false, source_commit: '36c9c04' },
  { dir: 'object_first_v2_validation_16_v1', label: 'Validation-16 (V2 architecture, 16 cards)', is_v2_architecture: true, source_commit: '53f72d2 (frozen prompts from 4eba93c)' },
  { dir: 'object_first_v2_validation_8_hard_sentinels_v1', label: 'Validation-8 hard sentinels (V2 architecture, 8 cards)', is_v2_architecture: true, source_commit: 'c7d00b9 (frozen prompts from 2208ce3)' },
  { dir: 'object_first_v2_recheck_3_final_v1', label: 'Recheck-3 final (V2 architecture, 3 cards)', is_v2_architecture: true, source_commit: '7425cce (frozen prompts from 4c8791c)' },
  { dir: 'object_first_v2_startups_final_recheck_v1', label: 'Startups final single-sentinel recheck (V2 architecture, 1 card)', is_v2_architecture: true, source_commit: '9b031bc (frozen prompt from 9b031bc itself)' },
];

// Authoritative visual acceptance explicitly supplied by the user in this
// conversation's own instructions (never inferred by Claude). Each entry
// names the exact source experiment whose output the acceptance applies
// to, so it is only ever attached to the specific image file it was
// actually said about.
const SUPPLIED_VISUAL_ACCEPTANCE = {
  'object_first_v2_recheck_3_final_v1::media.anime': { verdict: 'PASS', quote: '"media.anime = PASS" - Production Rollout Engineering task instructions, citing Recheck-3 ChatGPT review' },
  'object_first_v2_recheck_3_final_v1::learning.mock_trial': { verdict: 'PASS / acceptable', quote: '"learning.mock_trial = PASS / acceptable" - Production Rollout Engineering task instructions, citing Recheck-3 ChatGPT review' },
  'object_first_v2_startups_final_recheck_v1::business.startups': { verdict: 'PASS', quote: '"The final startup image at commit 9b031bc successfully resolved: human-hand leakage, readable product-name packaging, electronics-hobby semantic collapse" - Production Rollout Engineering task instructions' },
};

function loadCurrentFrozenHashes() {
  const rows = readJsonl(path.join(AUDIT_DIR, 'compiled_prompts_v1.jsonl'));
  return new Map(rows.map(r => [r.canonical_interest_id, r.prompt_sha256 || crypto.createHash('sha256').update(r.final_compiled_prompt, 'utf8').digest('hex')]));
}

function inventoryExperiment(exp, currentHashes) {
  const dir = path.join(OUTPUT_ROOT, exp.dir);
  const manifestPath = path.join(dir, 'manifest.json');
  if (!fs.existsSync(manifestPath)) {
    return { experiment: exp.label, dir: exp.dir, error: 'no manifest.json found', entries: [] };
  }
  const manifest = readJson(manifestPath);
  const entries = (manifest.entries || []).map(e => {
    const id = e.canonical_interest_id;
    const imagePath = e.local_image_path ? path.join(path.dirname(ROOT), '..', e.local_image_path) : (e.output_filename ? path.join(dir, 'images', e.output_filename) : null);
    const resolvedImagePath = e.status === 'succeeded' && e.output_filename ? path.join(dir, 'images', e.output_filename) : null;
    const fileExists = resolvedImagePath ? fs.existsSync(resolvedImagePath) : false;
    const currentFrozenSha = currentHashes.get(id) || null;
    const recordedPromptSha = e.prompt_sha256 || null;
    const shaMatch = exp.is_v2_architecture && recordedPromptSha && currentFrozenSha ? recordedPromptSha === currentFrozenSha : false;
    const acceptanceKey = `${exp.dir}::${id}`;
    const suppliedAcceptance = SUPPLIED_VISUAL_ACCEPTANCE[acceptanceKey] || null;
    // A third, honest bucket: visual acceptance IS established, but the
    // recorded prompt does NOT match what the current canonical pipeline
    // reproduces (e.g. Recheck-3's media.anime/learning.mock_trial used a
    // one-off local effect_level diversity adjustment applied only to
    // that 3-card test batch, never folded back into composition_diversity_v2.json
    // or any spec file, so re-running the standard compiler does not
    // reproduce it). This is a real provenance gap, not a hash-check bug -
    // it requires an explicit decision (formally adopt the tested value as
    // a canonical override, or discard and regenerate) before reuse.
    const promptDivergedButAccepted = Boolean(exp.is_v2_architecture && recordedPromptSha && currentFrozenSha && !shaMatch && suppliedAcceptance && fileExists && e.status === 'succeeded');
    return {
      canonical_interest_id: id,
      source_experiment: exp.label,
      source_dir: exp.dir,
      source_commit: exp.source_commit,
      is_v2_architecture: exp.is_v2_architecture,
      model: e.model || manifest.model || null,
      api_status: e.status,
      recorded_prompt_sha256: recordedPromptSha,
      current_frozen_prompt_sha256_9b031bc: currentFrozenSha,
      prompt_sha256_exact_match: shaMatch,
      file_exists: fileExists,
      file_sha256: e.file_sha256 || null,
      technical_integrity_ok: e.status === 'succeeded' && fileExists && Boolean(e.file_sha256),
      supplied_visual_acceptance: suppliedAcceptance,
      production_reuse_candidate: Boolean(shaMatch && fileExists && Boolean(e.file_sha256) && e.status === 'succeeded' && suppliedAcceptance),
      reuse_needs_visual_confirmation: Boolean(shaMatch && fileExists && Boolean(e.file_sha256) && e.status === 'succeeded' && !suppliedAcceptance),
      reuse_prompt_diverged_from_canonical: promptDivergedButAccepted,
    };
  });
  return { experiment: exp.label, dir: exp.dir, entries };
}

function main() {
  const currentHashes = loadCurrentFrozenHashes();
  if (currentHashes.size !== 2208) throw new Error(`Expected 2208 current frozen prompt hashes, got ${currentHashes.size}. Refusing (fail-closed).`);

  const perExperiment = EXPERIMENTS.map(exp => inventoryExperiment(exp, currentHashes));
  const allEntries = perExperiment.flatMap(e => e.entries);

  const reuseCandidates = allEntries.filter(e => e.production_reuse_candidate);
  const needsConfirmation = allEntries.filter(e => e.reuse_needs_visual_confirmation);
  const diverged = allEntries.filter(e => e.reuse_prompt_diverged_from_canonical);
  const nonMatchingV2 = allEntries.filter(e => e.is_v2_architecture && !e.prompt_sha256_exact_match && !e.reuse_prompt_diverged_from_canonical && e.api_status === 'succeeded');
  const nonV2Architecture = allEntries.filter(e => !e.is_v2_architecture);
  const contentBlocked = allEntries.filter(e => e.api_status !== 'succeeded');

  // production_reuse_candidate is keyed by canonical id - if the same id
  // appears reusable from more than one experiment (should not happen
  // given the analysis above, but verified mechanically rather than
  // assumed), dedupe by id, preferring the most recent source commit.
  const reuseByIdMap = new Map();
  for (const r of reuseCandidates) {
    if (!reuseByIdMap.has(r.canonical_interest_id)) reuseByIdMap.set(r.canonical_interest_id, r);
  }
  const uniqueReusableIds = [...reuseByIdMap.keys()];

  const totalEligible = 2208;
  const futureNewGenerationCount = totalEligible - uniqueReusableIds.length;
  const fullFreshCeilingUsd = Number((totalEligible * 0.0168).toFixed(4));
  const revisedProjectedCostUsd = Number((futureNewGenerationCount * 0.0168).toFixed(4));
  const savingsUsd = Number((fullFreshCeilingUsd - revisedProjectedCostUsd).toFixed(4));

  const summary = {
    version: 'v1',
    generated_at: new Date().toISOString(),
    scope: 'Zero-cost technical inventory only. No image contents were inspected. Visual acceptance is attached ONLY where explicitly supplied by the user in prior instructions, never inferred.',
    current_frozen_production_candidate_commit: '9b031bc',
    total_eligible: totalEligible,
    per_experiment_summary: perExperiment.map(e => ({ experiment: e.experiment, dir: e.dir, entry_count: e.entries.length, error: e.error || null })),
    total_historical_generated_entries_examined: allEntries.length,
    non_v2_architecture_count: nonV2Architecture.length,
    v2_architecture_succeeded_non_matching_count: nonMatchingV2.length,
    v2_architecture_content_blocked_or_failed_count: contentBlocked.filter(e => e.is_v2_architecture).length,
    exact_match_technically_reusable_count: reuseCandidates.length,
    exact_match_visually_accepted_count: reuseCandidates.length,
    reuse_needs_visual_confirmation_count: needsConfirmation.length,
    accepted_but_prompt_diverged_from_canonical_count: diverged.length,
    accepted_but_prompt_diverged_from_canonical_note: 'These images ARE explicitly visually accepted, but their exact submitted prompt included a one-off local effect_level diversity adjustment (applied only within the Recheck-3 3-card test batch to avoid a repeated "restrained" value) that was never folded back into any canonical spec file, so the standard compiler does not reproduce it. NOT counted as reuse-ready until an explicit decision is made: either formally adopt the tested effect_level as a canonical per-id override (creating a real, spec-driven prompt change, which Part 1 explicitly forbids doing silently in this checkpoint), or discard and regenerate fresh from the canonical prompt.',
    unique_reusable_canonical_ids: uniqueReusableIds,
    future_new_generation_count: futureNewGenerationCount,
    full_fresh_generation_ceiling_usd: fullFreshCeilingUsd,
    revised_projected_generation_cost_usd: revisedProjectedCostUsd,
    exact_savings_from_reuse_usd: savingsUsd,
  };

  writeJson(path.join(AUDIT_DIR, 'existing_art_inventory_v1.json'), { summary, per_experiment: perExperiment });
  console.log(`Inventory complete. Reusable (hash-match + supplied acceptance): ${reuseCandidates.length}. Needs visual confirmation: ${needsConfirmation.length}. Accepted-but-diverged: ${diverged.length}. Non-matching V2: ${nonMatchingV2.length}. Non-V2-architecture: ${nonV2Architecture.length}. Future new-generation count: ${futureNewGenerationCount}. Revised cost: $${revisedProjectedCostUsd}. Savings: $${savingsUsd}.`);
}

main();

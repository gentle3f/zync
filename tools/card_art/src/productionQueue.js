// Production-batch queue builder for the full 2210-interest baseline-art
// catalog. Pure, deterministic, zero-cost: compiles every prompt with the
// real production compiler (D4 + global brand-safety/text/screen policies
// + hobby_overrides_v1.json fixes + the diversity layer) but never calls
// any generation API. Callers decide when (if ever) to actually submit.
//
// Determinism contract: given the same spec/catalog/override files, two
// independent calls to buildProductionQueue() must produce byte-identical
// queue rows (ordering, diversity/effects assignments, batch numbers,
// prompt fingerprints) - verified by validateProductionArchitecture.js.

import crypto from 'node:crypto';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';
import { compileHobbyPrompt } from './buildPromptV1.js';

export const EXPECTED_ELIGIBLE_COUNT = 2210;
export const MODEL = 'gemini-3.1-flash-lite-image';
export const PROVIDER = 'Google Gemini API direct';
export const BATCH_SIZE = 120;
export const BATCH_IMAGE_OUTPUT_PRICE_USD = 0.0168;

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

function outputFilenameFor(canonicalInterestId) {
  return `${canonicalInterestId.replaceAll('.', '__')}__gemini_3_1_flash_lite_image.jpg`;
}

function plannedBatchId(batchNumber) {
  return `zync-prod-batch-${String(batchNumber).padStart(3, '0')}`;
}

// specCtx: { globalStyle, archetypes, variants, categories, subcategories,
//            overrides, flagship, diversityProfiles, guardrails }
export function buildProductionQueue(specCtx) {
  const bridge = buildCatalogRecipeBridge();

  if (bridge.eligible.length !== EXPECTED_ELIGIBLE_COUNT) {
    throw new Error(
      `Fail-closed: expected exactly ${EXPECTED_ELIGIBLE_COUNT} baseline-art-eligible ` +
      `interests, but the rights-first catalog bridge now reports ${bridge.eligible.length}. ` +
      `Refusing to build a production queue against an unexpectedly-changed eligible set.`,
    );
  }

  const seenIds = new Set();
  for (const row of bridge.eligible) {
    if (seenIds.has(row.canonical_interest_id)) {
      throw new Error(`Duplicate canonical_interest_id in eligible catalog: ${row.canonical_interest_id}`);
    }
    seenIds.add(row.canonical_interest_id);
  }

  const quarantined = specCtx.guardrails?.quarantined || {};

  // Deterministic, reproducible ordering: sort by canonical_interest_id.
  // (buildCatalogRecipeBridge's own ordering is not guaranteed stable
  // across catalog edits, so we do not rely on array order alone.)
  const sortedRows = [...bridge.eligible].sort((a, b) =>
    a.canonical_interest_id < b.canonical_interest_id ? -1 : a.canonical_interest_id > b.canonical_interest_id ? 1 : 0,
  );

  const compiledEntries = sortedRows.map(row => {
    const hobby = row.recipe;
    const overrideKey = row.source_recipe_id || hobby.id;
    const isQuarantined = Object.hasOwn(quarantined, row.canonical_interest_id);
    const compiled = compileHobbyPrompt({
      hobby,
      globalStyle: specCtx.globalStyle,
      archetypes: specCtx.archetypes,
      variants: specCtx.variants,
      categories: specCtx.categories,
      subcategories: specCtx.subcategories,
      override: specCtx.overrides.overrides?.[overrideKey] || null,
      flagshipOverride: specCtx.flagship.flagship?.[overrideKey] || null,
      diversityProfiles: specCtx.diversityProfiles,
    });

    return {
      canonical_interest_id: row.canonical_interest_id,
      title: hobby.title,
      runtime_category: row.runtime_category,
      runtime_cluster: row.runtime_cluster,
      art_policy: row.art_policy,
      recipe_source: row.recipe_source,
      archetype: compiled.effective.archetype,
      visual_variant: compiled.variant.id,
      diversity_profile: compiled.diversityProfile,
      effects_profile: compiled.diversityProfile?.effects_intensity || null,
      prompt_sha256: sha256(compiled.compiledPrompt),
      prompt_length: compiled.compiledPrompt.length,
      model: MODEL,
      provider: PROVIDER,
      quarantined: isQuarantined,
      quarantine_reason: isQuarantined ? quarantined[row.canonical_interest_id].reason : null,
      output_filename: outputFilenameFor(row.canonical_interest_id),
    };
  });

  // Batch assignment: only non-quarantined entries get a numbered
  // production batch. Quarantined entries stay in the full queue (so the
  // eligible-count vs auto-production-count vs quarantine-count
  // distinction is never silently lost) but receive no batch number and
  // cannot be picked up by any batch-submission pass.
  const autoEntries = compiledEntries.filter(e => !e.quarantined);
  const quarantinedEntries = compiledEntries.filter(e => e.quarantined);

  const batches = [];
  for (let i = 0; i < autoEntries.length; i += BATCH_SIZE) {
    const batchNumber = batches.length + 1;
    const slice = autoEntries.slice(i, i + BATCH_SIZE);
    for (const entry of slice) {
      entry.batch_number = batchNumber;
      entry.planned_batch_id = plannedBatchId(batchNumber);
      entry.status = 'pending';
    }
    batches.push({
      batch_number: batchNumber,
      planned_batch_id: plannedBatchId(batchNumber),
      size: slice.length,
      canonical_interest_ids: slice.map(e => e.canonical_interest_id),
    });
  }
  for (const entry of quarantinedEntries) {
    entry.batch_number = null;
    entry.planned_batch_id = null;
    entry.status = 'quarantined_excluded';
  }

  const queue = [...autoEntries, ...quarantinedEntries].sort((a, b) =>
    a.canonical_interest_id < b.canonical_interest_id ? -1 : a.canonical_interest_id > b.canonical_interest_id ? 1 : 0,
  );

  const counts = {
    eligible_catalog_count: compiledEntries.length,
    auto_production_count: autoEntries.length,
    quarantine_count: quarantinedEntries.length,
    planned_batch_count: batches.length,
    batch_size: BATCH_SIZE,
  };

  return { queue, batches, counts, quarantined_ids: quarantinedEntries.map(e => e.canonical_interest_id) };
}

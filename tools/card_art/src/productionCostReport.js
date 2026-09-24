// Cost accounting for the production batch pipeline. Pure function over
// the queue + manifest state - does not assume failed requests are billed
// unless a manifest record explicitly carries an actual_cost_usd (only
// set from real API/billing metadata, never inferred).

import { BATCH_IMAGE_OUTPUT_PRICE_USD } from './productionQueue.js';

export function buildCostReport(queue, priorManifestById) {
  const eligible = queue.length;
  const quarantined = queue.filter(e => e.quarantined).length;
  const autoProduction = eligible - quarantined;

  let succeeded = 0;
  let failedTransient = 0;
  let failedContent = 0;
  let needsQa = 0;
  let retryPending = 0;
  let actualCostKnownUsd = 0;
  let actualCostKnownCount = 0;

  for (const entry of queue) {
    const prior = priorManifestById.get(entry.canonical_interest_id);
    if (!prior) continue;
    if (prior.status === 'succeeded') succeeded += 1;
    if (prior.status === 'failed_transient') failedTransient += 1;
    if (prior.status === 'failed_content') failedContent += 1;
    if (prior.status === 'needs_qa') needsQa += 1;
    if (prior.status === 'retry_pending') retryPending += 1;
    if (typeof prior.actual_cost_usd === 'number') {
      actualCostKnownUsd += prior.actual_cost_usd;
      actualCostKnownCount += 1;
    }
  }

  return {
    unit_price_usd_per_successful_image: BATCH_IMAGE_OUTPUT_PRICE_USD,
    eligible_catalog_count: eligible,
    quarantine_count: quarantined,
    auto_production_count: autoProduction,
    estimated_baseline_cost_usd_all_eligible: Number((eligible * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)),
    estimated_cost_usd_auto_production_only: Number((autoProduction * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)),
    planned_images: autoProduction,
    successful_images: succeeded,
    failed_transient: failedTransient,
    failed_content: failedContent,
    needs_qa: needsQa,
    retry_pending: retryPending,
    billed_image_outputs_estimate: succeeded,
    estimated_cost_of_successful_so_far_usd: Number((succeeded * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)),
    actual_cost_known_usd: actualCostKnownCount > 0 ? Number(actualCostKnownUsd.toFixed(4)) : null,
    actual_cost_known_image_count: actualCostKnownCount,
    note: 'estimated_cost_of_successful_so_far_usd assumes only successful images are billed (Google Batch image-output pricing) unless actual_cost_known_usd from real billing metadata says otherwise. Failed/transient requests are not assumed billed.',
  };
}

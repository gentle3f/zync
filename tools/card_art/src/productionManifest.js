// Resume-safe, failure-only-retry manifest logic for the production
// batch pipeline. Pure functions only - no network calls, no file writes
// here (callers own I/O so this module stays trivially unit-testable and
// safe to exercise with mocked data).
//
// Manifest entry shape (persisted separately per canonical_interest_id,
// keyed by canonical_interest_id -> latest known record):
//   {
//     canonical_interest_id, status, batch_number, planned_batch_id,
//     google_batch_name, request_index, request_key,
//     prompt_sha256, output_filename, file_sha256,
//     generated_at, model, provider,
//     estimated_cost_usd, actual_cost_usd,
//     attempt, last_error,
//   }
//
// Statuses: pending, submitted, succeeded, failed_transient,
// failed_content, needs_qa, approved, retry_pending, quarantined_excluded.

export const RETRYABLE_STATUSES = new Set(['failed_transient', 'retry_pending']);
// failed_content is NOT retryable automatically: a content-policy
// rejection usually means the compiled prompt itself needs a
// hobby_overrides_v1.json fix, not a bare resubmission. It routes to
// needs_qa for human review instead of the retry queue.
export const NON_RETRYABLE_TERMINAL_STATUSES = new Set([
  'succeeded', 'needs_qa', 'approved', 'quarantined_excluded',
]);

// Given the full queue (from buildProductionQueue) and a map of prior
// manifest records (canonical_interest_id -> record, possibly empty),
// decide what a resume pass should submit next. Never returns an id whose
// prior record is already 'succeeded' - a restart must not regenerate a
// known-good image.
export function planSubmission(queue, priorManifestById) {
  const toSubmit = [];
  const skippedSucceeded = [];
  const skippedQuarantined = [];
  for (const entry of queue) {
    if (entry.quarantined) {
      skippedQuarantined.push(entry.canonical_interest_id);
      continue;
    }
    const prior = priorManifestById.get(entry.canonical_interest_id);
    if (!prior) {
      toSubmit.push({ ...entry, plan_reason: 'never_attempted' });
      continue;
    }
    if (prior.status === 'succeeded') {
      skippedSucceeded.push(entry.canonical_interest_id);
      continue;
    }
    if (RETRYABLE_STATUSES.has(prior.status)) {
      toSubmit.push({ ...entry, plan_reason: 'retry', prior_attempt: prior.attempt || 1 });
      continue;
    }
    if (NON_RETRYABLE_TERMINAL_STATUSES.has(prior.status)) {
      // needs_qa / approved / quarantined_excluded: not auto-submitted;
      // requires a separate human/QA action to move it back to pending.
      continue;
    }
    // pending / submitted with no resolution yet (e.g. an interrupted run):
    // safe to (re)submit, since it never reached a terminal success state.
    toSubmit.push({ ...entry, plan_reason: 'unresolved_prior_attempt' });
  }
  return { toSubmit, skippedSucceeded, skippedQuarantined };
}

// Given a batch of completed request outcomes (mocked or real), classify
// each into the next manifest status. transientErrorCodes/contentErrorCodes
// let callers map provider-specific error shapes without this module
// needing to know Gemini's exact error taxonomy.
export function classifyOutcome(outcome) {
  if (outcome.image_written) return 'succeeded';
  if (outcome.error_type === 'timeout' || outcome.error_type === 'no_image' || outcome.error_type === 'transient') {
    return 'failed_transient';
  }
  if (outcome.error_type === 'content_policy') return 'failed_content';
  return 'needs_qa';
}

// Builds the next-round retry plan strictly from failed_transient /
// retry_pending entries. A successful entry is never included, even if it
// appears alongside failures in the same source batch.
export function planRetryBatch(priorManifestById) {
  const retryIds = [];
  for (const [id, record] of priorManifestById) {
    if (RETRYABLE_STATUSES.has(record.status)) retryIds.push(id);
  }
  return retryIds.sort();
}

// Real direct-Google production runner. Reads the already-validated
// production_queue_v1.json + production_batch_plan_v1.json rather than
// building an ad-hoc selection, and submits through the direct Google
// Gemini Batch API (no fal.ai). Hard-locked to production batch 1 only
// for this authorized session - any other --batch value throws.
//
// Usage:
//   node src/runProductionBatch.js --batch=1 --dry-run
//   node src/runProductionBatch.js --batch=1 --submit
//   node src/runProductionBatch.js --batch=1 --collect
//
// Requires GEMINI_API_KEY for --submit/--collect.

import 'dotenv/config';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { Readable } from 'node:stream';
import { finished } from 'node:stream/promises';
import { fileURLToPath } from 'node:url';
import { chain } from 'stream-chain';
import { parser } from 'stream-json/parser.js';
import { pick } from 'stream-json/filters/pick.js';
import { ignore } from 'stream-json/filters/ignore.js';
import { streamArray } from 'stream-json/streamers/stream-array.js';
import { streamValues } from 'stream-json/streamers/stream-values.js';
import { compileHobbyPrompt } from './buildPromptV1.js';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';
import { MODEL, PROVIDER, BATCH_IMAGE_OUTPUT_PRICE_USD } from './productionQueue.js';

// Hard authorization lock: this session is authorized for production
// batch 1 ONLY. Do not widen this set without a new explicit user
// instruction authorizing further batches.
const AUTHORIZED_BATCH_NUMBERS = new Set([1]);

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');
const SPECS = path.join(ROOT, 'specs');
const CATALOG = path.join(ROOT, 'catalog');
const QUEUE_PATH = path.join(CATALOG, 'production_queue_v1.json');
const PLAN_PATH = path.join(CATALOG, 'production_batch_plan_v1.json');

const BATCH_ENDPOINT_FOR = model =>
  `https://generativelanguage.googleapis.com/v1beta/models/${model}:batchGenerateContent`;

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};

function sha256Text(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}
function sha256Buffer(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

function parseArgs(argv) {
  const args = { batch: null, dryRun: false, submit: false, collect: false };
  for (const arg of argv) {
    if (arg === '--dry-run') args.dryRun = true;
    else if (arg === '--submit') args.submit = true;
    else if (arg === '--collect') args.collect = true;
    else if (arg.startsWith('--batch=')) args.batch = Number(arg.slice('--batch='.length));
  }
  return args;
}

function loadSpecCtx() {
  return {
    globalStyle: readJson(path.join(SPECS, 'global_style_v1.json')),
    archetypes: readJson(path.join(SPECS, 'archetypes_v1.json')),
    variants: readJson(path.join(SPECS, 'archetype_variants_v1.json')),
    categories: readJson(path.join(SPECS, 'category_modifiers_v1.json')),
    subcategories: readJson(path.join(SPECS, 'subcategory_modifiers_v1.json')),
    overrides: readJson(path.join(CATALOG, 'hobby_overrides_v1.json')),
    flagship: readJson(path.join(CATALOG, 'flagship_overrides_v1.json')),
    diversityProfiles: readJson(path.join(SPECS, 'diversity_profiles_v1.json')),
    guardrails: readJson(path.join(SPECS, 'generation_guardrails_v1.json')),
  };
}

// Recompiles the exact prompt for a batch's ids straight from the same
// production compiler productionQueue.js uses, and cross-checks the
// result against the already-committed queue's prompt_sha256 fingerprint.
// This is the mechanism that lets the committed queue stay compact (no
// embedded prompt text) while still being a faithful, verifiable source
// of truth for what gets submitted.
function compileBatchRows(batchNumber) {
  const queueDoc = readJson(QUEUE_PATH);
  const planDoc = readJson(PLAN_PATH);
  const planBatch = planDoc.batches.find(b => b.batch_number === batchNumber);
  if (!planBatch) throw new Error(`Batch ${batchNumber} not found in production_batch_plan_v1.json`);

  const queueById = new Map(queueDoc.entries.map(e => [e.canonical_interest_id, e]));
  const ids = planBatch.canonical_interest_ids;

  const uniqueIds = new Set(ids);
  if (uniqueIds.size !== ids.length) throw new Error(`Batch ${batchNumber} has duplicate canonical_interest_ids in the plan`);

  const specCtx = loadSpecCtx();
  const bridge = buildCatalogRecipeBridge();
  const eligibleById = new Map(bridge.eligible.map(r => [r.canonical_interest_id, r]));
  const quarantined = specCtx.guardrails?.quarantined || {};

  const rows = ids.map((id, index) => {
    const queueEntry = queueById.get(id);
    if (!queueEntry) throw new Error(`${id} is in the batch plan but missing from production_queue_v1.json`);
    if (queueEntry.quarantined || Object.hasOwn(quarantined, id)) {
      throw new Error(`Refusing quarantined canonical in a production batch: ${id}`);
    }
    if (queueEntry.batch_number !== batchNumber) {
      throw new Error(`${id} queue batch_number=${queueEntry.batch_number} does not match requested batch ${batchNumber}`);
    }

    const row = eligibleById.get(id);
    if (!row) throw new Error(`${id} is in the queue but not in the current eligible catalog bridge`);
    const hobby = row.recipe;
    const overrideKey = row.source_recipe_id || hobby.id;
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

    const recomputedSha = sha256Text(compiled.compiledPrompt);
    if (recomputedSha !== queueEntry.prompt_sha256) {
      throw new Error(
        `${id}: recompiled prompt_sha256 (${recomputedSha}) does not match production_queue_v1.json's stored ` +
        `fingerprint (${queueEntry.prompt_sha256}). The queue is stale relative to current specs/overrides - rebuild ` +
        `it with buildProductionQueueCli.js before submitting.`,
      );
    }

    return {
      canonical_interest_id: id,
      title: hobby.title,
      runtime_category: row.runtime_category,
      runtime_cluster: row.runtime_cluster,
      art_policy: row.art_policy,
      recipe_source: row.recipe_source,
      archetype: compiled.effective.archetype,
      visual_variant: compiled.variant.id,
      diversity_profile: compiled.diversityProfile,
      effects_profile: compiled.diversityProfile?.effects_intensity || null,
      prompt_sha256: recomputedSha,
      prompt_length: compiled.compiledPrompt.length,
      final_prompt: compiled.compiledPrompt,
      model: MODEL,
      provider: PROVIDER,
      batch_number: batchNumber,
      planned_batch_id: planBatch.planned_batch_id,
      request_index: index,
      request_key: id,
      output_filename: queueEntry.output_filename,
    };
  });

  return { rows, planBatch };
}

function outDirFor(batchNumber) {
  return path.join(ROOT, 'output', `production_batch_${String(batchNumber).padStart(3, '0')}_v1`);
}

function apiHeaders() {
  const key = process.env.GEMINI_API_KEY;
  if (!key) throw new Error('GEMINI_API_KEY is not set.');
  return { 'x-goog-api-key': key, 'Content-Type': 'application/json' };
}

async function jsonFetch(url, options = {}) {
  const res = await fetch(url, options);
  const text = await res.text();
  let parsed;
  try { parsed = JSON.parse(text); } catch { parsed = { raw: text }; }
  if (!res.ok) throw new Error('Gemini API HTTP ' + res.status + ': ' + JSON.stringify(parsed));
  return parsed;
}

function buildBatchPayload(rows, plannedBatchId) {
  return {
    batch: {
      display_name: plannedBatchId,
      input_config: {
        requests: {
          requests: rows.map(row => ({
            request: {
              contents: [{ role: 'user', parts: [{ text: row.final_prompt }] }],
              generationConfig: { responseModalities: ['Image'], imageConfig: { aspectRatio: '2:3' } },
            },
            metadata: { key: row.request_key, index: row.request_index },
          })),
        },
      },
    },
  };
}

function extractResponse(wrapper) {
  return wrapper?.response || wrapper?.inlineResponse || wrapper?.result || wrapper;
}
function extractImagePart(response) {
  const candidates = response?.candidates || [];
  for (const candidate of candidates) {
    for (const part of candidate?.content?.parts || []) {
      const inline = part?.inlineData || part?.inline_data;
      if (inline?.data && String(inline?.mimeType || inline?.mime_type || '').startsWith('image/')) {
        return { data: inline.data, mime_type: inline.mimeType || inline.mime_type };
      }
    }
  }
  return null;
}
function extensionForMime(mime) {
  if (mime === 'image/jpeg') return 'jpg';
  if (mime === 'image/webp') return 'webp';
  return 'png';
}

const REDACT_THRESHOLD = 2000;
function redactLargeStrings(value) {
  if (Array.isArray(value)) return value.map(redactLargeStrings);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      if (typeof v === 'string' && v.length > REDACT_THRESHOLD) {
        out[k] = '[redacted-large-string field="' + k + '" len=' + v.length + ']';
      } else {
        out[k] = redactLargeStrings(v);
      }
    }
    return out;
  }
  return value;
}

function classifyError(message) {
  const m = String(message || '').toLowerCase();
  if (m.includes('timeout')) return 'timeout';
  if (m.includes('no image') || m.includes('no inlinedata')) return 'no_image';
  if (m.includes('safety') || m.includes('blocked') || m.includes('policy')) return 'content_policy';
  return 'transient';
}

async function submit(rows, plannedBatchId, outDir) {
  const payload = buildBatchPayload(rows, plannedBatchId);
  writeJson(path.join(outDir, 'requests.json'), {
    model: MODEL,
    provider: PROVIDER,
    generated_at: new Date().toISOString(),
    batch_number: rows[0]?.batch_number,
    planned_batch_id: plannedBatchId,
    rows,
    payload,
  });

  const result = await jsonFetch(BATCH_ENDPOINT_FOR(MODEL), {
    method: 'POST',
    headers: apiHeaders(),
    body: JSON.stringify(payload),
  });
  if (!result?.name) throw new Error('Batch submission returned no job name.');
  writeJson(path.join(outDir, 'batch_job.json'), {
    model: MODEL,
    provider: PROVIDER,
    submitted_at: new Date().toISOString(),
    batch_number: rows[0]?.batch_number,
    planned_batch_id: plannedBatchId,
    batch_name: result.name,
    raw: result,
  });
  console.log('Submitted direct Google production batch:', result.name);
}

// A 120-request batch status response can carry >500MB of inline base64
// image + thoughtSignature data (and Google duplicates the whole
// inlinedResponses array under both metadata.output and response), which
// blows past Node/V8's ~512MB max string length if read via res.text().
// So the response body is streamed straight to a scratch file (never
// materialized as one JS string), then processed in two token-streaming
// passes with stream-json: one that strips out both inlinedResponses
// duplicates entirely (leaving a small metadata-only summary, which is
// also exactly what we want to persist - no raw base64/thoughtSignature
// ever touches the committed batch_status.json), and one that streams
// only response.inlinedResponses.inlinedResponses items one at a time so
// memory stays bounded to a single request's payload, not all 120 at once.
async function fetchStatusToScratchFile(statusUrl) {
  const res = await fetch(statusUrl, { method: 'GET', headers: apiHeaders() });
  if (!res.ok || !res.body) {
    const text = await res.text().catch(() => '');
    throw new Error('Gemini API HTTP ' + res.status + ': ' + text.slice(0, 2000));
  }
  const scratchPath = path.join(os.tmpdir(), `zync-batch-status-${crypto.randomBytes(8).toString('hex')}.json`);
  const nodeReadable = Readable.fromWeb(res.body);
  const writeStream = fs.createWriteStream(scratchPath);
  nodeReadable.pipe(writeStream);
  await finished(writeStream);
  return scratchPath;
}

async function readStatusSummary(scratchPath) {
  let summary = null;
  await new Promise((resolve, reject) => {
    const pipeline = chain([
      fs.createReadStream(scratchPath),
      parser(),
      ignore({ filter: /inlinedResponses/ }),
      streamValues(),
    ]);
    pipeline.on('data', ({ value }) => { summary = value; });
    pipeline.on('end', resolve);
    pipeline.on('error', reject);
  });
  return summary;
}

async function forEachInlineResponse(scratchPath, onItem) {
  await new Promise((resolve, reject) => {
    const pipeline = chain([
      fs.createReadStream(scratchPath),
      parser(),
      pick({ filter: 'response.inlinedResponses.inlinedResponses' }),
      streamArray(),
    ]);
    pipeline.on('data', ({ value }) => onItem(value));
    pipeline.on('end', resolve);
    pipeline.on('error', reject);
  });
}

async function collect(rows, outDir) {
  const jobPath = path.join(outDir, 'batch_job.json');
  if (!fs.existsSync(jobPath)) throw new Error('No batch_job.json found. Run --submit first.');
  const job = readJson(jobPath);
  const statusUrl = 'https://generativelanguage.googleapis.com/v1beta/' + job.batch_name;

  const scratchPath = await fetchStatusToScratchFile(statusUrl);
  let statusSummary;
  try {
    statusSummary = await readStatusSummary(scratchPath);
    writeJson(path.join(outDir, 'batch_status.json'), redactLargeStrings(statusSummary));

    const state = statusSummary?.metadata?.state || statusSummary?.state || statusSummary?.batch?.state || null;
    console.log('Batch state:', state || 'unknown');
    const SUCCESS_STATES = new Set(['JOB_STATE_SUCCEEDED', 'BATCH_STATE_SUCCEEDED']);
    if (!SUCCESS_STATES.has(state)) {
      console.log('No images written. Re-run --collect after the batch succeeds.');
      return;
    }

    const imagesDir = path.join(outDir, 'images');
    fs.mkdirSync(imagesDir, { recursive: true });

    const manifestPath = path.join(outDir, 'manifest.json');
    const priorManifest = fs.existsSync(manifestPath) ? readJson(manifestPath) : { entries: [] };
    const priorByKey = new Map(priorManifest.entries.map(e => [e.canonical_interest_id, e]));
    const rowsById = new Map(rows.map(r => [r.canonical_interest_id, r]));

    const nowIso = new Date().toISOString();
    const entriesById = new Map();
    let succeeded = 0;
    let failedTransient = 0;
    let failedContent = 0;

    await forEachInlineResponse(scratchPath, wrapper => {
      const key = wrapper?.metadata?.key;
      const row = key ? rowsById.get(key) : null;
      if (!row) {
        console.warn(`Skipping response with unrecognized/missing metadata.key: ${key}`);
        return;
      }
      const prior = priorByKey.get(row.canonical_interest_id);
      if (prior?.status === 'succeeded') {
        // Resume-safe: never regenerate/overwrite an already-succeeded entry.
        entriesById.set(row.canonical_interest_id, prior);
        succeeded += 1;
        return;
      }

      const response = extractResponse(wrapper);
      const image = extractImagePart(response);

      if (!image) {
        const finishReason = response?.candidates?.[0]?.finishReason || response?.candidates?.[0]?.finish_reason || null;
        const errType = finishReason && String(finishReason).toUpperCase().includes('SAFETY')
          ? 'content_policy'
          : classifyError(JSON.stringify(response || {}).slice(0, 300));
        const status_ = errType === 'content_policy' ? 'failed_content' : 'failed_transient';
        if (status_ === 'failed_content') failedContent += 1; else failedTransient += 1;
        entriesById.set(row.canonical_interest_id, {
          canonical_interest_id: row.canonical_interest_id,
          title: row.title,
          runtime_category: row.runtime_category,
          runtime_cluster: row.runtime_cluster,
          archetype: row.archetype,
          visual_variant: row.visual_variant,
          diversity_profile: row.diversity_profile,
          effects_profile: row.effects_profile,
          model: MODEL,
          provider: PROVIDER,
          batch_number: row.batch_number,
          planned_batch_id: row.planned_batch_id,
          google_batch_name: job.batch_name,
          request_index: row.request_index,
          request_key: row.request_key,
          prompt_sha256: row.prompt_sha256,
          output_filename: row.output_filename,
          file_sha256: null,
          generated_at: nowIso,
          status: status_,
          attempt: (prior?.attempt || 0) + 1,
          last_error: `no image inlineData in response (finishReason=${finishReason || 'unknown'})`,
          estimated_cost_usd: null,
          actual_cost_usd: null,
        });
        return;
      }

      const ext = extensionForMime(image.mime_type);
      const filename = row.output_filename.replace(/\.jpg$/, `.${ext}`);
      const localPath = path.join(imagesDir, filename);
      const buffer = Buffer.from(image.data, 'base64');
      fs.writeFileSync(localPath, buffer);
      succeeded += 1;
      entriesById.set(row.canonical_interest_id, {
        canonical_interest_id: row.canonical_interest_id,
        title: row.title,
        runtime_category: row.runtime_category,
        runtime_cluster: row.runtime_cluster,
        archetype: row.archetype,
        visual_variant: row.visual_variant,
        diversity_profile: row.diversity_profile,
        effects_profile: row.effects_profile,
        model: MODEL,
        provider: PROVIDER,
        batch_number: row.batch_number,
        planned_batch_id: row.planned_batch_id,
        google_batch_name: job.batch_name,
        request_index: row.request_index,
        request_key: row.request_key,
        prompt_sha256: row.prompt_sha256,
        output_filename: filename,
        local_image_path: path.relative(REPO_ROOT, localPath).replace(/\\/g, '/'),
        file_sha256: sha256Buffer(buffer),
        mime_type: image.mime_type,
        generated_at: nowIso,
        status: 'succeeded',
        attempt: (prior?.attempt || 0) + 1,
        last_error: null,
        estimated_cost_usd: BATCH_IMAGE_OUTPUT_PRICE_USD,
        actual_cost_usd: null,
        qa_status: 'pending_human_review',
      });
    });

    // Any row that never showed up in the response stream at all (should
    // not happen, but defensive) is recorded as a transient failure rather
    // than silently dropped from the manifest.
    for (const row of rows) {
      if (entriesById.has(row.canonical_interest_id)) continue;
      failedTransient += 1;
      entriesById.set(row.canonical_interest_id, {
        canonical_interest_id: row.canonical_interest_id,
        title: row.title,
        runtime_category: row.runtime_category,
        runtime_cluster: row.runtime_cluster,
        archetype: row.archetype,
        visual_variant: row.visual_variant,
        diversity_profile: row.diversity_profile,
        effects_profile: row.effects_profile,
        model: MODEL,
        provider: PROVIDER,
        batch_number: row.batch_number,
        planned_batch_id: row.planned_batch_id,
        google_batch_name: job.batch_name,
        request_index: row.request_index,
        request_key: row.request_key,
        prompt_sha256: row.prompt_sha256,
        output_filename: row.output_filename,
        file_sha256: null,
        generated_at: nowIso,
        status: 'failed_transient',
        attempt: 1,
        last_error: 'no response item found for this canonical_interest_id in the batch status stream',
        estimated_cost_usd: null,
        actual_cost_usd: null,
      });
    }

    const entries = rows.map(r => entriesById.get(r.canonical_interest_id));
    const manifest = {
      version: `production_batch_${String(rows[0]?.batch_number).padStart(3, '0')}_v1`,
      generated_at: nowIso,
      provider: PROVIDER,
      model: MODEL,
      fal_ai: false,
      batch_number: rows[0]?.batch_number,
      planned_batch_id: rows[0]?.planned_batch_id,
      google_batch_name: job.batch_name,
      expected_entries: rows.length,
      succeeded,
      failed_transient: failedTransient,
      failed_content: failedContent,
      estimated_cost_usd: Number((succeeded * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)),
      entries,
    };
    writeJson(manifestPath, manifest);
    console.log(
      `Collected batch ${manifest.batch_number}: succeeded=${succeeded} failed_transient=${failedTransient} ` +
      `failed_content=${failedContent} / ${rows.length}; manifest=${path.relative(ROOT, manifestPath)}`,
    );
  } finally {
    fs.rm(scratchPath, { force: true }, () => {});
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.batch == null) throw new Error('Missing --batch=N');
  if (!AUTHORIZED_BATCH_NUMBERS.has(args.batch)) {
    throw new Error(
      `HARD FAIL: production batch ${args.batch} is not authorized in this session. ` +
      `Only batch ${[...AUTHORIZED_BATCH_NUMBERS].join(', ')} is authorized. Refusing to proceed.`,
    );
  }

  const { rows, planBatch } = compileBatchRows(args.batch);
  const outDir = outDirFor(args.batch);

  if (args.dryRun || (!args.submit && !args.collect)) {
    const estCost = rows.length * BATCH_IMAGE_OUTPUT_PRICE_USD;
    console.log(`Dry run: production batch ${args.batch} (${planBatch.planned_batch_id}), ${rows.length} entries.`);
    console.log(`Estimated image-output cost: $${estCost.toFixed(4)} (plus small input-token charges).`);
    const ids = rows.map(r => r.canonical_interest_id);
    console.log('Unique ids:', new Set(ids).size === ids.length ? 'OK (no duplicates)' : 'DUPLICATES FOUND');
    for (const row of rows.slice(0, 3)) {
      console.log(`\n--- ${row.title} [${row.canonical_interest_id}] / ${row.archetype} / ${row.visual_variant} ---`);
      console.log(`diversity_profile=${JSON.stringify(row.diversity_profile)}`);
      console.log(row.final_prompt.slice(0, 400) + '...');
    }
    return;
  }

  if (args.submit) await submit(rows, planBatch.planned_batch_id, outDir);
  if (args.collect) await collect(rows, outDir);
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});

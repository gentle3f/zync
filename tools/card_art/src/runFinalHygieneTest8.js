// Final production-hygiene validation runner: proves (1) the strengthened
// business title/heading rule fixes the last two Batch-1 business
// blockers, and (2) the new arts_text_suppression_policy controls the
// arts.* text-leak cluster from Batch 1. Direct Google Gemini Batch API
// only, no fal.ai. Reuses the permanent streaming-collection fix from
// runProductionBatch.js.
//
// Usage:
//   node src/runFinalHygieneTest8.js --dry-run
//   node src/runFinalHygieneTest8.js --submit
//   node src/runFinalHygieneTest8.js --collect
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

const MODEL = 'gemini-3.1-flash-lite-image';
const PROVIDER = 'Google Gemini API direct';
const BATCH_IMAGE_OUTPUT_PRICE_USD = 0.0168;

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');
const SPECS = path.join(ROOT, 'specs');
const CATALOG = path.join(ROOT, 'catalog');
const CFG_PATH = path.join(CATALOG, 'final_hygiene_test_8_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'final_hygiene_test_8_v1');

const BATCH_ENDPOINT = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:batchGenerateContent`;

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};

function sha256Buffer(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

function outputFilenameFor(id) {
  return `${id.replaceAll('.', '__')}__gemini_3_1_flash_lite_image.jpg`;
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

function compileRows(ids) {
  const specCtx = loadSpecCtx();
  const bridge = buildCatalogRecipeBridge();
  const eligibleById = new Map(bridge.eligible.map(r => [r.canonical_interest_id, r]));
  const quarantined = specCtx.guardrails?.quarantined || {};

  return ids.map((id, index) => {
    if (Object.hasOwn(quarantined, id)) throw new Error(`Refusing quarantined canonical: ${id}`);
    const row = eligibleById.get(id);
    if (!row) throw new Error(`Unknown or non-eligible canonical interest: ${id}`);
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
    return {
      canonical_interest_id: id,
      title: hobby.title,
      runtime_category: row.runtime_category,
      runtime_cluster: row.runtime_cluster,
      archetype: compiled.effective.archetype,
      visual_variant: compiled.variant.id,
      diversity_profile: compiled.diversityProfile,
      effects_profile: compiled.diversityProfile?.effects_intensity || null,
      final_prompt: compiled.compiledPrompt,
      model: MODEL,
      provider: PROVIDER,
      request_index: index,
      request_key: id,
      output_filename: outputFilenameFor(id),
    };
  });
}

function buildBatchPayload(rows) {
  return {
    batch: {
      display_name: 'zync-final-hygiene-test-8-v1',
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

async function submit(rows) {
  const payload = buildBatchPayload(rows);
  writeJson(path.join(OUT_DIR, 'requests.json'), {
    model: MODEL,
    provider: PROVIDER,
    generated_at: new Date().toISOString(),
    rows,
    payload,
  });
  const result = await jsonFetch(BATCH_ENDPOINT, { method: 'POST', headers: apiHeaders(), body: JSON.stringify(payload) });
  if (!result?.name) throw new Error('Batch submission returned no job name.');
  writeJson(path.join(OUT_DIR, 'batch_job.json'), {
    model: MODEL,
    provider: PROVIDER,
    submitted_at: new Date().toISOString(),
    batch_name: result.name,
    raw: result,
  });
  console.log('Submitted direct Google final-hygiene-test batch:', result.name);
}

async function fetchStatusToScratchFile(statusUrl) {
  const res = await fetch(statusUrl, { method: 'GET', headers: apiHeaders() });
  if (!res.ok || !res.body) {
    const text = await res.text().catch(() => '');
    throw new Error('Gemini API HTTP ' + res.status + ': ' + text.slice(0, 2000));
  }
  const scratchPath = path.join(os.tmpdir(), `zync-final-hygiene-status-${crypto.randomBytes(8).toString('hex')}.json`);
  const nodeReadable = Readable.fromWeb(res.body);
  const writeStream = fs.createWriteStream(scratchPath);
  nodeReadable.pipe(writeStream);
  await finished(writeStream);
  return scratchPath;
}

async function readStatusSummary(scratchPath) {
  let summary = null;
  await new Promise((resolve, reject) => {
    const pipeline = chain([fs.createReadStream(scratchPath), parser(), ignore({ filter: /inlinedResponses/ }), streamValues()]);
    pipeline.on('data', ({ value }) => { summary = value; });
    pipeline.on('end', resolve);
    pipeline.on('error', reject);
  });
  return summary;
}

async function forEachInlineResponse(scratchPath, onItem) {
  await new Promise((resolve, reject) => {
    const pipeline = chain([fs.createReadStream(scratchPath), parser(), pick({ filter: 'response.inlinedResponses.inlinedResponses' }), streamArray()]);
    pipeline.on('data', ({ value }) => onItem(value));
    pipeline.on('end', resolve);
    pipeline.on('error', reject);
  });
}

async function collect(rows) {
  const jobPath = path.join(OUT_DIR, 'batch_job.json');
  if (!fs.existsSync(jobPath)) throw new Error('No batch_job.json found. Run --submit first.');
  const job = readJson(jobPath);
  const statusUrl = 'https://generativelanguage.googleapis.com/v1beta/' + job.batch_name;

  const scratchPath = await fetchStatusToScratchFile(statusUrl);
  try {
    const statusSummary = await readStatusSummary(scratchPath);
    writeJson(path.join(OUT_DIR, 'batch_status.json'), redactLargeStrings(statusSummary));

    const state = statusSummary?.metadata?.state || statusSummary?.state || statusSummary?.batch?.state || null;
    console.log('Batch state:', state || 'unknown');
    const SUCCESS_STATES = new Set(['JOB_STATE_SUCCEEDED', 'BATCH_STATE_SUCCEEDED']);
    if (!SUCCESS_STATES.has(state)) {
      console.log('No images written. Re-run --collect after the batch succeeds.');
      return;
    }

    const imagesDir = path.join(OUT_DIR, 'images');
    fs.mkdirSync(imagesDir, { recursive: true });
    const rowsById = new Map(rows.map(r => [r.canonical_interest_id, r]));
    const nowIso = new Date().toISOString();
    const entriesById = new Map();
    let succeeded = 0, failedTransient = 0, failedContent = 0;

    await forEachInlineResponse(scratchPath, wrapper => {
      const key = wrapper?.metadata?.key;
      const row = key ? rowsById.get(key) : null;
      if (!row) { console.warn(`Skipping response with unrecognized/missing metadata.key: ${key}`); return; }

      const response = extractResponse(wrapper);
      const image = extractImagePart(response);
      if (!image) {
        const finishReason = response?.candidates?.[0]?.finishReason || response?.candidates?.[0]?.finish_reason || null;
        const errType = finishReason && String(finishReason).toUpperCase().includes('SAFETY') ? 'content_policy' : classifyError(JSON.stringify(response || {}).slice(0, 300));
        const status_ = errType === 'content_policy' ? 'failed_content' : 'failed_transient';
        if (status_ === 'failed_content') failedContent += 1; else failedTransient += 1;
        entriesById.set(row.canonical_interest_id, {
          ...row, google_batch_name: job.batch_name, file_sha256: null, generated_at: nowIso,
          status: status_, last_error: `no image inlineData in response (finishReason=${finishReason || 'unknown'})`,
          estimated_cost_usd: null,
        });
        return;
      }
      const ext = extensionForMime(image.mime_type);
      const filename = row.output_filename.replace(/\.jpg$/, `.${ext}`);
      const localPath = path.join(imagesDir, filename);
      const buffer = Buffer.from(image.data, 'base64');
      fs.writeFileSync(localPath, buffer);
      succeeded += 1;
      const { final_prompt, ...rowMeta } = row;
      entriesById.set(row.canonical_interest_id, {
        ...rowMeta, google_batch_name: job.batch_name, output_filename: filename,
        local_image_path: path.relative(REPO_ROOT, localPath).replace(/\\/g, '/'),
        file_sha256: sha256Buffer(buffer), mime_type: image.mime_type, generated_at: nowIso,
        status: 'succeeded', last_error: null, estimated_cost_usd: BATCH_IMAGE_OUTPUT_PRICE_USD,
        qa_status: 'pending_human_review',
      });
    });

    for (const row of rows) {
      if (entriesById.has(row.canonical_interest_id)) continue;
      failedTransient += 1;
      const { final_prompt, ...rowMeta } = row;
      entriesById.set(row.canonical_interest_id, {
        ...rowMeta, google_batch_name: job.batch_name, file_sha256: null, generated_at: nowIso,
        status: 'failed_transient', last_error: 'no response item found for this canonical_interest_id in the batch status stream',
        estimated_cost_usd: null,
      });
    }

    const entries = rows.map(r => entriesById.get(r.canonical_interest_id));
    const manifest = {
      version: 'final_hygiene_test_8_v1',
      generated_at: nowIso,
      provider: PROVIDER,
      model: MODEL,
      fal_ai: false,
      google_batch_name: job.batch_name,
      expected_entries: rows.length,
      succeeded, failed_transient: failedTransient, failed_content: failedContent,
      estimated_cost_usd: Number((succeeded * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)),
      entries,
    };
    writeJson(path.join(OUT_DIR, 'manifest.json'), manifest);
    console.log(`Collected: succeeded=${succeeded} failed_transient=${failedTransient} failed_content=${failedContent} / ${rows.length}`);
  } finally {
    fs.rm(scratchPath, { force: true }, () => {});
  }
}

async function main() {
  const args = new Set(process.argv.slice(2));
  const config = readJson(CFG_PATH);
  const ids = config.ids;
  if (!Array.isArray(ids) || ids.length !== 8 || new Set(ids).size !== 8) {
    throw new Error('Final hygiene test config must contain exactly 8 unique hobby IDs.');
  }
  const QUARANTINED = new Set(['sports.american_football', 'technology.robotics']);
  for (const id of ids) if (QUARANTINED.has(id)) throw new Error('Refusing quarantined canonical: ' + id);

  const rows = compileRows(ids);
  if (rows.length !== 8) throw new Error('Expected 8 compiled rows, got ' + rows.length);

  if (args.has('--dry-run') || (!args.has('--submit') && !args.has('--collect'))) {
    console.log(`Dry run: 8 direct-Google final-hygiene-test prompts; estimated cost=$${(8 * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)}.`);
    for (const row of rows) {
      const hasBusinessPolicy = row.final_prompt.includes('This is a business, startup, career, finance, or professional-planning scene');
      const hasDevicePolicy = row.final_prompt.includes('fruit-shaped or bitten-fruit silhouette');
      console.log(`\n--- ${row.title} [${row.canonical_interest_id}] / ${row.archetype} / business_policy=${hasBusinessPolicy} device_policy=${hasDevicePolicy} ---`);
    }
    return;
  }
  if (args.has('--submit')) await submit(rows);
  if (args.has('--collect')) await collect(rows);
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});

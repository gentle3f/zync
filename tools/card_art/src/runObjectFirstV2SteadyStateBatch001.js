// Zync Object-First V2 Steady-State BATCH-001: AUTHORIZED first real
// steady-state production batch, released after Sentinel-8
// PASS_REMEDIATION_VALIDATED (commit 2fb7c5d) and the user's explicit
// acceptance of both automotive Sentinel outputs. Generates exactly the
// 120 ids from the committed object_first_v2_steady_state_batch001_v1.json.
//
// Per-card production candidate version preserved exactly as recorded in
// the queue - 118 cards on v2.4, 2 cards (learning.business_books,
// transport.sports_cars) on v2.5. Never flattened.
//
// Hard-excluded and refused if present: business.startups (reusable),
// music.rock/motorsport.cars (Canary-24 QA-quarantined), arts.illustration
// (repaired but held), wellness.stretching (held),
// sports.american_football/technology.robotics (catalog quarantine).
//
// CRITICAL: this runner does NOT compile prompts. It loads the frozen
// final_compiled_prompt strings verbatim from
// output/object_first_v2_steady_state_batch001_v1/frozen_prompts_v1.json
// and cross-checks each one's live SHA256 against the config's recorded
// prompt_sha256 before submission.
//
// GENERATION ONLY: per the standing operating rule, this run performs no
// visual inspection of the collected images. Only technical/metadata
// validation is recorded. Visual review happens separately via ChatGPT.
// No auto-chain into Batch-002.
//
// Usage:
//   node src/runObjectFirstV2SteadyStateBatch001.js --dry-run
//   node src/runObjectFirstV2SteadyStateBatch001.js --submit
//   node src/runObjectFirstV2SteadyStateBatch001.js --collect
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

const MODEL = 'gemini-3.1-flash-lite-image';
const PROVIDER = 'Google Gemini API direct';
const BATCH_IMAGE_OUTPUT_PRICE_USD = 0.0168;
const EXPECTED_COUNT = 120;

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');
const CATALOG = path.join(ROOT, 'catalog');
const CFG_PATH = path.join(CATALOG, 'object_first_v2_steady_state_batch001_v1.json');
const FROZEN_PROMPTS_PATH = path.join(ROOT, 'output', 'object_first_v2_steady_state_batch001_v1', 'frozen_prompts_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_v2_steady_state_batch001_v1');

const BATCH_ENDPOINT = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:batchGenerateContent`;

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};

function sha256Buffer(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}
function sha256Text(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}
function outputFilenameFor(id) {
  return `${id.replaceAll('.', '__')}__object_first_v2_steady_state_batch001__gemini_3_1_flash_lite_image.jpg`;
}

function loadFrozenRows(config) {
  const frozen = readJson(FROZEN_PROMPTS_PATH);
  const frozenById = new Map(frozen.map(f => [f.canonical_interest_id, f]));

  return config.cards.map((card, index) => {
    const frozenEntry = frozenById.get(card.id);
    if (!frozenEntry) throw new Error(`No frozen compiled prompt found for "${card.id}" in ${FROZEN_PROMPTS_PATH}`);
    const liveSha = sha256Text(frozenEntry.final_compiled_prompt);
    if (liveSha !== card.prompt_sha256) {
      throw new Error(`SHA256 mismatch for "${card.id}" (version ${card.production_candidate_version}): recorded=${card.prompt_sha256} recomputed=${liveSha}. Refusing to submit a prompt that may have drifted from the audited text.`);
    }
    return {
      canonical_interest_id: card.id,
      title: card.title,
      archetype: card.archetype,
      production_candidate_version: card.production_candidate_version,
      structural_containment_rule_id: card.structural_containment_rule_id,
      confidence: card.confidence,
      composition_archetype: card.composition_archetype,
      palette_lighting_route: card.palette_lighting_route,
      effect_level: card.effect_level,
      scene_family: card.scene_family,
      text_mode: card.text_mode,
      physical_logic_domain: card.physical_logic_domain,
      interaction_support_mode: card.interaction_support_mode,
      final_prompt: frozenEntry.final_compiled_prompt,
      prompt_sha256: card.prompt_sha256,
      model: MODEL,
      provider: PROVIDER,
      request_index: index,
      request_key: card.id,
      output_filename: outputFilenameFor(card.id),
    };
  });
}

function buildBatchPayload(rows) {
  return {
    batch: {
      display_name: 'zync-object-first-v2-steady-state-batch001-v1',
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
    model: MODEL, provider: PROVIDER, generated_at: new Date().toISOString(), rows, payload,
  });
  const result = await jsonFetch(BATCH_ENDPOINT, { method: 'POST', headers: apiHeaders(), body: JSON.stringify(payload) });
  if (!result?.name) throw new Error('Batch submission returned no job name.');
  writeJson(path.join(OUT_DIR, 'batch_job.json'), {
    model: MODEL, provider: PROVIDER, submitted_at: new Date().toISOString(), batch_name: result.name, raw: result,
  });
  console.log('Submitted direct Google steady-state Batch-001:', result.name);
}

async function fetchStatusToScratchFile(statusUrl) {
  const res = await fetch(statusUrl, { method: 'GET', headers: apiHeaders() });
  if (!res.ok || !res.body) {
    const text = await res.text().catch(() => '');
    throw new Error('Gemini API HTTP ' + res.status + ': ' + text.slice(0, 2000));
  }
  const scratchPath = path.join(os.tmpdir(), `zync-object-first-v2-steadystate001-status-${crypto.randomBytes(8).toString('hex')}.json`);
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
        entriesById.set(row.canonical_interest_id, { ...row, file_sha256: null, generated_at: nowIso, status: status_, last_error: `no image inlineData in response (finishReason=${finishReason || 'unknown'})`, estimated_cost_usd: null });
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
        ...rowMeta, output_filename: filename,
        local_image_path: path.relative(REPO_ROOT, localPath).replace(/\\/g, '/'),
        file_sha256: sha256Buffer(buffer), mime_type: image.mime_type, generated_at: nowIso,
        status: 'succeeded', last_error: null, estimated_cost_usd: BATCH_IMAGE_OUTPUT_PRICE_USD, qa_status: 'pending_external_visual_review_chatgpt',
      });
    });

    for (const row of rows) {
      if (entriesById.has(row.canonical_interest_id)) continue;
      failedTransient += 1;
      const { final_prompt, ...rowMeta } = row;
      entriesById.set(row.canonical_interest_id, { ...rowMeta, file_sha256: null, generated_at: nowIso, status: 'failed_transient', last_error: 'no response item found for this canonical_interest_id in the batch status stream', estimated_cost_usd: null });
    }

    const entries = rows.map(r => entriesById.get(r.canonical_interest_id));
    const manifest = {
      version: 'object_first_v2_steady_state_batch001_v1', generated_at: nowIso, provider: PROVIDER, model: MODEL, fal_ai: false,
      google_batch_name: job.batch_name, expected_entries: rows.length, succeeded, failed_transient: failedTransient, failed_content: failedContent,
      estimated_cost_usd: Number((succeeded * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)), entries,
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
  const ids = config.cards.map(c => c.id);
  if (!Array.isArray(ids) || ids.length !== EXPECTED_COUNT || new Set(ids).size !== EXPECTED_COUNT) {
    throw new Error(`Steady-state Batch-001 config must contain exactly ${EXPECTED_COUNT} unique hobby IDs.`);
  }
  const FORBIDDEN = new Set(['business.startups', 'music.rock', 'motorsport.cars', 'sports.american_football', 'technology.robotics', 'wellness.stretching', 'arts.illustration']);
  for (const id of ids) if (FORBIDDEN.has(id)) throw new Error('Refusing forbidden/held/quarantined canonical: ' + id);

  const queue = readJson(path.join(CATALOG, 'production_queue_v2_object_first.json'));
  const queueById = new Map(queue.rows.map(r => [r.canonical_id, r]));
  for (const id of ids) {
    const row = queueById.get(id);
    if (!row) throw new Error(`Batch-001 id not found in production queue: ${id}`);
    if (row.generation_hold_reason) throw new Error(`Refusing held id (${row.generation_hold_reason}): ${id}`);
  }

  const rows = loadFrozenRows(config);
  if (rows.length !== EXPECTED_COUNT) throw new Error(`Expected ${EXPECTED_COUNT} frozen rows, got ${rows.length}`);

  if (args.has('--dry-run') || (!args.has('--submit') && !args.has('--collect'))) {
    console.log(`Dry run: ${EXPECTED_COUNT} direct-Google steady-state Batch-001 prompts (SHA256-verified); estimated cost=$${(EXPECTED_COUNT * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)}.`);
    const versionCounts = rows.reduce((acc, r) => { acc[r.production_candidate_version] = (acc[r.production_candidate_version] || 0) + 1; return acc; }, {});
    console.log('Version distribution:', JSON.stringify(versionCounts));
    for (const row of rows.slice(0, 3)) {
      console.log(`\n--- ${row.canonical_interest_id} / version=${row.production_candidate_version} / scene_family=${row.scene_family} / sha256=${row.prompt_sha256.slice(0, 16)}... ---`);
      console.log(row.final_prompt.slice(0, 200) + '...');
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

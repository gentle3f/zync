// D4 cross-category durability test: 12 hobbies via the REAL production
// compiler (global_style_v1.json now = D4, hobby_overrides_v1.json now
// includes the learning.philosophy fix), through Gemini 3.1 Flash Lite
// Image direct (no fal.ai). This is NOT an isolated experiment override -
// D4 has been promoted to the actual production global style this
// checkpoint, so this runner compiles exactly the way normal production
// generation would.
//
// Usage:
//   node src/runD4Durability12.js --dry-run
//   node src/runD4Durability12.js --submit
//   node src/runD4Durability12.js --collect
//
// Requires GEMINI_API_KEY for --submit/--collect.

import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';
import { compileHobbyPrompt } from './buildPromptV1.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');
const CFG_PATH = path.join(ROOT, 'catalog', 'style_d4_durability_12_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'style_d4_durability_12_v1');
const IMAGES_DIR = path.join(OUT_DIR, 'images');
const REQUESTS_PATH = path.join(OUT_DIR, 'requests.json');
const JOB_PATH = path.join(OUT_DIR, 'batch_job.json');
const STATUS_PATH = path.join(OUT_DIR, 'batch_status.json');
const MANIFEST_PATH = path.join(OUT_DIR, 'manifest.json');

const MODEL = 'gemini-3.1-flash-lite-image';
const BATCH_ENDPOINT =
  'https://generativelanguage.googleapis.com/v1beta/models/' +
  MODEL +
  ':batchGenerateContent';

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};

function loadCompileContext() {
  const specs = path.join(ROOT, 'specs');
  const catalog = path.join(ROOT, 'catalog');
  return {
    globalStyle: readJson(path.join(specs, 'global_style_v1.json')),
    archetypes: readJson(path.join(specs, 'archetypes_v1.json')),
    variants: readJson(path.join(specs, 'archetype_variants_v1.json')),
    categories: readJson(path.join(specs, 'category_modifiers_v1.json')),
    subcategories: readJson(path.join(specs, 'subcategory_modifiers_v1.json')),
    overrides: readJson(path.join(catalog, 'hobby_overrides_v1.json')),
    flagship: readJson(path.join(catalog, 'flagship_overrides_v1.json')),
  };
}

function compileRows(ids) {
  const ctx = loadCompileContext();
  const bridge = buildCatalogRecipeBridge();
  const eligible = new Map(bridge.eligible.map(row => [row.canonical_interest_id, row]));
  const rows = [];
  for (const id of ids) {
    const row = eligible.get(id);
    if (!row) throw new Error('Unknown or non-eligible canonical interest: ' + id);
    const hobby = row.recipe;
    const overrideKey = row.source_recipe_id || hobby.id;
    const compiled = compileHobbyPrompt({
      hobby,
      globalStyle: ctx.globalStyle,
      archetypes: ctx.archetypes,
      variants: ctx.variants,
      categories: ctx.categories,
      subcategories: ctx.subcategories,
      override: ctx.overrides.overrides?.[overrideKey] || null,
      flagshipOverride: ctx.flagship.flagship?.[overrideKey] || null,
    });
    rows.push({
      canonical_interest_id: id,
      title: hobby.title,
      runtime_category: row.runtime_category,
      runtime_cluster: row.runtime_cluster,
      recipe_source: row.recipe_source,
      archetype: compiled.effective.archetype,
      visual_variant: compiled.variant.id,
      final_prompt: compiled.compiledPrompt,
    });
  }
  return rows;
}

function buildBatchPayload(rows) {
  return {
    batch: {
      display_name: 'zync-d4-durability-12-v1',
      input_config: {
        requests: {
          requests: rows.map((row, index) => ({
            request: {
              contents: [{
                role: 'user',
                parts: [{ text: row.final_prompt }],
              }],
              generationConfig: {
                responseModalities: ['Image'],
                imageConfig: {
                  aspectRatio: '2:3',
                },
              },
            },
            metadata: {
              key: row.canonical_interest_id,
              index,
            },
          })),
        },
      },
    },
  };
}

function apiHeaders() {
  const key = process.env.GEMINI_API_KEY;
  if (!key) throw new Error('GEMINI_API_KEY is not set.');
  return {
    'x-goog-api-key': key,
    'Content-Type': 'application/json',
  };
}

async function jsonFetch(url, options = {}) {
  const res = await fetch(url, options);
  const text = await res.text();
  let parsed;
  try { parsed = JSON.parse(text); } catch { parsed = { raw: text }; }
  if (!res.ok) {
    throw new Error('Gemini API HTTP ' + res.status + ': ' + JSON.stringify(parsed));
  }
  return parsed;
}

function findInlineResponses(status) {
  return (
    status?.response?.inlinedResponses?.inlinedResponses ||
    status?.response?.inlinedResponses ||
    status?.metadata?.output?.inlinedResponses?.inlinedResponses ||
    status?.metadata?.output?.inlinedResponses ||
    status?.dest?.inlinedResponses?.inlinedResponses ||
    status?.dest?.inlinedResponses ||
    status?.output?.inlinedResponses?.inlinedResponses ||
    status?.output?.inlinedResponses ||
    status?.batch?.dest?.inlinedResponses?.inlinedResponses ||
    status?.batch?.dest?.inlinedResponses ||
    []
  );
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
        return {
          data: inline.data,
          mime_type: inline.mimeType || inline.mime_type,
        };
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

async function submit(rows) {
  const payload = buildBatchPayload(rows);
  writeJson(REQUESTS_PATH, {
    model: MODEL,
    provider: 'Google Gemini API direct',
    generated_at: new Date().toISOString(),
    rows,
    payload,
  });

  const result = await jsonFetch(BATCH_ENDPOINT, {
    method: 'POST',
    headers: apiHeaders(),
    body: JSON.stringify(payload),
  });
  if (!result?.name) throw new Error('Batch submission returned no job name.');
  writeJson(JOB_PATH, {
    model: MODEL,
    provider: 'Google Gemini API direct',
    submitted_at: new Date().toISOString(),
    batch_name: result.name,
    raw: result,
  });
  console.log('Submitted direct Google Gemini batch:', result.name);
}

async function collect(rows) {
  if (!fs.existsSync(JOB_PATH)) {
    throw new Error('No batch_job.json found. Run --submit first.');
  }
  const job = readJson(JOB_PATH);
  const statusUrl = 'https://generativelanguage.googleapis.com/v1beta/' + job.batch_name;
  const status = await jsonFetch(statusUrl, {
    method: 'GET',
    headers: apiHeaders(),
  });
  writeJson(STATUS_PATH, redactLargeStrings(status));

  const state =
    status?.metadata?.state ||
    status?.state ||
    status?.batch?.state ||
    null;
  console.log('Batch state:', state || 'unknown');
  const SUCCESS_STATES = new Set(['JOB_STATE_SUCCEEDED', 'BATCH_STATE_SUCCEEDED']);
  if (!SUCCESS_STATES.has(state)) {
    console.log('No images written. Re-run --collect after the batch succeeds.');
    return;
  }

  const responses = findInlineResponses(status);
  if (!Array.isArray(responses) || responses.length !== rows.length) {
    throw new Error(
      'Expected ' + rows.length + ' inline responses but found ' +
      (Array.isArray(responses) ? responses.length : 'non-array'),
    );
  }

  fs.mkdirSync(IMAGES_DIR, { recursive: true });
  const entries = [];
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const wrapper = responses[i];
    const response = extractResponse(wrapper);
    const image = extractImagePart(response);
    if (!image) {
      entries.push({
        ...row,
        model: MODEL,
        provider: 'Google Gemini API direct',
        batch_name: job.batch_name,
        response_index: i,
        metadata: wrapper?.metadata || null,
        image_written: false,
        error: 'No image inlineData found in response',
      });
      continue;
    }
    const ext = extensionForMime(image.mime_type);
    const filename =
      row.canonical_interest_id.replaceAll('.', '__') +
      '__gemini_3_1_flash_lite_image.' + ext;
    const localPath = path.join(IMAGES_DIR, filename);
    fs.writeFileSync(localPath, Buffer.from(image.data, 'base64'));
    entries.push({
      ...row,
      model: MODEL,
      provider: 'Google Gemini API direct',
      batch_name: job.batch_name,
      response_index: i,
      metadata: wrapper?.metadata || null,
      mime_type: image.mime_type,
      local_image_path: path.relative(REPO_ROOT, localPath).replace(/\\/g, '/'),
      estimated_batch_image_output_cost_usd: 0.0168,
      image_written: true,
      qa_status: 'pending_human_review',
    });
  }

  const manifest = {
    version: 'style_d4_durability_12_v1',
    generated_at: new Date().toISOString(),
    provider: 'Google Gemini API direct',
    model: MODEL,
    fal_ai: false,
    batch_name: job.batch_name,
    expected_entries: rows.length,
    written_images: entries.filter(x => x.image_written).length,
    estimated_batch_image_output_cost_usd:
      Number((entries.filter(x => x.image_written).length * 0.0168).toFixed(4)),
    note: 'D4 cross-category durability test using the real production compiler (global_style_v1.json = D4, hobby_overrides_v1.json includes the learning.philosophy fix and new global_brand_safety_policy).',
    entries,
  };
  writeJson(MANIFEST_PATH, manifest);
  console.log(
    'Collected ' + manifest.written_images + '/' + rows.length +
    ' images; manifest=' + path.relative(ROOT, MANIFEST_PATH),
  );
}

async function main() {
  const args = new Set(process.argv.slice(2));
  const config = readJson(CFG_PATH);
  const ids = config.ids;
  if (!Array.isArray(ids) || ids.length !== 12 || new Set(ids).size !== 12) {
    throw new Error('D4 durability config must contain exactly 12 unique hobby IDs.');
  }
  const QUARANTINED = new Set(['sports.american_football', 'technology.robotics']);
  for (const id of ids) {
    if (QUARANTINED.has(id)) throw new Error('Refusing quarantined canonical: ' + id);
  }
  const rows = compileRows(ids);
  if (rows.length !== 12) throw new Error('Expected 12 compiled rows, got ' + rows.length);

  if (args.has('--dry-run') || (!args.has('--submit') && !args.has('--collect'))) {
    console.log(
      'Dry run: 12 direct-Google Gemini 3.1 Flash Lite D4-durability prompts (real production compiler); ' +
      'Batch API estimated image-output cost=$' +
      config.expected.estimated_image_output_cost_usd.toFixed(4) +
      ' plus input tokens.',
    );
    for (const row of rows) {
      console.log(
        '\n--- ' + row.title + ' [' + row.canonical_interest_id + '] / ' +
        row.archetype + ' / ' + row.visual_variant + ' ---\n' +
        row.final_prompt,
      );
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

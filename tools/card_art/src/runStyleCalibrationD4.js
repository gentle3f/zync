// House-style D4 calibration: 6 hobbies x 1 Japanese special-illustration/
// full-art global-style candidate = 6 requests, via Gemini 3.1 Flash Lite
// Image direct (no fal.ai). Follows the D1/D2/D3 round, where D3 (the
// strongest of the three) still read as ordinary anime lifestyle
// illustration rather than an iconic special-illustration moment.
//
// IMPORTANT: this does NOT touch tools/card_art/specs/global_style_v1.json.
// The D4 style block is injected as an isolated in-memory globalStyle
// clone at compile time only, for this experiment run.
//
// Usage:
//   node src/runStyleCalibrationD4.js --dry-run
//   node src/runStyleCalibrationD4.js --submit
//   node src/runStyleCalibrationD4.js --collect
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
const CFG_PATH = path.join(ROOT, 'catalog', 'style_calibration_d4_6_v1.json');
const BLOCKS_PATH = path.join(ROOT, 'catalog', 'style_calibration_d4_block_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'style_calibration_d4_6_v1');
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

// Builds an isolated globalStyle clone with ONLY the top-level `prompt`
// (the visual-style block) swapped out. global_text_policy,
// global_screen_policy, and global_negatives are untouched, so content
// safety / text-suppression / screen-suppression behavior is held
// constant - only visual style varies.
function styleVariantGlobalStyle(baseGlobalStyle, styleBlockPrompt) {
  return { ...baseGlobalStyle, prompt: styleBlockPrompt };
}

function compileRows(ids, styleVersions, blocks) {
  const ctx = loadCompileContext();
  const bridge = buildCatalogRecipeBridge();
  const eligible = new Map(bridge.eligible.map(row => [row.canonical_interest_id, row]));
  const rows = [];
  for (const id of ids) {
    const row = eligible.get(id);
    if (!row) throw new Error('Unknown or non-eligible canonical interest: ' + id);
    const hobby = row.recipe;
    const overrideKey = row.source_recipe_id || hobby.id;
    for (const styleKey of styleVersions) {
      const styleBlock = blocks.styles[styleKey];
      if (!styleBlock) throw new Error('Unknown style version: ' + styleKey);
      const styledGlobalStyle = styleVariantGlobalStyle(ctx.globalStyle, styleBlock.prompt);
      const compiled = compileHobbyPrompt({
        hobby,
        globalStyle: styledGlobalStyle,
        archetypes: ctx.archetypes,
        variants: ctx.variants,
        categories: ctx.categories,
        subcategories: ctx.subcategories,
        override: ctx.overrides.overrides?.[overrideKey] || null,
        flagshipOverride: ctx.flagship.flagship?.[overrideKey] || null,
      });
      rows.push({
        canonical_interest_id: id,
        style_version: styleKey,
        style_label: styleBlock.label,
        title: hobby.title,
        runtime_category: row.runtime_category,
        runtime_cluster: row.runtime_cluster,
        recipe_source: row.recipe_source,
        archetype: compiled.effective.archetype,
        visual_variant: compiled.variant.id,
        final_prompt: compiled.compiledPrompt,
      });
    }
  }
  return rows;
}

// Verifies each hobby's compiled prompt starts with exactly the injected
// D4 style block string (sections[0] in buildPromptV1.js). This is a
// weaker check than the A/B/C or D1/D2/D3 rounds (which compared multiple
// style versions against each other) since D4 has no sibling style version
// in this run to diff against - but it still catches any accidental
// mutation of the semantic sections by confirming the known-length style
// prefix is present verbatim before any paid call.
function verifyStyleBlockPrefix(rows, blocks) {
  for (const row of rows) {
    const stylePrompt = blocks.styles[row.style_version].prompt;
    if (!row.final_prompt.startsWith(stylePrompt)) {
      throw new Error(
        'Compiled prompt for ' + row.canonical_interest_id + '/' + row.style_version +
        ' does not start with its injected style block as expected.',
      );
    }
  }
  console.log('Style-block prefix check passed for all ' + rows.length + ' rows.');
}

function buildBatchPayload(rows) {
  return {
    batch: {
      display_name: 'zync-style-calibration-d4-6-v1',
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
              key: row.canonical_interest_id + '__' + row.style_version,
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

// Redacts any oversized string (base64 image payloads, this model's large
// thoughtSignature reasoning blobs) by length regardless of key name, so
// the on-disk forensic record stays small.
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

  const entries = [];
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const wrapper = responses[i];
    const response = extractResponse(wrapper);
    const image = extractImagePart(response);
    const styleDir = path.join(IMAGES_DIR, row.style_version);
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
    fs.mkdirSync(styleDir, { recursive: true });
    const ext = extensionForMime(image.mime_type);
    const filename =
      row.canonical_interest_id.replaceAll('.', '__') +
      '__' + row.style_version +
      '__gemini_3_1_flash_lite_image.' + ext;
    const localPath = path.join(styleDir, filename);
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
    version: 'style_calibration_d4_6_v1',
    generated_at: new Date().toISOString(),
    provider: 'Google Gemini API direct',
    model: MODEL,
    fal_ai: false,
    batch_name: job.batch_name,
    expected_entries: rows.length,
    written_images: entries.filter(x => x.image_written).length,
    estimated_batch_image_output_cost_usd:
      Number((entries.filter(x => x.image_written).length * 0.0168).toFixed(4)),
    note: 'Style D4: single special-illustration/full-art style candidate across 6 hobbies, successor to D1/D2/D3.',
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
  const blocks = readJson(BLOCKS_PATH);
  const ids = config.ids;
  const styleVersions = config.style_versions;
  if (!Array.isArray(ids) || ids.length !== 6 || new Set(ids).size !== 6) {
    throw new Error('Style calibration config must contain exactly 6 unique hobby IDs.');
  }
  if (!Array.isArray(styleVersions) || styleVersions.length !== 1) {
    throw new Error('D4 config must contain exactly 1 style version.');
  }
  const rows = compileRows(ids, styleVersions, blocks);
  if (rows.length !== 6) throw new Error('Expected 6 compiled rows, got ' + rows.length);

  verifyStyleBlockPrefix(rows, blocks);

  if (args.has('--dry-run') || (!args.has('--submit') && !args.has('--collect'))) {
    console.log(
      'Dry run: 6 direct-Google Gemini 3.1 Flash Lite D4 style-calibration prompts (6 hobbies x 1 style); ' +
      'Batch API estimated image-output cost=$' +
      config.expected.estimated_image_output_cost_usd.toFixed(4) +
      ' plus input tokens.',
    );
    for (const row of rows) {
      console.log(
        '\n--- ' + row.title + ' [' + row.canonical_interest_id + '] / style ' + row.style_version +
        ' (' + row.style_label + ') / ' + row.archetype + ' / ' + row.visual_variant + ' ---\n' +
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

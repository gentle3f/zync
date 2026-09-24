// Round 2 isolated, exploratory object-only visual-direction test:
// targeted re-test of the 2 partial failures from round 1
// (gaming.tabletop_rpg, food.dish.bun_cha) with stronger human-containment
// language, plus 6 new scope-expansion hobbies. Uses the real, unmodified
// D4 global style (global_style_v1.json's prompt field - read only, never
// written) plus a temporary experiment-only "no humans, object is hero"
// policy layered in via compileHobbyPrompt's existing experimentOverride
// parameter. Does NOT touch any production file, the production queue,
// launch-gate files, or quarantine status. Direct Google Gemini Batch API
// only, no fal.ai. Reuses the permanent streaming-collection fix from
// runProductionBatch.js.
//
// Usage:
//   node src/runObjectOnlyStyleTest8v2.js --dry-run
//   node src/runObjectOnlyStyleTest8v2.js --submit
//   node src/runObjectOnlyStyleTest8v2.js --collect
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
const CFG_PATH = path.join(CATALOG, 'object_only_style_test_8_v2_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'object_only_style_test_8_v2_v1');

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
  return `${id.replaceAll('.', '__')}__object_only_test_v2__gemini_3_1_flash_lite_image.jpg`;
}

// Global (this-experiment-only) human-exclusion + composition policy.
// Never written to any production spec file.
const OBJECT_ONLY_GLOBAL_POLICY =
  'EXPERIMENTAL DIRECTION FOR THIS IMAGE ONLY: this artwork must contain ZERO humans - no people, no faces, no heads, no hands, no arms, no legs, no body parts, no human silhouettes, no person-shaped shadows, no people visible in mirrors or through windows, no human reflections, no crowds, no tiny background people, and no implied person holding or using the object. If the hobby would normally show a person performing an action, communicate the activity instead through object motion, environmental movement, physical traces of action, dynamic staging, equipment position, material effects, and cause-and-effect cues. The object itself is the protagonist of the composition. Keep every strength of the house illustration language - polished Japanese commercial-illustration rendering, premium special-illustration feeling, clean attractive linework and shading, strong focal hierarchy, vivid but controlled color, dynamic perspective where appropriate, satisfying lighting, rich material detail, iconic memorable composition, collectible appeal, emotional atmosphere, full-bleed artwork, modern global appeal - but remove any dependence on an anime character. Do not render this as ordinary product photography, Amazon-style catalog photography, sterile stock photography, a flat corporate illustration, a technical diagram, or a generic 3D render; it must still read as a deliberately composed premium illustration. Build one dominant hero object or object cluster with immediately readable hobby identity, clear foreground/midground/background depth, environmental storytelling, and a visually memorable special moment - do not simply place an object centered against a plain background, compose an actual scene. Leave enough edge breathing room for a card frame to be overlaid later. Avoid clearly readable generated text when it is not semantically essential (no invented titles, fake slogans, readable labels, UI text, posters, brand names, logos, or manufacturer marks) - tiny non-legible print, abstract notation, or decorative marks are fine. The artwork itself must contain no card frame, no card border, no rarity badge, no title panel, no stats box, no TCG shell, no rounded card UI, and no watermark.';

const HOBBY_DIRECTIONS = {
  // --- Targeted re-tests: stronger human-containment language after the
  // round-1 findings (background silhouettes/diners leaked in via the
  // *environment*, not the hero object itself). ---
  'gaming.tabletop_rpg': {
    subject: 'A hero cluster of polyhedral dice mid-roll or glowing, detailed fantasy miniatures on a battle map, character sheets, a folded GM screen, spell-effect glow, tokens, and terrain pieces at the decisive peak of an adventure moment, with absolutely no people, no hands, and no background patrons anywhere in the frame',
    environment: 'A cozy tabletop gaming nook lit by warm candle or fire glow. If any tavern-like or gaming-room backdrop is visible, it must be shown completely EMPTY - no seated or standing figures, no silhouettes, no shadows suggesting a person, just architecture, furniture, and atmosphere. Do not include any readable sign, banner, or nameplate anywhere in the scene.',
    additions: 'This must feel energetic and magical purely through the objects - mid-air dice, a spell-glow effect rising from a miniature, dramatic warm lighting, dynamic staging - not through any implied human presence. Fantasy imagery is appropriate here since it belongs to the game itself, but there must be no human players, no fake TCG card frame, no readable rulebook or card text, and no recognizable game franchise or IP. If a bar or seating area is visible in the background, it must be explicitly empty of any patron, staff figure, silhouette, or shadow.',
  },
  'food.dish.bun_cha': {
    subject: 'A vivid Bun Cha meal - grilled pork, rice noodles, fresh herbs, dipping broth/sauce, and appropriate accompaniments - as the sole hero object, with absolutely no diners, patrons, or restaurant staff visible anywhere in the frame, foreground or background',
    environment: 'A warm, appetizing table styling scene. If a restaurant or street-food backdrop is visible, it must be shown completely EMPTY of people - no seated diners, no figures walking past, no blurred background patrons of any kind. Prefer a shallow depth of field or softly abstracted background that naturally de-emphasizes any background area rather than populating it with figures.',
    additions: 'No hands, no chopsticks being actively held - chopsticks may rest naturally on the table or bowl. Keep the mood joyful and appetizing through steam, glaze, ingredient arrangement, and color - not through any human presence, implied or visible, anywhere in the scene including the background.',
  },
  // --- Scope-expansion tests ---
  'books.reading': {
    subject: 'A cozy reading scene where an open book mid-page-turn, a small stack of other books, and a bookmark are the heroes, with absolutely no reader, no hands, and no person present',
    environment: 'A warm reading nook - a soft chair or window seat, a blanket, a lamp casting warm light, a steaming teacup or mug nearby, rain or dusk visible through a window - conveying that reading is actively happening',
    additions: 'The open book\'s pages must show only abstract, non-legible line-texture suggesting text, never a readable title, author name, or body copy. No readable text anywhere on any book cover or spine.',
  },
  'outdoors.camping': {
    subject: 'A glowing tent, a crackling campfire, and camping gear as the sole heroes of a night forest scene, with absolutely no campers or people visible',
    environment: 'A forest campsite at dusk or night - string lights or a lantern glowing warmly, gear (backpack, boots, cooking pot, folding chair) arranged naturally nearby, stars or moonlight above, smoke rising from the fire',
    additions: 'The scene must feel lived-in and recently active (an empty camp chair, a lantern still lit) without showing anyone. No readable gear-brand text or labels.',
  },
  'sports.badminton': {
    subject: 'A badminton racket and shuttlecock captured at the dramatic instant of impact or mid-flight, as the sole heroes, with absolutely no player visible',
    environment: 'An indoor badminton court - net, court lines, and court lighting clearly visible - with the racket staged at a dynamic angle and the shuttlecock frozen mid-arc showing motion trails',
    additions: 'Convey the decisive sporting moment purely through object motion (motion blur/trail on the shuttlecock, a taut net, vibrating racket strings) rather than any implied player. No brand marks or readable text on the racket or court.',
  },
  'food.coffee': {
    subject: 'A coffee brewing ritual staged as pure object storytelling - a pour-over dripper, a cup with visible crema/steam, beans, and a kettle - as the sole heroes, with absolutely no barista or person present',
    environment: 'A warm coffee-ritual scene on a wooden counter or table, morning light through a window, steam rising, coffee beans scattered artfully nearby',
    additions: 'No cafe patrons or background people. No readable menu, cafe signage, or packaging/bag text - beans and equipment must be generic and unbranded.',
  },
  'technology.3d_printing': {
    subject: 'A 3D printer actively mid-print, with the print head in motion and a partially-completed printed object visible on the bed, as the sole hero, with absolutely no maker or person present',
    environment: 'A workshop desk scene - filament spools, small hand tools, a tablet or monitor turned dark/off, printed sample objects nearby - conveying an active, ongoing print job',
    additions: 'No readable screen text or UI. No manufacturer branding or logos on the printer body - keep it a generic, plausible 3D printer design.',
  },
  'lifestyle.home_decor': {
    subject: 'A beautifully curated interior corner - furniture, textiles, a vase with flowers, art on the wall, warm lighting - as the sole hero, with absolutely no person present',
    environment: 'A tastefully styled living space corner with layered textures, warm natural light, and a sense of considered design',
    additions: 'No readable wall art text, no readable book titles on any visible shelf, no brand labels on furniture or decor.',
  },
};

function loadSpecCtx() {
  return {
    globalStyle: readJson(path.join(SPECS, 'global_style_v1.json')),
    archetypes: readJson(path.join(SPECS, 'archetypes_v1.json')),
    variants: readJson(path.join(SPECS, 'archetype_variants_v1.json')),
    categories: readJson(path.join(SPECS, 'category_modifiers_v1.json')),
    subcategories: readJson(path.join(SPECS, 'subcategory_modifiers_v1.json')),
    overrides: readJson(path.join(CATALOG, 'hobby_overrides_v1.json')),
    flagship: readJson(path.join(CATALOG, 'flagship_overrides_v1.json')),
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
    const direction = HOBBY_DIRECTIONS[id];
    if (!direction) throw new Error(`No object-only direction defined for: ${id}`);
    const hobby = row.recipe;
    const overrideKey = row.source_recipe_id || hobby.id;

    // experimentOverride: the established isolated-test mechanism in this
    // compiler (same one used by every prior calibration round). Applied
    // on top of the real, unmodified production hobby override, never
    // written back to any file. diversityProfiles is intentionally
    // omitted for this run - protagonist/build/hair language would
    // directly contradict the zero-humans rule under test.
    const experimentOverride = {
      subject: direction.subject,
      environment: direction.environment,
      override_prompt_additions: [OBJECT_ONLY_GLOBAL_POLICY, direction.additions],
    };

    const compiled = compileHobbyPrompt({
      hobby,
      globalStyle: specCtx.globalStyle,
      archetypes: specCtx.archetypes,
      variants: specCtx.variants,
      categories: specCtx.categories,
      subcategories: specCtx.subcategories,
      override: specCtx.overrides.overrides?.[overrideKey] || null,
      flagshipOverride: specCtx.flagship.flagship?.[overrideKey] || null,
      experimentOverride,
    });
    return {
      canonical_interest_id: id,
      title: hobby.title,
      runtime_category: row.runtime_category,
      runtime_cluster: row.runtime_cluster,
      archetype: compiled.effective.archetype,
      visual_variant: compiled.variant.id,
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
      display_name: 'zync-object-only-style-test-8-v2-v1',
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
  console.log('Submitted direct Google object-only-style-test batch:', result.name);
}

async function fetchStatusToScratchFile(statusUrl) {
  const res = await fetch(statusUrl, { method: 'GET', headers: apiHeaders() });
  if (!res.ok || !res.body) {
    const text = await res.text().catch(() => '');
    throw new Error('Gemini API HTTP ' + res.status + ': ' + text.slice(0, 2000));
  }
  const scratchPath = path.join(os.tmpdir(), `zync-object-only-v2-status-${crypto.randomBytes(8).toString('hex')}.json`);
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
        status: 'succeeded', last_error: null, estimated_cost_usd: BATCH_IMAGE_OUTPUT_PRICE_USD, qa_status: 'pending_human_review',
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
      version: 'object_only_style_test_8_v2_v1', generated_at: nowIso, provider: PROVIDER, model: MODEL, fal_ai: false,
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
  const ids = config.ids;
  if (!Array.isArray(ids) || ids.length !== 8 || new Set(ids).size !== 8) {
    throw new Error('Object-only style test v2 config must contain exactly 8 unique hobby IDs.');
  }
  const QUARANTINED = new Set(['sports.american_football', 'technology.robotics']);
  for (const id of ids) if (QUARANTINED.has(id)) throw new Error('Refusing quarantined canonical: ' + id);

  const rows = compileRows(ids);
  if (rows.length !== 8) throw new Error('Expected 8 compiled rows, got ' + rows.length);

  if (args.has('--dry-run') || (!args.has('--submit') && !args.has('--collect'))) {
    console.log(`Dry run: 8 direct-Google object-only-style-test-v2 prompts; estimated cost=$${(8 * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)}.`);
    for (const row of rows) {
      console.log(`\n--- ${row.title} [${row.canonical_interest_id}] / ${row.archetype} ---`);
      console.log(row.final_prompt);
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

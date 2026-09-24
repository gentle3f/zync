// Round 4 isolated, exploratory object-first visual-direction test:
// structural containment rescue test. Re-tests the 7 hobby IDs that
// showed human-leak failures in round 3 (media.movies, sports.running,
// outdoors.swimming, sports.basketball, gaming.board, technology.ai,
// pets.dogs), this time designing each scene from the start around an
// empty/private environment or before/after-action staging rather than a
// human-centered scene with the human subtracted. Uses the real,
// unmodified D4 global style (global_style_v1.json's prompt field - read
// only, never written) plus a temporary experiment-only "zero humans,
// non-human protagonist" policy layered in via compileHobbyPrompt's
// existing experimentOverride parameter. Does NOT touch any production
// file, the production queue, launch-gate files, or quarantine status.
// Direct Google Gemini Batch API only, no fal.ai. Reuses the permanent
// streaming-collection fix from runProductionBatch.js.
//
// GENERATION ONLY: per explicit operating instruction, this round performs
// no visual inspection of the collected images. Only technical/metadata
// validation (file existence, dimensions, format, size, hash, API
// success/failure, cost) is recorded. Visual review happens separately.
//
// Usage:
//   node src/runObjectFirstRound4.js --dry-run
//   node src/runObjectFirstRound4.js --submit
//   node src/runObjectFirstRound4.js --collect
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
const CFG_PATH = path.join(CATALOG, 'object_first_round4_containment_7_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_round4_containment_7_v1');

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
  return `${id.replaceAll('.', '__')}__object_first_r4__gemini_3_1_flash_lite_image.jpg`;
}

// Global (this-experiment-only) human-exclusion + anti-sameness policy.
// Never written to any production spec file.
const OBJECT_ONLY_GLOBAL_POLICY =
  'EXPERIMENTAL DIRECTION FOR THIS IMAGE ONLY: this artwork must contain ZERO real human presence - no people, no faces, no heads, no hands, no arms, no legs, no feet, no body parts, no human silhouettes, no crowds, no spectators, no players, no workers, no staff, no passersby, no portraits, no photographs of people, no screen images of people, no posters containing people, no reflections containing people, no person-shaped shadows, no cropped humans, and no distant background humans. This rule applies BOTH to the physical scene AND to any media, screen, or display shown inside the scene (a movie screen must not show a person; an AI visualization must not contain a human portrait). Hobby-intrinsic non-real human-LIKE objects are allowed only when unmistakably small physical game pieces with a visible base/stand - tabletop miniatures, chess pieces, figurines - never a dynamically-posed character with expressive facial detail. Real animals are allowed and encouraged where semantically appropriate (this is a zero-HUMANS rule, not a zero-living-beings rule). STRUCTURAL CONTAINMENT METHOD: do not design a normal human-centered scene and then try to remove the person. Design the scene from the start so no human presence is structurally expected - use empty spaces, private environments, equipment arranged before or after the activity, physical aftermath, object motion, environmental traces, activated machines, water movement, dust, light, empty seating, or abstract displays. Avoid public/social environments that naturally encourage populating the background with people. PHYSICAL-LOGIC RULE: do not solve zero-human scenes with invisible-human physics - do not show a tool, instrument, or vessel operating, pouring, or moving entirely on its own with no plausible cause. Allowed: a ball already in flight, water still moving from a very recent disturbance, fire burning, a machine operating automatically, bubbles, wind, net movement still settling, and other physical aftermath or already-in-motion states. CRITICAL ANTI-SAMENESS RULE: do not default to warm golden-hour light, a centered hero object, a cozy warm interior, or floating sparkle particles as the default treatment. Follow the specific composition and lighting direction given for this card exactly; deliberately vary angle, distance, time of day, and palette from a generic cozy-golden template. Sparkle/glow particle effects should be rare and only used when explicitly called for below - do not add them by default. Keep every strength of the house illustration language - polished Japanese commercial-illustration rendering, premium special-illustration feeling, clean attractive linework and shading, strong focal hierarchy, vivid but controlled color, satisfying lighting, rich material detail, iconic memorable composition, collectible appeal, emotional atmosphere, full-bleed artwork, modern global appeal - but remove any dependence on a human character. Do not render this as ordinary product photography, Amazon-style catalog photography, sterile stock photography, a flat corporate illustration, a technical diagram, or a generic 3D render; it must still read as a deliberately composed premium illustration, not a plain still life. Leave enough edge breathing room for a card frame to be overlaid later. Avoid clearly readable generated text when it is not semantically essential (no invented titles, fake slogans, readable signage, packaging copy, brand names, readable book titles, readable wall text, fake UI text, menu text, or labels) - tiny non-legible print, abstract notation, or decorative marks intrinsic to an object are fine. No recognizable brand marks of any kind - no shoe brand marks, sports brand marks, camera brand marks, vehicle manufacturer logos/badges, computer or device logos, or game franchise/team identities; keep every object a generic, original design. The artwork itself must contain no card frame, no Zync frame, no card border, no rarity badge, no title panel, no stats box, no TCG shell, no rounded card UI, and no watermark.';

const HOBBY_DIRECTIONS = {
  'media.movies': {
    subject: '(cinema) A completely empty cinema auditorium - rows of empty seats, a projector beam cutting through dust/haze, a scattered box of popcorn and unreadable ticket stubs near one seat, the screen glowing with ONLY non-human visual content such as a galaxy, an ocean horizon, drifting clouds, or abstract city lights at night',
    environment: 'STRUCTURAL CONTAINMENT: an empty theatre shown wide enough to show scale, the screen as the dominant light source glowing with pure landscape/abstract imagery, cool blue-purple projector light cutting through the dark haze',
    additions: 'Absolutely no actors, no silhouettes, no human figures anywhere on the screen content, and no film posters containing people anywhere in the theatre. The screen must show only galaxy, ocean, landscape, clouds, or abstract city-light imagery - never a figure, a face, or a story scene implying a person. No audience in any seat. Lighting is cool and dramatic, not warm/cozy. Hero: the cinematic environment itself.',
  },
  'sports.running': {
    subject: '(running) An AFTER-ACTION scene on an empty athletics track: a pair of generic unbranded running shoes resting side by side near the starting blocks, a stopwatch on the ground nearby, fresh shoe-print impressions in wet track material, scattered displaced track granules, and water droplets still settling on the surface',
    environment: 'STRUCTURAL CONTAINMENT: an empty outdoor or indoor athletics track shown from a low, dramatic ground-level perspective, wet track surface reflecting overcast daylight, lane markings receding into the distance, no runner anywhere in frame',
    additions: 'The shoes rest naturally on the ground - they are not in mid-air, not moving on their own, and have no legs, feet, or body attached. Energy comes entirely from the aftermath: fresh footprints, settling water droplets, a still-ticking stopwatch, scattered granules - not from an implied runner. Generic unbranded shoe design only, no manufacturer marks or stripes. No person anywhere on the track.',
  },
  'outdoors.swimming': {
    subject: '(swimming) An EMPTY swimming lane immediately after a swimmer has passed through: swim goggles and a swim cap resting on the starting block, taut lane-rope floats, a turbulent water trail with fading ripples receding down the lane, and a cluster of underwater bubbles still rising and dispersing',
    environment: 'STRUCTURAL CONTAINMENT: overhead/top-down camera looking straight down onto the pool lane from directly above, showing the empty starting block, lane lines, turquoise water texture, and sunlight refraction patterns on the pool floor below',
    additions: 'No swimmer, no human body, no arms, no legs, no hand, no underwater human shadow anywhere in frame - the turbulence and bubble trail imply a swimmer has JUST passed through, not that one is currently present. Cool turquoise/cyan palette, bright overhead sun - not warm or golden.',
  },
  'sports.basketball': {
    subject: '(basketball) A basketball captured mid-arc in flight toward a hoop inside a completely empty indoor practice gym, the net still rippling from motion, polished hardwood floor reflections below',
    environment: 'STRUCTURAL CONTAINMENT: a private, empty practice gym - plain walls, a single hoop, EMPTY bleachers shown clearly unoccupied (bare bench rows, no color-blocked crowd shapes, no blur suggesting figures), even gym lighting',
    additions: 'No player, no hands, no implied shooter, no crowd, no spectator-shaped blur anywhere in the bleachers, no jerseys, no team branding, no player posters on the walls. The bleachers must read unambiguously as empty rows, not as a blurred or distant crowd. Generic ball and generic court/hoop design only.',
  },
  'gaming.board': {
    subject: '(board games) A richly detailed board-game table mid-session inside a private, empty dedicated game room - a game board with strategic piece positions, dice, cards face-down, wooden tokens, small resource markers, and tabletop miniatures clearly mounted on visible bases',
    environment: 'STRUCTURAL CONTAINMENT: an angled, elevated three-quarter view where the tabletop dominates the composition; the background contains ONLY shelves, blank walls, a lamp, and generic game storage boxes - no seating area, no cafe, no social venue of any kind',
    additions: 'No people anywhere, including no background figures at any table or shelf. Human-shaped tabletop miniatures are allowed only if unmistakably miniature scale, clearly mounted on visible bases, and obviously physical game pieces rather than characters. No readable game text, no readable card or box text, no handwritten notes anywhere in frame. Entirely original/generic game design - no recognizable copyrighted board game.',
  },
  'technology.ai': {
    subject: '(artificial intelligence) A purely non-human AI visual metaphor: an interconnected neural-network graph of glowing nodes and light-lines, layered generative structures, and geometric inference pathways, rendered as if it were a piece of abstract data architecture rather than a device or a person',
    environment: 'STRUCTURAL CONTAINMENT: minimal hero composition - the vast majority of the frame is empty dark negative space; the glowing network/data structure and a hint of server-rack hardware silhouette sit small and precisely placed, not filling the frame; cool blue/cyan light only, no warm tones',
    additions: 'No person, no hands, no arms, no torso, no coder-at-a-monitor scene, no laptop operator, no human portraits or face thumbnails anywhere (including inside any floating result panel), no humanoid robot. No readable code, no readable UI text, no fake dashboard, no software/company logos. The AI system itself - the network structure and hardware - must be the sole protagonist.',
  },
  'pets.dogs': {
    subject: '(dogs) A real dog as the sole protagonist, resting or alertly looking toward a favorite toy, inside a PRIVATE fenced garden or a private home interior - a water bowl, scattered leaves or grass texture, a soft dog bed, toys nearby',
    environment: 'STRUCTURAL CONTAINMENT: option A - a fenced private garden with grass, leaves, and natural daylight; option B - a private home interior with a window showing ONLY garden, plants, rain, or sky (no street, no pedestrians visible through the window). Soft, intimate, moody light - cool rainy grey or gentle interior lamp glow.',
    additions: 'A real dog is required and is NOT a zero-human violation - this specifically re-tests whether a fully private, non-street environment removes the background-human leak seen in round 3. No human owner, no hands, no leash being held, no people or pedestrian silhouettes visible anywhere including through any window or reflection - if a window is shown, it must reveal only garden, plants, rain, or sky, never a street. No readable text on the collar or any dog gear.',
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
      display_name: 'zync-object-first-round4-containment-7-v1',
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
  const scratchPath = path.join(os.tmpdir(), `zync-object-first-round4-status-${crypto.randomBytes(8).toString('hex')}.json`);
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
      version: 'object_first_round4_containment_7_v1', generated_at: nowIso, provider: PROVIDER, model: MODEL, fal_ai: false,
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
  if (!Array.isArray(ids) || ids.length !== 7 || new Set(ids).size !== 7) {
    throw new Error('Object-first round 4 config must contain exactly 7 unique hobby IDs.');
  }
  const QUARANTINED = new Set(['sports.american_football', 'technology.robotics']);
  for (const id of ids) if (QUARANTINED.has(id)) throw new Error('Refusing quarantined canonical: ' + id);

  const rows = compileRows(ids);
  if (rows.length !== 7) throw new Error('Expected 7 compiled rows, got ' + rows.length);

  if (args.has('--dry-run') || (!args.has('--submit') && !args.has('--collect'))) {
    console.log(`Dry run: 7 direct-Google object-first-round4-containment prompts; estimated cost=$${(7 * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)}.`);
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

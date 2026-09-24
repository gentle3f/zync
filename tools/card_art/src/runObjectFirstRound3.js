// Round 3 isolated, exploratory object-first visual-direction test:
// cross-family stress test (12 new hobbies, several deliberately hard:
// cinema, AI, road trip, pets) plus a deliberate composition/lighting
// diversity router to test whether object-first develops a new sameness
// problem. Uses the real, unmodified D4 global style
// (global_style_v1.json's prompt field - read only, never written) plus a
// temporary experiment-only "zero humans, non-human protagonist" policy
// layered in via compileHobbyPrompt's existing experimentOverride
// parameter. Does NOT touch any production file, the production queue,
// launch-gate files, or quarantine status. Direct Google Gemini Batch API
// only, no fal.ai. Reuses the permanent streaming-collection fix from
// runProductionBatch.js.
//
// Usage:
//   node src/runObjectFirstRound3.js --dry-run
//   node src/runObjectFirstRound3.js --submit
//   node src/runObjectFirstRound3.js --collect
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
const CFG_PATH = path.join(CATALOG, 'object_first_round3_12_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'object_first_round3_12_v1');

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
  return `${id.replaceAll('.', '__')}__object_first_r3__gemini_3_1_flash_lite_image.jpg`;
}

// Global (this-experiment-only) human-exclusion + anti-sameness policy.
// Never written to any production spec file.
const OBJECT_ONLY_GLOBAL_POLICY =
  'EXPERIMENTAL DIRECTION FOR THIS IMAGE ONLY: this artwork must contain ZERO real human presence - no real people, no faces, no heads, no hands, no arms, no legs, no body parts, no human silhouettes, no person-shaped shadows, no people visible in mirrors or through windows, no human reflections, no crowds, no players, no diners, no staff, no athletes, no drivers, no photographers, no musicians, no background patrons, no cropped-off humans, and no implied person holding or using the object. Hobby-intrinsic non-real human-LIKE objects are allowed only when clearly objects, not living people - tabletop miniatures, chess pieces, figurines, statues - and they must read unambiguously as small objects/game pieces (visible base or stand, limited facial detail, static or clearly toy-like posing), never as a dynamically-posed character with expressive facial detail. Real animals are allowed and encouraged where semantically appropriate (this is a zero-HUMANS rule, not a zero-living-beings rule). If the hobby would normally show a person performing an action, communicate the activity instead through object motion, environmental movement, physical traces of action, dynamic staging, equipment position, material effects, and cause-and-effect cues - splash, dust, steam, vibration, bouncing, impact trails, moving leaves, rolling motion, displaced water, fluttering pages, airborne ingredients, tire tracks, a glowing active process, environmental aftermath, directional light, motion blur, reflections, dramatic perspective, activated/open equipment, or just-before/just-after action staging. The object, animal, or environment itself is the protagonist and every card must feel like a captured MOMENT, never an object sitting neatly and statically on a table. CRITICAL ANTI-SAMENESS RULE: do not default to warm golden-hour light, a centered hero object, a cozy warm interior, or floating sparkle particles - those must NOT be the default treatment across a set of cards. Follow the specific composition and lighting direction given for this card exactly; deliberately vary angle, distance, time of day, and palette from a generic cozy-golden template. Sparkle/glow particle effects should be rare and only used when explicitly called for below - do not add them by default. Keep every strength of the house illustration language - polished Japanese commercial-illustration rendering, premium special-illustration feeling, clean attractive linework and shading, strong focal hierarchy, vivid but controlled color, satisfying lighting, rich material detail, iconic memorable composition, collectible appeal, emotional atmosphere, full-bleed artwork, modern global appeal - but remove any dependence on an anime character. Do not render this as ordinary product photography, Amazon-style catalog photography, sterile stock photography, a flat corporate illustration, a technical diagram, or a generic 3D render; it must still read as a deliberately composed premium illustration, not a plain still life. Leave enough edge breathing room for a card frame to be overlaid later. Avoid clearly readable generated text when it is not semantically essential (no invented titles, fake slogans, readable signage, packaging copy, brand names, readable book titles, readable wall text, fake UI text, menu text, or labels) - tiny non-legible print, abstract notation, or decorative marks intrinsic to an object are fine. No recognizable brand marks of any kind - no shoe brand marks, sports brand marks, camera brand marks, vehicle manufacturer logos/badges, computer or device logos, or game franchise/team identities; keep every object a generic, original design. The artwork itself must contain no card frame, no Zync frame, no card border, no rarity badge, no title panel, no stats box, no TCG shell, no rounded card UI, and no watermark.';

const HOBBY_DIRECTIONS = {
  'media.movies': {
    subject: '(cinema) An illuminated cinema screen glowing in a dark theatre, with a projector beam cutting through visible dust/haze, rows of empty seats receding into darkness, a scattered film reel or ticket stubs with no readable text',
    environment: 'ARCHITECTURAL WIDE SHOT: a grand, dark, empty cinema hall shown from a wide architectural angle that shows scale - sweeping rows of seats, the screen glow as the only light source, cool blue-purple projector light cutting through the dark air',
    additions: 'No audience, no silhouettes in any seat. Do not generate movie characters, scenes, or any recognizable copyrighted film imagery on the screen itself - the screen should glow with abstract light/color, not a specific movie frame. Lighting is cool and dramatic, not warm/cozy.',
  },
  'sports.running': {
    subject: '(running) A pair of generic unbranded running shoes captured at the exact instant of a powerful stride impact on a wet running track, with displaced water droplets and track debris flying',
    environment: 'ACTION-FREEZE MOMENT: frozen mid-stride at the decisive instant of ground contact - motion blur on the trailing shoe, a spray of water/dust radiating from the impact point, lane markings streaking past, crisp neutral daylight (not golden hour)',
    additions: 'No runner, no legs, no implied person - the shoe appears to be moving under its own dynamic energy. Generic unbranded shoe design only, no manufacturer marks or stripes.',
  },
  'outdoors.swimming': {
    subject: '(swimming) Swim goggles, a swim cap, and taut lane-rope floats resting at the surface of a rippling pool, with a trail of bubbles and displaced water suggesting someone just dove in',
    environment: 'OVERHEAD / TOP-DOWN: camera looking straight down onto the pool surface from directly above, showing lane lines, turquoise water texture, ripple patterns, and sunlight refraction patterns on the pool floor below',
    additions: 'No swimmer, no human body in or near the water, no arms or legs. Cool turquoise/cyan palette, bright overhead sun - not warm or golden.',
  },
  'sports.basketball': {
    subject: '(basketball) A basketball captured mid-arc just before it drops through a hoop and net, with the net still rippling from a very recent previous shot',
    environment: 'LOW-ANGLE KINETIC: camera positioned low, looking dramatically upward at the hoop and ball against the sky/arena lights, exaggerated dynamic perspective, dramatic arena lighting with a mix of warm floor light and cool overhead light',
    additions: 'No player, no hands, no implied shooter. No team branding, no NBA-like logos, no readable arena signage or scoreboard text. Generic ball and generic court/hoop design only.',
  },
  'photography.general': {
    subject: '(photography) A generic camera lens shown in extreme macro close-up, aperture blades visible and slightly open, a reflection of a compelling landscape or scene visible curved across the glass surface',
    environment: 'MACRO CLOSE-UP: extremely tight macro framing on the lens glass and aperture mechanism, shallow depth of field, soft neutral daylight, muted restrained palette rather than saturated color',
    additions: 'No photographer, no hands holding the camera, no visible camera-brand logo or readable model text. The scene should feel like photography is about seeing and composition, not equipment ownership - the reflected landscape should be the emotional payoff.',
  },
  'music.piano': {
    subject: '(piano) A grand piano with its lid open, keys catching a single dramatic spotlight in an otherwise dark rehearsal space, with a very faint visual suggestion of string resonance/vibration in the air above the keys',
    environment: 'QUIET ATMOSPHERIC COMPOSITION: a mostly dark, quiet stage or rehearsal room, one focused warm spotlight isolating the piano while the rest of the space falls into cool shadow - restrained, emotionally still, not a bright cozy room',
    additions: 'No pianist, no hands on the keys. No readable sheet music - if a music stand/pages are visible, use only abstract non-legible notation-like marks. No literal floating music-note symbols.',
  },
  'gaming.board': {
    subject: '(board games) A richly detailed board-game table mid-session - a game board with strategic piece positions, dice, cards face-down, wooden tokens, and small resource markers all captured at a tense decisive moment',
    environment: 'DENSE-DETAIL COMPOSITION: an angled, elevated three-quarter view packed with rich tabletop detail (many pieces, textures, materials) rather than a single hero object - warm lamp light but with strong dramatic shadow contrast, not soft cozy light',
    additions: 'No players, no hands. Entirely original/generic game design - no recognizable copyrighted board game, no readable game title, no readable card or box text.',
  },
  'lifestyle.gardening': {
    subject: '(gardening) A watering can mid-pour over a bed of seedlings and blooming flowers, water droplets catching the light, fresh dark soil, and gardening tools resting nearby',
    environment: 'BRIGHT DAYLIGHT: crisp, clear morning sunlight, high visibility, saturated natural greens, dew still visible on leaves - an energetic bright outdoor garden bed, not a moody interior',
    additions: 'No gardener, no hands on the watering can. If gloves are shown they must be empty, lying on the ground. Must feel alive and growing, not like generic home decor - soil, water, and plant texture should dominate.',
  },
  'food.baking': {
    subject: '(baking) A tray of rising bread/pastries pulled from an oven, with a strong diagonal shaft of light cutting across the counter, flour dust caught glowing in the light beam, and scattered raw ingredients',
    environment: 'STRONG DIAGONAL COMPOSITION: a bold diagonal line runs through the frame - the light beam, the counter edge, or the arrangement of trays - creating dynamic tension rather than a centered symmetrical shot. Warm oven glow balanced against cooler ambient kitchen light',
    additions: 'No baker, no hands. No branded packaging, no readable labels on any ingredient bag or box. Must feel alive, steaming, and appetizing.',
  },
  'technology.ai': {
    subject: '(artificial intelligence) A single, minimal, glowing abstract neural-network core - nodes and connecting light-lines - floating in dark negative space, deliberately uncluttered',
    environment: 'MINIMAL HERO COMPOSITION: the vast majority of the frame is empty dark negative space; the glowing abstract network structure is small and precisely placed, not filling the frame - cool blue/cyan light only, no warm tones',
    additions: 'No person, no "coder at a monitor" cliche. No readable code, no readable UI text, no fake dashboard, no software/company logos, no sci-fi cliche overload (no glowing red HAL-eye, no generic robot). Must still read clearly as AI/machine intelligence through the network-node visualization alone.',
  },
  'pets.dogs': {
    subject: '(dogs) A real dog as the protagonist - an expressive, naturally-posed dog looking out through a rain-streaked window, with a favorite toy and a leash resting nearby, a soft dog bed visible',
    environment: 'RAINY / MOODY ATMOSPHERE: soft grey rainy daylight through the window, muted cool tones, gentle indoor lamp glow as a secondary light source, an intimate quiet mood rather than a bright cheerful one',
    additions: 'A real dog is required and is NOT a zero-human violation - this specifically tests whether a non-human living protagonist works in the object-first direction. No human owner, no hands, no leash being held. No readable text on the collar or any dog gear.',
  },
  'travel.roadtrip': {
    subject: '(road trip) A generic unbranded car parked at a scenic overlook at night, headlights cutting into the darkness toward an open mountain road, a folded paper map and luggage visible through the open trunk',
    environment: 'COOL NIGHT SCENE: deep night blues, headlight beams as the main light source, stars visible above distant mountains, cool crisp night air - not a warm sunset',
    additions: 'No driver, no passengers, no people visible through any window or reflection. No recognizable manufacturer badge, logo, or distinctive real vehicle design - keep the car generic. Must feel like the emotional idea of a journey, not a car advertisement.',
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
      display_name: 'zync-object-first-round3-12-v1',
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
  const scratchPath = path.join(os.tmpdir(), `zync-object-first-round3-status-${crypto.randomBytes(8).toString('hex')}.json`);
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
      version: 'object_first_round3_12_v1', generated_at: nowIso, provider: PROVIDER, model: MODEL, fal_ai: false,
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
  if (!Array.isArray(ids) || ids.length !== 12 || new Set(ids).size !== 12) {
    throw new Error('Object-first round 3 config must contain exactly 12 unique hobby IDs.');
  }
  const QUARANTINED = new Set(['sports.american_football', 'technology.robotics']);
  for (const id of ids) if (QUARANTINED.has(id)) throw new Error('Refusing quarantined canonical: ' + id);

  const rows = compileRows(ids);
  if (rows.length !== 12) throw new Error('Expected 12 compiled rows, got ' + rows.length);

  if (args.has('--dry-run') || (!args.has('--submit') && !args.has('--collect'))) {
    console.log(`Dry run: 12 direct-Google object-first-round3 prompts; estimated cost=$${(12 * BATCH_IMAGE_OUTPUT_PRICE_USD).toFixed(4)}.`);
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

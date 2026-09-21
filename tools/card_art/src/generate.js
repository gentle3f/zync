// Zync Hobby Card art pilot generation pipeline.
//
// Generates one artwork per hobby recipe using fal.ai's fal-ai/nano-banana-pro/edit
// model, which accepts a reference image for style guidance alongside a text prompt.
//
// Usage:
//   node src/generate.js                 generate all hobbies (1 attempt each, skips existing)
//   node src/generate.js --only=piano,ai generate only the listed hobby ids
//   node src/generate.js --retry=piano   force a second attempt for a hobby (attempt 2, max 2)
//   node src/generate.js --dry-run       build prompts and print cost estimate, no API calls

import 'dotenv/config';
import { fal } from '@fal-ai/client';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildPrompt } from './buildPrompt.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');

const MODEL = 'fal-ai/nano-banana-pro/edit';
const RESOLUTION = '2K';
const ASPECT_RATIO = '2:3';
const COST_PER_IMAGE_USD = 0.15; // nano-banana-pro/edit at 1K/2K resolution

const REFERENCE_IMAGE_PATH = path.join(REPO_ROOT, 'references', 'zync-card-style-reference.png');
const HOBBIES_PATH = path.join(ROOT, 'recipes', 'pilot_hobbies_v1.json');
const ARCHETYPES_PATH = path.join(ROOT, 'recipes', 'archetypes_v1.json');
const OUTPUT_DIR = path.join(ROOT, 'output', 'pilot_v1');
const IMAGES_DIR = path.join(OUTPUT_DIR, 'images');
const MANIFEST_PATH = path.join(OUTPUT_DIR, 'manifest.json');

function parseArgs(argv) {
  const args = { only: null, retry: null, dryRun: false };
  for (const arg of argv) {
    if (arg === '--dry-run') args.dryRun = true;
    else if (arg.startsWith('--only=')) args.only = arg.slice('--only='.length).split(',');
    else if (arg.startsWith('--retry=')) args.retry = arg.slice('--retry='.length).split(',');
  }
  return args;
}

function loadManifest() {
  if (fs.existsSync(MANIFEST_PATH)) {
    return JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf-8'));
  }
  return { model: MODEL, resolution: RESOLUTION, aspect_ratio: ASPECT_RATIO, generated_at: null, entries: [] };
}

function saveManifest(manifest) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2));
}

async function uploadReferenceImage() {
  const buffer = fs.readFileSync(REFERENCE_IMAGE_PATH);
  const file = new Blob([buffer], { type: 'image/png' });
  file.name = 'zync-card-style-reference.png';
  const url = await fal.storage.upload(file);
  return url;
}

async function generateOne({ hobby, hobbiesDoc, archetypesDoc, referenceUrl, attempt }) {
  const prompt = buildPrompt({ hobbiesDoc, archetypesDoc, hobby });

  const result = await fal.subscribe(MODEL, {
    input: {
      prompt,
      image_urls: [referenceUrl],
      num_images: 1,
      aspect_ratio: ASPECT_RATIO,
      resolution: RESOLUTION,
      output_format: 'png',
    },
    logs: false,
  });

  const image = result?.data?.images?.[0];
  if (!image?.url) {
    throw new Error(`No image returned for hobby "${hobby.id}": ${JSON.stringify(result)}`);
  }

  const res = await fetch(image.url);
  const arrayBuffer = await res.arrayBuffer();
  const fileName = `${hobby.id}_attempt${attempt}.png`;
  fs.mkdirSync(IMAGES_DIR, { recursive: true });
  const localPath = path.join(IMAGES_DIR, fileName);
  fs.writeFileSync(localPath, Buffer.from(arrayBuffer));

  return {
    hobby: hobby.title,
    hobby_id: hobby.id,
    archetype: hobby.archetype,
    final_prompt: prompt,
    model: MODEL,
    reference_mechanism: 'fal-ai/nano-banana-pro/edit image_urls reference-image style guidance',
    fal_request_id: result?.requestId || null,
    local_image_path: path.relative(REPO_ROOT, localPath).replace(/\\/g, '/'),
    attempt,
    estimated_cost_usd: COST_PER_IMAGE_USD,
    generated_at: new Date().toISOString(),
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (!process.env.FAL_KEY && !args.dryRun) {
    console.error('FAL_KEY is not set. Fill it into tools/card_art/.env before running (or use --dry-run).');
    process.exit(1);
  }
  if (process.env.FAL_KEY) {
    fal.config({ credentials: process.env.FAL_KEY });
  }

  const hobbiesDoc = JSON.parse(fs.readFileSync(HOBBIES_PATH, 'utf-8'));
  const archetypesDoc = JSON.parse(fs.readFileSync(ARCHETYPES_PATH, 'utf-8'));

  let hobbies = hobbiesDoc.hobbies;
  if (args.only) hobbies = hobbies.filter((h) => args.only.includes(h.id));

  if (args.dryRun) {
    console.log(`Dry run: ${hobbies.length} hobbies, model=${MODEL}, resolution=${RESOLUTION}`);
    for (const hobby of hobbies) {
      const prompt = buildPrompt({ hobbiesDoc, archetypesDoc, hobby });
      console.log(`\n--- ${hobby.title} (${hobby.archetype}) ---\n${prompt}`);
    }
    console.log(`\nEstimated cost for ${hobbies.length} images: $${(hobbies.length * COST_PER_IMAGE_USD).toFixed(2)}`);
    return;
  }

  const manifest = loadManifest();
  manifest.model = MODEL;
  manifest.resolution = RESOLUTION;
  manifest.aspect_ratio = ASPECT_RATIO;

  console.log('Uploading reference image to fal.ai storage...');
  const referenceUrl = await uploadReferenceImage();
  console.log(`Reference image URL: ${referenceUrl}`);

  let totalCalls = 0;
  let totalCost = 0;

  for (const hobby of hobbies) {
    const existing = manifest.entries.filter((e) => e.hobby_id === hobby.id);
    const isRetry = args.retry?.includes(hobby.id);
    if (existing.length > 0 && !isRetry) {
      console.log(`Skipping ${hobby.title} (already generated, attempt ${existing[existing.length - 1].attempt}). Use --retry=${hobby.id} to force another attempt.`);
      continue;
    }
    const attempt = existing.length + 1;
    if (attempt > 2) {
      console.log(`Skipping ${hobby.title}: already at max 2 attempts.`);
      continue;
    }

    console.log(`Generating ${hobby.title} (attempt ${attempt})...`);
    try {
      const entry = await generateOne({ hobby, hobbiesDoc, archetypesDoc, referenceUrl, attempt });
      manifest.entries.push(entry);
      totalCalls += 1;
      totalCost += entry.estimated_cost_usd;
      saveManifest(manifest);
      console.log(`  -> saved ${entry.local_image_path}`);
    } catch (err) {
      console.error(`  !! failed for ${hobby.title}:`, err.message || err);
    }
  }

  manifest.generated_at = new Date().toISOString();
  saveManifest(manifest);

  console.log(`\nDone. API calls this run: ${totalCalls}. Estimated cost this run: $${totalCost.toFixed(2)}.`);
  const grandTotal = manifest.entries.reduce((sum, e) => sum + e.estimated_cost_usd, 0);
  console.log(`Total entries in manifest: ${manifest.entries.length}. Total estimated cost so far: $${grandTotal.toFixed(2)}.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

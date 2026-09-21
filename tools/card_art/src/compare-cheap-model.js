// One-off comparison: same prompts/reference image, run through a cheaper
// fal.ai model, to check whether quality holds up before committing a
// 3000+ card batch to it. Not part of the regular pilot pipeline.
//
// Usage: node src/compare-cheap-model.js

import 'dotenv/config';
import { fal } from '@fal-ai/client';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildPrompt } from './buildPrompt.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');

const MODEL = 'fal-ai/gemini-25-flash-image/edit';
const COST_PER_IMAGE_USD = 0.039;
const ASPECT_RATIO = '2:3';

const REFERENCE_IMAGE_PATH = path.join(REPO_ROOT, 'references', 'zync-card-style-reference.png');
const HOBBIES_PATH = path.join(ROOT, 'recipes', 'pilot_hobbies_v1.json');
const ARCHETYPES_PATH = path.join(ROOT, 'recipes', 'archetypes_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'compare_gemini', 'images');

const SAMPLE_IDS = ['badminton', 'bouldering', 'sushi', 'boardgames', 'cinema'];

async function main() {
  if (!process.env.FAL_KEY) {
    console.error('FAL_KEY not set.');
    process.exit(1);
  }
  fal.config({ credentials: process.env.FAL_KEY });

  const hobbiesDoc = JSON.parse(fs.readFileSync(HOBBIES_PATH, 'utf-8'));
  const archetypesDoc = JSON.parse(fs.readFileSync(ARCHETYPES_PATH, 'utf-8'));
  const hobbies = hobbiesDoc.hobbies.filter((h) => SAMPLE_IDS.includes(h.id));

  const buffer = fs.readFileSync(REFERENCE_IMAGE_PATH);
  const file = new Blob([buffer], { type: 'image/png' });
  file.name = 'zync-card-style-reference.png';
  const referenceUrl = await fal.storage.upload(file);
  console.log(`Reference uploaded: ${referenceUrl}`);

  fs.mkdirSync(OUT_DIR, { recursive: true });
  let totalCost = 0;

  for (const hobby of hobbies) {
    const prompt = buildPrompt({ hobbiesDoc, archetypesDoc, hobby });
    console.log(`Generating ${hobby.title} via ${MODEL}...`);
    const result = await fal.subscribe(MODEL, {
      input: {
        prompt,
        image_urls: [referenceUrl],
        num_images: 1,
        aspect_ratio: ASPECT_RATIO,
        output_format: 'png',
      },
      logs: false,
    });
    const image = result?.data?.images?.[0];
    if (!image?.url) {
      console.error(`  !! no image for ${hobby.id}`);
      continue;
    }
    const res = await fetch(image.url);
    const arrayBuffer = await res.arrayBuffer();
    const localPath = path.join(OUT_DIR, `${hobby.id}.png`);
    fs.writeFileSync(localPath, Buffer.from(arrayBuffer));
    totalCost += COST_PER_IMAGE_USD;
    console.log(`  -> saved ${path.relative(REPO_ROOT, localPath)}`);
  }

  console.log(`\nDone. ${hobbies.length} images, ~$${totalCost.toFixed(3)} total.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

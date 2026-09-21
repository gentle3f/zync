// One-off comparison: same prompts/reference image, run through FLUX.2 [dev] edit
// ($0.012/MP for input+output) to check if it beats gemini-25-flash-image/edit
// on cost while holding quality, before committing a 3000+ card batch.
//
// Usage: node src/compare-flux2.js

import 'dotenv/config';
import { fal } from '@fal-ai/client';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildPrompt } from './buildPrompt.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');

const MODEL = 'fal-ai/flux-2/edit';
const IMAGE_SIZE = { width: 832, height: 1248 }; // matches gemini-flash sample for fair comparison, ~1.04MP output

const REFERENCE_IMAGE_PATH = path.join(REPO_ROOT, 'references', 'zync-card-style-reference.png');
const HOBBIES_PATH = path.join(ROOT, 'recipes', 'pilot_hobbies_v1.json');
const ARCHETYPES_PATH = path.join(ROOT, 'recipes', 'archetypes_v1.json');
const OUT_DIR = path.join(ROOT, 'output', 'compare_flux2', 'images');

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

  for (const hobby of hobbies) {
    const prompt = buildPrompt({ hobbiesDoc, archetypesDoc, hobby });
    console.log(`Generating ${hobby.title} via ${MODEL}...`);
    const result = await fal.subscribe(MODEL, {
      input: {
        prompt,
        image_urls: [referenceUrl],
        num_images: 1,
        image_size: IMAGE_SIZE,
        output_format: 'png',
      },
      logs: false,
    });
    const image = result?.data?.images?.[0];
    if (!image?.url) {
      console.error(`  !! no image for ${hobby.id}: ${JSON.stringify(result?.data)}`);
      continue;
    }
    const res = await fetch(image.url);
    const arrayBuffer = await res.arrayBuffer();
    const localPath = path.join(OUT_DIR, `${hobby.id}.png`);
    fs.writeFileSync(localPath, Buffer.from(arrayBuffer));
    console.log(`  -> saved ${path.relative(REPO_ROOT, localPath)}`);
  }

  console.log('\nDone.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

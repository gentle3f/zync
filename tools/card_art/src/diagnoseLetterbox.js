// Zero-cost diagnostic for dark top/bottom bands in already-generated PNGs.
// This script never calls fal.ai and never modifies images.

import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

function contiguousEdgeBand(rowStats, fromStart = true) {
  let count = 0;
  const ordered = fromStart ? rowStats : [...rowStats].reverse();
  for (const row of ordered) {
    if (row.meanLuma <= 48 && row.darkFraction >= 0.82) count += 1;
    else break;
  }
  return count;
}

async function inspect(filePath) {
  const buffer = fs.readFileSync(filePath);
  const image = sharp(buffer, { failOn: 'none' });
  const metadata = await image.metadata();
  const { data, info } = await image.removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const rows = [];
  for (let y = 0; y < info.height; y++) {
    let total = 0;
    let dark = 0;
    for (let x = 0; x < info.width; x++) {
      const i = (y * info.width + x) * info.channels;
      const r = data[i] ?? 0;
      const g = data[i + 1] ?? r;
      const b = data[i + 2] ?? r;
      const luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      total += luma;
      if (luma <= 48) dark += 1;
    }
    rows.push({ meanLuma: total / info.width, darkFraction: dark / info.width });
  }
  const top = contiguousEdgeBand(rows, true);
  const bottom = contiguousEdgeBand(rows, false);
  const frac = (top + bottom) / info.height;
  return {
    file: path.relative(ROOT, filePath).replace(/\\/g, '/'),
    format: metadata.format,
    width: metadata.width,
    height: metadata.height,
    top_dark_band_px: top,
    bottom_dark_band_px: bottom,
    combined_dark_band_fraction: Number(frac.toFixed(4)),
    likely_letterbox: frac >= 0.06 || top >= 24 || bottom >= 24,
  };
}

const defaults = [
  'output/confirmatory_30_v1/images/business__coworking__flux_2__attempt1.png',
  'output/post_confirmatory_repair_v1/images/business__coworking__flux_2__attempt1.png',
  'output/confirmatory_30_v1/images/learning__mock_trial__flux_2__attempt1.png',
  'output/post_confirmatory_repair_v1/images/learning__mock_trial__flux_2__attempt1.png',
];

const files = process.argv.slice(2).length ? process.argv.slice(2) : defaults;
const results = [];
for (const rel of files) {
  const full = path.isAbsolute(rel) ? rel : path.join(ROOT, rel);
  if (!fs.existsSync(full)) {
    results.push({ file: rel, missing: true });
    continue;
  }
  results.push(await inspect(full));
}
console.log(JSON.stringify(results, null, 2));

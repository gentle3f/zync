// Zero-cost diagnostic for dark top/bottom bands in already-generated PNGs.
// This script never calls fal.ai and never modifies images.

import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

function contiguousFlatEdgeBand(rowStats, fromStart = true) {
  const ordered = fromStart ? rowStats : [...rowStats].reverse();
  if (!ordered.length) return 0;
  const seed = ordered[0].meanLuma;
  let count = 0;
  for (const row of ordered) {
    const flat = row.stddevLuma <= 8 && row.rangeLuma <= 28;
    const stableTone = Math.abs(row.meanLuma - seed) <= 15;
    if (flat && stableTone) count += 1;
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
    let totalSq = 0;
    let minLuma = 255;
    let maxLuma = 0;
    for (let x = 0; x < info.width; x++) {
      const i = (y * info.width + x) * info.channels;
      const r = data[i] ?? 0;
      const g = data[i + 1] ?? r;
      const b = data[i + 2] ?? r;
      const luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      total += luma;
      totalSq += luma * luma;
      minLuma = Math.min(minLuma, luma);
      maxLuma = Math.max(maxLuma, luma);
    }
    const meanLuma = total / info.width;
    const variance = Math.max(0, totalSq / info.width - meanLuma * meanLuma);
    rows.push({ meanLuma, stddevLuma: Math.sqrt(variance), rangeLuma: maxLuma - minLuma });
  }
  const top = contiguousFlatEdgeBand(rows, true);
  const bottom = contiguousFlatEdgeBand(rows, false);
  const frac = (top + bottom) / info.height;
  return {
    detector_version: 'v2-flatness',
    file: path.relative(ROOT, filePath).replace(/\\/g, '/'),
    format: metadata.format,
    width: metadata.width,
    height: metadata.height,
    top_flat_band_px: top,
    bottom_flat_band_px: bottom,
    combined_flat_band_fraction: Number(frac.toFixed(4)),
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

// Builds a single contact-sheet.jpg grid from all images in the manifest,
// plus a gallery.html for easy browsing.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');
const OUTPUT_DIR = path.join(ROOT, 'output', 'pilot_v1');
const MANIFEST_PATH = path.join(OUTPUT_DIR, 'manifest.json');
const CONTACT_SHEET_PATH = path.join(OUTPUT_DIR, 'contact-sheet.jpg');
const GALLERY_PATH = path.join(OUTPUT_DIR, 'gallery.html');

const CELL_W = 400;
const CELL_H = 600;
const COLS = 5;
const LABEL_H = 40;

function latestByHobby(entries) {
  const map = new Map();
  for (const e of entries) {
    const prev = map.get(e.hobby_id);
    if (!prev || e.attempt > prev.attempt) map.set(e.hobby_id, e);
  }
  return [...map.values()];
}

async function buildContactSheet(entries) {
  const rows = Math.ceil(entries.length / COLS);
  const sheetW = COLS * CELL_W;
  const sheetH = rows * (CELL_H + LABEL_H);

  const composites = [];
  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];
    const col = i % COLS;
    const row = Math.floor(i / COLS);
    const imgPath = path.join(REPO_ROOT, entry.local_image_path);
    const resized = await sharp(imgPath).resize(CELL_W, CELL_H, { fit: 'cover' }).toBuffer();
    composites.push({ input: resized, left: col * CELL_W, top: row * (CELL_H + LABEL_H) });

    const label = Buffer.from(
      `<svg width="${CELL_W}" height="${LABEL_H}"><rect width="100%" height="100%" fill="black"/><text x="10" y="26" font-size="20" fill="white" font-family="sans-serif">${entry.hobby}</text></svg>`
    );
    composites.push({ input: label, left: col * CELL_W, top: row * (CELL_H + LABEL_H) + CELL_H });
  }

  await sharp({
    create: { width: sheetW, height: sheetH, channels: 3, background: { r: 20, g: 20, b: 25 } },
  })
    .composite(composites)
    .jpeg({ quality: 88 })
    .toFile(CONTACT_SHEET_PATH);
}

function buildGallery(entries) {
  const cards = entries
    .map(
      (e) => `
    <div class="card">
      <img src="images/${path.basename(e.local_image_path)}" alt="${e.hobby}" />
      <div class="meta">
        <strong>${e.hobby}</strong>
        <span>${e.archetype} · attempt ${e.attempt}</span>
      </div>
    </div>`
    )
    .join('\n');

  const html = `<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<title>Zync Card Art Pilot v1</title>
<style>
  body { background:#12131a; color:#eee; font-family: sans-serif; margin:0; padding:24px; }
  h1 { font-weight:600; }
  .grid { display:grid; grid-template-columns: repeat(5, 1fr); gap:16px; }
  .card { background:#1c1e28; border-radius:8px; overflow:hidden; }
  .card img { width:100%; display:block; aspect-ratio:2/3; object-fit:cover; }
  .meta { padding:8px 10px; display:flex; flex-direction:column; gap:2px; font-size:13px; }
  .meta span { color:#9aa; }
</style>
</head>
<body>
  <h1>Zync Hobby Card Art — Pilot v1</h1>
  <div class="grid">
    ${cards}
  </div>
</body>
</html>`;

  fs.writeFileSync(GALLERY_PATH, html);
}

async function main() {
  if (!fs.existsSync(MANIFEST_PATH)) {
    console.error('No manifest.json found. Run generate.js first.');
    process.exit(1);
  }
  const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf-8'));
  const entries = latestByHobby(manifest.entries).sort((a, b) => a.hobby.localeCompare(b.hobby));

  if (entries.length === 0) {
    console.error('No entries in manifest.');
    process.exit(1);
  }

  await buildContactSheet(entries);
  buildGallery(entries);
  console.log(`Contact sheet: ${CONTACT_SHEET_PATH}`);
  console.log(`Gallery: ${GALLERY_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

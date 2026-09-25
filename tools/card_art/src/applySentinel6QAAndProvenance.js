// Zync Object-First V2 Production Rollout - Sentinel-6 QA + provenance.
//
// Part 1: records the AUTHORITATIVE ChatGPT visual QA for the 6
// Sentinel-6 remediation outputs (5 approved, 1 approved_with_minor).
//
// Part 2: reconciles remediation replacement provenance. Each of these 6
// ids has an OLDER, QA-quarantined v2.3 Wave-B asset (real image,
// preserved untouched in output/object_first_v2_production_waveB48_v1/)
// and a NEWER, now-approved v2.4/v2.4.1 Sentinel-6 asset (real image,
// preserved untouched in output/object_first_v24_sentinel6_v1/). Neither
// image file is touched by this script. The queue row's live fields
// (generation_status/visual_qa_*) are updated to reflect the NEW
// approved asset; the OLD asset's disposition/finding/version/SHA/source
// are captured into a new `superseded_assets` array on the same row
// before being overwritten, tagged `status: superseded_by_remediation_asset`
// (never deleted, never silently dropped, never retroactively approved).
//
// Zero-cost. No image generated. No image inspected.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CATALOG = path.join(ROOT, 'catalog');
const OUT_ROLLOUT = path.join(ROOT, 'output', 'production_rollout_v2_object_first_v1');

const QUEUE_PATH = path.join(CATALOG, 'production_queue_v2_object_first.json');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
};

// ---------------------------------------------------------------------------
// PART 1 - Sentinel-6 authoritative QA decisions
// ---------------------------------------------------------------------------

const SENTINEL_APPROVED = {
  'food.coffee': 'The physical-logic repair succeeded - kettle rests naturally, dripper is physically supported, no invisible-human pour-over, coffee semantic identity remains clear.',
  'music.singing': 'The repaired v2.4.1 scene now clearly communicates singing/vocal recording - indoor vocal booth, mounted microphone, pop filter, acoustic treatment, lyric stand, no outdoor/rain contradiction, no unrelated instrument becoming the subject.',
  'music.karaoke': 'The repaired v2.4.1 scene clearly communicates karaoke - private karaoke room, microphones, karaoke machine/screen, lounge environment, no rainy outdoor microphone drift.',
  'learning.book_genre.booktube': 'The repaired scene clearly communicates BookTube/book-review creator culture - books, camera/tripod, ring light, microphone, book display. No robot-library/conveyor drift.',
  'technology.gadgets': 'The repaired scene now clearly communicates consumer gadgets - phone-like device, earbuds, wearable, speaker, power bank, camera/accessories. No CNC/factory/manufacturing drift. No obvious brand-logo problem.',
};

const SENTINEL_APPROVED_WITH_MINOR = {
  'learning.fiction': {
    flags: ['text_leak_minor'],
    finding: 'Floating-pen/invisible-human physics is solved, pen rests naturally, fiction/manuscript identity is clear. Remaining pseudo-handwriting functions mostly as manuscript texture; some text-like leakage remains but is acceptable.',
  },
};

const SENTINEL_SOURCE_DIR = 'tools/card_art/output/object_first_v24_sentinel6_v1';
const WAVEB_SOURCE_DIR = 'tools/card_art/output/object_first_v2_production_waveB48_v1';

function applySentinelQAAndProvenance(queueRows) {
  const byId = new Map(queueRows.map(r => [r.canonical_id, r]));
  const results = [];

  const allIds = [...Object.keys(SENTINEL_APPROVED), ...Object.keys(SENTINEL_APPROVED_WITH_MINOR)];
  if (allIds.length !== 6) throw new Error(`Expected 6 Sentinel-6 ids, got ${allIds.length}`);

  for (const id of allIds) {
    const row = byId.get(id);
    if (!row) throw new Error(`Sentinel-6 id not found in queue: ${id}`);
    if (row.generation_status !== 'generated_pending_remediation_qa') {
      throw new Error(`${id} does not have generation_status=generated_pending_remediation_qa (has ${row.generation_status}) - refusing to apply Sentinel-6 QA.`);
    }

    // Capture the OLD (Wave-B, v2.3, quarantined) provenance before it is
    // overwritten - it must never be silently lost.
    const oldProvenance = {
      source: WAVEB_SOURCE_DIR,
      production_candidate_version: 'v2.3',
      // The queue row's prompt_sha256/version were already overwritten to
      // the Sentinel (v2.4/v2.4.1) values by finalizeSentinel6.js at
      // collection time - the true old v2.3 hash lives in the immutable
      // production_candidate_freeze_v1.json, referenced here by id rather
      // than re-copied, to avoid any risk of transcription drift.
      prompt_sha256_ref: 'output/production_rollout_v2_object_first_v1/production_candidate_freeze_v1.json#' + id,
      visual_qa_disposition: row.visual_qa_disposition, // was 'qa_quarantine' from the Wave-B QA pass
      visual_qa_flags: row.visual_qa_flags,
      visual_qa_finding: row.visual_qa_finding,
      status: 'superseded_by_remediation_asset',
      superseded_by: {
        sentinel_source_commit: '1762230',
        canonical_asset_source: SENTINEL_SOURCE_DIR,
      },
    };
    if (!row.superseded_assets) row.superseded_assets = [];
    row.superseded_assets.push(oldProvenance);

    // Apply the NEW (Sentinel-6) approved disposition as the row's live
    // state. prompt_sha256/production_candidate_version are already
    // correct (set at Sentinel-6 collection time) - only the QA
    // disposition/status fields change here.
    if (SENTINEL_APPROVED[id]) {
      row.visual_qa_disposition = 'approved';
      row.visual_qa_flags = [];
      row.visual_qa_finding = SENTINEL_APPROVED[id];
      row.generation_status = 'approved';
      results.push({ canonical_id: id, disposition: 'approved' });
    } else {
      const info = SENTINEL_APPROVED_WITH_MINOR[id];
      row.visual_qa_disposition = 'approved_with_minor';
      row.visual_qa_flags = info.flags;
      row.visual_qa_finding = info.finding;
      row.generation_status = 'approved_with_minor';
      results.push({ canonical_id: id, disposition: 'approved_with_minor', flags: info.flags, finding: info.finding });
    }

    row.canonical_asset_source = SENTINEL_SOURCE_DIR;
  }

  const approved = Object.keys(SENTINEL_APPROVED).length;
  const approvedWithMinor = Object.keys(SENTINEL_APPROVED_WITH_MINOR).length;
  if (approved !== 5 || approvedWithMinor !== 1) throw new Error(`Sentinel-6 disposition count mismatch: approved=${approved} approved_with_minor=${approvedWithMinor}`);

  return { reviewed: 6, approved, approved_with_minor: approvedWithMinor, failed: 0, content_blocked: 0, results };
}

function main() {
  const queue = readJson(QUEUE_PATH);
  const summary = applySentinelQAAndProvenance(queue.rows);
  writeJson(QUEUE_PATH, queue);

  writeJson(path.join(OUT_ROLLOUT, 'sentinel_6_qa_results_v1.json'), {
    version: 'sentinel_6_qa_results_v1',
    recorded_at: new Date().toISOString(),
    source: 'Authoritative ChatGPT visual review supplied verbatim by the user; not re-derived or inspected by Claude.',
    ...summary,
    systemic_findings: {
      pass: [
        'human-operated-object physical logic repaired for coffee/fiction',
        'vocal semantic grammar repaired for singing/karaoke',
        'BookTube semantic repair successful',
        'gadgets semantic repair successful',
        'no zero-human regression',
        'no content block',
        'no prompt-conflict regression',
      ],
    },
    conclusion: 'PASS_REMEDIATION_VALIDATED',
    authorizes: 'wave_c_96',
    provenance_note: 'Each of these 6 ids now carries a superseded_assets entry on its queue row recording the OLD v2.3 Wave-B QA-quarantined asset (status: superseded_by_remediation_asset) - never deleted, never overwritten, never retroactively approved. The row\'s live generation_status/visual_qa_* fields now reflect the NEW Sentinel-6 (v2.4/v2.4.1) approved asset. Neither image file was touched.',
  });

  console.log('Sentinel-6 QA applied:', JSON.stringify(summary.results.map(r => r.canonical_id + ':' + r.disposition)));
}

main();

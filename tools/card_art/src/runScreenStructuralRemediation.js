// 10-card structural screen-safety validation. Standard FLUX only.
// No auto-rerolls.

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const BATCH_PATH = path.join(ROOT, 'catalog', 'screen_structural_remediation_v1.json');
const RUNNER = path.join(__dirname, 'generateCompiledBatch.js');

const batch = JSON.parse(fs.readFileSync(BATCH_PATH, 'utf-8'));
const dryRun = process.argv.includes('--dry-run');

console.log(
  `Screen structural remediation ${batch.version}: ${batch.expected.total_cards} cards; ` +
  `standard=${batch.expected.standard_cards}; estimated first-pass cost=$${batch.expected.estimated_total_cost_usd.toFixed(4)}`,
);

for (const route of batch.routes) {
  const args = [
    RUNNER,
    ...(dryRun ? ['--dry-run'] : []),
    `--model=${route.model}`,
    `--only=${route.ids.join(',')}`,
  ];
  const result = spawnSync(process.execPath, args, {
    stdio: 'inherit',
    env: { ...process.env, ZYNC_CARD_ART_OUTPUT_TAG: batch.output_tag },
  });
  if (result.status !== 0) process.exit(result.status ?? 1);
}

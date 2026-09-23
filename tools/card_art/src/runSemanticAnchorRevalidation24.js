// Targeted semantic-anchor revalidation.
// Existing generator only; 24 Standard-FLUX calls; no auto-rerolls or follow-on batch.

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(ROOT, 'catalog', 'semantic_anchor_revalidation_24_v1.json');
const RUNNER = path.join(__dirname, 'generateCompiledBatch.js');
const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf-8'));
const dryRun = process.argv.includes('--dry-run');

if (config.ids.length !== 24 || new Set(config.ids).size !== 24) {
  throw new Error('semantic_anchor_revalidation_24_v1 must contain exactly 24 unique IDs');
}

console.log(
  `Semantic-anchor revalidation: calls=${config.expected.api_calls}; estimated total=$${config.expected.estimated_total_cost_usd.toFixed(2)}`
);

const args = [
  RUNNER,
  ...(dryRun ? ['--dry-run'] : []),
  '--model=text',
  `--only=${config.ids.join(',')}`,
];

const result = spawnSync(process.execPath, args, {
  stdio: 'inherit',
  env: { ...process.env, ZYNC_CARD_ART_OUTPUT_TAG: config.output_tag },
});
if (result.status !== 0) process.exit(result.status ?? 1);

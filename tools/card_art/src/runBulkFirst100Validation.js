// Stratified 100-card validation for BULK-FIRST.
// Uses the existing validated generator. No auto-rerolls. No broad follow-on batch.

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(ROOT, 'catalog', 'bulk_first_100_validation_v1.json');
const RUNNER = path.join(__dirname, 'generateCompiledBatch.js');

const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf-8'));
const dryRun = process.argv.includes('--dry-run');

if (!Array.isArray(config.ids) || config.ids.length !== 100 || new Set(config.ids).size !== 100) {
  throw new Error('bulk_first_100_validation_v1.json must contain exactly 100 unique IDs');
}

console.log(
  `Bulk-first 100 validation: calls=${config.expected.api_calls}; ` +
  `archetypes=${config.expected.archetypes_covered}; ` +
  `estimated total=$${config.expected.estimated_total_cost_usd.toFixed(2)}`,
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

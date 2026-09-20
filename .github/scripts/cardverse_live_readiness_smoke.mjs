import { buildCardverseReadiness } from '../../server/cardverse/readiness.js';

const report = await buildCardverseReadiness();

const safeReport = {
  status: report.status,
  ready: report.ready,
  checks: report.checks,
  gates: report.gates,
};

console.log('[cardverse-live-readiness] ' + JSON.stringify(safeReport));

let exitCode = 0;
if (!report.checks.database.configured) exitCode += 1;
if (!report.checks.database.reachable) exitCode += 2;
if (!report.checks.database.schemaReady) exitCode += 4;
if (!report.checks.abuseGuard.configured) exitCode += 8;
if (!report.checks.abuseGuard.reachable) exitCode += 16;
if (!report.checks.providers.any) exitCode += 32;

if (!report.ready && exitCode === 0) exitCode = 64;

if (exitCode !== 0) {
  console.error('[cardverse-live-readiness] NOT_READY_CODE=' + exitCode);
  process.exit(exitCode);
}

console.log('[cardverse-live-readiness] READY');
// env-refresh probe 2026-09-20-google

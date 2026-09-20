import { buildCardverseReadiness } from '../../api/_cardverse/readiness.js';

const report = await buildCardverseReadiness();

const safeReport = {
  status: report.status,
  ready: report.ready,
  checks: report.checks,
  gates: report.gates,
};

console.log('[cardverse-live-readiness] ' + JSON.stringify(safeReport));

if (!report.ready) {
  console.error('[cardverse-live-readiness] NOT_READY');
  process.exit(2);
}

console.log('[cardverse-live-readiness] READY');

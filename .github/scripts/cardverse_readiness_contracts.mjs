import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {
  authorizeCardverseReadiness,
  buildCardverseReadiness,
  cardverseReadinessEnabled,
} from '../../server/cardverse/readiness.js';

const oldEnabled = process.env.CARDVERSE_READINESS_ENABLED;
const oldSecret = process.env.ZYNC_CARDVERSE_READINESS_SECRET;

try {
  delete process.env.CARDVERSE_READINESS_ENABLED;
  delete process.env.ZYNC_CARDVERSE_READINESS_SECRET;
  assert.equal(cardverseReadinessEnabled(), false);
  assert.equal(authorizeCardverseReadiness('Bearer anything'), false);

  process.env.CARDVERSE_READINESS_ENABLED = 'true';
  process.env.ZYNC_CARDVERSE_READINESS_SECRET = 'short';
  assert.equal(cardverseReadinessEnabled(), false);

  const operatorSecret = 'R'.repeat(48);
  process.env.ZYNC_CARDVERSE_READINESS_SECRET = operatorSecret;
  assert.equal(cardverseReadinessEnabled(), true);
  assert.equal(authorizeCardverseReadiness('Bearer ' + operatorSecret), true);
  assert.equal(authorizeCardverseReadiness('Bearer ' + 'X'.repeat(48)), false);
  assert.equal(authorizeCardverseReadiness('Basic ' + operatorSecret), false);
} finally {
  if (oldEnabled == null) delete process.env.CARDVERSE_READINESS_ENABLED;
  else process.env.CARDVERSE_READINESS_ENABLED = oldEnabled;
  if (oldSecret == null) delete process.env.ZYNC_CARDVERSE_READINESS_SECRET;
  else process.env.ZYNC_CARDVERSE_READINESS_SECRET = oldSecret;
}

const baseOptions = {
  databaseConfigured: true,
  abuseConfigured: true,
  providers: { google: true, apple: false, any: true },
  proofConfigured: false,
  packPolicyConfigured: false,
  gates: {
    api: false,
    packOpen: false,
    questClaim: false,
    proofRedeem: false,
    accountLifecycle: false,
  },
  async checkDatabase() { return true; },
  async checkAbuseGuard() { return true; },
  async checkPackPolicy() { return true; },
};

{
  const report = await buildCardverseReadiness(baseOptions);
  assert.equal(report.status, 'ready');
  assert.equal(report.ready, true);
  assert.equal(report.checks.database.reachable, true);
  assert.equal(report.checks.database.schemaReady, true);
  assert.equal(report.checks.abuseGuard.reachable, true);
  assert.equal(report.checks.providers.google, true);
  assert.equal(report.checks.providers.apple, false);
  assert.equal(report.gates.api, false);
}

{
  const report = await buildCardverseReadiness({
    ...baseOptions,
    async checkDatabase() {
      return { reachable: true, schemaReady: false };
    },
  });
  assert.equal(report.ready, false);
  assert.equal(report.checks.database.reachable, true);
  assert.equal(report.checks.database.schemaReady, false);
}

{
  const report = await buildCardverseReadiness({
    ...baseOptions,
    async checkDatabase() { throw new Error('do not leak me'); },
  });
  assert.equal(report.ready, false);
  assert.equal(report.checks.database.configured, true);
  assert.equal(report.checks.database.reachable, false);
  assert.equal(JSON.stringify(report).includes('do not leak me'), false);
}

{
  const report = await buildCardverseReadiness({
    ...baseOptions,
    proofConfigured: false,
    gates: { ...baseOptions.gates, api: true, proofRedeem: true },
  });
  assert.equal(report.ready, false);
}

{
  const report = await buildCardverseReadiness({
    ...baseOptions,
    packPolicyConfigured: true,
    gates: { ...baseOptions.gates, api: true, packOpen: true },
    async checkPackPolicy() { return false; },
  });
  assert.equal(report.ready, false);
  assert.equal(report.checks.packPolicy.valid, false);
}

{
  const report = await buildCardverseReadiness({
    ...baseOptions,
    providers: { google: false, apple: false, any: false },
  });
  assert.equal(report.ready, false);
}

const readinessSource = await readFile(
  new URL('../../server/cardverse/readiness.js', import.meta.url),
  'utf8',
);
assert.match(readinessSource, /cardverse_inventory_ledger_immutable/);
assert.match(readinessSource, /cardverse_reward_proofs_issuer_ticket_uidx/);

const routeSource = await readFile(
  new URL('../../server/cardverse/routes/readiness.js', import.meta.url),
  'utf8',
);
assert.match(routeSource, /authorizeCardverseReadiness/);
assert.match(routeSource, /report\.ready \? 200 : 503/);
assert.equal(routeSource.includes('DATABASE_URL'), false);
assert.equal(routeSource.includes('ZYNC_GOOGLE_CLIENT_IDS'), false);

const route = await import('../../server/cardverse/routes/readiness.js');
assert.equal(typeof route.default, 'function');

console.log('✓ Cardverse operator readiness contracts passed');

import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  canonicalQuestCycles,
  evaluateQuestProofs,
  normalizeQuestClaim,
  normalizeTrustedRewardProof,
  questDefinition,
} from '../../server/cardverse/reward_store.js';

const migration = await readFile(
  new URL('../../db/migrations/0004_cardverse_reward_proofs.sql', import.meta.url),
  'utf8',
);

for (const table of [
  'cardverse_draw_token_balances',
  'cardverse_reward_proofs',
  'cardverse_reward_grants',
  'cardverse_reward_grant_proofs',
]) {
  assert.match(migration, new RegExp('CREATE TABLE IF NOT EXISTS ' + table));
}

assert.match(migration, /UNIQUE \(account_id, client_event_id\)/);
assert.match(migration, /UNIQUE \(account_id, quest_id, cycle_start\)/);
assert.match(migration, /locked_quantity <= quantity/);

assert.deepEqual(
  canonicalQuestCycles('2026-09-20T00:30:00.000Z', 480),
  {
    dailyCycleStart: '2026-09-19T16:00:00.000Z',
    weeklyCycleStart: '2026-09-13T16:00:00.000Z',
  },
);

const ACCOUNT = '11111111-1111-4111-8111-111111111111';
const proof = normalizeTrustedRewardProof({
  accountId: ACCOUNT,
  clientEventId: 'event-1',
  eventType: 'one_to_one_zync',
  source: 'one_to_one',
  occurredAt: '2026-09-18T03:00:00.000Z',
  participantCount: 2,
  repeatPerson: false,
  interestCategories: ['sports', 'sports', 'Food'],
  timezoneOffsetMinutes: 480,
  verifier: 'server_zync_handshake_v1',
});
assert.equal(proof.accountId, ACCOUNT);
assert.deepEqual(proof.interestCategories, ['food', 'sports']);
assert.equal(proof.weeklyCycleStart, '2026-09-13T16:00:00.000Z');

const claim = normalizeQuestClaim({
  eligibilityKey: 'weekly_five_real_world_actions:2026-09-13T16:00:00.000Z',
  questId: 'weekly_five_real_world_actions',
  cycleStart: '2026-09-13T16:00:00.000Z',
  proofEventIds: ['event-3', 'event-1', 'event-2', 'event-2'],
  idempotencyKey: 'quest-claim-attempt-0001',
  clientContractVersion: 1,
});
assert.deepEqual(claim.proofEventIds, ['event-1', 'event-2', 'event-3']);
assert.equal(questDefinition(claim.questId).rewardKind, 'discovery_pack');

assert.throws(
  () => normalizeQuestClaim({
    ...claim,
    accountId: ACCOUNT,
  }),
  /cardverse_quest_client_authority_forbidden/,
);

const weeklyRows = [
  {
    event_type: 'one_to_one_zync',
    repeat_person: false,
    participant_count: 2,
    interest_categories: ['sports'],
    weekly_cycle_start: '2026-09-13T16:00:00.000Z',
  },
  {
    event_type: 'one_to_one_zync',
    repeat_person: true,
    participant_count: 2,
    interest_categories: ['food'],
    weekly_cycle_start: '2026-09-13T16:00:00.000Z',
  },
  {
    event_type: 'tried_together_completed',
    repeat_person: false,
    participant_count: 4,
    interest_categories: ['music'],
    weekly_cycle_start: '2026-09-13T16:00:00.000Z',
  },
  {
    event_type: 'one_to_one_zync',
    repeat_person: false,
    participant_count: 2,
    interest_categories: [],
    weekly_cycle_start: '2026-09-13T16:00:00.000Z',
  },
];

assert.throws(
  () => evaluateQuestProofs(
    'weekly_five_real_world_actions',
    '2026-09-13T16:00:00.000Z',
    weeklyRows,
  ),
  /cardverse_quest_proof_insufficient/,
);

assert.equal(
  evaluateQuestProofs(
    'weekly_group_activity',
    '2026-09-13T16:00:00.000Z',
    weeklyRows,
  ).current,
  1,
);

assert.equal(
  evaluateQuestProofs(
    'weekly_three_zyncs',
    '2026-09-13T16:00:00.000Z',
    weeklyRows,
  ).current,
  3,
);

assert.throws(
  () => evaluateQuestProofs(
    'weekly_group_activity',
    '2026-09-06T16:00:00.000Z',
    weeklyRows,
  ),
  /cardverse_quest_proof_cycle_mismatch/,
);

const endpoint = await import('../../server/cardverse/routes/quests/claim.js');
assert.equal(typeof endpoint.default, 'function');

console.log('✓ Cardverse trusted Quest proof/reward contracts passed');


assert.throws(
  () => evaluateQuestProofs(
    'weekly_three_zyncs',
    '2026-09-13T16:00:00.000Z',
    [
      {
        event_type: 'one_to_one_zync',
        repeat_person: null,
        interest_categories: [],
        weekly_cycle_start: '2026-09-13T16:00:00.000Z',
      },
      {
        event_type: 'one_to_one_zync',
        repeat_person: null,
        interest_categories: [],
        weekly_cycle_start: '2026-09-13T16:00:00.000Z',
      },
    ],
  ),
  /cardverse_quest_proof_insufficient/,
);

console.log('✓ Unclassified relay proofs cannot satisfy multi-Zync Quest');


assert.equal(
  questDefinition('lifetime_eight_real_world_actions').cadence,
  'lifetime',
);
assert.throws(
  () => normalizeQuestClaim({
    eligibilityKey: 'lifetime_eight_real_world_actions:2026-01-01T00:00:00.000Z',
    questId: 'lifetime_eight_real_world_actions',
    cycleStart: '2026-01-01T00:00:00.000Z',
    proofEventIds: ['a'],
    idempotencyKey: 'lifetime-claim-0001',
    clientContractVersion: 1,
  }),
  /cardverse_quest_claim_invalid/,
);

const dailyStore = await import('../../server/cardverse/daily_login_store.js');
assert.deepEqual(
  dailyStore.normalizeDailyLoginClaim({
    idempotencyKey: 'daily-login-claim-0001',
    timezoneOffsetMinutes: 480,
    clientContractVersion: 1,
  }),
  {
    idempotencyKey: 'daily-login-claim-0001',
    timezoneOffsetMinutes: 480,
    clientContractVersion: 1,
  },
);
assert.throws(
  () => dailyStore.normalizeDailyLoginClaim({
    idempotencyKey: 'daily-login-claim-0001',
    timezoneOffsetMinutes: 480,
    clientContractVersion: 1,
    amount: 999,
  }),
  /cardverse_daily_login_client_authority_forbidden/,
);

const drawStore = await import('../../server/cardverse/draw_store.js');
assert.deepEqual(
  drawStore.normalizeDrawTokenRequest({
    idempotencyKey: 'draw-token-redeem-0001',
    clientRevealVersion: 1,
  }),
  {
    idempotencyKey: 'draw-token-redeem-0001',
    clientRevealVersion: 1,
  },
);
assert.deepEqual(
  drawStore.normalizeDrawTokenRequest({
    idempotencyKey: 'draw:12:1',
    clientRevealVersion: 1,
  }),
  {
    idempotencyKey: 'draw:12:1',
    clientRevealVersion: 1,
  },
);
assert.equal(
  drawStore.storageDrawIdempotencyKey('draw:12:1').length,
  76,
);
assert.match(
  drawStore.storageDrawIdempotencyKey('draw:12:1'),
  /^legacy-draw:[0-9a-f]{64}$/,
);
assert.equal(
  drawStore.storageDrawIdempotencyKey('draw-token-redeem-0001'),
  'draw-token-redeem-0001',
);

assert.throws(
  () => drawStore.normalizeDrawTokenRequest({
    idempotencyKey: 'draw-token-redeem-0001',
    clientRevealVersion: 1,
    finish: 'secret',
  }),
  /cardverse_draw_client_authority_forbidden/,
);

const dailyEndpoint = await import('../../server/cardverse/routes/rewards/daily-login.js');
const drawEndpoint = await import('../../server/cardverse/routes/draws/redeem.js');
assert.equal(typeof dailyEndpoint.default, 'function');
assert.equal(typeof drawEndpoint.default, 'function');

console.log('✓ Daily login and Draw Token contracts passed');

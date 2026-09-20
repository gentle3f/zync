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
  eligibilityKey: 'weekly_real_world_three:2026-09-13T16:00:00.000Z',
  questId: 'weekly_real_world_three',
  cycleStart: '2026-09-13T16:00:00.000Z',
  proofEventIds: ['event-3', 'event-1', 'event-2', 'event-2'],
  idempotencyKey: 'quest-claim-attempt-0001',
  clientContractVersion: 1,
});
assert.deepEqual(claim.proofEventIds, ['event-1', 'event-2', 'event-3']);
assert.equal(questDefinition(claim.questId).rewardKind, 'standard_pack');

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
    interest_categories: ['sports'],
    weekly_cycle_start: '2026-09-13T16:00:00.000Z',
  },
  {
    event_type: 'one_to_one_zync',
    repeat_person: true,
    interest_categories: ['food'],
    weekly_cycle_start: '2026-09-13T16:00:00.000Z',
  },
  {
    event_type: 'tried_together_completed',
    repeat_person: false,
    interest_categories: ['music'],
    weekly_cycle_start: '2026-09-13T16:00:00.000Z',
  },
];

assert.equal(
  evaluateQuestProofs(
    'weekly_real_world_three',
    '2026-09-13T16:00:00.000Z',
    weeklyRows,
  ).current,
  3,
);

assert.equal(
  evaluateQuestProofs(
    'weekly_three_interest_worlds',
    '2026-09-13T16:00:00.000Z',
    weeklyRows,
  ).current,
  3,
);

assert.throws(
  () => evaluateQuestProofs(
    'weekly_meet_two_new_people',
    '2026-09-13T16:00:00.000Z',
    weeklyRows,
  ),
  /cardverse_quest_proof_insufficient/,
);

assert.throws(
  () => evaluateQuestProofs(
    'weekly_real_world_three',
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
    'weekly_meet_two_new_people',
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

console.log('✓ Unclassified relay proofs cannot satisfy new-person Quest');

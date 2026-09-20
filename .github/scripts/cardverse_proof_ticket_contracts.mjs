import assert from 'node:assert/strict';
import {
  createRelayCompletionTicket,
  createRelayResponderCapability,
  relayResponderCapabilityHash,
  verifyRelayCompletionTicket,
} from '../../api/_cardverse/proof_ticket.js';
import {
  normalizeRelayProofRedemption,
  redeemRelayCompletionTicket,
} from '../../api/_cardverse/proof_ticket_redemption.js';

process.env.ZYNC_CARDVERSE_PROOF_SECRET =
  'unit-test-cardverse-proof-secret-1234567890';
process.env.CARDVERSE_PROOF_TICKET_DAYS = '30';

const SESSION_ID = 'ABCDEFGHIJKLMNOPQRSTUVWX';
const ACCOUNT = '11111111-1111-4111-8111-111111111111';
const PROOF_ID = '22222222-2222-4222-8222-222222222222';
const COMPLETED = Date.parse('2026-09-20T02:00:00.000Z');

const capability = createRelayResponderCapability(SESSION_ID, 'OpaquePayload_123');
assert.match(capability, /^[A-Za-z0-9_-]{43}$/);
assert.match(relayResponderCapabilityHash(capability), /^[a-f0-9]{64}$/);

const hostTicket = createRelayCompletionTicket({
  sessionId: SESSION_ID,
  role: 'host',
  completedAtMs: COMPLETED,
});
const scannerTicket = createRelayCompletionTicket({
  sessionId: SESSION_ID,
  role: 'scanner',
  completedAtMs: COMPLETED,
});
assert.notEqual(hostTicket, scannerTicket);

const verified = verifyRelayCompletionTicket(hostTicket, {
  nowMs: COMPLETED + 1000,
});
assert.equal(verified.eventType, 'one_to_one_zync');
assert.equal(verified.source, 'one_to_one');
assert.equal(verified.participantCount, 2);
assert.equal(verified.occurredAt, '2026-09-20T02:00:00.000Z');

assert.throws(
  () => verifyRelayCompletionTicket(hostTicket + 'x', { nowMs: COMPLETED + 1000 }),
  /cardverse_proof_ticket_invalid/,
);
assert.throws(
  () => verifyRelayCompletionTicket(hostTicket, {
    nowMs: COMPLETED + 31 * 86_400_000,
  }),
  /cardverse_proof_ticket_expired/,
);

assert.deepEqual(
  normalizeRelayProofRedemption({
    ticket: hostTicket,
    clientEventId: 'relay-event-host-1',
    timezoneOffsetMinutes: 480,
  }),
  {
    ticket: hostTicket,
    clientEventId: 'relay-event-host-1',
    timezoneOffsetMinutes: 480,
  },
);
assert.throws(
  () => normalizeRelayProofRedemption({
    ticket: hostTicket,
    clientEventId: 'relay-event-host-1',
    timezoneOffsetMinutes: 480,
    repeatPerson: false,
  }),
  /cardverse_proof_client_authority_forbidden/,
);

{
  let call = 0;
  const tx = {
    async query(text, params) {
      call += 1;
      if (text.includes("status = 'active' FOR UPDATE")) {
        assert.equal(params[0], ACCOUNT);
        return [{ id: ACCOUNT }];
      }
      if (text.includes('pg_advisory_xact_lock')) return [];
      if (text.includes('WHERE issuer_ticket_id = $1 FOR UPDATE')) return [];
      if (text.includes('INSERT INTO cardverse_reward_proofs')) {
        assert.equal(params[0], ACCOUNT);
        assert.equal(params[1], 'relay-event-host-1');
        assert.equal(params[2], 'one_to_one_zync');
        assert.equal(params[3], 'one_to_one');
        assert.equal(params[6], null);
        assert.deepEqual(params[8], []);
        assert.equal(params[12], 'relay_completion_ticket_v1');
        assert.equal(params[13], verified.issuerTicketId);
        return [{
          proof_id: PROOF_ID,
          verified_at: '2026-09-20T02:00:01.000Z',
        }];
      }
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { transaction: (fn) => fn(tx) };
  const result = await redeemRelayCompletionTicket(
    db,
    ACCOUNT,
    {
      ticket: hostTicket,
      clientEventId: 'relay-event-host-1',
      timezoneOffsetMinutes: 480,
    },
    { nowMs: COMPLETED + 1000 },
  );
  assert.equal(result.proofId, PROOF_ID);
  assert.equal(result.idempotentReplay, false);
  assert.equal(call, 4);
}

{
  const tx = {
    async query(text, params) {
      if (text.includes("status = 'active' FOR UPDATE")) {
        assert.equal(params[0], ACCOUNT);
        return [{ id: ACCOUNT }];
      }
      if (text.includes('pg_advisory_xact_lock')) return [];
      if (text.includes('WHERE issuer_ticket_id = $1 FOR UPDATE')) {
        return [{
          proof_id: PROOF_ID,
          account_id: ACCOUNT,
          client_event_id: 'relay-event-host-1',
          verified_at: '2026-09-20T02:00:01.000Z',
          daily_cycle_start: '2026-09-19T16:00:00.000Z',
          weekly_cycle_start: '2026-09-13T16:00:00.000Z',
        }];
      }
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { transaction: (fn) => fn(tx) };
  const replay = await redeemRelayCompletionTicket(
    db,
    ACCOUNT,
    {
      ticket: hostTicket,
      clientEventId: 'relay-event-host-1',
      timezoneOffsetMinutes: 480,
    },
    { nowMs: COMPLETED + 1000 },
  );
  assert.equal(replay.proofId, PROOF_ID);
  assert.equal(replay.idempotentReplay, true);
}

{
  const tx = {
    async query(text, params) {
      if (text.includes("status = 'active' FOR UPDATE")) {
        assert.equal(params[0], ACCOUNT);
        return [{ id: ACCOUNT }];
      }
      if (text.includes('pg_advisory_xact_lock')) return [];
      if (text.includes('WHERE issuer_ticket_id = $1 FOR UPDATE')) {
        return [{
          proof_id: PROOF_ID,
          account_id: '33333333-3333-4333-8333-333333333333',
          client_event_id: 'other-event',
        }];
      }
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { transaction: (fn) => fn(tx) };
  await assert.rejects(
    () => redeemRelayCompletionTicket(
      db,
      ACCOUNT,
      {
        ticket: hostTicket,
        clientEventId: 'relay-event-host-1',
        timezoneOffsetMinutes: 480,
      },
      { nowMs: COMPLETED + 1000 },
    ),
    /cardverse_proof_ticket_already_redeemed/,
  );
}

{
  const db = {
    transaction: (callback) => callback({
      async query(text) {
        if (text.includes("status = 'active' FOR UPDATE")) return [];
        throw new Error('unexpected query after inactive account');
      },
    }),
  };
  await assert.rejects(
    () => redeemRelayCompletionTicket(
      db,
      ACCOUNT,
      {
        ticket: hostTicket,
        clientEventId: 'relay-event-host-1',
        timezoneOffsetMinutes: 480,
      },
      { nowMs: COMPLETED + 1000 },
    ),
    /cardverse_account_not_active/,
  );
}

const endpoint = await import('../../api/v1/cardverse/proofs/redeem.js');
assert.equal(typeof endpoint.default, 'function');

console.log('✓ Cardverse anonymous relay proof-ticket contracts passed');

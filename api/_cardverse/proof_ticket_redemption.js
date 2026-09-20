import { recordTrustedRewardProof } from './reward_store.js';
import { verifyRelayCompletionTicket } from './proof_ticket.js';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function domainError(code) {
  const error = new Error(code);
  error.code = code;
  return error;
}

function cleanText(value, max) {
  if (typeof value !== 'string') return '';
  const clean = value.trim();
  return clean.length <= max ? clean : '';
}

function cleanUuid(value, code) {
  const clean = cleanText(value, 64).toLowerCase();
  if (!UUID.test(clean)) throw domainError(code);
  return clean;
}

export function normalizeRelayProofRedemption(raw = {}) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError('cardverse_proof_redemption_invalid');
  }
  if ('accountId' in raw || 'repeatPerson' in raw || 'interestCategories' in raw) {
    throw domainError('cardverse_proof_client_authority_forbidden');
  }

  const ticket = cleanText(raw.ticket, 4096);
  const clientEventId = cleanText(raw.clientEventId, 160);
  const timezoneOffsetMinutes = Number(raw.timezoneOffsetMinutes);

  if (!ticket || !clientEventId) throw domainError('cardverse_proof_redemption_invalid');
  if (!Number.isInteger(timezoneOffsetMinutes) ||
      timezoneOffsetMinutes < -840 || timezoneOffsetMinutes > 840) {
    throw domainError('cardverse_timezone_offset_invalid');
  }

  return { ticket, clientEventId, timezoneOffsetMinutes };
}

export async function redeemRelayCompletionTicket(
  db,
  accountIdValue,
  rawInput,
  options = {},
) {
  if (!db || typeof db.transaction !== 'function') {
    throw domainError('cardverse_transaction_required');
  }

  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');
  const input = normalizeRelayProofRedemption(rawInput);
  const proof = verifyRelayCompletionTicket(input.ticket, options);

  return db.transaction(async (tx) => {
    // Re-check and lock account state inside the durable mutation transaction.
    // Route-level session resolution alone cannot close a concurrent delete race.
    const accounts = await tx.query(
      "SELECT id FROM zync_accounts WHERE id = $1 AND status = 'active' FOR UPDATE",
      [accountId],
    );
    if (accounts.length !== 1) throw domainError('cardverse_account_not_active');

    await tx.query(
      'SELECT pg_advisory_xact_lock(hashtextextended($1, 0))',
      [proof.issuerTicketId],
    );

    const existing = await tx.query(
      'SELECT proof_id, account_id, client_event_id, verified_at, ' +
        'daily_cycle_start, weekly_cycle_start ' +
      'FROM cardverse_reward_proofs WHERE issuer_ticket_id = $1 FOR UPDATE',
      [proof.issuerTicketId],
    );

    if (existing.length > 0) {
      const row = existing[0];
      if (row.account_id !== accountId || row.client_event_id !== input.clientEventId) {
        throw domainError('cardverse_proof_ticket_already_redeemed');
      }
      return {
        proofId: row.proof_id,
        clientEventId: row.client_event_id,
        verifiedAt: row.verified_at instanceof Date
          ? row.verified_at.toISOString()
          : row.verified_at,
        dailyCycleStart: row.daily_cycle_start instanceof Date
          ? row.daily_cycle_start.toISOString()
          : row.daily_cycle_start,
        weeklyCycleStart: row.weekly_cycle_start instanceof Date
          ? row.weekly_cycle_start.toISOString()
          : row.weekly_cycle_start,
        idempotentReplay: true,
      };
    }

    const result = await recordTrustedRewardProof(tx, {
      accountId,
      clientEventId: input.clientEventId,
      eventType: proof.eventType,
      source: proof.source,
      occurredAt: proof.occurredAt,
      participantCount: proof.participantCount,
      repeatPerson: null,
      interestCategories: [],
      timezoneOffsetMinutes: input.timezoneOffsetMinutes,
      verifier: 'relay_completion_ticket_v1',
      issuerTicketId: proof.issuerTicketId,
    });

    return {
      ...result,
      idempotentReplay: false,
    };
  });
}

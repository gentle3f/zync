import { createHash } from 'node:crypto';

import { canonicalQuestCycles } from './reward_store.js';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const IDEMPOTENCY_KEY = /^[A-Za-z0-9._:-]{16,128}$/;
const MIN_CLAIM_GAP_MS = 20 * 60 * 60 * 1000;

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

function asIso(value) {
  if (value instanceof Date) return value.toISOString();
  return typeof value === 'string' ? value : null;
}

function asJsonObject(value) {
  if (!value) return null;
  if (typeof value === 'object') return value;
  if (typeof value !== 'string') return null;
  try {
    const parsed = JSON.parse(value);
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch (_) {
    return null;
  }
}

export function normalizeDailyLoginClaim(raw = {}) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError('cardverse_daily_login_claim_invalid');
  }
  const forbidden = new Set([
    'accountId',
    'reward',
    'kind',
    'amount',
    'drawTokens',
    'cards',
    'finish',
    'rarity',
  ]);
  if (Object.keys(raw).some((key) => forbidden.has(key))) {
    throw domainError('cardverse_daily_login_client_authority_forbidden');
  }

  const idempotencyKey = cleanText(raw.idempotencyKey, 128);
  const timezoneOffsetMinutes = Number(raw.timezoneOffsetMinutes);
  const clientContractVersion = Number(raw.clientContractVersion);

  if (!IDEMPOTENCY_KEY.test(idempotencyKey) ||
      !Number.isInteger(timezoneOffsetMinutes) ||
      timezoneOffsetMinutes < -840 ||
      timezoneOffsetMinutes > 840 ||
      clientContractVersion !== 1) {
    throw domainError('cardverse_daily_login_claim_invalid');
  }

  return {
    idempotencyKey,
    timezoneOffsetMinutes,
    clientContractVersion,
  };
}

function requestHash(accountId, claim) {
  return createHash('sha256')
    .update(JSON.stringify({
      accountId,
      timezoneOffsetMinutes: claim.timezoneOffsetMinutes,
      clientContractVersion: claim.clientContractVersion,
    }))
    .digest('hex');
}

async function replay(tx, accountId, claim, hash) {
  const rows = await tx.query(
    'SELECT request_hash, response_json FROM cardverse_idempotency_records ' +
      'WHERE account_id = $1 AND scope = $2 AND idempotency_key = $3 FOR UPDATE',
    [accountId, 'daily_login_claim', claim.idempotencyKey],
  );
  if (rows.length !== 1) throw domainError('cardverse_idempotency_lost');
  if (rows[0].request_hash !== hash) throw domainError('cardverse_idempotency_conflict');
  const response = asJsonObject(rows[0].response_json);
  if (!response) throw domainError('cardverse_idempotency_incomplete');
  return { ...response, idempotentReplay: true };
}

export async function claimDailyLoginReward(
  db,
  accountIdValue,
  rawClaim,
  options = {},
) {
  if (!db || typeof db.transaction !== 'function') {
    throw domainError('cardverse_transaction_required');
  }

  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');
  const claim = normalizeDailyLoginClaim(rawClaim);
  const now = options.now instanceof Date ? options.now : new Date();
  if (Number.isNaN(now.getTime())) {
    throw domainError('cardverse_daily_login_time_invalid');
  }
  const hash = requestHash(accountId, claim);
  const cycles = canonicalQuestCycles(now, claim.timezoneOffsetMinutes);
  const cycleStart = cycles.dailyCycleStart;
  const eligibilityKey = 'daily_login:' + cycleStart;

  return db.transaction(async (tx) => {
    const accounts = await tx.query(
      "SELECT id FROM zync_accounts WHERE id = $1 AND status = 'active' FOR UPDATE",
      [accountId],
    );
    if (accounts.length !== 1) throw domainError('cardverse_account_not_active');

    await tx.query(
      'SELECT pg_advisory_xact_lock(hashtextextended($1, 0))',
      [accountId + ':daily_login'],
    );

    const reserved = await tx.query(
      'INSERT INTO cardverse_idempotency_records ' +
        '(account_id, scope, idempotency_key, request_hash) ' +
        "VALUES ($1, 'daily_login_claim', $2, $3) " +
        'ON CONFLICT (account_id, scope, idempotency_key) DO NOTHING ' +
        'RETURNING request_hash',
      [accountId, claim.idempotencyKey, hash],
    );
    if (reserved.length === 0) {
      return replay(tx, accountId, claim, hash);
    }

    const sameCycle = await tx.query(
      'SELECT grant_id FROM cardverse_reward_grants ' +
        'WHERE account_id = $1 AND quest_id = $2 AND cycle_start = $3 FOR UPDATE',
      [accountId, 'daily_login', cycleStart],
    );
    if (sameCycle.length > 0) {
      throw domainError('cardverse_daily_login_already_claimed');
    }

    const recent = await tx.query(
      'SELECT issued_at FROM cardverse_reward_grants ' +
        'WHERE account_id = $1 AND quest_id = $2 ' +
        'ORDER BY issued_at DESC LIMIT 1 FOR UPDATE',
      [accountId, 'daily_login'],
    );
    if (recent.length > 0) {
      const last = new Date(recent[0].issued_at);
      if (!Number.isNaN(last.getTime()) &&
          now.getTime() - last.getTime() < MIN_CLAIM_GAP_MS) {
        throw domainError('cardverse_daily_login_too_soon');
      }
    }

    const grants = await tx.query(
      'INSERT INTO cardverse_reward_grants (' +
        'account_id, eligibility_key, quest_id, cycle_start, reward_kind, amount' +
      ") VALUES ($1, $2, 'daily_login', $3, 'draw_token', 1) " +
      'RETURNING grant_id, server_sequence, issued_at',
      [accountId, eligibilityKey, cycleStart],
    );
    const grant = grants[0];
    if (!grant?.grant_id) throw domainError('cardverse_reward_grant_create_failed');

    await tx.query(
      'INSERT INTO cardverse_draw_token_balances ' +
        '(account_id, quantity, locked_quantity, version) VALUES ($1, 1, 0, 1) ' +
      'ON CONFLICT (account_id) DO UPDATE SET ' +
        'quantity = cardverse_draw_token_balances.quantity + 1, ' +
        'version = cardverse_draw_token_balances.version + 1, updated_at = now()',
      [accountId],
    );

    await tx.query(
      'INSERT INTO cardverse_inventory_ledger ' +
        '(account_id, event_type, asset_kind, asset_key, quantity_delta, correlation_id, metadata) ' +
        "VALUES ($1, 'quest_reward', 'draw_token', 'draw_token', 1, $2, $3::jsonb)",
      [
        accountId,
        grant.grant_id,
        JSON.stringify({ questId: 'daily_login', source: 'daily_check_in' }),
      ],
    );

    const response = {
      grantId: grant.grant_id,
      eligibilityKey,
      questId: 'daily_login',
      idempotencyKey: claim.idempotencyKey,
      kind: 'drawToken',
      amount: 1,
      issuedAt: asIso(grant.issued_at),
      serverSequence: Number(grant.server_sequence),
      unopenedPackIds: [],
      cycleStart,
      nextEligibleAt: new Date(now.getTime() + MIN_CLAIM_GAP_MS).toISOString(),
      serverAuthoritative: true,
    };

    await tx.query(
      'UPDATE cardverse_idempotency_records SET response_json = $4::jsonb, completed_at = now() ' +
        "WHERE account_id = $1 AND scope = 'daily_login_claim' AND idempotency_key = $2 " +
        'AND request_hash = $3',
      [accountId, claim.idempotencyKey, hash, JSON.stringify(response)],
    );

    return { ...response, idempotentReplay: false };
  });
}

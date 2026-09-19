import { createHash } from 'node:crypto';

const QUESTS = Object.freeze({
  daily_make_a_zync: Object.freeze({
    cadence: 'daily',
    metric: 'one_to_one_zyncs',
    target: 1,
    rewardKind: 'draw_token',
    responseKind: 'drawToken',
    amount: 1,
  }),
  daily_tried_together: Object.freeze({
    cadence: 'daily',
    metric: 'tried_together',
    target: 1,
    rewardKind: 'draw_token',
    responseKind: 'drawToken',
    amount: 1,
  }),
  weekly_meet_two_new_people: Object.freeze({
    cadence: 'weekly',
    metric: 'new_person_zyncs',
    target: 2,
    rewardKind: 'standard_pack',
    responseKind: 'standardPack',
    amount: 1,
  }),
  weekly_real_world_three: Object.freeze({
    cadence: 'weekly',
    metric: 'real_world_actions',
    target: 3,
    rewardKind: 'standard_pack',
    responseKind: 'standardPack',
    amount: 1,
  }),
  weekly_three_interest_worlds: Object.freeze({
    cadence: 'weekly',
    metric: 'distinct_interest_categories',
    target: 3,
    rewardKind: 'discovery_pack',
    responseKind: 'discoveryPack',
    amount: 1,
  }),
});

const EVENT_TYPES = new Set(['one_to_one_zync', 'tried_together_completed']);
const SOURCES = new Set(['one_to_one', 'zync_now']);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const IDEMPOTENCY_KEY = /^[A-Za-z0-9._:-]{16,128}$/;
const CATEGORY = /^[a-z0-9_]{1,32}$/;
const MAX_PROOFS = 8;

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

function parseDate(value, code) {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) throw domainError(code);
  return date;
}

function iso(value) {
  return parseDate(value, 'cardverse_date_invalid').toISOString();
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

export function questDefinition(questIdValue) {
  const questId = cleanText(questIdValue, 120);
  const definition = QUESTS[questId];
  if (!definition) throw domainError('cardverse_quest_unknown');
  return { questId, ...definition };
}

export function canonicalQuestCycles(occurredAtValue, timezoneOffsetMinutesValue) {
  const occurredAt = parseDate(occurredAtValue, 'cardverse_proof_time_invalid');
  const offset = Number(timezoneOffsetMinutesValue);
  if (!Number.isInteger(offset) || offset < -840 || offset > 840) {
    throw domainError('cardverse_timezone_offset_invalid');
  }

  const shifted = new Date(occurredAt.getTime() + offset * 60_000);
  const localDayMs = Date.UTC(
    shifted.getUTCFullYear(),
    shifted.getUTCMonth(),
    shifted.getUTCDate(),
  );
  const dailyStart = new Date(localDayMs - offset * 60_000);
  const mondayDistance = (shifted.getUTCDay() + 6) % 7;
  const weeklyStart = new Date(
    localDayMs - mondayDistance * 86_400_000 - offset * 60_000,
  );

  return {
    dailyCycleStart: dailyStart.toISOString(),
    weeklyCycleStart: weeklyStart.toISOString(),
  };
}

export function normalizeTrustedRewardProof(input = {}) {
  const accountId = cleanUuid(input.accountId, 'cardverse_account_id_invalid');
  const clientEventId = cleanText(input.clientEventId, 160);
  const eventType = cleanText(input.eventType, 64).toLowerCase();
  const source = cleanText(input.source, 32).toLowerCase();
  const occurredAt = parseDate(input.occurredAt, 'cardverse_proof_time_invalid');
  const participantCount = Number(input.participantCount);
  const timezoneOffsetMinutes = Number(input.timezoneOffsetMinutes);
  const verifier = cleanText(input.verifier, 80);
  const issuerTicketId = cleanText(input.issuerTicketId ?? '', 128) || null;
  const mode = cleanText(input.mode ?? '', 32);
  const repeatPerson = input.repeatPerson == null
    ? null
    : input.repeatPerson === true;
  const categories = [...new Set(
    (Array.isArray(input.interestCategories) ? input.interestCategories : [])
      .filter((item) => typeof item === 'string')
      .map((item) => item.trim().toLowerCase())
      .filter((item) => CATEGORY.test(item)),
  )].sort();

  if (!clientEventId) throw domainError('cardverse_proof_event_id_invalid');
  if (!EVENT_TYPES.has(eventType)) throw domainError('cardverse_proof_event_type_invalid');
  if (!SOURCES.has(source)) throw domainError('cardverse_proof_source_invalid');
  if (!Number.isInteger(participantCount) || participantCount < 2 || participantCount > 8) {
    throw domainError('cardverse_proof_participant_count_invalid');
  }
  if (!Number.isInteger(timezoneOffsetMinutes) ||
      timezoneOffsetMinutes < -840 || timezoneOffsetMinutes > 840) {
    throw domainError('cardverse_timezone_offset_invalid');
  }
  if (!verifier) throw domainError('cardverse_proof_verifier_missing');
  if (categories.length > 8) throw domainError('cardverse_proof_categories_invalid');

  const cycles = canonicalQuestCycles(occurredAt, timezoneOffsetMinutes);
  return {
    accountId,
    clientEventId,
    eventType,
    source,
    occurredAt: occurredAt.toISOString(),
    participantCount,
    repeatPerson,
    mode,
    interestCategories: categories,
    timezoneOffsetMinutes,
    verifier,
    issuerTicketId,
    ...cycles,
  };
}

export async function recordTrustedRewardProof(db, rawInput) {
  if (!db || typeof db.query !== 'function') throw domainError('cardverse_database_invalid');
  const input = normalizeTrustedRewardProof(rawInput);

  const rows = await db.query(
    'INSERT INTO cardverse_reward_proofs (' +
      'account_id, client_event_id, event_type, source, occurred_at, participant_count, ' +
      'repeat_person, mode, interest_categories, timezone_offset_minutes, ' +
      'daily_cycle_start, weekly_cycle_start, verifier, issuer_ticket_id' +
    ') VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::text[], $10, $11, $12, $13, $14) ' +
    'ON CONFLICT (account_id, client_event_id) DO NOTHING ' +
    'RETURNING proof_id, verified_at',
    [
      input.accountId,
      input.clientEventId,
      input.eventType,
      input.source,
      input.occurredAt,
      input.participantCount,
      input.repeatPerson,
      input.mode,
      input.interestCategories,
      input.timezoneOffsetMinutes,
      input.dailyCycleStart,
      input.weeklyCycleStart,
      input.verifier,
      input.issuerTicketId,
    ],
  );
  if (rows.length !== 1) throw domainError('cardverse_proof_already_recorded');
  return {
    proofId: rows[0].proof_id,
    clientEventId: input.clientEventId,
    verifiedAt: iso(rows[0].verified_at),
    dailyCycleStart: input.dailyCycleStart,
    weeklyCycleStart: input.weeklyCycleStart,
  };
}

export function normalizeQuestClaim(raw = {}) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError('cardverse_quest_claim_invalid');
  }
  const forbidden = new Set([
    'accountId',
    'reward',
    'rewardKind',
    'kind',
    'amount',
    'drawTokens',
    'packId',
    'packIds',
    'finish',
    'rarity',
    'cards',
  ]);
  if (Object.keys(raw).some((key) => forbidden.has(key))) {
    throw domainError('cardverse_quest_client_authority_forbidden');
  }

  const eligibilityKey = cleanText(raw.eligibilityKey, 240);
  const definition = questDefinition(raw.questId);
  const cycleStart = parseDate(raw.cycleStart, 'cardverse_quest_cycle_invalid');
  const idempotencyKey = cleanText(raw.idempotencyKey, 128);
  const clientContractVersion = Number(raw.clientContractVersion);
  const proofEventIds = [...new Set(
    (Array.isArray(raw.proofEventIds) ? raw.proofEventIds : [])
      .filter((item) => typeof item === 'string')
      .map((item) => item.trim())
      .filter(Boolean),
  )].sort();

  if (!eligibilityKey ||
      eligibilityKey !== definition.questId + ':' + cycleStart.toISOString() ||
      !IDEMPOTENCY_KEY.test(idempotencyKey) ||
      clientContractVersion !== 1 ||
      proofEventIds.length < 1 ||
      proofEventIds.length > MAX_PROOFS) {
    throw domainError('cardverse_quest_claim_invalid');
  }

  return {
    eligibilityKey,
    questId: definition.questId,
    cycleStart: cycleStart.toISOString(),
    proofEventIds,
    idempotencyKey,
    clientContractVersion,
  };
}

function rowCategories(row) {
  if (Array.isArray(row.interest_categories)) return row.interest_categories;
  return [];
}

export function evaluateQuestProofs(questIdValue, cycleStartValue, rows) {
  const definition = questDefinition(questIdValue);
  const cycleStart = iso(cycleStartValue);
  const proofs = Array.isArray(rows) ? rows : [];
  const cycleColumn = definition.cadence === 'daily'
    ? 'daily_cycle_start'
    : 'weekly_cycle_start';

  if (proofs.some((row) => iso(row[cycleColumn]) !== cycleStart)) {
    throw domainError('cardverse_quest_proof_cycle_mismatch');
  }

  let current;
  switch (definition.metric) {
    case 'one_to_one_zyncs':
      current = proofs.filter((row) => row.event_type === 'one_to_one_zync').length;
      break;
    case 'new_person_zyncs':
      current = proofs.filter(
        (row) => row.event_type === 'one_to_one_zync' && row.repeat_person === false,
      ).length;
      break;
    case 'tried_together':
      current = proofs.filter(
        (row) => row.event_type === 'tried_together_completed',
      ).length;
      break;
    case 'real_world_actions':
      current = proofs.filter(
        (row) => EVENT_TYPES.has(row.event_type),
      ).length;
      break;
    case 'distinct_interest_categories': {
      const categories = new Set();
      for (const row of proofs) {
        for (const category of rowCategories(row)) {
          if (CATEGORY.test(category)) categories.add(category);
        }
      }
      current = categories.size;
      break;
    }
    default:
      throw domainError('cardverse_quest_unknown');
  }

  if (current < definition.target) throw domainError('cardverse_quest_proof_insufficient');
  return {
    questId: definition.questId,
    rewardKind: definition.rewardKind,
    responseKind: definition.responseKind,
    amount: definition.amount,
    target: definition.target,
    current,
  };
}

function claimHash(accountId, claim) {
  return createHash('sha256')
    .update(JSON.stringify({
      accountId,
      eligibilityKey: claim.eligibilityKey,
      questId: claim.questId,
      cycleStart: claim.cycleStart,
      proofEventIds: claim.proofEventIds,
      clientContractVersion: claim.clientContractVersion,
    }))
    .digest('hex');
}

async function idempotentReplay(tx, accountId, claim, hash) {
  const rows = await tx.query(
    'SELECT request_hash, response_json FROM cardverse_idempotency_records ' +
      'WHERE account_id = $1 AND scope = $2 AND idempotency_key = $3 FOR UPDATE',
    [accountId, 'quest_claim', claim.idempotencyKey],
  );
  if (rows.length !== 1) throw domainError('cardverse_idempotency_lost');
  if (rows[0].request_hash !== hash) throw domainError('cardverse_idempotency_conflict');
  const response = asJsonObject(rows[0].response_json);
  if (!response) throw domainError('cardverse_idempotency_incomplete');
  return { ...response, idempotentReplay: true };
}

export async function claimQuestReward(db, accountIdValue, rawClaim) {
  if (!db || typeof db.transaction !== 'function') {
    throw domainError('cardverse_transaction_required');
  }
  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');
  const claim = normalizeQuestClaim(rawClaim);
  const hash = claimHash(accountId, claim);

  return db.transaction(async (tx) => {
    const accounts = await tx.query(
      "SELECT id FROM zync_accounts WHERE id = $1 AND status = 'active' FOR UPDATE",
      [accountId],
    );
    if (accounts.length !== 1) throw domainError('cardverse_account_not_active');

    await tx.query(
      'SELECT pg_advisory_xact_lock(hashtextextended($1, 0))',
      [accountId + ':' + claim.questId + ':' + claim.cycleStart],
    );

    const reserved = await tx.query(
      'INSERT INTO cardverse_idempotency_records ' +
        '(account_id, scope, idempotency_key, request_hash) ' +
        "VALUES ($1, 'quest_claim', $2, $3) " +
        'ON CONFLICT (account_id, scope, idempotency_key) DO NOTHING ' +
        'RETURNING request_hash',
      [accountId, claim.idempotencyKey, hash],
    );
    if (reserved.length === 0) {
      return idempotentReplay(tx, accountId, claim, hash);
    }

    const existing = await tx.query(
      'SELECT grant_id FROM cardverse_reward_grants ' +
        'WHERE account_id = $1 AND quest_id = $2 AND cycle_start = $3 FOR UPDATE',
      [accountId, claim.questId, claim.cycleStart],
    );
    if (existing.length > 0) throw domainError('cardverse_quest_already_claimed');

    const proofRows = await tx.query(
      'SELECT proof_id, client_event_id, event_type, repeat_person, interest_categories, ' +
        'daily_cycle_start, weekly_cycle_start ' +
      'FROM cardverse_reward_proofs ' +
      'WHERE account_id = $1 AND client_event_id = ANY($2::text[]) FOR UPDATE',
      [accountId, claim.proofEventIds],
    );
    if (proofRows.length !== claim.proofEventIds.length) {
      throw domainError('cardverse_quest_proof_unknown');
    }

    const reward = evaluateQuestProofs(claim.questId, claim.cycleStart, proofRows);
    const grants = await tx.query(
      'INSERT INTO cardverse_reward_grants (' +
        'account_id, eligibility_key, quest_id, cycle_start, reward_kind, amount' +
      ') VALUES ($1, $2, $3, $4, $5, $6) ' +
      'RETURNING grant_id, server_sequence, issued_at',
      [
        accountId,
        claim.eligibilityKey,
        claim.questId,
        claim.cycleStart,
        reward.rewardKind,
        reward.amount,
      ],
    );
    const grant = grants[0];
    if (!grant?.grant_id) throw domainError('cardverse_reward_grant_create_failed');

    for (const proof of proofRows) {
      await tx.query(
        'INSERT INTO cardverse_reward_grant_proofs (grant_id, proof_id) VALUES ($1, $2)',
        [grant.grant_id, proof.proof_id],
      );
    }

    const unopenedPackIds = [];
    if (reward.rewardKind === 'draw_token') {
      await tx.query(
        'INSERT INTO cardverse_draw_token_balances ' +
          '(account_id, quantity, locked_quantity, version) VALUES ($1, $2, 0, 1) ' +
        'ON CONFLICT (account_id) DO UPDATE SET ' +
          'quantity = cardverse_draw_token_balances.quantity + EXCLUDED.quantity, ' +
          'version = cardverse_draw_token_balances.version + 1, updated_at = now()',
        [accountId, reward.amount],
      );
      await tx.query(
        'INSERT INTO cardverse_inventory_ledger ' +
          '(account_id, event_type, asset_kind, asset_key, quantity_delta, correlation_id, metadata) ' +
          "VALUES ($1, 'quest_reward', 'draw_token', 'draw_token', $2, $3, $4::jsonb)",
        [
          accountId,
          reward.amount,
          grant.grant_id,
          JSON.stringify({ questId: claim.questId }),
        ],
      );
    } else {
      if (reward.amount !== 1) throw domainError('cardverse_pack_reward_amount_unsupported');
      const packType = reward.rewardKind === 'standard_pack' ? 'standard' : 'discovery';
      const packs = await tx.query(
        'INSERT INTO cardverse_pack_entitlements (account_id, grant_id, pack_type) ' +
          'VALUES ($1, $2, $3) RETURNING pack_id',
        [accountId, grant.grant_id, packType],
      );
      const packId = packs[0]?.pack_id;
      if (!packId) throw domainError('cardverse_pack_issue_failed');
      unopenedPackIds.push(packId);

      await tx.query(
        'INSERT INTO cardverse_inventory_ledger ' +
          '(account_id, event_type, asset_kind, asset_key, quantity_delta, correlation_id, metadata) ' +
          "VALUES ($1, 'pack_grant', 'pack', $2, 1, $3, $4::jsonb)",
        [
          accountId,
          packId,
          grant.grant_id,
          JSON.stringify({ questId: claim.questId, packType }),
        ],
      );
    }

    const response = {
      grantId: grant.grant_id,
      eligibilityKey: claim.eligibilityKey,
      questId: claim.questId,
      idempotencyKey: claim.idempotencyKey,
      kind: reward.responseKind,
      amount: reward.amount,
      issuedAt: iso(grant.issued_at),
      serverSequence: Number(grant.server_sequence),
      unopenedPackIds,
      serverAuthoritative: true,
    };

    await tx.query(
      'UPDATE cardverse_idempotency_records SET response_json = $4::jsonb, completed_at = now() ' +
        "WHERE account_id = $1 AND scope = 'quest_claim' AND idempotency_key = $2 " +
        'AND request_hash = $3',
      [accountId, claim.idempotencyKey, hash, JSON.stringify(response)],
    );

    return { ...response, idempotentReplay: false };
  });
}

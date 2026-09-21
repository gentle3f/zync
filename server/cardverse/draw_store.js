import { createHash } from 'node:crypto';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const IDEMPOTENCY_KEY = /^[A-Za-z0-9._:-]{16,128}$/;
const LEGACY_DRAW_IDEMPOTENCY_KEY = /^draw:[0-9]+:[0-9]+$/;
const FINISH_IDS = new Set(['normal', 'foil', 'holo', 'prism', 'legendary', 'secret']);

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

function asIso(value) {
  if (value instanceof Date) return value.toISOString();
  return typeof value === 'string' ? value : null;
}

export function normalizeDrawTokenRequest(raw = {}) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError('cardverse_draw_request_invalid');
  }
  const forbidden = new Set([
    'accountId', 'seed', 'randomSeed', 'result', 'cards', 'finish',
    'rarity', 'odds', 'policyVersion', 'interestId',
  ]);
  if (Object.keys(raw).some((key) => forbidden.has(key))) {
    throw domainError('cardverse_draw_client_authority_forbidden');
  }
  const idempotencyKey = cleanText(raw.idempotencyKey, 128);
  const clientRevealVersion = Number(raw.clientRevealVersion);
  if (!(IDEMPOTENCY_KEY.test(idempotencyKey) ||
        LEGACY_DRAW_IDEMPOTENCY_KEY.test(idempotencyKey)) ||
      !Number.isInteger(clientRevealVersion) ||
      clientRevealVersion < 1 ||
      clientRevealVersion > 100) {
    throw domainError('cardverse_draw_request_invalid');
  }
  return { idempotencyKey, clientRevealVersion };
}

function normalizePlan(raw = {}) {
  const policyVersion = Number(raw.policyVersion);
  const item = raw.item;
  if (!Number.isInteger(policyVersion) || policyVersion < 1 ||
      !item || typeof item !== 'object' || Array.isArray(item)) {
    throw domainError('cardverse_draw_plan_invalid');
  }

  const canonicalInterestId = cleanText(item.canonicalInterestId, 255);
  const finishId = cleanText(item.finishId, 80).toLowerCase();
  const editionId = cleanText(item.editionId, 120).toLowerCase();
  const ownershipKind = cleanText(item.ownershipKind, 32).toLowerCase();
  const quantity = Number(item.quantity ?? 1);
  const artSystemVersion = Number(item.artSystemVersion ?? 1);

  if (!canonicalInterestId || canonicalInterestId.includes('::') ||
      !FINISH_IDS.has(finishId) ||
      !editionId || editionId.includes('::') ||
      ownershipKind !== 'stackable' ||
      quantity !== 1 ||
      !Number.isInteger(artSystemVersion) || artSystemVersion < 1) {
    throw domainError('cardverse_draw_plan_invalid');
  }

  return {
    policyVersion,
    item: {
      canonicalInterestId,
      finishId,
      editionId,
      ownershipKind,
      quantity,
      artSystemVersion,
      variantKey: canonicalInterestId + '::' + finishId + '::' + editionId,
    },
  };
}

function requestHash(accountId, request) {
  return createHash('sha256')
    .update(JSON.stringify({
      accountId,
      clientRevealVersion: request.clientRevealVersion,
    }))
    .digest('hex');
}

async function replay(tx, accountId, request, hash) {
  const rows = await tx.query(
    'SELECT request_hash, response_json FROM cardverse_idempotency_records ' +
      'WHERE account_id = $1 AND scope = $2 AND idempotency_key = $3 FOR UPDATE',
    [accountId, 'draw_token_redeem', request.idempotencyKey],
  );
  if (rows.length !== 1) throw domainError('cardverse_idempotency_lost');
  if (rows[0].request_hash !== hash) throw domainError('cardverse_idempotency_conflict');
  const response = asJsonObject(rows[0].response_json);
  if (!response) throw domainError('cardverse_idempotency_incomplete');
  return { ...response, idempotentReplay: true };
}

export async function redeemDrawToken(db, accountIdValue, rawRequest, options = {}) {
  if (!db || typeof db.transaction !== 'function') {
    throw domainError('cardverse_transaction_required');
  }
  if (typeof options.rollCard !== 'function') {
    throw domainError('cardverse_server_roller_required');
  }

  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');
  const request = normalizeDrawTokenRequest(rawRequest);
  const hash = requestHash(accountId, request);

  return db.transaction(async (tx) => {
    const accounts = await tx.query(
      "SELECT id FROM zync_accounts WHERE id = $1 AND status = 'active' FOR UPDATE",
      [accountId],
    );
    if (accounts.length !== 1) throw domainError('cardverse_account_not_active');

    const reserved = await tx.query(
      'INSERT INTO cardverse_idempotency_records ' +
        '(account_id, scope, idempotency_key, request_hash) ' +
        "VALUES ($1, 'draw_token_redeem', $2, $3) " +
        'ON CONFLICT (account_id, scope, idempotency_key) DO NOTHING ' +
        'RETURNING request_hash',
      [accountId, request.idempotencyKey, hash],
    );
    if (reserved.length === 0) {
      return replay(tx, accountId, request, hash);
    }

    const balances = await tx.query(
      'SELECT quantity, locked_quantity FROM cardverse_draw_token_balances ' +
        'WHERE account_id = $1 FOR UPDATE',
      [accountId],
    );
    const quantity = Number(balances[0]?.quantity ?? 0);
    const locked = Number(balances[0]?.locked_quantity ?? 0);
    if (quantity - locked < 1) throw domainError('cardverse_draw_token_insufficient');

    const plan = normalizePlan(await options.rollCard());
    const drawRows = await tx.query(
      'SELECT gen_random_uuid() AS draw_id, now() AS rolled_at',
    );
    const drawId = drawRows[0]?.draw_id;
    const rolledAt = drawRows[0]?.rolled_at;
    if (!drawId || !rolledAt) throw domainError('cardverse_draw_create_failed');

    await tx.query(
      'UPDATE cardverse_draw_token_balances SET quantity = quantity - 1, ' +
        'version = version + 1, updated_at = now() WHERE account_id = $1',
      [accountId],
    );

    await tx.query(
      'INSERT INTO cardverse_stack_balances ' +
        '(account_id, variant_key, quantity, locked_quantity, version) ' +
        'VALUES ($1, $2, 1, 0, 1) ' +
      'ON CONFLICT (account_id, variant_key) DO UPDATE SET ' +
        'quantity = cardverse_stack_balances.quantity + 1, ' +
        'version = cardverse_stack_balances.version + 1, updated_at = now()',
      [accountId, plan.item.variantKey],
    );

    await tx.query(
      'INSERT INTO cardverse_inventory_ledger ' +
        '(account_id, event_type, asset_kind, asset_key, quantity_delta, correlation_id, metadata) ' +
        "VALUES ($1, 'draw_token_spend', 'draw_token', 'draw_token', -1, $2, $3::jsonb)",
      [
        accountId,
        drawId,
        JSON.stringify({ policyVersion: plan.policyVersion }),
      ],
    );

    await tx.query(
      'INSERT INTO cardverse_inventory_ledger ' +
        '(account_id, event_type, asset_kind, asset_key, quantity_delta, correlation_id, metadata) ' +
        "VALUES ($1, 'stack_credit', 'stackable', $2, 1, $3, $4::jsonb)",
      [
        accountId,
        plan.item.variantKey,
        drawId,
        JSON.stringify({ source: 'draw_token', policyVersion: plan.policyVersion }),
      ],
    );

    const response = {
      drawId,
      idempotencyKey: request.idempotencyKey,
      rolledAt: asIso(rolledAt),
      item: {
        variant: {
          interestId: plan.item.canonicalInterestId,
          finishId: plan.item.finishId,
          editionId: plan.item.editionId,
        },
        quantity: 1,
      },
      serverAuthoritative: true,
    };

    await tx.query(
      'UPDATE cardverse_idempotency_records SET response_json = $4::jsonb, completed_at = now() ' +
        "WHERE account_id = $1 AND scope = 'draw_token_redeem' AND idempotency_key = $2 " +
        'AND request_hash = $3',
      [accountId, request.idempotencyKey, hash, JSON.stringify(response)],
    );

    return { ...response, idempotentReplay: false };
  });
}

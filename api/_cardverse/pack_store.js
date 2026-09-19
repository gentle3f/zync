import { createHash } from 'node:crypto';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const IDEMPOTENCY_KEY = /^[A-Za-z0-9._:-]{16,128}$/;
const FINISH_IDS = new Set(['normal', 'foil', 'holo', 'prism', 'legendary', 'secret']);
const OWNERSHIP_KINDS = new Set(['stackable', 'unique']);
const FORBIDDEN_CLIENT_KEYS = new Set([
  'accountId',
  'seed',
  'randomSeed',
  'result',
  'cards',
  'finish',
  'rarity',
  'odds',
  'policyVersion',
]);

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

function safePart(value, max, code) {
  const clean = cleanText(value, max);
  if (!clean || clean.includes('::')) throw domainError(code);
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

export function normalizePackOpenRequest(raw = {}) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError('cardverse_pack_open_request_invalid');
  }
  if (Object.keys(raw).some((key) => FORBIDDEN_CLIENT_KEYS.has(key))) {
    throw domainError('cardverse_pack_open_client_authority_forbidden');
  }

  const packId = cleanUuid(raw.packId, 'cardverse_pack_id_invalid');
  const idempotencyKey = cleanText(raw.idempotencyKey, 128);
  const clientRevealVersion = Number(raw.clientRevealVersion);

  if (!IDEMPOTENCY_KEY.test(idempotencyKey)) {
    throw domainError('cardverse_idempotency_key_invalid');
  }
  if (!Number.isInteger(clientRevealVersion) || clientRevealVersion < 1 || clientRevealVersion > 100) {
    throw domainError('cardverse_reveal_version_invalid');
  }

  return { packId, idempotencyKey, clientRevealVersion };
}

export function normalizeServerRollPlan(raw = {}) {
  const policyVersion = Number(raw.policyVersion);
  const sourceItems = Array.isArray(raw.items) ? raw.items : [];

  if (!Number.isInteger(policyVersion) || policyVersion < 1) {
    throw domainError('cardverse_pack_policy_invalid');
  }
  if (sourceItems.length !== 5) {
    throw domainError('cardverse_pack_result_count_invalid');
  }

  const items = sourceItems.map((source) => {
    const canonicalInterestId = safePart(
      source?.canonicalInterestId,
      255,
      'cardverse_pack_interest_invalid',
    );
    const finishId = safePart(source?.finishId, 80, 'cardverse_pack_finish_invalid').toLowerCase();
    const editionId = safePart(source?.editionId, 120, 'cardverse_pack_edition_invalid').toLowerCase();
    const ownershipKind = cleanText(source?.ownershipKind, 32).toLowerCase();
    const quantity = Number(source?.quantity ?? 1);
    const artSystemVersion = Number(source?.artSystemVersion ?? 1);
    const soulbound = source?.soulbound === true;

    if (!FINISH_IDS.has(finishId)) throw domainError('cardverse_pack_finish_invalid');
    if (!OWNERSHIP_KINDS.has(ownershipKind)) {
      throw domainError('cardverse_pack_ownership_kind_invalid');
    }
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 20) {
      throw domainError('cardverse_pack_quantity_invalid');
    }
    if (ownershipKind === 'unique' && quantity !== 1) {
      throw domainError('cardverse_unique_pack_quantity_invalid');
    }
    if (!Number.isInteger(artSystemVersion) || artSystemVersion < 1 || artSystemVersion > 1000) {
      throw domainError('cardverse_art_version_invalid');
    }

    return {
      canonicalInterestId,
      finishId,
      editionId,
      ownershipKind,
      quantity,
      artSystemVersion,
      soulbound,
      variantKey: canonicalInterestId + '::' + finishId + '::' + editionId,
    };
  });

  return { policyVersion, items };
}

function requestHash(accountId, request) {
  return createHash('sha256')
    .update(JSON.stringify({
      accountId,
      packId: request.packId,
      clientRevealVersion: request.clientRevealVersion,
    }))
    .digest('hex');
}

async function replayIdempotent(tx, accountId, scope, request, hash) {
  const prior = await tx.query(
    'SELECT request_hash, response_json ' +
      'FROM cardverse_idempotency_records ' +
      'WHERE account_id = $1 AND scope = $2 AND idempotency_key = $3 ' +
      'FOR UPDATE',
    [accountId, scope, request.idempotencyKey],
  );
  if (prior.length === 0) throw domainError('cardverse_idempotency_lost');
  if (prior[0].request_hash !== hash) throw domainError('cardverse_idempotency_conflict');
  const response = asJsonObject(prior[0].response_json);
  if (!response) throw domainError('cardverse_idempotency_incomplete');
  return { ...response, idempotentReplay: true };
}

export async function openPack(db, accountIdValue, rawRequest, options = {}) {
  if (!db || typeof db.transaction !== 'function') {
    throw domainError('cardverse_transaction_required');
  }
  if (typeof options.rollPack !== 'function') {
    throw domainError('cardverse_server_roller_required');
  }

  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');
  const request = normalizePackOpenRequest(rawRequest);
  const hash = requestHash(accountId, request);
  const scope = 'pack_open';

  return db.transaction(async (tx) => {
    const accounts = await tx.query(
      "SELECT id FROM zync_accounts WHERE id = $1 AND status = 'active' FOR UPDATE",
      [accountId],
    );
    if (accounts.length === 0) throw domainError('cardverse_account_not_active');

    const reserved = await tx.query(
      'INSERT INTO cardverse_idempotency_records ' +
        '(account_id, scope, idempotency_key, request_hash) ' +
        'VALUES ($1, $2, $3, $4) ' +
        'ON CONFLICT (account_id, scope, idempotency_key) DO NOTHING ' +
        'RETURNING request_hash',
      [accountId, scope, request.idempotencyKey, hash],
    );

    if (reserved.length === 0) {
      return replayIdempotent(tx, accountId, scope, request, hash);
    }

    const packs = await tx.query(
      'SELECT pack_id, account_id, grant_id, pack_type, status, version, issued_at ' +
        'FROM cardverse_pack_entitlements ' +
        'WHERE pack_id = $1 AND account_id = $2 FOR UPDATE',
      [request.packId, accountId],
    );
    if (packs.length === 0) throw domainError('cardverse_pack_not_found');
    const pack = packs[0];
    if (pack.status !== 'unopened') throw domainError('cardverse_pack_already_opened');

    const plan = normalizeServerRollPlan(await options.rollPack({
      packId: pack.pack_id,
      packType: pack.pack_type,
    }));

    const rolls = await tx.query(
      'INSERT INTO cardverse_pack_rolls ' +
        '(pack_id, account_id, idempotency_key, client_reveal_version, policy_version) ' +
        'VALUES ($1, $2, $3, $4, $5) ' +
        'RETURNING server_roll_id, rolled_at',
      [
        pack.pack_id,
        accountId,
        request.idempotencyKey,
        request.clientRevealVersion,
        plan.policyVersion,
      ],
    );
    const roll = rolls[0];
    if (!roll?.server_roll_id) throw domainError('cardverse_pack_roll_create_failed');

    const receiptItems = [];
    for (let position = 0; position < plan.items.length; position += 1) {
      const item = plan.items[position];
      let instanceId = null;

      if (item.ownershipKind === 'stackable') {
        await tx.query(
          'INSERT INTO cardverse_stack_balances ' +
            '(account_id, variant_key, quantity, locked_quantity, version) ' +
            'VALUES ($1, $2, $3, 0, 1) ' +
            'ON CONFLICT (account_id, variant_key) DO UPDATE SET ' +
            'quantity = cardverse_stack_balances.quantity + EXCLUDED.quantity, ' +
            'version = cardverse_stack_balances.version + 1, updated_at = now()',
          [accountId, item.variantKey, item.quantity],
        );
      } else {
        const instances = await tx.query(
          'INSERT INTO cardverse_unique_instances ' +
            '(account_id, canonical_interest_id, finish_id, edition_id, art_system_version, ' +
            "acquisition_source, soulbound, locked, version) " +
            "VALUES ($1, $2, $3, $4, $5, 'pack', $6, false, 1) " +
            'RETURNING instance_id',
          [
            accountId,
            item.canonicalInterestId,
            item.finishId,
            item.editionId,
            item.artSystemVersion,
            item.soulbound,
          ],
        );
        instanceId = instances[0]?.instance_id ?? null;
        if (!instanceId) throw domainError('cardverse_unique_instance_create_failed');
      }

      await tx.query(
        'INSERT INTO cardverse_pack_roll_items ' +
          '(server_roll_id, position, canonical_interest_id, finish_id, edition_id, ' +
          'variant_key, ownership_kind, quantity, instance_id) ' +
          'VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
        [
          roll.server_roll_id,
          position,
          item.canonicalInterestId,
          item.finishId,
          item.editionId,
          item.variantKey,
          item.ownershipKind,
          item.quantity,
          instanceId,
        ],
      );

      await tx.query(
        'INSERT INTO cardverse_inventory_ledger ' +
          '(account_id, event_type, asset_kind, asset_key, quantity_delta, correlation_id, metadata) ' +
          "VALUES ($1, $2, $3, $4, $5, $6, '{}'::jsonb)",
        [
          accountId,
          item.ownershipKind === 'unique' ? 'unique_credit' : 'stack_credit',
          item.ownershipKind,
          instanceId ?? item.variantKey,
          item.quantity,
          roll.server_roll_id,
        ],
      );

      receiptItems.push({
        variant: {
          interestId: item.canonicalInterestId,
          finishId: item.finishId,
          editionId: item.editionId,
        },
        quantity: item.quantity,
        ...(instanceId ? { instanceId } : {}),
      });
    }

    const opened = await tx.query(
      "UPDATE cardverse_pack_entitlements SET status = 'opened', opened_at = $3, " +
        'version = version + 1 WHERE pack_id = $1 AND account_id = $2 AND status = ' +
        "'unopened' RETURNING version",
      [pack.pack_id, accountId, roll.rolled_at],
    );
    if (opened.length !== 1) throw domainError('cardverse_pack_open_race');

    await tx.query(
      'INSERT INTO cardverse_inventory_ledger ' +
        '(account_id, event_type, asset_kind, asset_key, quantity_delta, correlation_id, metadata) ' +
        "VALUES ($1, 'pack_open', 'pack', $2, -1, $3, $4::jsonb)",
      [
        accountId,
        pack.pack_id,
        roll.server_roll_id,
        JSON.stringify({ packType: pack.pack_type, policyVersion: plan.policyVersion }),
      ],
    );

    const response = {
      packId: pack.pack_id,
      serverRollId: roll.server_roll_id,
      idempotencyKey: request.idempotencyKey,
      rolledAt: asIso(roll.rolled_at),
      items: receiptItems,
      serverAuthoritative: true,
    };

    await tx.query(
      'UPDATE cardverse_idempotency_records SET response_json = $4::jsonb, completed_at = now() ' +
        'WHERE account_id = $1 AND scope = $2 AND idempotency_key = $3',
      [accountId, scope, request.idempotencyKey, JSON.stringify(response)],
    );

    return { ...response, idempotentReplay: false };
  });
}

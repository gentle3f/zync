import { createHash } from 'node:crypto';

const PROVIDERS = new Set(['google', 'apple']);
const PACK_TYPES = new Set(['standard', 'discovery']);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const IDEMPOTENCY_KEY = /^[A-Za-z0-9._:-]{16,128}$/;

function domainError(code) {
  const error = new Error(code);
  error.code = code;
  return error;
}

function requireDb(db) {
  if (!db || (typeof db.query !== 'function' && typeof db.transaction !== 'function')) {
    throw domainError('cardverse_database_invalid');
  }
}

function cleanText(value, max) {
  if (typeof value !== 'string') return '';
  const clean = value.trim();
  return clean.length <= max ? clean : '';
}

function cleanUuid(value, code = 'cardverse_uuid_invalid') {
  const clean = cleanText(value, 64).toLowerCase();
  if (!UUID.test(clean)) throw domainError(code);
  return clean;
}

function asIso(value) {
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string') return value;
  return null;
}

function asJsonObject(value) {
  if (!value) return null;
  if (typeof value === 'object') return value;
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      return parsed && typeof parsed === 'object' ? parsed : null;
    } catch (_) {
      return null;
    }
  }
  return null;
}

export function normalizeIdentityInput(input = {}) {
  const provider = cleanText(input.provider, 32).toLowerCase();
  const providerSubject = cleanText(input.providerSubject, 255);
  const providerEmail = cleanText(input.providerEmail, 320) || null;
  const emailVerified = input.emailVerified === true;

  if (!PROVIDERS.has(provider)) throw domainError('cardverse_identity_provider_invalid');
  if (!providerSubject) throw domainError('cardverse_identity_subject_invalid');

  return {
    provider,
    providerSubject,
    providerEmail,
    emailVerified,
  };
}

export async function ensureAccountForIdentity(db, rawInput) {
  requireDb(db);
  if (typeof db.transaction !== 'function') throw domainError('cardverse_transaction_required');
  const input = normalizeIdentityInput(rawInput);

  return db.transaction(async (tx) => {
    const lockKey = input.provider + ':' + input.providerSubject;
    await tx.query(
      'SELECT pg_advisory_xact_lock(hashtextextended($1, 0))',
      [lockKey],
    );

    const existing = await tx.query(
      `SELECT a.id, a.status, a.created_at
         FROM zync_identity_links l
         JOIN zync_accounts a ON a.id = l.account_id
        WHERE l.provider = $1 AND l.provider_subject = $2
        FOR UPDATE OF l`,
      [input.provider, input.providerSubject],
    );

    if (existing.length > 0) {
      return {
        created: false,
        account: {
          id: existing[0].id,
          status: existing[0].status,
          createdAt: asIso(existing[0].created_at),
        },
      };
    }

    const accounts = await tx.query(
      `INSERT INTO zync_accounts DEFAULT VALUES
       RETURNING id, status, created_at`,
    );
    const account = accounts[0];
    if (!account?.id) throw domainError('cardverse_account_create_failed');

    await tx.query(
      `INSERT INTO zync_identity_links (
         account_id, provider, provider_subject, provider_email,
         email_verified, last_verified_at
       ) VALUES ($1, $2, $3, $4, $5, now())`,
      [
        account.id,
        input.provider,
        input.providerSubject,
        input.providerEmail,
        input.emailVerified,
      ],
    );

    return {
      created: true,
      account: {
        id: account.id,
        status: account.status,
        createdAt: asIso(account.created_at),
      },
    };
  });
}

export async function linkIdentityToAccount(db, accountIdValue, rawInput) {
  requireDb(db);
  if (typeof db.transaction !== 'function') throw domainError('cardverse_transaction_required');
  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');
  const input = normalizeIdentityInput(rawInput);

  return db.transaction(async (tx) => {
    await tx.query(
      'SELECT pg_advisory_xact_lock(hashtextextended($1, 0))',
      [input.provider + ':' + input.providerSubject],
    );

    const accounts = await tx.query(
      `SELECT id, status FROM zync_accounts
        WHERE id = $1
        FOR UPDATE`,
      [accountId],
    );
    if (accounts.length === 0 || accounts[0].status !== 'active') {
      throw domainError('cardverse_account_not_active');
    }

    const providerOwner = await tx.query(
      `SELECT account_id
         FROM zync_identity_links
        WHERE provider = $1 AND provider_subject = $2
        FOR UPDATE`,
      [input.provider, input.providerSubject],
    );
    if (providerOwner.length > 0 && providerOwner[0].account_id !== accountId) {
      throw domainError('cardverse_identity_already_linked');
    }

    const accountProvider = await tx.query(
      `SELECT provider_subject
         FROM zync_identity_links
        WHERE account_id = $1 AND provider = $2
        FOR UPDATE`,
      [accountId, input.provider],
    );
    if (
      accountProvider.length > 0
      && accountProvider[0].provider_subject !== input.providerSubject
    ) {
      throw domainError('cardverse_provider_already_linked');
    }

    await tx.query(
      `INSERT INTO zync_identity_links (
         account_id, provider, provider_subject, provider_email,
         email_verified, last_verified_at
       ) VALUES ($1, $2, $3, $4, $5, now())
       ON CONFLICT (provider, provider_subject)
       DO UPDATE SET
         provider_email = EXCLUDED.provider_email,
         email_verified = EXCLUDED.email_verified,
         last_verified_at = now()`,
      [
        accountId,
        input.provider,
        input.providerSubject,
        input.providerEmail,
        input.emailVerified,
      ],
    );

    return { accountId, provider: input.provider, linked: true };
  });
}

export function normalizePackIssueInput(input = {}) {
  const accountId = cleanUuid(input.accountId, 'cardverse_account_id_invalid');
  const grantId = cleanUuid(input.grantId, 'cardverse_grant_id_invalid');
  const packType = cleanText(input.packType, 32).toLowerCase();
  const idempotencyKey = cleanText(input.idempotencyKey, 128);

  if (!PACK_TYPES.has(packType)) throw domainError('cardverse_pack_type_invalid');
  if (!IDEMPOTENCY_KEY.test(idempotencyKey)) {
    throw domainError('cardverse_idempotency_key_invalid');
  }

  return { accountId, grantId, packType, idempotencyKey };
}

function packIssueHash(input) {
  return createHash('sha256')
    .update(JSON.stringify({
      accountId: input.accountId,
      grantId: input.grantId,
      packType: input.packType,
    }))
    .digest('hex');
}

function packResponse(row, ledgerSequence = null, ledgerEventId = null) {
  return {
    packId: row.pack_id,
    accountId: row.account_id,
    grantId: row.grant_id,
    packType: row.pack_type,
    status: row.status,
    version: Number(row.version),
    issuedAt: asIso(row.issued_at),
    ledgerSequence: ledgerSequence == null ? null : Number(ledgerSequence),
    ledgerEventId,
  };
}

export async function issuePackEntitlement(db, rawInput) {
  requireDb(db);
  if (typeof db.transaction !== 'function') throw domainError('cardverse_transaction_required');
  const input = normalizePackIssueInput(rawInput);
  const requestHash = packIssueHash(input);
  const scope = 'pack_grant';

  return db.transaction(async (tx) => {
    const accounts = await tx.query(
      `SELECT id FROM zync_accounts
        WHERE id = $1 AND status = 'active'
        FOR UPDATE`,
      [input.accountId],
    );
    if (accounts.length === 0) throw domainError('cardverse_account_not_active');

    const reserved = await tx.query(
      `INSERT INTO cardverse_idempotency_records (
         account_id, scope, idempotency_key, request_hash
       ) VALUES ($1, $2, $3, $4)
       ON CONFLICT (account_id, scope, idempotency_key) DO NOTHING
       RETURNING request_hash`,
      [input.accountId, scope, input.idempotencyKey, requestHash],
    );

    if (reserved.length === 0) {
      const prior = await tx.query(
        `SELECT request_hash, response_json
           FROM cardverse_idempotency_records
          WHERE account_id = $1 AND scope = $2 AND idempotency_key = $3
          FOR UPDATE`,
        [input.accountId, scope, input.idempotencyKey],
      );
      if (prior.length === 0) throw domainError('cardverse_idempotency_lost');
      if (prior[0].request_hash !== requestHash) {
        throw domainError('cardverse_idempotency_conflict');
      }
      const response = asJsonObject(prior[0].response_json);
      if (!response) throw domainError('cardverse_idempotency_incomplete');
      return { ...response, idempotentReplay: true };
    }

    const existingGrant = await tx.query(
      `SELECT pack_id, account_id, grant_id, pack_type, status, version, issued_at
         FROM cardverse_pack_entitlements
        WHERE grant_id = $1
        FOR UPDATE`,
      [input.grantId],
    );

    let response;
    if (existingGrant.length > 0) {
      const row = existingGrant[0];
      if (row.account_id !== input.accountId || row.pack_type !== input.packType) {
        throw domainError('cardverse_grant_conflict');
      }
      response = packResponse(row);
    } else {
      const packs = await tx.query(
        `INSERT INTO cardverse_pack_entitlements (
           account_id, grant_id, pack_type
         ) VALUES ($1, $2, $3)
         RETURNING pack_id, account_id, grant_id, pack_type, status, version, issued_at`,
        [input.accountId, input.grantId, input.packType],
      );
      const pack = packs[0];
      if (!pack?.pack_id) throw domainError('cardverse_pack_issue_failed');

      const ledger = await tx.query(
        `INSERT INTO cardverse_inventory_ledger (
           account_id, event_type, asset_kind, asset_key,
           quantity_delta, correlation_id, metadata
         ) VALUES ($1, 'pack_grant', 'pack', $2, 1, $3, $4::jsonb)
         RETURNING sequence, event_id`,
        [
          input.accountId,
          pack.pack_id,
          input.grantId,
          JSON.stringify({ packType: input.packType }),
        ],
      );
      response = packResponse(
        pack,
        ledger[0]?.sequence ?? null,
        ledger[0]?.event_id ?? null,
      );
    }

    await tx.query(
      `UPDATE cardverse_idempotency_records
          SET response_json = $4::jsonb, completed_at = now()
        WHERE account_id = $1 AND scope = $2 AND idempotency_key = $3`,
      [
        input.accountId,
        scope,
        input.idempotencyKey,
        JSON.stringify(response),
      ],
    );

    return { ...response, idempotentReplay: false };
  });
}

export async function listOwnershipSnapshot(db, accountIdValue) {
  requireDb(db);
  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');

  const accounts = await db.query(
    `SELECT id, status, created_at
       FROM zync_accounts
      WHERE id = $1`,
    [accountId],
  );
  if (accounts.length === 0) throw domainError('cardverse_account_not_found');

  const balances = await db.query(
    `SELECT variant_key, quantity, locked_quantity, version, updated_at
       FROM cardverse_stack_balances
      WHERE account_id = $1
      ORDER BY variant_key`,
    [accountId],
  );

  const uniqueInstances = await db.query(
    `SELECT instance_id, canonical_interest_id, finish, edition,
            art_system_version, soulbound, locked, version, acquired_at, metadata
       FROM cardverse_unique_instances
      WHERE account_id = $1
      ORDER BY acquired_at, instance_id`,
    [accountId],
  );

  const unopenedPacks = await db.query(
    `SELECT pack_id, grant_id, pack_type, status, version, issued_at
       FROM cardverse_pack_entitlements
      WHERE account_id = $1 AND status = 'unopened'
      ORDER BY issued_at, pack_id`,
    [accountId],
  );

  const cursorRows = await db.query(
    `SELECT COALESCE(MAX(sequence), 0) AS ledger_cursor
       FROM cardverse_inventory_ledger
      WHERE account_id = $1`,
    [accountId],
  );

  return {
    account: {
      id: accounts[0].id,
      status: accounts[0].status,
      createdAt: asIso(accounts[0].created_at),
    },
    ledgerCursor: Number(cursorRows[0]?.ledger_cursor ?? 0),
    balances: balances.map((row) => ({
      variantKey: row.variant_key,
      quantity: Number(row.quantity),
      lockedQuantity: Number(row.locked_quantity),
      version: Number(row.version),
      updatedAt: asIso(row.updated_at),
    })),
    uniqueInstances: uniqueInstances.map((row) => ({
      instanceId: row.instance_id,
      canonicalInterestId: row.canonical_interest_id,
      finish: row.finish,
      edition: row.edition,
      artSystemVersion: Number(row.art_system_version),
      soulbound: row.soulbound === true,
      locked: row.locked === true,
      version: Number(row.version),
      acquiredAt: asIso(row.acquired_at),
      metadata: asJsonObject(row.metadata) ?? {},
    })),
    unopenedPacks: unopenedPacks.map((row) => ({
      packId: row.pack_id,
      grantId: row.grant_id,
      packType: row.pack_type,
      status: row.status,
      version: Number(row.version),
      issuedAt: asIso(row.issued_at),
    })),
  };
}

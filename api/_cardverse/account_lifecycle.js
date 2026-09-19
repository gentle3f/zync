import { normalizeIdentityInput } from './ownership_store.js';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function domainError(code) {
  const error = new Error(code);
  error.code = code;
  return error;
}

function cleanUuid(value) {
  const clean = typeof value === 'string' ? value.trim().toLowerCase() : '';
  if (!UUID.test(clean)) throw domainError('cardverse_account_id_invalid');
  return clean;
}

function requireTransactionalDb(db) {
  if (!db || typeof db.transaction !== 'function') {
    throw domainError('cardverse_transaction_required');
  }
}

export async function unlinkIdentityFromAccount(db, accountIdValue, rawIdentity) {
  requireTransactionalDb(db);
  const accountId = cleanUuid(accountIdValue);
  const identity = normalizeIdentityInput(rawIdentity);

  return db.transaction(async (tx) => {
    const accounts = await tx.query(
      `SELECT id, status
         FROM zync_accounts
        WHERE id = $1
        FOR UPDATE`,
      [accountId],
    );
    if (accounts.length === 0 || accounts[0].status !== 'active') {
      throw domainError('cardverse_account_not_active');
    }

    const links = await tx.query(
      `SELECT id, provider, provider_subject
         FROM zync_identity_links
        WHERE account_id = $1 AND unlinked_at IS NULL
        ORDER BY created_at, id
        FOR UPDATE`,
      [accountId],
    );
    const target = links.find(
      (row) => row.provider === identity.provider
        && row.provider_subject === identity.providerSubject,
    );
    if (!target) throw domainError('cardverse_identity_not_linked');
    if (links.length <= 1) {
      throw domainError('cardverse_last_identity_unlink_forbidden');
    }

    await tx.query(
      `UPDATE zync_identity_links
          SET unlinked_at = now(),
              provider_email = NULL,
              email_verified = false
        WHERE id = $1 AND account_id = $2 AND unlinked_at IS NULL`,
      [target.id, accountId],
    );

    await tx.query(
      `UPDATE zync_account_sessions
          SET revoked_at = COALESCE(revoked_at, now())
        WHERE account_id = $1 AND revoked_at IS NULL`,
      [accountId],
    );

    return {
      accountId,
      provider: identity.provider,
      unlinked: true,
      allSessionsRevoked: true,
    };
  });
}

export async function deleteAccount(db, accountIdValue, rawIdentity) {
  requireTransactionalDb(db);
  const accountId = cleanUuid(accountIdValue);
  const identity = normalizeIdentityInput(rawIdentity);

  return db.transaction(async (tx) => {
    const accounts = await tx.query(
      `SELECT id, status, deleted_at
         FROM zync_accounts
        WHERE id = $1
        FOR UPDATE`,
      [accountId],
    );
    if (accounts.length === 0) throw domainError('cardverse_account_not_found');
    if (accounts[0].status === 'deleted') {
      return {
        accountId,
        deleted: true,
        alreadyDeleted: true,
        deletedAt: accounts[0].deleted_at instanceof Date
          ? accounts[0].deleted_at.toISOString()
          : accounts[0].deleted_at ?? null,
      };
    }
    if (accounts[0].status !== 'active') {
      throw domainError('cardverse_account_not_active');
    }

    const verifiedLink = await tx.query(
      `SELECT id
         FROM zync_identity_links
        WHERE account_id = $1
          AND provider = $2
          AND provider_subject = $3
          AND unlinked_at IS NULL
        FOR UPDATE`,
      [accountId, identity.provider, identity.providerSubject],
    );
    if (verifiedLink.length !== 1) throw domainError('cardverse_identity_not_linked');

    const updated = await tx.query(
      `UPDATE zync_accounts
          SET status = 'deleted',
              deleted_at = COALESCE(deleted_at, now()),
              updated_at = now()
        WHERE id = $1
        RETURNING deleted_at`,
      [accountId],
    );

    await tx.query(
      `UPDATE zync_identity_links
          SET provider_email = NULL,
              email_verified = false
        WHERE account_id = $1`,
      [accountId],
    );

    await tx.query(
      `UPDATE zync_account_sessions
          SET revoked_at = COALESCE(revoked_at, now())
        WHERE account_id = $1 AND revoked_at IS NULL`,
      [accountId],
    );

    const deletedAt = updated[0]?.deleted_at;
    return {
      accountId,
      deleted: true,
      alreadyDeleted: false,
      deletedAt: deletedAt instanceof Date ? deletedAt.toISOString() : deletedAt ?? null,
    };
  });
}

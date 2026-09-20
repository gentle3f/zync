import { createHash, randomBytes } from 'node:crypto';

const PROVIDERS = new Set(['google', 'apple']);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const SESSION_TOKEN = /^[A-Za-z0-9_-]{32,128}$/;
const DEFAULT_CHALLENGE_MINUTES = 10;
const DEFAULT_SESSION_DAYS = 30;
const DEFAULT_MAX_ACTIVE_SESSIONS = 8;

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

function providerValue(value) {
  const provider = cleanText(value, 32).toLowerCase();
  if (!PROVIDERS.has(provider)) throw domainError('cardverse_identity_provider_invalid');
  return provider;
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

function positiveInteger(value, fallback, max) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > max) return fallback;
  return parsed;
}

function iso(value) {
  if (value instanceof Date) return value.toISOString();
  return typeof value === 'string' ? value : null;
}

export async function createAuthChallenge(db, providerInput, options = {}) {
  if (!db || typeof db.query !== 'function') throw domainError('cardverse_database_invalid');
  const provider = providerValue(providerInput);
  const ttlMinutes = positiveInteger(
    options.ttlMinutes ?? process.env.CARDVERSE_AUTH_CHALLENGE_MINUTES,
    DEFAULT_CHALLENGE_MINUTES,
    30,
  );
  const nonce = randomBytes(32).toString('base64url');
  const nonceHash = sha256(nonce);

  const rows = await db.query(
    'INSERT INTO cardverse_auth_challenges (provider, nonce_hash, expires_at) ' +
      "VALUES ($1, $2, now() + ($3::text || ' minutes')::interval) " +
      'RETURNING challenge_id, expires_at',
    [provider, nonceHash, ttlMinutes],
  );
  const row = rows[0];
  if (!row?.challenge_id) throw domainError('cardverse_auth_challenge_create_failed');

  return {
    challengeId: row.challenge_id,
    provider,
    nonce,
    expiresAt: iso(row.expires_at),
  };
}

export async function consumeAuthChallenge(db, input = {}) {
  if (!db || typeof db.query !== 'function') throw domainError('cardverse_database_invalid');
  const challengeId = cleanUuid(input.challengeId, 'cardverse_auth_challenge_id_invalid');
  const provider = providerValue(input.provider);
  const nonce = cleanText(input.nonce, 512);
  if (!nonce) throw domainError('cardverse_provider_nonce_missing');

  const rows = await db.query(
    'UPDATE cardverse_auth_challenges SET consumed_at = now() ' +
      'WHERE challenge_id = $1 AND provider = $2 AND nonce_hash = $3 ' +
      'AND consumed_at IS NULL AND expires_at > now() ' +
      'RETURNING challenge_id',
    [challengeId, provider, sha256(nonce)],
  );
  if (rows.length !== 1) throw domainError('cardverse_auth_challenge_invalid');
  return { challengeId, consumed: true };
}

export async function createAccountSession(db, accountIdValue, options = {}) {
  if (!db || typeof db.transaction !== 'function') {
    throw domainError('cardverse_transaction_required');
  }
  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');
  const ttlDays = positiveInteger(
    options.ttlDays ?? process.env.CARDVERSE_SESSION_TTL_DAYS,
    DEFAULT_SESSION_DAYS,
    90,
  );
  const maxActiveSessions = positiveInteger(
    options.maxActiveSessions ?? process.env.CARDVERSE_MAX_ACTIVE_SESSIONS,
    DEFAULT_MAX_ACTIVE_SESSIONS,
    32,
  );
  const token = randomBytes(32).toString('base64url');
  const tokenHash = sha256(token);

  return db.transaction(async (tx) => {
    // Serialize session creation against other logins and account deletion.
    // This makes CARDVERSE_MAX_ACTIVE_SESSIONS a hard per-account bound rather
    // than a best-effort cleanup under concurrent provider exchanges.
    const accounts = await tx.query(
      "SELECT id FROM zync_accounts WHERE id = $1 AND status = 'active' FOR UPDATE",
      [accountId],
    );
    if (accounts.length !== 1) throw domainError('cardverse_account_not_active');

    const rows = await tx.query(
      'INSERT INTO zync_account_sessions (account_id, token_hash, expires_at) ' +
        "VALUES ($1, $2, now() + ($3::text || ' days')::interval) " +
        'RETURNING session_id, expires_at',
      [accountId, tokenHash, ttlDays],
    );
    const row = rows[0];
    if (!row?.session_id) throw domainError('cardverse_session_create_failed');

    await tx.query(
      `UPDATE zync_account_sessions
          SET revoked_at = COALESCE(revoked_at, now())
        WHERE account_id = $1
          AND revoked_at IS NULL
          AND session_id NOT IN (
            SELECT session_id
              FROM zync_account_sessions
             WHERE account_id = $1
               AND revoked_at IS NULL
               AND expires_at > now()
             ORDER BY created_at DESC, session_id DESC
             LIMIT $2
          )`,
      [accountId, maxActiveSessions],
    );

    return {
      sessionId: row.session_id,
      accountId,
      token,
      expiresAt: iso(row.expires_at),
    };
  });
}

export function bearerTokenFromAuthorization(value) {
  const raw = cleanText(value, 256);
  const match = /^Bearer\s+([A-Za-z0-9_-]{32,128})$/i.exec(raw);
  if (!match || !SESSION_TOKEN.test(match[1])) {
    throw domainError('cardverse_session_missing');
  }
  return match[1];
}

export async function resolveAccountSession(db, tokenValue) {
  if (!db || typeof db.query !== 'function') throw domainError('cardverse_database_invalid');
  const token = cleanText(tokenValue, 128);
  if (!SESSION_TOKEN.test(token)) throw domainError('cardverse_session_invalid');

  const rows = await db.query(
    'SELECT s.session_id, s.account_id, s.expires_at, a.status ' +
      'FROM zync_account_sessions s ' +
      'JOIN zync_accounts a ON a.id = s.account_id ' +
      'WHERE s.token_hash = $1 AND s.revoked_at IS NULL ' +
      "AND s.expires_at > now() AND a.status = 'active' LIMIT 1",
    [sha256(token)],
  );
  const row = rows[0];
  if (!row?.session_id) throw domainError('cardverse_session_invalid');

  await db.query(
    'UPDATE zync_account_sessions SET last_seen_at = now() ' +
      "WHERE session_id = $1 AND last_seen_at < now() - interval '15 minutes'",
    [row.session_id],
  );

  return {
    sessionId: row.session_id,
    accountId: row.account_id,
    expiresAt: iso(row.expires_at),
  };
}

export async function revokeAccountSession(db, tokenValue) {
  if (!db || typeof db.query !== 'function') throw domainError('cardverse_database_invalid');
  const token = cleanText(tokenValue, 128);
  if (!SESSION_TOKEN.test(token)) throw domainError('cardverse_session_invalid');

  await db.query(
    'UPDATE zync_account_sessions SET revoked_at = COALESCE(revoked_at, now()) ' +
      'WHERE token_hash = $1',
    [sha256(token)],
  );
  return { revoked: true };
}

export async function revokeAllAccountSessions(db, accountIdValue) {
  if (!db || typeof db.query !== 'function') throw domainError('cardverse_database_invalid');
  const accountId = cleanUuid(accountIdValue, 'cardverse_account_id_invalid');
  const rows = await db.query(
    `UPDATE zync_account_sessions
        SET revoked_at = COALESCE(revoked_at, now())
      WHERE account_id = $1 AND revoked_at IS NULL
      RETURNING session_id`,
    [accountId],
  );
  return { revoked: rows.length };
}

BEGIN;

CREATE TABLE IF NOT EXISTS cardverse_auth_challenges (
  challenge_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider text NOT NULL CHECK (provider IN ('google', 'apple')),
  nonce_hash text NOT NULL UNIQUE CHECK (char_length(nonce_hash) = 64),
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz NULL,
  CHECK (expires_at > created_at),
  CHECK (consumed_at IS NULL OR consumed_at >= created_at)
);

CREATE INDEX IF NOT EXISTS cardverse_auth_challenges_expiry_idx
  ON cardverse_auth_challenges(expires_at)
  WHERE consumed_at IS NULL;

CREATE TABLE IF NOT EXISTS zync_account_sessions (
  session_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  token_hash text NOT NULL UNIQUE CHECK (char_length(token_hash) = 64),
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz NULL,
  CHECK (expires_at > created_at),
  CHECK (last_seen_at >= created_at),
  CHECK (revoked_at IS NULL OR revoked_at >= created_at)
);

CREATE INDEX IF NOT EXISTS zync_account_sessions_active_owner_idx
  ON zync_account_sessions(account_id, expires_at DESC)
  WHERE revoked_at IS NULL;

COMMENT ON TABLE cardverse_auth_challenges IS
  'Single-use provider nonce challenges. Store only nonce hashes; never provider tokens.';

COMMENT ON TABLE zync_account_sessions IS
  'Opaque Cardverse bearer sessions. Only SHA-256 token hashes are persisted.';

COMMIT;

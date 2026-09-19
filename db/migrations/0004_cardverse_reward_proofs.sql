BEGIN;

CREATE TABLE IF NOT EXISTS cardverse_draw_token_balances (
  account_id uuid PRIMARY KEY REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  quantity integer NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  locked_quantity integer NOT NULL DEFAULT 0 CHECK (locked_quantity >= 0),
  version bigint NOT NULL DEFAULT 1 CHECK (version >= 1),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (locked_quantity <= quantity)
);

CREATE TABLE IF NOT EXISTS cardverse_reward_proofs (
  proof_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  client_event_id text NOT NULL CHECK (char_length(client_event_id) BETWEEN 1 AND 160),
  event_type text NOT NULL
    CHECK (event_type IN ('one_to_one_zync', 'tried_together_completed')),
  source text NOT NULL
    CHECK (source IN ('one_to_one', 'zync_now')),
  occurred_at timestamptz NOT NULL,
  participant_count smallint NOT NULL CHECK (participant_count BETWEEN 2 AND 8),
  repeat_person boolean NOT NULL DEFAULT false,
  mode text NOT NULL DEFAULT '' CHECK (char_length(mode) <= 32),
  interest_categories text[] NOT NULL DEFAULT '{}'::text[]
    CHECK (cardinality(interest_categories) <= 8),
  timezone_offset_minutes smallint NOT NULL
    CHECK (timezone_offset_minutes BETWEEN -840 AND 840),
  daily_cycle_start timestamptz NOT NULL,
  weekly_cycle_start timestamptz NOT NULL,
  verified_at timestamptz NOT NULL DEFAULT now(),
  verifier text NOT NULL CHECK (char_length(verifier) BETWEEN 1 AND 80),
  UNIQUE (account_id, client_event_id),
  CHECK (daily_cycle_start <= occurred_at),
  CHECK (occurred_at < daily_cycle_start + interval '1 day'),
  CHECK (weekly_cycle_start <= occurred_at),
  CHECK (occurred_at < weekly_cycle_start + interval '7 days')
);

CREATE INDEX IF NOT EXISTS cardverse_reward_proofs_owner_time_idx
  ON cardverse_reward_proofs(account_id, occurred_at DESC);

CREATE TABLE IF NOT EXISTS cardverse_reward_grants (
  grant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  server_sequence bigint GENERATED ALWAYS AS IDENTITY UNIQUE,
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  eligibility_key text NOT NULL CHECK (char_length(eligibility_key) BETWEEN 1 AND 240),
  quest_id text NOT NULL CHECK (char_length(quest_id) BETWEEN 1 AND 120),
  cycle_start timestamptz NOT NULL,
  reward_kind text NOT NULL
    CHECK (reward_kind IN ('draw_token', 'standard_pack', 'discovery_pack')),
  amount integer NOT NULL CHECK (amount >= 1 AND amount <= 20),
  issued_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (account_id, eligibility_key),
  UNIQUE (account_id, quest_id, cycle_start)
);

CREATE TABLE IF NOT EXISTS cardverse_reward_grant_proofs (
  grant_id uuid NOT NULL REFERENCES cardverse_reward_grants(grant_id) ON DELETE RESTRICT,
  proof_id uuid NOT NULL REFERENCES cardverse_reward_proofs(proof_id) ON DELETE RESTRICT,
  PRIMARY KEY (grant_id, proof_id)
);

COMMENT ON TABLE cardverse_reward_proofs IS
  'Coarse server-verified Quest proof only. Never store peer identity, social handles, QR payloads or conversation content.';

COMMENT ON TABLE cardverse_reward_grants IS
  'Authoritative reward decision. Client eligibility is never sufficient to create this row.';

COMMIT;

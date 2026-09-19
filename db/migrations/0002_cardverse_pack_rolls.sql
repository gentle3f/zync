BEGIN;

CREATE TABLE IF NOT EXISTS cardverse_pack_rolls (
  server_roll_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pack_id uuid NOT NULL UNIQUE
    REFERENCES cardverse_pack_entitlements(pack_id) ON DELETE RESTRICT,
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  idempotency_key text NOT NULL
    CHECK (char_length(idempotency_key) BETWEEN 16 AND 128),
  client_reveal_version integer NOT NULL CHECK (client_reveal_version >= 1),
  policy_version integer NOT NULL CHECK (policy_version >= 1),
  rolled_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (account_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS cardverse_pack_rolls_owner_time_idx
  ON cardverse_pack_rolls(account_id, rolled_at DESC);

CREATE TABLE IF NOT EXISTS cardverse_pack_roll_items (
  server_roll_id uuid NOT NULL
    REFERENCES cardverse_pack_rolls(server_roll_id) ON DELETE RESTRICT,
  position smallint NOT NULL CHECK (position BETWEEN 0 AND 31),
  canonical_interest_id text NOT NULL
    CHECK (char_length(canonical_interest_id) BETWEEN 1 AND 255),
  finish_id text NOT NULL CHECK (char_length(finish_id) BETWEEN 1 AND 80),
  edition_id text NOT NULL CHECK (char_length(edition_id) BETWEEN 1 AND 120),
  variant_key text NOT NULL CHECK (char_length(variant_key) BETWEEN 5 AND 520),
  ownership_kind text NOT NULL CHECK (ownership_kind IN ('stackable', 'unique')),
  quantity integer NOT NULL CHECK (quantity >= 1),
  instance_id uuid NULL
    REFERENCES cardverse_unique_instances(instance_id) ON DELETE RESTRICT,
  PRIMARY KEY (server_roll_id, position),
  CHECK (
    (ownership_kind = 'stackable' AND instance_id IS NULL)
    OR
    (ownership_kind = 'unique' AND quantity = 1 AND instance_id IS NOT NULL)
  ),
  CHECK (position('::' in canonical_interest_id) = 0),
  CHECK (position('::' in finish_id) = 0),
  CHECK (position('::' in edition_id) = 0)
);

COMMENT ON TABLE cardverse_pack_rolls IS
  'One immutable server roll per pack. A pack can never be rerolled.';

COMMENT ON TABLE cardverse_pack_roll_items IS
  'Persisted pack result order used by receipt-driven reveal/resume.';

COMMIT;

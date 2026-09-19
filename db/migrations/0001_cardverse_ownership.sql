BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS zync_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'suspended', 'deleted')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS zync_identity_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  provider text NOT NULL CHECK (provider IN ('google', 'apple')),
  provider_subject text NOT NULL CHECK (char_length(provider_subject) BETWEEN 1 AND 255),
  provider_email text NULL,
  email_verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_verified_at timestamptz NULL,
  UNIQUE (provider, provider_subject),
  UNIQUE (account_id, provider)
);

CREATE INDEX IF NOT EXISTS zync_identity_links_account_idx
  ON zync_identity_links(account_id);

CREATE TABLE IF NOT EXISTS cardverse_pack_entitlements (
  pack_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  grant_id uuid NULL,
  pack_type text NOT NULL
    CHECK (pack_type IN ('standard', 'discovery')),
  status text NOT NULL DEFAULT 'unopened'
    CHECK (status IN ('unopened', 'opened')),
  version bigint NOT NULL DEFAULT 1 CHECK (version >= 1),
  issued_at timestamptz NOT NULL DEFAULT now(),
  opened_at timestamptz NULL,
  CHECK (
    (status = 'unopened' AND opened_at IS NULL)
    OR
    (status = 'opened' AND opened_at IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS cardverse_pack_entitlements_grant_uidx
  ON cardverse_pack_entitlements(grant_id)
  WHERE grant_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS cardverse_pack_entitlements_owner_status_idx
  ON cardverse_pack_entitlements(account_id, status, issued_at DESC);

CREATE TABLE IF NOT EXISTS cardverse_stack_balances (
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  variant_key text NOT NULL CHECK (char_length(variant_key) BETWEEN 1 AND 255),
  quantity integer NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  locked_quantity integer NOT NULL DEFAULT 0 CHECK (locked_quantity >= 0),
  version bigint NOT NULL DEFAULT 1 CHECK (version >= 1),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (account_id, variant_key),
  CHECK (locked_quantity <= quantity)
);

CREATE TABLE IF NOT EXISTS cardverse_unique_instances (
  instance_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  canonical_interest_id text NOT NULL
    CHECK (char_length(canonical_interest_id) BETWEEN 1 AND 255),
  finish text NOT NULL
    CHECK (finish IN ('normal', 'foil', 'holo', 'prism', 'legendary', 'secret')),
  edition text NOT NULL
    CHECK (edition IN ('core', 'encounter', 'discovery', 'event', 'starter', 'achievement')),
  art_system_version integer NOT NULL DEFAULT 1 CHECK (art_system_version >= 1),
  soulbound boolean NOT NULL DEFAULT false,
  locked boolean NOT NULL DEFAULT false,
  version bigint NOT NULL DEFAULT 1 CHECK (version >= 1),
  acquired_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS cardverse_unique_instances_owner_idx
  ON cardverse_unique_instances(account_id, acquired_at DESC);

CREATE TABLE IF NOT EXISTS cardverse_idempotency_records (
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  scope text NOT NULL CHECK (char_length(scope) BETWEEN 1 AND 80),
  idempotency_key text NOT NULL CHECK (char_length(idempotency_key) BETWEEN 16 AND 128),
  request_hash text NOT NULL CHECK (char_length(request_hash) = 64),
  response_json jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz NULL,
  PRIMARY KEY (account_id, scope, idempotency_key),
  CHECK (
    (response_json IS NULL AND completed_at IS NULL)
    OR
    (response_json IS NOT NULL AND completed_at IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS cardverse_inventory_ledger (
  sequence bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  account_id uuid NOT NULL REFERENCES zync_accounts(id) ON DELETE RESTRICT,
  event_type text NOT NULL
    CHECK (event_type IN (
      'pack_grant',
      'pack_open',
      'quest_reward',
      'stack_credit',
      'stack_debit',
      'unique_credit',
      'unique_debit',
      'trade_reserve',
      'trade_release',
      'trade_out',
      'trade_in',
      'migration',
      'admin_correction'
    )),
  asset_kind text NOT NULL
    CHECK (asset_kind IN ('pack', 'stackable', 'unique', 'draw_token')),
  asset_key text NOT NULL CHECK (char_length(asset_key) BETWEEN 1 AND 255),
  quantity_delta integer NOT NULL,
  correlation_id uuid NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS cardverse_inventory_ledger_owner_sequence_idx
  ON cardverse_inventory_ledger(account_id, sequence);

CREATE OR REPLACE FUNCTION cardverse_reject_ledger_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'cardverse_inventory_ledger is append-only';
END;
$$;

DROP TRIGGER IF EXISTS cardverse_inventory_ledger_immutable
  ON cardverse_inventory_ledger;

CREATE TRIGGER cardverse_inventory_ledger_immutable
BEFORE UPDATE OR DELETE OR TRUNCATE
ON cardverse_inventory_ledger
FOR EACH STATEMENT
EXECUTE FUNCTION cardverse_reject_ledger_mutation();

COMMENT ON TABLE zync_accounts IS
  'Internal Zync account identity. Provider email is never the inventory primary key.';

COMMENT ON TABLE zync_identity_links IS
  'Authenticated Google/Apple identity links to one internal Zync account UUID.';

COMMENT ON TABLE cardverse_inventory_ledger IS
  'Append-only evidence for every Cardverse economy mutation. Never store peer identity here.';

COMMIT;

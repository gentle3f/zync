BEGIN;

ALTER TABLE zync_accounts
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz NULL;

ALTER TABLE zync_identity_links
  ADD COLUMN IF NOT EXISTS unlinked_at timestamptz NULL;

CREATE INDEX IF NOT EXISTS zync_identity_links_active_account_idx
  ON zync_identity_links(account_id, provider)
  WHERE unlinked_at IS NULL;

COMMENT ON COLUMN zync_accounts.deleted_at IS
  'Logical account deletion timestamp. Ownership ledger rows remain immutable for audit integrity.';

COMMENT ON COLUMN zync_identity_links.unlinked_at IS
  'Soft unlink tombstone. Provider subjects are not silently recycled into a different Cardverse owner.';

COMMIT;

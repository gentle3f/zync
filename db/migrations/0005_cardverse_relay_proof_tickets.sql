BEGIN;

ALTER TABLE cardverse_reward_proofs
  ALTER COLUMN repeat_person DROP NOT NULL;

ALTER TABLE cardverse_reward_proofs
  ALTER COLUMN repeat_person DROP DEFAULT;

ALTER TABLE cardverse_reward_proofs
  ADD COLUMN IF NOT EXISTS issuer_ticket_id text NULL;

CREATE UNIQUE INDEX IF NOT EXISTS cardverse_reward_proofs_issuer_ticket_uidx
  ON cardverse_reward_proofs(issuer_ticket_id)
  WHERE issuer_ticket_id IS NOT NULL;

COMMENT ON COLUMN cardverse_reward_proofs.repeat_person IS
  'NULL means the trusted verifier did not establish whether this was a repeat person. NULL must never count as new-person proof.';

COMMENT ON COLUMN cardverse_reward_proofs.issuer_ticket_id IS
  'Opaque server-issued proof ticket identifier. Unique across all accounts to prevent cross-account replay.';

COMMIT;

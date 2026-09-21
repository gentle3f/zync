BEGIN;

ALTER TABLE cardverse_inventory_ledger
  DROP CONSTRAINT IF EXISTS cardverse_inventory_ledger_event_type_check;

ALTER TABLE cardverse_inventory_ledger
  ADD CONSTRAINT cardverse_inventory_ledger_event_type_check
  CHECK (event_type IN (
    'pack_grant',
    'pack_open',
    'quest_reward',
    'draw_token_spend',
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
  ));

COMMENT ON COLUMN cardverse_inventory_ledger.event_type IS
  'Append-only economy event. draw_token_spend records one Draw Token consumed for one server-authoritative single-card draw.';

COMMIT;

#!/usr/bin/env bash
set -euo pipefail

sudo systemctl start postgresql.service

psql_zync() {
  sudo -u postgres psql -X -v ON_ERROR_STOP=1 -d postgres "$@"
}

expect_sql_failure() {
  local label="$1"
  local sql="$2"
  if psql_zync -c "$sql"; then
    echo "Expected PostgreSQL constraint failure: $label" >&2
    exit 1
  fi
  echo "✓ expected failure: $label"
}

for migration in db/migrations/*.sql; do
  echo "Applying $migration"
  psql_zync -f "$migration"
done

for table in \
  zync_accounts \
  zync_identity_links \
  cardverse_pack_entitlements \
  cardverse_stack_balances \
  cardverse_unique_instances \
  cardverse_idempotency_records \
  cardverse_inventory_ledger \
  cardverse_pack_rolls \
  cardverse_pack_roll_items \
  cardverse_auth_challenges \
  zync_account_sessions \
  cardverse_draw_token_balances \
  cardverse_reward_proofs \
  cardverse_reward_grants \
  cardverse_reward_grant_proofs
do
  value="$(psql_zync -Atc "SELECT to_regclass('public.${table}') IS NOT NULL")"
  test "$value" = "t"
done

ACCOUNT="11111111-1111-4111-8111-111111111111"
GRANT="22222222-2222-4222-8222-222222222222"
PACK="33333333-3333-4333-8333-333333333333"
ROLL="44444444-4444-4444-8444-444444444444"
LEDGER="55555555-5555-4555-8555-555555555555"

psql_zync <<SQL
INSERT INTO zync_accounts (id) VALUES ('$ACCOUNT');

INSERT INTO cardverse_pack_entitlements (
  pack_id, account_id, grant_id, pack_type
) VALUES (
  '$PACK', '$ACCOUNT', '$GRANT', 'standard'
);

INSERT INTO cardverse_pack_rolls (
  server_roll_id, pack_id, account_id, idempotency_key,
  client_reveal_version, policy_version
) VALUES (
  '$ROLL', '$PACK', '$ACCOUNT', 'pack-open-attempt-0001', 1, 1
);

INSERT INTO cardverse_pack_roll_items (
  server_roll_id, position, canonical_interest_id, finish_id,
  edition_id, variant_key, ownership_kind, quantity
) VALUES (
  '$ROLL', 0, 'sports.badminton', 'normal',
  'core_set_1', 'sports.badminton::normal::core_set_1',
  'stackable', 1
);

INSERT INTO cardverse_unique_instances (
  account_id, canonical_interest_id, finish_id, edition_id,
  art_system_version, acquisition_source, soulbound
) VALUES (
  '$ACCOUNT', 'music.piano', 'secret', 'event_2026',
  2, 'event', true
);

INSERT INTO cardverse_inventory_ledger (
  event_id, account_id, event_type, asset_kind,
  asset_key, quantity_delta, correlation_id
) VALUES (
  '$LEDGER', '$ACCOUNT', 'pack_open', 'pack',
  '$PACK', -1, '$ROLL'
);
SQL

edition="$(psql_zync -Atc "SELECT edition_id FROM cardverse_unique_instances WHERE account_id = '$ACCOUNT' LIMIT 1")"
test "$edition" = "event_2026"

variant="$(psql_zync -Atc "SELECT variant_key FROM cardverse_pack_roll_items WHERE server_roll_id = '$ROLL' AND position = 0")"
test "$variant" = "sports.badminton::normal::core_set_1"

expect_sql_failure \
  "append-only ledger rejects UPDATE" \
  "UPDATE cardverse_inventory_ledger SET quantity_delta = 99 WHERE event_id = '$LEDGER'"

expect_sql_failure \
  "locked quantity cannot exceed quantity" \
  "INSERT INTO cardverse_stack_balances (account_id, variant_key, quantity, locked_quantity) VALUES ('$ACCOUNT', 'sports.badminton::normal::core_set_1', 1, 2)"

expect_sql_failure \
  "one persisted server roll per pack" \
  "INSERT INTO cardverse_pack_rolls (pack_id, account_id, idempotency_key, client_reveal_version, policy_version) VALUES ('$PACK', '$ACCOUNT', 'pack-open-attempt-0002', 1, 1)"

echo "✓ PostgreSQL Cardverse migrations and hard constraints passed"


# The relay proof migration makes repeat-person unknown nullable and issuer tickets globally unique.
repeat_nullable="$(psql_zync -Atc "SELECT is_nullable FROM information_schema.columns WHERE table_name='cardverse_reward_proofs' AND column_name='repeat_person'")"
test "$repeat_nullable" = "YES"

psql_zync -c "INSERT INTO cardverse_reward_proofs (
  account_id, client_event_id, event_type, source, occurred_at,
  participant_count, repeat_person, timezone_offset_minutes,
  daily_cycle_start, weekly_cycle_start, verifier, issuer_ticket_id
) VALUES (
  '$ACCOUNT', 'relay-proof-event-1', 'one_to_one_zync', 'one_to_one',
  '2026-09-20T02:00:00Z', 2, NULL, 480,
  '2026-09-19T16:00:00Z', '2026-09-13T16:00:00Z',
  'relay_completion_ticket_v1', 'issuer-ticket-proof-1'
)"

expect_sql_failure \
  "relay proof issuer ticket cannot be replayed" \
  "INSERT INTO cardverse_reward_proofs (
     account_id, client_event_id, event_type, source, occurred_at,
     participant_count, repeat_person, timezone_offset_minutes,
     daily_cycle_start, weekly_cycle_start, verifier, issuer_ticket_id
   ) VALUES (
     '$ACCOUNT', 'relay-proof-event-2', 'one_to_one_zync', 'one_to_one',
     '2026-09-20T02:01:00Z', 2, NULL, 480,
     '2026-09-19T16:00:00Z', '2026-09-13T16:00:00Z',
     'relay_completion_ticket_v1', 'issuer-ticket-proof-1'
   )"

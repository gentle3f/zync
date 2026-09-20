import { timingSafeEqual } from 'node:crypto';

import {
  cardverseAbuseGuardConfigured,
  checkCardverseAbuseGuard,
} from './abuse_guard.js';
import {
  cardverseDatabaseConfigured,
  getCardverseDatabase,
} from './db.js';
import { loadConfiguredCardversePackPolicyV1 } from './pack_policy_v1.js';
import { relayProofTicketsEnabled } from './proof_ticket.js';
import { configuredCardverseProviderAudiences } from './provider_auth.js';
import {
  cardverseAccountLifecycleEnabled,
  cardverseApiEnabled,
  cardversePackOpenEnabled,
  cardverseProofRedeemEnabled,
  cardverseQuestClaimEnabled,
} from './runtime_gate.js';

function enabled(value) {
  return String(value || '').trim().toLowerCase() === 'true';
}

function secret() {
  const value = String(process.env.ZYNC_CARDVERSE_READINESS_SECRET || '').trim();
  return value.length >= 32 ? value : '';
}

function safeEqual(leftValue, rightValue) {
  const left = Buffer.from(String(leftValue || ''));
  const right = Buffer.from(String(rightValue || ''));
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

export function cardverseReadinessEnabled() {
  return enabled(process.env.CARDVERSE_READINESS_ENABLED) && Boolean(secret());
}

export function authorizeCardverseReadiness(authorization) {
  if (!cardverseReadinessEnabled()) return false;
  const raw = typeof authorization === 'string' ? authorization.trim() : '';
  const match = /^Bearer\s+([^\s]{32,256})$/i.exec(raw);
  return Boolean(match && safeEqual(match[1], secret()));
}

async function defaultDatabaseCheck() {
  const db = await getCardverseDatabase();
  const rows = await db.query(`
    SELECT (
      to_regclass('public.zync_accounts') IS NOT NULL AND
      to_regclass('public.zync_identity_links') IS NOT NULL AND
      to_regclass('public.cardverse_pack_entitlements') IS NOT NULL AND
      to_regclass('public.cardverse_stack_balances') IS NOT NULL AND
      to_regclass('public.cardverse_unique_instances') IS NOT NULL AND
      to_regclass('public.cardverse_idempotency_records') IS NOT NULL AND
      to_regclass('public.cardverse_inventory_ledger') IS NOT NULL AND
      to_regclass('public.cardverse_pack_rolls') IS NOT NULL AND
      to_regclass('public.cardverse_pack_roll_items') IS NOT NULL AND
      to_regclass('public.cardverse_auth_challenges') IS NOT NULL AND
      to_regclass('public.zync_account_sessions') IS NOT NULL AND
      to_regclass('public.cardverse_draw_token_balances') IS NOT NULL AND
      to_regclass('public.cardverse_reward_proofs') IS NOT NULL AND
      to_regclass('public.cardverse_reward_grants') IS NOT NULL AND
      to_regclass('public.cardverse_reward_grant_proofs') IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'zync_accounts'
           AND column_name = 'deleted_at'
      ) AND
      EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'zync_identity_links'
           AND column_name = 'unlinked_at'
      )
    ) AS schema_ready
  `);
  return {
    reachable: true,
    schemaReady: rows[0]?.schema_ready === true,
  };
}

async function defaultAbuseCheck() {
  const result = await checkCardverseAbuseGuard();
  return result?.reachable === true;
}

function defaultPackPolicyCheck() {
  loadConfiguredCardversePackPolicyV1();
  return true;
}

function defaultGates() {
  return Object.freeze({
    api: cardverseApiEnabled(),
    packOpen: cardversePackOpenEnabled(),
    questClaim: cardverseQuestClaimEnabled(),
    proofRedeem: cardverseProofRedeemEnabled(),
    accountLifecycle: cardverseAccountLifecycleEnabled(),
  });
}

export async function buildCardverseReadiness(options = {}) {
  const databaseConfigured = options.databaseConfigured ?? cardverseDatabaseConfigured();
  const abuseConfigured = options.abuseConfigured ?? cardverseAbuseGuardConfigured();
  const providers = options.providers ?? configuredCardverseProviderAudiences();
  const proofConfigured = options.proofConfigured ?? relayProofTicketsEnabled();
  const packPolicyConfigured = options.packPolicyConfigured ??
    Boolean(String(process.env.CARDVERSE_PACK_POLICY_V1 || '').trim());
  const gates = options.gates ?? defaultGates();

  let databaseReachable = false;
  let databaseSchemaReady = false;
  if (databaseConfigured) {
    try {
      const databaseResult = await (options.checkDatabase ?? defaultDatabaseCheck)();
      if (databaseResult === true) {
        databaseReachable = true;
        databaseSchemaReady = true;
      } else {
        databaseReachable = databaseResult?.reachable === true;
        databaseSchemaReady = databaseResult?.schemaReady === true;
      }
    } catch (_) {
      databaseReachable = false;
      databaseSchemaReady = false;
    }
  }

  let abuseReachable = false;
  if (abuseConfigured) {
    try {
      abuseReachable = await (options.checkAbuseGuard ?? defaultAbuseCheck)();
    } catch (_) {
      abuseReachable = false;
    }
  }

  let packPolicyValid = false;
  if (packPolicyConfigured) {
    try {
      packPolicyValid = await (options.checkPackPolicy ?? defaultPackPolicyCheck)();
    } catch (_) {
      packPolicyValid = false;
    }
  }

  const baseReady =
    databaseConfigured &&
    databaseReachable &&
    databaseSchemaReady &&
    abuseConfigured &&
    abuseReachable &&
    providers?.any === true;

  const enabledFeatureDependenciesReady =
    (!gates.packOpen || packPolicyValid) &&
    (!gates.proofRedeem || proofConfigured);

  const ready = baseReady && enabledFeatureDependenciesReady;

  return Object.freeze({
    status: ready ? 'ready' : 'not_ready',
    ready,
    checks: Object.freeze({
      database: Object.freeze({
        configured: databaseConfigured,
        reachable: databaseReachable,
        schemaReady: databaseSchemaReady,
      }),
      abuseGuard: Object.freeze({
        configured: abuseConfigured,
        reachable: abuseReachable,
      }),
      providers: Object.freeze({
        google: providers?.google === true,
        apple: providers?.apple === true,
        any: providers?.any === true,
      }),
      proofTickets: Object.freeze({
        configured: proofConfigured,
      }),
      packPolicy: Object.freeze({
        configured: packPolicyConfigured,
        valid: packPolicyValid,
      }),
    }),
    gates: Object.freeze({
      api: gates.api === true,
      packOpen: gates.packOpen === true,
      questClaim: gates.questClaim === true,
      proofRedeem: gates.proofRedeem === true,
      accountLifecycle: gates.accountLifecycle === true,
    }),
  });
}

import {
  applyCardverseAbuseHeaders,
  enforceCardverseAccountRateLimit,
  enforceCardverseIpRateLimit,
} from '../../../_cardverse/abuse_guard.js';
import { getCardverseDatabase } from '../../../_cardverse/db.js';
import {
  cardverseQuestClaimEnabled,
  rejectDisabledCardverse,
} from '../../../_cardverse/runtime_gate.js';
import { claimQuestReward } from '../../../_cardverse/reward_store.js';
import {
  bearerTokenFromAuthorization,
  resolveAccountSession,
} from '../../../_cardverse/session_store.js';

const BAD_REQUEST = new Set([
  'cardverse_quest_claim_invalid',
  'cardverse_quest_unknown',
  'cardverse_quest_client_authority_forbidden',
]);

function statusFor(error) {
  if (error?.code === 'cardverse_database_not_configured' ||
      error?.code === 'cardverse_abuse_guard_not_configured' ||
      error?.code === 'cardverse_abuse_guard_unavailable') return 503;
  if (error?.code === 'cardverse_rate_limited') return 429;
  if (error?.code === 'cardverse_session_missing' ||
      error?.code === 'cardverse_session_invalid') return 401;
  if (error?.code === 'cardverse_account_not_active') return 403;
  if (BAD_REQUEST.has(error?.code)) return 400;
  if (error?.code === 'cardverse_quest_proof_unknown' ||
      error?.code === 'cardverse_quest_proof_cycle_mismatch' ||
      error?.code === 'cardverse_quest_proof_insufficient') return 403;
  if (error?.code === 'cardverse_quest_already_claimed' ||
      error?.code === 'cardverse_idempotency_conflict') return 409;
  return 500;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (!cardverseQuestClaimEnabled()) return rejectDisabledCardverse(res);

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  try {
    await enforceCardverseIpRateLimit(req, 'quest_claim_ip');
    const token = bearerTokenFromAuthorization(req.headers?.authorization);
    const db = await getCardverseDatabase();
    const session = await resolveAccountSession(db, token);
    await enforceCardverseAccountRateLimit(session.accountId, 'quest_claim_account');
    const receipt = await claimQuestReward(db, session.accountId, req.body);
    return res.status(200).json(receipt);
  } catch (error) {
    applyCardverseAbuseHeaders(res, error);
    const status = statusFor(error);
    if (status >= 500) console.error('Cardverse Quest claim failed', error?.code || error?.message);
    return res.status(status).json({ error: error?.code || 'cardverse_quest_claim_failed' });
  }
}

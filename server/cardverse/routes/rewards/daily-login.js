import {
  applyCardverseAbuseHeaders,
  enforceCardverseAccountRateLimit,
  enforceCardverseIpRateLimit,
} from '../../abuse_guard.js';
import { claimDailyLoginReward } from '../../daily_login_store.js';
import { getCardverseDatabase } from '../../db.js';
import {
  cardverseQuestClaimEnabled,
  rejectDisabledCardverse,
} from '../../runtime_gate.js';
import {
  bearerTokenFromAuthorization,
  resolveAccountSession,
} from '../../session_store.js';

const BAD_REQUEST = new Set([
  'cardverse_daily_login_claim_invalid',
  'cardverse_daily_login_client_authority_forbidden',
  'cardverse_timezone_offset_invalid',
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
  if (error?.code === 'cardverse_daily_login_already_claimed' ||
      error?.code === 'cardverse_daily_login_too_soon' ||
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
    await enforceCardverseIpRateLimit(req, 'daily_login_ip');
    const token = bearerTokenFromAuthorization(req.headers?.authorization);
    const db = await getCardverseDatabase();
    const session = await resolveAccountSession(db, token);
    await enforceCardverseAccountRateLimit(
      session.accountId,
      'daily_login_account',
    );
    const receipt = await claimDailyLoginReward(
      db,
      session.accountId,
      req.body,
    );
    return res.status(200).json(receipt);
  } catch (error) {
    applyCardverseAbuseHeaders(res, error);
    const status = statusFor(error);
    if (status >= 500) {
      console.error(
        'Cardverse daily login failed',
        error?.code || error?.message,
      );
    }
    return res.status(status).json({
      error: error?.code || 'cardverse_daily_login_failed',
    });
  }
}

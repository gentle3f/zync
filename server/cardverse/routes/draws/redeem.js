import {
  applyCardverseAbuseHeaders,
  enforceCardverseAccountRateLimit,
  enforceCardverseIpRateLimit,
} from '../../abuse_guard.js';
import { getCardverseDatabase } from '../../db.js';
import { redeemDrawToken } from '../../draw_store.js';
import { createCardverseSingleCardRoller } from '../../pack_policy_v1.js';
import {
  cardverseDrawEnabled,
  rejectDisabledCardverse,
} from '../../runtime_gate.js';
import {
  bearerTokenFromAuthorization,
  resolveAccountSession,
} from '../../session_store.js';

const BAD_REQUEST = new Set([
  'cardverse_draw_request_invalid',
  'cardverse_draw_client_authority_forbidden',
]);

function statusFor(error) {
  if (error?.code === 'cardverse_database_not_configured' ||
      error?.code === 'cardverse_pack_policy_not_configured' ||
      error?.code === 'cardverse_abuse_guard_not_configured' ||
      error?.code === 'cardverse_abuse_guard_unavailable') return 503;
  if (error?.code === 'cardverse_rate_limited') return 429;
  if (error?.code === 'cardverse_session_missing' ||
      error?.code === 'cardverse_session_invalid') return 401;
  if (error?.code === 'cardverse_account_not_active') return 403;
  if (BAD_REQUEST.has(error?.code)) return 400;
  if (error?.code === 'cardverse_draw_token_insufficient' ||
      error?.code === 'cardverse_idempotency_conflict') return 409;
  return 500;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (!cardverseDrawEnabled()) return rejectDisabledCardverse(res);

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  try {
    await enforceCardverseIpRateLimit(req, 'draw_redeem_ip');
    const token = bearerTokenFromAuthorization(req.headers?.authorization);
    const db = await getCardverseDatabase();
    const session = await resolveAccountSession(db, token);
    await enforceCardverseAccountRateLimit(
      session.accountId,
      'draw_redeem_account',
    );
    const receipt = await redeemDrawToken(
      db,
      session.accountId,
      req.body,
      { rollCard: createCardverseSingleCardRoller() },
    );
    return res.status(200).json(receipt);
  } catch (error) {
    applyCardverseAbuseHeaders(res, error);
    const status = statusFor(error);
    if (status >= 500) {
      console.error(
        'Cardverse Draw Token redeem failed',
        error?.code || error?.message,
      );
    }
    return res.status(status).json({
      error: error?.code || 'cardverse_draw_redeem_failed',
    });
  }
}

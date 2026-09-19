import {
  applyCardverseAbuseHeaders,
  enforceCardverseAccountRateLimit,
  enforceCardverseIpRateLimit,
} from '../../../_cardverse/abuse_guard.js';
import { deleteAccount } from '../../../_cardverse/account_lifecycle.js';
import { getCardverseDatabase } from '../../../_cardverse/db.js';
import { verifyProviderAccountAction } from '../../../_cardverse/provider_auth.js';
import {
  cardverseAccountLifecycleEnabled,
  rejectDisabledCardverse,
} from '../../../_cardverse/runtime_gate.js';
import {
  bearerTokenFromAuthorization,
  resolveAccountSession,
} from '../../../_cardverse/session_store.js';

const UNAUTHORIZED = new Set([
  'cardverse_provider_token_invalid',
  'cardverse_provider_subject_missing',
  'cardverse_provider_nonce_missing',
  'cardverse_auth_challenge_invalid',
]);

function statusFor(error) {
  if (error?.code === 'cardverse_database_not_configured' ||
      error?.code === 'cardverse_provider_audience_not_configured' ||
      error?.code === 'cardverse_abuse_guard_not_configured' ||
      error?.code === 'cardverse_abuse_guard_unavailable') return 503;
  if (error?.code === 'cardverse_rate_limited') return 429;
  if (error?.code === 'cardverse_session_missing' ||
      error?.code === 'cardverse_session_invalid' ||
      UNAUTHORIZED.has(error?.code)) return 401;
  if (error?.code === 'cardverse_account_delete_confirmation_invalid' ||
      error?.code === 'cardverse_identity_provider_invalid' ||
      error?.code === 'cardverse_auth_challenge_id_invalid') return 400;
  if (error?.code === 'cardverse_account_not_active' ||
      error?.code === 'cardverse_identity_not_linked') return 403;
  return 500;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (!cardverseAccountLifecycleEnabled()) return rejectDisabledCardverse(res);
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  const body = req.body && typeof req.body === 'object' ? req.body : {};
  if (body.confirmation !== 'DELETE') {
    return res.status(400).json({ error: 'cardverse_account_delete_confirmation_invalid' });
  }
  if (typeof body.idToken !== 'string' || body.idToken.length > 20000) {
    return res.status(400).json({ error: 'cardverse_provider_token_invalid' });
  }

  try {
    await enforceCardverseIpRateLimit(req, 'account_lifecycle_ip');
    const token = bearerTokenFromAuthorization(req.headers?.authorization);
    const db = await getCardverseDatabase();
    const session = await resolveAccountSession(db, token);
    await enforceCardverseAccountRateLimit(session.accountId, 'account_lifecycle_account');
    const identity = await verifyProviderAccountAction(db, {
      provider: body.provider,
      challengeId: body.challengeId,
      idToken: body.idToken,
    });
    await deleteAccount(db, session.accountId, identity);
    return res.status(204).end();
  } catch (error) {
    applyCardverseAbuseHeaders(res, error);
    const status = statusFor(error);
    if (status >= 500) console.error('Cardverse account deletion failed', error?.code || error?.message);
    return res.status(status).json({ error: error?.code || 'cardverse_account_delete_failed' });
  }
}

import {
  applyCardverseAbuseHeaders,
  enforceCardverseAccountRateLimit,
  enforceCardverseIpRateLimit,
} from '../../abuse_guard.js';
import { getCardverseDatabase } from '../../db.js';
import {
  cardverseAccountLifecycleEnabled,
  rejectDisabledCardverse,
} from '../../runtime_gate.js';
import {
  bearerTokenFromAuthorization,
  resolveAccountSession,
  revokeAllAccountSessions,
} from '../../session_store.js';

function statusFor(error) {
  if (error?.code === 'cardverse_database_not_configured' ||
      error?.code === 'cardverse_abuse_guard_not_configured' ||
      error?.code === 'cardverse_abuse_guard_unavailable') return 503;
  if (error?.code === 'cardverse_rate_limited') return 429;
  if (error?.code === 'cardverse_session_missing' ||
      error?.code === 'cardverse_session_invalid') return 401;
  return 500;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (!cardverseAccountLifecycleEnabled()) return rejectDisabledCardverse(res);
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  try {
    await enforceCardverseIpRateLimit(req, 'account_lifecycle_ip');
    const token = bearerTokenFromAuthorization(req.headers?.authorization);
    const db = await getCardverseDatabase();
    const session = await resolveAccountSession(db, token);
    await enforceCardverseAccountRateLimit(session.accountId, 'account_lifecycle_account');
    await revokeAllAccountSessions(db, session.accountId);
    return res.status(204).end();
  } catch (error) {
    applyCardverseAbuseHeaders(res, error);
    const status = statusFor(error);
    if (status >= 500) console.error('Cardverse logout-all failed', error?.code || error?.message);
    return res.status(status).json({ error: error?.code || 'cardverse_logout_all_failed' });
  }
}

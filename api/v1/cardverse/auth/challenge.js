import {\n  applyCardverseAbuseHeaders,\n  enforceCardverseIpRateLimit,\n} from '../../../_cardverse/abuse_guard.js';\nimport { cardverseApiEnabled, rejectDisabledCardverse } from '../../../_cardverse/runtime_gate.js';
import { getCardverseDatabase } from '../../../_cardverse/db.js';
import { createAuthChallenge } from '../../../_cardverse/session_store.js';

function statusFor(error) {
  if (error?.code === 'cardverse_database_not_configured' ||\n      error?.code === 'cardverse_abuse_guard_not_configured' ||\n      error?.code === 'cardverse_abuse_guard_unavailable') return 503;\n  if (error?.code === 'cardverse_rate_limited') return 429;
  if (error?.code === 'cardverse_identity_provider_invalid') return 400;
  return 500;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (!cardverseApiEnabled()) return rejectDisabledCardverse(res);
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  try {
    const db = await getCardverseDatabase();
    const challenge = await createAuthChallenge(db, req.body?.provider);
    return res.status(200).json(challenge);
  } catch (error) {
    const status = statusFor(error);
    if (status >= 500) console.error('Cardverse auth challenge failed', error?.code || error?.message);
    return res.status(status).json({ error: error?.code || 'cardverse_auth_failed' });
  }
}

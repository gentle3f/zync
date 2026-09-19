import { getCardverseDatabase } from '../../../../_cardverse/db.js';
import { authenticateProvider } from '../../../../_cardverse/provider_auth.js';

const UNAUTHORIZED = new Set([
  'cardverse_provider_token_invalid',
  'cardverse_provider_subject_missing',
  'cardverse_provider_nonce_missing',
  'cardverse_auth_challenge_invalid',
]);

function statusFor(error) {
  if (error?.code === 'cardverse_database_not_configured' ||
      error?.code === 'cardverse_provider_audience_not_configured') return 503;
  if (UNAUTHORIZED.has(error?.code)) return 401;
  if (error?.code === 'cardverse_identity_provider_invalid' ||
      error?.code === 'cardverse_auth_challenge_id_invalid') return 400;
  if (error?.code === 'cardverse_account_not_active') return 403;
  return 500;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  const body = req.body && typeof req.body === 'object' ? req.body : {};
  if (typeof body.idToken !== 'string' || body.idToken.length > 20000) {
    return res.status(400).json({ error: 'cardverse_provider_token_invalid' });
  }

  try {
    const db = await getCardverseDatabase();
    const result = await authenticateProvider(db, {
      provider: body.provider,
      challengeId: body.challengeId,
      idToken: body.idToken,
    });
    return res.status(200).json({
      account: result.account,
      accountCreated: result.accountCreated,
      sessionToken: result.session.token,
      sessionExpiresAt: result.session.expiresAt,
      provider: result.identity.provider,
    });
  } catch (error) {
    const status = statusFor(error);
    if (status >= 500) console.error('Cardverse provider auth failed', error?.code || error?.message);
    return res.status(status).json({ error: error?.code || 'cardverse_auth_failed' });
  }
}

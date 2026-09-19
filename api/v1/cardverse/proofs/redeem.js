import {
  applyCardverseAbuseHeaders,
  enforceCardverseAccountRateLimit,
  enforceCardverseIpRateLimit,
} from '../../../_cardverse/abuse_guard.js';
import { getCardverseDatabase } from '../../../_cardverse/db.js';
import { redeemRelayCompletionTicket } from '../../../_cardverse/proof_ticket_redemption.js';
import {
  cardverseProofRedeemEnabled,
  rejectDisabledCardverse,
} from '../../../_cardverse/runtime_gate.js';
import {
  bearerTokenFromAuthorization,
  resolveAccountSession,
} from '../../../_cardverse/session_store.js';

const BAD_REQUEST = new Set([
  'cardverse_proof_redemption_invalid',
  'cardverse_proof_client_authority_forbidden',
  'cardverse_timezone_offset_invalid',
  'cardverse_proof_ticket_invalid',
  'cardverse_proof_ticket_expired',
]);

function statusFor(error) {
  if (error?.code === 'cardverse_database_not_configured' ||
      error?.code === 'cardverse_proof_secret_not_configured') return 503;
  if (error?.code === 'cardverse_rate_limited') return 429;
  if (error?.code === 'cardverse_session_missing' ||
      error?.code === 'cardverse_session_invalid') return 401;
  if (BAD_REQUEST.has(error?.code)) return 400;
  if (error?.code === 'cardverse_proof_ticket_already_redeemed') return 409;
  return 500;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (!cardverseProofRedeemEnabled()) return rejectDisabledCardverse(res);

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  try {
    const token = bearerTokenFromAuthorization(req.headers?.authorization);
    const db = await getCardverseDatabase();
    const session = await resolveAccountSession(db, token);
    await enforceCardverseAccountRateLimit(session.accountId, 'proof_redeem_account');
    const receipt = await redeemRelayCompletionTicket(
      db,
      session.accountId,
      req.body,
    );
    return res.status(200).json(receipt);
  } catch (error) {
    const status = statusFor(error);
    if (status >= 500) {
      console.error('Cardverse proof redemption failed', error?.code || error?.message);
    }
    return res.status(status).json({ error: error?.code || 'cardverse_proof_redemption_failed' });
  }
}

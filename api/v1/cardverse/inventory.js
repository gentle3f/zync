import { getCardverseDatabase } from '../../../_cardverse/db.js';
import { listOwnershipSnapshot } from '../../../_cardverse/ownership_store.js';
import {
  bearerTokenFromAuthorization,
  resolveAccountSession,
} from '../../../_cardverse/session_store.js';

function statusFor(error) {
  if (error?.code === 'cardverse_database_not_configured') return 503;
  if (error?.code === 'cardverse_session_missing' ||
      error?.code === 'cardverse_session_invalid') return 401;
  return 500;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  try {
    const token = bearerTokenFromAuthorization(req.headers?.authorization);
    const db = await getCardverseDatabase();
    const session = await resolveAccountSession(db, token);
    const snapshot = await listOwnershipSnapshot(db, session.accountId);
    return res.status(200).json(snapshot);
  } catch (error) {
    const status = statusFor(error);
    if (status >= 500) console.error('Cardverse inventory failed', error?.code || error?.message);
    return res.status(status).json({ error: error?.code || 'cardverse_inventory_failed' });
  }
}

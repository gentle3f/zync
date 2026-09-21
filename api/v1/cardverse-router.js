import accountDelete from '../../server/cardverse/routes/account/delete.js';
import authChallenge from '../../server/cardverse/routes/auth/challenge.js';
import authLink from '../../server/cardverse/routes/auth/link.js';
import authLogoutAll from '../../server/cardverse/routes/auth/logout-all.js';
import authLogout from '../../server/cardverse/routes/auth/logout.js';
import authProvider from '../../server/cardverse/routes/auth/provider.js';
import authUnlink from '../../server/cardverse/routes/auth/unlink.js';
import inventory from '../../server/cardverse/routes/inventory.js';
import dailyLogin from '../../server/cardverse/routes/rewards/daily-login.js';
import drawRedeem from '../../server/cardverse/routes/draws/redeem.js';
import packOpen from '../../server/cardverse/routes/packs/open.js';
import proofRedeem from '../../server/cardverse/routes/proofs/redeem.js';
import questClaim from '../../server/cardverse/routes/quests/claim.js';
import readiness from '../../server/cardverse/routes/readiness.js';

const ROUTES = Object.freeze({
  'account/delete': accountDelete,
  'auth/challenge': authChallenge,
  'auth/link': authLink,
  'auth/logout-all': authLogoutAll,
  'auth/logout': authLogout,
  'auth/provider': authProvider,
  'auth/unlink': authUnlink,
  'inventory': inventory,
  'rewards/daily-login': dailyLogin,
  'draws/redeem': drawRedeem,
  'packs/open': packOpen,
  'proofs/redeem': proofRedeem,
  'quests/claim': questClaim,
  'readiness': readiness,
});

function routeKey(req) {
  const value = req?.query?.cardverse_route;
  if (Array.isArray(value)) return '';
  return typeof value === 'string' ? value.trim() : '';
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  const route = routeKey(req);
  const selected = ROUTES[route];
  if (!selected) return res.status(404).json({ error: 'not_found' });
  return selected(req, res);
}

export { ROUTES as cardverseRouterRoutes };

import {
  authorizeCardverseReadiness,
  buildCardverseReadiness,
} from '../../_cardverse/readiness.js';

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');

  if (!authorizeCardverseReadiness(req.headers?.authorization)) {
    return res.status(404).json({ error: 'not_found' });
  }

  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  const report = await buildCardverseReadiness();
  return res.status(report.ready ? 200 : 503).json(report);
}

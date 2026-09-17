// Legacy compatibility endpoint for the original Zync client.
// V1 uses /api/v1/question and /api/v1/normalize-interest instead.

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Only POST method allowed' });
  }

  const prompt = typeof req.body?.prompt === 'string' ? req.body.prompt.trim() : '';
  const model = typeof req.body?.model === 'string' ? req.body.model.trim() : '';

  if (!prompt || !model || prompt.length > 6000 || model.length > 160) {
    return res.status(400).json({ error: 'Missing or invalid prompt/model' });
  }

  const apiKey = process.env.OPENROUTER_API_KEY || process.env.API_KEY;
  if (!apiKey) {
    return res.status(503).json({ error: 'AI not configured' });
  }

  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        messages: [{ role: 'user', content: prompt }],
      }),
    });

    const data = await response.json().catch(() => ({}));
    res.setHeader('Cache-Control', 'no-store');
    return res.status(response.ok ? 200 : 502).json(data);
  } catch (_) {
    return res.status(502).json({ error: 'API request failed' });
  }
}

// Legacy compatibility endpoint for the original Zync client.
// V1 uses /api/v1/question and /api/v1/normalize-interest instead.

function safeStringArray(value, max = 50) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item) => typeof item === 'string')
    .map((item) => item.trim().slice(0, 120))
    .filter(Boolean)
    .slice(0, max);
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Only POST method allowed' });
  }

  const promptSource = typeof req.body?.promptSource === 'string' ? req.body.promptSource.trim() : '';
  const interests = safeStringArray(req.body?.interests);
  const askedQuestions = safeStringArray(req.body?.asked_questions);

  if (!/^[A-Za-z0-9_-]{1,64}$/.test(promptSource) || interests.length === 0) {
    return res.status(400).json({ error: 'Missing or invalid promptSource/interests' });
  }

  const apiKey = process.env.OPENROUTER_API_KEY || process.env.API_KEY;
  if (!apiKey) {
    return res.status(503).json({ error: 'AI not configured' });
  }

  try {
    const githubPromptUrl = `https://raw.githubusercontent.com/gentle3f/zync/main/prompts/${promptSource}.json`;
    const promptResponse = await fetch(githubPromptUrl);
    if (!promptResponse.ok) {
      return res.status(502).json({ error: 'Prompt template unavailable' });
    }
    const promptJson = await promptResponse.json();
    if (typeof promptJson?.prompt !== 'string') {
      return res.status(502).json({ error: 'Invalid prompt template' });
    }

    const model = typeof promptJson.model === 'string' && promptJson.model.trim()
      ? promptJson.model.trim().slice(0, 160)
      : 'openrouter/free';
    const finalPrompt = promptJson.prompt
      .replace('{interests}', interests.join(', '))
      .replace('{asked_questions}', askedQuestions.join('、'));

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        messages: [{ role: 'user', content: finalPrompt }],
      }),
    });

    const data = await response.json().catch(() => ({}));
    res.setHeader('Cache-Control', 'no-store');
    return res.status(response.ok ? 200 : 502).json(data);
  } catch (_) {
    return res.status(502).json({ error: 'API request failed' });
  }
}

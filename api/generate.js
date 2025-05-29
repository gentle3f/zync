// api/generate.js

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Only POST method allowed' });
  }

  const { prompt, model } = req.body;

  if (!prompt || !model) {
    return res.status(400).json({ error: 'Missing prompt or model in body' });
  }

  // ✅ 直接在這裡放入你的 OpenRouter API 金鑰（僅限於私有專案使用）
  const OPENROUTER_API_KEY = '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';

  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://zync-hazel.vercel.app',
        'X-Title': 'Zync App'
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'user', content: prompt }
        ]
      })
    });

    const data = await response.json();
    res.status(200).json(data);
  } catch (err) {
    res.status(500).json({ error: 'API request failed', details: err.message });
  }
}

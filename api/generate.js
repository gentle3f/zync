// api/generate.js

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Only POST method allowed' });
  }

  const { language, type, interests, model } = req.body;

  if (!language || !type || !interests || !model) {
    return res.status(400).json({ error: 'Missing required fields in body' });
  }

  try {
    const fileURL = `https://raw.githubusercontent.com/gentle3f/zync/main/prompts/${language}${type}.json`;
    const promptData = await fetch(fileURL).then(res => res.json());
    const promptText = promptData.prompt.replace('{interests}', interests.join(','));

    const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

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
          { role: 'user', content: promptText }
        ]
      })
    });

    const data = await response.json();
    res.status(200).json(data);
  } catch (err) {
    res.status(500).json({ error: 'API request failed', details: err.message });
  }
}

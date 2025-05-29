export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Only POST method allowed' });
  }

  const { prompt, model } = req.body;

  if (!prompt || !model) {
    return res.status(400).json({ error: 'Missing prompt or model' });
  }

  try {
    const response = await fetch('https://openrouter.ai/api/v1/', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer YOUR_KEY`,
        'Content-Type': 'application/json; charset=utf-8'
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

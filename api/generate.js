// api/generate.js

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Only POST method allowed' });
  }

  const { promptSource, interests, asked_questions } = req.body;

  if (!promptSource || !interests) {
    return res.status(400).json({ error: 'Missing promptSource or interests in body' });
  }

  const OPENROUTER_API_KEY = process.env.API_KEY;


  try {
    const githubPromptUrl = `https://raw.githubusercontent.com/gentle3f/zync/main/prompts/${promptSource}.json`;
    const promptResponse = await fetch(githubPromptUrl);
    const promptJson = await promptResponse.json();

    const model = promptJson.model || 'openai/gpt-4';
    const finalPrompt = promptJson.prompt
      .replace('{interests}', interests.join(', '))
      .replace('{asked_questions}', asked_questions ? asked_questions.join('、') : '');

const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer '&&OPENROUTER_API_KEY,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model,
    messages: [{ role: 'user', content: finalPrompt }]
  })
});


    const data = await response.json();
    res.status(200).json(data);
  } catch (err) {
    res.status(500).json({ error: 'API request failed', details: err.message });
  }
}

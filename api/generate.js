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
      .replace('{asked_questions}', asked_questions ? asked_questions.join(',') : '');

    console.log("Sending Headers:", {
      'Authorization': 'Bearer ' + OPENROUTER_API_KEY,
      'Content-Type': 'application/json'
    });

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + OPENROUTER_API_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: model,
        messages: [{ role: 'user', content: finalPrompt }]
      })
    });

    const data = await response.json();
    console.log("Raw response from OpenRouter:", JSON.stringify(data, null, 2));

    // Normalize and extract final content from known patterns
    let finalText = "";
    if (data.choices && data.choices[0]?.message?.content) {
      finalText = data.choices[0].message.content;
    } else if (data.choices && data.choices[0]?.text) {
      finalText = data.choices[0].text;
    } else if (data.choices && data.choices[0]?.message && data.choices[0].message?.text) {
      finalText = data.choices[0].message.text;
    } else {
      finalText = "⚠️ AI 回應格式錯誤，請稍後再試。";
    }

    res.status(200).json({ result: finalText });
  } catch (err) {
    console.log("API request failed:", err);
    res.status(200).json({ result: "❌ 發生錯誤，請稍後再試。" });
  }
}

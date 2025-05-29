// File: api/generate.js

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Only POST method allowed' });
  }

  const { interests, language, askedQuestions = [] } = req.body;

  if (!interests || !Array.isArray(interests) || interests.length === 0) {
    return res.status(400).json({ error: 'Invalid interests input' });
  }

  const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

  const prompt = buildPrompt({ interests, language, askedQuestions });

  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
    },
    body: JSON.stringify({
      model: "openrouter/openai/gpt-4o",
      messages: [
        {
          role: "user",
          content: prompt,
        },
      ],
    }),
  });

  const data = await response.json();

  if (!data.choices || !data.choices[0]) {
    return res.status(500).json({ error: 'AI response error' });
  }

  return res.status(200).json({ result: data.choices[0].message.content });
}

function buildPrompt({ interests, language, askedQuestions }) {
  const joinedInterests = interests.join('、');
  const joinedAsked = askedQuestions.join('\n');

  if (language === 'zh') {
    return `你是一個 AI 助理，目標是幫助兩位素未謀面的使用者，在現實生活中自然地展開對話。根據以下共同興趣：「${joinedInterests}」，請從中挑選出最值得提出對話問題的三個興趣。請避免與以下問題重複：\n${joinedAsked}\n如果所有興趣都已問過，也可以再根據其中任一項目提出新的角度。請以以下格式回應：\n1. ...\n2. ...\n3. ...`;
  } else {
    return `You are an AI assistant. Your goal is to help two people start a conversation naturally in real life. Based on the following common interests: ${joinedInterests}, pick three that are best to ask questions about. Avoid overlapping with the following already-asked questions:\n${joinedAsked}\nIf all topics have been used, generate new angles on any of them. Format the output like:\n1. ...\n2. ...\n3. ...`;
  }
}

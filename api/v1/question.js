const ALLOWED_MODES = new Set(['easy', 'fun', 'debate', 'deep', 'guess', 'surprise']);

function stringArray(value, max = 12) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item) => typeof item === 'string')
    .map((item) => item.trim())
    .filter(Boolean)
    .slice(0, max);
}

function buildPrompt({ language, mode, shared, personA, personB }) {
  const commonRules = [
    'You are the conversation engine for Zync, an offline social icebreaker.',
    `Write exactly ONE conversation question in ${language}.`,
    'The question must make the two people interact with each other, not answer two independent survey questions.',
    'Make it specific, natural, concise, and genuinely discussable.',
    'Do not mention that you are an AI. Do not explain your reasoning. Return only the question.',
    `Conversation mode: ${mode}.`,
  ];

  if (shared.length > 0) {
    return [
      ...commonRules,
      `Their shared interests are: ${shared.join(', ')}.`,
      'Use one or more shared interests to create a question likely to produce a real back-and-forth conversation.',
      mode === 'guess' ? 'For guess mode, make them predict something about each other and then compare answers.' : '',
      mode === 'debate' ? 'For debate mode, give them a friendly position or trade-off they can disagree about.' : '',
      mode === 'deep' ? 'For deep mode, make it meaningful without becoming intrusive or therapeutic.' : '',
    ].filter(Boolean).join('\n');
  }

  return [
    ...commonRules,
    `Person A interests: ${personA.join(', ') || 'not provided'}.`,
    `Person B interests: ${personB.join(', ') || 'not provided'}.`,
    'There is no exact shared interest. Find a clever but plausible crossover between one interest from A and one from B, then turn that crossover into a question both can meaningfully discuss.',
    'Do not frame the lack of a match as a failure.',
  ].join('\n');
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  const body = req.body && typeof req.body === 'object' ? req.body : {};
  const language = typeof body.language === 'string' && body.language.trim()
    ? body.language.trim().slice(0, 32)
    : 'en';
  const mode = ALLOWED_MODES.has(body.mode) ? body.mode : 'fun';
  const shared = stringArray(body.shared);
  const personA = stringArray(body.personA);
  const personB = stringArray(body.personB);

  if (shared.length === 0 && personA.length === 0 && personB.length === 0) {
    return res.status(400).json({ error: 'interests_required' });
  }

  const apiKey = process.env.OPENROUTER_API_KEY || process.env.API_KEY;
  if (!apiKey) {
    return res.status(503).json({ error: 'ai_not_configured' });
  }

  const model = process.env.OPENROUTER_MODEL || 'openrouter/free';
  const prompt = buildPrompt({ language, mode, shared, personA, personB });

  try {
    const upstream = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': process.env.ZYNC_PUBLIC_URL || 'https://zync.app',
        'X-Title': 'Zync',
      },
      body: JSON.stringify({
        model,
        messages: [
          {
            role: 'system',
            content: 'You write safe, friendly social icebreaker questions. Avoid sexual content, harassment, private-data requests, medical/legal/financial advice, and manipulative questions.',
          },
          { role: 'user', content: prompt },
        ],
        temperature: mode === 'surprise' ? 1.0 : 0.8,
        max_tokens: 180,
      }),
    });

    const data = await upstream.json().catch(() => ({}));
    if (!upstream.ok) {
      console.error('OpenRouter question error', upstream.status, data?.error?.message || data?.error || 'unknown');
      return res.status(502).json({ error: 'ai_upstream_error' });
    }

    const question = data?.choices?.[0]?.message?.content?.trim();
    if (!question) {
      return res.status(502).json({ error: 'empty_ai_response' });
    }

    res.setHeader('Cache-Control', 'no-store');
    return res.status(200).json({ question, model });
  } catch (error) {
    console.error('Question generation failed', error?.message || error);
    return res.status(502).json({ error: 'ai_request_failed' });
  }
}

import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

async function loadHandler(path) {
  const source = await readFile(path, 'utf8');
  const encoded = Buffer.from(source).toString('base64');
  const module = await import(`data:text/javascript;base64,${encoded}`);
  return module.default;
}

function makeResponse() {
  const state = { status: 200, body: undefined };
  const res = {
    status(code) { state.status = code; return res; },
    json(value) { state.body = value; return res; },
    setHeader() { return res; },
  };
  return { state, res };
}

async function invoke(handler, body) {
  const { state, res } = makeResponse();
  await handler({ method: 'POST', body }, res);
  return state;
}

function enableAi() {
  process.env.OPENROUTER_API_KEY = 'privacy-contract-key';
  process.env.OPENROUTER_MODEL = 'openrouter/free';
}

function captureSuccessfulFetch(responseContent) {
  let request;
  globalThis.fetch = async (url, options) => {
    request = { url, options };
    return {
      ok: true,
      status: 200,
      json: async () => ({ choices: [{ message: { content: responseContent } }] }),
    };
  };
  return () => request;
}

function assertZeroRetention(request) {
  assert.equal(request.url, 'https://openrouter.ai/api/v1/chat/completions');
  const upstream = JSON.parse(request.options.body);
  assert.equal(upstream.provider?.zdr, true);
  assert.equal(upstream.provider?.data_collection, 'deny');
  if ('allow_fallbacks' in upstream.provider) {
    assert.equal(upstream.provider.allow_fallbacks, true);
  }
  if ('reasoning_effort' in upstream) {
    assert.equal(upstream.reasoning_effort, 'none');
    assert.deepEqual(upstream.modalities, ['text']);
    assert.ok(Number.isInteger(upstream.max_completion_tokens));
    assert.equal('max_tokens' in upstream, false);
  }
  assert.ok(request.options.signal, 'OpenRouter request must retain its timeout/abort signal');
}

const question = await loadHandler('api/v1/question.js');
const normalize = await loadHandler('api/v1/normalize-interest.js');

enableAi();

{
  const getRequest = captureSuccessfulFetch('What would you both want to try together?');
  const result = await invoke(question, {
    language: 'en',
    mode: 'fun',
    shared: ['Badminton'],
  });
  assert.equal(result.status, 200);
  assertZeroRetention(getRequest());
  console.log('✓ question endpoint enforces OpenRouter ZDR and denies provider data collection');
}

{
  const getRequest = captureSuccessfulFetch(
    '{"canonicalName":"Urban Sketching","displayName":"Urban Sketching","category":"arts"}',
  );
  const result = await invoke(normalize, {
    input: 'urban sketching',
    language: 'en',
  });
  assert.equal(result.status, 200);
  assertZeroRetention(getRequest());
  console.log('✓ normalization endpoint enforces OpenRouter ZDR and denies provider data collection');
}

console.log('\n2 OpenRouter privacy contract tests passed.');

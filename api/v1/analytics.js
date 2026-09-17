const EVENT_PROPERTIES = {
  app_open: {
    locale: 'locale',
    profile_ready: 'boolean',
  },
  interest_setup_complete: {
    selected_count: 'count',
  },
  interest_added: {
    source: 'interest_source',
    selected_count: 'count',
  },
  qr_generated: {
    interest_count: 'count',
    transport: 'transport',
  },
  qr_scanned: {
    transport: 'transport',
  },
  match_complete: {
    has_match: 'boolean',
    repeat_peer: 'boolean',
  },
  match_count: {
    count: 'count',
  },
  question_generated: {
    mode: 'mode',
    source: 'question_source',
    match_type: 'match_type',
    bilingual: 'boolean',
  },
  question_next: {
    mode: 'mode',
  },
  mode_selected: {
    mode: 'mode',
  },
  zync_again: {
    prior_sessions: 'count',
  },
};

const LOCALES = new Set(['en', 'zh-Hant', 'zh-Hans', 'ja', 'ko', 'es', 'fr', 'pt']);
const MODES = new Set(['easy', 'fun', 'debate', 'deep', 'guess', 'surprise']);
const INTEREST_SOURCES = new Set(['seed', 'saved_custom', 'ai_normalized']);
const QUESTION_SOURCES = new Set(['ai', 'fallback']);
const MATCH_TYPES = new Set(['shared', 'crossover']);
const TRANSPORTS = new Set(['legacy', 'compressed']);
const UUIDISH = /^[a-zA-Z0-9-]{16,64}$/;

function canonicalLocale(value) {
  const raw = typeof value === 'string' ? value.trim().replaceAll('_', '-') : '';
  if (!raw) return null;
  if (/^zh-(hant|hk|tw|mo)/i.test(raw)) return 'zh-Hant';
  if (/^zh-(hans|cn|sg)/i.test(raw)) return 'zh-Hans';
  const base = raw.split('-')[0].toLowerCase();
  return LOCALES.has(base) ? base : null;
}

function sanitizeProperty(type, value) {
  if (type === 'boolean') return typeof value === 'boolean' ? value : undefined;
  if (type === 'count') {
    if (typeof value !== 'number' || !Number.isFinite(value)) return undefined;
    return Math.max(0, Math.min(1000, Math.round(value)));
  }
  if (type === 'locale') return canonicalLocale(value) ?? undefined;
  if (type === 'mode') return typeof value === 'string' && MODES.has(value) ? value : undefined;
  if (type === 'interest_source') {
    return typeof value === 'string' && INTEREST_SOURCES.has(value) ? value : undefined;
  }
  if (type === 'question_source') {
    return typeof value === 'string' && QUESTION_SOURCES.has(value) ? value : undefined;
  }
  if (type === 'match_type') {
    return typeof value === 'string' && MATCH_TYPES.has(value) ? value : undefined;
  }
  if (type === 'transport') {
    return typeof value === 'string' && TRANSPORTS.has(value) ? value : undefined;
  }
  return undefined;
}

function sanitizeProperties(event, input) {
  const schema = EVENT_PROPERTIES[event];
  if (!schema || !input || typeof input !== 'object' || Array.isArray(input)) return {};
  const clean = {};
  for (const [key, type] of Object.entries(schema)) {
    const value = sanitizeProperty(type, input[key]);
    if (value !== undefined) clean[key] = value;
  }
  return clean;
}

function analyticsConfig() {
  const apiKey = (process.env.POSTHOG_PROJECT_API_KEY || '').trim();
  const host = (process.env.POSTHOG_HOST || '').trim().replace(/\/$/, '');
  if (!apiKey || !host) return null;
  try {
    const parsed = new URL(host);
    if (parsed.protocol !== 'https:') return null;
  } catch (_) {
    return null;
  }
  return { apiKey, host };
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  const body = req.body && typeof req.body === 'object' ? req.body : {};
  const event = typeof body.event === 'string' ? body.event.trim() : '';
  const installId = typeof body.installId === 'string' ? body.installId.trim() : '';
  const sessionId = typeof body.sessionId === 'string' ? body.sessionId.trim() : '';

  if (!Object.hasOwn(EVENT_PROPERTIES, event)) {
    return res.status(400).json({ error: 'analytics_event_invalid' });
  }
  if (!UUIDISH.test(installId) || !UUIDISH.test(sessionId)) {
    return res.status(400).json({ error: 'analytics_identity_invalid' });
  }

  const config = analyticsConfig();
  if (!config) {
    return res.status(503).json({ error: 'analytics_not_configured' });
  }

  const properties = sanitizeProperties(event, body.properties);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);
  try {
    const upstream = await fetch(`${config.host}/capture/`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        api_key: config.apiKey,
        event,
        properties: {
          distinct_id: `zync:${installId}`,
          zync_session_id: sessionId,
          zync_schema_version: 1,
          $process_person_profile: false,
          ...properties,
        },
      }),
      signal: controller.signal,
    });

    if (!upstream.ok) {
      return res.status(502).json({ error: 'analytics_upstream_error' });
    }

    res.setHeader('Cache-Control', 'no-store');
    return res.status(200).json({ ok: true });
  } catch (_) {
    return res.status(502).json({ error: 'analytics_upstream_error' });
  } finally {
    clearTimeout(timeout);
  }
}

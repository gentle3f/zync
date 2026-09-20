import {
  createHash,
  createHmac,
  timingSafeEqual,
} from 'node:crypto';

const PREFIX = 'ZP1';
const ROLE_SET = new Set(['host', 'scanner']);
const DEFAULT_TTL_DAYS = 30;
const MAX_TTL_DAYS = 90;
const SESSION_RE = /^[A-Za-z0-9_-]{22,64}$/;
const CAPABILITY_RE = /^[A-Za-z0-9_-]{43}$/;
const TICKET_RE = /^ZP1\.([A-Za-z0-9_-]+)\.([A-Za-z0-9_-]{43})$/;

function domainError(code) {
  const error = new Error(code);
  error.code = code;
  return error;
}

function secret() {
  const value = String(process.env.ZYNC_CARDVERSE_PROOF_SECRET || '').trim();
  return value.length >= 32 ? value : '';
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

function hmac(value) {
  const key = secret();
  if (!key) throw domainError('cardverse_proof_secret_not_configured');
  return createHmac('sha256', key).update(value).digest();
}

function b64url(value) {
  return Buffer.from(value).toString('base64url');
}

function ttlDays() {
  const raw = Number(process.env.CARDVERSE_PROOF_TICKET_DAYS);
  if (Number.isInteger(raw) && raw >= 1 && raw <= MAX_TTL_DAYS) return raw;
  return DEFAULT_TTL_DAYS;
}

function safeEqualString(a, b) {
  const left = Buffer.from(String(a));
  const right = Buffer.from(String(b));
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

export function relayProofTicketsEnabled() {
  return Boolean(secret());
}

export function createRelayResponderCapability(sessionId, opaquePayload) {
  if (!relayProofTicketsEnabled()) return null;
  if (!SESSION_RE.test(String(sessionId || ''))) {
    throw domainError('cardverse_relay_session_invalid');
  }
  const payloadHash = sha256(String(opaquePayload || ''));
  return b64url(hmac('relay-capability-v1|' + sessionId + '|' + payloadHash));
}

export function relayResponderCapabilityHash(capability) {
  if (!CAPABILITY_RE.test(String(capability || ''))) {
    throw domainError('cardverse_relay_capability_invalid');
  }
  return sha256(capability);
}

export function createRelayCompletionTicket({
  sessionId,
  role,
  completedAtMs,
}) {
  if (!SESSION_RE.test(String(sessionId || ''))) {
    throw domainError('cardverse_relay_session_invalid');
  }
  if (!ROLE_SET.has(role)) throw domainError('cardverse_relay_role_invalid');

  const completed = Number(completedAtMs);
  if (!Number.isInteger(completed) || completed < 1) {
    throw domainError('cardverse_relay_completion_time_invalid');
  }

  const jti = createHmac('sha256', secret())
    .update('relay-proof-jti-v1|' + sessionId + '|' + role)
    .digest('hex');
  const expiresAtMs = completed + ttlDays() * 86_400_000;
  const payload = {
    v: 1,
    jti,
    typ: 'one_to_one_zync',
    src: 'one_to_one',
    pc: 2,
    iat: completed,
    exp: expiresAtMs,
  };
  const encoded = b64url(Buffer.from(JSON.stringify(payload), 'utf8'));
  const signature = b64url(hmac(PREFIX + '.' + encoded));
  return PREFIX + '.' + encoded + '.' + signature;
}

export function verifyRelayCompletionTicket(ticketValue, options = {}) {
  const ticket = String(ticketValue || '').trim();
  const match = TICKET_RE.exec(ticket);
  if (!match) throw domainError('cardverse_proof_ticket_invalid');

  const expected = b64url(hmac(PREFIX + '.' + match[1]));
  if (!safeEqualString(expected, match[2])) {
    throw domainError('cardverse_proof_ticket_invalid');
  }

  let payload;
  try {
    payload = JSON.parse(Buffer.from(match[1], 'base64url').toString('utf8'));
  } catch (_) {
    throw domainError('cardverse_proof_ticket_invalid');
  }

  const nowMs = Number.isFinite(options.nowMs) ? Number(options.nowMs) : Date.now();
  if (
    payload?.v !== 1 ||
    typeof payload?.jti !== 'string' ||
    !/^[a-f0-9]{64}$/.test(payload.jti) ||
    payload?.typ !== 'one_to_one_zync' ||
    payload?.src !== 'one_to_one' ||
    payload?.pc !== 2 ||
    !Number.isInteger(payload?.iat) ||
    !Number.isInteger(payload?.exp) ||
    payload.exp <= payload.iat ||
    nowMs >= payload.exp
  ) {
    throw domainError(
      Number.isInteger(payload?.exp) && nowMs >= payload.exp
        ? 'cardverse_proof_ticket_expired'
        : 'cardverse_proof_ticket_invalid',
    );
  }

  return Object.freeze({
    issuerTicketId: payload.jti,
    eventType: payload.typ,
    source: payload.src,
    participantCount: payload.pc,
    occurredAt: new Date(payload.iat).toISOString(),
    expiresAt: new Date(payload.exp).toISOString(),
  });
}

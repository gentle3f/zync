import { ensureAccountForIdentity, linkIdentityToAccount } from './ownership_store.js';
import {
  consumeAuthChallenge,
  createAccountSession,
} from './session_store.js';

const PROVIDERS = {
  google: {
    issuers: ['https://accounts.google.com', 'accounts.google.com'],
    jwksUrl: 'https://www.googleapis.com/oauth2/v3/certs',
    audienceEnv: 'ZYNC_GOOGLE_CLIENT_IDS',
  },
  apple: {
    issuers: ['https://appleid.apple.com'],
    jwksUrl: 'https://appleid.apple.com/auth/keys',
    audienceEnv: 'ZYNC_APPLE_CLIENT_IDS',
  },
};

const jwksCache = new Map();

function domainError(code) {
  const error = new Error(code);
  error.code = code;
  return error;
}

function cleanText(value, max) {
  if (typeof value !== 'string') return '';
  const clean = value.trim();
  return clean.length <= max ? clean : '';
}

function providerConfig(value) {
  const provider = cleanText(value, 32).toLowerCase();
  const config = PROVIDERS[provider];
  if (!config) throw domainError('cardverse_identity_provider_invalid');
  return { provider, ...config };
}

function parseAudiences(value) {
  return String(value || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
    .slice(0, 12);
}

function verifiedFlag(value) {
  return value === true || value === 'true';
}

async function defaultJwtVerify(idToken, config, audiences) {
  const { createRemoteJWKSet, jwtVerify } = await import('jose');
  let jwks = jwksCache.get(config.provider);
  if (!jwks) {
    jwks = createRemoteJWKSet(new URL(config.jwksUrl));
    jwksCache.set(config.provider, jwks);
  }
  return jwtVerify(idToken, jwks, {
    issuer: config.issuers,
    audience: audiences,
    algorithms: ['RS256'],
  });
}

export async function verifyProviderIdToken(providerInput, idTokenInput, options = {}) {
  const config = providerConfig(providerInput);
  const idToken = cleanText(idTokenInput, 20000);
  if (!idToken || idToken.split('.').length !== 3) {
    throw domainError('cardverse_provider_token_invalid');
  }

  const audiences = options.audiences?.length
    ? options.audiences
    : parseAudiences(process.env[config.audienceEnv]);
  if (!audiences.length) throw domainError('cardverse_provider_audience_not_configured');

  let verified;
  try {
    verified = options.verifyJwt
      ? await options.verifyJwt({
          provider: config.provider,
          idToken,
          issuers: config.issuers,
          audience: audiences,
          jwksUrl: config.jwksUrl,
          algorithms: ['RS256'],
        })
      : await defaultJwtVerify(idToken, config, audiences);
  } catch (_) {
    throw domainError('cardverse_provider_token_invalid');
  }

  const payload = verified?.payload ?? verified;
  const providerSubject = cleanText(payload?.sub, 255);
  const nonce = cleanText(payload?.nonce, 512);
  if (!providerSubject) throw domainError('cardverse_provider_subject_missing');
  if (!nonce) throw domainError('cardverse_provider_nonce_missing');

  return {
    provider: config.provider,
    providerSubject,
    providerEmail: cleanText(payload?.email, 320) || null,
    emailVerified: verifiedFlag(payload?.email_verified),
    nonce,
  };
}

export async function authenticateProvider(db, input = {}, options = {}) {
  const identity = await verifyProviderIdToken(
    input.provider,
    input.idToken,
    options,
  );

  await consumeAuthChallenge(db, {
    challengeId: input.challengeId,
    provider: identity.provider,
    nonce: identity.nonce,
  });

  const accountResult = await ensureAccountForIdentity(db, identity);
  if (accountResult.account.status !== 'active') {
    throw domainError('cardverse_account_not_active');
  }

  const session = await createAccountSession(
    db,
    accountResult.account.id,
    options.sessionOptions,
  );

  return {
    account: accountResult.account,
    accountCreated: accountResult.created,
    session,
    identity: {
      provider: identity.provider,
      emailVerified: identity.emailVerified,
    },
  };
}


export async function verifyProviderAccountAction(db, input = {}, options = {}) {
  const identity = await verifyProviderIdToken(
    input.provider,
    input.idToken,
    options,
  );

  await consumeAuthChallenge(db, {
    challengeId: input.challengeId,
    provider: identity.provider,
    nonce: identity.nonce,
  });

  return identity;
}

export async function linkProviderIdentityToAccount(db, accountId, input = {}, options = {}) {
  const identity = await verifyProviderAccountAction(db, input, options);
  const linked = await linkIdentityToAccount(db, accountId, identity);
  return {
    ...linked,
    identity: {
      provider: identity.provider,
      emailVerified: identity.emailVerified,
    },
  };
}

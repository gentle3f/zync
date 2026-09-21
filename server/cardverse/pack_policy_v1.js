import { randomInt as cryptoRandomInt } from 'node:crypto';

import {
  CARDVERSE_ART_SYSTEM_VERSION,
  CARDVERSE_PACK_CATALOG_V1,
  CARDVERSE_PACK_CATALOG_VERSION,
} from './catalog_v1.js';

const FINISH_ORDER = Object.freeze([
  'normal',
  'foil',
  'holo',
  'prism',
  'legendary',
  'secret',
]);
const FINISH_INDEX = new Map(FINISH_ORDER.map((finish, index) => [finish, index]));
const CATALOG_SET = new Set(CARDVERSE_PACK_CATALOG_V1);
const PACK_TYPES = new Set(['standard', 'discovery']);
const MAX_WEIGHT = 1_000_000;
const MAX_TOTAL_WEIGHT = 1_000_000_000;

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

function positiveWeight(value, code) {
  const weight = Number(value);
  if (!Number.isInteger(weight) || weight < 1 || weight > MAX_WEIGHT) {
    throw domainError(code);
  }
  return weight;
}

function normalizeWeights(raw, allowedKeys, code) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError(code);
  }
  const entries = [];
  let total = 0;
  for (const [key, value] of Object.entries(raw)) {
    if (!allowedKeys.has(key)) throw domainError(code);
    const weight = positiveWeight(value, code);
    total += weight;
    if (total > MAX_TOTAL_WEIGHT) throw domainError(code);
    entries.push(Object.freeze({ key, weight }));
  }
  if (!entries.length) throw domainError(code);
  return Object.freeze({ entries: Object.freeze(entries), total });
}

function normalizeGuarantee(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError('cardverse_pack_guarantee_invalid');
  }
  if (raw.type === 'none') {
    return Object.freeze({ type: 'none' });
  }
  if (raw.type === 'at_least_one_finish') {
    const minimumFinish = cleanText(raw.minimumFinish, 32).toLowerCase();
    if (!FINISH_INDEX.has(minimumFinish)) {
      throw domainError('cardverse_pack_guarantee_invalid');
    }
    return Object.freeze({
      type: 'at_least_one_finish',
      minimumFinish,
    });
  }
  throw domainError('cardverse_pack_guarantee_invalid');
}

function normalizePackPolicy(packType, raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError('cardverse_pack_policy_invalid');
  }
  const editionId = cleanText(raw.editionId, 120).toLowerCase();
  if (!editionId || editionId.includes('::')) {
    throw domainError('cardverse_pack_edition_invalid');
  }

  const interestWeights = normalizeWeights(
    raw.interestWeights,
    CATALOG_SET,
    'cardverse_pack_interest_weights_invalid',
  );
  const finishWeights = normalizeWeights(
    raw.finishWeights,
    new Set(FINISH_ORDER),
    'cardverse_pack_finish_weights_invalid',
  );

  return Object.freeze({
    packType,
    editionId,
    interestWeights,
    finishWeights,
    guarantee: normalizeGuarantee(raw.guarantee),
  });
}

export function parseCardversePackPolicyV1(rawValue) {
  let raw;
  try {
    raw = typeof rawValue === 'string' ? JSON.parse(rawValue) : rawValue;
  } catch (_) {
    throw domainError('cardverse_pack_policy_invalid');
  }
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw domainError('cardverse_pack_policy_invalid');
  }
  if (raw.version !== 1 || raw.catalogVersion !== CARDVERSE_PACK_CATALOG_VERSION) {
    throw domainError('cardverse_pack_policy_version_invalid');
  }
  if (!raw.packs || typeof raw.packs !== 'object' || Array.isArray(raw.packs)) {
    throw domainError('cardverse_pack_policy_invalid');
  }

  const packs = {};
  for (const packType of PACK_TYPES) {
    packs[packType] = normalizePackPolicy(packType, raw.packs[packType]);
  }

  return Object.freeze({
    version: 1,
    catalogVersion: CARDVERSE_PACK_CATALOG_VERSION,
    packs: Object.freeze(packs),
  });
}

export function loadConfiguredCardversePackPolicyV1() {
  const raw = String(process.env.CARDVERSE_PACK_POLICY_V1 || '').trim();
  if (!raw) throw domainError('cardverse_pack_policy_not_configured');
  return parseCardversePackPolicyV1(raw);
}

function drawWeighted(weights, randomInt) {
  const needle = randomInt(weights.total);
  if (!Number.isInteger(needle) || needle < 0 || needle >= weights.total) {
    throw domainError('cardverse_server_rng_invalid');
  }
  let cursor = 0;
  for (const entry of weights.entries) {
    cursor += entry.weight;
    if (needle < cursor) return entry.key;
  }
  throw domainError('cardverse_server_rng_invalid');
}

function finishMeetsMinimum(finish, minimum) {
  return FINISH_INDEX.get(finish) >= FINISH_INDEX.get(minimum);
}

function eligibleGuaranteedFinishes(weights, minimum) {
  const minimumIndex = FINISH_INDEX.get(minimum);
  const entries = weights.entries.filter(
    (entry) => FINISH_INDEX.get(entry.key) >= minimumIndex,
  );
  if (!entries.length) throw domainError('cardverse_pack_guarantee_unreachable');
  const total = entries.reduce((sum, entry) => sum + entry.weight, 0);
  return Object.freeze({ entries: Object.freeze(entries), total });
}

export function createCardversePackRoller(options = {}) {
  const policy = options.policy ?? loadConfiguredCardversePackPolicyV1();
  const randomInt = options.randomInt ?? cryptoRandomInt;

  return ({ packType }) => {
    const normalizedPackType = cleanText(packType, 32).toLowerCase();
    const packPolicy = policy.packs[normalizedPackType];
    if (!packPolicy) throw domainError('cardverse_pack_type_invalid');

    const items = Array.from({ length: 5 }, () => ({
      canonicalInterestId: drawWeighted(packPolicy.interestWeights, randomInt),
      finishId: drawWeighted(packPolicy.finishWeights, randomInt),
      editionId: packPolicy.editionId,
      ownershipKind: 'stackable',
      quantity: 1,
      artSystemVersion: CARDVERSE_ART_SYSTEM_VERSION,
      soulbound: false,
    }));

    if (packPolicy.guarantee.type === 'at_least_one_finish') {
      const minimum = packPolicy.guarantee.minimumFinish;
      if (!items.some((item) => finishMeetsMinimum(item.finishId, minimum))) {
        const guaranteedWeights = eligibleGuaranteedFinishes(
          packPolicy.finishWeights,
          minimum,
        );
        items[items.length - 1] = {
          ...items[items.length - 1],
          finishId: drawWeighted(guaranteedWeights, randomInt),
        };
      }
    }

    return {
      policyVersion: policy.version,
      items,
    };
  };
}


export function createCardverseSingleCardRoller(options = {}) {
  const policy = options.policy ?? loadConfiguredCardversePackPolicyV1();
  const randomInt = options.randomInt ?? cryptoRandomInt;

  return () => {
    const packPolicy = policy.packs.standard;
    if (!packPolicy) throw domainError('cardverse_pack_type_invalid');
    return {
      policyVersion: policy.version,
      item: {
        canonicalInterestId: drawWeighted(
          packPolicy.interestWeights,
          randomInt,
        ),
        finishId: drawWeighted(packPolicy.finishWeights, randomInt),
        editionId: packPolicy.editionId,
        ownershipKind: 'stackable',
        quantity: 1,
        artSystemVersion: CARDVERSE_ART_SYSTEM_VERSION,
        soulbound: false,
      },
    };
  };
}

import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  CARDVERSE_PACK_CATALOG_V1,
  CARDVERSE_PACK_CATALOG_VERSION,
} from '../../api/_cardverse/catalog_v1.js';
import {
  createCardversePackRoller,
  loadConfiguredCardversePackPolicyV1,
  parseCardversePackPolicyV1,
} from '../../api/_cardverse/pack_policy_v1.js';

const recipeSource = await readFile(
  new URL('../../mobile/lib/core/card_visual_recipe.dart', import.meta.url),
  'utf8',
);

function dartList(name, nextMarker) {
  const start = recipeSource.indexOf('static const ' + name);
  const end = recipeSource.indexOf(nextMarker, start);
  assert.ok(start >= 0 && end > start, 'missing Dart list: ' + name);
  return [...recipeSource.slice(start, end).matchAll(/'([a-z0-9_.-]+)'/g)]
    .map((match) => match[1]);
}

const proof = dartList('proofInterestIds', 'static const expandedProofInterestIds');
const expandedOnly = dartList('expandedProofInterestIds', 'static CardVisualRecipe? resolve');
const approved = [...new Set([...proof, ...expandedOnly])].sort();
const serverCatalog = [...CARDVERSE_PACK_CATALOG_V1].sort();

assert.equal(CARDVERSE_PACK_CATALOG_VERSION, 1);
assert.equal(serverCatalog.length, 50);
assert.deepEqual(serverCatalog, approved);

const configured = {
  version: 1,
  catalogVersion: 1,
  packs: {
    standard: {
      editionId: 'core_set_1',
      interestWeights: {
        'sports.badminton': 3,
        'food.coffee': 1,
      },
      finishWeights: {
        normal: 80,
        foil: 15,
        holo: 5,
      },
      guarantee: { type: 'none' },
    },
    discovery: {
      editionId: 'discovery',
      interestWeights: {
        'technology.ai': 1,
        'travel.japan': 1,
      },
      finishWeights: {
        normal: 90,
        prism: 10,
      },
      guarantee: {
        type: 'at_least_one_finish',
        minimumFinish: 'prism',
      },
    },
  },
};

const policy = parseCardversePackPolicyV1(configured);
assert.equal(policy.version, 1);
assert.equal(policy.packs.standard.editionId, 'core_set_1');
assert.equal(policy.packs.discovery.guarantee.minimumFinish, 'prism');

{
  const draws = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  const roller = createCardversePackRoller({
    policy,
    randomInt(max) {
      const next = draws.shift() ?? 0;
      assert.ok(next < max);
      return next;
    },
  });
  const result = roller({ packType: 'standard' });
  assert.equal(result.policyVersion, 1);
  assert.equal(result.items.length, 5);
  assert.equal(result.items.every((item) => item.editionId === 'core_set_1'), true);
  assert.equal(result.items.every((item) => item.ownershipKind === 'stackable'), true);
}

{
  const draws = [
    0, 0,
    0, 0,
    0, 0,
    0, 0,
    0, 0,
    0,
  ];
  const roller = createCardversePackRoller({
    policy,
    randomInt(max) {
      const next = draws.shift() ?? 0;
      assert.ok(next < max);
      return next;
    },
  });
  const result = roller({ packType: 'discovery' });
  assert.equal(result.items.length, 5);
  assert.equal(result.items.slice(0, 4).every((item) => item.finishId === 'normal'), true);
  assert.equal(result.items[4].finishId, 'prism');
}

assert.throws(
  () => parseCardversePackPolicyV1({
    ...configured,
    packs: {
      ...configured.packs,
      standard: {
        ...configured.packs.standard,
        interestWeights: { 'not.in.catalog': 1 },
      },
    },
  }),
  /cardverse_pack_interest_weights_invalid/,
);

assert.throws(
  () => parseCardversePackPolicyV1({
    ...configured,
    packs: {
      ...configured.packs,
      standard: {
        ...configured.packs.standard,
        finishWeights: { normal: 1, mythic: 1 },
      },
    },
  }),
  /cardverse_pack_finish_weights_invalid/,
);

{
  const before = process.env.CARDVERSE_PACK_POLICY_V1;
  delete process.env.CARDVERSE_PACK_POLICY_V1;
  assert.throws(
    () => loadConfiguredCardversePackPolicyV1(),
    /cardverse_pack_policy_not_configured/,
  );
  if (before == null) {
    delete process.env.CARDVERSE_PACK_POLICY_V1;
  } else {
    process.env.CARDVERSE_PACK_POLICY_V1 = before;
  }
}

const endpoint = await import('../../api/v1/cardverse/packs/open.js');
assert.equal(typeof endpoint.default, 'function');

console.log('✓ Cardverse server catalog/policy contracts passed');

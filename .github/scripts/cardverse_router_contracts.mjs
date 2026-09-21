import assert from 'node:assert/strict';
import { readdir, readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const apiRoot = path.join(root, 'api');

async function jsFiles(dir) {
  const out = [];
  for (const name of await readdir(dir)) {
    const full = path.join(dir, name);
    const info = await stat(full);
    if (info.isDirectory()) out.push(...await jsFiles(full));
    else if (name.endsWith('.js')) out.push(path.relative(root, full).replaceAll('\\', '/'));
  }
  return out.sort();
}

const files = await jsFiles(apiRoot);
assert.ok(files.length <= 12, 'Hobby function budget exceeded: ' + files.length);
assert.equal(files.includes('api/v1/cardverse-router.js'), true);
assert.equal(files.some((p) => p.startsWith('api/_cardverse/')), false);
assert.equal(files.some((p) => p.startsWith('api/v1/cardverse/')), false);

const expected = [
  'account/delete',
  'auth/challenge',
  'auth/link',
  'auth/logout-all',
  'auth/logout',
  'auth/provider',
  'auth/unlink',
  'inventory',
  'rewards/daily-login',
  'draws/redeem',
  'packs/open',
  'proofs/redeem',
  'quests/claim',
  'readiness',
];

const config = JSON.parse(await readFile(path.join(root, 'vercel.json'), 'utf8'));
const rewrites = config.rewrites || [];
for (const route of expected) {
  const source = '/api/v1/cardverse/' + route;
  const destination = '/api/v1/cardverse-router?cardverse_route=' + route;
  assert.equal(
    rewrites.some((r) => r.source === source && r.destination === destination),
    true,
    'missing Cardverse rewrite: ' + route,
  );
}

const router = await import('../../api/v1/cardverse-router.js');
assert.deepEqual(Object.keys(router.cardverseRouterRoutes).sort(), expected.slice().sort());

console.log('✓ Cardverse router/function-budget contracts passed (' + files.length + ' functions)');

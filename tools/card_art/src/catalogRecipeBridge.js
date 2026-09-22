// Rights-first runtime-catalog -> card-art recipe bridge.
//
// Pure local/static transformation:
// - reads bundled Dart catalog sources
// - mirrors the runtime card-policy resolver
// - derives long-tail recipes from inheritance defaults
// - lets reviewed manual recipes override derived recipes only AFTER rights pass
//
// This module makes no network/API calls and generates no images.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CARD_ART_ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(CARD_ART_ROOT, '../..');
const CORE_ROOT = path.join(REPO_ROOT, 'mobile', 'lib', 'core');

const read = p => fs.readFileSync(p, 'utf-8');
const readJson = p => JSON.parse(read(p));
const readJsonl = p => read(p).split('\n').map(x => x.trim()).filter(Boolean).map(JSON.parse);

const LEGACY_CANONICAL_CONCEPTS = new Set([
  'gaming|sandbox_games',
  'music|reggae',
  'music|jazz',
  'music|world_music',
  'learning|science_fiction_books',
  'learning|business_books',
]);

const FOLDS = {
  'á':'a','à':'a','â':'a','ä':'a','ã':'a','å':'a',
  'é':'e','è':'e','ê':'e','ë':'e',
  'í':'i','ì':'i','î':'i','ï':'i',
  'ó':'o','ò':'o','ô':'o','ö':'o','õ':'o',
  'ú':'u','ù':'u','û':'u','ü':'u',
  'ç':'c','ñ':'n','ý':'y','ÿ':'y',
};

function slug(value) {
  let text = String(value).toLowerCase().replaceAll('&', ' and ');
  for (const [from, to] of Object.entries(FOLDS)) text = text.split(from).join(to);
  return text
    .replace(/[’'"\`´]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
}

function splitAliases(value) {
  return String(value || '').split(';').map(x => x.trim()).filter(Boolean);
}

function parseCatalog() {
  const parts = fs.readdirSync(CORE_ROOT)
    .filter(name => /^interest_catalog_part\d+\.dart$/.test(name))
    .sort((a, b) => {
      const ai = Number(a.match(/\d+/)[0]);
      const bi = Number(b.match(/\d+/)[0]);
      return ai - bi;
    });

  const items = [];
  for (const part of parts) {
    const source = read(path.join(CORE_ROOT, part));

    for (const match of source.matchAll(/parseInterestCatalogRows\(r'''([\s\S]*?)'''\)/g)) {
      for (const rawLine of match[1].split(/\r?\n/)) {
        const line = rawLine.trim();
        if (!line || line.startsWith('#')) continue;
        const fields = line.split('|');
        if (fields.length !== 8) throw new Error(`Invalid catalog row in ${part}: ${line}`);
        items.push({
          id: fields[0],
          category: fields[1],
          cluster: fields[2],
          rank: Number(fields[3]),
          title: fields[4],
        });
      }
    }

    const familyRe = /parseInterestFamily\(\s*idPrefix:\s*'([^']+)'\s*,\s*category:\s*'([^']+)'\s*,\s*cluster:\s*'([^']+)'\s*,\s*rankStart:\s*(\d+)\s*,\s*raw:\s*r'''([\s\S]*?)'''\s*,?\s*\)/g;
    for (const match of source.matchAll(familyRe)) {
      const [, idPrefix, category, cluster, rankStartText, rawBlock] = match;
      const rankStart = Number(rankStartText);
      let offset = 0;
      for (const rawLine of rawBlock.split(/\r?\n/)) {
        const line = rawLine.trim();
        if (!line || line.startsWith('#')) continue;
        const fields = line.split('|').map(x => x.trim());
        if (!fields.length || fields.length > 6 || !fields[0]) {
          throw new Error(`Invalid family row in ${part}: ${line}`);
        }
        const title = fields[0];
        const itemSlug = slug(title);
        if (!itemSlug) throw new Error(`Empty family slug in ${part}: ${title}`);
        const rank = rankStart + offset;
        offset += 1;
        if (LEGACY_CANONICAL_CONCEPTS.has(`${category}|${itemSlug}`)) continue;
        items.push({
          id: `${idPrefix}.${itemSlug}`,
          category,
          cluster,
          rank,
          title,
        });
      }
    }
  }

  const ids = new Set();
  for (const item of items) {
    if (!item.id || !item.category || !item.title || !Number.isFinite(item.rank)) {
      throw new Error(`Malformed catalog item: ${JSON.stringify(item)}`);
    }
    if (ids.has(item.id)) throw new Error(`Duplicate canonical interest id: ${item.id}`);
    ids.add(item.id);
  }
  return items;
}

function parseConstStringSet(source, name) {
  const re = new RegExp(`static const Set<String> ${name} = \\\{([\\s\\S]*?)\\\};`);
  const match = source.match(re);
  if (!match) throw new Error(`Could not parse resolver set ${name}`);
  return new Set([...match[1].matchAll(/'([^']+)'/g)].map(m => m[1]));
}

function matchingParen(source, openIndex) {
  let depth = 0;
  let quote = null;
  let escaped = false;
  for (let i = openIndex; i < source.length; i++) {
    const ch = source[i];
    if (quote) {
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === quote) quote = null;
      continue;
    }
    if (ch === "'" || ch === '"') {
      quote = ch;
      continue;
    }
    if (ch === '(') depth += 1;
    else if (ch === ')') {
      depth -= 1;
      if (depth === 0) return i;
    }
  }
  throw new Error('Unbalanced parentheses while parsing entity metadata');
}

function parseExplicitCardMetadata() {
  const source = read(path.join(CORE_ROOT, 'interest_entity_metadata.dart'));
  const output = new Map();
  const entryRe = /'([^']+)'\s*:\s*InterestEntityMetadata\(/g;
  for (const match of source.matchAll(entryRe)) {
    const id = match[1];
    const open = source.indexOf('(', match.index + match[0].length - 1);
    const close = matchingParen(source, open);
    const body = source.slice(open + 1, close);
    const cardStart = body.indexOf('card: CardProfile(');
    if (cardStart < 0) continue;
    const cardOpen = body.indexOf('(', cardStart);
    const cardClose = matchingParen(body, cardOpen);
    const card = body.slice(cardOpen + 1, cardClose);
    const collectible = card.match(/collectible:\s*(true|false)/)?.[1] === 'true';
    const artPolicy = card.match(/artPolicy:\s*CardArtPolicy\.(\w+)/)?.[1];
    if (!artPolicy) throw new Error(`Missing artPolicy for explicit card metadata: ${id}`);
    output.set(id, { collectible, artPolicy });
  }
  return output;
}

function loadRightsPolicy() {
  const source = read(path.join(CORE_ROOT, 'interest_card_policy_resolver.dart'));
  return {
    licensedClusters: parseConstStringSet(source, '_licensedClusters'),
    licensedIds: parseConstStringSet(source, '_licensedIds'),
    abstractOnlyIds: parseConstStringSet(source, '_abstractOnlyIds'),
    explicitCards: parseExplicitCardMetadata(),
  };
}

function decidePolicy(item, rights) {
  if (rights.licensedIds.has(item.id) || rights.licensedClusters.has(item.cluster)) {
    return { art_policy:'licensedOnly', baseline_art_eligible:false, reason:'licensed_runtime_policy' };
  }
  if (rights.abstractOnlyIds.has(item.id)) {
    return { art_policy:'abstractOnly', baseline_art_eligible:true, reason:'abstract_only_runtime_policy' };
  }
  const explicit = rights.explicitCards.get(item.id);
  if (explicit) {
    if (!explicit.collectible || explicit.artPolicy === 'notCollectible') {
      return { art_policy:'notCollectible', baseline_art_eligible:false, reason:'explicit_not_collectible' };
    }
    if (explicit.artPolicy === 'licensedOnly') {
      return { art_policy:'licensedOnly', baseline_art_eligible:false, reason:'explicit_licensed_only' };
    }
    if (!['originalGeneric','abstractOnly'].includes(explicit.artPolicy)) {
      throw new Error(`Unknown explicit card art policy "${explicit.artPolicy}" for ${item.id}`);
    }
    return {
      art_policy: explicit.artPolicy,
      baseline_art_eligible: true,
      reason:'explicit_metadata',
    };
  }
  return { art_policy:'originalGeneric', baseline_art_eligible:true, reason:'generic_concept' };
}

function renderTemplate(value, item) {
  return String(value).replaceAll('${title}', item.title);
}

function matchesRule(item, match) {
  if (match.category && item.category !== match.category) return false;
  if (match.cluster && item.cluster !== match.cluster) return false;
  if (match.cluster_prefix && !(item.cluster === match.cluster_prefix || item.cluster.startsWith(`${match.cluster_prefix}/`))) return false;
  if (match.cluster_contains && !item.cluster.includes(match.cluster_contains)) return false;
  if (match.id && item.id !== match.id) return false;
  if (match.id_in && !match.id_in.includes(item.id)) return false;
  if (match.id_prefix && !item.id.startsWith(match.id_prefix)) return false;
  if (match.id_contains && !item.id.includes(match.id_contains)) return false;
  return true;
}

function deriveRecipe(item, defaults, policy) {
  const base = defaults.category_defaults[item.category];
  if (!base) throw new Error(`No card-art category default for runtime category "${item.category}" (${item.id})`);
  let profile = JSON.parse(JSON.stringify(base));
  for (const rule of defaults.profile_rules || []) {
    if (matchesRule(item, rule.match || {})) profile = { ...profile, ...(rule.patch || {}) };
  }

  const rankMax = Number(defaults.tiering?.common_rank_max ?? 1200);
  const defaultTier = defaults.tiering?.default_tier || 'long_tail';
  const configuredHardCase =
    (defaults.hard_case_ids || []).includes(item.id) ||
    (defaults.hard_case_categories || []).includes(item.category);
  const hardCase = policy.art_policy === 'abstractOnly' || configuredHardCase;
  const avoid = (profile.avoid || []).map(x => renderTemplate(x, item));
  if (policy.art_policy === 'abstractOnly') {
    avoid.push(
      'official logos, wordmarks, mascots, badges, or certification seals',
      'official-looking brand trade dress or endorsement cues',
      'a composition whose recognition depends on copying a protected mark',
    );
  }
  return {
    id: item.id,
    title: item.title,
    category: profile.art_category,
    subcategory: null,
    archetype: profile.archetype,
    ...(profile.visual_variant ? {visual_variant: profile.visual_variant} : {}),
    tier: item.rank <= rankMax ? 'common' : defaultTier,
    difficulty: hardCase ? 'hard_case' : 'normal',
    human_review_required: hardCase,
    subject: renderTemplate(profile.subject_template, item),
    environment: renderTemplate(profile.environment_template, item),
    emotion: (profile.emotion || []).map(x => renderTemplate(x, item)),
    recognition_anchors: (profile.recognition_anchors || []).map(x => renderTemplate(x, item)),
    must_include: (profile.must_include || []).map(x => renderTemplate(x, item)),
    avoid,
    notes: `Derived from runtime catalog ${item.id} via catalog_recipe_defaults_v1; art policy=${policy.art_policy}.`,
  };
}

function validateManualRecipes(catalogById) {
  const catalogDir = path.join(CARD_ART_ROOT, 'catalog');
  const manual = readJsonl(path.join(catalogDir, 'hobby_recipes_v1.jsonl'));
  const mapping = readJson(path.join(catalogDir, 'manual_recipe_canonical_map_v1.json')).manual_to_canonical || {};

  const manualByCanonical = new Map();
  const seenManualIds = new Set();
  for (const recipe of manual) {
    if (seenManualIds.has(recipe.id)) throw new Error(`Duplicate manual recipe id: ${recipe.id}`);
    seenManualIds.add(recipe.id);
    const canonicalId = mapping[recipe.id];
    if (!canonicalId) throw new Error(`Manual recipe "${recipe.id}" has no canonical mapping`);
    if (!catalogById.has(canonicalId)) throw new Error(`Manual recipe "${recipe.id}" maps to missing canonical "${canonicalId}"`);
    if (manualByCanonical.has(canonicalId)) throw new Error(`Multiple manual recipes map to ${canonicalId}`);
    manualByCanonical.set(canonicalId, { ...recipe, source_recipe_id: recipe.id });
  }

  for (const mappedId of Object.keys(mapping)) {
    if (!seenManualIds.has(mappedId)) throw new Error(`Canonical map contains unknown manual recipe id: ${mappedId}`);
  }
  return manualByCanonical;
}

export function buildCatalogRecipeBridge() {
  const catalog = parseCatalog();
  const catalogById = new Map(catalog.map(item => [item.id, item]));
  const rights = loadRightsPolicy();
  const defaults = readJson(path.join(CARD_ART_ROOT, 'specs', 'catalog_recipe_defaults_v1.json'));
  const manualByCanonical = validateManualRecipes(catalogById);

  const eligible = [];
  const blocked = [];
  const counts = {
    total: catalog.length,
    originalGeneric: 0,
    abstractOnly: 0,
    licensedOnly: 0,
    notCollectible: 0,
    baselineEligible: 0,
    blocked: 0,
    manualEligible: 0,
    derivedEligible: 0,
    manualBlocked: 0,
  };

  for (const item of catalog) {
    const policy = decidePolicy(item, rights);
    counts[policy.art_policy] = (counts[policy.art_policy] || 0) + 1;
    const manual = manualByCanonical.get(item.id);

    if (!policy.baseline_art_eligible) {
      counts.blocked += 1;
      if (manual) counts.manualBlocked += 1;
      blocked.push({
        canonical_interest_id:item.id,
        title:item.title,
        runtime_category:item.category,
        runtime_cluster:item.cluster,
        rank:item.rank,
        art_policy:policy.art_policy,
        reason:policy.reason,
        manual_recipe_id:manual?.source_recipe_id || null,
      });
      continue;
    }

    counts.baselineEligible += 1;
    let recipe;
    let recipeSource;
    let sourceRecipeId = null;
    if (manual) {
      counts.manualEligible += 1;
      recipeSource = 'manual';
      sourceRecipeId = manual.source_recipe_id;
      recipe = { ...manual, id:item.id, title:item.title };
      delete recipe.source_recipe_id;
    } else {
      counts.derivedEligible += 1;
      recipeSource = 'derived';
      recipe = deriveRecipe(item, defaults, policy);
    }

    eligible.push({
      canonical_interest_id:item.id,
      runtime_category:item.category,
      runtime_cluster:item.cluster,
      rank:item.rank,
      art_policy:policy.art_policy,
      policy_reason:policy.reason,
      recipe_source:recipeSource,
      source_recipe_id:sourceRecipeId,
      recipe,
    });
  }

  if (eligible.length + blocked.length !== catalog.length) {
    throw new Error('Bridge partition does not cover the full catalog');
  }
  if (counts.baselineEligible !== eligible.length || counts.blocked !== blocked.length) {
    throw new Error('Bridge count invariant failed');
  }

  return { catalog, eligible, blocked, counts };
}

export function writeCatalogRecipeBridge({ outDir = path.join(CARD_ART_ROOT, 'generated') } = {}) {
  const result = buildCatalogRecipeBridge();
  fs.mkdirSync(outDir, { recursive:true });
  fs.writeFileSync(
    path.join(outDir, 'catalog_recipe_manifest_v1.jsonl'),
    result.eligible.map(x => JSON.stringify(x)).join('\n') + '\n',
  );
  fs.writeFileSync(
    path.join(outDir, 'catalog_recipe_blocked_v1.jsonl'),
    result.blocked.map(x => JSON.stringify(x)).join('\n') + '\n',
  );
  fs.writeFileSync(
    path.join(outDir, 'catalog_recipe_summary_v1.json'),
    JSON.stringify(result.counts, null, 2) + '\n',
  );
  return result;
}

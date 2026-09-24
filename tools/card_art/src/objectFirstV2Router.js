// Pure, zero-I/O routing logic for the candidate V2 object-first
// architecture. Given one eligible catalog row (from
// catalogRecipeBridge.js's `eligible` array, read-only, never mutated)
// plus the V2 rule specs, decides:
//   - protagonist_type
//   - object_first_status
//   - structural_containment_rule_id
//   - composition_archetype / palette_lighting_route / effect_level
//     (deterministic, hash-based, reproducible from the canonical id)
//   - physical_logic_risk / text_risk / brand_risk flags
//
// This module makes no network/file-write calls and generates no images
// or prompts - it only decides WHAT each card should route to. Assembling
// an actual compiled prompt string from these routing decisions is a
// separate, not-yet-built step (see global_style_v2_object_first.json's
// "not_yet_built" field).

// Same FNV-1a stable-hash + modulo technique as src/diversityLayer.js's
// stableHash()/uniformPick()/weightedPick(), reimplemented locally so V2
// has zero code dependency on V1's diversity system.
function stableHash(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}
function uniformPick(id, dimensionName, valuesObject) {
  const keys = Object.keys(valuesObject);
  const index = stableHash(`${id}::v2::${dimensionName}`) % keys.length;
  return keys[index];
}
function weightedPick(id, dimensionName, weights) {
  const entries = Object.entries(weights);
  const total = entries.reduce((sum, [, w]) => sum + w, 0);
  const roll = stableHash(`${id}::v2::${dimensionName}`) % total;
  let cursor = 0;
  for (const [key, weight] of entries) {
    cursor += weight;
    if (roll < cursor) return key;
  }
  return entries[entries.length - 1][0];
}

// Archetype-level risk sets. Kept local to the router (not in the JSON
// spec) since they are structural classification logic, not rule data.
const PHYSICAL_LOGIC_RISK_ARCHETYPES = new Set([
  'creative_studio', 'drink_ritual', 'performance', 'home_lifestyle',
  'fitness_training', 'calm_wellness', 'wellness_experience', 'music_listening',
]);
const TEXT_RISK_ARCHETYPES = new Set([
  'reading_world', 'learning_exploration', 'strategy_table', 'digital_play',
  'creator_workflow', 'campaign_planning', 'legal_practice', 'story_culture',
  'professional_world', 'campus_activity', 'shared_workspace',
]);
const BRAND_RISK_ARCHETYPES = new Set([
  'journey_machine', 'aviation_world', 'fitness_training', 'water_outdoors',
  'outdoor_motion', 'solo_action', 'screenless_pc_play', 'digital_play',
  'physical_prototype', 'tech_workspace', 'vertical_adventure',
]);

function matchesIdPrefixOverride(id, override) {
  return Boolean(override.match?.id_prefix) && id.startsWith(override.match.id_prefix);
}

function findKeywordMatch(id, title, rules) {
  const haystack = `${id} ${title}`.toLowerCase();
  for (const pattern of rules.human_exception_keyword_scan.patterns) {
    if (haystack.includes(pattern)) return pattern;
  }
  return null;
}

/**
 * @param {{canonical_interest_id:string, title:string, runtime_category:string, runtime_cluster:string, archetype:string}} row
 * @param {{rules:object, containment:object, composition:object, quarantinedIds:Set<string>}} ctx
 */
export function routeHobbyV2(row, ctx) {
  const { canonical_interest_id: id, title, runtime_category, runtime_cluster, archetype } = row;
  const { rules, quarantinedIds } = ctx;

  const base = {
    canonical_interest_id: id,
    title,
    runtime_category,
    runtime_cluster,
    archetype,
  };

  if (quarantinedIds.has(id)) {
    return {
      ...base,
      protagonist_type: null,
      object_first_status: 'excluded_quarantined',
      structural_containment_rule_id: null,
      composition_archetype: null,
      palette_lighting_route: null,
      effect_level: null,
      physical_logic_risk: false,
      text_risk: false,
      brand_risk: false,
      human_exception_keyword_matched: null,
      routing_note: 'Quarantined per generation_guardrails_v1.json; excluded from all V2 generation and distributions. Quarantine file not modified.',
    };
  }

  const archetypeDefault = rules.archetype_defaults[archetype];
  if (!archetypeDefault) {
    throw new Error(`No V2 archetype default defined for archetype "${archetype}" (id=${id}). Every archetype in specs/archetypes_v1.json must have an entry in object_first_rules_v2.json's archetype_defaults.`);
  }

  let protagonist_type = archetypeDefault.protagonist_type;
  let object_first_status = archetypeDefault.object_first_status;
  let structural_containment_rule_id = archetypeDefault.structural_containment_rule_id;
  let routing_note = archetypeDefault.rationale;

  const idOverride = rules.id_prefix_overrides.find(o => matchesIdPrefixOverride(id, o));
  if (idOverride) {
    protagonist_type = idOverride.protagonist_type;
    object_first_status = idOverride.object_first_status;
    structural_containment_rule_id = idOverride.structural_containment_rule_id;
    routing_note = `id_prefix_override(${idOverride.match.id_prefix}): ${idOverride.rationale}`;
  }

  const keywordMatch = findKeywordMatch(id, title, rules);
  let human_exception_keyword_matched = null;
  if (keywordMatch) {
    const irreducible = rules.human_exception_keyword_scan.irreducible_human_ids.includes(id);
    if (irreducible) {
      protagonist_type = 'unresolved';
      object_first_status = 'human_exception_candidate';
      structural_containment_rule_id = null;
      routing_note = `human_exception_keyword_scan matched "${keywordMatch}" and id is explicitly listed in irreducible_human_ids - accepted as a true human exception.`;
    } else {
      protagonist_type = 'object';
      object_first_status = 'containment_required';
      structural_containment_rule_id = 'private_empty_venue';
      routing_note = `human_exception_keyword_scan matched "${keywordMatch}" but was CHALLENGED and downgraded: ${rules.human_exception_keyword_scan.challenge_alternatives[keywordMatch]}`;
    }
    human_exception_keyword_matched = keywordMatch;
  }

  const composition_archetype = uniformPick(id, 'composition_archetype', ctx.composition.dimensions.composition_archetype.values);
  const palette_lighting_route = uniformPick(id, 'palette_lighting_route', ctx.composition.dimensions.palette_lighting_route.values);
  const effect_level = weightedPick(id, 'effect_level', ctx.composition.dimensions.effect_level.weights);

  return {
    ...base,
    protagonist_type,
    object_first_status,
    structural_containment_rule_id,
    composition_archetype,
    palette_lighting_route,
    effect_level,
    physical_logic_risk: PHYSICAL_LOGIC_RISK_ARCHETYPES.has(archetype),
    text_risk: TEXT_RISK_ARCHETYPES.has(archetype),
    brand_risk: BRAND_RISK_ARCHETYPES.has(archetype),
    human_exception_keyword_matched,
    routing_note,
  };
}

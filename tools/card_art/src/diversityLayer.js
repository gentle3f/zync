// Deterministic presentation-variety layer for D4. Does not touch D4's
// rendering language (globalStyle.prompt) - it only adds a separate,
// additive guidance section computed from a stable hash of the hobby
// recipe id, so the same id always yields the same diversity profile
// across regenerations.
//
// Purpose: prevent catalog-wide convergence on the same young-female /
// dark-straight-hair / golden-hour / medium-shot / smiling / sparkly
// default across thousands of cards, without ever overriding
// hobby-specific semantic requirements.

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
  const index = stableHash(`${id}::diversity::${dimensionName}`) % keys.length;
  return keys[index];
}

// weights: plain object of {key: integerWeight}. Deterministically buckets
// via hash mod totalWeight, so the long-run distribution across the
// catalog approximates the given ratios (e.g. 40/35/25) instead of a
// uniform split across N values.
function weightedPick(id, dimensionName, weights) {
  const entries = Object.entries(weights);
  const total = entries.reduce((sum, [, w]) => sum + w, 0);
  const roll = stableHash(`${id}::diversity::${dimensionName}`) % total;
  let cursor = 0;
  for (const [key, weight] of entries) {
    cursor += weight;
    if (roll < cursor) return key;
  }
  return entries[entries.length - 1][0];
}

function pick(id, dimensionName, dimension) {
  if (dimension.weights) return weightedPick(id, dimensionName, dimension.weights);
  return uniformPick(id, dimensionName, dimension.values);
}

// diversityLock: optional per-hobby object (from hobby_overrides_v1.json's
// "diversity_lock" field) that pins specific dimensions when a hobby's own
// semantics require it, e.g. { gender_presentation: "mixed_group" }. Any
// dimension not present in the lock is still chosen deterministically
// from id.
export function computeDiversityProfile(id, diversityProfiles, diversityLock = null) {
  const dims = diversityProfiles.dimensions;
  const profile = {};
  for (const dimensionName of Object.keys(dims)) {
    const locked = diversityLock?.[dimensionName];
    profile[dimensionName] = locked && dims[dimensionName].values[locked]
      ? locked
      : pick(id, dimensionName, dims[dimensionName]);
  }
  return profile;
}

// object_led gets a dedicated, mechanically stronger multi-sentence
// directive instead of the one-line phrase used for other dimension
// values - a single sentence proved insufficient (outdoors.fishing in the
// 8-card diversity test still let the human dominate the frame).
const OBJECT_LED_DIRECTIVE =
  'For this card, the hobby-defining object, material, tool, dish, device, catch, or creation moment must occupy the largest ' +
  'or strongest visual emphasis in the frame. Any human figure present is a supporting actor only: keep their face and body ' +
  'secondary in scale, do not frame this as a character portrait, and do not let a human face be the primary hero of the ' +
  'composition. Camera attention, foreground scale, and lighting should all favor the object or action rather than the ' +
  'person. If a human is present, show them actively interacting with the object (hands, tools, gesture, or gaze directed ' +
  'at it) rather than posed for a portrait. This does not have to be a literal close-up - a wider shot where the object ' +
  'still visually dominates the composition is equally acceptable.';

export function buildDiversitySection(profile, diversityProfiles) {
  const dims = diversityProfiles.dimensions;
  const phrases = Object.keys(profile).map(dimensionName => {
    const value = profile[dimensionName];
    if (dimensionName === 'gender_presentation' && value === 'object_led') {
      return OBJECT_LED_DIRECTIVE;
    }
    return dims[dimensionName].values[value];
  });
  return (
    `Vary this specific card's presentation within the house style below, without changing the ` +
    `rendering language itself: ${phrases.join(' ')} Choose an emotional expression that matches ` +
    `the emotional mode above rather than defaulting to a smiling face if the mode calls for ` +
    `something else. Effects-intensity guidance above governs sparkle/glow/particle usage only and ` +
    `must never be used to omit a semantically required object, action, or recognition cue. If any of ` +
    `this presentation guidance ever conflicts with the hobby-specific recognition or must-include ` +
    `requirements elsewhere in this prompt, the hobby-specific requirements always take priority.`
  );
}

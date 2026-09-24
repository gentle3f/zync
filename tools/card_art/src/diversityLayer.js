// Deterministic presentation-variety layer for D4. Does not touch D4's
// rendering language (globalStyle.prompt) - it only adds a separate,
// additive guidance section computed from a stable hash of the hobby
// recipe id, so the same id always yields the same diversity profile
// across regenerations.
//
// Purpose: prevent catalog-wide convergence on the same young-female /
// golden-hour / medium-shot / smiling / sparkly default across thousands
// of cards, without ever overriding hobby-specific semantic requirements.

function stableHash(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function pick(id, dimensionName, valuesObject) {
  const keys = Object.keys(valuesObject);
  const index = stableHash(`${id}::diversity::${dimensionName}`) % keys.length;
  return keys[index];
}

// diversityLock: optional per-hobby object (from hobby_overrides_v1.json's
// "diversity_lock" field) that pins specific dimensions when a hobby's own
// semantics require it, e.g. { protagonist: "mixed_group" }. Any dimension
// not present in the lock is still chosen deterministically from id.
export function computeDiversityProfile(id, diversityProfiles, diversityLock = null) {
  const dims = diversityProfiles.dimensions;
  const profile = {};
  for (const dimensionName of Object.keys(dims)) {
    const locked = diversityLock?.[dimensionName];
    profile[dimensionName] = locked && dims[dimensionName].values[locked]
      ? locked
      : pick(id, dimensionName, dims[dimensionName].values);
  }
  return profile;
}

export function buildDiversitySection(profile, diversityProfiles) {
  const dims = diversityProfiles.dimensions;
  const phrases = Object.keys(profile).map(
    dimensionName => dims[dimensionName].values[profile[dimensionName]],
  );
  return (
    `Vary this specific card's presentation within the house style below, without changing the ` +
    `rendering language itself: ${phrases.join(' ')} Choose an emotional expression that matches ` +
    `the emotional mode above rather than defaulting to a smiling face if the mode calls for ` +
    `something else. If any of this presentation guidance ever conflicts with the hobby-specific ` +
    `recognition or must-include requirements elsewhere in this prompt, the hobby-specific ` +
    `requirements always take priority.`
  );
}

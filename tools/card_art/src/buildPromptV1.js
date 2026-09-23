// V1 prompt compiler. Pure compilation only: no fal.ai calls.
function list(items) {
  return items && items.length ? items.join(', ') : null;
}
function stableIndex(id, n) {
  let h = 2166136261;
  for (let i = 0; i < id.length; i++) {
    h ^= id.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return (h >>> 0) % n;
}
function applyOverride(base, override) {
  if (!override) return {...base};
  const out = {...base};
  for (const k of ['subject','environment','composition','camera','lighting','palette','visual_variant']) {
    if (override[k] != null) out[k] = override[k];
  }
  out.emotion = [...(base.emotion || []), ...(override.emotion_add || [])];
  out.recognition_anchors = [...(base.recognition_anchors || []), ...(override.recognition_anchors_add || [])];
  out.must_include = [...(base.must_include || []), ...(override.must_include_add || [])];
  out.avoid = [...(base.avoid || []), ...(override.avoid_add || []), ...(override.override_avoid || [])];
  return out;
}
export function compileHobbyPrompt({ hobby, globalStyle, archetypes, variants, categories, subcategories, override, flagshipOverride }) {
  let effective = applyOverride(hobby, override);
  effective = applyOverride(effective, flagshipOverride);
  const archetype = archetypes.archetypes[effective.archetype];
  if (!archetype) throw new Error(`Unknown archetype "${effective.archetype}" for hobby "${effective.id}"`);
  const category = categories.categories[effective.category];
  if (!category) throw new Error(`Unknown category "${effective.category}" for hobby "${effective.id}"`);
  const subcategory = effective.subcategory ? subcategories.subcategories[effective.subcategory] : null;
  if (effective.subcategory && !subcategory) throw new Error(`Unknown subcategory "${effective.subcategory}" for hobby "${effective.id}"`);
  const pool = variants.archetypes[effective.archetype] || [];
  if (!pool.length) throw new Error(`No visual variants for archetype "${effective.archetype}"`);
  const genericPool = pool.filter(v => v.generic_eligible !== false);
  if (!genericPool.length) {
    throw new Error(`No generic-eligible visual variants for archetype "${effective.archetype}"`);
  }
  const variant = effective.visual_variant
    ? pool.find(v => v.id === effective.visual_variant)
    : genericPool[stableIndex(effective.id, genericPool.length)];
  if (!variant) throw new Error(`Unknown visual_variant "${effective.visual_variant}" for hobby "${effective.id}"`);

  // Keep internal compiler metadata out of the image prompt. Previous
  // LABEL (identifier): formatting caused models to echo archetype/variant ids
  // as visible captions (for example HEAT ROOM / IMMERSION_RITUAL).
  const sections = [];
  sections.push(globalStyle.prompt);
  sections.push(
    `Use this overall composition approach: ${archetype.composition} ${archetype.camera} ` +
    `The emotional feeling should be ${list(archetype.feeling)}. ` +
    `Make the hobby immediately recognizable through ${archetype.recognition}.`
  );
  sections.push(
    `Compose the specific scene this way: ${variant.composition} ${variant.camera} ` +
    `Use ${variant.lighting}.`
  );
  sections.push(
    `Use this colour and material direction: ${category.palette_bias}. ${list(category.extra_rules)}.`
  );
  if (subcategory) {
    sections.push(
      `Make these recognition cues visually clear: ${list(subcategory.recognition_anchors)}.`
    );
  }
  sections.push(`Depict this activity: ${effective.subject}`);
  sections.push(`Place it in this believable setting: ${effective.environment}`);
  sections.push(`The emotional tone should feel ${list(effective.emotion)}.`);
  if (effective.composition) sections.push(`Use this activity-specific composition: ${effective.composition}`);
  if (effective.camera) sections.push(`Use this activity-specific camera treatment: ${effective.camera}`);
  if (effective.lighting) sections.push(`Use this activity-specific lighting: ${effective.lighting}`);
  if (effective.palette) sections.push(`Use this activity-specific palette: ${effective.palette}`);
  sections.push(
    `Keep these hobby-recognition cues visible: ${list(effective.recognition_anchors)}.`
  );
  sections.push(`The scene must include: ${list(effective.must_include)}.`);

  const promptAdditions = [
    ...(override?.override_prompt_additions || []),
    ...(flagshipOverride?.override_prompt_additions || [])
  ];
  if (promptAdditions.length) {
    sections.push(`Follow these additional scene constraints: ${promptAdditions.join(' ')}`);
  }

  const avoidList = [
    ...(effective.avoid || []),
    ...(subcategory?.avoid || []),
    ...(archetype.avoid || [])
  ];
  sections.push(
    `Do not depict any of the following: ${[...new Set(avoidList)].join(', ')}.`
  );
  sections.push(
    `Also avoid these global failure modes: ${list(globalStyle.global_negatives)}.`
  );
  const compiledPrompt = sections.join('\n\n');

  // Regression guard: model-facing prose must not expose compiler metadata in
  // the old title-like LABEL (identifier): format, nor raw underscore-style
  // archetype/variant/subcategory ids that can be echoed as captions.
  //
  // Anchored to the start of a section (sections are joined by "\n\n", so
  // each one starts a new line) and matched case-sensitively against the old
  // ALL-CAPS header tokens only. A looser anywhere-in-text, case-insensitive
  // match would collide with ordinary prose the new compiler intentionally
  // emits (e.g. "The scene must include: ..." contains "must include:" and
  // would otherwise false-positive on every single hobby).
  const forbiddenHeaderPattern =
    /^(?:GLOBAL STYLE|REFERENCE STYLE|ARCHETYPE|VISUAL VARIANT|CATEGORY|SUBCATEGORY|SUBJECT|ENVIRONMENT|EMOTION|HOBBY COMPOSITION|HOBBY CAMERA|HOBBY LIGHTING|HOBBY PALETTE|HOBBY RECOGNITION ANCHORS|MUST INCLUDE|OVERRIDE GUIDANCE|AVOID|GLOBAL NEGATIVES)\s*(?:\([^)]*\))?\s*:/m;
  if (forbiddenHeaderPattern.test(compiledPrompt)) {
    throw new Error(`Prompt-format regression for hobby "${effective.id}": title-like compiler header leaked into model-facing text`);
  }

  const internalIds = [
    effective.archetype,
    variant.id,
    effective.subcategory,
  ].filter(value => value && /[_./]/.test(value));
  for (const id of internalIds) {
    if (compiledPrompt.includes(id)) {
      throw new Error(
        `Prompt-format regression for hobby "${effective.id}": internal identifier "${id}" leaked into model-facing text`,
      );
    }
  }

  return {
    compiledPrompt,
    negativeConstraints: [...new Set([...avoidList, ...globalStyle.global_negatives])],
    archetype, category, subcategory, variant, effective
  };
}

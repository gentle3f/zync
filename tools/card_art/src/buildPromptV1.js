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

  const sections = [];
  sections.push(`GLOBAL STYLE: ${globalStyle.prompt}`);
  sections.push(`REFERENCE STYLE: ${globalStyle.reference_instruction}`);
  sections.push(`ARCHETYPE (${effective.archetype}): ${archetype.composition} ${archetype.camera} Emotional feeling: ${list(archetype.feeling)}. Recognition requirement: ${archetype.recognition}`);
  sections.push(`VISUAL VARIANT (${variant.id}): ${variant.composition} ${variant.camera} Lighting bias: ${variant.lighting}`);
  sections.push(`CATEGORY (${effective.category}): Palette bias — ${category.palette_bias}. ${list(category.extra_rules)}.`);
  if (subcategory) sections.push(`SUBCATEGORY (${effective.subcategory}): Recognition anchors — ${list(subcategory.recognition_anchors)}.`);
  sections.push(`SUBJECT: ${effective.subject}`);
  sections.push(`ENVIRONMENT: ${effective.environment}`);
  sections.push(`EMOTION: ${list(effective.emotion)}.`);
  if (effective.composition) sections.push(`HOBBY COMPOSITION: ${effective.composition}`);
  if (effective.camera) sections.push(`HOBBY CAMERA: ${effective.camera}`);
  if (effective.lighting) sections.push(`HOBBY LIGHTING: ${effective.lighting}`);
  if (effective.palette) sections.push(`HOBBY PALETTE: ${effective.palette}`);
  sections.push(`HOBBY RECOGNITION ANCHORS: ${list(effective.recognition_anchors)}.`);
  sections.push(`MUST INCLUDE: ${list(effective.must_include)}.`);

  const promptAdditions = [
    ...(override?.override_prompt_additions || []),
    ...(flagshipOverride?.override_prompt_additions || [])
  ];
  if (promptAdditions.length) sections.push(`OVERRIDE GUIDANCE: ${promptAdditions.join(' ')}`);

  const avoidList = [
    ...(effective.avoid || []),
    ...(subcategory?.avoid || []),
    ...(archetype.avoid || [])
  ];
  sections.push(`AVOID: ${[...new Set(avoidList)].join(', ')}.`);
  sections.push(`GLOBAL NEGATIVES: ${list(globalStyle.global_negatives)}.`);
  return {
    compiledPrompt: sections.join('\n\n'),
    negativeConstraints: [...new Set([...avoidList, ...globalStyle.global_negatives])],
    archetype, category, subcategory, variant, effective
  };
}

// Compiles one hobby_recipes_v1.jsonl record into a final prompt following the
// composition order in specs/ZYNC_CARD_ART_PROMPT_SYSTEM_V1.md:
//
//   1. global style
//   2. archetype guidance
//   3. category modifier
//   4. subcategory modifier
//   5. hobby-specific subject and environment
//   6. emotion
//   7. composition / camera / lighting / palette
//   8. recognition anchors
//   9. must-include
//   10. avoid
//   11. global negatives
//
// Optional overrides (hobby_overrides_v1.json for long-tail/hard_case hobbies,
// flagship_overrides_v1.json for the benchmark set) are merged in after the
// base recipe and before global negatives.

function list(items) {
  return items && items.length ? items.join(', ') : null;
}

export function compileHobbyPrompt({ hobby, globalStyle, archetypes, categories, subcategories, override, flagshipOverride }) {
  const archetype = archetypes.archetypes[hobby.archetype];
  if (!archetype) {
    throw new Error(`Unknown archetype "${hobby.archetype}" for hobby "${hobby.id}"`);
  }
  const category = categories.categories[hobby.category];
  if (!category) {
    throw new Error(`Unknown category "${hobby.category}" for hobby "${hobby.id}"`);
  }
  const subcategory = hobby.subcategory ? subcategories.subcategories[hobby.subcategory] : null;
  if (hobby.subcategory && !subcategory) {
    throw new Error(`Unknown subcategory "${hobby.subcategory}" for hobby "${hobby.id}"`);
  }

  const sections = [];

  // 1. global style
  sections.push(`GLOBAL STYLE: ${globalStyle.prompt}`);

  // 2. archetype guidance
  sections.push(
    `ARCHETYPE (${hobby.archetype}): ${archetype.composition} ${archetype.camera} Emotional feeling: ${list(archetype.feeling)}. Recognition requirement: ${archetype.recognition}`
  );

  // 3. category modifier
  sections.push(
    `CATEGORY (${hobby.category}): Palette bias — ${category.palette_bias}. ${list(category.extra_rules)}.`
  );

  // 4. subcategory modifier (optional)
  if (subcategory) {
    sections.push(
      `SUBCATEGORY (${hobby.subcategory}): Recognition anchors — ${list(subcategory.recognition_anchors)}.`
    );
  }

  // 5. hobby-specific subject and environment
  sections.push(`SUBJECT: ${hobby.subject}`);
  sections.push(`ENVIRONMENT: ${hobby.environment}`);

  // 6. emotion
  sections.push(`EMOTION: ${list(hobby.emotion)}.`);

  // 7. composition / camera / lighting / palette — inherited from archetype (2) and category (3) above;
  //    no hobby-level override fields present in v1 pilot data, so nothing additional here.

  // 8. recognition anchors
  sections.push(`HOBBY RECOGNITION ANCHORS: ${list(hobby.recognition_anchors)}.`);

  // 9. must-include
  sections.push(`MUST INCLUDE: ${list(hobby.must_include)}.`);

  // optional override prompt additions (flagship or long-tail), inserted before avoid/negatives
  const overrideAdditions = [
    ...(override?.override_prompt_additions || []),
    ...(flagshipOverride?.override_prompt_additions || []),
  ];
  if (overrideAdditions.length) {
    sections.push(`OVERRIDE GUIDANCE: ${overrideAdditions.join(' ')}`);
  }

  // 10. avoid — hobby avoid + subcategory avoid + archetype avoid + override avoid
  const avoidList = [
    ...(hobby.avoid || []),
    ...(subcategory?.avoid || []),
    ...(archetype.avoid || []),
    ...(override?.override_avoid || []),
    ...(flagshipOverride?.override_avoid || []),
  ];
  sections.push(`AVOID: ${list(avoidList)}.`);

  // 11. global negatives
  sections.push(`GLOBAL NEGATIVES: ${list(globalStyle.global_negatives)}.`);

  const compiledPrompt = sections.join('\n\n');

  const negativeConstraints = [...new Set([...avoidList, ...globalStyle.global_negatives])];

  return { compiledPrompt, negativeConstraints, archetype, category, subcategory };
}

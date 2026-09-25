// Candidate V2 object-first prompt compiler. Turns a routeHobbyV2()
// routing decision into an actual, final, model-facing prompt string -
// the piece explicitly missing from the a369058 checkpoint (routing
// metadata existed, but no compiled prompt did).
//
// Design principle (per the task spec): POSITIVE SCENE CONSTRUCTION
// FIRST, negative suppression second. The scene itself (built from each
// hobby's structural containment rule's scene_template) is what makes
// human leakage unlikely; the human-suppression paragraph is short by
// default and only expanded for the small set of rules already proven to
// trigger a strong human prior even under containment (abstract_system_
// no_operator, screen_non_human_content, swimming_hard_case_no_visible_
// swimmer).
//
// Reuses ONLY global_style_v1.json's global_brand_safety_policy field BY
// REFERENCE/READ ONLY (this module never writes to global_style_v1.json).
// The base rendering style and screen policy use V2-native text instead
// (global_style_v2_object_first.json's v2_native_style / screen_policy_v2)
// - see that file's history for why: V1's 'prompt' and
// 'global_screen_policy' fields both contain human/character-oriented
// language incompatible with V2's zero-human mandate, and V2 now uses its
// own explicitly-authorized human-language-free equivalents rather than
// reusing-and-patching V1's. V1's own compiler (buildPromptV1.js's
// compileHobbyPrompt) is untouched and still used for all real
// V1/production generation.
//
// This module makes no network/file-write calls and generates no images.

function list(items) {
  return items && items.length ? items.join(', ') : null;
}
function renderTemplate(value, ctx) {
  return String(value).replaceAll('${title}', ctx.title);
}

// Rules whose validating round found a severe/repeated human-leak failure
// even under general containment (media.movies, technology.ai,
// outdoors.swimming in round 3) - these get the fuller suppression
// paragraph appended on top of the baseline policy. Every other rule uses
// the baseline non_human_protagonist_policy alone, per the task's explicit
// instruction not to bloat every prompt with a huge repetitive negative
// block.
const STRONG_SUPPRESSION_RULE_IDS = new Set([
  'abstract_system_no_operator',
  'screen_non_human_content',
  'swimming_hard_case_no_visible_swimmer',
]);

const STRONG_SUPPRESSION_ADDENDUM =
  'This hobby has previously shown a strong tendency for a human figure, body part, or face to leak into the scene even under a general no-human policy, so apply extra care: absolutely no hands, arms, torso, legs, or face may appear anywhere in the frame, including inside any screen, reflection, or display within the scene, and no humanoid figure may be implied by posture, shadow, or silhouette.';

const CARD_UI_SUPPRESSION =
  'The artwork itself must be full-bleed and edge-to-edge with no card frame, no card border, no rounded card shell, no rarity badge, no title panel, no stats box, no TCG layout, and no watermark - the application adds any card UI separately.';

/**
 * @param {{canonical_interest_id:string, title:string, runtime_category:string, runtime_cluster:string, recipe:object, source_recipe_id:string|null}} row
 * @param {{globalStyleV1:object, globalStyleV2:object, physicalLogicV2:object, rulesV2:object, containmentV2:object, compositionV2:object, quarantinedIds:Set<string>, textModesV2:object, physicalLogicDomainsV2:object}} ctx
 * @param {function} routeFn - routeHobbyV2, injected for testability
 */
export function compileObjectFirstPromptV2(row, ctx, routeFn) {
  const routing = routeFn({
    canonical_interest_id: row.canonical_interest_id,
    title: row.title,
    runtime_category: row.runtime_category,
    runtime_cluster: row.runtime_cluster,
    archetype: row.recipe.archetype,
  }, { rules: ctx.rulesV2, containment: ctx.containmentV2, composition: ctx.compositionV2, quarantinedIds: ctx.quarantinedIds, textModes: ctx.textModesV2, physicalLogicDomains: ctx.physicalLogicDomainsV2 });

  if (routing.object_first_status === 'excluded_quarantined') {
    return { ...routing, semantic_recipe_id: row.canonical_interest_id, source_recipe_id: row.source_recipe_id || null, final_compiled_prompt: null, compiled: false };
  }

  const rule = ctx.containmentV2.rules[routing.structural_containment_rule_id];
  if (!rule) throw new Error(`Unknown structural containment rule "${routing.structural_containment_rule_id}" for ${row.canonical_interest_id}`);
  const sceneText = renderTemplate(rule.scene_template, { title: row.title });

  const compositionText = ctx.compositionV2.dimensions.composition_archetype.values[routing.composition_archetype];
  const paletteText = ctx.compositionV2.dimensions.palette_lighting_route.values[routing.palette_lighting_route];
  const effectText = ctx.compositionV2.dimensions.effect_level.semantic_guidance[routing.effect_level];
  const sceneFamilyText = routing.scene_family ? ctx.compositionV2.dimensions.scene_family.values[routing.scene_family] : null;

  // Text mode (Part C, post-Validation-16): replaces the single shared
  // text_policy_v2 paragraph with a mode matched to this row's actual
  // text-risk level, plus any id-specific guidance (e.g. the MUN
  // non-literal-country-name decision, or the marketing/gaming.video
  // reinforcement language).
  const modeDef = ctx.textModesV2?.modes?.[routing.text_mode];
  const idTextOverride = ctx.textModesV2?.id_overrides?.[row.canonical_interest_id];
  const textPolicySection = modeDef
    ? `${ctx.globalStyleV2.text_policy_v2.principle} ${modeDef.guidance}${idTextOverride ? ' ' + idTextOverride.guidance : ''}`
    : `${ctx.globalStyleV2.text_policy_v2.principle} Suppress generated text when it is ${list(ctx.globalStyleV2.text_policy_v2.suppress_when)}.`;

  // Physical logic (Part B, post-Validation-16): the shared generic rule
  // is always present, plus a domain-specific rule appended when this
  // row's archetype maps to one (physical_logic_domains_v2.json) - e.g.
  // food_utensils fixes food.japanese's floating-chopsticks failure.
  const domainDef = routing.physical_logic_domain ? ctx.physicalLogicDomainsV2?.domains?.[routing.physical_logic_domain] : null;
  const physicalLogicSection =
    `${ctx.physicalLogicV2.rule_text} For example, never depict ${list(ctx.physicalLogicV2.forbidden_examples.slice(0, 3))}. ` +
    `Motion must have a plausible cause such as ${list(ctx.physicalLogicV2.allowed_causes_of_motion.slice(0, 6))}.` +
    (domainDef ? ` ${domainDef.rule_text}` : '');

  let humanSuppressionSection = ctx.globalStyleV2.non_human_protagonist_policy;
  if (STRONG_SUPPRESSION_RULE_IDS.has(routing.structural_containment_rule_id)) {
    humanSuppressionSection += ' ' + STRONG_SUPPRESSION_ADDENDUM;
  }

  // V2 base style: uses globalStyleV2.v2_native_style, an explicitly
  // authorized human-language-free fork of V1's D4 rendering-language
  // block (global_style_v1.json's 'prompt' field), written this
  // checkpoint to eliminate the character/face/anatomy language that a
  // prior checkpoint could only patch with an override clause. V1's
  // global_style_v1.json is never read for prompt text here and remains
  // completely untouched (still hash-verified unchanged by the audit).
  //
  // Screen suppression uses globalStyleV2.screen_policy_v2, a dedicated
  // positive V2 screen policy written this checkpoint - V1's
  // global_screen_policy (which contains a human-recognition clause) is
  // still never reused, but is now replaced by real V2-native coverage
  // instead of being simply omitted.
  const sections = [
    ctx.globalStyleV2.v2_native_style,
    ctx.globalStyleV1.global_brand_safety_policy,
    ctx.globalStyleV2.screen_policy_v2,
    humanSuppressionSection,
    ctx.globalStyleV2.anti_sameness_policy,
    physicalLogicSection,
    `Depict this activity: ${sceneText}`,
    sceneFamilyText ? `Overall scene structure: ${sceneFamilyText}` : null,
    `Use this composition: ${compositionText}`,
    `Use this lighting and palette: ${paletteText}`,
    `Effects guidance: ${effectText}`,
    textPolicySection,
    CARD_UI_SUPPRESSION,
  ].filter(Boolean);

  const compiledPrompt = sections.join('\n\n');

  if (compiledPrompt.includes('${')) {
    throw new Error(`Unresolved template placeholder in compiled V2 prompt for ${row.canonical_interest_id}`);
  }
  const internalIds = [
    routing.protagonist_type, routing.object_first_status, routing.structural_containment_rule_id,
    routing.composition_archetype, routing.palette_lighting_route, routing.effect_level,
    routing.scene_family, routing.text_mode, routing.physical_logic_domain,
  ].filter(v => v && v.includes('_'));
  for (const id of new Set(internalIds)) {
    if (compiledPrompt.includes(id)) {
      throw new Error(`V2 prompt-format regression for ${row.canonical_interest_id}: internal identifier "${id}" leaked into model-facing text`);
    }
  }

  return {
    ...routing,
    semantic_recipe_id: row.canonical_interest_id,
    source_recipe_id: row.source_recipe_id || null,
    final_compiled_prompt: compiledPrompt,
    compiled: true,
  };
}

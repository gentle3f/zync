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
// Reuses V1's global_style_v1.json fields (prompt, global_screen_policy,
// global_brand_safety_policy) BY REFERENCE/READ ONLY - this module never
// writes to global_style_v1.json and V1's own compiler
// (buildPromptV1.js's compileHobbyPrompt) is untouched and still used
// for all real V1/production generation.
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
 * @param {{globalStyleV1:object, globalStyleV2:object, physicalLogicV2:object, rulesV2:object, containmentV2:object, compositionV2:object, quarantinedIds:Set<string>}} ctx
 * @param {function} routeFn - routeHobbyV2, injected for testability
 */
export function compileObjectFirstPromptV2(row, ctx, routeFn) {
  const routing = routeFn({
    canonical_interest_id: row.canonical_interest_id,
    title: row.title,
    runtime_category: row.runtime_category,
    runtime_cluster: row.runtime_cluster,
    archetype: row.recipe.archetype,
  }, { rules: ctx.rulesV2, containment: ctx.containmentV2, composition: ctx.compositionV2, quarantinedIds: ctx.quarantinedIds });

  if (routing.object_first_status === 'excluded_quarantined') {
    return { ...routing, semantic_recipe_id: row.canonical_interest_id, source_recipe_id: row.source_recipe_id || null, final_compiled_prompt: null, compiled: false };
  }

  const rule = ctx.containmentV2.rules[routing.structural_containment_rule_id];
  if (!rule) throw new Error(`Unknown structural containment rule "${routing.structural_containment_rule_id}" for ${row.canonical_interest_id}`);
  const sceneText = renderTemplate(rule.scene_template, { title: row.title });

  const compositionText = ctx.compositionV2.dimensions.composition_archetype.values[routing.composition_archetype];
  const paletteText = ctx.compositionV2.dimensions.palette_lighting_route.values[routing.palette_lighting_route];
  const effectText = ctx.compositionV2.dimensions.effect_level.semantic_guidance[routing.effect_level];

  const textPolicy = ctx.globalStyleV2.text_policy_v2;
  const textPolicySection =
    `${textPolicy.principle} Suppress generated text when it is ${list(textPolicy.suppress_when)}. ` +
    `Non-legible or abstract marks are fine when semantically natural, for example ${list(textPolicy.allow_when_semantically_natural.slice(0, 4))}.`;

  const physicalLogicSection =
    `${ctx.physicalLogicV2.rule_text} For example, never depict ${list(ctx.physicalLogicV2.forbidden_examples.slice(0, 3))}. ` +
    `Motion must have a plausible cause such as ${list(ctx.physicalLogicV2.allowed_causes_of_motion.slice(0, 6))}.`;

  let humanSuppressionSection = ctx.globalStyleV2.non_human_protagonist_policy;
  if (STRONG_SUPPRESSION_RULE_IDS.has(routing.structural_containment_rule_id)) {
    humanSuppressionSection += ' ' + STRONG_SUPPRESSION_ADDENDUM;
  }

  // Note: V1's global_screen_policy is deliberately NOT reused here - it
  // contains a human-recognition clause ("Recognition must come from the
  // person, physical tool, device...") written for V1's human-led
  // compositions that would directly conflict with V2's zero-human
  // mandate. Screen suppression for V2 is instead covered by
  // non_human_protagonist_policy's existing "no screen images of people"
  // clause plus the dedicated screen_non_human_content containment rule
  // for archetypes where a screen is semantically present. See
  // global_style_v2_object_first.json's base_style_conflict_disclosure.
  const sections = [
    ctx.globalStyleV1.prompt,
    ctx.globalStyleV2.base_style_override_clause,
    ctx.globalStyleV1.global_brand_safety_policy,
    humanSuppressionSection,
    ctx.globalStyleV2.anti_sameness_policy,
    physicalLogicSection,
    `Depict this activity: ${sceneText}`,
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

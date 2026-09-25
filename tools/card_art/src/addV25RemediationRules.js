// Zync Object-First V2 Wave-C Remediation - v2.5 narrow architecture.
//
// Part 6-9: 7 new id-exact structural containment rules (2 automotive-
// adjacent generic-morphology fixes are handled separately via a global
// automotive grammar note; the 7 here are the human-operated-object and
// semantic-misroute fixes: lifestyle.gardening, science.chemistry,
// learning.nonfiction, wellness.mobility, media.tv,
// technology.machine_learning, arts.illustration).
//
// Part 7: introduces `interaction_support_mode` as a reusable field on
// EVERY structural containment rule (existing 29 + 7 new = 36) -
// static_resting / mechanically_supported / automated_machine /
// passive_physics / environmental_aftermath / not_applicable /
// screen_content_only. This is METADATA ONLY for the 29 pre-existing
// rules (their scene_template text is untouched, so already-decided
// rows' prompt hashes do not change) - it classifies what kind of
// physical interaction each rule's scene construction already implies,
// giving future static audits a structured signal instead of only a
// text-based verb scan.
//
// Zero-cost. No image generated.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SPECS = path.join(ROOT, 'specs');

const readJson = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const writeJson = (p, value) => fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');

const containmentPath = path.join(SPECS, 'structural_containment_rules_v2.json');
const rulesPath = path.join(SPECS, 'object_first_rules_v2.json');

const containment = readJson(containmentPath);
const objectFirstRules = readJson(rulesPath);

// ---------------------------------------------------------------------------
// interaction_support_mode - metadata tag for every EXISTING rule
// ---------------------------------------------------------------------------

const EXISTING_MODE_TAGS = {
  action_aftermath: 'environmental_aftermath',
  private_empty_venue: 'static_resting',
  object_hero_no_performer: 'static_resting',
  abstract_system_no_operator: 'automated_machine',
  screen_non_human_content: 'screen_content_only',
  private_environment_animal: 'not_applicable',
  swimming_hard_case_no_visible_swimmer: 'passive_physics',
  generic_structural_containment: 'static_resting',
  object_hero_clean: 'static_resting',
  professional_material_world: 'static_resting',
  listening_equipment_world: 'static_resting',
  campus_activity_grammar: 'static_resting',
  community_gathering_traces: 'static_resting',
  community_gathering_vehicles: 'static_resting',
  shared_workspace_grammar: 'static_resting',
  campaign_planning_materials: 'static_resting',
  legal_practice_materials: 'static_resting',
  model_railway_miniature_scale: 'static_resting',
  anime_culture_object_first: 'static_resting',
  startup_early_stage_world: 'static_resting',
  pop_music_production_energy: 'mechanically_supported',
  mock_trial_simulation: 'static_resting',
  coffee_ritual_resting_scene: 'static_resting',
  fiction_object_first_grammar: 'static_resting',
  vocal_singing_object_first: 'mechanically_supported',
  karaoke_object_first: 'mechanically_supported',
  booktube_creator_setup_no_presenter: 'mechanically_supported',
  consumer_gadgets_object_hero: 'static_resting',
  stretching_mobility_props_no_body: 'static_resting',
};

for (const [ruleId, mode] of Object.entries(EXISTING_MODE_TAGS)) {
  if (!containment.rules[ruleId]) throw new Error(`Unknown existing rule id: ${ruleId}`);
  containment.rules[ruleId].interaction_support_mode = mode;
}
const untaggedExisting = Object.keys(containment.rules).filter(id => !EXISTING_MODE_TAGS[id]);
if (untaggedExisting.length && untaggedExisting.length !== 7) {
  // Exactly 7 new rules (added below) are expected to be untagged at this
  // point in the script; anything else means an existing rule was missed.
  throw new Error(`Unexpected untagged existing rule count: ${untaggedExisting.length} (${untaggedExisting.join(', ')})`);
}

// ---------------------------------------------------------------------------
// 7 new id-exact structural containment rules
// ---------------------------------------------------------------------------

const NEW_RULES = {
  // Part 8 - lifestyle.gardening (floating self-watering watering can).
  gardening_object_first_grammar: {
    applies_to_archetypes: [],
    interaction_support_mode: 'static_resting',
    bad_pattern: "lifestyle.gardening's generic_structural_containment fallback (home_lifestyle archetype) gave no concrete prop-rest guidance, and its own recipe subject text is human-first ('a person actively...'), so the model preserved an implied active-watering action via an invisible hand - a watering can floated and watered plants by itself.",
    good_pattern: 'A planted garden scene built entirely from resting objects - no watering can, hose, or tool shown actively pouring or operating.',
    scene_template:
      'A private, empty garden scene for ${title}: a planted garden bed with flowers, vegetables, or seedlings, visible soil, a watering can resting on the ground or a bench (never tilted as if pouring, never floating), a trowel resting naturally beside the bed, empty gardening gloves laid down, and recently-wet soil or scattered water droplets on leaves as a physically self-explaining static cue of recent watering. If a hose or sprinkler is shown, it must be visibly connected to a fixed support (a tap, a reel, a mounted sprinkler head) rather than floating or self-operating. No person, no floating tool, and no tool shown actively performing its action.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (commit f98b1fc finding).',
  },

  // Part 9 - science.chemistry (floating self-pouring flask).
  chemistry_lab_object_first_grammar: {
    applies_to_archetypes: [],
    interaction_support_mode: 'mechanically_supported',
    bad_pattern: "science.chemistry's generic_structural_containment fallback (learning_exploration archetype) gave no concrete lab-equipment-rest guidance, and its own recipe subject text is human-first ('a person actively building, configuring...'), so the model preserved an implied active-pouring action via an invisible hand - a flask/lab vessel floated and poured liquid by itself.",
    good_pattern: 'A lab scene built entirely from mechanically-supported, resting glassware - no flask, beaker, or pipette shown actively pouring or operating unsupported.',
    scene_template:
      'A private, empty chemistry lab scene for ${title}: flasks and test tubes resting upright in a rack or held by a clamp on a lab stand (never tilted as if pouring, never floating unsupported), measuring glassware resting on the bench, a burner or hotplate with a visible support base, colorful chemical solutions showing color change as a static visual property, condensation on cool glass, and a controlled reaction vessel resting in its stand. If active liquid transfer is depicted, it must be shown with a visible mechanical support (a burette clamped to a stand, a dropper resting in a holder) - otherwise show only the before or after state of the reaction, never mid-pour with no support. No person, no floating vessel, and no vessel shown actively pouring with no support.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (commit f98b1fc finding).',
  },

  // Part 10 - learning.nonfiction (drifted to astronomy/telescope).
  nonfiction_object_first_grammar: {
    applies_to_archetypes: [],
    interaction_support_mode: 'static_resting',
    bad_pattern: "learning.nonfiction shares the same generic, human-first V1 recipe pattern as learning.fiction (fixed previously) but was never given its own concrete anchors - under generic_structural_containment's vague 'defining objects... carry the recognition' framing, the model drifted to an unrelated 'curiosity/documentary' concept (astronomy/telescope/stargazing) instead of nonfiction reading material.",
    good_pattern: 'A nonfiction/research reading scene anchored in concrete reference-material objects, not an unrelated science-documentary subject.',
    scene_template:
      'A private, empty nonfiction/research reading scene for ${title}: reference books and factual books with blank spines resting on a desk or shelf, a bookmark ribbon, a magnifying glass resting beside an open book, folded maps or charts with non-legible detail, photographs resting face-down or with non-legible content, and a factual diagram or chart sheet lying flat - in a warm home, library, or study environment. The scene communicates real-world factual/research reading culture through arrangement alone, with no person present. The scene must NOT become an astronomy, telescope, or stargazing scene, and must NOT become a fiction/fantasy reading scene - the objects shown must read as factual reference material specifically.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (commit f98b1fc finding, root cause: ambiguous/under-specified semantic anchors inherited from the same generic V1 recipe pattern as learning.fiction).',
  },

  // Part 10 - wellness.mobility (drifted to dog agility).
  mobility_training_object_first_grammar: {
    applies_to_archetypes: [],
    interaction_support_mode: 'static_resting',
    bad_pattern: "wellness.mobility's generic_structural_containment fallback (calm_wellness archetype) did not disambiguate the word 'mobility' from animal mobility/agility - under a zero-human policy with only generic wellness-prop guidance, the model rendered dog agility/pet obstacle equipment instead of human joint-mobility training equipment.",
    good_pattern: 'A human joint-mobility training scene anchored in concrete mobility equipment, explicitly not an animal-agility or obstacle-course scene.',
    scene_template:
      'A private, empty human mobility-training scene for ${title}: a mobility/stretching mat laid flat, resistance bands, a foam roller, a mobility ball, a stretching strap, and mobility blocks arranged naturally in an open, calm, uncluttered studio, home, or outdoor floor space. This is HUMAN joint-mobility and range-of-motion training, not any other kind of "mobility" - the scene must NOT become a dog-agility course, pet obstacle equipment, a transport-mobility scene, or a wheelchair/assistive-device scene. No person, no animal, and no large obstacle-course structure.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (commit f98b1fc finding, root cause: word-level ambiguity in "mobility" never disambiguated by the generic fallback rule).',
  },

  // Part 10 - media.tv (drifted to outdoor cinema projection).
  television_object_first_grammar: {
    applies_to_archetypes: [],
    interaction_support_mode: 'screen_content_only',
    bad_pattern: "media.tv's own recipe environment text explicitly lists 'cinema, theatre' alongside 'home-viewing' as acceptable venues for TV Series - a genuine content ambiguity inherited from the underlying recipe data, not a V2 routing bug. Combined with the generic screen_non_human_content rule (no venue specificity beyond 'empty of any audience'), the model rendered an outdoor projection/large-screen public event instead of television viewing.",
    good_pattern: 'A home television-viewing scene anchored in TV-specific equipment, explicitly not a cinema or outdoor public screening.',
    scene_template:
      'A private, empty home television-viewing scene for ${title}: a television set or flat display resting on a stand or mounted on a wall, a remote control resting on a nearby surface, a media console, a couch or viewing seating, speakers, and a TV-guide or streaming interface showing only non-readable abstract tiles on the screen. This is TELEVISION specifically - the scene must NOT become a cinema, movie theatre, outdoor projection, or large public screening event; keep the setting as an ordinary home living-room or media room, never a public venue.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (commit f98b1fc finding). Root cause disclosed at the recipe-data level: the original V1 recipe environment field for TV Series names cinema/theatre as valid venues, which is inherited content ambiguity, not a V2 architecture bug.',
  },

  // Part 10 - technology.machine_learning (drifted to sci-fi machine/totem).
  machine_learning_object_first_grammar: {
    applies_to_archetypes: [],
    interaction_support_mode: 'automated_machine',
    bad_pattern: "abstract_system_no_operator's 'self-contained abstract or mechanical system operating on its own' framing fits technology.ai (which passed cleanly) but machine_learning's own recipe anchors ('human actively using Machine Learning, subfield-specific hardware') gave no concrete grounded-technical objects, so the model filled the abstraction with a generic sci-fi machine/totem instead of recognizable ML-technical imagery.",
    good_pattern: 'A grounded, technical machine-learning visualization - training hardware and abstract data/model visuals - not a generic sci-fi machine.',
    scene_template:
      'A private, empty machine-learning workspace for ${title}, represented as a self-contained technical system operating entirely on its own: server or GPU compute hardware with status lights, an abstract training-pipeline or model-graph visualization glowing on a display (non-readable), dataset blocks or embedding-cluster visuals rendered as abstract geometric shapes, and an evaluation-chart geometry shown as abstract non-legible curves. The majority of the frame stays clean negative space. This must read as grounded machine-learning technical infrastructure specifically - it must NOT become a generic sci-fi machine, a giant mechanical robot or totem, a humanoid AI figure, or generic cyberpunk technology. There is no operator, no hands, no arms, and no person of any kind.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (commit f98b1fc finding). Exact-ID fix only - technology.ai, which shares the same tech_workspace archetype and abstract_system_no_operator rule, passed cleanly, confirming this is a recipe-specific concrete-anchor gap, not a systemic rule-family failure (the same determination already made for technology.gadgets).',
  },

  // Part 10 - arts.illustration (drifted to matcha/tea culture).
  illustration_object_first_grammar: {
    applies_to_archetypes: [],
    interaction_support_mode: 'static_resting',
    bad_pattern: "action_aftermath's scene_template was written generically for a sports-validation case (sports.running) and uses phrasing like 'water droplets' and 'a freshly disturbed surface' with no illustration-specific concrete noun at all - combined with arts.illustration's own vague recipe anchors ('relevant tool, material, movement, or medium'), the model had almost total freedom and defaulted to an unrelated but physically-plausible 'recently finished' warm/steam/liquid scene (matcha/tea culture) rather than an art-supplies scene. This is a genuine, disclosed static cause (missing concrete anchors), not a fabricated routing bug.",
    good_pattern: 'An illustration studio still life anchored in concrete drawing/art-supply objects, not an unrelated food/drink or tea-ceremony scene.',
    scene_template:
      'A private, empty illustration studio scene for ${title}: an open sketchbook showing only non-legible abstract marks, a drawing tablet with a stylus resting beside it, ink pens and pencils resting on the desk, brushes resting beside a finished piece of art (never held, never mid-stroke), one or two finished illustrated prints or a line-art sheet displayed, small color swatches, and a drawing desk or studio corner. The scene communicates drawn visual-art culture through these objects alone, with no person present. The scene must NOT become a tea ceremony, matcha, or any food/drink scene, must NOT become generic photography, and must NOT become printing/manufacturing machinery.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (commit f98b1fc finding). Prepared and repaired this checkpoint but the id remains qa_quarantine and is deliberately excluded from Sentinel-8 - it stays held pending a later, separate visual revalidation.',
  },
};

for (const [id, rule] of Object.entries(NEW_RULES)) {
  if (containment.rules[id]) throw new Error(`Rule id already exists: ${id}`);
  containment.rules[id] = rule;
  containment.rule_id_index.push(id);
}

writeJson(containmentPath, containment);

// ---------------------------------------------------------------------------
// id-exact overrides in object_first_rules_v2.json
// ---------------------------------------------------------------------------

const ID_OVERRIDES = {
  'lifestyle.gardening': { rule: 'gardening_object_first_grammar', protagonist_type: 'object', reason: 'v2.5 Wave-C remediation: floating self-watering watering can fix.' },
  'science.chemistry': { rule: 'chemistry_lab_object_first_grammar', protagonist_type: 'object', reason: 'v2.5 Wave-C remediation: floating self-pouring flask fix.' },
  'learning.nonfiction': { rule: 'nonfiction_object_first_grammar', protagonist_type: 'object', reason: 'v2.5 Wave-C remediation: astronomy/telescope semantic misroute fix.' },
  'wellness.mobility': { rule: 'mobility_training_object_first_grammar', protagonist_type: 'object', reason: 'v2.5 Wave-C remediation: dog-agility semantic misroute fix.' },
  'media.tv': { rule: 'television_object_first_grammar', protagonist_type: 'environment', reason: 'v2.5 Wave-C remediation: outdoor-cinema-projection semantic misroute fix.' },
  'technology.machine_learning': { rule: 'machine_learning_object_first_grammar', protagonist_type: 'abstract_system', reason: 'v2.5 Wave-C remediation: generic sci-fi machine/totem semantic misroute fix.' },
  'arts.illustration': { rule: 'illustration_object_first_grammar', protagonist_type: 'object', reason: 'v2.5 Wave-C remediation: matcha/tea-culture semantic misroute fix. Remains qa_quarantine, excluded from Sentinel-8.' },
};

for (const [id, info] of Object.entries(ID_OVERRIDES)) {
  if (objectFirstRules.id_prefix_overrides.some(o => o.match?.id === id)) throw new Error(`id_prefix_overrides already has an exact-id entry for ${id}`);
  objectFirstRules.id_prefix_overrides.push({
    match: { id },
    protagonist_type: info.protagonist_type,
    object_first_status: 'containment_required',
    structural_containment_rule_id: info.rule,
    confidence: 'extrapolated',
    rationale: info.reason,
  });
}

writeJson(rulesPath, objectFirstRules);

console.log('Tagged interaction_support_mode on', Object.keys(EXISTING_MODE_TAGS).length, 'existing rules.');
console.log('Added 7 new structural containment rules:', Object.keys(NEW_RULES).join(', '));
console.log('Added 7 id-exact routing overrides:', Object.keys(ID_OVERRIDES).join(', '));

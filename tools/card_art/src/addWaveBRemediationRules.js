// Zync Object-First V2 Wave-B Remediation Gate - adds 7 id-exact
// structural containment rule fixes (Parts 5/6/7/8) plus their routing
// overrides in object_first_rules_v2.json. Programmatic (not hand-edited
// JSON) to avoid syntax errors given the file sizes involved.
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
// 7 new id-exact structural containment rules
// ---------------------------------------------------------------------------

const NEW_RULES = {
  // Part 5 - food.coffee (floating self-pouring kettle). Does NOT touch
  // food.specialty_coffee, which passed and keeps private_empty_venue.
  coffee_ritual_resting_scene: {
    applies_to_archetypes: [],
    bad_pattern: "food.coffee's own recipe subject text describes coffee 'held in both hands' and 'hands cradling the mug', which under a zero-human policy caused the model to preserve the implied active pour-over action via an invisible hand - rendered as a kettle pouring by itself.",
    good_pattern: 'A completely static, already-finished or resting coffee setup: no vessel is shown mid-pour or mid-action, everything rests on a stable surface.',
    scene_template:
      "A private, empty coffee scene for ${title} built entirely from resting, already-finished elements: coffee beans, a finished cup of coffee, a grinder, a dripper resting on its server or cup, a kettle resting on the counter (never pouring, never tilted as if mid-pour), a filter paper, gentle steam rising from the still cup as a physically self-explaining static cue, in a cozy cafe or home coffee environment with no person present. Every tool and vessel is shown at rest or as if a session just finished, never suspended, tilted, or actively pouring.",
    validated_by: [],
    notes: 'Wave-B remediation (commit 6848b4b finding). id-exact override for food.coffee only - food.specialty_coffee already passed and is untouched.',
  },

  // Part 6 - learning.fiction (floating self-writing pen + pseudo-text).
  fiction_object_first_grammar: {
    applies_to_archetypes: [],
    bad_pattern: "learning.fiction's own recipe subject text is human-first ('a person actively reading... annotating... hands, book bodies, pages... must carry the concept'), which under a zero-human policy caused the model to preserve the implied active writing action via an invisible hand - rendered as a large pen floating and writing by itself, with substantial pseudo-legible text.",
    good_pattern: 'A completely static reading/writing-culture still life built from resting objects and environmental/abstract story motifs, with no pen or book performing an action by itself.',
    scene_template:
      'A private, empty fiction/story scene for ${title} built entirely from resting objects: an open novel or manuscript lying flat, a stack of books, a notebook showing only non-legible abstract marks, a resting fountain pen lying beside the notebook (never held, never mid-stroke, never floating), bookmarks, index cards, and subtle genre-neutral storytelling atmosphere (soft light, warm color, a sense of imagination) carried through the environment rather than through any active writing gesture. The scene communicates fiction and narrative culture through arrangement and atmosphere alone, with no person, no floating implement, and no readable prose anywhere in frame.',
    validated_by: [],
    notes: 'Wave-B remediation (commit 6848b4b finding).',
  },

  // Part 7 - music.singing (drifted to percussion/instrument imagery).
  vocal_singing_object_first: {
    applies_to_archetypes: [],
    bad_pattern: "object_hero_no_performer's generic 'instrument or tool that defines the hobby' framing has no instrument to anchor to for a vocal-only hobby, so the model substituted an unrelated instrument (percussion) as a false hero instead of communicating singing.",
    good_pattern: 'Anchor identity in vocal-performance equipment and environment rather than any instrument, with no visible singer.',
    scene_template:
      'A private, empty vocal-performance scene for ${title} built from a mounted studio or stage microphone on its stand (never held, never floating), a pop filter, a vocal booth or rehearsal-room environment, a lyric sheet showing only non-legible abstract marks, and subtle visual cues suggesting recent vocal performance (a softly glowing waveform display, warm stage or booth lighting) - with absolutely no performer, singer, or visible person anywhere in frame, and no unrelated instrument substituted as the hero.',
    validated_by: [],
    notes: 'Wave-B remediation (commit 6848b4b finding, Part 7 music semantic hardening).',
  },

  // Part 7 - music.karaoke (isolated mic in a rainy street scene).
  karaoke_object_first: {
    applies_to_archetypes: [],
    bad_pattern: "object_hero_no_performer's generic framing produced an isolated microphone in an unrelated outdoor rainy setting, communicating nothing about karaoke specifically.",
    good_pattern: 'Anchor identity in karaoke-room equipment (machine, screen, mounted mics, lounge cues) rather than a bare microphone in a generic setting.',
    scene_template:
      'A private, empty karaoke-room scene for ${title} built from a karaoke microphone mounted on a stand or resting plausibly on a table (never floating, never held), a karaoke machine or screen showing only a non-readable abstract song-selection interface, a second microphone paired nearby if useful, a small speaker setup, and warm colored karaoke-lounge lighting - with absolutely no performer, singer, or visible person anywhere in frame.',
    validated_by: [],
    notes: 'Wave-B remediation (commit 6848b4b finding, Part 7 music semantic hardening).',
  },

  // Part 8 - learning.book_genre.booktube (rendered as robot library/conveyor).
  booktube_creator_setup_no_presenter: {
    applies_to_archetypes: [],
    bad_pattern: "abstract_system_no_operator's 'self-contained abstract or mechanical system... operating entirely on its own' framing fits genuinely automated/abstract subjects (technology.ai) but does not fit a human creator hobby like BookTube - forcing it into that framing produced a robot-library/conveyor-belt scene with no relation to book creation or video presenting.",
    good_pattern: 'A book-creator recording setup shown as a still, resting scene - camera, books, and recording gear - communicating creator culture without any operator or mechanical-system substitution.',
    scene_template:
      'A private, empty book-creator recording setup for ${title}: a stack of plain unbranded books with one open on a stand, a generic camera or phone mounted on a tripod aimed at an empty presenting spot, a small microphone and a soft ring light nearby, all resting in place as if a recording session just ended or is about to begin - with no presenter, no operator, no platform interface, no readable text, and absolutely no factory, conveyor, robotic, or industrial-manufacturing imagery of any kind.',
    validated_by: [],
    notes: 'Wave-B remediation (commit 6848b4b finding). Exact-ID fix only, not a rule-family change - sibling creator_workflow/tech_workspace rows using the same underlying abstract_system_no_operator rule (technology.ai) passed cleanly, confirming this is a recipe-specific mismatch, not a systemic grammar failure.',
  },

  // Part 8 - technology.gadgets (rendered as CNC/electronics manufacturing).
  consumer_gadgets_object_hero: {
    applies_to_archetypes: [],
    bad_pattern: "abstract_system_no_operator's 'mechanical system operating on its own' framing fits an inherently automated/abstract subject (technology.ai) but does not fit ordinary consumer hardware - forcing gadgets into that framing produced CNC/electronics-manufacturing machinery instead of everyday devices.",
    good_pattern: 'A still-life arrangement of ordinary unbranded consumer gadgets, resting in place, with no factory or manufacturing framing.',
    scene_template:
      'A private, empty consumer-gadgets still life for ${title}: an assortment of generic unbranded consumer devices resting on a surface - wireless earbuds in their case, a generic smartwatch-like wearable, a portable charger, a compact speaker, a slab-shaped phone-like device with a blank screen, a small camera or its accessories, and a charging dock - arranged as if just unpacked or set down, with no person, no recognizable brand marks, and absolutely no CNC machine, factory line, circuit-board manufacturing, or robotics-workshop imagery of any kind.',
    validated_by: [],
    notes: 'Wave-B remediation (commit 6848b4b finding). Exact-ID fix only - technology.ai, which shares the same tech_workspace archetype and abstract_system_no_operator rule, passed cleanly, confirming this is a recipe-specific mismatch (gadgets are physical objects, not an abstract system), not a systemic grammar failure.',
  },

  // Part 8 - wellness.stretching (rendered as a large rehab/gym machine).
  stretching_mobility_props_no_body: {
    applies_to_archetypes: [],
    bad_pattern: "generic_structural_containment's default 'defining objects/equipment as hero' framing gave the model no specific prop guidance for stretching, so it invented a large rehabilitation/gym machine as a false hero object instead of simple mobility props.",
    good_pattern: 'Simple, recognizable stretching/mobility props in a calm, uncluttered space, with no large machine and no human body.',
    scene_template:
      'A private, empty stretching/mobility scene for ${title}: a yoga or stretching mat laid flat, a resistance band, a stretching strap, a foam roller, and mobility blocks arranged naturally in an open, calm, uncluttered studio, home, or outdoor floor space - with no person, no human body of any kind, and absolutely no large gym machine, physiotherapy equipment, or weightlifting apparatus as the hero.',
    validated_by: [],
    notes: 'Wave-B remediation (commit 6848b4b finding). Exact-ID fix only - sibling calm_wellness rows (wellness.pilates approved, wellness.yoga generated with no comparable finding) show no equivalent failure under the same generic_structural_containment rule, confirming this is a recipe-specific prop-guidance gap, not a systemic grammar failure.',
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

// protagonist_type/object_first_status carried over from each id's current
// production_candidate_freeze_v1.json (v2.3) row, except technology.gadgets
// whose protagonist_type moves from "abstract_system" to "object" (Part 8:
// gadgets are now a still-life of resting consumer objects, not a
// self-operating abstract system).
const ID_OVERRIDES = {
  'food.coffee': { rule: 'coffee_ritual_resting_scene', protagonist_type: 'food_drink', reason: 'Wave-B remediation: floating self-pouring kettle fix, exact-id only (food.specialty_coffee untouched).' },
  'learning.fiction': { rule: 'fiction_object_first_grammar', protagonist_type: 'object', reason: 'Wave-B remediation: floating self-writing pen + pseudo-text fix.' },
  'music.singing': { rule: 'vocal_singing_object_first', protagonist_type: 'object', reason: 'Wave-B remediation: vocal-identity semantic hardening (Part 7).' },
  'music.karaoke': { rule: 'karaoke_object_first', protagonist_type: 'object', reason: 'Wave-B remediation: vocal-identity semantic hardening (Part 7).' },
  'learning.book_genre.booktube': { rule: 'booktube_creator_setup_no_presenter', protagonist_type: 'machine_process', reason: 'Wave-B remediation: robot-library/conveyor misfire fix, exact-id only.' },
  'technology.gadgets': { rule: 'consumer_gadgets_object_hero', protagonist_type: 'object', reason: 'Wave-B remediation: CNC/manufacturing misfire fix, exact-id only. protagonist_type changed from abstract_system to object.' },
  'wellness.stretching': { rule: 'stretching_mobility_props_no_body', protagonist_type: 'environment', reason: 'Wave-B remediation: gym-machine misfire fix, exact-id only.' },
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

console.log('Added 7 new structural containment rules:', Object.keys(NEW_RULES).join(', '));
console.log('Added 7 id-exact routing overrides:', Object.keys(ID_OVERRIDES).join(', '));

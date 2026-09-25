// Zync Object-First V2 Wave-C Remediation - Part 6.
// Narrow automotive generic-morphology grammar for the 3 QA-quarantined
// full-body-car ids (transport.classic_cars, transport.sports_cars,
// transport.supercars). The problem is not "remove logos" (already
// covered catalog-wide by global_brand_safety_policy) - it is
// recognizable VEHICLE MORPHOLOGY even with no logo present. These rules
// replace the shared private_empty_venue default with id-exact grammar
// demanding deliberately original/blended body geometry.
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

const MORPHOLOGY_NEGATIVE_CLAUSE =
  'Avoid any combination of features strongly associated with a specific real manufacturer or model, even with no logo present: no signature headlight geometry, no signature grille or intake design, no trademark-like taillight arrangement, no distinctive greenhouse/window profile, no iconic fender or shoulder-line proportions, no highly recognizable side-intake layout, no model-specific rear-wing or body treatment, and no classic model-specific silhouette. Prefer original, blended body geometry with simplified forms, non-identifying headlight clusters, a novel grille/intake treatment, and mixed-era or mixed-brand design cues rather than one exact real model.';

const NEW_RULES = {
  classic_car_generic_morphology: {
    applies_to_archetypes: [],
    interaction_support_mode: 'static_resting',
    bad_pattern: 'transport.classic_cars rendered a vehicle body strongly resembling a recognizable classic Japanese sports/GT car design even with no logo present - the shared private_empty_venue rule has no morphology constraint at all.',
    good_pattern: 'Classic-car appreciation communicated through generic vintage vehicles, period tools, and mixed-era cues rather than one identifiable real classic model.',
    scene_template:
      'A private, empty classic-car garage scene for ${title}: a generic vintage-styled vehicle body with deliberately blended, mixed-era design cues (not matching any one real historic model), period-appropriate tools resting on a workbench, vintage badges and dials with no readable brand names, and warm garage lighting. ' + MORPHOLOGY_NEGATIVE_CLAUSE + ' No person.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (Part 6). id-exact, narrow automotive grammar.',
  },
  sports_car_generic_morphology: {
    applies_to_archetypes: [],
    interaction_support_mode: 'static_resting',
    bad_pattern: 'transport.sports_cars rendered a car silhouette strongly resembling Porsche-911-type signature morphology even with no logo present.',
    good_pattern: 'A generic original sports coupe with deliberately non-model-specific blended geometry.',
    scene_template:
      'A private, empty scene for ${title}: a generic original sports-coupe body with deliberately blended, non-model-specific proportions parked in a clean private space, its own defining performance cues (a low stance, a simplified sport-oriented silhouette) carrying the recognition. ' + MORPHOLOGY_NEGATIVE_CLAUSE + ' No person.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (Part 6). id-exact, narrow automotive grammar.',
  },
  supercar_generic_morphology: {
    applies_to_archetypes: [],
    interaction_support_mode: 'static_resting',
    bad_pattern: 'transport.supercars rendered a vehicle morphology strongly resembling a recognizable McLaren-like supercar design language even with no logo present.',
    good_pattern: 'A fictional futuristic high-performance vehicle with deliberately original morphology, not an identifiable real supercar model.',
    scene_template:
      'A private, empty scene for ${title}: a fictional, futuristic high-performance vehicle with deliberately original, invented body geometry (not matching any real supercar manufacturer\'s design language) parked in a clean private space, its dramatic low stance and performance-oriented silhouette carrying the recognition on their own. ' + MORPHOLOGY_NEGATIVE_CLAUSE + ' No person.',
    validated_by: [],
    notes: 'v2.5 Wave-C remediation (Part 6). id-exact, narrow automotive grammar.',
  },
};

for (const [id, rule] of Object.entries(NEW_RULES)) {
  if (containment.rules[id]) throw new Error(`Rule id already exists: ${id}`);
  containment.rules[id] = rule;
  containment.rule_id_index.push(id);
}
writeJson(containmentPath, containment);

const ID_OVERRIDES = {
  'transport.classic_cars': { rule: 'classic_car_generic_morphology', reason: 'v2.5 Wave-C remediation: brand-likeness (classic Japanese GT/sports car) fix.' },
  'transport.sports_cars': { rule: 'sports_car_generic_morphology', reason: 'v2.5 Wave-C remediation: brand-likeness (Porsche-911-type) fix.' },
  'transport.supercars': { rule: 'supercar_generic_morphology', reason: 'v2.5 Wave-C remediation: brand-likeness (McLaren-like) fix.' },
};
for (const [id, info] of Object.entries(ID_OVERRIDES)) {
  if (objectFirstRules.id_prefix_overrides.some(o => o.match?.id === id)) throw new Error(`id_prefix_overrides already has an exact-id entry for ${id}`);
  objectFirstRules.id_prefix_overrides.push({
    match: { id },
    protagonist_type: 'machine_process',
    object_first_status: 'containment_required',
    structural_containment_rule_id: info.rule,
    confidence: 'extrapolated',
    rationale: info.reason,
  });
}
writeJson(rulesPath, objectFirstRules);

console.log('Added 3 automotive morphology rules:', Object.keys(NEW_RULES).join(', '));
console.log('Added 3 id-exact routing overrides:', Object.keys(ID_OVERRIDES).join(', '));

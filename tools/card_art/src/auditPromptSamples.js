// Compile a fixed stratified prompt sample for human QA.
// No API calls. No image generation.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';
import { compileHobbyPrompt } from './buildPromptV1.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const readJson = p => JSON.parse(fs.readFileSync(p, 'utf-8'));

const SAMPLE_IDS = [
  'sports.american_football',
  'sports.hiking',
  'lifestyle.game_nights',
  'transport.car_meets',
  'sports.badminton',
  'gaming.chess',
  'wellness.weightlifting',
  'wellness.yoga',
  'outdoors.surfing',
  'outdoors.kayaking',
  'sports.gravel_cycling',
  'lifestyle.gardening',
  'food.yum_cha',
  'motorsport.sim_racing',
  'arts.lion_dance',
  'career.nursing',
  'pets.dog_agility',
  'learning.archaeology',
  'books.reading',
  'history.general',
  'learning.philosophy',
  'wellness.mindfulness',
  'fashion.streetwear',
  'collecting.stamps',
  'transport.railways',
  'learning.model_united_nations',
  'learning.campus_radio',
  'learning.math_olympiad',
  'learning.study_abroad',
  'business.case_competitions',
  'business.founder_meetups',
  'wellness.hot_springs',
  'wellness.sauna',
  'lifestyle.book_swaps',
  'lifestyle.repair_workshops',
  'arts.podcasting',
  'arts.video_editing',
  'arts.vlogging',
  'arts.animation_production',
  'arts.blogging',
  'gaming.game_streaming',
  'gaming.escape_room_design',
  'technology.python',
  'learning.book_genre.booktok',
  'travel.style_deep.unesco_heritage_travel',
];

function main() {
  const specs = path.join(ROOT, 'specs');
  const cat = path.join(ROOT, 'catalog');
  const out = path.join(ROOT, 'generated');

  const globalStyle = readJson(path.join(specs, 'global_style_v1.json'));
  const archetypes = readJson(path.join(specs, 'archetypes_v1.json'));
  const variants = readJson(path.join(specs, 'archetype_variants_v1.json'));
  const categories = readJson(path.join(specs, 'category_modifiers_v1.json'));
  const subcategories = readJson(path.join(specs, 'subcategory_modifiers_v1.json'));
  const overrides = readJson(path.join(cat, 'hobby_overrides_v1.json'));
  const flagship = readJson(path.join(cat, 'flagship_overrides_v1.json'));

  const bridge = buildCatalogRecipeBridge();
  const byId = new Map(bridge.eligible.map(row => [row.canonical_interest_id, row]));
  const samples = [];

  for (const id of SAMPLE_IDS) {
    const row = byId.get(id);
    if (!row) throw new Error(`Stratified sample is missing or no longer baseline-eligible: ${id}`);

    const hobby = row.recipe;
    const overrideKey = row.source_recipe_id || hobby.id;
    const compiled = compileHobbyPrompt({
      hobby,
      globalStyle,
      archetypes,
      variants,
      categories,
      subcategories,
      override: overrides.overrides?.[overrideKey] || null,
      flagshipOverride: flagship.flagship?.[overrideKey] || null,
    });

    samples.push({
      canonical_interest_id: row.canonical_interest_id,
      title: hobby.title,
      runtime_category: row.runtime_category,
      runtime_cluster: row.runtime_cluster,
      art_policy: row.art_policy,
      recipe_source: row.recipe_source,
      source_recipe_id: row.source_recipe_id,
      difficulty: hobby.difficulty || 'normal',
      human_review_required: !!hobby.human_review_required,
      archetype: hobby.archetype,
      visual_variant: compiled.variant.id,
      compiled_prompt: compiled.compiledPrompt,
      negative_constraints: compiled.negativeConstraints,
    });
  }

  fs.mkdirSync(out, { recursive: true });
  const target = path.join(out, 'stratified_prompt_samples_v1.jsonl');
  fs.writeFileSync(target, samples.map(row => JSON.stringify(row)).join('\n') + '\n');
  console.log(`Compiled ${samples.length} stratified prompt samples -> ${target}`);
}

main();

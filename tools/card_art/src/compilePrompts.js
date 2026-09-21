// Compiles catalog recipes to auditable prompt records. No API calls.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { compileHobbyPrompt } from './buildPromptV1.js';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const readJson = p => JSON.parse(fs.readFileSync(p, 'utf-8'));
const readJsonl = p => fs.readFileSync(p, 'utf-8').split('\n').map(x=>x.trim()).filter(Boolean).map(JSON.parse);
function main() {
  const specs = path.join(ROOT,'specs'), cat = path.join(ROOT,'catalog'), out = path.join(ROOT,'generated');
  const globalStyle=readJson(path.join(specs,'global_style_v1.json'));
  const archetypes=readJson(path.join(specs,'archetypes_v1.json'));
  const variants=readJson(path.join(specs,'archetype_variants_v1.json'));
  const categories=readJson(path.join(specs,'category_modifiers_v1.json'));
  const subcategories=readJson(path.join(specs,'subcategory_modifiers_v1.json'));
  const qa=readJson(path.join(specs,'qa_rubric_v1.json'));
  const hobbies=readJsonl(path.join(cat,'hobby_recipes_v1.jsonl'));
  const overrides=readJson(path.join(cat,'hobby_overrides_v1.json'));
  const flagship=readJson(path.join(cat,'flagship_overrides_v1.json'));
  const records=[], failures=[];
  for (const hobby of hobbies) {
    try {
      const o=overrides.overrides?.[hobby.id]||null, f=flagship.flagship?.[hobby.id]||null;
      const c=compileHobbyPrompt({hobby,globalStyle,archetypes,variants,categories,subcategories,override:o,flagshipOverride:f});
      const ruleKey=hobby.tier==='flagship'?'flagship':hobby.difficulty==='hard_case'?'hard_case':hobby.tier==='long_tail'?'long_tail':'common';
      const rule=qa.pass_rules[ruleKey];
      records.push({
        hobby_id:hobby.id,title:hobby.title,tier:hobby.tier,difficulty:hobby.difficulty||'normal',
        human_review_required:!!hobby.human_review_required,
        model_default:globalStyle.default_model,fallback_model:globalStyle.fallback_model,premium_model:globalStyle.premium_model,
        style_reference_path:globalStyle.style_reference_path,
        archetype:hobby.archetype,visual_variant:c.variant.id,category:hobby.category,subcategory:hobby.subcategory,
        compiled_prompt:c.compiledPrompt,negative_constraints:c.negativeConstraints,
        fallback_hint:`reroll on default model if a QA reroll trigger fires OR the image fails the tier/difficulty pass rule (${rule}); then escalate to fallback_model. Use premium_model only when premium rescue is explicitly justified.`,
        qa_notes:hobby.notes||''
      });
    } catch (e) { failures.push({hobby_id:hobby.id,error:e.message}); }
  }
  if (failures.length) { console.error(JSON.stringify(failures,null,2)); process.exit(1); }
  fs.mkdirSync(out,{recursive:true});
  fs.writeFileSync(path.join(out,'compiled_prompts_v1.jsonl'),records.map(x=>JSON.stringify(x)).join('\n')+'\n');
  console.log(`Compiled ${records.length}/${hobbies.length} hobbies`);
}
main();

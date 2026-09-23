// Rights-safe image generation runner for compiled catalog prompts.
//
// Default behavior:
//   - uses catalog/launch_image_batch_v1.json
//   - rebuilds the runtime rights-first recipe bridge in memory
//   - compiles prompts with the structured V1 compiler
//   - generates through reference-free FLUX.2 text-to-image first
//   - refuses any canonical that is not baseline-art eligible
//
// Usage:
//   node src/generateCompiledBatch.js --dry-run
//   node src/generateCompiledBatch.js
//   node src/generateCompiledBatch.js --only=sports.badminton,food.coffee
//   node src/generateCompiledBatch.js --model=fallback --only=technology.ai
//   node src/generateCompiledBatch.js --retry=technology.ai --model=fallback

import 'dotenv/config';
import { fal } from '@fal-ai/client';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildCatalogRecipeBridge } from './catalogRecipeBridge.js';
import { compileHobbyPrompt } from './buildPromptV1.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..', '..');

const BATCH_PATH = path.join(ROOT, 'catalog', 'launch_image_batch_v1.json');
const REFERENCE_PATH = path.join(REPO_ROOT, 'references', 'zync-card-style-reference.png');
const OUTPUT_DIR = path.join(ROOT, 'output', 'launch_v1');
const IMAGES_DIR = path.join(OUTPUT_DIR, 'images');
const MANIFEST_PATH = path.join(OUTPUT_DIR, 'manifest.json');

const COST_USD = {
  'flux-2': 0.0125,
  'flux-2/edit': 0.025,
  'gemini-25-flash-image/edit': 0.039,
  'nano-banana-pro/edit': 0.15,
};

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf-8'));
}

function parseArgs(argv) {
  const args = { only: null, retry: new Set(), dryRun: false, model: 'default' };
  for (const arg of argv) {
    if (arg === '--dry-run') args.dryRun = true;
    else if (arg.startsWith('--only=')) {
      args.only = arg.slice('--only='.length).split(',').map(x => x.trim()).filter(Boolean);
    } else if (arg.startsWith('--retry=')) {
      args.retry = new Set(arg.slice('--retry='.length).split(',').map(x => x.trim()).filter(Boolean));
    } else if (arg.startsWith('--model=')) {
      args.model = arg.slice('--model='.length).trim();
    }
  }
  return args;
}

function falModel(model) {
  return model.startsWith('fal-ai/') ? model : `fal-ai/${model}`;
}

function resolveModel(name, globalStyle) {
  const aliases = {
    default: 'flux-2',
    text: 'flux-2',
    edit: 'flux-2/edit',
    fallback: globalStyle.fallback_model,
    premium: globalStyle.premium_model,
  };
  const resolved = aliases[name] || name;
  if (!Object.hasOwn(COST_USD, resolved)) {
    throw new Error(
      `Unsupported model "${name}". Use default, fallback, premium, or one of: ${Object.keys(COST_USD).join(', ')}`,
    );
  }
  return resolved;
}

function loadManifest() {
  if (!fs.existsSync(MANIFEST_PATH)) {
    return {
      version: 'launch_v1',
      generated_at: null,
      reference_style_path: 'references/zync-card-style-reference.png',
      entries: [],
    };
  }
  return readJson(MANIFEST_PATH);
}

function saveManifest(manifest) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2) + '\n');
}

async function uploadReference() {
  const buffer = fs.readFileSync(REFERENCE_PATH);
  const file = new Blob([buffer], { type: 'image/png' });
  file.name = 'zync-card-style-reference.png';
  return fal.storage.upload(file);
}

function needsReference(model) {
  return model.endsWith('/edit');
}

function promptForModel(prompt, model) {
  if (needsReference(model)) return prompt;
  return prompt
    .split('\n\n')
    .filter(section => !section.startsWith('REFERENCE STYLE:'))
    .join('\n\n');
}

function modelInput(model, prompt, referenceUrl) {
  if (model === 'flux-2') {
    return {
      prompt,
      image_size: { width: 832, height: 1248 },
      num_images: 1,
      output_format: 'png',
    };
  }

  const common = {
    prompt,
    image_urls: [referenceUrl],
    num_images: 1,
    output_format: 'png',
  };
  if (model === 'flux-2/edit') {
    return {
      ...common,
      image_size: { width: 832, height: 1248 },
    };
  }
  if (model === 'gemini-25-flash-image/edit') {
    return {
      ...common,
      aspect_ratio: '2:3',
    };
  }
  if (model === 'nano-banana-pro/edit') {
    return {
      ...common,
      aspect_ratio: '2:3',
      resolution: '2K',
    };
  }
  throw new Error(`No input adapter for model ${model}`);
}

function compileRows(ids) {
  const specs = path.join(ROOT, 'specs');
  const catalog = path.join(ROOT, 'catalog');
  const globalStyle = readJson(path.join(specs, 'global_style_v1.json'));
  const archetypes = readJson(path.join(specs, 'archetypes_v1.json'));
  const variants = readJson(path.join(specs, 'archetype_variants_v1.json'));
  const categories = readJson(path.join(specs, 'category_modifiers_v1.json'));
  const subcategories = readJson(path.join(specs, 'subcategory_modifiers_v1.json'));
  const overrides = readJson(path.join(catalog, 'hobby_overrides_v1.json'));
  const flagship = readJson(path.join(catalog, 'flagship_overrides_v1.json'));

  const bridge = buildCatalogRecipeBridge();
  const eligible = new Map(bridge.eligible.map(row => [row.canonical_interest_id, row]));
  const blocked = new Map(bridge.blocked.map(row => [row.canonical_interest_id, row]));
  const output = [];

  for (const id of ids) {
    if (blocked.has(id)) {
      const row = blocked.get(id);
      throw new Error(
        `Refusing rights-blocked canonical ${id} (policy=${row.art_policy}, reason=${row.reason})`,
      );
    }
    const row = eligible.get(id);
    if (!row) throw new Error(`Unknown or non-eligible canonical interest: ${id}`);

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

    output.push({
      canonical_interest_id: row.canonical_interest_id,
      title: hobby.title,
      runtime_category: row.runtime_category,
      runtime_cluster: row.runtime_cluster,
      art_policy: row.art_policy,
      recipe_source: row.recipe_source,
      source_recipe_id: row.source_recipe_id,
      tier: hobby.tier,
      difficulty: hobby.difficulty || 'normal',
      human_review_required:
        !!hobby.human_review_required || row.art_policy === 'abstractOnly',
      archetype: hobby.archetype,
      visual_variant: compiled.variant.id,
      prompt: compiled.compiledPrompt,
      negative_constraints: compiled.negativeConstraints,
      global_style: globalStyle,
    });
  }
  return output;
}

async function generateOne({ row, model, referenceUrl, attempt }) {
  const finalPrompt = promptForModel(row.prompt, model);
  const result = await fal.subscribe(falModel(model), {
    input: modelInput(model, finalPrompt, referenceUrl),
    logs: false,
  });
  const image = result?.data?.images?.[0];
  if (!image?.url) {
    throw new Error(`No image returned for ${row.canonical_interest_id}`);
  }

  const response = await fetch(image.url);
  if (!response.ok) {
    throw new Error(`Image download failed for ${row.canonical_interest_id}: HTTP ${response.status}`);
  }
  const fileName = `${row.canonical_interest_id.replaceAll('.', '__')}__${model.replaceAll('/', '_').replaceAll('-', '_')}__attempt${attempt}.png`;
  fs.mkdirSync(IMAGES_DIR, { recursive: true });
  const localPath = path.join(IMAGES_DIR, fileName);
  fs.writeFileSync(localPath, Buffer.from(await response.arrayBuffer()));

  return {
    canonical_interest_id: row.canonical_interest_id,
    title: row.title,
    runtime_category: row.runtime_category,
    runtime_cluster: row.runtime_cluster,
    art_policy: row.art_policy,
    recipe_source: row.recipe_source,
    tier: row.tier,
    difficulty: row.difficulty,
    human_review_required: row.human_review_required,
    archetype: row.archetype,
    visual_variant: row.visual_variant,
    model,
    attempt,
    final_prompt: finalPrompt,
    negative_constraints: row.negative_constraints,
    conditioning_mode: needsReference(model) ? 'reference_edit' : 'text_only',
    reference_style_path: needsReference(model)
      ? 'references/zync-card-style-reference.png'
      : null,
    fal_request_id: result?.requestId || null,
    local_image_path: path.relative(REPO_ROOT, localPath).replace(/\\/g, '/'),
    estimated_cost_usd: COST_USD[model],
    generated_at: new Date().toISOString(),
    qa_status: 'pending_human_review',
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const batch = readJson(BATCH_PATH);
  let ids = args.only || batch.ids;
  ids = [...new Set(ids)];

  if (!ids.length) throw new Error('No canonical interest IDs requested.');

  const rows = compileRows(ids);
  const globalStyle = rows[0]?.global_style || readJson(path.join(ROOT, 'specs', 'global_style_v1.json'));
  const model = resolveModel(args.model, globalStyle);
  for (const row of rows) delete row.global_style;

  const cost = COST_USD[model] * rows.length;
  if (args.dryRun) {
    console.log(`Dry run: ${rows.length} rights-safe compiled prompts; model=${model}; estimated first-pass cost=$${cost.toFixed(3)}`);
    for (const row of rows) {
      console.log(
        `\n--- ${row.title} [${row.canonical_interest_id}] / ${row.archetype} / ${row.visual_variant} / ${row.recipe_source} / ${row.difficulty} ---\n${row.prompt}`,
      );
    }
    return;
  }

  if (!process.env.FAL_KEY) {
    throw new Error('FAL_KEY is not set. Use --dry-run or configure tools/card_art/.env.');
  }
  fal.config({ credentials: process.env.FAL_KEY });

  const manifest = loadManifest();
  const referenceUrl = needsReference(model) ? await uploadReference() : null;

  let calls = 0;
  let runCost = 0;
  for (const row of rows) {
    const previous = manifest.entries.filter(
      entry => entry.canonical_interest_id === row.canonical_interest_id && entry.model === model,
    );
    const retry = args.retry.has(row.canonical_interest_id);
    if (previous.length && !retry) {
      console.log(`Skipping ${row.title}: already has ${model} output; use --retry=${row.canonical_interest_id}`);
      continue;
    }
    const attempt = previous.length + 1;
    if (attempt > 2) {
      console.log(`Skipping ${row.title}: max 2 attempts reached for ${model}`);
      continue;
    }

    console.log(`Generating ${row.title} via ${model} (attempt ${attempt})...`);
    try {
      const entry = await generateOne({ row, model, referenceUrl, attempt });
      manifest.entries.push(entry);
      calls += 1;
      runCost += entry.estimated_cost_usd;
      saveManifest(manifest);
      console.log(`  -> ${entry.local_image_path}`);
    } catch (error) {
      console.error(`  !! ${row.title}: ${error.message || error}`);
    }
  }

  manifest.generated_at = new Date().toISOString();
  saveManifest(manifest);
  console.log(
    `Done. API calls=${calls}; estimated run cost=$${runCost.toFixed(3)}; manifest entries=${manifest.entries.length}.`,
  );
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});

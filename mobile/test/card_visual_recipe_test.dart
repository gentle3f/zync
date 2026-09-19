import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/card_visual_recipe.dart';
import 'package:zync/core/interest_entity_metadata.dart';
import 'package:zync/core/interest_catalog.dart';

void main() {
  test('proof batch resolves twelve deterministic representative recipes', () {
    final recipes = CardVisualRecipeResolver.proofBatch();

    expect(recipes, hasLength(12));
    expect(
      recipes.map((item) => item.interestId).toSet(),
      hasLength(12),
    );
    expect(
      recipes.every((item) => item.visualSeed.isNotEmpty),
      isTrue,
    );
    expect(
      recipes.every((item) => item.visualFamily.isNotEmpty),
      isTrue,
    );
    expect(
      recipes.every((item) => item.iconKey.isNotEmpty),
      isTrue,
    );
    expect(
      recipes.every((item) => item.sceneGrammar.isNotEmpty),
      isTrue,
    );
  });

  test('same canonical interest always resolves same visual recipe', () {
    final first =
        CardVisualRecipeResolver.resolve('sports.badminton')!;
    final second =
        CardVisualRecipeResolver.resolve('sports.badminton')!;

    expect(first.visualSeed, second.visualSeed);
    expect(first.categoryKit, second.categoryKit);
    expect(first.visualFamily, second.visualFamily);
    expect(first.sceneGrammar, second.sceneGrammar);
    expect(first.paletteSlot, second.paletteSlot);
  });

  test('palette slot is valid for each category kit', () {
    for (final recipe in CardVisualRecipeResolver.proofBatch()) {
      final kit =
          CardVisualRecipeResolver.categoryKits[recipe.categoryKit]!;
      expect(recipe.paletteSlot, greaterThanOrEqualTo(0));
      expect(recipe.paletteSlot, lessThan(kit.paletteCount));
    }
  });

  test('approved visual families map to expected scene grammars', () {
    expect(
      CardVisualRecipeResolver
          .resolve('sports.badminton')!
          .sceneGrammar,
      'court_arc',
    );
    expect(
      CardVisualRecipeResolver
          .resolve('outdoors.bouldering')!
          .sceneGrammar,
      'climbing_facets',
    );
    expect(
      CardVisualRecipeResolver
          .resolve('media.movies')!
          .sceneGrammar,
      'cinema_frame_light',
    );
    expect(
      CardVisualRecipeResolver
          .resolve('crafts.diy')!
          .sceneGrammar,
      'crafts_cut_paper',
    );
  });

  test('recipe preserves explicit art policy', () {
    final recipe =
        CardVisualRecipeResolver.resolve('media.movies')!;

    expect(recipe.artPolicy, CardArtPolicy.originalGeneric);
  });

  test('unknown or unapproved interests do not silently get generated', () {
    expect(
      CardVisualRecipeResolver.resolve('anime.jojo'),
      isNull,
    );
    expect(
      CardVisualRecipeResolver.resolve('not.a.real.interest'),
      isNull,
    );
  });

  test('expanded proof batch resolves exactly fifty balanced recipes', () {
    final recipes = CardVisualRecipeResolver.expandedProofBatch();

    expect(recipes, hasLength(50));
    expect(
      recipes.map((item) => item.interestId).toSet(),
      hasLength(50),
    );
    expect(
      recipes.map((item) => item.categoryKit).toSet(),
      hasLength(15),
    );
    expect(
      recipes.map((item) => item.visualFamily).toSet().length,
      greaterThanOrEqualTo(30),
    );
    expect(
      recipes.map((item) => item.visualSeed).toSet(),
      hasLength(50),
    );
  });

  test('all fifty proof interests exist and keep both Chinese scripts', () {
    for (final recipe in CardVisualRecipeResolver.expandedProofBatch()) {
      final item = InterestCatalog.byId(recipe.interestId);
      expect(
        item,
        isNotNull,
        reason: 'Missing canonical interest: ${recipe.interestId}',
      );
      expect(
        item!.labels['zh-Hant']?.trim(),
        isNotEmpty,
        reason: '${recipe.interestId} missing zh-Hant',
      );
      expect(
        item.labels['zh-Hans']?.trim(),
        isNotEmpty,
        reason: '${recipe.interestId} missing zh-Hans',
      );
    }
  });

  test('expanded proof batch is a superset of the twelve-card review set', () {
    final reviewIds = CardVisualRecipeResolver.proofBatch()
        .map((item) => item.interestId)
        .toSet();
    final expandedIds = CardVisualRecipeResolver.expandedProofBatch()
        .map((item) => item.interestId)
        .toSet();

    expect(expandedIds.containsAll(reviewIds), isTrue);
  });

  test('category registry covers every proof recipe kit', () {
    final kits = CardVisualRecipeResolver.categoryKits.keys.toSet();

    for (final recipe in CardVisualRecipeResolver.proofBatch()) {
      expect(kits, contains(recipe.categoryKit));
    }
  });
}

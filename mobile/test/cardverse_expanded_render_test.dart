import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/card_visual_recipe.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/widgets/zync_card_preview.dart';

void main() {
  testWidgets(
      'all fifty expanded proof cards render in English and Traditional Chinese',
      (tester) async {
    final recipes = CardVisualRecipeResolver.expandedProofBatch();
    const finishes = CardFinishTier.values;

    for (final locale in const ['en', 'zh-Hant']) {
      for (var index = 0; index < recipes.length; index += 1) {
        final recipe = recipes[index];
        final interest = InterestCatalog.byId(recipe.interestId)!;
        final title = interest.labelFor(locale);

        await tester.pumpWidget(
          MaterialApp(
            locale: locale == 'en'
                ? const Locale('en')
                : const Locale('zh', 'HK'),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 220,
                  height: 308,
                  child: ZyncCardPreview(
                    recipe: recipe,
                    title: title,
                    subtitle:
                        '${recipe.categoryKit} · ${recipe.visualFamily}',
                    finish: finishes[index % finishes.length],
                    editionLabel: 'CORE',
                    cardNumberLabel: 'PROOF',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.text(title),
          findsOneWidget,
          reason:
              '${recipe.interestId} should render in $locale',
        );
        expect(
          tester.takeException(),
          isNull,
          reason:
              '${recipe.interestId} overflowed or threw in $locale',
        );
      }
    }
  });

  testWidgets('new category scene kits render without exceptions',
      (tester) async {
    const samples = {
      'travel.japan': CardFinishTier.holo,
      'technology.ai': CardFinishTier.prism,
      'outdoors.stargazing': CardFinishTier.legendary,
      'collecting.lego': CardFinishTier.foil,
      'motorsport.formula1': CardFinishTier.secret,
      'music.piano': CardFinishTier.holo,
      'gaming.board': CardFinishTier.prism,
      'learning.languages': CardFinishTier.legendary,
      'crafts.knitting': CardFinishTier.foil,
    };

    for (final entry in samples.entries) {
      final recipe = CardVisualRecipeResolver.resolve(entry.key)!;
      final title = InterestCatalog.byId(entry.key)!.labelFor('zh-Hant');

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh', 'HK'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 350,
                child: ZyncCardPreview(
                  recipe: recipe,
                  title: title,
                  subtitle: recipe.sceneGrammar,
                  finish: entry.value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(title), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: '${entry.key} scene failed to render',
      );
    }
  });
}

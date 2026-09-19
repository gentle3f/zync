import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/card_visual_recipe.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/widgets/zync_card_preview.dart';

void main() {
  const titles = <String, String>{
    'sports.badminton': 'Badminton',
    'sports.basketball': 'Basketball',
    'outdoors.bouldering': 'Bouldering',
    'food.coffee': 'Coffee',
    'food.cooking': 'Cooking',
    'wellness.yoga': 'Yoga',
    'photography.general': 'Photography',
    'media.movies': 'Film & Cinema',
    'music.pop': 'Pop Music',
    'gaming.video': 'Video Games',
    'books.reading': 'Reading',
    'crafts.diy': 'DIY & Crafts',
  };

  testWidgets('all twelve proof recipes render at collectible card size',
      (tester) async {
    for (final recipe in CardVisualRecipeResolver.proofBatch()) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 350,
                child: ZyncCardPreview(
                  recipe: recipe,
                  title: titles[recipe.interestId]!,
                  subtitle:
                      '${recipe.categoryKit} · ${recipe.visualFamily}',
                  cardNumberLabel: 'PREVIEW',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(titles[recipe.interestId]!), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('long Traditional Chinese title stays bounded', (tester) async {
    final recipe =
        CardVisualRecipeResolver.resolve('photography.general')!;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'HK'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              height: 308,
              child: ZyncCardPreview(
                recipe: recipe,
                title: '街頭攝影與城市生活紀錄',
                subtitle: '藝術 · 攝影',
                finish: CardFinishTier.holo,
                editionLabel: 'CORE',
                cardNumberLabel: 'PREVIEW',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('街頭攝影與城市生活紀錄'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finish overlays render without changing base recipe',
      (tester) async {
    final recipe =
        CardVisualRecipeResolver.resolve('sports.badminton')!;

    for (final finish in [
      CardFinishTier.normal,
      CardFinishTier.foil,
      CardFinishTier.holo,
      CardFinishTier.prism,
      CardFinishTier.legendary,
      CardFinishTier.secret,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 350,
                child: ZyncCardPreview(
                  recipe: recipe,
                  title: 'Badminton',
                  subtitle: 'Sports · Racket Sports',
                  finish: finish,
                  editionLabel: 'CORE',
                  cardNumberLabel: 'PREVIEW',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Badminton'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Encounter label can render on same base card', (tester) async {
    final recipe =
        CardVisualRecipeResolver.resolve('sports.basketball')!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              height: 350,
              child: ZyncCardPreview(
                recipe: recipe,
                title: 'Basketball',
                subtitle: 'Discovered through a Zync',
                finish: CardFinishTier.foil,
                editionLabel: 'ENCOUNTER',
                cardNumberLabel: 'MEMORY',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ENCOUNTER'), findsOneWidget);
    expect(find.text('Discovered through a Zync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

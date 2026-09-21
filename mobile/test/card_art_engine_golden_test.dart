import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/card_visual_recipe.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/widgets/zync_card_preview.dart';

void main() {
  testWidgets('renders scalable Card Art Engine flagship proof sheet',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 380);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recipes = CardVisualRecipeResolver.flagshipPrototypeBatch();
    const titles = <String, String>{
      'travel.roadtrip': 'ROAD TRIP',
      'sports.badminton': 'BADMINTON',
      'food.coffee': 'COFFEE',
      'technology.ai': 'AI',
      'gaming.board': 'BOARD GAMES',
    };
    const subtitles = <String, String>{
      'travel.roadtrip': 'Freedom · Road · Explore',
      'sports.badminton': 'Speed · Rally · Connect',
      'food.coffee': 'Ritual · Warmth · Conversation',
      'technology.ai': 'Curiosity · Create · Future',
      'gaming.board': 'Strategy · Laughter · Together',
    };
    const finishes = <CardFinishTier>[
      CardFinishTier.normal,
      CardFinishTier.foil,
      CardFinishTier.holo,
      CardFinishTier.prism,
      CardFinishTier.legendary,
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0E1B2A),
          body: Center(
            child: RepaintBoundary(
              key: const ValueKey('card-art-engine-proof-sheet'),
              child: Container(
                color: const Color(0xFF0E1B2A),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < recipes.length; i++) ...[
                      SizedBox(
                        width: 205,
                        height: 287,
                        child: ZyncCardPreview(
                          recipe: recipes[i],
                          title: titles[recipes[i].interestId]!,
                          subtitle: subtitles[recipes[i].interestId]!,
                          finish: finishes[i],
                          editionLabel: 'CORE',
                          cardNumberLabel:
                              'F${(i + 1).toString().padLeft(2, '0')}',
                        ),
                      ),
                      if (i != recipes.length - 1)
                        const SizedBox(width: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const ValueKey('card-art-engine-proof-sheet')),
      matchesGoldenFile('goldens/card_art_engine_v1_flagships.png'),
    );
  });
}

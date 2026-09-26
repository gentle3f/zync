import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/card_fx/card_fx_spec.dart';
import 'package:zync/screens/card_fx_lab_screen.dart';

void main() {
  test('rarity profiles scale visual intensity monotonically', () {
    final profiles = ZyncFxRarity.values
        .map(ZyncCardFxProfile.forRarity)
        .toList(growable: false);

    for (var i = 1; i < profiles.length; i++) {
      expect(
        profiles[i].edgeGlowOpacity,
        greaterThanOrEqualTo(profiles[i - 1].edgeGlowOpacity),
      );
      expect(
        profiles[i].foilOpacity,
        greaterThanOrEqualTo(profiles[i - 1].foilOpacity),
      );
      expect(
        profiles[i].particleCount,
        greaterThanOrEqualTo(profiles[i - 1].particleCount),
      );
    }
  });

  test('all five rarities resolve to distinct locked frame assets', () {
    final assets = ZyncFxRarity.values
        .map(ZyncFrameAssets.forRarity)
        .toList(growable: false);

    expect(assets, hasLength(5));
    expect(assets.toSet(), hasLength(5));
    for (final asset in assets) {
      expect(asset, startsWith('assets/card_fx/frames/master/'));
      expect(asset, endsWith('_master_v1.png'));
    }
    for (final sample in cardFxLabSamples) {
      expect(
          sample.resolvedFrameAsset, ZyncFrameAssets.forRarity(sample.rarity));
    }
  });

  test('lab samples use three distinct accepted production artworks', () {
    expect(cardFxLabSamples, hasLength(3));
    expect(
      cardFxLabSamples.map((item) => item.id).toSet(),
      {
        'books.reading',
        'technology.ai',
        'food.coffee',
      },
    );
    expect(
      cardFxLabSamples.map((item) => item.artworkAsset).toSet().length,
      3,
    );
  });

  testWidgets('Card FX Lab exposes inspect, reveal and tuning controls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CardFxLabScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Card FX Lab'), findsOneWidget);
    expect(find.text('Inspect'), findsOneWidget);
    expect(find.text('Draw reveal'), findsOneWidget);
    expect(find.text('Coffee · LEGENDARY'), findsOneWidget);
    expect(find.text('FX Debug Panel'), findsOneWidget);
    expect(find.text('Foil intensity'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('COMMON'), findsOneWidget);

    await tester.tap(find.text('COMMON'));
    await tester.pump();

    expect(find.text('COMMON PROFILE'), findsOneWidget);

    await tester.tap(find.text('Artificial Intelligence · RARE'));
    await tester.pump();

    expect(find.text('RARE PROFILE'), findsOneWidget);

    final drawRevealButton =
        find.byKey(const ValueKey('fx-draw-reveal-button'));
    await tester.tap(drawRevealButton);
    await tester.pump();

    final replayButton = find.byKey(const ValueKey('fx-replay-button'));
    expect(replayButton, findsOneWidget);
    expect(
      find.byKey(const ValueKey('fx-reveal-technology.ai-rare-3')),
      findsOneWidget,
    );

    await tester.tap(drawRevealButton);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('fx-reveal-technology.ai-rare-4')),
      findsOneWidget,
    );

    await tester.tap(replayButton);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('fx-reveal-technology.ai-rare-4')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fx-reveal-technology.ai-rare-5')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

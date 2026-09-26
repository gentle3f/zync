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
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const CardFxLabScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Card FX Lab'), findsOneWidget);
    expect(find.text('Inspect'), findsOneWidget);
    expect(find.text('Open pack'), findsOneWidget);
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

    expect(find.text('Tear Up'), findsOneWidget);
    expect(find.text('Split Open'), findsOneWidget);
    expect(find.text('Charge Burst'), findsOneWidget);
    expect(find.text('Seal Slide'), findsOneWidget);
    expect(find.byKey(const ValueKey('pack-choice-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('pack-choice-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pack-choice-2')), findsOneWidget);

    final middlePack = find.byKey(const ValueKey('pack-choice-1'));
    await tester.ensureVisible(middlePack);
    await tester.pump();
    await tester.tap(middlePack);
    await tester.pump();
    final tearGesture = find.byKey(const ValueKey('opening-gesture-tear-up'));
    expect(tearGesture, findsOneWidget);
    expect(
      find.byKey(const ValueKey('opening-card-extraction-back')),
      findsNothing,
    );
    await tester.ensureVisible(tearGesture);
    await tester.pump();

    await tester.drag(tearGesture, const Offset(0, -180));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));

    // The wrapper opens first; only then may the real card back emerge.
    expect(
      find.byKey(const ValueKey('opening-card-extraction-back')),
      findsOneWidget,
    );
    // The Lab must still animate even when the host OS reports reduced motion.
    expect(find.text('Z'), findsOneWidget);

    final replayButton = find.byKey(const ValueKey('fx-replay-button'));
    expect(replayButton, findsOneWidget);
    await tester.ensureVisible(replayButton);
    await tester.pump();
    await tester.tap(replayButton);
    await tester.pump();
    expect(find.byKey(const ValueKey('pack-choice-0')), findsOneWidget);

    // B keeps the physical card back behind the wrapper before commit, then
    // reveals it only through the widening center clip while the drag is held.
    await tester.tap(find.text('Split Open'));
    await tester.pump();
    final splitPack = find.byKey(const ValueKey('pack-choice-1'));
    await tester.tap(splitPack);
    await tester.pump();

    final splitGesture =
        find.byKey(const ValueKey('opening-gesture-split-open'));
    expect(splitGesture, findsOneWidget);
    expect(
      find.byKey(const ValueKey('opening-split-preextract-back')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('opening-split-card-window')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('opening-card-extraction-back')),
      findsNothing,
    );

    final splitWindow = find.byKey(const ValueKey('opening-split-card-window'));
    Rect currentSplitClip() {
      final clip = tester.widget<ClipRect>(splitWindow);
      return clip.clipper!.getClip(const Size(390, 620));
    }

    expect(currentSplitClip().width, 0);
    final splitDetector = tester.widget<GestureDetector>(splitGesture);
    splitDetector.onHorizontalDragStart?.call(
      DragStartDetails(globalPosition: tester.getCenter(splitGesture)),
    );
    // Apply an actual ~14% B pull: just beyond the foil-separation threshold.
    splitDetector.onHorizontalDragUpdate?.call(
      DragUpdateDetails(
        delta: const Offset(20, 0),
        primaryDelta: 20,
        globalPosition: tester.getCenter(splitGesture) + const Offset(20, 0),
      ),
    );
    await tester.pump();
    final earlyClip = currentSplitClip();
    expect(earlyClip.width, greaterThan(10));
    expect(earlyClip.width, lessThan(40));

    splitDetector.onHorizontalDragUpdate?.call(
      DragUpdateDetails(
        delta: const Offset(42, 0),
        primaryDelta: 42,
        globalPosition: tester.getCenter(splitGesture) + const Offset(62, 0),
      ),
    );
    await tester.pump();
    final widerClip = currentSplitClip();
    expect(widerClip.width, greaterThan(earlyClip.width));
    expect(
      find.byKey(const ValueKey('opening-split-preextract-back')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('opening-card-extraction-back')),
      findsNothing,
    );
    splitDetector.onHorizontalDragEnd?.call(DragEndDetails());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

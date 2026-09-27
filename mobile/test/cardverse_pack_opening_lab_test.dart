import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/card_fx/card_fx_spec.dart';
import 'package:zync/card_fx/zync_fx_card.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/screens/cardverse_pack_opening_lab_screen.dart';
import 'package:zync/widgets/zync_card_preview.dart';

Widget lab({
  int revealedCount = 0,
  bool reduceMotion = false,
}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: CardversePackOpeningLabScreen(
          initialRevealedCount: revealedCount,
        ),
      ),
    );

Widget playerPack({bool reduceMotion = true}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: const CardversePackOpeningLabScreen(
          labMode: false,
        ),
      ),
    );

void setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('sealed pack does not reveal committed card names',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(lab(reduceMotion: true));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('pack-lab-sealed')),
      findsOneWidget,
    );
    expect(find.text('Badminton'), findsNothing);
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('Bouldering'), findsNothing);
    expect(find.text('Piano'), findsNothing);
    expect(find.text('Japan'), findsNothing);
    expect(find.textContaining('server result locked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player pack uses production Split Open before receipt reveal',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(playerPack());
    await tester.pump();

    expect(find.text('RECEIPT'), findsNothing);
    expect(find.textContaining('server result locked'), findsNothing);
    expect(
      find.byKey(const ValueKey('pack-production-split-open')),
      findsOneWidget,
    );
    expect(find.text('CHOOSE A PACK'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pack-choice-1')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('opening-gesture-split-open')),
      findsOneWidget,
    );

    final splitGesture =
        find.byKey(const ValueKey('opening-gesture-split-open'));
    final detector = tester.widget<GestureDetector>(splitGesture);
    detector.onHorizontalDragStart?.call(
      DragStartDetails(globalPosition: tester.getCenter(splitGesture)),
    );
    detector.onHorizontalDragUpdate?.call(
      DragUpdateDetails(
        delta: const Offset(20, 0),
        primaryDelta: 20,
        globalPosition: tester.getCenter(splitGesture) + const Offset(20, 0),
      ),
    );
    await tester.pump();

    final splitWindow =
        find.byKey(const ValueKey('opening-split-card-window'));
    final earlyClip = tester
        .widget<ClipRect>(splitWindow)
        .clipper!
        .getClip(const Size(390, 620));
    expect(earlyClip.width, greaterThan(10));
    expect(earlyClip.width, lessThan(40));
    expect(
      find.byKey(const ValueKey('opening-split-preextract-back')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('opening-card-stack-5')),
      findsOneWidget,
    );
    for (var depth = 0; depth < 5; depth++) {
      expect(
        find.byKey(ValueKey('opening-card-stack-layer-${depth}')),
        findsOneWidget,
      );
    }

    detector.onHorizontalDragUpdate?.call(
      DragUpdateDetails(
        delta: const Offset(84, 0),
        primaryDelta: 84,
        globalPosition: tester.getCenter(splitGesture) + const Offset(104, 0),
      ),
    );
    await tester.pump();

    detector.onHorizontalDragEnd?.call(DragEndDetails());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('opening-card-extraction-back')),
      findsOneWidget,
    );
    expect(find.text('DRAWING STACK'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('0 / 5'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pack-reveal-stack')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pack-reveal-stack-back-4')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('pack-lab-reveal-next-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduce Motion reveals the five receipt cards and reaches recap',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(lab(reduceMotion: true));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pack-lab-open')));
    await tester.pumpAndSettle();

    expect(find.text('0 / 5'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pack-reveal-stack')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pack-reveal-stack-back-4')),
      findsOneWidget,
    );

    final expected = [
      for (final id in const [
        'sports.badminton',
        'food.coffee',
        'outdoors.bouldering',
        'music.piano',
        'travel.japan',
      ])
        InterestCatalog.byId(id)!.labelFor('en'),
    ];

    for (var i = 0; i < expected.length; i++) {
      await tester.tap(
        find.byKey(ValueKey('pack-lab-reveal-next-$i')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(expected[i]), findsOneWidget);
      expect(find.text('${i + 1} / 5'), findsWidgets);
      final remaining = expected.length - (i + 1);
      if (remaining > 0) {
        expect(
          find.byKey(ValueKey('pack-reveal-stack-back-${remaining - 1}')),
          findsOneWidget,
        );
      } else {
        expect(
          find.byKey(const ValueKey('pack-reveal-stack-back-0')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    }

    expect(
      find.byKey(const ValueKey('pack-lab-recap-button')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('pack-lab-recap-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pack-lab-recap')),
      findsOneWidget,
    );
    for (final title in expected) {
      expect(find.text(title), findsOneWidget);
    }
    final rollId = find.byKey(
      const ValueKey('pack-lab-server-roll-id'),
    );
    await tester.scrollUntilVisible(
      rollId,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(rollId, findsOneWidget);
    expect(find.text('serverRollId: proof-server-roll-1'), findsOneWidget);
  });

  testWidgets('resume at three of five continues with committed fourth card',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      lab(
        revealedCount: 3,
        reduceMotion: true,
      ),
    );
    await tester.pump();

    expect(find.text('3 / 5'), findsWidgets);
    expect(find.text('Bouldering'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('pack-lab-reveal-next-3')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Piano'), findsOneWidget);
    expect(find.text('4 / 5'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focused Holo reveal uses the formal locked-frame renderer',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      lab(
        revealedCount: 3,
        reduceMotion: false,
      ),
    );
    await tester.pump();

    expect(find.text('Bouldering'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('cardverse-formal-card-outdoors.bouldering'),
      ),
      findsOneWidget,
    );
    final focusedCard = tester.widget<ZyncFxCard>(find.byType(ZyncFxCard));
    expect(focusedCard.spec.resolvedFrameAsset, ZyncFrameAssets.rare);
    expect(focusedCard.artworkOverride, isNotNull);
    expect(find.byType(ZyncCardPreview), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player recap has an explicit return to My Zync World',
      (tester) async {
    setPhone(tester);
    tester.view.physicalSize = const Size(430, 1800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: const CardversePackOpeningLabScreen(
          initialRevealedCount: 5,
          labMode: false,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('pack-player-return-world')),
      findsOneWidget,
    );
    expect(find.text('Back to My Zync World'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fully revealed resume goes straight to immutable recap',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      lab(
        revealedCount: 5,
        reduceMotion: true,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('pack-lab-recap')),
      findsOneWidget,
    );
    expect(find.text('Pack complete'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('pack-recap-card-travel.japan'),
      ),
      findsOneWidget,
    );
    expect(find.byType(ZyncFxCard), findsNWidgets(5));
    expect(find.byType(ZyncCardPreview), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

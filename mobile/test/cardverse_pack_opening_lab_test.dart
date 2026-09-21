import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/screens/cardverse_pack_opening_lab_screen.dart';

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

  testWidgets('player pack hides receipt diagnostics and uses player copy',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(playerPack());
    await tester.pump();

    expect(find.text('RECEIPT'), findsNothing);
    expect(find.textContaining('server result locked'), findsNothing);
    expect(
      find.text('5 cards · reveal them one by one'),
      findsOneWidget,
    );
    expect(find.text('Open Pack'), findsWidgets);
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
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(expected[i]), findsOneWidget);
      expect(find.text('${i + 1} / 5'), findsWidgets);
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

  testWidgets('focused Holo reveal uses animated finish with motion enabled',
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
      find.byKey(const ValueKey('card-finish-animated')),
      findsOneWidget,
    );
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
    expect(tester.takeException(), isNull);
  });
}

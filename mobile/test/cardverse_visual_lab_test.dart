import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/screens/cardverse_visual_lab_screen.dart';

void main() {
  testWidgets('Cardverse visual lab exposes twelve proof cards',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh', 'HK'),
        home: CardverseVisualLabScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Cardverse Visual Lab'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('card-lab-item-sports.badminton'),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey('card-lab-item-crafts.diy'),
      ),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('card-lab-item-crafts.diy'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Holo proof card opens focus animation and can switch finish',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: CardverseVisualLabScreen(),
      ),
    );
    await tester.pump();

    final target = find.byKey(
      const ValueKey('card-lab-item-sports.badminton'),
    );
    expect(target, findsOneWidget);
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      find.byKey(const ValueKey('cardverse-card-detail')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('finish-chip-holo')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('card-finish-animated')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('finish-chip-legendary')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final legendary = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('finish-chip-legendary')),
    );
    expect(legendary.selected, isTrue);
    expect(tester.takeException(), isNull);
  });
}

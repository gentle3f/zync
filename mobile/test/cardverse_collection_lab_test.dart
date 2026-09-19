import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/screens/cardverse_collection_lab_screen.dart';

void setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('binder lab exposes owned missing encounter and want-to-try views',
      (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: CardverseCollectionLabScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('collection-discovered-count')),
      findsOneWidget,
    );
    expect(find.text('37 / 50 discovered'), findsOneWidget);
    expect(find.textContaining('13 missing'), findsWidgets);
    expect(find.textContaining('4 Encounter'), findsWidgets);
    expect(find.textContaining('5 Want to Try'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('collection-filter-missing')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('binder-missing-sports.badminton'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('binder-card-sports.basketball'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('collection-filter-owned')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('binder-card-sports.basketball'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('collection-filter-wantToTry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('binder-card-outdoors.bouldering'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('card detail can add a discovered hobby to Want to Try',
      (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: CardverseCollectionLabScreen(),
      ),
    );
    await tester.pump();

    final coffee = find.byKey(
      const ValueKey('binder-card-food.coffee'),
    );
    await tester.ensureVisible(coffee);
    await tester.tap(coffee);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('collection-card-detail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('card-finish-animated')),
      findsOneWidget,
    );
    expect(find.text('Add to Want to Try'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('collection-want-to-try-toggle')),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('In Want to Try'), findsOneWidget);
    expect(find.textContaining('6 Want to Try'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Encounter proof card is visibly soulbound in detail',
      (tester) async {
    setPhoneSurface(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: CardverseCollectionLabScreen(),
      ),
    );
    await tester.pump();

    final basketball = find.byKey(
      const ValueKey('binder-card-sports.basketball'),
    );
    await tester.tap(basketball);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Encounter · Soulbound'), findsOneWidget);
    expect(find.text('ENCOUNTER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

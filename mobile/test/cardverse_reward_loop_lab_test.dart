import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/screens/cardverse_reward_loop_lab_screen.dart';

void setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('reward loop starts with eligibility but no minted reward',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: CardverseRewardLoopLabScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Cardverse Reward Loop Lab'), findsOneWidget);
    expect(find.text('MOCK SERVER'), findsOneWidget);
    expect(find.textContaining('weekly_real_world_three'), findsWidgets);
    expect(find.textContaining('3 bounded IDs'), findsOneWidget);
    expect(
      find.text('No rewardKind, amount, packId, cards or finish.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reward-loop-open-pack')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mock server grant creates one unopened standard pack',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: CardverseRewardLoopLabScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('reward-loop-simulate-server')),
    );
    await tester.pump();

    expect(find.text('standardPack'), findsOneWidget);
    expect(find.text('lab-server-pack-1'), findsWidgets);
    expect(
      find.byKey(const ValueKey('reward-loop-open-pack')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('server-issued pack enters the receipt-driven sealed Pack Lab',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: CardverseRewardLoopLabScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('reward-loop-simulate-server')),
    );
    await tester.pump();

    final openButton =
        find.byKey(const ValueKey('reward-loop-open-pack'));
    await tester.ensureVisible(openButton);
    await tester.tap(openButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Cardverse Pack Lab'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pack-lab-sealed')),
      findsOneWidget,
    );
    expect(find.text('Badminton'), findsNothing);
    expect(find.text('Sushi'), findsNothing);
    expect(find.text('Artificial Intelligence'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/screens/reward_reveal_test_screen.dart';

void main() {
  void setPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
  }

  testWidgets('reward lab exposes separate single and five-card flows',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: RewardRevealTestScreen()),
    );
    await tester.pump();

    expect(find.text('Single Draw — 1 Card'), findsOneWidget);
    expect(find.text('Pack Opening — 5 Cards'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reward-lab-google-diagnostics')),
      findsOneWidget,
    );
  });

  testWidgets('single draw test never enters pack wrapper', (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: RewardRevealTestScreen()),
    );

    await tester.tap(find.text('Test Single Draw'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('single-draw-card-back')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pack-production-split-open')),
      findsNothing,
    );
    expect(find.text('One card is ready'), findsOneWidget);
  });

  testWidgets('five-card test enters production Split Open with five-card stack',
      (tester) async {
    setPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: RewardRevealTestScreen()),
    );

    await tester.tap(find.text('Test 5-Card Pack'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('pack-production-split-open')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('pack-choice-1')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('opening-card-stack-5')),
      findsOneWidget,
    );
    expect(find.text('CHOOSE A PACK'), findsNothing);
  });
}

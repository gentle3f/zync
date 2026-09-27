import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/widgets/cardverse_single_draw_reveal.dart';

void main() {
  testWidgets('single draw stays face-down until the player reveals it',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final receipt = CardverseSingleDrawReceipt.serverValidated(
      drawId: 'draw-proof-1',
      idempotencyKey: 'draw-proof-idempotency-1',
      rolledAt: DateTime.utc(2026, 9, 27, 6),
      item: const CardversePackResultItem(
        variant: CardVariantKey(
          interestId: 'sports.badminton',
          finishId: 'normal',
          editionId: 'core_set_1',
        ),
        quantity: 1,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showCardverseSingleDrawReveal(
                      context: context,
                      receipt: receipt,
                      locale: 'en',
                    );
                  },
                  child: const Text('Open draw'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open draw'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('single-draw-card-back')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('single-draw-card-front')),
      findsNothing,
    );
    expect(find.text('Badminton'), findsNothing);
    expect(find.text('One card is ready'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('single-draw-reveal-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('single-draw-card-back')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('single-draw-card-front')),
      findsOneWidget,
    );
    expect(find.text('Badminton'), findsOneWidget);
    expect(find.text('You drew a card'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('single-draw-close')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

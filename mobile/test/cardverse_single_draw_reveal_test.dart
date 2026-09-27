import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/card_fx/card_fx_spec.dart';
import 'package:zync/card_fx/zync_fx_card.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/widgets/cardverse_single_draw_reveal.dart';
import 'package:zync/widgets/zync_card_preview.dart';

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
    final zCorrection = tester.widget<Transform>(
      find.byKey(const ValueKey('card-back-z-optical-center')),
    );
    expect(zCorrection.transform.storage[12], closeTo(-4, 0.01));
    expect(
      find.byKey(const ValueKey('pack-production-split-open')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('opening-card-stack-5')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('pack-reveal-stack')),
      findsNothing,
    );
    expect(find.text('Badminton'), findsNothing);
    expect(find.text('One card is ready'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('single-draw-reveal-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 320));

    expect(
      find.byKey(const ValueKey('single-draw-card-back')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('single-draw-card-front')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cardverse-formal-card-sports.badminton')),
      findsOneWidget,
    );
    final formalCard = tester.widget<ZyncFxCard>(find.byType(ZyncFxCard));
    expect(formalCard.spec.resolvedFrameAsset, ZyncFrameAssets.common);
    expect(formalCard.artworkOverride, isA<ZyncCardArtwork>());
    expect(find.byType(ZyncCardPreview), findsNothing);
    expect(find.text('Badminton'), findsOneWidget);
    expect(find.text('You drew a card'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('single-draw-close')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

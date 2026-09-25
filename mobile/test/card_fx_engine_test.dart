import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zync/card_fx/card_fx_profile.dart';
import 'package:zync/card_fx/card_fx_surface.dart';
import 'package:zync/core/cardverse_models.dart';

void main() {
  test('rarity profiles escalate foil and reveal intensity', () {
    final normal = CardFxProfile.forFinish(CardFinishTier.normal);
    final rare = CardFxProfile.forFinish(CardFinishTier.holo);
    final epic = CardFxProfile.forFinish(CardFinishTier.prism);
    final legendary = CardFxProfile.forFinish(CardFinishTier.legendary);

    expect(normal.foilOpacity, 0);
    expect(rare.foilOpacity, greaterThan(normal.foilOpacity));
    expect(epic.foilOpacity, greaterThan(rare.foilOpacity));
    expect(legendary.foilOpacity, greaterThan(epic.foilOpacity));
    expect(legendary.particleCount, greaterThan(epic.particleCount));
    expect(
      legendary.revealDuration,
      greaterThan(epic.revealDuration),
    );
  });

  testWidgets('interactive surface accepts drag without changing card child',
      (tester) async {
    const cardKey = ValueKey('fx-test-card');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              height: 350,
              child: ZyncCardFxSurface(
                finish: CardFinishTier.holo,
                ambientFx: CardAmbientFx.dust,
                child: ColoredBox(
                  key: cardKey,
                  color: Colors.indigo,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(cardKey), findsOneWidget);
    final surface = find.byKey(const ValueKey('card-fx-interactive-surface'));
    expect(surface, findsOneWidget);

    await tester.drag(surface, const Offset(40, 24));
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.byKey(cardKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reveal supports Reduce Motion static fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 350,
                child: ZyncCardReveal(
                  finish: CardFinishTier.legendary,
                  ambientFx: CardAmbientFx.embers,
                  enableHaptics: false,
                  front: ColoredBox(
                    key: ValueKey('fx-reveal-front'),
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('fx-reveal-front')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/card_visual_recipe.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/widgets/zync_card_preview.dart';

Widget card({
  required bool animate,
  bool reduceMotion = false,
  CardFinishTier finish = CardFinishTier.holo,
}) {
  final recipe =
      CardVisualRecipeResolver.resolve('sports.badminton')!;
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 250,
            height: 350,
            child: ZyncCardPreview(
              recipe: recipe,
              title: 'Badminton',
              subtitle: 'Sports · Racket Sports',
              finish: finish,
              animateFinish: animate,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('binder/grid Holo stays static by default', (tester) async {
    await tester.pumpWidget(card(animate: false));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('card-finish-static')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('card-finish-animated')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('focused Holo uses animated finish layer', (tester) async {
    await tester.pumpWidget(card(animate: true));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('card-finish-animated')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.byKey(const ValueKey('card-finish-animated')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduce Motion forces focused Holo back to static finish',
      (tester) async {
    await tester.pumpWidget(
      card(
        animate: true,
        reduceMotion: true,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('card-finish-static')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('card-finish-animated')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Foil remains static even when focus animation is requested',
      (tester) async {
    await tester.pumpWidget(
      card(
        animate: true,
        finish: CardFinishTier.foil,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('card-finish-static')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('card-finish-animated')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

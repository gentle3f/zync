import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_entity_metadata.dart';
import 'package:zync/core/zync_now_constraints_transport.dart';
import 'package:zync/widgets/zync_now_constraints_form.dart';

void main() {
  testWidgets(
      'private Zync Now form keeps low-friction defaults and maps hard veto',
      (tester) async {
    ZyncNowPrivateContext? submitted;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZyncNowConstraintsForm(
              onSubmit: (context) async {
                submitted = context;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flexible'), findsOneWidget);
    expect(find.text('Either'), findsOneWidget);
    expect(find.text('Mix it up'), findsOneWidget);
    expect(find.text('No sports'), findsOneWidget);

    await tester.tap(find.text('Free'));
    await tester.tap(find.text('No sports'));
    await tester.pump();

    await tester.ensureVisible(find.text('Lock my preferences'));
    await tester.tap(find.text('Lock my preferences'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(
      submitted!.constraints.duration,
      ActivityDurationBand.flexible,
    );
    expect(
      submitted!.constraints.maxCost,
      ActivityCostBand.free,
    );
    expect(submitted!.constraints.energy, isNull);
    expect(
      submitted!.constraints.setting,
      ActivitySetting.either,
    );
    expect(
      submitted!.constraints.hardVetoCategories,
      {'sports'},
    );
    expect(
      submitted!.novelty,
      ZyncNowNoveltyPreference.mixed,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('private Zync Now form caps hard-no selection at three',
      (tester) async {
    ZyncNowPrivateContext? submitted;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZyncNowConstraintsForm(
              onSubmit: (context) async {
                submitted = context;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in const [
      'No sports',
      'No making / cooking',
      'No competition',
      'No watching',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }

    await tester.ensureVisible(find.text('Lock my preferences'));
    await tester.tap(find.text('Lock my preferences'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    final vetoCount =
        submitted!.constraints.hardVetoVerbs.length +
        submitted!.constraints.hardVetoCategories.length;
    expect(vetoCount, 3);
    expect(
      submitted!.constraints.hardVetoCategories,
      contains('sports'),
    );
    expect(tester.takeException(), isNull);
  });
}

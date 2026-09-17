import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/models.dart';
import 'package:zync/l10n/generated/app_localizations.dart';
import 'package:zync/screens/interest_setup_screen.dart';
import 'package:zync/ui/zync_design.dart';

void main() {
  testWidgets('interest setup drills from category to L2 and L3 taxonomy', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profile = LocalProfile(
      localId: 'taxonomy-test',
      nickname: '',
      language: 'en',
      interests: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ZyncTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: InterestSetupScreen(
          profile: profile,
          editing: true,
          onSaved: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l1Strip = find.byType(ListView).first;
    for (var i = 0; i < 4 && find.text('Entertainment').evaluate().isEmpty; i++) {
      await tester.drag(l1Strip, const Offset(-700, 0));
      await tester.pumpAndSettle();
    }
    expect(find.text('Entertainment'), findsOneWidget);
    await tester.tap(find.text('Entertainment'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('interest-l2-strip')), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('TV & Drama'), findsOneWidget);
    expect(find.text('Anime & Manga'), findsOneWidget);

    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('interest-l3-strip')), findsOneWidget);
    expect(find.text('Genres & Subgenres'), findsOneWidget);
    expect(find.text('Classics'), findsOneWidget);
    expect(find.text('Modern Favorites'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

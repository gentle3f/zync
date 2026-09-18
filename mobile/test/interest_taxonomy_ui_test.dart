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
    tester.view.physicalSize = const Size(3000, 1688);
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

    expect(find.text('Entertainment'), findsOneWidget);
    await tester.tap(find.text('Entertainment'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('interest-l2-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('interest-l2-movies')), findsOneWidget);
    expect(find.byKey(const ValueKey('interest-l2-tv_drama')), findsOneWidget);
    expect(find.byKey(const ValueKey('interest-l2-anime_manga')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('interest-l2-movies')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('interest-l3-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('interest-l3-subgenres')), findsOneWidget);
    expect(find.byKey(const ValueKey('interest-l3-classics')), findsOneWidget);
    expect(find.byKey(const ValueKey('interest-l3-modern_evergreen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

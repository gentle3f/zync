import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/matching_service.dart';
import 'package:zync/core/models.dart';
import 'package:zync/l10n/generated/app_localizations.dart';
import 'package:zync/screens/match_screen.dart';
import 'package:zync/ui/zync_design.dart';

void main() {
  testWidgets('pair recap offers a real-world next step and returns true',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const peer = QrProfilePayload(
      version: QrProfilePayload.currentVersion,
      localId: 'peer-next-step',
      nickname: 'Jamie',
      language: 'en',
      interests: [
        SelectedInterest(
          id: 'sports.badminton',
          strength: InterestStrength.love,
        ),
      ],
    );
    final match = MatchingService.compare(
      const [
        SelectedInterest(
          id: 'sports.badminton',
          strength: InterestStrength.like,
        ),
      ],
      peer.interests,
      sessionSeed: 'next-step-session',
    );

    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: ZyncTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('launch-match'),
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => MatchScreen(
                        peer: peer,
                        match: match,
                        newMatchCount: 0,
                        sessionSeed: 'next-step-session',
                        canStartZyncNow: true,
                      ),
                    ),
                  );
                },
                child: const Text('Launch'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('launch-match')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('zync-reveal-first')));
    await tester.pumpAndSettle();

    final nextConnection = find.byKey(const ValueKey('zync-next-connection'));
    await tester.scrollUntilVisible(
      nextConnection,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(nextConnection);
    await tester.pumpAndSettle();

    final finish = find.text('Finish & recap');
    await tester.scrollUntilVisible(
      finish,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(finish);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('zync-match-start-activity')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('zync-match-start-activity')),
    );
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.byKey(const ValueKey('launch-match')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

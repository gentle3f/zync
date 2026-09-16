import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/models.dart';
import 'package:zync/l10n/generated/app_localizations.dart';
import 'package:zync/screens/home_screen.dart';
import 'package:zync/screens/interest_setup_screen.dart';
import 'package:zync/screens/match_screen.dart';
import 'package:zync/screens/show_qr_screen.dart';
import 'package:zync/ui/zync_design.dart';

void main() {
  const profile = LocalProfile(
    localId: 'me-123',
    nickname: 'Alexandria',
    language: 'fr',
    interests: [
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
      SelectedInterest(id: 'motorsport.formula1', strength: InterestStrength.like),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
      SelectedInterest(id: 'travel.japan', strength: InterestStrength.like),
      SelectedInterest(id: 'technology.ai', strength: InterestStrength.like),
      SelectedInterest(id: 'photography.street', strength: InterestStrength.wantToTry),
    ],
  );

  testWidgets('home survives a narrow French phone with larger text', (tester) async {
    _setPhone(tester, width: 320, height: 700);
    await tester.pumpWidget(
      _harness(
        HomeScreen(profile: profile, onProfileChanged: (_) async {}),
        locale: const Locale('fr'),
        textScale: 1.2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('interest onboarding survives narrow Portuguese layout', (tester) async {
    _setPhone(tester, width: 320, height: 700);
    const emptyProfile = LocalProfile(
      localId: 'new-user',
      nickname: '',
      language: 'pt',
      interests: [],
    );
    await tester.pumpWidget(
      _harness(
        InterestSetupScreen(profile: emptyProfile, onSaved: (_) async {}),
        locale: const Locale('pt'),
        textScale: 1.15,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('QR handoff remains scroll-safe on a small screen', (tester) async {
    _setPhone(tester, width: 320, height: 620);
    await tester.pumpWidget(
      _harness(
        const ShowQrScreen(profile: profile),
        locale: const Locale('fr'),
        textScale: 1.15,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('large compressed QR renders on a narrow phone', (tester) async {
    _setPhone(tester, width: 320, height: 680);
    const categories = ['sports', 'arts', 'travel', 'technology', 'food'];
    final largeProfile = LocalProfile(
      localId: 'large-qr-user',
      nickname: 'International Explorer',
      language: 'zh-Hant',
      interests: List.generate(
        80,
        (index) => SelectedInterest(
          id: 'custom.${index.toString().padLeft(4, '0')}abcdefghijkl',
          strength: InterestStrength.values[index % InterestStrength.values.length],
          customLabel: 'Interest $index — 週末主題 ${index % 10}',
          customCategory: categories[index % categories.length],
        ),
      ),
    );

    expect(
      QrProfilePayload.fromProfile(largeProfile).encode(),
      startsWith(QrProfilePayload.compressedPrefix),
    );
    await tester.pumpWidget(
      _harness(
        ShowQrScreen(profile: largeProfile),
        locale: const Locale('zh', 'HK'),
        textScale: 1.1,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden-match reveal handles long labels on a small screen', (tester) async {
    _setPhone(tester, width: 320, height: 660);
    const peer = QrProfilePayload(
      version: QrProfilePayload.currentVersion,
      localId: 'peer-456',
      nickname: 'Jean-Christophe',
      language: 'fr',
      interests: [],
    );
    const match = MatchResult(
      shared: [
        SelectedInterest(
          id: 'custom.analogue-photo',
          strength: InterestStrength.love,
          customLabel: 'Photographie argentique de rue et développement maison',
          customCategory: 'arts',
        ),
        SelectedInterest(
          id: 'motorsport.formula1',
          strength: InterestStrength.like,
        ),
      ],
      onlyMine: [],
      onlyTheirs: [],
    );
    await tester.pumpWidget(
      _harness(
        const MatchScreen(peer: peer, match: match, newMatchCount: 1),
        locale: const Locale('fr'),
        textScale: 1.15,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

void _setPhone(WidgetTester tester, {required double width, required double height}) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, height * 2);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _harness(
  Widget home, {
  required Locale locale,
  double textScale = 1,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ZyncTheme.light(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

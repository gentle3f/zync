import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/relay_service.dart';
import 'package:zync/l10n/generated/app_localizations.dart';
import 'package:zync/screens/conversation_screen.dart';
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

  testWidgets('home normal phone is one-screen with primary actions visible without scrolling', (tester) async {
    _setPhone(tester, width: 390, height: 844);
    await tester.pumpWidget(
      _harness(
        HomeScreen(profile: profile, onProfileChanged: (_) async {}),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show my QR'), findsOneWidget);
    expect(find.text('Scan someone'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home survives a narrow French phone with larger text using fallback scroll', (tester) async {
    _setPhone(tester, width: 320, height: 700);
    await tester.pumpWidget(
      _harness(
        HomeScreen(profile: profile, onProfileChanged: (_) async {}),
        locale: const Locale('fr'),
        textScale: 1.2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('configured privacy policy is visible from Home', (tester) async {
    const privacyUrl = String.fromEnvironment('ZYNC_PRIVACY_URL');
    if (privacyUrl.isEmpty) return;

    _setPhone(tester, width: 390, height: 844);
    await tester.pumpWidget(
      _harness(
        HomeScreen(profile: profile, onProfileChanged: (_) async {}),
        locale: const Locale('fr'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Politique de confidentialité'), findsOneWidget);
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

  testWidgets('QR handoff fits a normal phone without vertical scrolling', (tester) async {
    _setPhone(tester, width: 390, height: 844);
    final relay = _WaitingRelayClient();
    await tester.pumpWidget(
      _harness(
        ShowQrScreen(profile: profile, relayClient: relay),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Waiting for scan…'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('QR handoff remains scroll-safe on a small screen', (tester) async {
    _setPhone(tester, width: 320, height: 620);
    final relay = _WaitingRelayClient();
    await tester.pumpWidget(
      _harness(
        ShowQrScreen(profile: profile, relayClient: relay),
        locale: const Locale('fr'),
        textScale: 1.15,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('large profile handshake QR renders on a narrow phone', (tester) async {
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
    final relay = _WaitingRelayClient();
    await tester.pumpWidget(
      _harness(
        ShowQrScreen(profile: largeProfile, relayClient: relay),
        locale: const Locale('zh', 'HK'),
        textScale: 1.1,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('等待掃描…'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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

  testWidgets('bilingual conversation fallback fits a narrow phone', (tester) async {
    _setPhone(tester, width: 320, height: 700);
    const match = MatchResult(
      shared: [
        SelectedInterest(id: 'motorsport.formula1', strength: InterestStrength.love),
      ],
      onlyMine: [],
      onlyTheirs: [],
    );

    await tester.pumpWidget(
      _harness(
        const ConversationScreen(match: match, peerLanguage: 'ja-JP', sessionSeed: 'ABCDEFGHIJKLMNOPQRSTUVWX'),
        locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        textScale: 1.15,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('日本語'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _WaitingRelayClient implements RelayClient {
  bool created = false;

  @override
  Future<void> createSession({required String sessionId, required DateTime expiresAt}) async {
    created = true;
  }

  @override
  Future<RelayTakeResult> take({required String sessionId}) async => const RelayTakeResult.waiting();

  @override
  Future<void> respond({required String sessionId, required String payload}) async {}

  @override
  Future<void> consume({required String sessionId}) async {}

  @override
  Future<void> cancel({required String sessionId}) async {}
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

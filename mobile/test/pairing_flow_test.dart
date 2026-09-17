import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zync/core/local_store.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/relay_service.dart';
import 'package:zync/l10n/generated/app_localizations.dart';
import 'package:zync/screens/show_qr_screen.dart';
import 'package:zync/ui/zync_design.dart';

void main() {
  testWidgets('host auto-advances to Match after one encrypted scanner response', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const host = LocalProfile(
      localId: 'host-local-id',
      nickname: 'Host',
      language: 'en',
      interests: [
        SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
        SelectedInterest(id: 'anime.jojo', strength: InterestStrength.like),
        SelectedInterest(id: 'technology.ai', strength: InterestStrength.like),
        SelectedInterest(id: 'travel.japan', strength: InterestStrength.wantToTry),
        SelectedInterest(id: 'food.cooking', strength: InterestStrength.like),
      ],
    );
    const scanner = LocalProfile(
      localId: 'scanner-local-id',
      nickname: 'Scanner',
      language: 'ja',
      interests: [
        SelectedInterest(id: 'sports.badminton', strength: InterestStrength.like),
        SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
        SelectedInterest(id: 'photography.street', strength: InterestStrength.like),
        SelectedInterest(id: 'travel.japan', strength: InterestStrength.like),
        SelectedInterest(id: 'music.drums', strength: InterestStrength.wantToTry),
      ],
    );
    final relay = _HostFlowRelay();
    final bootstrap = RelayBootstrap(
      sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      hostToken: '0123456789ABCDEFGHIJKLMNOPQRSTUV',
      secretBytes: List<int>.generate(32, (index) => index + 1),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 3)),
      hostProfile: QrProfilePayload.fromProfile(host),
    );
    final encodedQr = bootstrap.qr.encode();
    final handshake = ZyncHandshakeQrPayload.decode(encodedQr);
    expect(encodedQr, isNot(contains(bootstrap.hostToken)));

    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        home: ShowQrScreen(
          profile: host,
          relayClient: relay,
          bootstrapFactory: (_) => bootstrap,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(relay.createdSessionId, bootstrap.sessionId);
    expect(relay.createdHostToken, bootstrap.hostToken);
    expect(find.text('Waiting for scan…'), findsOneWidget);
    expect(handshake.sessionId, relay.createdSessionId);

    relay.responsePayload = await RelayCrypto.encryptPeerResponse(
      handshake: handshake,
      scannerProfile: scanner,
    );

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('YOU ZYNC!'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
    expect(relay.consumedSessionId, handshake.sessionId);
    expect(relay.consumedHostToken, relay.createdHostToken);
    expect(relay.cancelledSessionId, isNull);

    final history = await LocalStore.findHistory(scanner.localId);
    expect(history, isNotNull);
    expect(history!.peerNickname, scanner.nickname);
    expect(history.sessionCount, 1);
    expect(history.previousSharedIds.toSet(), {'sports.badminton', 'anime.jojo', 'travel.japan'});
  });
}

class _HostFlowRelay implements RelayClient {
  String? createdSessionId;
  String? createdHostToken;
  String? consumedSessionId;
  String? consumedHostToken;
  String? cancelledSessionId;
  String? responsePayload;

  @override
  Future<void> createSession({
    required String sessionId,
    required String hostToken,
    required DateTime expiresAt,
  }) async {
    createdSessionId = sessionId;
    createdHostToken = hostToken;
    expect(expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
  }

  @override
  Future<RelayTakeResult> take({required String sessionId, required String hostToken}) async {
    expect(sessionId, createdSessionId);
    expect(hostToken, createdHostToken);
    final response = responsePayload;
    return response == null ? const RelayTakeResult.waiting() : RelayTakeResult.ready(response);
  }

  @override
  Future<void> respond({required String sessionId, required String payload}) async {
    throw UnimplementedError('Host flow must not submit a scanner response');
  }

  @override
  Future<void> consume({required String sessionId, required String hostToken}) async {
    consumedSessionId = sessionId;
    consumedHostToken = hostToken;
  }

  @override
  Future<void> cancel({required String sessionId, required String hostToken}) async {
    cancelledSessionId = sessionId;
    expect(hostToken, createdHostToken);
  }
}

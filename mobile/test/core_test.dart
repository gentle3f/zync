import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/ai_service.dart';
import 'package:zync/core/language_support.dart';
import 'package:zync/core/matching_service.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/relay_service.dart';
import 'package:zync/core/zync_session_service.dart';
import 'package:zync/core/zync_alias.dart';

void main() {
  test('ridiculous anonymous alias is deterministic and never exposes the raw ID', () {
    final first = ZyncAlias.forId('peer-stable-123', 'en');
    final second = ZyncAlias.forId('peer-stable-123', 'en');
    final zh = ZyncAlias.forId('peer-stable-123', 'zh-Hant');

    expect(first, second);
    expect(first, isNot(contains('peer-stable-123')));
    expect(first, isNot(startsWith('Zync #')));
    expect(first.split(' ').length, greaterThanOrEqualTo(2));
    expect(zh, isNotEmpty);
  });

  test('QR includes only explicitly shared public social links', () {
    const profile = LocalProfile(
      localId: 'social-user',
      nickname: '',
      language: 'en',
      interests: [
        SelectedInterest(id: 'sports.badminton', strength: InterestStrength.like),
      ],
      socialLinks: [
        SocialLink(
          platform: SocialPlatform.instagram,
          value: '@open_me',
          shareAfterZync: true,
        ),
        SocialLink(
          platform: SocialPlatform.threads,
          value: '@private_for_now',
          shareAfterZync: false,
        ),
      ],
    );

    final payload = QrProfilePayload.fromProfile(profile);
    expect(payload.socialLinks, hasLength(1));
    expect(payload.socialLinks.single.platform, SocialPlatform.instagram);

    final decoded = QrProfilePayload.decode(payload.encode());
    expect(decoded.socialLinks, hasLength(1));
    expect(decoded.socialLinks.single.profileUrl, 'https://www.instagram.com/open_me/');
    expect(decoded.socialLinks.single.shareAfterZync, isTrue);
  });

  test('old profile and QR JSON remain valid without social-link fields', () {
    final profile = LocalProfile.fromJson({
      'localId': 'old-local',
      'nickname': '',
      'language': 'en',
      'interests': const [],
    });
    expect(profile.socialLinks, isEmpty);

    final decoded = QrProfilePayload.decode(
      jsonEncode({
        'v': QrProfilePayload.currentVersion,
        'id': 'old-peer',
        'name': '',
        'lang': 'en',
        'i': const [],
      }),
    );
    expect(decoded.socialLinks, isEmpty);
  });

  test('history JSON migrates old rows and preserves richer local memories', () {
    final old = ZyncHistoryEntry.fromJson({
      'peerId': 'old-peer',
      'peerNickname': '',
      'previousSharedIds': ['sports.badminton'],
      'firstZyncAt': '2026-09-17T00:00:00Z',
      'lastZyncAt': '2026-09-18T00:00:00Z',
      'sessionCount': 2,
    });
    expect(old.peerInterests, isEmpty);
    expect(old.recentQuestions, isEmpty);

    final rich = ZyncHistoryEntry(
      peerId: 'peer-rich',
      peerNickname: '',
      previousSharedIds: const ['anime.jojo'],
      firstZyncAt: DateTime.utc(2026, 9, 17),
      lastZyncAt: DateTime.utc(2026, 9, 18),
      sessionCount: 3,
      peerInterests: const [
        SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
      ],
      recentQuestions: [
        ZyncQuestionMemory(
          connectionKey: 'shared:anime.jojo',
          question: 'Which Part would you start with?',
          mode: 'fun',
          createdAt: DateTime.utc(2026, 9, 18),
          connectionLabel: 'JoJo',
        ),
      ],
    );
    final roundTrip = ZyncHistoryEntry.fromJson(rich.toJson());
    expect(roundTrip.peerInterests.single.id, 'sports.badminton');
    expect(roundTrip.recentQuestions.single.question, 'Which Part would you start with?');
  });

  test('one-person fallback invites curiosity instead of inventing a crossover', () {
    const service = AiService(baseUrl: '');
    const match = MatchResult(
      shared: [],
      onlyMine: [],
      onlyTheirs: [
        SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
      ],
    );
    final result = service.localFallback(language: 'en', match: match);
    expect(result.fromAi, isFalse);
    expect(result.question.toLowerCase(), contains('badminton'));
    expect(result.question.toLowerCase(), isNot(contains('combined')));
  });

  test('small QR payload stays legacy JSON and round-trips without PII expansion', () {
    const profile = LocalProfile(
      localId: 'abc-123',
      nickname: 'Gentle',
      language: 'zh-Hant',
      interests: [
        SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
        SelectedInterest(id: 'motorsport.formula1', strength: InterestStrength.like),
      ],
    );

    final payload = QrProfilePayload.fromProfile(profile);
    final encoded = payload.encode();
    final decoded = QrProfilePayload.decode(encoded);

    expect(encoded, startsWith('{'));
    expect(decoded.version, QrProfilePayload.currentVersion);
    expect(decoded.localId, profile.localId);
    expect(decoded.nickname, profile.nickname);
    expect(decoded.language, profile.language);
    expect(decoded.interests.map((e) => e.id), ['anime.jojo', 'motorsport.formula1']);
    expect(encoded, isNot(contains('email')));
    expect(encoded, isNot(contains('phone')));
  });

  test('decoder remains backward compatible with legacy raw JSON', () {
    const profile = LocalProfile(
      localId: 'legacy-user',
      nickname: 'Legacy',
      language: 'en',
      interests: [
        SelectedInterest(id: 'sports.badminton', strength: InterestStrength.like),
      ],
    );

    final legacy = QrProfilePayload.fromProfile(profile).encodeLegacyJson();
    final decoded = QrProfilePayload.decode(legacy);

    expect(legacy, startsWith('{'));
    expect(decoded.localId, 'legacy-user');
    expect(decoded.interests.single.id, 'sports.badminton');
  });

  test('large interest profile uses compressed QR transport and preserves all metadata', () {
    const categories = ['sports', 'arts', 'travel', 'technology', 'food'];
    final interests = List.generate(
      80,
      (index) => SelectedInterest(
        id: 'custom.${index.toString().padLeft(4, '0')}abcdefghijkl',
        strength: InterestStrength.values[index % InterestStrength.values.length],
        customLabel: 'Interest $index — 週末主題 ${index % 10}',
        customCategory: categories[index % categories.length],
      ),
    );
    final profile = LocalProfile(
      localId: 'large-profile-12345678',
      nickname: 'International Explorer',
      language: 'zh-Hant',
      interests: interests,
    );

    final payload = QrProfilePayload.fromProfile(profile);
    final legacy = payload.encodeLegacyJson();
    final encoded = payload.encode();
    final decoded = QrProfilePayload.decode(encoded);

    expect(encoded, startsWith(QrProfilePayload.compressedPrefix));
    expect(utf8.encode(encoded).length, lessThan(2000));
    expect(utf8.encode(encoded).length, lessThan(utf8.encode(legacy).length));
    expect(decoded.localId, profile.localId);
    expect(decoded.nickname, profile.nickname);
    expect(decoded.language, profile.language);
    expect(decoded.interests, hasLength(80));
    expect(decoded.interests[37].id, interests[37].id);
    expect(decoded.interests[37].strength, interests[37].strength);
    expect(decoded.interests[37].customLabel, interests[37].customLabel);
    expect(decoded.interests[37].customCategory, interests[37].customCategory);
  });

  test('malformed compressed QR transport is rejected', () {
    expect(
      () => QrProfilePayload.decode('${QrProfilePayload.compressedPrefix}not-valid@@'),
      throwsA(isA<FormatException>()),
    );
  });

  test('custom interest QR metadata round-trips with readable label and category', () {
    const profile = LocalProfile(
      localId: 'custom-1',
      nickname: 'Railfan',
      language: 'en',
      interests: [
        SelectedInterest(
          id: 'custom.1234567890abcdef',
          strength: InterestStrength.love,
          customLabel: 'Railway Photography',
          customCategory: 'transport',
        ),
      ],
    );

    final decoded = QrProfilePayload.decode(QrProfilePayload.fromProfile(profile).encode());
    final custom = decoded.interests.single;

    expect(custom.id, 'custom.1234567890abcdef');
    expect(custom.strength, InterestStrength.love);
    expect(custom.customLabel, 'Railway Photography');
    expect(custom.customCategory, 'transport');
  });

  test('matching uses canonical IDs and returns non-shared interests separately', () {
    const mine = [
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
      SelectedInterest(id: 'technology.ai', strength: InterestStrength.like),
    ];
    const theirs = [
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.like),
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
    ];

    final result = MatchingService.compare(mine, theirs);

    expect(result.shared.map((e) => e.id), ['anime.jojo']);
    expect(result.shared.single.strength, InterestStrength.like);
    expect(result.onlyMine.map((e) => e.id), ['technology.ai']);
    expect(result.onlyTheirs.map((e) => e.id), ['sports.badminton']);
  });

  test('shared custom interest preserves readable metadata for reveal and AI', () {
    const mine = [
      SelectedInterest(
        id: 'custom.abc',
        strength: InterestStrength.love,
        customLabel: 'Urban Sketching',
        customCategory: 'arts',
      ),
    ];
    const theirs = [
      SelectedInterest(
        id: 'custom.abc',
        strength: InterestStrength.like,
        customLabel: 'Urban Sketching',
        customCategory: 'arts',
      ),
    ];

    final shared = MatchingService.compare(mine, theirs).shared.single;

    expect(shared.id, 'custom.abc');
    expect(shared.strength, InterestStrength.like);
    expect(shared.customLabel, 'Urban Sketching');
    expect(shared.customCategory, 'arts');
  });

  test('zero-match remains a valid result for crossover AI', () {
    const mine = [SelectedInterest(id: 'motorsport.formula1', strength: InterestStrength.love)];
    const theirs = [SelectedInterest(id: 'food.cooking', strength: InterestStrength.like)];

    final result = MatchingService.compare(mine, theirs);

    expect(result.shared, isEmpty);
    expect(result.onlyMine, hasLength(1));
    expect(result.onlyTheirs, hasLength(1));
  });

  test('seeded shared-interest reveal order is deterministic for both devices', () {
    const host = [
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
      SelectedInterest(id: 'technology.ai', strength: InterestStrength.like),
    ];
    const scanner = [
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
      SelectedInterest(id: 'technology.ai', strength: InterestStrength.like),
    ];
    const seed = 'ABCDEFGHIJKLMNOPQRSTUVWX';

    final onScanner = MatchingService.compare(host, scanner, sessionSeed: seed);
    final onHost = MatchingService.compare(host, scanner, sessionSeed: seed);

    expect(onScanner.shared.map((item) => item.id).toList(), onHost.shared.map((item) => item.id).toList());
    expect(onScanner.onlyMine.map((item) => item.id).toList(), onHost.onlyMine.map((item) => item.id).toList());
    expect(onScanner.onlyTheirs.map((item) => item.id).toList(), onHost.onlyTheirs.map((item) => item.id).toList());
  });

  test('matching preserves each person strength for the same canonical interest', () {
    const mine = [
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
    ];
    const theirs = [
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.wantToTry),
    ];

    final result = MatchingService.compare(mine, theirs);
    final detail = result.sharedDetails.single;

    expect(detail.mine.strength, InterestStrength.love);
    expect(detail.theirs.strength, InterestStrength.wantToTry);
    expect(detail.merged.strength, InterestStrength.wantToTry);
  });

  test('Zync Session collapses broad ancestors but never sibling specific interests', () {
    const mine = [
      SelectedInterest(id: 'media.anime', strength: InterestStrength.like),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
      SelectedInterest(id: 'entertainment.one_piece', strength: InterestStrength.like),
    ];
    const theirs = [
      SelectedInterest(id: 'media.anime', strength: InterestStrength.love),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
      SelectedInterest(id: 'entertainment.one_piece', strength: InterestStrength.love),
    ];

    final match = MatchingService.compare(mine, theirs, sessionSeed: 'session-a');
    final connections = ZyncSessionService.exactConnections(
      match,
      sessionSeed: 'session-a',
    );

    expect(connections.map((item) => item.id), containsAll(['anime.jojo', 'entertainment.one_piece']));
    expect(connections.map((item) => item.id), isNot(contains('media.anime')));
    expect(
      connections.firstWhere((item) => item.id == 'anime.jojo').context.map((item) => item.id),
      contains('media.anime'),
    );
  });

  test('connection threads never collapse sibling L2 families', () {
    const mine = [
      SelectedInterest(id: 'media.movies', strength: InterestStrength.like),
      SelectedInterest(id: 'media.anime', strength: InterestStrength.like),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
    ];
    const theirs = [
      SelectedInterest(id: 'media.movies', strength: InterestStrength.love),
      SelectedInterest(id: 'media.anime', strength: InterestStrength.like),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
    ];

    final match = MatchingService.compare(mine, theirs, sessionSeed: 'sibling-test');
    final connections = ZyncSessionService.exactConnections(
      match,
      sessionSeed: 'sibling-test',
    );

    expect(connections.map((item) => item.id), contains('media.movies'));
    expect(connections.map((item) => item.id), contains('anime.jojo'));
    expect(connections.map((item) => item.id), isNot(contains('media.anime')));
  });

  test('Zync Again newness is local metadata and does not change shared reveal order', () {
    const mine = [
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.like),
    ];
    const theirs = [
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.like),
    ];
    final match = MatchingService.compare(mine, theirs, sessionSeed: 'stable-seed');
    final firstDevice = ZyncSessionService.exactConnections(
      match,
      previousSharedIds: {'sports.badminton'},
      markNewConnections: true,
      sessionSeed: 'stable-seed',
    );
    final secondDevice = ZyncSessionService.exactConnections(
      match,
      previousSharedIds: const {},
      markNewConnections: true,
      sessionSeed: 'stable-seed',
    );

    expect(
      firstDevice.map((item) => item.id).toList(),
      secondDevice.map((item) => item.id).toList(),
    );
    expect(
      firstDevice.firstWhere((item) => item.id == 'anime.jojo').isNew,
      isTrue,
    );
  });

  test('a newly added broad parent does not make an old specific reveal look new', () {
    const mine = [
      SelectedInterest(id: 'media.anime', strength: InterestStrength.like),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
    ];
    const theirs = [
      SelectedInterest(id: 'media.anime', strength: InterestStrength.like),
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
    ];
    final match = MatchingService.compare(mine, theirs, sessionSeed: 'repeat-thread');
    final connections = ZyncSessionService.exactConnections(
      match,
      previousSharedIds: {'anime.jojo'},
      markNewConnections: true,
      sessionSeed: 'repeat-thread',
    );

    expect(connections.single.id, 'anime.jojo');
    expect(connections.single.isNew, isFalse);
  });

  test('first-ever Zync does not label every connection as new since last time', () {
    const mine = [
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
    ];
    const theirs = [
      SelectedInterest(id: 'anime.jojo', strength: InterestStrength.like),
    ];
    final match = MatchingService.compare(mine, theirs, sessionSeed: 'first-session');
    final connections = ZyncSessionService.exactConnections(
      match,
      previousSharedIds: const {},
      markNewConnections: false,
      sessionSeed: 'first-session',
    );

    expect(connections.single.isNew, isFalse);
  });

  test('zero-match bridge selection is deterministic and graph-aware', () {
    const match = MatchResult(
      shared: [],
      onlyMine: [
        SelectedInterest(id: 'travel.japan', strength: InterestStrength.love),
        SelectedInterest(id: 'technology.ai', strength: InterestStrength.like),
      ],
      onlyTheirs: [
        SelectedInterest(id: 'food.japanese', strength: InterestStrength.love),
        SelectedInterest(id: 'sports.badminton', strength: InterestStrength.like),
      ],
    );

    final first = ZyncSessionService.bestCrossover(match, sessionSeed: 'same-session');
    final second = ZyncSessionService.bestCrossover(match, sessionSeed: 'same-session');

    expect(first, isNotNull);
    expect(first!.connectionKey, second!.connectionKey);
    expect(first.mine.id, 'travel.japan');
    expect(first.theirs.id, 'food.japanese');
  });

  test('handshake QR carries a short-lived session but never the private host capability', () {
    final now = DateTime.utc(2026, 9, 17, 12);
    const host = LocalProfile(
      localId: 'host-123',
      nickname: 'Host',
      language: 'zh-Hant',
      interests: [SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love)],
    );
    final bootstrap = RelayBootstrap(
      sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      hostToken: '0123456789ABCDEFGHIJKLMNOPQRSTUV',
      secretBytes: List<int>.generate(32, (index) => index),
      expiresAt: now.add(const Duration(minutes: 3)),
      hostProfile: QrProfilePayload.fromProfile(host),
    );

    final encoded = bootstrap.qr.encode();
    final decoded = ZyncHandshakeQrPayload.decode(encoded, now: now);

    expect(encoded, startsWith('ZH2:'));
    expect(decoded.protocolVersion, zyncRelayProtocolVersion);
    expect(decoded.sessionId, bootstrap.sessionId);
    expect(decoded.secretBytes, bootstrap.secretBytes);
    expect(decoded.expiresAt, bootstrap.expiresAt);
    expect(decoded.hostProfile.localId, host.localId);
    expect(decoded.hostProfile.nickname, host.nickname);
    expect(encoded, isNot(contains(bootstrap.hostToken)));
    expect(encoded, isNot(contains('email')));
    expect(encoded, isNot(contains('phone')));
  });

  test('expired handshake QR is rejected before pairing', () {
    final now = DateTime.utc(2026, 9, 17, 12);
    const host = LocalProfile(
      localId: 'host-123',
      nickname: '',
      language: 'en',
      interests: [SelectedInterest(id: 'anime.jojo', strength: InterestStrength.like)],
    );
    final bootstrap = RelayBootstrap(
      sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      hostToken: '0123456789ABCDEFGHIJKLMNOPQRSTUV',
      secretBytes: List<int>.filled(32, 7),
      expiresAt: now.add(const Duration(minutes: 3)),
      hostProfile: QrProfilePayload.fromProfile(host),
    );

    expect(
      () => ZyncHandshakeQrPayload.decode(bootstrap.qr.encode(), now: now.add(const Duration(minutes: 4))),
      throwsA(isA<FormatException>()),
    );
  });

  test('scanner profile is AES-GCM encrypted and only the host secret can decrypt it', () async {
    final now = DateTime.utc(2026, 9, 17, 12);
    const host = LocalProfile(
      localId: 'host-123',
      nickname: 'Host',
      language: 'en',
      interests: [SelectedInterest(id: 'anime.jojo', strength: InterestStrength.like)],
    );
    const scanner = LocalProfile(
      localId: 'scanner-456',
      nickname: 'Scanner',
      language: 'ja',
      interests: [
        SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
        SelectedInterest(id: 'travel.japan', strength: InterestStrength.like),
      ],
    );
    final bootstrap = RelayBootstrap(
      sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      hostToken: '0123456789ABCDEFGHIJKLMNOPQRSTUV',
      secretBytes: List<int>.generate(32, (index) => 255 - index),
      expiresAt: now.add(const Duration(minutes: 3)),
      hostProfile: QrProfilePayload.fromProfile(host),
    );
    final handshake = ZyncHandshakeQrPayload.decode(bootstrap.qr.encode(), now: now);

    final opaque = await RelayCrypto.encryptPeerResponse(
      handshake: handshake,
      scannerProfile: scanner,
    );
    expect(opaque, isNot(contains('Scanner')));
    expect(opaque, isNot(contains('scanner-456')));
    expect(opaque, matches(RegExp(r'^[A-Za-z0-9_-]+$')));

    final peer = await RelayCrypto.decryptPeerResponse(
      bootstrap: bootstrap,
      opaquePayload: opaque,
      now: now.add(const Duration(seconds: 30)),
    );
    expect(peer.localId, scanner.localId);
    expect(peer.nickname, scanner.nickname);
    expect(peer.language, scanner.language);
    expect(peer.interests.map((item) => item.id).toList(), ['anime.jojo', 'travel.japan']);

    final wrongSecret = RelayBootstrap(
      sessionId: bootstrap.sessionId,
      hostToken: bootstrap.hostToken,
      secretBytes: List<int>.filled(32, 1),
      expiresAt: bootstrap.expiresAt,
      hostProfile: bootstrap.hostProfile,
    );
    await expectLater(
      RelayCrypto.decryptPeerResponse(
        bootstrap: wrongSecret,
        opaquePayload: opaque,
        now: now.add(const Duration(seconds: 30)),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('V1 language canonicalization preserves Chinese script distinction', () {
    expect(ZyncLanguage.canonical('zh-HK'), 'zh-Hant');
    expect(ZyncLanguage.canonical('zh_CN'), 'zh-Hans');
    expect(ZyncLanguage.canonical('ja-JP'), 'ja');
    expect(ZyncLanguage.canonical('pt-BR'), 'pt');
    expect(ZyncLanguage.needsSecondary('zh-Hant', 'ja-JP'), isTrue);
    expect(ZyncLanguage.needsSecondary('en-US', 'en-GB'), isFalse);
  });

  test('offline fallback returns paired questions when peer language differs', () async {
    const match = MatchResult(
      shared: [SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love)],
      onlyMine: [],
      onlyTheirs: [],
    );
    const service = AiService(baseUrl: '');

    final result = await service.generateQuestion(
      language: 'zh-Hant',
      secondaryLanguage: 'ja-JP',
      mode: ConversationMode.fun,
      match: match,
      sessionSeed: 'ABCDEFGHIJKLMNOPQRSTUVWX',
    );

    expect(result.fromAi, isFalse);
    expect(result.question, isNotEmpty);
    expect(result.secondaryQuestion, isNotNull);
    expect(result.secondaryQuestion, isNotEmpty);
    expect(result.secondaryLanguage, 'ja');
  });

  test('same-language peers do not render a duplicate secondary fallback', () async {
    const match = MatchResult(
      shared: [SelectedInterest(id: 'sports.badminton', strength: InterestStrength.like)],
      onlyMine: [],
      onlyTheirs: [],
    );
    const service = AiService(baseUrl: '');

    final result = await service.generateQuestion(
      language: 'en-US',
      secondaryLanguage: 'en-GB',
      mode: ConversationMode.easy,
      match: match,
    );

    expect(result.secondaryQuestion, isNull);
    expect(result.secondaryLanguage, isNull);
  });
}

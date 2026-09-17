import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/ai_service.dart';
import 'package:zync/core/language_support.dart';
import 'package:zync/core/matching_service.dart';
import 'package:zync/core/models.dart';

void main() {
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

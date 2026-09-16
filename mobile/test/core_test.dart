import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/matching_service.dart';
import 'package:zync/core/models.dart';

void main() {
  test('QR payload round-trips without PII expansion', () {
    const profile = LocalProfile(
      localId: 'abc-123',
      nickname: 'Gentle',
      language: 'zh-Hant',
      interests: [
        SelectedInterest(id: 'anime.jojo', strength: InterestStrength.love),
        SelectedInterest(id: 'motorsport.formula1', strength: InterestStrength.like),
      ],
    );

    final encoded = QrProfilePayload.fromProfile(profile).encode();
    final decoded = QrProfilePayload.decode(encoded);

    expect(decoded.version, QrProfilePayload.currentVersion);
    expect(decoded.localId, profile.localId);
    expect(decoded.nickname, profile.nickname);
    expect(decoded.language, profile.language);
    expect(decoded.interests.map((e) => e.id), ['anime.jojo', 'motorsport.formula1']);
    expect(encoded, isNot(contains('email')));
    expect(encoded, isNot(contains('phone')));
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
}

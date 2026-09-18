import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/achievement_service.dart';
import 'package:zync/core/models.dart';

ZyncHistoryEntry peer(
  String id, {
  List<String> interests = const [],
  List<String> shared = const [],
  int sessions = 1,
}) {
  final now = DateTime.utc(2026, 9, 19);
  return ZyncHistoryEntry(
    peerId: id,
    peerNickname: '',
    previousSharedIds: shared,
    firstZyncAt: now,
    lastZyncAt: now,
    sessionCount: sessions,
    peerInterests: interests
        .map(
          (interestId) => SelectedInterest(
            id: interestId,
            strength: InterestStrength.like,
          ),
        )
        .toList(),
  );
}

void main() {
  test('achievements start locked with no real-world encounters', () {
    final snapshot = AchievementService.evaluate(const []);

    expect(snapshot.distinctPeople, 0);
    expect(snapshot.unlockedIds, isEmpty);
  });

  test('repeat Zyncs with the same peer do not farm people achievements', () {
    final snapshot = AchievementService.evaluate([
      peer('same-person', interests: const ['sports.basketball'], sessions: 1),
      peer('same-person', interests: const ['sports.basketball'], sessions: 8),
    ]);

    expect(snapshot.distinctPeople, 1);
    expect(snapshot.unlockedIds, contains('first_zync'));
    expect(snapshot.unlockedIds, isNot(contains('people_five')));
    final basketball = snapshot.progress
        .firstWhere((item) => item.id == 'basketball_starting_five');
    expect(basketball.current, 1);
  });

  test('Starting Five unlocks from five distinct basketball people', () {
    final snapshot = AchievementService.evaluate([
      for (var i = 0; i < 5; i++)
        peer('basketball-$i', interests: const ['sports.basketball']),
    ]);

    expect(snapshot.unlockedIds, contains('basketball_starting_five'));
    final basketball = snapshot.progress
        .firstWhere((item) => item.id == 'basketball_starting_five');
    expect(basketball.current, 5);
  });

  test('ten-sport explorer counts distinct canonical sports, not sessions', () {
    const sports = [
      'sports.badminton',
      'sports.tennis',
      'sports.running',
      'sports.hiking',
      'sports.football',
      'sports.basketball',
      'sports.table_tennis',
      'sports.squash',
      'sports.pickleball',
      'sports.padel',
    ];

    final snapshot = AchievementService.evaluate([
      for (var i = 0; i < sports.length; i++)
        peer('sport-$i', interests: [sports[i]]),
    ]);

    expect(snapshot.discoveredSports, hasLength(10));
    expect(snapshot.unlockedIds, contains('sports_ten'));
  });

  test('old history can still contribute through previously shared IDs', () {
    final snapshot = AchievementService.evaluate([
      for (var i = 0; i < 5; i++)
        peer('legacy-$i', shared: const ['sports.basketball']),
    ]);

    expect(snapshot.unlockedIds, contains('basketball_starting_five'));
  });

  test('newlyUnlocked only returns trophies crossed by the latest encounter', () {
    final before = [
      for (var i = 0; i < 4; i++)
        peer('basketball-$i', interests: const ['sports.basketball']),
    ];
    final after = [
      ...before,
      peer('basketball-4', interests: const ['sports.basketball']),
    ];

    final unlocked = AchievementService.newlyUnlocked(
      before: before,
      after: after,
    );

    expect(unlocked, contains('basketball_starting_five'));
    expect(unlocked, isNot(contains('first_zync')));
  });
}

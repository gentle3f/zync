import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/achievement_service.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/progress_event.dart';

ZyncHistoryEntry peer(
  String id, {
  List<String> interests = const [],
  List<String> shared = const [],
  List<String> seen = const [],
  int sessions = 1,
  List<String> questionModes = const [],
}) {
  final now = DateTime.utc(2026, 9, 19);
  return ZyncHistoryEntry(
    peerId: id,
    peerNickname: '',
    previousSharedIds: shared,
    firstZyncAt: now,
    lastZyncAt: now,
    sessionCount: sessions,
    seenInterestIds: seen,
    peerInterests: interests
        .map(
          (interestId) => SelectedInterest(
            id: interestId,
            strength: InterestStrength.like,
          ),
        )
        .toList(),
    recentQuestions: [
      for (var i = 0; i < questionModes.length; i++)
        ZyncQuestionMemory(
          connectionKey: 'connection-$i',
          question: 'Question $i',
          mode: questionModes[i],
          createdAt: now,
        ),
    ],
  );
}

ZyncProgressEvent action(
  String id, {
  ZyncProgressEventType type = ZyncProgressEventType.oneToOneZync,
  int participants = 2,
  String mode = '',
  List<String> categories = const [],
}) =>
    ZyncProgressEvent(
      id: id,
      type: type,
      source: type == ZyncProgressEventType.triedTogetherCompleted
          ? ZyncProgressSource.zyncNow
          : ZyncProgressSource.oneToOne,
      occurredAt: DateTime.utc(2026, 9, 19, 12),
      participantCount: participants,
      mode: mode,
      interestCategories: categories,
    );

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

  test('badminton doubles needs four distinct badminton people', () {
    final snapshot = AchievementService.evaluate([
      for (var i = 0; i < 4; i++)
        peer('badminton-$i', interests: const ['sports.badminton']),
    ]);

    expect(snapshot.unlockedIds, contains('badminton_doubles_four'));
  });

  test('racket combination counts distinct racket interests, not people', () {
    final snapshot = AchievementService.evaluate([
      peer('a', interests: const ['sports.badminton']),
      peer('b', interests: const ['sports.tennis']),
      peer('c', interests: const ['sports.table_tennis']),
      peer('d', interests: const ['sports.pickleball']),
    ]);

    final racket =
        snapshot.progress.firstWhere((item) => item.id == 'racket_four');
    expect(racket.current, 4);
    expect(racket.unlocked, isTrue);
  });

  test('active mix requires sports and outdoors rather than raw interest count',
      () {
    final incomplete = AchievementService.evaluate([
      peer(
        'sporty',
        interests: const [
          'sports.badminton',
          'sports.tennis',
          'sports.running',
          'sports.basketball',
          'sports.football',
        ],
      ),
    ]);
    expect(
      incomplete.unlockedIds,
      isNot(contains('active_mix')),
    );

    final complete = AchievementService.evaluate([
      peer(
        'sporty',
        interests: const [
          'sports.badminton',
          'sports.tennis',
          'sports.running',
          'outdoors.bouldering',
          'outdoors.camping',
        ],
      ),
    ]);
    expect(complete.unlockedIds, contains('active_mix'));
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

  test('earned discovery progress does not regress when peer interests change',
      () {
    final snapshot = AchievementService.evaluate([
      peer(
        'changed-profile',
        interests: const ['music.jazz'],
        seen: const ['sports.basketball', 'music.jazz'],
      ),
    ]);

    final basketball = snapshot.progress
        .firstWhere((item) => item.id == 'basketball_starting_five');
    expect(basketball.current, 1);
    expect(snapshot.discoveredSports, contains('sports.basketball'));
  });

  test('connection-depth trophies reward repeat relationships, not new people',
      () {
    final snapshot = AchievementService.evaluate([
      peer('friend-a', sessions: 3),
      peer('friend-b', sessions: 3),
      peer('friend-c', sessions: 3),
    ]);

    expect(snapshot.unlockedIds, contains('familiar_face_three'));
    expect(snapshot.unlockedIds, contains('familiar_circle_three'));
    expect(snapshot.unlockedIds, contains('deep_circle_three'));
    expect(snapshot.unlockedIds, isNot(contains('people_five')));
  });

  test('conversation sampler counts distinct modes across real peer history', () {
    final snapshot = AchievementService.evaluate([
      peer('a', questionModes: const ['easy', 'guess']),
      peer('b', questionModes: const ['deep', 'guess']),
    ]);

    expect(snapshot.unlockedIds, contains('conversation_modes_three'));
    expect(
      snapshot.unlockedIds,
      isNot(contains('conversation_modes_six')),
    );
  });

  test('tried-together trophies use privacy-bounded real-world events', () {
    final snapshot = AchievementService.evaluate(
      const [],
      events: [
        action(
          'try-1',
          type: ZyncProgressEventType.triedTogetherCompleted,
          participants: 4,
          mode: 'discovery',
          categories: const ['food', 'travel'],
        ),
        action(
          'try-2',
          type: ZyncProgressEventType.triedTogetherCompleted,
          participants: 3,
          mode: 'mixed',
          categories: const ['sports'],
        ),
        action(
          'try-3',
          type: ZyncProgressEventType.triedTogetherCompleted,
          participants: 2,
          mode: 'familiar',
          categories: const ['arts', 'music'],
        ),
      ],
    );

    expect(snapshot.unlockedIds, contains('tried_together_three'));
    expect(snapshot.unlockedIds, contains('group_activity_first'));
    expect(snapshot.unlockedIds, contains('activity_categories_five'));
    expect(snapshot.unlockedIds, contains('activity_modes_three'));
  });

  test('duplicate progress event ids never farm action achievements', () {
    final duplicate = action(
      'same-event',
      type: ZyncProgressEventType.triedTogetherCompleted,
      categories: const ['food'],
    );
    final snapshot = AchievementService.evaluate(
      const [],
      events: [duplicate, duplicate, duplicate],
    );

    final tried = snapshot.progress
        .firstWhere((item) => item.id == 'tried_together_three');
    expect(tried.current, 1);
    expect(tried.unlocked, isFalse);
  });

  test('newlyUnlocked can include progress-event achievements', () {
    final beforeEvents = [
      for (var i = 0; i < 9; i++) action('action-$i'),
    ];
    final afterEvents = [
      ...beforeEvents,
      action('action-9'),
    ];

    final unlocked = AchievementService.newlyUnlocked(
      before: const [],
      after: const [],
      beforeEvents: beforeEvents,
      afterEvents: afterEvents,
    );

    expect(unlocked, contains('real_world_actions_ten'));
  });

  test('newlyUnlocked only returns trophies crossed by latest encounter', () {
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

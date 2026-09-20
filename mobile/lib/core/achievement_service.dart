import 'dart:math' as math;

import 'interest_catalog.dart';
import 'models.dart';
import 'progress_event.dart';

enum AchievementFamily {
  connection,
  discovery,
  crew,
  realWorld,
}

class AchievementProgress {
  const AchievementProgress({
    required this.id,
    required this.family,
    required this.current,
    required this.target,
  });

  final String id;
  final AchievementFamily family;
  final int current;
  final int target;

  bool get unlocked => current >= target;
  double get fraction =>
      target <= 0 ? 1.0 : (current / target).clamp(0.0, 1.0).toDouble();
}

class AchievementSnapshot {
  const AchievementSnapshot({
    required this.progress,
    required this.distinctPeople,
    required this.discoveredSports,
    required this.discoveredInterests,
    required this.discoveredCategories,
    required this.totalZyncSessions,
    required this.triedTogetherCount,
  });

  final List<AchievementProgress> progress;
  final int distinctPeople;
  final Set<String> discoveredSports;
  final Set<String> discoveredInterests;
  final Set<String> discoveredCategories;
  final int totalZyncSessions;
  final int triedTogetherCount;

  int get unlockedCount => progress.where((item) => item.unlocked).length;
  Set<String> get unlockedIds =>
      progress.where((item) => item.unlocked).map((item) => item.id).toSet();
}

class AchievementService {
  const AchievementService._();

  static const _racketInterests = <String>{
    'sports.badminton',
    'sports.tennis',
    'sports.table_tennis',
    'sports.squash',
    'sports.pickleball',
    'sports.padel',
  };

  static AchievementSnapshot evaluate(
    List<ZyncHistoryEntry> history, {
    Iterable<ZyncProgressEvent> events = const [],
  }) {
    final uniquePeers = <String, ZyncHistoryEntry>{};
    for (final entry in history) {
      // History is already one row per peer in normal storage. Keeping the
      // highest session count makes evaluation robust to imported/legacy rows.
      final previous = uniquePeers[entry.peerId];
      if (previous == null || entry.sessionCount >= previous.sessionCount) {
        uniquePeers[entry.peerId] = entry;
      }
    }

    final discoveredInterests = <String>{};
    final discoveredByCategory = <String, Set<String>>{};
    final peopleByInterest = <String, Set<String>>{};
    final peopleByCategory = <String, Set<String>>{};
    final conversationModes = <String>{};

    var totalZyncSessions = 0;
    var repeatPeople = 0;
    var closeConnections = 0;
    var maxPeerSessions = 0;

    for (final entry in uniquePeers.values) {
      final sessions = math.max(1, entry.sessionCount);
      totalZyncSessions += sessions;
      if (sessions >= 2) repeatPeople += 1;
      if (sessions >= 3) closeConnections += 1;
      maxPeerSessions = math.max(maxPeerSessions, sessions);

      for (final memory in entry.recentQuestions) {
        final mode = memory.mode.trim().toLowerCase();
        if (mode.isNotEmpty) conversationModes.add(mode);
      }

      final peerInterestIds = <String>{
        ...entry.seenInterestIds,
        ...entry.previousSharedIds,
        ...entry.peerInterests.map((item) => item.id),
      };

      final peerCategories = <String>{};
      for (final id in peerInterestIds) {
        discoveredInterests.add(id);
        peopleByInterest.putIfAbsent(id, () => <String>{}).add(entry.peerId);

        final category = InterestCatalog.byId(id)?.category.trim().toLowerCase();
        if (category == null || category.isEmpty) continue;
        discoveredByCategory.putIfAbsent(category, () => <String>{}).add(id);
        peerCategories.add(category);
      }
      for (final category in peerCategories) {
        peopleByCategory
            .putIfAbsent(category, () => <String>{})
            .add(entry.peerId);
      }
    }

    final eventById = <String, ZyncProgressEvent>{};
    for (final event in events) {
      eventById[event.id] = event;
    }
    final realEvents = eventById.values.toList(growable: false);
    final triedTogether = realEvents
        .where(
          (event) =>
              event.type == ZyncProgressEventType.triedTogetherCompleted,
        )
        .toList(growable: false);
    final groupActivities = triedTogether
        .where((event) => event.participantCount >= 3)
        .toList(growable: false);
    final activityCategories = <String>{
      for (final event in triedTogether) ...event.interestCategories,
    };
    final activityModes = <String>{
      for (final event in triedTogether)
        if (event.mode.trim().isNotEmpty) event.mode.trim().toLowerCase(),
    };

    int interestPeople(String id) => peopleByInterest[id]?.length ?? 0;
    int categoryPeople(String category) =>
        peopleByCategory[category]?.length ?? 0;
    int categoryInterests(String category) =>
        discoveredByCategory[category]?.length ?? 0;

    int categoryMix(Map<String, int> requirements) {
      var score = 0;
      for (final entry in requirements.entries) {
        score += math.min(categoryInterests(entry.key), entry.value);
      }
      return score;
    }

    final discoveredSports =
        Set<String>.from(discoveredByCategory['sports'] ?? const <String>{});
    final discoveredCategories = discoveredByCategory.keys.toSet();
    final people = uniquePeers.length;

    final progress = <AchievementProgress>[
      // People & connection depth.
      _p('first_zync', AchievementFamily.connection, people, 1),
      _p('people_five', AchievementFamily.connection, people, 5),
      _p('people_ten', AchievementFamily.connection, people, 10),
      _p('people_twentyfive', AchievementFamily.connection, people, 25),
      _p(
        'zync_sessions_ten',
        AchievementFamily.connection,
        totalZyncSessions,
        10,
      ),
      _p(
        'zync_sessions_twentyfive',
        AchievementFamily.connection,
        totalZyncSessions,
        25,
      ),
      _p(
        'familiar_face_three',
        AchievementFamily.connection,
        maxPeerSessions,
        3,
      ),
      _p(
        'familiar_circle_three',
        AchievementFamily.connection,
        repeatPeople,
        3,
      ),
      _p(
        'deep_circle_three',
        AchievementFamily.connection,
        closeConnections,
        3,
      ),
      _p(
        'conversation_modes_three',
        AchievementFamily.connection,
        conversationModes.length,
        3,
      ),
      _p(
        'conversation_modes_six',
        AchievementFamily.connection,
        conversationModes.length,
        6,
      ),

      // Interest discovery breadth and combinations.
      _p(
        'curiosity_10',
        AchievementFamily.discovery,
        discoveredInterests.length,
        10,
      ),
      _p(
        'curiosity_25',
        AchievementFamily.discovery,
        discoveredInterests.length,
        25,
      ),
      _p(
        'curiosity_50',
        AchievementFamily.discovery,
        discoveredInterests.length,
        50,
      ),
      _p(
        'curiosity_100',
        AchievementFamily.discovery,
        discoveredInterests.length,
        100,
      ),
      _p(
        'categories_three',
        AchievementFamily.discovery,
        discoveredCategories.length,
        3,
      ),
      _p(
        'categories_five',
        AchievementFamily.discovery,
        discoveredCategories.length,
        5,
      ),
      _p(
        'categories_eight',
        AchievementFamily.discovery,
        discoveredCategories.length,
        8,
      ),
      _p(
        'categories_twelve',
        AchievementFamily.discovery,
        discoveredCategories.length,
        12,
      ),
      _p(
        'sports_five',
        AchievementFamily.discovery,
        discoveredSports.length,
        5,
      ),
      _p(
        'sports_ten',
        AchievementFamily.discovery,
        discoveredSports.length,
        10,
      ),
      _p(
        'racket_four',
        AchievementFamily.discovery,
        _racketInterests.intersection(discoveredInterests).length,
        4,
      ),
      _p(
        'active_mix',
        AchievementFamily.discovery,
        categoryMix(const {'sports': 3, 'outdoors': 2}),
        5,
      ),
      _p(
        'culture_mix',
        AchievementFamily.discovery,
        categoryMix(const {'music': 2, 'entertainment': 2, 'arts': 1}),
        5,
      ),
      _p(
        'maker_mix',
        AchievementFamily.discovery,
        categoryMix(const {'technology': 2, 'arts': 1, 'crafts': 1}),
        4,
      ),
      _p(
        'taste_trip',
        AchievementFamily.discovery,
        categoryMix(const {'food': 3, 'travel': 2}),
        5,
      ),
      _p(
        'mind_body_mix',
        AchievementFamily.discovery,
        categoryMix(const {'wellness': 2, 'sports': 2}),
        4,
      ),

      // Themed crews. Every count is distinct people, never repeated sessions.
      _p(
        'basketball_starting_five',
        AchievementFamily.crew,
        interestPeople('sports.basketball'),
        5,
      ),
      _p(
        'basketball_full_roster',
        AchievementFamily.crew,
        interestPeople('sports.basketball'),
        12,
      ),
      _p(
        'football_starting_eleven',
        AchievementFamily.crew,
        interestPeople('sports.football'),
        11,
      ),
      _p(
        'badminton_doubles_four',
        AchievementFamily.crew,
        interestPeople('sports.badminton'),
        4,
      ),
      _p(
        'coffee_table_five',
        AchievementFamily.crew,
        interestPeople('food.coffee'),
        5,
      ),
      _p(
        'gaming_party_four',
        AchievementFamily.crew,
        interestPeople('gaming.video'),
        4,
      ),
      _p(
        'book_club_five',
        AchievementFamily.crew,
        interestPeople('books.reading'),
        5,
      ),
      _p(
        'ai_roundtable_three',
        AchievementFamily.crew,
        interestPeople('technology.ai'),
        3,
      ),
      _p(
        'photo_walk_three',
        AchievementFamily.crew,
        interestPeople('photography.general'),
        3,
      ),
      _p(
        'japan_crew_three',
        AchievementFamily.crew,
        interestPeople('travel.japan'),
        3,
      ),
      _p(
        'music_crew_five',
        AchievementFamily.crew,
        categoryPeople('music'),
        5,
      ),

      // Real-world follow-through.
      _p(
        'tried_together_first',
        AchievementFamily.realWorld,
        triedTogether.length,
        1,
      ),
      _p(
        'tried_together_three',
        AchievementFamily.realWorld,
        triedTogether.length,
        3,
      ),
      _p(
        'tried_together_ten',
        AchievementFamily.realWorld,
        triedTogether.length,
        10,
      ),
      _p(
        'group_activity_first',
        AchievementFamily.realWorld,
        groupActivities.length,
        1,
      ),
      _p(
        'group_activity_three',
        AchievementFamily.realWorld,
        groupActivities.length,
        3,
      ),
      _p(
        'activity_categories_three',
        AchievementFamily.realWorld,
        activityCategories.length,
        3,
      ),
      _p(
        'activity_categories_five',
        AchievementFamily.realWorld,
        activityCategories.length,
        5,
      ),
      _p(
        'activity_modes_three',
        AchievementFamily.realWorld,
        activityModes.length,
        3,
      ),
      _p(
        'real_world_actions_ten',
        AchievementFamily.realWorld,
        realEvents.length,
        10,
      ),
      _p(
        'real_world_actions_twentyfive',
        AchievementFamily.realWorld,
        realEvents.length,
        25,
      ),
    ];

    return AchievementSnapshot(
      progress: List.unmodifiable(progress),
      distinctPeople: people,
      discoveredSports: Set.unmodifiable(discoveredSports),
      discoveredInterests: Set.unmodifiable(discoveredInterests),
      discoveredCategories: Set.unmodifiable(discoveredCategories),
      totalZyncSessions: totalZyncSessions,
      triedTogetherCount: triedTogether.length,
    );
  }

  static AchievementProgress _p(
    String id,
    AchievementFamily family,
    int current,
    int target,
  ) =>
      AchievementProgress(
        id: id,
        family: family,
        current: current,
        target: target,
      );

  static Set<String> newlyUnlocked({
    required List<ZyncHistoryEntry> before,
    required List<ZyncHistoryEntry> after,
    Iterable<ZyncProgressEvent> beforeEvents = const [],
    Iterable<ZyncProgressEvent> afterEvents = const [],
  }) {
    final beforeIds =
        evaluate(before, events: beforeEvents).unlockedIds;
    final afterIds = evaluate(after, events: afterEvents).unlockedIds;
    return afterIds.difference(beforeIds);
  }
}

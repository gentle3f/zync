import 'progress_event.dart';

enum ZyncQuestCadence {
  daily,
  weekly,
  lifetime,
}

enum ZyncQuestMetric {
  oneToOneZyncs,
  newPersonZyncs,
  triedTogether,
  realWorldActions,
  distinctInterestCategories,
  groupActivities,
}

enum ZyncQuestRewardKind {
  drawToken,
  standardPack,
  discoveryPack,
}

class ZyncQuestRewardPreview {
  const ZyncQuestRewardPreview({
    required this.kind,
    required this.amount,
  });

  final ZyncQuestRewardKind kind;
  final int amount;

  /// Local Quest progress is useful UX evidence, not authoritative economy.
  /// Cardverse must revalidate before minting any cloud inventory.
  bool get requiresServerValidation => true;
}

class ZyncQuestDefinition {
  const ZyncQuestDefinition({
    required this.id,
    required this.cadence,
    required this.metric,
    required this.target,
    required this.reward,
  });

  final String id;
  final ZyncQuestCadence cadence;
  final ZyncQuestMetric metric;
  final int target;
  final ZyncQuestRewardPreview reward;
}

class ZyncQuestRewardEligibility {
  const ZyncQuestRewardEligibility({
    required this.key,
    required this.questId,
    required this.cycleStart,
    required this.reward,
    required this.proofEventIds,
  });

  final String key;
  final String questId;
  final DateTime cycleStart;
  final ZyncQuestRewardPreview reward;

  /// Bounded local proof references only. The server must not trust these
  /// blindly and may choose not to accept pre-account/offline claims.
  final List<String> proofEventIds;

  bool get requiresServerValidation => true;
}

class ZyncQuestProgress {
  const ZyncQuestProgress({
    required this.definition,
    required this.current,
    required this.cycleStart,
    required this.cycleEnd,
    required this.eligibility,
  });

  final ZyncQuestDefinition definition;
  final int current;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final ZyncQuestRewardEligibility? eligibility;

  bool get complete => current >= definition.target;

  double get fraction => definition.target <= 0
      ? 1.0
      : (current / definition.target).clamp(0.0, 1.0).toDouble();
}

class ZyncQuestBoardSnapshot {
  const ZyncQuestBoardSnapshot({
    required this.generatedAt,
    required this.timezoneOffset,
    required this.progress,
  });

  final DateTime generatedAt;
  final Duration timezoneOffset;
  final List<ZyncQuestProgress> progress;

  int get completedCount => progress.where((item) => item.complete).length;

  List<ZyncQuestRewardEligibility> get eligibleRewards => List.unmodifiable(
        progress
            .map((item) => item.eligibility)
            .whereType<ZyncQuestRewardEligibility>(),
      );
}

class ZyncQuestEngine {
  const ZyncQuestEngine._();

  static const definitions = <ZyncQuestDefinition>[
    ZyncQuestDefinition(
      id: 'daily_make_a_zync',
      cadence: ZyncQuestCadence.daily,
      metric: ZyncQuestMetric.oneToOneZyncs,
      target: 1,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.drawToken,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'daily_tried_together',
      cadence: ZyncQuestCadence.daily,
      metric: ZyncQuestMetric.triedTogether,
      target: 1,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.drawToken,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'daily_two_real_world_actions',
      cadence: ZyncQuestCadence.daily,
      metric: ZyncQuestMetric.realWorldActions,
      target: 2,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.drawToken,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'weekly_three_zyncs',
      cadence: ZyncQuestCadence.weekly,
      metric: ZyncQuestMetric.oneToOneZyncs,
      target: 3,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.standardPack,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'weekly_two_tried_together',
      cadence: ZyncQuestCadence.weekly,
      metric: ZyncQuestMetric.triedTogether,
      target: 2,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.standardPack,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'weekly_group_activity',
      cadence: ZyncQuestCadence.weekly,
      metric: ZyncQuestMetric.groupActivities,
      target: 1,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.discoveryPack,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'weekly_five_real_world_actions',
      cadence: ZyncQuestCadence.weekly,
      metric: ZyncQuestMetric.realWorldActions,
      target: 5,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.discoveryPack,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'lifetime_five_zyncs',
      cadence: ZyncQuestCadence.lifetime,
      metric: ZyncQuestMetric.oneToOneZyncs,
      target: 5,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.standardPack,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'lifetime_three_tried_together',
      cadence: ZyncQuestCadence.lifetime,
      metric: ZyncQuestMetric.triedTogether,
      target: 3,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.standardPack,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'lifetime_three_group_activities',
      cadence: ZyncQuestCadence.lifetime,
      metric: ZyncQuestMetric.groupActivities,
      target: 3,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.discoveryPack,
        amount: 1,
      ),
    ),
    ZyncQuestDefinition(
      id: 'lifetime_eight_real_world_actions',
      cadence: ZyncQuestCadence.lifetime,
      metric: ZyncQuestMetric.realWorldActions,
      target: 8,
      reward: ZyncQuestRewardPreview(
        kind: ZyncQuestRewardKind.discoveryPack,
        amount: 1,
      ),
    ),
  ];

  static ZyncQuestBoardSnapshot evaluate({
    required Iterable<ZyncProgressEvent> events,
    DateTime? now,
    Duration? timezoneOffset,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    final offset = timezoneOffset ?? DateTime.now().timeZoneOffset;

    final uniqueEvents = <String, ZyncProgressEvent>{};
    for (final event in events) {
      uniqueEvents[event.id] = event;
    }

    final progress = <ZyncQuestProgress>[];
    for (final definition in definitions) {
      final window = _window(
        definition.cadence,
        now: current,
        offset: offset,
      );
      final windowEvents = uniqueEvents.values
          .where(
            (event) =>
                !event.occurredAt.toUtc().isBefore(window.start) &&
                event.occurredAt.toUtc().isBefore(window.end),
          )
          .toList()
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

      final matched = _matchedEvents(definition.metric, windowEvents);
      final currentValue = definition.metric ==
              ZyncQuestMetric.distinctInterestCategories
          ? _distinctCategories(matched).length
          : matched.length;

      final complete = currentValue >= definition.target;
      progress.add(
        ZyncQuestProgress(
          definition: definition,
          current: currentValue,
          cycleStart: window.start,
          cycleEnd: window.end,
          eligibility: complete
              ? ZyncQuestRewardEligibility(
                  key:
                      '${definition.id}:${window.start.toIso8601String()}',
                  questId: definition.id,
                  cycleStart: window.start,
                  reward: definition.reward,
                  proofEventIds: List.unmodifiable(
                    _proofEventIds(
                      metric: definition.metric,
                      events: matched,
                      target: definition.target,
                    ),
                  ),
                )
              : null,
        ),
      );
    }

    return ZyncQuestBoardSnapshot(
      generatedAt: current,
      timezoneOffset: offset,
      progress: List.unmodifiable(progress),
    );
  }

  static List<ZyncProgressEvent> _matchedEvents(
    ZyncQuestMetric metric,
    List<ZyncProgressEvent> events,
  ) {
    return switch (metric) {
      ZyncQuestMetric.oneToOneZyncs => events
          .where((event) => event.type == ZyncProgressEventType.oneToOneZync)
          .toList(growable: false),
      ZyncQuestMetric.newPersonZyncs => events
          .where(
            (event) =>
                event.type == ZyncProgressEventType.oneToOneZync &&
                !event.repeatPerson,
          )
          .toList(growable: false),
      ZyncQuestMetric.triedTogether => events
          .where(
            (event) =>
                event.type ==
                ZyncProgressEventType.triedTogetherCompleted,
          )
          .toList(growable: false),
      ZyncQuestMetric.realWorldActions => events
          .where(
            (event) =>
                event.type == ZyncProgressEventType.oneToOneZync ||
                event.type ==
                    ZyncProgressEventType.triedTogetherCompleted,
          )
          .toList(growable: false),
      ZyncQuestMetric.distinctInterestCategories => events
          .where((event) => event.interestCategories.isNotEmpty)
          .toList(growable: false),
      ZyncQuestMetric.groupActivities => events
          .where(
            (event) =>
                event.type == ZyncProgressEventType.triedTogetherCompleted &&
                event.participantCount >= 3,
          )
          .toList(growable: false),
    };
  }

  static Set<String> _distinctCategories(
    Iterable<ZyncProgressEvent> events,
  ) {
    final result = <String>{};
    for (final event in events) {
      result.addAll(event.interestCategories);
    }
    return result;
  }

  static List<String> _proofEventIds({
    required ZyncQuestMetric metric,
    required List<ZyncProgressEvent> events,
    required int target,
  }) {
    if (metric != ZyncQuestMetric.distinctInterestCategories) {
      return events.take(target).map((event) => event.id).toList();
    }

    final proof = <String>[];
    final categories = <String>{};
    for (final event in events) {
      final before = categories.length;
      categories.addAll(event.interestCategories);
      if (categories.length > before) {
        proof.add(event.id);
      }
      if (categories.length >= target) break;
    }
    return proof;
  }

  static _QuestWindow _window(
    ZyncQuestCadence cadence, {
    required DateTime now,
    required Duration offset,
  }) {
    // Shift into a synthetic local clock encoded as UTC so cycle math does
    // not depend on the CI runner/device timezone. Convert back afterwards.
    final localClock = now.toUtc().add(offset);
    final localDay = DateTime.utc(
      localClock.year,
      localClock.month,
      localClock.day,
    );

    late final DateTime localStart;
    late final Duration length;

    switch (cadence) {
      case ZyncQuestCadence.daily:
        localStart = localDay;
        length = const Duration(days: 1);
      case ZyncQuestCadence.weekly:
        localStart = localDay.subtract(
          Duration(days: localClock.weekday - DateTime.monday),
        );
        length = const Duration(days: 7);
      case ZyncQuestCadence.lifetime:
        return _QuestWindow(
          start: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          end: DateTime.utc(9999),
        );
    }

    final start = localStart.subtract(offset);
    return _QuestWindow(
      start: start,
      end: start.add(length),
    );
  }
}

class _QuestWindow {
  const _QuestWindow({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

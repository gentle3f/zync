import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/progress_event.dart';
import 'package:zync/core/quest_engine.dart';

ZyncProgressEvent event({
  required String id,
  required ZyncProgressEventType type,
  required DateTime at,
  bool repeatPerson = false,
  List<String> categories = const [],
}) =>
    ZyncProgressEvent(
      id: id,
      type: type,
      source: type == ZyncProgressEventType.oneToOneZync
          ? ZyncProgressSource.oneToOne
          : ZyncProgressSource.zyncNow,
      occurredAt: at,
      participantCount: 2,
      repeatPerson: repeatPerson,
      interestCategories: categories,
    );

ZyncQuestProgress quest(
  ZyncQuestBoardSnapshot snapshot,
  String id,
) =>
    snapshot.progress.firstWhere(
      (item) => item.definition.id == id,
    );

void main() {
  const hkt = Duration(hours: 8);

  test('daily quests reset on device-local midnight, not UTC midnight', () {
    final events = [
      event(
        id: 'before-local-midnight',
        type: ZyncProgressEventType.oneToOneZync,
        at: DateTime.utc(2026, 9, 19, 15, 30), // 23:30 HKT
      ),
      event(
        id: 'after-local-midnight',
        type: ZyncProgressEventType.oneToOneZync,
        at: DateTime.utc(2026, 9, 19, 16, 30), // 00:30 HKT Sep 20
      ),
    ];

    final sep19 = ZyncQuestEngine.evaluate(
      events: events,
      now: DateTime.utc(2026, 9, 19, 15, 50),
      timezoneOffset: hkt,
    );
    expect(
      quest(sep19, 'daily_make_a_zync').current,
      1,
    );
    expect(
      quest(sep19, 'daily_make_a_zync')
          .eligibility!
          .proofEventIds,
      ['before-local-midnight'],
    );

    final sep20 = ZyncQuestEngine.evaluate(
      events: events,
      now: DateTime.utc(2026, 9, 19, 17),
      timezoneOffset: hkt,
    );
    expect(
      quest(sep20, 'daily_make_a_zync').current,
      1,
    );
    expect(
      quest(sep20, 'daily_make_a_zync')
          .eligibility!
          .proofEventIds,
      ['after-local-midnight'],
    );
  });

  test('weekly three-Zync quest counts verified 1:1 Zyncs', () {
    final snapshot = ZyncQuestEngine.evaluate(
      events: [
        event(
          id: 'new-1',
          type: ZyncProgressEventType.oneToOneZync,
          at: DateTime.utc(2026, 9, 18, 4),
        ),
        event(
          id: 'repeat',
          type: ZyncProgressEventType.oneToOneZync,
          at: DateTime.utc(2026, 9, 18, 5),
          repeatPerson: true,
        ),
        event(
          id: 'new-2',
          type: ZyncProgressEventType.oneToOneZync,
          at: DateTime.utc(2026, 9, 19, 4),
        ),
      ],
      now: DateTime.utc(2026, 9, 19, 12),
      timezoneOffset: hkt,
    );

    final progress = quest(snapshot, 'weekly_three_zyncs');
    expect(progress.current, 3);
    expect(progress.complete, isTrue);
    expect(
      progress.eligibility!.proofEventIds,
      ['new-1', 'repeat', 'new-2'],
    );
  });

  test('Tried Together powers daily and real-world weekly progress', () {
    final snapshot = ZyncQuestEngine.evaluate(
      events: [
        event(
          id: 'did-it',
          type: ZyncProgressEventType.triedTogetherCompleted,
          at: DateTime.utc(2026, 9, 19, 10),
          categories: const ['sports'],
        ),
      ],
      now: DateTime.utc(2026, 9, 19, 12),
      timezoneOffset: hkt,
    );

    expect(
      quest(snapshot, 'daily_tried_together').current,
      1,
    );
    expect(
      quest(snapshot, 'weekly_five_real_world_actions').current,
      1,
    );
  });

  test('group activity quest requires a Tried Together group of 3+', () {
    final snapshot = ZyncQuestEngine.evaluate(
      events: [
        ZyncProgressEvent(
          id: 'group',
          type: ZyncProgressEventType.triedTogetherCompleted,
          source: ZyncProgressSource.zyncNow,
          occurredAt: DateTime.utc(2026, 9, 19, 10),
          participantCount: 4,
          interestCategories: const ['music'],
        ),
      ],
      now: DateTime.utc(2026, 9, 19, 12),
      timezoneOffset: hkt,
    );

    final progress = quest(snapshot, 'weekly_group_activity');
    expect(progress.current, 1);
    expect(progress.complete, isTrue);
    expect(progress.eligibility!.proofEventIds, ['group']);
    expect(
      progress.eligibility!.reward.kind,
      ZyncQuestRewardKind.discoveryPack,
    );
  });

  test('lifetime quests never reset and use epoch cycle start', () {
    final snapshot = ZyncQuestEngine.evaluate(
      events: [
        for (var i = 0; i < 5; i++)
          event(
            id: 'old-$i',
            type: ZyncProgressEventType.oneToOneZync,
            at: DateTime.utc(2025, 1, i + 1),
          ),
      ],
      now: DateTime.utc(2026, 9, 19, 12),
      timezoneOffset: hkt,
    );

    final progress = quest(snapshot, 'lifetime_five_zyncs');
    expect(progress.current, 5);
    expect(progress.complete, isTrue);
    expect(
      progress.cycleStart,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  });

  test('reward eligibility is explicitly non-authoritative', () {
    final snapshot = ZyncQuestEngine.evaluate(
      events: [
        event(
          id: 'zync',
          type: ZyncProgressEventType.oneToOneZync,
          at: DateTime.utc(2026, 9, 19, 10),
        ),
      ],
      now: DateTime.utc(2026, 9, 19, 12),
      timezoneOffset: hkt,
    );

    final eligibility =
        quest(snapshot, 'daily_make_a_zync').eligibility!;
    expect(eligibility.requiresServerValidation, isTrue);
    expect(eligibility.reward.requiresServerValidation, isTrue);
    expect(eligibility.reward.kind, ZyncQuestRewardKind.drawToken);
    expect(eligibility.reward.amount, 1);
  });

  test('duplicate event IDs are counted once', () {
    final duplicate = event(
      id: 'same-id',
      type: ZyncProgressEventType.oneToOneZync,
      at: DateTime.utc(2026, 9, 19, 10),
    );
    final snapshot = ZyncQuestEngine.evaluate(
      events: [duplicate, duplicate],
      now: DateTime.utc(2026, 9, 19, 12),
      timezoneOffset: hkt,
    );

    expect(
      quest(snapshot, 'weekly_five_real_world_actions').current,
      1,
    );
  });
}

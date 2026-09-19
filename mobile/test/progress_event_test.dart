import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zync/core/local_store.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/progress_event.dart';
import 'package:zync/core/zync_now_engine.dart';
import 'package:zync/core/zync_now_memory.dart';

ZyncNowCandidate _candidate() {
  return ZyncNowEngine.generate(
    participants: const [
      ZyncNowParticipant(
        id: 'a',
        interests: [
          SelectedInterest(
            id: 'sports.badminton',
            strength: InterestStrength.love,
          ),
        ],
      ),
      ZyncNowParticipant(
        id: 'b',
        interests: [
          SelectedInterest(
            id: 'sports.badminton',
            strength: InterestStrength.like,
          ),
        ],
      ),
    ],
    mode: ZyncNowMode.familiar,
    seed: 'progress-event-test',
  ).first;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('one-to-one Zync emits a coarse event without peer identity', () async {
    const peerId = 'peer-secret-123';
    const nickname = 'Private Nickname';

    await LocalStore.recordZync(
      peerId: peerId,
      peerNickname: nickname,
      sharedIds: const ['sports.badminton'],
      peerInterests: const [
        SelectedInterest(
          id: 'food.coffee',
          strength: InterestStrength.like,
        ),
      ],
    );

    final events = await LocalStore.loadProgressEvents();
    expect(events, hasLength(1));
    final event = events.single;

    expect(event.type, ZyncProgressEventType.oneToOneZync);
    expect(event.source, ZyncProgressSource.oneToOne);
    expect(event.participantCount, 2);
    expect(event.repeatPerson, isFalse);
    expect(event.interestCategories, containsAll({'sports', 'food'}));

    final encoded = jsonEncode(event.toJson());
    expect(encoded, isNot(contains(peerId)));
    expect(encoded, isNot(contains(nickname)));
    expect(encoded, isNot(contains('sports.badminton')));
    expect(encoded, isNot(contains('food.coffee')));
  });

  test('repeat peer is represented only as a boolean', () async {
    await LocalStore.recordZync(
      peerId: 'same-peer',
      peerNickname: 'Someone',
      sharedIds: const ['sports.badminton'],
    );
    await LocalStore.recordZync(
      peerId: 'same-peer',
      peerNickname: 'Someone',
      sharedIds: const ['sports.badminton'],
    );

    final events = await LocalStore.loadProgressEvents();
    expect(events, hasLength(2));
    expect(events.first.repeatPerson, isTrue);
    expect(events.last.repeatPerson, isFalse);

    final encoded = jsonEncode(events.map((item) => item.toJson()).toList());
    expect(encoded, isNot(contains('same-peer')));
    expect(encoded, isNot(contains('Someone')));
  });

  test('Tried Together completion emits one positive progress event', () async {
    final memory = await LocalStore.recordZyncNowChoice(
      candidate: _candidate(),
      chosenAt: DateTime.utc(2026, 9, 19, 12),
    );

    await LocalStore.recordZyncNowOutcome(
      memoryId: memory.id,
      status: ZyncNowActivityStatus.completed,
      at: DateTime.utc(2026, 9, 19, 13),
    );
    await LocalStore.recordZyncNowOutcome(
      memoryId: memory.id,
      status: ZyncNowActivityStatus.completed,
      at: DateTime.utc(2026, 9, 19, 14),
    );

    final events = await LocalStore.loadProgressEvents();
    expect(events, hasLength(1));
    final event = events.single;

    expect(event.type, ZyncProgressEventType.triedTogetherCompleted);
    expect(event.source, ZyncProgressSource.zyncNow);
    expect(event.participantCount, 2);
    expect(event.mode, ZyncNowMode.familiar.name);
    expect(event.interestCategories, {'sports'});

    final encoded = jsonEncode(event.toJson());
    expect(encoded, isNot(contains('sports.badminton')));
    expect(encoded, isNot(contains(memory.id)));
  });

  test('skipped Tried Together does not mint a positive event', () async {
    final memory = await LocalStore.recordZyncNowChoice(
      candidate: _candidate(),
    );

    await LocalStore.recordZyncNowOutcome(
      memoryId: memory.id,
      status: ZyncNowActivityStatus.skipped,
    );

    expect(await LocalStore.loadProgressEvents(), isEmpty);
  });

  test('malformed progress storage fails safely', () async {
    SharedPreferences.setMockInitialValues({
      'zync.progress.events.v1': '[{"bad":true}]',
    });

    expect(await LocalStore.loadProgressEvents(), isEmpty);
  });
}

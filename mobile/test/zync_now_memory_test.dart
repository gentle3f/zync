import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zync/core/local_store.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/zync_now_engine.dart';
import 'package:zync/core/zync_now_memory.dart';

ZyncNowParticipant _participant(
  String id,
  List<SelectedInterest> interests,
) =>
    ZyncNowParticipant(id: id, interests: interests);

SelectedInterest _interest(
  String id, [
  InterestStrength strength = InterestStrength.like,
]) =>
    SelectedInterest(id: id, strength: strength);

Future<ZyncNowCandidate> _candidate() async {
  final candidates = ZyncNowEngine.generate(
    participants: [
      _participant('a', [
        _interest('sports.badminton', InterestStrength.love),
      ]),
      _participant('b', [
        _interest('sports.badminton', InterestStrength.like),
      ]),
    ],
    mode: ZyncNowMode.familiar,
    seed: 'memory-test',
  );
  return candidates.first;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('chosen activity is stored without peer identity', () async {
    final candidate = await _candidate();
    final chosenAt = DateTime.utc(2026, 9, 19, 10);

    final memory = await LocalStore.recordZyncNowChoice(
      candidate: candidate,
      chosenAt: chosenAt,
    );
    final stored = await LocalStore.loadZyncNowActivities();

    expect(stored, hasLength(1));
    expect(stored.single.id, memory.id);
    expect(stored.single.candidateId, candidate.id);
    expect(stored.single.repeatKey, candidate.repeatKey);
    expect(stored.single.templateId, candidate.templateId);
    expect(stored.single.sourceInterestIds, candidate.sourceInterestIds);
    expect(stored.single.groupSize, 2);
    expect(stored.single.status, ZyncNowActivityStatus.chosen);
    expect(stored.single.chosenAt, chosenAt);
  });

  test('saved activity reconstructs its localized candidate recipe', () async {
    final candidate = await _candidate();
    final memory = await LocalStore.recordZyncNowChoice(candidate: candidate);

    final restored = memory.toCandidate();

    expect(restored.id, candidate.id);
    expect(restored.repeatKey, candidate.repeatKey);
    expect(restored.templateId, candidate.templateId);
    expect(restored.sourceInterestIds, candidate.sourceInterestIds);
    expect(restored.participantCount, candidate.participantCount);
    expect(restored.titleFor('en'), candidate.titleFor('en'));
    expect(
      restored.instructionFor('zh-Hant'),
      candidate.instructionFor('zh-Hant'),
    );
  });

  test('Did it outcome turns a choice into completed Tried Together memory',
      () async {
    final candidate = await _candidate();
    final memory = await LocalStore.recordZyncNowChoice(candidate: candidate);
    final completedAt = DateTime.utc(2026, 9, 20, 8, 30);

    final updated = await LocalStore.recordZyncNowOutcome(
      memoryId: memory.id,
      status: ZyncNowActivityStatus.completed,
      at: completedAt,
    );

    expect(updated, isNotNull);
    expect(updated!.didIt, isTrue);
    expect(updated.status, ZyncNowActivityStatus.completed);
    expect(updated.completedAt, completedAt);

    final stored = await LocalStore.loadZyncNowActivities();
    expect(stored.single.didIt, isTrue);
  });

  test('chosen and completed activities contribute recent repeat keys',
      () async {
    final candidate = await _candidate();
    final memory = await LocalStore.recordZyncNowChoice(candidate: candidate);

    expect(
      await LocalStore.recentZyncNowActivityKeys(),
      contains(candidate.repeatKey),
    );

    await LocalStore.recordZyncNowOutcome(
      memoryId: memory.id,
      status: ZyncNowActivityStatus.completed,
    );

    expect(
      await LocalStore.recentZyncNowActivityKeys(),
      contains(candidate.repeatKey),
    );
  });

  test('skipped activity stops contributing a repeat key', () async {
    final candidate = await _candidate();
    final memory = await LocalStore.recordZyncNowChoice(candidate: candidate);

    await LocalStore.recordZyncNowOutcome(
      memoryId: memory.id,
      status: ZyncNowActivityStatus.skipped,
    );

    expect(
      await LocalStore.recentZyncNowActivityKeys(),
      isNot(contains(candidate.repeatKey)),
    );
  });

  test('malformed local activity memory fails safely', () async {
    SharedPreferences.setMockInitialValues({
      'zync.zync_now.activities.v1': '{not-json',
    });

    expect(await LocalStore.loadZyncNowActivities(), isEmpty);
  });
}

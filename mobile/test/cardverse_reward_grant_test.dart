import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_reward_grant.dart';
import 'package:zync/core/quest_engine.dart';

const eligibility = ZyncQuestRewardEligibility(
  key: 'weekly_real_world_three:2026-09-14T16:00:00.000Z',
  questId: 'weekly_real_world_three',
  cycleStart: DateTime.fromMillisecondsSinceEpoch(
    1789401600000,
    isUtc: true,
  ),
  reward: ZyncQuestRewardPreview(
    kind: ZyncQuestRewardKind.standardPack,
    amount: 1,
  ),
  proofEventIds: ['event-1', 'event-2', 'event-3'],
);

void main() {
  test('quest claim carries proof but never chooses reward output', () {
    final request = CardverseQuestRewardClaimRequest.fromEligibility(
      eligibility: eligibility,
      idempotencyKey: 'claim-attempt-1',
    );
    final json = request.toJson();

    expect(json['eligibilityKey'], eligibility.key);
    expect(json['questId'], eligibility.questId);
    expect(json['proofEventIds'], eligibility.proofEventIds);
    expect(json.containsKey('rewardKind'), isFalse);
    expect(json.containsKey('amount'), isFalse);
    expect(json.containsKey('packIds'), isFalse);
    expect(json.containsKey('cards'), isFalse);
  });

  test('client-selected reward fields are rejected', () {
    for (final forbidden in const [
      'rewardKind',
      'amount',
      'packIds',
      'finish',
      'cards',
    ]) {
      expect(
        () => CardverseQuestRewardClaimRequest.fromJson({
          ...CardverseQuestRewardClaimRequest.fromEligibility(
            eligibility: eligibility,
            idempotencyKey: 'claim-attempt-1',
          ).toJson(),
          forbidden: 'client-choice',
        }),
        throwsA(isA<FormatException>()),
        reason: '$forbidden must remain server-owned',
      );
    }
  });

  test('standard-pack grant contains exactly one unopened pack per reward',
      () {
    final receipt = CardverseRewardGrantReceipt.serverValidated(
      grantId: 'grant-1',
      eligibilityKey: eligibility.key,
      questId: eligibility.questId,
      idempotencyKey: 'claim-attempt-1',
      kind: CardverseRewardGrantKind.standardPack,
      amount: 1,
      issuedAt: DateTime.utc(2026, 9, 20),
      serverSequence: 101,
      unopenedPackIds: const ['pack-server-1'],
    );

    expect(receipt.serverAuthoritative, isTrue);
    expect(receipt.unopenedPackIds, ['pack-server-1']);
    expect(receipt.matchesEligibility(eligibility), isTrue);
  });

  test('pack grant quantity must equal server-issued pack IDs', () {
    expect(
      () => CardverseRewardGrantReceipt.serverValidated(
        grantId: 'grant-bad',
        eligibilityKey: eligibility.key,
        questId: eligibility.questId,
        idempotencyKey: 'claim-attempt-1',
        kind: CardverseRewardGrantKind.standardPack,
        amount: 2,
        issuedAt: DateTime.utc(2026, 9, 20),
        serverSequence: 102,
        unopenedPackIds: const ['only-one-pack'],
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('draw-token grant cannot smuggle an unopened pack', () {
    expect(
      () => CardverseRewardGrantReceipt.serverValidated(
        grantId: 'grant-token',
        eligibilityKey: 'daily:today',
        questId: 'daily_make_a_zync',
        idempotencyKey: 'claim-token',
        kind: CardverseRewardGrantKind.drawToken,
        amount: 1,
        issuedAt: DateTime.utc(2026, 9, 20),
        serverSequence: 103,
        unopenedPackIds: const ['not-allowed'],
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('mismatched server reward does not match local eligibility', () {
    final receipt = CardverseRewardGrantReceipt.serverValidated(
      grantId: 'grant-wrong',
      eligibilityKey: eligibility.key,
      questId: eligibility.questId,
      idempotencyKey: 'claim-attempt-1',
      kind: CardverseRewardGrantKind.discoveryPack,
      amount: 1,
      issuedAt: DateTime.utc(2026, 9, 20),
      serverSequence: 104,
      unopenedPackIds: const ['pack-server-2'],
    );

    expect(receipt.matchesEligibility(eligibility), isFalse);
  });

  test('duplicate unopened pack IDs are rejected', () {
    expect(
      () => CardverseRewardGrantReceipt.serverValidated(
        grantId: 'grant-dup',
        eligibilityKey: eligibility.key,
        questId: eligibility.questId,
        idempotencyKey: 'claim-attempt-1',
        kind: CardverseRewardGrantKind.standardPack,
        amount: 2,
        issuedAt: DateTime.utc(2026, 9, 20),
        serverSequence: 105,
        unopenedPackIds: const ['same-pack', 'same-pack'],
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

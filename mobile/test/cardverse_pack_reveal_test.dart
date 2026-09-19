import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/core/cardverse_pack_reveal.dart';

CardversePackOpenReceipt receipt() =>
    CardversePackOpenReceipt.serverValidated(
      packId: 'pack-proof-1',
      serverRollId: 'server-roll-proof-1',
      idempotencyKey: 'open-proof-1',
      rolledAt: DateTime.utc(2026, 9, 19, 16),
      items: const [
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'sports.badminton',
            finishId: 'normal',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'food.coffee',
            finishId: 'foil',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'outdoors.bouldering',
            finishId: 'holo',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'music.piano',
            finishId: 'prism',
            editionId: 'discovery',
          ),
          quantity: 1,
        ),
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'travel.japan',
            finishId: 'legendary',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
      ],
    );

void main() {
  test('reveal plan is fully determined by persisted server receipt', () {
    final first = CardversePackRevealPlan.fromReceipt(receipt());
    final second = CardversePackRevealPlan.fromReceipt(receipt());

    expect(first.receiptDriven, isTrue);
    expect(first.serverRollId, 'server-roll-proof-1');
    expect(first.items, hasLength(5));
    expect(
      first.items.map((item) => item.variant.value).toList(),
      second.items.map((item) => item.variant.value).toList(),
    );
    expect(
      first.items.map((item) => item.finish).toList(),
      [
        CardFinishTier.normal,
        CardFinishTier.foil,
        CardFinishTier.holo,
        CardFinishTier.prism,
        CardFinishTier.legendary,
      ],
    );
  });

  test('resume cursor preserves the exact next committed card', () {
    final plan = CardversePackRevealPlan.fromReceipt(receipt());

    final cursor = plan.cursor(revealedCount: 3);

    expect(cursor.revealedItems, hasLength(3));
    expect(cursor.nextItem, isNotNull);
    expect(
      cursor.nextItem!.variant.interestId,
      'music.piano',
    );
    expect(cursor.progress, 3 / 5);

    final afterFourth = cursor.revealNext();
    expect(afterFourth.revealedCount, 4);
    expect(
      afterFourth.nextItem!.variant.interestId,
      'travel.japan',
    );
  });

  test('fully revealed cursor cannot reroll or reveal another card', () {
    final plan = CardversePackRevealPlan.fromReceipt(receipt());
    final cursor = plan.cursor(revealedCount: 5);

    expect(cursor.complete, isTrue);
    expect(cursor.nextItem, isNull);
    expect(
      () => cursor.revealNext(),
      throwsStateError,
    );
  });

  test('invalid resume count is rejected', () {
    final plan = CardversePackRevealPlan.fromReceipt(receipt());

    expect(
      () => plan.cursor(revealedCount: -1),
      throwsRangeError,
    );
    expect(
      () => plan.cursor(revealedCount: 6),
      throwsRangeError,
    );
  });

  test('serialized reveal checkpoint resumes only the same server roll', () {
    final plan = CardversePackRevealPlan.fromReceipt(receipt());
    final checkpoint = CardversePackRevealCheckpoint.fromJson(const {
      'serverRollId': 'server-roll-proof-1',
      'revealedCount': 3,
    });

    final resumed = checkpoint.resume(plan);

    expect(resumed.revealedCount, 3);
    expect(
      resumed.nextItem!.variant.interestId,
      'music.piano',
    );
    expect(
      checkpoint.toJson(),
      {
        'serverRollId': 'server-roll-proof-1',
        'revealedCount': 3,
      },
    );

    final otherReceipt = CardversePackOpenReceipt.serverValidated(
      packId: 'other-pack',
      serverRollId: 'different-roll',
      idempotencyKey: 'other-open',
      rolledAt: DateTime.utc(2026, 9, 19),
      items: const [
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'sports.badminton',
            finishId: 'normal',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
      ],
    );
    final otherPlan = CardversePackRevealPlan.fromReceipt(otherReceipt);

    expect(
      () => checkpoint.resume(otherPlan),
      throwsStateError,
    );
  });

  test('Reduce Motion removes suspense without changing card finish', () {
    expect(
      CardverseRevealTiming.suspenseFor(
        CardFinishTier.legendary,
        reduceMotion: true,
      ),
      Duration.zero,
    );
    expect(
      CardverseRevealTiming.suspenseFor(
        CardFinishTier.legendary,
      ),
      const Duration(milliseconds: 1050),
    );
  });

  test('unknown finish is rejected instead of silently downgraded', () {
    final bad = CardversePackOpenReceipt.serverValidated(
      packId: 'pack-bad',
      serverRollId: 'roll-bad',
      idempotencyKey: 'open-bad',
      rolledAt: DateTime.utc(2026, 9, 19),
      items: const [
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'sports.badminton',
            finishId: 'mythic-client-invented',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
      ],
    );

    expect(
      () => CardversePackRevealPlan.fromReceipt(bad),
      throwsA(isA<FormatException>()),
    );
  });

  test('unknown or unapproved card art is rejected', () {
    final bad = CardversePackOpenReceipt.serverValidated(
      packId: 'pack-bad-art',
      serverRollId: 'roll-bad-art',
      idempotencyKey: 'open-bad-art',
      rolledAt: DateTime.utc(2026, 9, 19),
      items: const [
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'fake.card.interest',
            finishId: 'normal',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
      ],
    );

    expect(
      () => CardversePackRevealPlan.fromReceipt(bad),
      throwsA(isA<FormatException>()),
    );
  });
}

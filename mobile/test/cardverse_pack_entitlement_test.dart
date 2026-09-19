import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/core/cardverse_pack_entitlement.dart';
import 'package:zync/core/cardverse_reward_grant.dart';

CardverseRewardGrantReceipt packGrant() =>
    CardverseRewardGrantReceipt.serverValidated(
      grantId: 'grant-pack-1',
      eligibilityKey: 'quest-cycle-1',
      questId: 'weekly_real_world_three',
      idempotencyKey: 'claim-1',
      kind: CardverseRewardGrantKind.standardPack,
      amount: 1,
      issuedAt: DateTime.utc(2026, 9, 20),
      serverSequence: 201,
      unopenedPackIds: const ['pack-server-1'],
    );

void main() {
  test('server grant becomes an unopened pack entitlement', () {
    final entitlement =
        CardverseUnopenedPackEntitlement.fromServerGrant(
      grant: packGrant(),
      packId: 'pack-server-1',
      serverVersion: 1,
    );

    expect(entitlement.packId, 'pack-server-1');
    expect(
      entitlement.kind,
      CardversePackEntitlementKind.standard,
    );
    expect(entitlement.sourceGrantId, 'grant-pack-1');
  });

  test('client cannot open a pack ID not present in the grant', () {
    expect(
      () => CardverseUnopenedPackEntitlement.fromServerGrant(
        grant: packGrant(),
        packId: 'pack-invented-by-client',
        serverVersion: 1,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('Draw Token reward cannot be converted into a pack', () {
    final tokenGrant =
        CardverseRewardGrantReceipt.serverValidated(
      grantId: 'grant-token',
      eligibilityKey: 'daily-cycle',
      questId: 'daily_make_a_zync',
      idempotencyKey: 'claim-token',
      kind: CardverseRewardGrantKind.drawToken,
      amount: 1,
      issuedAt: DateTime.utc(2026, 9, 20),
      serverSequence: 202,
    );

    expect(
      () => CardverseUnopenedPackEntitlement.fromServerGrant(
        grant: tokenGrant,
        packId: 'anything',
        serverVersion: 1,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('entitlement creates a bounded open request without RNG controls', () {
    final entitlement =
        CardverseUnopenedPackEntitlement.fromServerGrant(
      grant: packGrant(),
      packId: 'pack-server-1',
      serverVersion: 1,
    );

    final request = entitlement.createOpenRequest(
      idempotencyKey: 'open-1',
    );
    final json = request.toJson();

    expect(json['packId'], 'pack-server-1');
    expect(json['idempotencyKey'], 'open-1');
    expect(json.containsKey('seed'), isFalse);
    expect(json.containsKey('cards'), isFalse);
    expect(json.containsKey('finish'), isFalse);
  });

  test('only matching persisted receipt completes the open handshake', () {
    final entitlement =
        CardverseUnopenedPackEntitlement.fromServerGrant(
      grant: packGrant(),
      packId: 'pack-server-1',
      serverVersion: 1,
    );
    final request = entitlement.createOpenRequest(
      idempotencyKey: 'open-1',
    );
    final receipt = CardversePackOpenReceipt.serverValidated(
      packId: 'pack-server-1',
      serverRollId: 'roll-server-1',
      idempotencyKey: 'open-1',
      rolledAt: DateTime.utc(2026, 9, 20, 1),
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

    expect(
      entitlement.acceptsReceipt(
        request: request,
        receipt: receipt,
      ),
      isTrue,
    );

    final wrongAttempt = CardversePackOpenReceipt.serverValidated(
      packId: 'pack-server-1',
      serverRollId: 'roll-server-1',
      idempotencyKey: 'different-open-attempt',
      rolledAt: DateTime.utc(2026, 9, 20, 1),
      items: receipt.items,
    );

    expect(
      entitlement.acceptsReceipt(
        request: request,
        receipt: wrongAttempt,
      ),
      isFalse,
    );
  });
}

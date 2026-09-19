import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/core/cardverse_trade_models.dart';

void main() {
  const variantA = CardVariantKey(
    interestId: 'sports.badminton',
    finishId: 'holo',
    editionId: 'core_set_1',
  );
  const variantB = CardVariantKey(
    interestId: 'food.coffee',
    finishId: 'foil',
    editionId: 'core_set_1',
  );

  CardverseTradeProposal proposal() => CardverseTradeProposal.validated(
        tradeId: 'trade-1',
        revision: 3,
        accountA: 'account-a',
        accountB: 'account-b',
        offerFromA: [
          CardverseTradeAssetRef.stackable(
            variant: variantA,
            quantity: 2,
          ),
        ],
        offerFromB: [
          CardverseTradeAssetRef.stackable(
            variant: variantB,
            quantity: 1,
          ),
        ],
        expiresAt: DateTime.utc(2026, 9, 20),
      );

  test('direct trade requires two distinct accounts and assets on both sides',
      () {
    expect(proposal().accountA, isNot(proposal().accountB));

    expect(
      () => CardverseTradeProposal.validated(
        tradeId: 'trade-2',
        revision: 1,
        accountA: 'same',
        accountB: 'same',
        offerFromA: [
          CardverseTradeAssetRef.stackable(
            variant: variantA,
            quantity: 1,
          ),
        ],
        offerFromB: [
          CardverseTradeAssetRef.stackable(
            variant: variantB,
            quantity: 1,
          ),
        ],
        expiresAt: DateTime.utc(2026, 9, 20),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('duplicate asset references in one side are rejected', () {
    expect(
      () => CardverseTradeProposal.validated(
        tradeId: 'trade-dup',
        revision: 1,
        accountA: 'a',
        accountB: 'b',
        offerFromA: [
          CardverseTradeAssetRef.stackable(
            variant: variantA,
            quantity: 1,
          ),
          CardverseTradeAssetRef.stackable(
            variant: variantA,
            quantity: 2,
          ),
        ],
        offerFromB: [
          CardverseTradeAssetRef.unique(instanceId: 'instance-b'),
        ],
        expiresAt: DateTime.utc(2026, 9, 20),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('settlement requires both accounts to confirm the same revision', () {
    final trade = proposal();
    final now = DateTime.utc(2026, 9, 19, 12);

    expect(
      CardverseTradeContract.readyToSettle(
        proposal: trade,
        confirmations: [
          CardverseTradeConfirmation(
            tradeId: trade.tradeId,
            revision: trade.revision,
            accountId: trade.accountA,
            confirmedAt: now,
          ),
        ],
        now: now,
      ),
      isFalse,
    );

    expect(
      CardverseTradeContract.readyToSettle(
        proposal: trade,
        confirmations: [
          CardverseTradeConfirmation(
            tradeId: trade.tradeId,
            revision: trade.revision,
            accountId: trade.accountA,
            confirmedAt: now,
          ),
          CardverseTradeConfirmation(
            tradeId: trade.tradeId,
            revision: trade.revision - 1,
            accountId: trade.accountB,
            confirmedAt: now,
          ),
        ],
        now: now,
      ),
      isFalse,
    );

    expect(
      CardverseTradeContract.readyToSettle(
        proposal: trade,
        confirmations: [
          CardverseTradeConfirmation(
            tradeId: trade.tradeId,
            revision: trade.revision,
            accountId: trade.accountA,
            confirmedAt: now,
          ),
          CardverseTradeConfirmation(
            tradeId: trade.tradeId,
            revision: trade.revision,
            accountId: trade.accountB,
            confirmedAt: now,
          ),
        ],
        now: now,
      ),
      isTrue,
    );
  });

  test('expired trade cannot settle even with both confirmations', () {
    final trade = proposal();
    final afterExpiry = DateTime.utc(2026, 9, 21);

    expect(
      CardverseTradeContract.readyToSettle(
        proposal: trade,
        confirmations: [
          CardverseTradeConfirmation(
            tradeId: trade.tradeId,
            revision: trade.revision,
            accountId: trade.accountA,
            confirmedAt: DateTime.utc(2026, 9, 19),
          ),
          CardverseTradeConfirmation(
            tradeId: trade.tradeId,
            revision: trade.revision,
            accountId: trade.accountB,
            confirmedAt: DateTime.utc(2026, 9, 19),
          ),
        ],
        now: afterExpiry,
      ),
      isFalse,
    );
  });

  test('trade system explicitly excludes marketplace cash and auctions', () {
    expect(CardverseTradeContract.requiresAtomicServerTransaction, isTrue);
    expect(CardverseTradeContract.supportsCashMarketplace, isFalse);
    expect(CardverseTradeContract.supportsAuctions, isFalse);
  });

  test('trade ledger entries require trade ID and one asset movement shape', () {
    final entry = CardverseInventoryLedgerEntry.validated(
      eventId: 'ledger-1',
      serverSequence: 101,
      accountId: 'account-a',
      kind: CardverseLedgerKind.tradeOut,
      occurredAt: DateTime.utc(2026, 9, 19),
      variant: variantA,
      quantityDelta: -2,
      tradeId: 'trade-1',
    );

    expect(entry.tradeId, 'trade-1');
    expect(entry.quantityDelta, -2);

    expect(
      () => CardverseInventoryLedgerEntry.validated(
        eventId: 'ledger-bad',
        serverSequence: 102,
        accountId: 'account-a',
        kind: CardverseLedgerKind.tradeOut,
        occurredAt: DateTime.utc(2026, 9, 19),
        variant: variantA,
        quantityDelta: -1,
      ),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => CardverseInventoryLedgerEntry.validated(
        eventId: 'ledger-two-shapes',
        serverSequence: 103,
        accountId: 'account-a',
        kind: CardverseLedgerKind.tradeIn,
        occurredAt: DateTime.utc(2026, 9, 19),
        variant: variantA,
        quantityDelta: 1,
        instanceId: 'instance-1',
        tradeId: 'trade-1',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('settlement receipt is server authoritative and idempotent-keyed', () {
    final receipt = CardverseTradeSettlementReceipt.serverValidated(
      tradeId: 'trade-1',
      revision: 3,
      serverTransactionId: 'tx-server-1',
      idempotencyKey: 'trade-confirm-attempt-1',
      completedAt: DateTime.utc(2026, 9, 19, 12),
      ledgerEventIds: const ['ledger-a-out', 'ledger-b-in'],
    );

    expect(receipt.serverAuthoritative, isTrue);
    expect(receipt.idempotencyKey, 'trade-confirm-attempt-1');

    expect(
      () => CardverseTradeSettlementReceipt.serverValidated(
        tradeId: 'trade-1',
        revision: 3,
        serverTransactionId: '',
        idempotencyKey: 'trade-confirm-attempt-1',
        completedAt: DateTime.utc(2026, 9, 19, 12),
        ledgerEventIds: const ['only-one'],
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

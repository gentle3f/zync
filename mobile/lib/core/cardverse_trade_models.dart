import 'cardverse_models.dart';

enum CardverseTradeState {
  draft,
  review,
  locked,
  completed,
  cancelled,
  expired,
}

enum CardverseLedgerKind {
  packGrant,
  packOpen,
  tradeReserve,
  tradeRelease,
  tradeOut,
  tradeIn,
  questReward,
  migration,
  correction,
}

class CardverseTradeAssetRef {
  const CardverseTradeAssetRef._({
    this.variant,
    this.quantity,
    this.instanceId,
  });

  final CardVariantKey? variant;
  final int? quantity;
  final String? instanceId;

  bool get isStackable => variant != null;
  bool get isUnique => instanceId != null;

  factory CardverseTradeAssetRef.stackable({
    required CardVariantKey variant,
    required int quantity,
  }) {
    if (quantity < 1) {
      throw const FormatException('Invalid trade quantity');
    }
    return CardverseTradeAssetRef._(
      variant: variant,
      quantity: quantity,
    );
  }

  factory CardverseTradeAssetRef.unique({
    required String instanceId,
  }) {
    if (instanceId.trim().isEmpty) {
      throw const FormatException('Invalid trade instance');
    }
    return CardverseTradeAssetRef._(
      instanceId: instanceId.trim(),
    );
  }

  String get stableKey => isStackable
      ? 'stack:${variant!.value}'
      : 'instance:$instanceId';
}

class CardverseTradeProposal {
  const CardverseTradeProposal._({
    required this.tradeId,
    required this.revision,
    required this.accountA,
    required this.accountB,
    required this.offerFromA,
    required this.offerFromB,
    required this.expiresAt,
    required this.state,
  });

  final String tradeId;
  final int revision;
  final String accountA;
  final String accountB;
  final List<CardverseTradeAssetRef> offerFromA;
  final List<CardverseTradeAssetRef> offerFromB;
  final DateTime expiresAt;
  final CardverseTradeState state;

  factory CardverseTradeProposal.validated({
    required String tradeId,
    required int revision,
    required String accountA,
    required String accountB,
    required List<CardverseTradeAssetRef> offerFromA,
    required List<CardverseTradeAssetRef> offerFromB,
    required DateTime expiresAt,
    CardverseTradeState state = CardverseTradeState.review,
  }) {
    if (tradeId.trim().isEmpty ||
        revision < 1 ||
        accountA.trim().isEmpty ||
        accountB.trim().isEmpty ||
        accountA == accountB ||
        offerFromA.isEmpty ||
        offerFromB.isEmpty ||
        state == CardverseTradeState.completed ||
        state == CardverseTradeState.cancelled ||
        state == CardverseTradeState.expired) {
      throw const FormatException('Invalid direct trade proposal');
    }

    _validateDistinctAssets(offerFromA);
    _validateDistinctAssets(offerFromB);

    return CardverseTradeProposal._(
      tradeId: tradeId.trim(),
      revision: revision,
      accountA: accountA.trim(),
      accountB: accountB.trim(),
      offerFromA: List.unmodifiable(offerFromA),
      offerFromB: List.unmodifiable(offerFromB),
      expiresAt: expiresAt.toUtc(),
      state: state,
    );
  }

  static void _validateDistinctAssets(
    List<CardverseTradeAssetRef> assets,
  ) {
    final keys = <String>{};
    for (final asset in assets) {
      if (!keys.add(asset.stableKey)) {
        throw const FormatException('Duplicate asset in direct trade');
      }
    }
  }
}

class CardverseTradeConfirmation {
  const CardverseTradeConfirmation({
    required this.tradeId,
    required this.revision,
    required this.accountId,
    required this.confirmedAt,
  });

  final String tradeId;
  final int revision;
  final String accountId;
  final DateTime confirmedAt;
}

class CardverseTradeContract {
  const CardverseTradeContract._();

  static bool readyToSettle({
    required CardverseTradeProposal proposal,
    required Iterable<CardverseTradeConfirmation> confirmations,
    DateTime? now,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    if (!current.isBefore(proposal.expiresAt) ||
        (proposal.state != CardverseTradeState.review &&
            proposal.state != CardverseTradeState.locked)) {
      return false;
    }

    final confirmedAccounts = <String>{};
    for (final confirmation in confirmations) {
      if (confirmation.tradeId != proposal.tradeId ||
          confirmation.revision != proposal.revision ||
          (confirmation.accountId != proposal.accountA &&
              confirmation.accountId != proposal.accountB)) {
        continue;
      }
      confirmedAccounts.add(confirmation.accountId);
    }

    return confirmedAccounts.contains(proposal.accountA) &&
        confirmedAccounts.contains(proposal.accountB);
  }

  static bool get requiresAtomicServerTransaction => true;
  static bool get supportsCashMarketplace => false;
  static bool get supportsAuctions => false;
}

class CardverseInventoryLedgerEntry {
  const CardverseInventoryLedgerEntry._({
    required this.eventId,
    required this.serverSequence,
    required this.accountId,
    required this.kind,
    required this.occurredAt,
    this.variant,
    this.quantityDelta,
    this.instanceId,
    this.tradeId,
    this.packId,
  });

  final String eventId;
  final int serverSequence;
  final String accountId;
  final CardverseLedgerKind kind;
  final DateTime occurredAt;
  final CardVariantKey? variant;
  final int? quantityDelta;
  final String? instanceId;
  final String? tradeId;
  final String? packId;

  factory CardverseInventoryLedgerEntry.validated({
    required String eventId,
    required int serverSequence,
    required String accountId,
    required CardverseLedgerKind kind,
    required DateTime occurredAt,
    CardVariantKey? variant,
    int? quantityDelta,
    String? instanceId,
    String? tradeId,
    String? packId,
  }) {
    final hasStackableMovement =
        variant != null && quantityDelta != null && quantityDelta != 0;
    final hasUniqueMovement =
        instanceId != null && instanceId.trim().isNotEmpty;

    if (eventId.trim().isEmpty ||
        serverSequence < 1 ||
        accountId.trim().isEmpty ||
        hasStackableMovement == hasUniqueMovement) {
      throw const FormatException('Invalid inventory ledger entry');
    }

    if ((kind == CardverseLedgerKind.tradeIn ||
            kind == CardverseLedgerKind.tradeOut ||
            kind == CardverseLedgerKind.tradeReserve ||
            kind == CardverseLedgerKind.tradeRelease) &&
        (tradeId == null || tradeId.trim().isEmpty)) {
      throw const FormatException('Trade ledger entry requires trade ID');
    }

    return CardverseInventoryLedgerEntry._(
      eventId: eventId.trim(),
      serverSequence: serverSequence,
      accountId: accountId.trim(),
      kind: kind,
      occurredAt: occurredAt.toUtc(),
      variant: variant,
      quantityDelta: quantityDelta,
      instanceId: instanceId?.trim(),
      tradeId: tradeId?.trim(),
      packId: packId?.trim(),
    );
  }
}

class CardverseTradeSettlementReceipt {
  const CardverseTradeSettlementReceipt._({
    required this.tradeId,
    required this.revision,
    required this.serverTransactionId,
    required this.idempotencyKey,
    required this.completedAt,
    required this.ledgerEventIds,
  });

  final String tradeId;
  final int revision;
  final String serverTransactionId;
  final String idempotencyKey;
  final DateTime completedAt;
  final List<String> ledgerEventIds;

  factory CardverseTradeSettlementReceipt.serverValidated({
    required String tradeId,
    required int revision,
    required String serverTransactionId,
    required String idempotencyKey,
    required DateTime completedAt,
    required List<String> ledgerEventIds,
  }) {
    if (tradeId.trim().isEmpty ||
        revision < 1 ||
        serverTransactionId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty ||
        ledgerEventIds.length < 2 ||
        ledgerEventIds.any((item) => item.trim().isEmpty)) {
      throw const FormatException('Invalid direct trade settlement receipt');
    }

    return CardverseTradeSettlementReceipt._(
      tradeId: tradeId.trim(),
      revision: revision,
      serverTransactionId: serverTransactionId.trim(),
      idempotencyKey: idempotencyKey.trim(),
      completedAt: completedAt.toUtc(),
      ledgerEventIds: List.unmodifiable(ledgerEventIds),
    );
  }

  bool get serverAuthoritative => true;
}

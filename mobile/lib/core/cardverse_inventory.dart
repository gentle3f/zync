import 'cardverse_models.dart';

class CardverseUnopenedPack {
  const CardverseUnopenedPack({
    required this.packId,
    required this.packType,
    required this.issuedAt,
  });

  final String packId;
  final String packType;
  final DateTime issuedAt;
}

class CardverseInventoryCard {
  const CardverseInventoryCard({
    required this.variant,
    required this.quantity,
  });

  final CardVariantKey variant;
  final int quantity;
}

class CardverseInventorySnapshot {
  const CardverseInventorySnapshot({
    required this.accountId,
    required this.ledgerCursor,
    required this.drawTokens,
    required this.lockedDrawTokens,
    required this.claimedEligibilityKeys,
    required this.cards,
    required this.unopenedPacks,
  });

  final String accountId;
  final int ledgerCursor;
  final int drawTokens;
  final int lockedDrawTokens;
  final Set<String> claimedEligibilityKeys;
  final List<CardverseInventoryCard> cards;
  final List<CardverseUnopenedPack> unopenedPacks;

  int get availableDrawTokens => drawTokens - lockedDrawTokens;
  int get ownedCardCopies =>
      cards.fold<int>(0, (sum, item) => sum + item.quantity);
  int get discoveredVariants => cards.length;

  factory CardverseInventorySnapshot.fromJson(Map<String, dynamic> json) {
    int number(Object? value, {int fallback = 0}) =>
        value is num ? value.toInt() : fallback;

    final account = json['account'];
    final accountId = account is Map
        ? (account['id'] as String?)?.trim() ?? ''
        : '';
    final ledgerCursor = number(json['ledgerCursor']);
    final draw = json['drawTokens'];
    final drawTokens = draw is Map ? number(draw['quantity']) : 0;
    final lockedDrawTokens =
        draw is Map ? number(draw['lockedQuantity']) : 0;

    if (accountId.isEmpty ||
        ledgerCursor < 0 ||
        drawTokens < 0 ||
        lockedDrawTokens < 0 ||
        lockedDrawTokens > drawTokens) {
      throw const FormatException('Invalid Cardverse inventory snapshot');
    }

    final quantities = <String, int>{};

    final balances = json['balances'];
    if (balances is List) {
      for (final raw in balances) {
        if (raw is! Map) continue;
        final key = (raw['variantKey'] as String?)?.trim() ?? '';
        final quantity = number(raw['quantity']);
        if (key.isEmpty || quantity < 0) {
          throw const FormatException('Invalid Cardverse stack balance');
        }
        if (quantity > 0) {
          CardVariantKey.parse(key);
          quantities[key] = (quantities[key] ?? 0) + quantity;
        }
      }
    }

    final unique = json['uniqueInstances'];
    if (unique is List) {
      for (final raw in unique) {
        if (raw is! Map) continue;
        final key = (raw['variantKey'] as String?)?.trim() ?? '';
        if (key.isEmpty) {
          throw const FormatException('Invalid Cardverse unique instance');
        }
        CardVariantKey.parse(key);
        quantities[key] = (quantities[key] ?? 0) + 1;
      }
    }

    final cards = quantities.entries
        .map(
          (entry) => CardverseInventoryCard(
            variant: CardVariantKey.parse(entry.key),
            quantity: entry.value,
          ),
        )
        .toList(growable: false)
      ..sort(
        (a, b) => a.variant.interestId.compareTo(b.variant.interestId),
      );

    final packs = <CardverseUnopenedPack>[];
    final rawPacks = json['unopenedPacks'];
    if (rawPacks is List) {
      for (final raw in rawPacks) {
        if (raw is! Map) continue;
        final packId = (raw['packId'] as String?)?.trim() ?? '';
        final packType = (raw['packType'] as String?)?.trim() ?? '';
        final issuedAt = DateTime.tryParse(
          (raw['issuedAt'] as String?) ?? '',
        )?.toUtc();
        if (packId.isEmpty || packType.isEmpty || issuedAt == null) {
          throw const FormatException('Invalid Cardverse unopened pack');
        }
        packs.add(
          CardverseUnopenedPack(
            packId: packId,
            packType: packType,
            issuedAt: issuedAt,
          ),
        );
      }
    }

    final claimed = ((json['claimedEligibilityKeys'] as List?) ?? const [])
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    return CardverseInventorySnapshot(
      accountId: accountId,
      ledgerCursor: ledgerCursor,
      drawTokens: drawTokens,
      lockedDrawTokens: lockedDrawTokens,
      claimedEligibilityKeys: Set.unmodifiable(claimed),
      cards: List.unmodifiable(cards),
      unopenedPacks: List.unmodifiable(packs),
    );
  }
}

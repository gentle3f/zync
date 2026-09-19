enum CardFinishTier {
  normal,
  foil,
  holo,
  prism,
  legendary,
  secret,
}

enum CardEditionKind {
  core,
  encounter,
  discovery,
  event,
  starter,
  achievement,
}

enum CardOwnershipKind {
  stackable,
  unique,
}

enum CardTradability {
  tradable,
  soulbound,
}

enum CardAcquisitionSource {
  pack,
  encounter,
  quest,
  event,
  migration,
  trade,
}

enum CardverseIdentityProvider {
  google,
  apple,
}

class CardverseAccount {
  const CardverseAccount({
    required this.accountId,
    this.identityLinks = const [],
  });

  final String accountId;
  final List<CardverseIdentityLink> identityLinks;
}

class CardverseIdentityLink {
  const CardverseIdentityLink({
    required this.provider,
    required this.providerSubject,
    required this.linkedAt,
  });

  final CardverseIdentityProvider provider;
  final String providerSubject;
  final DateTime linkedAt;
}

class CardDefinition {
  const CardDefinition({
    required this.interestId,
    required this.cardNumber,
    required this.artSystemVersion,
    required this.visualSeed,
    required this.visualFamily,
  });

  final String interestId;
  final int cardNumber;
  final int artSystemVersion;
  final String visualSeed;
  final String visualFamily;

  factory CardDefinition.fromInterest({
    required String interestId,
    required int cardNumber,
    required int artSystemVersion,
    required String visualFamily,
  }) {
    final normalized = interestId.trim();
    if (normalized.isEmpty ||
        cardNumber < 1 ||
        artSystemVersion < 1 ||
        visualFamily.trim().isEmpty) {
      throw const FormatException('Invalid Cardverse card definition');
    }

    return CardDefinition(
      interestId: normalized,
      cardNumber: cardNumber,
      artSystemVersion: artSystemVersion,
      visualSeed: CardVisualIdentity.seedFor(
        interestId: normalized,
        artSystemVersion: artSystemVersion,
      ),
      visualFamily: visualFamily.trim(),
    );
  }
}

class CardFinishDefinition {
  const CardFinishDefinition({
    required this.id,
    required this.tier,
    required this.ownershipKind,
  });

  final String id;
  final CardFinishTier tier;
  final CardOwnershipKind ownershipKind;
}

class CardEditionDefinition {
  const CardEditionDefinition({
    required this.id,
    required this.kind,
    required this.defaultTradability,
    this.serialLimited = false,
  });

  final String id;
  final CardEditionKind kind;
  final CardTradability defaultTradability;
  final bool serialLimited;
}

class CardVariantKey {
  const CardVariantKey({
    required this.interestId,
    required this.finishId,
    required this.editionId,
  });

  final String interestId;
  final String finishId;
  final String editionId;

  String get value => '$interestId::$finishId::$editionId';

  factory CardVariantKey.parse(String raw) {
    final parts = raw.split('::');
    if (parts.length != 3 || parts.any((item) => item.trim().isEmpty)) {
      throw const FormatException('Invalid Cardverse variant key');
    }
    return CardVariantKey(
      interestId: parts[0],
      finishId: parts[1],
      editionId: parts[2],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CardVariantKey &&
      other.interestId == interestId &&
      other.finishId == finishId &&
      other.editionId == editionId;

  @override
  int get hashCode => Object.hash(interestId, finishId, editionId);
}

class StackableCardBalance {
  const StackableCardBalance._({
    required this.accountId,
    required this.variant,
    required this.quantity,
    required this.lockedQuantity,
    required this.version,
  });

  final String accountId;
  final CardVariantKey variant;
  final int quantity;
  final int lockedQuantity;
  final int version;

  int get availableQuantity => quantity - lockedQuantity;

  factory StackableCardBalance.validated({
    required String accountId,
    required CardVariantKey variant,
    required int quantity,
    int lockedQuantity = 0,
    int version = 0,
  }) {
    if (accountId.trim().isEmpty ||
        quantity < 0 ||
        lockedQuantity < 0 ||
        lockedQuantity > quantity ||
        version < 0) {
      throw const FormatException('Invalid stackable card balance');
    }
    return StackableCardBalance._(
      accountId: accountId,
      variant: variant,
      quantity: quantity,
      lockedQuantity: lockedQuantity,
      version: version,
    );
  }
}

class CardInstance {
  const CardInstance._({
    required this.instanceId,
    required this.ownerAccountId,
    required this.variant,
    required this.acquiredAt,
    required this.acquisitionSource,
    required this.locked,
    this.serialNumber,
    this.tradabilityOverride,
    this.tradeCount = 0,
  });

  final String instanceId;
  final String ownerAccountId;
  final CardVariantKey variant;
  final DateTime acquiredAt;
  final CardAcquisitionSource acquisitionSource;
  final bool locked;
  final int? serialNumber;
  final CardTradability? tradabilityOverride;
  final int tradeCount;

  factory CardInstance.validated({
    required String instanceId,
    required String ownerAccountId,
    required CardVariantKey variant,
    required DateTime acquiredAt,
    required CardAcquisitionSource acquisitionSource,
    bool locked = false,
    int? serialNumber,
    CardTradability? tradabilityOverride,
    int tradeCount = 0,
  }) {
    if (instanceId.trim().isEmpty ||
        ownerAccountId.trim().isEmpty ||
        (serialNumber != null && serialNumber < 1) ||
        tradeCount < 0) {
      throw const FormatException('Invalid unique card instance');
    }
    return CardInstance._(
      instanceId: instanceId,
      ownerAccountId: ownerAccountId,
      variant: variant,
      acquiredAt: acquiredAt.toUtc(),
      acquisitionSource: acquisitionSource,
      locked: locked,
      serialNumber: serialNumber,
      tradabilityOverride: tradabilityOverride,
      tradeCount: tradeCount,
    );
  }
}

class CardverseTradabilityPolicy {
  const CardverseTradabilityPolicy._();

  static CardTradability effective({
    required CardEditionDefinition edition,
    CardInstance? instance,
  }) {
    return instance?.tradabilityOverride ?? edition.defaultTradability;
  }

  static bool canTrade({
    required CardEditionDefinition edition,
    CardInstance? instance,
  }) {
    if (instance?.locked ?? false) return false;
    return effective(edition: edition, instance: instance) ==
        CardTradability.tradable;
  }

  static CardEditionDefinition encounterEdition({
    String id = 'encounter',
  }) =>
      CardEditionDefinition(
        id: id,
        kind: CardEditionKind.encounter,
        defaultTradability: CardTradability.soulbound,
      );

  static CardEditionDefinition starterEdition({
    String id = 'starter',
  }) =>
      CardEditionDefinition(
        id: id,
        kind: CardEditionKind.starter,
        defaultTradability: CardTradability.soulbound,
      );

  static CardEditionDefinition achievementEdition({
    String id = 'achievement',
  }) =>
      CardEditionDefinition(
        id: id,
        kind: CardEditionKind.achievement,
        defaultTradability: CardTradability.soulbound,
      );

  static CardEditionDefinition coreEdition({
    String id = 'core_set_1',
  }) =>
      CardEditionDefinition(
        id: id,
        kind: CardEditionKind.core,
        defaultTradability: CardTradability.tradable,
      );
}

class CardversePackOpenRequest {
  const CardversePackOpenRequest({
    required this.packId,
    required this.idempotencyKey,
    required this.clientRevealVersion,
  });

  final String packId;
  final String idempotencyKey;
  final int clientRevealVersion;

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'idempotencyKey': idempotencyKey,
        'clientRevealVersion': clientRevealVersion,
      };

  factory CardversePackOpenRequest.fromJson(Map<String, dynamic> json) {
    final packId = (json['packId'] as String?)?.trim() ?? '';
    final idempotencyKey =
        (json['idempotencyKey'] as String?)?.trim() ?? '';
    final revealVersion =
        (json['clientRevealVersion'] as num?)?.toInt() ?? 0;

    const forbidden = {
      'seed',
      'randomSeed',
      'result',
      'cards',
      'finish',
      'rarity',
      'odds',
    };
    if (json.keys.any(forbidden.contains) ||
        packId.isEmpty ||
        idempotencyKey.isEmpty ||
        revealVersion < 1) {
      throw const FormatException('Invalid Cardverse pack-open request');
    }

    return CardversePackOpenRequest(
      packId: packId,
      idempotencyKey: idempotencyKey,
      clientRevealVersion: revealVersion,
    );
  }
}

class CardversePackResultItem {
  const CardversePackResultItem({
    required this.variant,
    required this.quantity,
    this.instanceId,
  });

  final CardVariantKey variant;
  final int quantity;
  final String? instanceId;
}

class CardversePackOpenReceipt {
  const CardversePackOpenReceipt._({
    required this.packId,
    required this.serverRollId,
    required this.idempotencyKey,
    required this.rolledAt,
    required this.items,
  });

  final String packId;
  final String serverRollId;
  final String idempotencyKey;
  final DateTime rolledAt;
  final List<CardversePackResultItem> items;

  factory CardversePackOpenReceipt.serverValidated({
    required String packId,
    required String serverRollId,
    required String idempotencyKey,
    required DateTime rolledAt,
    required List<CardversePackResultItem> items,
  }) {
    if (packId.trim().isEmpty ||
        serverRollId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty ||
        items.isEmpty ||
        items.any((item) => item.quantity < 1)) {
      throw const FormatException('Invalid Cardverse pack receipt');
    }
    return CardversePackOpenReceipt._(
      packId: packId,
      serverRollId: serverRollId,
      idempotencyKey: idempotencyKey,
      rolledAt: rolledAt.toUtc(),
      items: List.unmodifiable(items),
    );
  }

  bool get serverAuthoritative => true;
}

class CardVisualIdentity {
  const CardVisualIdentity._();

  static String seedFor({
    required String interestId,
    required int artSystemVersion,
  }) {
    if (interestId.trim().isEmpty || artSystemVersion < 1) {
      throw const FormatException('Invalid Cardverse visual identity');
    }

    var hash = 0x811C9DC5;
    final source = 'card-art-v$artSystemVersion|${interestId.trim()}';
    for (final code in source.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

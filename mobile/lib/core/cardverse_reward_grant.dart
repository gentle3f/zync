import 'quest_engine.dart';

enum CardverseRewardGrantKind {
  drawToken,
  standardPack,
  discoveryPack,
}

class CardverseQuestRewardClaimRequest {
  const CardverseQuestRewardClaimRequest._({
    required this.eligibilityKey,
    required this.questId,
    required this.cycleStart,
    required this.proofEventIds,
    required this.idempotencyKey,
    required this.clientContractVersion,
  });

  final String eligibilityKey;
  final String questId;
  final DateTime cycleStart;
  final List<String> proofEventIds;
  final String idempotencyKey;
  final int clientContractVersion;

  factory CardverseQuestRewardClaimRequest.fromEligibility({
    required ZyncQuestRewardEligibility eligibility,
    required String idempotencyKey,
    int clientContractVersion = 1,
  }) {
    final key = eligibility.key.trim();
    final questId = eligibility.questId.trim();
    final idem = idempotencyKey.trim();
    final proof = eligibility.proofEventIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (key.isEmpty ||
        questId.isEmpty ||
        idem.isEmpty ||
        proof.isEmpty ||
        clientContractVersion < 1) {
      throw const FormatException(
        'Invalid Cardverse quest reward claim',
      );
    }

    return CardverseQuestRewardClaimRequest._(
      eligibilityKey: key,
      questId: questId,
      cycleStart: eligibility.cycleStart.toUtc(),
      proofEventIds: List.unmodifiable(proof),
      idempotencyKey: idem,
      clientContractVersion: clientContractVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'eligibilityKey': eligibilityKey,
        'questId': questId,
        'cycleStart': cycleStart.toIso8601String(),
        'proofEventIds': proofEventIds,
        'idempotencyKey': idempotencyKey,
        'clientContractVersion': clientContractVersion,
      };

  factory CardverseQuestRewardClaimRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    const forbidden = {
      'reward',
      'rewardKind',
      'kind',
      'amount',
      'drawTokens',
      'packId',
      'packIds',
      'finish',
      'rarity',
      'cards',
    };

    if (json.keys.any(forbidden.contains)) {
      throw const FormatException(
        'Client cannot choose Cardverse quest reward output',
      );
    }

    final key = (json['eligibilityKey'] as String?)?.trim() ?? '';
    final questId = (json['questId'] as String?)?.trim() ?? '';
    final cycleStart =
        DateTime.tryParse((json['cycleStart'] as String?) ?? '');
    final idempotencyKey =
        (json['idempotencyKey'] as String?)?.trim() ?? '';
    final version =
        (json['clientContractVersion'] as num?)?.toInt() ?? 0;
    final proof = ((json['proofEventIds'] as List?) ?? const [])
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (key.isEmpty ||
        questId.isEmpty ||
        cycleStart == null ||
        idempotencyKey.isEmpty ||
        version < 1 ||
        proof.isEmpty) {
      throw const FormatException(
        'Invalid Cardverse quest reward claim',
      );
    }

    return CardverseQuestRewardClaimRequest._(
      eligibilityKey: key,
      questId: questId,
      cycleStart: cycleStart.toUtc(),
      proofEventIds: List.unmodifiable(proof),
      idempotencyKey: idempotencyKey,
      clientContractVersion: version,
    );
  }
}

class CardverseRewardGrantReceipt {
  const CardverseRewardGrantReceipt._({
    required this.grantId,
    required this.eligibilityKey,
    required this.questId,
    required this.idempotencyKey,
    required this.kind,
    required this.amount,
    required this.issuedAt,
    required this.serverSequence,
    required this.unopenedPackIds,
  });

  final String grantId;
  final String eligibilityKey;
  final String questId;
  final String idempotencyKey;
  final CardverseRewardGrantKind kind;
  final int amount;
  final DateTime issuedAt;
  final int serverSequence;

  /// Only populated for pack grants. These are unopened server-owned pack
  /// entitlements, not card results and not client-side RNG handles.
  final List<String> unopenedPackIds;

  bool get serverAuthoritative => true;

  factory CardverseRewardGrantReceipt.serverValidated({
    required String grantId,
    required String eligibilityKey,
    required String questId,
    required String idempotencyKey,
    required CardverseRewardGrantKind kind,
    required int amount,
    required DateTime issuedAt,
    required int serverSequence,
    List<String> unopenedPackIds = const [],
  }) {
    final packs = unopenedPackIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final isPack = kind == CardverseRewardGrantKind.standardPack ||
        kind == CardverseRewardGrantKind.discoveryPack;

    if (grantId.trim().isEmpty ||
        eligibilityKey.trim().isEmpty ||
        questId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty ||
        amount < 1 ||
        serverSequence < 1 ||
        packs.toSet().length != packs.length ||
        (isPack && packs.length != amount) ||
        (!isPack && packs.isNotEmpty)) {
      throw const FormatException(
        'Invalid Cardverse reward grant receipt',
      );
    }

    return CardverseRewardGrantReceipt._(
      grantId: grantId.trim(),
      eligibilityKey: eligibilityKey.trim(),
      questId: questId.trim(),
      idempotencyKey: idempotencyKey.trim(),
      kind: kind,
      amount: amount,
      issuedAt: issuedAt.toUtc(),
      serverSequence: serverSequence,
      unopenedPackIds: List.unmodifiable(packs),
    );
  }

  bool matchesEligibility(ZyncQuestRewardEligibility eligibility) {
    return eligibilityKey == eligibility.key &&
        questId == eligibility.questId &&
        kind == expectedGrantKind(eligibility.reward.kind) &&
        amount == eligibility.reward.amount;
  }

  static CardverseRewardGrantKind expectedGrantKind(
    ZyncQuestRewardKind kind,
  ) =>
      switch (kind) {
        ZyncQuestRewardKind.drawToken =>
          CardverseRewardGrantKind.drawToken,
        ZyncQuestRewardKind.standardPack =>
          CardverseRewardGrantKind.standardPack,
        ZyncQuestRewardKind.discoveryPack =>
          CardverseRewardGrantKind.discoveryPack,
      };
}

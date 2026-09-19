import 'card_visual_recipe.dart';
import 'cardverse_models.dart';

class CardversePackRevealItem {
  const CardversePackRevealItem({
    required this.variant,
    required this.recipe,
    required this.finish,
    required this.quantity,
    required this.editionLabel,
    this.instanceId,
  });

  final CardVariantKey variant;
  final CardVisualRecipe recipe;
  final CardFinishTier finish;
  final int quantity;
  final String editionLabel;
  final String? instanceId;

  bool get focusAnimationRecommended =>
      finish == CardFinishTier.holo ||
      finish == CardFinishTier.prism ||
      finish == CardFinishTier.legendary ||
      finish == CardFinishTier.secret;
}

class CardversePackRevealPlan {
  const CardversePackRevealPlan._({
    required this.receipt,
    required this.items,
  });

  final CardversePackOpenReceipt receipt;
  final List<CardversePackRevealItem> items;

  bool get receiptDriven => true;
  String get serverRollId => receipt.serverRollId;

  factory CardversePackRevealPlan.fromReceipt(
    CardversePackOpenReceipt receipt,
  ) {
    if (!receipt.serverAuthoritative) {
      throw const FormatException(
        'Cardverse reveal requires a server-authoritative receipt',
      );
    }

    final items = <CardversePackRevealItem>[];
    for (final source in receipt.items) {
      final recipe =
          CardVisualRecipeResolver.resolve(source.variant.interestId);
      if (recipe == null) {
        throw FormatException(
          'No approved visual recipe for '
          '${source.variant.interestId}',
        );
      }

      items.add(
        CardversePackRevealItem(
          variant: source.variant,
          recipe: recipe,
          finish: _finishFromId(source.variant.finishId),
          quantity: source.quantity,
          editionLabel: _editionLabel(source.variant.editionId),
          instanceId: source.instanceId,
        ),
      );
    }

    return CardversePackRevealPlan._(
      receipt: receipt,
      items: List.unmodifiable(items),
    );
  }

  CardversePackRevealCursor cursor({
    int revealedCount = 0,
  }) =>
      CardversePackRevealCursor._(
        plan: this,
        revealedCount: revealedCount,
      );

  static CardFinishTier _finishFromId(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'normal' => CardFinishTier.normal,
      'foil' => CardFinishTier.foil,
      'holo' => CardFinishTier.holo,
      'prism' => CardFinishTier.prism,
      'legendary' => CardFinishTier.legendary,
      'secret' => CardFinishTier.secret,
      _ => throw FormatException('Unknown Cardverse finish: $raw'),
    };
  }

  static String _editionLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const FormatException('Missing Cardverse edition');
    }
    if (normalized == 'core' || normalized.startsWith('core_')) {
      return 'CORE';
    }
    if (normalized == 'encounter') return 'ENCOUNTER';
    if (normalized == 'discovery') return 'DISCOVERY';
    if (normalized == 'starter') return 'STARTER';
    if (normalized == 'achievement') return 'ACHIEVEMENT';
    if (normalized == 'event' || normalized.startsWith('event_')) {
      return 'EVENT';
    }
    throw FormatException('Unknown Cardverse edition: $raw');
  }
}

class CardversePackRevealCheckpoint {
  const CardversePackRevealCheckpoint({
    required this.serverRollId,
    required this.revealedCount,
  });

  final String serverRollId;
  final int revealedCount;

  Map<String, dynamic> toJson() => {
        'serverRollId': serverRollId,
        'revealedCount': revealedCount,
      };

  factory CardversePackRevealCheckpoint.fromJson(
    Map<String, dynamic> json,
  ) {
    final rollId = (json['serverRollId'] as String?)?.trim() ?? '';
    final count = (json['revealedCount'] as num?)?.toInt() ?? -1;
    if (rollId.isEmpty || count < 0) {
      throw const FormatException(
        'Invalid Cardverse reveal checkpoint',
      );
    }
    return CardversePackRevealCheckpoint(
      serverRollId: rollId,
      revealedCount: count,
    );
  }

  CardversePackRevealCursor resume(
    CardversePackRevealPlan plan,
  ) {
    if (plan.serverRollId != serverRollId) {
      throw StateError(
        'Reveal checkpoint belongs to a different server roll',
      );
    }
    return plan.cursor(revealedCount: revealedCount);
  }
}

class CardversePackRevealCursor {
  CardversePackRevealCursor._({
    required this.plan,
    required this.revealedCount,
  }) {
    if (revealedCount < 0 || revealedCount > plan.items.length) {
      throw RangeError.range(
        revealedCount,
        0,
        plan.items.length,
        'revealedCount',
      );
    }
  }

  final CardversePackRevealPlan plan;
  final int revealedCount;

  bool get complete => revealedCount >= plan.items.length;

  CardversePackRevealItem? get nextItem =>
      complete ? null : plan.items[revealedCount];

  List<CardversePackRevealItem> get revealedItems =>
      List.unmodifiable(plan.items.take(revealedCount));

  double get progress =>
      plan.items.isEmpty ? 1.0 : revealedCount / plan.items.length;

  CardversePackRevealCursor revealNext() {
    if (complete) {
      throw StateError('Cardverse pack is already fully revealed');
    }
    return CardversePackRevealCursor._(
      plan: plan,
      revealedCount: revealedCount + 1,
    );
  }
}

class CardverseRevealTiming {
  const CardverseRevealTiming._();

  static Duration suspenseFor(
    CardFinishTier finish, {
    bool reduceMotion = false,
  }) {
    if (reduceMotion) return Duration.zero;

    return switch (finish) {
      CardFinishTier.normal => const Duration(milliseconds: 350),
      CardFinishTier.foil => const Duration(milliseconds: 450),
      CardFinishTier.holo => const Duration(milliseconds: 650),
      CardFinishTier.prism => const Duration(milliseconds: 800),
      CardFinishTier.legendary => const Duration(milliseconds: 1050),
      CardFinishTier.secret => const Duration(milliseconds: 1200),
    };
  }
}

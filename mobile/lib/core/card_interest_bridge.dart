import 'interest_catalog.dart';
import 'models.dart';

class CardInterestIntentBridge {
  const CardInterestIntentBridge._();

  static SelectedInterest wantToTry(String interestId) {
    final normalized = interestId.trim();
    if (normalized.isEmpty || InterestCatalog.byId(normalized) == null) {
      throw ArgumentError.value(
        interestId,
        'interestId',
        'Want to Try requires a canonical Zync interest',
      );
    }
    return SelectedInterest(
      id: normalized,
      strength: InterestStrength.wantToTry,
    );
  }

  static List<SelectedInterest> upsertWantToTry({
    required List<SelectedInterest> existing,
    required String interestId,
  }) {
    final candidate = wantToTry(interestId);
    final updated = existing.toList(growable: true);
    final index = updated.indexWhere((item) => item.id == candidate.id);

    if (index < 0) {
      updated.add(candidate);
      return List.unmodifiable(updated);
    }

    final current = updated[index];

    // Card discovery must never downgrade a stronger declared interest.
    if (current.strength == InterestStrength.like ||
        current.strength == InterestStrength.love) {
      return List.unmodifiable(updated);
    }

    updated[index] = current.copyWith(
      strength: InterestStrength.wantToTry,
    );
    return List.unmodifiable(updated);
  }

  static List<SelectedInterest> removeWantToTry({
    required List<SelectedInterest> existing,
    required String interestId,
  }) {
    final updated = <SelectedInterest>[];
    for (final item in existing) {
      if (item.id == interestId &&
          item.strength == InterestStrength.wantToTry) {
        continue;
      }
      updated.add(item);
    }
    return List.unmodifiable(updated);
  }
}

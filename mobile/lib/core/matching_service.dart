import 'models.dart';

class MatchingService {
  const MatchingService._();

  static MatchResult compare(List<SelectedInterest> mine, List<SelectedInterest> theirs) {
    final mineById = {for (final item in mine) item.id: item};
    final theirById = {for (final item in theirs) item.id: item};

    final sharedIds = mineById.keys.toSet().intersection(theirById.keys.toSet());
    final shared = sharedIds.map((id) {
      final a = mineById[id]!;
      final b = theirById[id]!;
      final lower = a.strength.wireValue < b.strength.wireValue ? a.strength : b.strength;
      return SelectedInterest(
        id: id,
        strength: lower,
        customLabel: a.customLabel ?? b.customLabel,
        customCategory: a.customCategory ?? b.customCategory,
      );
    }).toList()
      ..sort((a, b) => b.strength.wireValue.compareTo(a.strength.wireValue));

    final onlyMine = mine.where((item) => !sharedIds.contains(item.id)).toList();
    final onlyTheirs = theirs.where((item) => !sharedIds.contains(item.id)).toList();

    return MatchResult(shared: shared, onlyMine: onlyMine, onlyTheirs: onlyTheirs);
  }
}

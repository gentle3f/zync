import 'dart:convert';

import 'models.dart';

class MatchingService {
  const MatchingService._();

  static MatchResult compare(
    List<SelectedInterest> mine,
    List<SelectedInterest> theirs, {
    String sessionSeed = '',
  }) {
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
      ..sort((a, b) {
        final strength = b.strength.wireValue.compareTo(a.strength.wireValue);
        if (strength != 0) return strength;
        if (sessionSeed.isNotEmpty) {
          final seeded = _seedScore(sessionSeed, a.id).compareTo(_seedScore(sessionSeed, b.id));
          if (seeded != 0) return seeded;
        }
        return a.id.compareTo(b.id);
      });

    final onlyMine = mine.where((item) => !sharedIds.contains(item.id)).toList();
    final onlyTheirs = theirs.where((item) => !sharedIds.contains(item.id)).toList();

    return MatchResult(shared: shared, onlyMine: onlyMine, onlyTheirs: onlyTheirs);
  }

  static int _seedScore(String seed, String id) {
    var hash = 0x811C9DC5;
    for (final byte in utf8.encode('$seed|$id')) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}

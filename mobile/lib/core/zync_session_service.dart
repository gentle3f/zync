import 'dart:convert';

import 'interest_catalog.dart';
import 'models.dart';

class ZyncConnection {
  const ZyncConnection({
    required this.primary,
    required this.context,
    required this.isNew,
    required this.magicScore,
  });

  final SharedInterestDetail primary;
  final List<SharedInterestDetail> context;
  final bool isNew;
  final int magicScore;

  String get id => primary.id;

  MatchResult get focusedMatch => MatchResult(
        shared: [primary.merged],
        sharedDetails: [primary],
        onlyMine: const [],
        onlyTheirs: const [],
      );
}

class ZyncCrossover {
  const ZyncCrossover({
    required this.mine,
    required this.theirs,
    required this.bridgeScore,
  });

  final SelectedInterest mine;
  final SelectedInterest theirs;
  final int bridgeScore;

  String get connectionKey => 'cross:${mine.id}>${theirs.id}';

  MatchResult get focusedMatch => MatchResult(
        shared: const [],
        onlyMine: [mine],
        onlyTheirs: [theirs],
      );
}

/// Converts raw exact matches into the human-facing Zync Session.
///
/// Matching remains exact-ID-only. This layer only decides which exact matches
/// deserve their own reveal moment, and in what deterministic order.
class ZyncSessionService {
  const ZyncSessionService._();

  static List<ZyncConnection> exactConnections(
    MatchResult match, {
    Set<String> previousSharedIds = const {},
    String sessionSeed = '',
  }) {
    final details = match.sharedDetails.isNotEmpty
        ? match.sharedDetails
        : match.shared
            .map((item) => SharedInterestDetail(mine: item, theirs: item))
            .toList(growable: false);
    if (details.isEmpty) return const [];

    final visible = details.where((candidate) {
      return !details.any(
        (other) => InterestCatalog.isBroadAncestorOf(candidate.id, other.id),
      );
    }).toList();

    final connections = visible.map((primary) {
      final context = details
          .where(
            (other) =>
                other.id != primary.id &&
                InterestCatalog.isBroadAncestorOf(other.id, primary.id),
          )
          .toList(growable: false);
      final threadIds = <String>{primary.id, ...context.map((item) => item.id)};
      final isNew = threadIds.any((id) => !previousSharedIds.contains(id));
      return ZyncConnection(
        primary: primary,
        context: context,
        isNew: isNew,
        magicScore: _magicScore(
          primary,
          isNew: isNew,
          sessionSeed: sessionSeed,
        ),
      );
    }).toList()
      ..sort((a, b) {
        final score = b.magicScore.compareTo(a.magicScore);
        if (score != 0) return score;
        return a.id.compareTo(b.id);
      });

    return List.unmodifiable(connections);
  }

  static ZyncCrossover? bestCrossover(
    MatchResult match, {
    String sessionSeed = '',
  }) {
    if (match.onlyMine.isEmpty || match.onlyTheirs.isEmpty) return null;

    ZyncCrossover? best;
    var bestScore = 1 << 30;
    for (final mine in match.onlyMine.take(20)) {
      for (final theirs in match.onlyTheirs.take(20)) {
        final distance = InterestCatalog.relationshipDistance(mine.id, theirs.id);
        final strength =
            (mine.strength.wireValue + theirs.strength.wireValue + 2) * 9;
        final specificity =
            InterestCatalog.specificityScore(mine.id) +
            InterestCatalog.specificityScore(theirs.id);
        final jitter = _seedScore(sessionSeed, '${mine.id}|${theirs.id}') % 11;
        final score = (distance * 100) - strength - specificity + jitter;
        if (score < bestScore) {
          bestScore = score;
          best = ZyncCrossover(
            mine: mine,
            theirs: theirs,
            bridgeScore: score,
          );
        }
      }
    }
    return best;
  }

  static int _magicScore(
    SharedInterestDetail detail, {
    required bool isNew,
    required String sessionSeed,
  }) {
    final definition = InterestCatalog.byId(detail.id);
    final rank = definition?.rank ?? 1800;
    final rarity = ((rank - 20) / 70).clamp(0, 28).round();
    final specificity = InterestCatalog.specificityScore(detail.id);
    final mutualStrength =
        (detail.mine.strength.wireValue + detail.theirs.strength.wireValue + 2) *
        10;
    final newBonus = isNew ? 80 : 0;
    final jitter = _seedScore(sessionSeed, detail.id) % 7;
    return newBonus + specificity + rarity + mutualStrength + jitter;
  }

  static int _seedScore(String seed, String value) {
    var hash = 0x811C9DC5;
    for (final byte in utf8.encode('$seed|$value')) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}

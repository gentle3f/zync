import 'interest_catalog.dart';
import 'models.dart';

class AchievementProgress {
  const AchievementProgress({
    required this.id,
    required this.current,
    required this.target,
  });

  final String id;
  final int current;
  final int target;

  bool get unlocked => current >= target;
  double get fraction => target <= 0 ? 1 : (current / target).clamp(0, 1);
}

class AchievementSnapshot {
  const AchievementSnapshot({
    required this.progress,
    required this.distinctPeople,
    required this.discoveredSports,
    required this.discoveredInterests,
  });

  final List<AchievementProgress> progress;
  final int distinctPeople;
  final Set<String> discoveredSports;
  final Set<String> discoveredInterests;

  int get unlockedCount => progress.where((item) => item.unlocked).length;
  Set<String> get unlockedIds =>
      progress.where((item) => item.unlocked).map((item) => item.id).toSet();
}

class AchievementService {
  const AchievementService._();

  static AchievementSnapshot evaluate(List<ZyncHistoryEntry> history) {
    final uniquePeers = <String, ZyncHistoryEntry>{};
    for (final entry in history) {
      uniquePeers[entry.peerId] = entry;
    }

    final discoveredSports = <String>{};
    final discoveredInterests = <String>{};
    var basketballPeople = 0;

    for (final entry in uniquePeers.values) {
      final peerInterestIds = <String>{
        ...entry.previousSharedIds,
        ...entry.peerInterests.map((item) => item.id),
      };

      if (peerInterestIds.contains('sports.basketball')) {
        basketballPeople += 1;
      }

      for (final id in peerInterestIds) {
        discoveredInterests.add(id);
        if (InterestCatalog.byId(id)?.category == 'sports') {
          discoveredSports.add(id);
        }
      }
    }

    final people = uniquePeers.length;
    final progress = <AchievementProgress>[
      AchievementProgress(id: 'first_zync', current: people, target: 1),
      AchievementProgress(id: 'people_five', current: people, target: 5),
      AchievementProgress(
        id: 'basketball_starting_five',
        current: basketballPeople,
        target: 5,
      ),
      AchievementProgress(
        id: 'sports_five',
        current: discoveredSports.length,
        target: 5,
      ),
      AchievementProgress(
        id: 'sports_ten',
        current: discoveredSports.length,
        target: 10,
      ),
      AchievementProgress(
        id: 'curiosity_25',
        current: discoveredInterests.length,
        target: 25,
      ),
    ];

    return AchievementSnapshot(
      progress: List.unmodifiable(progress),
      distinctPeople: people,
      discoveredSports: Set.unmodifiable(discoveredSports),
      discoveredInterests: Set.unmodifiable(discoveredInterests),
    );
  }

  static Set<String> newlyUnlocked({
    required List<ZyncHistoryEntry> before,
    required List<ZyncHistoryEntry> after,
  }) {
    final beforeIds = evaluate(before).unlockedIds;
    final afterIds = evaluate(after).unlockedIds;
    return afterIds.difference(beforeIds);
  }
}

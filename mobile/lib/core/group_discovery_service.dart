import 'dart:convert';

import 'group_zync_protocol.dart';
import 'interest_catalog.dart';
import 'models.dart';
import 'zync_now_engine.dart';

enum GroupDiscoveryMechanic {
  allTogether,
  hiddenCluster,
  majorityPattern,
  onlyOne,
  whoKnowsThis,
}

class GroupDiscoveryCandidate {
  const GroupDiscoveryCandidate({
    required this.id,
    required this.mechanic,
    required this.interestId,
    required this.participantIds,
    required this.score,
  });

  final String id;
  final GroupDiscoveryMechanic mechanic;
  final String interestId;
  final List<String> participantIds;
  final double score;

  int get subsetSize => participantIds.length;
}

class GroupDiscoveryPlan {
  const GroupDiscoveryPlan({
    required this.candidates,
    required this.participantCount,
  });

  final List<GroupDiscoveryCandidate> candidates;
  final int participantCount;
}

class GroupDiscoveryPlanner {
  const GroupDiscoveryPlanner._();

  static GroupDiscoveryPlan build({
    required List<GroupParticipantProfile> participants,
    String seed = '',
    int limit = 3,
    Map<String, int> previousTargetCounts = const {},
  }) {
    if (participants.length < 3 || participants.length > 8) {
      throw ArgumentError.value(
        participants.length,
        'participants',
        'Group Zync discovery requires 3 to 8 participants',
      );
    }
    if (limit <= 0) {
      return GroupDiscoveryPlan(
        candidates: const [],
        participantCount: participants.length,
      );
    }

    final ids = participants.map((item) => item.participantId).toList();
    if (ids.toSet().length != ids.length) {
      throw ArgumentError('Duplicate Group Zync participant IDs');
    }

    final holders = <String,
        List<({String participantId, SelectedInterest interest})>>{};
    for (final participant in participants) {
      final seen = <String>{};
      for (final interest in participant.interests) {
        if (!seen.add(interest.id)) continue;
        holders.putIfAbsent(interest.id, () => []).add(
              (
                participantId: participant.participantId,
                interest: interest,
              ),
            );
      }
    }

    final raw = <GroupDiscoveryCandidate>[];
    for (final entry in holders.entries) {
      final interestId = entry.key;
      final matches = entry.value;
      final exactIds = matches.map((item) => item.participantId).toList()
        ..sort();
      final count = exactIds.length;
      final n = participants.length;
      final specificity = InterestCatalog.specificityScore(interestId);
      final rank = InterestCatalog.byId(interestId)?.rank ?? 1800;
      final rarity = ((rank - 20) / 90).clamp(0, 22).toDouble();
      final strength = matches
              .map((item) => item.interest.strength.wireValue + 1)
              .fold<int>(0, (sum, value) => sum + value) /
          count;
      final fairnessPenalty = exactIds
              .map((id) => previousTargetCounts[id] ?? 0)
              .fold<int>(0, (sum, value) => sum + value) *
          7.0;

      void add(
        GroupDiscoveryMechanic mechanic,
        double mechanicBonus,
      ) {
        final jitter = _jitter(
          '$seed|${mechanic.name}|$interestId|${exactIds.join(',')}',
        );
        raw.add(
          GroupDiscoveryCandidate(
            id: 'group.${mechanic.name}.$interestId.${exactIds.join('-')}',
            mechanic: mechanic,
            interestId: interestId,
            participantIds: List.unmodifiable(exactIds),
            score: specificity +
                rarity +
                strength * 9 +
                mechanicBonus +
                jitter -
                fairnessPenalty,
          ),
        );
      }

      if (count == n) {
        add(GroupDiscoveryMechanic.allTogether, 22);
      } else if (count >= 2) {
        add(GroupDiscoveryMechanic.hiddenCluster, 18);
        if (count > n / 2) {
          add(GroupDiscoveryMechanic.majorityPattern, 12);
        }
      } else if (count == 1) {
        add(GroupDiscoveryMechanic.onlyOne, 10);
        if (matches.single.interest.strength == InterestStrength.love) {
          add(GroupDiscoveryMechanic.whoKnowsThis, 16);
        }
      }
    }

    raw.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.id.compareTo(b.id);
    });

    final selected = <GroupDiscoveryCandidate>[];
    final usedMechanics = <GroupDiscoveryMechanic>{};
    final usedInterestIds = <String>{};

    for (final candidate in raw) {
      if (usedInterestIds.contains(candidate.interestId)) continue;
      if (selected.length < 2 && usedMechanics.contains(candidate.mechanic)) {
        continue;
      }
      selected.add(candidate);
      usedMechanics.add(candidate.mechanic);
      usedInterestIds.add(candidate.interestId);
      if (selected.length >= limit) break;
    }

    if (selected.length < limit) {
      for (final candidate in raw) {
        if (selected.any((item) => item.id == candidate.id)) continue;
        if (usedInterestIds.contains(candidate.interestId)) continue;
        selected.add(candidate);
        usedInterestIds.add(candidate.interestId);
        if (selected.length >= limit) break;
      }
    }

    return GroupDiscoveryPlan(
      candidates: List.unmodifiable(selected),
      participantCount: participants.length,
    );
  }

  static List<ZyncNowParticipant> toZyncNowParticipants(
    List<GroupParticipantProfile> participants,
  ) =>
      participants
          .map(
            (item) => ZyncNowParticipant(
              id: item.participantId,
              interests: item.interests,
            ),
          )
          .toList(growable: false);

  static double _jitter(String value) {
    var hash = 0x811C9DC5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return (hash % 1000) / 1000 * 3.0;
  }
}

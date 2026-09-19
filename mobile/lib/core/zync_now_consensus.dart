import 'dart:convert';

import 'zync_now_engine.dart';

enum ZyncNowConsensusMethod {
  quickVote,
  rank,
  eliminateOne,
}

enum ZyncNowVote {
  love,
  okay,
  no,
}

enum ZyncNowConsensusStatus {
  decided,
  needsRelaxation,
}

class ZyncNowConsensusBallot {
  const ZyncNowConsensusBallot({
    required this.participantId,
    this.ratings = const {},
    this.ranking = const [],
    this.eliminateCandidateId,
    this.hardVetoCandidateIds = const {},
  });

  final String participantId;
  final Map<String, ZyncNowVote> ratings;
  final List<String> ranking;
  final String? eliminateCandidateId;

  /// Candidate-level "I genuinely cannot / will not do this" vetoes.
  /// These are different from a normal no vote and are always respected.
  final Set<String> hardVetoCandidateIds;
}

class ZyncNowCandidateConsensus {
  const ZyncNowCandidateConsensus({
    required this.candidateId,
    required this.hardVetoCount,
    required this.loveCount,
    required this.okayCount,
    required this.noCount,
    required this.rankPoints,
    required this.firstPlaceCount,
    required this.eliminateVotes,
    required this.preferencePoints,
    required this.baseScore,
  });

  final String candidateId;
  final int hardVetoCount;
  final int loveCount;
  final int okayCount;
  final int noCount;
  final int rankPoints;
  final int firstPlaceCount;
  final int eliminateVotes;
  final int preferencePoints;
  final double baseScore;
}

class ZyncNowConsensusResult {
  const ZyncNowConsensusResult({
    required this.status,
    required this.method,
    required this.candidateStats,
    required this.remainingCandidateIds,
    required this.usedTieBreak,
    this.chosenCandidateId,
  });

  final ZyncNowConsensusStatus status;
  final ZyncNowConsensusMethod method;
  final String? chosenCandidateId;
  final List<ZyncNowCandidateConsensus> candidateStats;
  final List<String> remainingCandidateIds;
  final bool usedTieBreak;

  bool get hasDecision =>
      status == ZyncNowConsensusStatus.decided &&
      chosenCandidateId != null;
}

class ZyncNowConsensusEngine {
  const ZyncNowConsensusEngine._();

  static ZyncNowConsensusResult resolve({
    required List<ZyncNowCandidate> candidates,
    required List<String> participantIds,
    required List<ZyncNowConsensusBallot> ballots,
    required ZyncNowConsensusMethod method,
    String seed = '',
  }) {
    _validateInputs(
      candidates: candidates,
      participantIds: participantIds,
      ballots: ballots,
      method: method,
    );

    final candidateIds = candidates.map((item) => item.id).toList();
    final candidateById = {
      for (final candidate in candidates) candidate.id: candidate,
    };

    final stats = <String, _MutableConsensusStats>{
      for (final candidate in candidates)
        candidate.id: _MutableConsensusStats(
          candidateId: candidate.id,
          baseScore: candidate.score,
        ),
    };

    for (final ballot in ballots) {
      for (final candidateId in ballot.hardVetoCandidateIds) {
        stats[candidateId]!.hardVetoCount += 1;
      }

      switch (method) {
        case ZyncNowConsensusMethod.quickVote:
          for (final candidateId in candidateIds) {
            final vote = ballot.ratings[candidateId]!;
            final item = stats[candidateId]!;
            switch (vote) {
              case ZyncNowVote.love:
                item.loveCount += 1;
                item.preferencePoints += 2;
              case ZyncNowVote.okay:
                item.okayCount += 1;
                item.preferencePoints += 1;
              case ZyncNowVote.no:
                item.noCount += 1;
            }
          }

        case ZyncNowConsensusMethod.rank:
          final count = candidateIds.length;
          for (var index = 0; index < ballot.ranking.length; index += 1) {
            final candidateId = ballot.ranking[index];
            final item = stats[candidateId]!;
            item.rankPoints += count - index;
            if (index == 0) item.firstPlaceCount += 1;
          }

        case ZyncNowConsensusMethod.eliminateOne:
          final eliminated = ballot.eliminateCandidateId!;
          stats[eliminated]!.eliminateVotes += 1;
      }
    }

    final available = candidateIds
        .where((id) => stats[id]!.hardVetoCount == 0)
        .toList(growable: false);

    final publicStats = candidateIds
        .map((id) => stats[id]!.freeze())
        .toList(growable: false);

    if (available.isEmpty) {
      return ZyncNowConsensusResult(
        status: ZyncNowConsensusStatus.needsRelaxation,
        method: method,
        candidateStats: publicStats,
        remainingCandidateIds: const [],
        usedTieBreak: false,
      );
    }

    final ordered = available.toList()
      ..sort(
        (a, b) => _compareCandidate(
          a: stats[a]!,
          b: stats[b]!,
          method: method,
          candidateById: candidateById,
          seed: seed,
        ),
      );

    final best = ordered.first;
    final tied = ordered.where((id) {
      return _sameDecisionTier(
        a: stats[best]!,
        b: stats[id]!,
        method: method,
      );
    }).toList(growable: false);

    final chosen = tied.length == 1
        ? best
        : _deterministicTieBreak(
            tied,
            seed: seed,
            candidateById: candidateById,
          );

    return ZyncNowConsensusResult(
      status: ZyncNowConsensusStatus.decided,
      method: method,
      chosenCandidateId: chosen,
      candidateStats: publicStats,
      remainingCandidateIds: List.unmodifiable(available),
      usedTieBreak: tied.length > 1,
    );
  }

  static void _validateInputs({
    required List<ZyncNowCandidate> candidates,
    required List<String> participantIds,
    required List<ZyncNowConsensusBallot> ballots,
    required ZyncNowConsensusMethod method,
  }) {
    if (candidates.isEmpty || candidates.length > 5) {
      throw ArgumentError.value(
        candidates.length,
        'candidates',
        'Zync Now consensus supports 1 to 5 candidates',
      );
    }
    if (participantIds.length < 2 || participantIds.length > 8) {
      throw ArgumentError.value(
        participantIds.length,
        'participantIds',
        'Zync Now consensus supports 2 to 8 participants',
      );
    }

    final candidateIds = candidates.map((item) => item.id).toList();
    final candidateSet = candidateIds.toSet();
    if (candidateSet.length != candidateIds.length) {
      throw ArgumentError('Duplicate Zync Now candidate IDs');
    }

    final participantSet = participantIds.toSet();
    if (participantSet.length != participantIds.length) {
      throw ArgumentError('Duplicate Zync Now participant IDs');
    }

    if (ballots.length != participantIds.length) {
      throw ArgumentError(
        'Zync Now consensus requires one private ballot per participant',
      );
    }

    final ballotIds = ballots.map((item) => item.participantId).toList();
    if (ballotIds.toSet().length != ballotIds.length ||
        ballotIds.toSet().difference(participantSet).isNotEmpty ||
        participantSet.difference(ballotIds.toSet()).isNotEmpty) {
      throw ArgumentError('Invalid Zync Now ballot participant set');
    }

    for (final ballot in ballots) {
      if (ballot.hardVetoCandidateIds.difference(candidateSet).isNotEmpty) {
        throw ArgumentError('Unknown hard-veto candidate');
      }

      switch (method) {
        case ZyncNowConsensusMethod.quickVote:
          if (ballot.ratings.keys.toSet().length != candidateSet.length ||
              ballot.ratings.keys.toSet().difference(candidateSet).isNotEmpty ||
              candidateSet.difference(ballot.ratings.keys.toSet()).isNotEmpty) {
            throw ArgumentError(
              'Quick Vote requires one rating for every candidate',
            );
          }

        case ZyncNowConsensusMethod.rank:
          if (ballot.ranking.length != candidateIds.length ||
              ballot.ranking.toSet().length != candidateIds.length ||
              ballot.ranking.toSet().difference(candidateSet).isNotEmpty) {
            throw ArgumentError(
              'Rank requires every candidate exactly once',
            );
          }

        case ZyncNowConsensusMethod.eliminateOne:
          final eliminated = ballot.eliminateCandidateId;
          if (eliminated == null || !candidateSet.contains(eliminated)) {
            throw ArgumentError(
              'Eliminate One requires one valid candidate',
            );
          }
      }
    }
  }

  static int _compareCandidate({
    required _MutableConsensusStats a,
    required _MutableConsensusStats b,
    required ZyncNowConsensusMethod method,
    required Map<String, ZyncNowCandidate> candidateById,
    required String seed,
  }) {
    int compareDescending(num left, num right) => right.compareTo(left);
    int compareAscending(num left, num right) => left.compareTo(right);

    switch (method) {
      case ZyncNowConsensusMethod.quickVote:
        var result = compareAscending(a.noCount, b.noCount);
        if (result != 0) return result;
        result = compareDescending(a.preferencePoints, b.preferencePoints);
        if (result != 0) return result;
        result = compareDescending(a.loveCount, b.loveCount);
        if (result != 0) return result;

      case ZyncNowConsensusMethod.rank:
        var result = compareDescending(a.rankPoints, b.rankPoints);
        if (result != 0) return result;
        result = compareDescending(a.firstPlaceCount, b.firstPlaceCount);
        if (result != 0) return result;

      case ZyncNowConsensusMethod.eliminateOne:
        final result = compareAscending(a.eliminateVotes, b.eliminateVotes);
        if (result != 0) return result;
    }

    final base = compareDescending(a.baseScore, b.baseScore);
    if (base != 0) return base;

    return _tieValue(
      a.candidateId,
      seed,
    ).compareTo(
      _tieValue(b.candidateId, seed),
    );
  }

  static bool _sameDecisionTier({
    required _MutableConsensusStats a,
    required _MutableConsensusStats b,
    required ZyncNowConsensusMethod method,
  }) {
    return switch (method) {
      ZyncNowConsensusMethod.quickVote =>
        a.noCount == b.noCount &&
            a.preferencePoints == b.preferencePoints &&
            a.loveCount == b.loveCount,
      ZyncNowConsensusMethod.rank =>
        a.rankPoints == b.rankPoints &&
            a.firstPlaceCount == b.firstPlaceCount,
      ZyncNowConsensusMethod.eliminateOne =>
        a.eliminateVotes == b.eliminateVotes,
    };
  }

  static String _deterministicTieBreak(
    List<String> candidateIds, {
    required String seed,
    required Map<String, ZyncNowCandidate> candidateById,
  }) {
    final ordered = candidateIds.toList()
      ..sort((a, b) {
        final base = candidateById[b]!.score.compareTo(candidateById[a]!.score);
        if (base != 0) return base;
        return _tieValue(a, seed).compareTo(_tieValue(b, seed));
      });
    return ordered.first;
  }

  static int _tieValue(String candidateId, String seed) {
    var hash = 0x811C9DC5;
    for (final byte in utf8.encode('$seed|$candidateId')) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _MutableConsensusStats {
  _MutableConsensusStats({
    required this.candidateId,
    required this.baseScore,
  });

  final String candidateId;
  final double baseScore;
  int hardVetoCount = 0;
  int loveCount = 0;
  int okayCount = 0;
  int noCount = 0;
  int rankPoints = 0;
  int firstPlaceCount = 0;
  int eliminateVotes = 0;
  int preferencePoints = 0;

  ZyncNowCandidateConsensus freeze() => ZyncNowCandidateConsensus(
        candidateId: candidateId,
        hardVetoCount: hardVetoCount,
        loveCount: loveCount,
        okayCount: okayCount,
        noCount: noCount,
        rankPoints: rankPoints,
        firstPlaceCount: firstPlaceCount,
        eliminateVotes: eliminateVotes,
        preferencePoints: preferencePoints,
        baseScore: baseScore,
      );
}

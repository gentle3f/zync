import 'group_zync_protocol.dart';
import 'zync_now_consensus.dart';
import 'zync_now_engine.dart';

class ZyncNowConsensusTransportRound {
  ZyncNowConsensusTransportRound({
    required this.roundNumber,
    required this.method,
    required List<ZyncNowCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates),
       _candidateByOptionId = {
         for (var i = 0; i < candidates.length; i += 1)
           optionIdForIndex(i): candidates[i],
       } {
    if (roundNumber < 1 || roundNumber > 99) {
      throw ArgumentError.value(roundNumber, 'roundNumber');
    }
    if (candidates.length < 2 || candidates.length > 3) {
      throw ArgumentError.value(
        candidates.length,
        'candidates',
        'Group Zync Now consensus uses 2 or 3 finalists',
      );
    }
    if (candidates.map((item) => item.id).toSet().length != candidates.length) {
      throw ArgumentError('Duplicate Zync Now candidate IDs');
    }
  }

  final int roundNumber;
  final ZyncNowConsensusMethod method;
  final List<ZyncNowCandidate> candidates;
  final Map<String, ZyncNowCandidate> _candidateByOptionId;

  static String optionIdForIndex(int index) =>
      'ZYNCNOW_OPTION_${index.toString().padLeft(8, '0')}';

  List<GroupBoundedOption> optionsFor(String locale) =>
      _candidateByOptionId.entries
          .map(
            (entry) => GroupBoundedOption(
              id: entry.key,
              label: entry.value.titleFor(locale),
            ),
          )
          .toList(growable: false);

  int get requiredSelections => switch (method) {
        ZyncNowConsensusMethod.quickVote => candidates.length,
        ZyncNowConsensusMethod.rank => candidates.length,
        ZyncNowConsensusMethod.eliminateOne => 1,
      };

  String get inputKind => switch (method) {
        ZyncNowConsensusMethod.quickVote => 'zync_now_quick_vote',
        ZyncNowConsensusMethod.rank => 'zync_now_rank',
        ZyncNowConsensusMethod.eliminateOne => 'zync_now_eliminate_one',
      };

  String optionIdForCandidate(String candidateId) {
    for (final entry in _candidateByOptionId.entries) {
      if (entry.value.id == candidateId) return entry.key;
    }
    throw ArgumentError.value(candidateId, 'candidateId');
  }

  String candidateIdForOption(String optionId) {
    final candidate = _candidateByOptionId[optionId];
    if (candidate == null) {
      throw ArgumentError.value(optionId, 'optionId');
    }
    return candidate.id;
  }

  GroupPrivateInput encodeBallot(ZyncNowConsensusBallot ballot) {
    final candidateIds = candidates.map((item) => item.id).toSet();
    if (ballot.hardVetoCandidateIds.difference(candidateIds).isNotEmpty) {
      throw ArgumentError('Unknown hard-veto candidate');
    }

    final answers = <String>[];

    switch (method) {
      case ZyncNowConsensusMethod.quickVote:
        if (ballot.ratings.keys.toSet().length != candidates.length ||
            ballot.ratings.keys.toSet().difference(candidateIds).isNotEmpty ||
            candidateIds.difference(ballot.ratings.keys.toSet()).isNotEmpty) {
          throw ArgumentError('Quick Vote needs one rating per finalist');
        }
        for (final candidate in candidates) {
          final optionId = optionIdForCandidate(candidate.id);
          final code = switch (ballot.ratings[candidate.id]!) {
            ZyncNowVote.love => 'L',
            ZyncNowVote.okay => 'O',
            ZyncNowVote.no => 'N',
          };
          answers.add('R-$code-$optionId');
        }

      case ZyncNowConsensusMethod.rank:
        if (ballot.ranking.length != candidates.length ||
            ballot.ranking.toSet().length != candidates.length ||
            ballot.ranking.toSet().difference(candidateIds).isNotEmpty) {
          throw ArgumentError('Rank needs each finalist exactly once');
        }
        for (final candidateId in ballot.ranking) {
          answers.add('K-${optionIdForCandidate(candidateId)}');
        }

      case ZyncNowConsensusMethod.eliminateOne:
        final candidateId = ballot.eliminateCandidateId;
        if (candidateId == null || !candidateIds.contains(candidateId)) {
          throw ArgumentError('Eliminate One needs one finalist');
        }
        answers.add('E-${optionIdForCandidate(candidateId)}');
    }

    for (final candidateId in ballot.hardVetoCandidateIds) {
      answers.add('V-${optionIdForCandidate(candidateId)}');
    }

    if (answers.length > 8) {
      throw ArgumentError('Consensus ballot is too large');
    }

    return GroupPrivateInput(
      roundNumber: roundNumber,
      participantId: ballot.participantId,
      answerIds: List.unmodifiable(answers),
    );
  }

  ZyncNowConsensusBallot decodeBallot(GroupPrivateInput input) {
    if (input.roundNumber != roundNumber) {
      throw const FormatException('Wrong Zync Now consensus round');
    }

    final ratings = <String, ZyncNowVote>{};
    final ranking = <String>[];
    String? eliminateCandidateId;
    final vetoes = <String>{};

    for (final token in input.answerIds) {
      if (token.startsWith('V-')) {
        final optionId = token.substring(2);
        vetoes.add(_decodeOption(optionId));
        continue;
      }

      switch (method) {
        case ZyncNowConsensusMethod.quickVote:
          final parts = token.split('-');
          if (parts.length < 3 || parts.first != 'R') {
            throw const FormatException('Invalid Quick Vote token');
          }
          final code = parts[1];
          final optionId = parts.sublist(2).join('-');
          final candidateId = _decodeOption(optionId);
          final vote = switch (code) {
            'L' => ZyncNowVote.love,
            'O' => ZyncNowVote.okay,
            'N' => ZyncNowVote.no,
            _ => throw const FormatException('Invalid Quick Vote rating'),
          };
          if (ratings.containsKey(candidateId)) {
            throw const FormatException('Duplicate Quick Vote candidate');
          }
          ratings[candidateId] = vote;

        case ZyncNowConsensusMethod.rank:
          if (!token.startsWith('K-')) {
            throw const FormatException('Invalid rank token');
          }
          final candidateId = _decodeOption(token.substring(2));
          if (ranking.contains(candidateId)) {
            throw const FormatException('Duplicate ranked candidate');
          }
          ranking.add(candidateId);

        case ZyncNowConsensusMethod.eliminateOne:
          if (!token.startsWith('E-') || eliminateCandidateId != null) {
            throw const FormatException('Invalid eliminate token');
          }
          eliminateCandidateId = _decodeOption(token.substring(2));
      }
    }

    final ballot = ZyncNowConsensusBallot(
      participantId: input.participantId,
      ratings: Map.unmodifiable(ratings),
      ranking: List.unmodifiable(ranking),
      eliminateCandidateId: eliminateCandidateId,
      hardVetoCandidateIds: Set.unmodifiable(vetoes),
    );

    encodeBallot(ballot);
    return ballot;
  }

  GroupPrivateInput encodeOptionBallot({
    required String participantId,
    required Map<String, ZyncNowVote> ratingsByOptionId,
    List<String> rankedOptionIds = const [],
    String? eliminateOptionId,
    Set<String> hardVetoOptionIds = const {},
  }) {
    final ratings = <String, ZyncNowVote>{
      for (final entry in ratingsByOptionId.entries)
        candidateIdForOption(entry.key): entry.value,
    };
    final ranking = rankedOptionIds
        .map(candidateIdForOption)
        .toList(growable: false);
    final eliminateCandidateId = eliminateOptionId == null
        ? null
        : candidateIdForOption(eliminateOptionId);
    final vetoes = hardVetoOptionIds
        .map(candidateIdForOption)
        .toSet();

    return encodeBallot(
      ZyncNowConsensusBallot(
        participantId: participantId,
        ratings: ratings,
        ranking: ranking,
        eliminateCandidateId: eliminateCandidateId,
        hardVetoCandidateIds: vetoes,
      ),
    );
  }

  String? optionIdForResult(ZyncNowConsensusResult result) {
    final candidateId = result.chosenCandidateId;
    if (candidateId == null) return null;
    return optionIdForCandidate(candidateId);
  }

  String _decodeOption(String optionId) {
    final candidate = _candidateByOptionId[optionId];
    if (candidate == null) {
      throw const FormatException('Unknown Zync Now option');
    }
    return candidate.id;
  }
}

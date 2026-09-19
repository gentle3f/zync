import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/zync_now_consensus.dart';
import 'package:zync/core/zync_now_engine.dart';

ZyncNowCandidate _candidate(
  String id, {
  double score = 50,
}) =>
    ZyncNowCandidate(
      id: id,
      kind: ZyncNowCandidateKind.safe,
      mode: ZyncNowMode.familiar,
      templateId: 'activity.play_casual',
      sourceInterestIds: const ['sports.badminton'],
      repeatKey: 'activity.play_casual|sports.badminton',
      score: score,
      selectedParticipantCount: 2,
      participantCount: 4,
    );

ZyncNowConsensusBallot _quick(
  String participantId, {
  required Map<String, ZyncNowVote> ratings,
  Set<String> vetoes = const {},
}) =>
    ZyncNowConsensusBallot(
      participantId: participantId,
      ratings: ratings,
      hardVetoCandidateIds: vetoes,
    );

void main() {
  final candidates = [
    _candidate('safe', score: 80),
    _candidate('discovery', score: 70),
    _candidate('wildcard', score: 60),
  ];

  test('quick vote prefers broad acceptance over polarising popularity', () {
    final result = ZyncNowConsensusEngine.resolve(
      candidates: candidates,
      participantIds: const ['a', 'b', 'c', 'd'],
      method: ZyncNowConsensusMethod.quickVote,
      seed: 'least-misery',
      ballots: [
        _quick('a', ratings: const {
          'safe': ZyncNowVote.love,
          'discovery': ZyncNowVote.okay,
          'wildcard': ZyncNowVote.no,
        }),
        _quick('b', ratings: const {
          'safe': ZyncNowVote.love,
          'discovery': ZyncNowVote.okay,
          'wildcard': ZyncNowVote.no,
        }),
        _quick('c', ratings: const {
          'safe': ZyncNowVote.love,
          'discovery': ZyncNowVote.okay,
          'wildcard': ZyncNowVote.okay,
        }),
        _quick('d', ratings: const {
          'safe': ZyncNowVote.no,
          'discovery': ZyncNowVote.okay,
          'wildcard': ZyncNowVote.love,
        }),
      ],
    );

    expect(result.hasDecision, isTrue);
    expect(result.chosenCandidateId, 'discovery');
    final safe = result.candidateStats.firstWhere(
      (item) => item.candidateId == 'safe',
    );
    final discovery = result.candidateStats.firstWhere(
      (item) => item.candidateId == 'discovery',
    );
    expect(safe.loveCount, 3);
    expect(safe.noCount, 1);
    expect(discovery.noCount, 0);
  });

  test('one genuine hard veto always removes a candidate', () {
    final result = ZyncNowConsensusEngine.resolve(
      candidates: candidates,
      participantIds: const ['a', 'b'],
      method: ZyncNowConsensusMethod.quickVote,
      ballots: [
        _quick(
          'a',
          ratings: const {
            'safe': ZyncNowVote.love,
            'discovery': ZyncNowVote.okay,
            'wildcard': ZyncNowVote.no,
          },
          vetoes: const {'safe'},
        ),
        _quick('b', ratings: const {
          'safe': ZyncNowVote.love,
          'discovery': ZyncNowVote.okay,
          'wildcard': ZyncNowVote.no,
        }),
      ],
    );

    expect(result.chosenCandidateId, isNot('safe'));
    expect(result.remainingCandidateIds, isNot(contains('safe')));
    expect(
      result.candidateStats
          .firstWhere((item) => item.candidateId == 'safe')
          .hardVetoCount,
      1,
    );
  });

  test('rank uses group Borda preference then first-place count', () {
    final result = ZyncNowConsensusEngine.resolve(
      candidates: candidates,
      participantIds: const ['a', 'b', 'c'],
      method: ZyncNowConsensusMethod.rank,
      ballots: const [
        ZyncNowConsensusBallot(
          participantId: 'a',
          ranking: ['wildcard', 'discovery', 'safe'],
        ),
        ZyncNowConsensusBallot(
          participantId: 'b',
          ranking: ['discovery', 'wildcard', 'safe'],
        ),
        ZyncNowConsensusBallot(
          participantId: 'c',
          ranking: ['discovery', 'safe', 'wildcard'],
        ),
      ],
    );

    expect(result.chosenCandidateId, 'discovery');
    final discovery = result.candidateStats.firstWhere(
      (item) => item.candidateId == 'discovery',
    );
    expect(discovery.firstPlaceCount, 2);
  });

  test('eliminate one keeps candidate with fewest private eliminations', () {
    final result = ZyncNowConsensusEngine.resolve(
      candidates: candidates,
      participantIds: const ['a', 'b', 'c', 'd'],
      method: ZyncNowConsensusMethod.eliminateOne,
      ballots: const [
        ZyncNowConsensusBallot(
          participantId: 'a',
          eliminateCandidateId: 'wildcard',
        ),
        ZyncNowConsensusBallot(
          participantId: 'b',
          eliminateCandidateId: 'wildcard',
        ),
        ZyncNowConsensusBallot(
          participantId: 'c',
          eliminateCandidateId: 'safe',
        ),
        ZyncNowConsensusBallot(
          participantId: 'd',
          eliminateCandidateId: 'safe',
        ),
      ],
    );

    expect(result.chosenCandidateId, 'discovery');
    expect(
      result.candidateStats
          .firstWhere((item) => item.candidateId == 'discovery')
          .eliminateVotes,
      0,
    );
  });

  test('all candidates hard-vetoed returns needs-relaxation, never overrides',
      () {
    final result = ZyncNowConsensusEngine.resolve(
      candidates: candidates,
      participantIds: const ['a', 'b'],
      method: ZyncNowConsensusMethod.quickVote,
      ballots: [
        _quick(
          'a',
          ratings: const {
            'safe': ZyncNowVote.no,
            'discovery': ZyncNowVote.no,
            'wildcard': ZyncNowVote.no,
          },
          vetoes: const {'safe', 'discovery'},
        ),
        _quick(
          'b',
          ratings: const {
            'safe': ZyncNowVote.no,
            'discovery': ZyncNowVote.no,
            'wildcard': ZyncNowVote.no,
          },
          vetoes: const {'wildcard'},
        ),
      ],
    );

    expect(result.status, ZyncNowConsensusStatus.needsRelaxation);
    expect(result.chosenCandidateId, isNull);
    expect(result.remainingCandidateIds, isEmpty);
  });

  test('perfect tie uses stable Zync tie-break for the same seed', () {
    final tiedCandidates = [
      _candidate('a', score: 50),
      _candidate('b', score: 50),
      _candidate('c', score: 50),
    ];
    const ballots = [
      ZyncNowConsensusBallot(
        participantId: 'p1',
        eliminateCandidateId: 'c',
      ),
      ZyncNowConsensusBallot(
        participantId: 'p2',
        eliminateCandidateId: 'c',
      ),
    ];

    final first = ZyncNowConsensusEngine.resolve(
      candidates: tiedCandidates,
      participantIds: const ['p1', 'p2'],
      ballots: ballots,
      method: ZyncNowConsensusMethod.eliminateOne,
      seed: 'same-room',
    );
    final second = ZyncNowConsensusEngine.resolve(
      candidates: tiedCandidates,
      participantIds: const ['p1', 'p2'],
      ballots: ballots,
      method: ZyncNowConsensusMethod.eliminateOne,
      seed: 'same-room',
    );

    expect(first.usedTieBreak, isTrue);
    expect(first.chosenCandidateId, second.chosenCandidateId);
    expect(first.chosenCandidateId, isNot('c'));
  });

  test('supports eight participants with one private ballot each', () {
    final participants = [for (var i = 0; i < 8; i++) 'p$i'];
    final ballots = [
      for (final participant in participants)
        _quick(participant, ratings: const {
          'safe': ZyncNowVote.okay,
          'discovery': ZyncNowVote.love,
          'wildcard': ZyncNowVote.okay,
        }),
    ];

    final result = ZyncNowConsensusEngine.resolve(
      candidates: candidates,
      participantIds: participants,
      ballots: ballots,
      method: ZyncNowConsensusMethod.quickVote,
    );

    expect(result.chosenCandidateId, 'discovery');
  });

  test('rejects missing or duplicate participant ballots', () {
    expect(
      () => ZyncNowConsensusEngine.resolve(
        candidates: candidates,
        participantIds: const ['a', 'b'],
        ballots: [
          _quick('a', ratings: const {
            'safe': ZyncNowVote.okay,
            'discovery': ZyncNowVote.okay,
            'wildcard': ZyncNowVote.okay,
          }),
        ],
        method: ZyncNowConsensusMethod.quickVote,
      ),
      throwsArgumentError,
    );

    expect(
      () => ZyncNowConsensusEngine.resolve(
        candidates: candidates,
        participantIds: const ['a', 'b'],
        ballots: [
          _quick('a', ratings: const {
            'safe': ZyncNowVote.okay,
            'discovery': ZyncNowVote.okay,
            'wildcard': ZyncNowVote.okay,
          }),
          _quick('a', ratings: const {
            'safe': ZyncNowVote.okay,
            'discovery': ZyncNowVote.okay,
            'wildcard': ZyncNowVote.okay,
          }),
        ],
        method: ZyncNowConsensusMethod.quickVote,
      ),
      throwsArgumentError,
    );
  });
}

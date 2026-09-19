import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/group_zync_protocol.dart';
import 'package:zync/core/zync_now_consensus.dart';
import 'package:zync/core/zync_now_consensus_transport.dart';
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
      participantCount: 3,
    );

void main() {
  final candidates = [
    _candidate('safe', score: 80),
    _candidate('discovery', score: 70),
    _candidate('wildcard', score: 60),
  ];

  test('bounded option IDs are short protocol-safe aliases', () {
    final round = ZyncNowConsensusTransportRound(
      roundNumber: 2,
      method: ZyncNowConsensusMethod.quickVote,
      candidates: candidates,
    );

    final options = round.optionsFor('zh-Hant');
    expect(options, hasLength(3));
    for (final option in options) {
      expect(option.id, matches(RegExp(r'^[A-Za-z0-9_-]{22,64}$')));
      expect(option.label.trim(), isNotEmpty);
      expect(option.id, isNot(contains('safe')));
    }
  });

  test('quick vote and hard veto survive encode/decode', () {
    final round = ZyncNowConsensusTransportRound(
      roundNumber: 3,
      method: ZyncNowConsensusMethod.quickVote,
      candidates: candidates,
    );
    const ballot = ZyncNowConsensusBallot(
      participantId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      ratings: {
        'safe': ZyncNowVote.love,
        'discovery': ZyncNowVote.okay,
        'wildcard': ZyncNowVote.no,
      },
      hardVetoCandidateIds: {'wildcard'},
    );

    final encoded = round.encodeBallot(ballot);
    expect(encoded.answerIds, hasLength(4));
    expect(encoded.answerIds.join('|'), isNot(contains('discovery')));

    final decoded = round.decodeBallot(encoded);
    expect(decoded.participantId, ballot.participantId);
    expect(decoded.ratings, ballot.ratings);
    expect(decoded.hardVetoCandidateIds, ballot.hardVetoCandidateIds);
  });

  test('rank ballot preserves candidate order', () {
    final round = ZyncNowConsensusTransportRound(
      roundNumber: 4,
      method: ZyncNowConsensusMethod.rank,
      candidates: candidates,
    );
    const ballot = ZyncNowConsensusBallot(
      participantId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      ranking: ['wildcard', 'safe', 'discovery'],
    );

    final decoded = round.decodeBallot(round.encodeBallot(ballot));
    expect(decoded.ranking, ballot.ranking);
  });

  test('eliminate-one ballot preserves selected finalist', () {
    final round = ZyncNowConsensusTransportRound(
      roundNumber: 5,
      method: ZyncNowConsensusMethod.eliminateOne,
      candidates: candidates,
    );
    const ballot = ZyncNowConsensusBallot(
      participantId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      eliminateCandidateId: 'safe',
    );

    final decoded = round.decodeBallot(round.encodeBallot(ballot));
    expect(decoded.eliminateCandidateId, 'safe');
  });

  test('participant can build ballot from bounded option IDs only', () {
    final round = ZyncNowConsensusTransportRound(
      roundNumber: 6,
      method: ZyncNowConsensusMethod.quickVote,
      candidates: candidates,
    );
    final options = round.optionsFor('en');

    final input = round.encodeOptionBallot(
      participantId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      ratingsByOptionId: {
        options[0].id: ZyncNowVote.okay,
        options[1].id: ZyncNowVote.love,
        options[2].id: ZyncNowVote.no,
      },
      hardVetoOptionIds: {options[2].id},
    );
    final decoded = round.decodeBallot(input);

    expect(decoded.ratings['safe'], ZyncNowVote.okay);
    expect(decoded.ratings['discovery'], ZyncNowVote.love);
    expect(decoded.ratings['wildcard'], ZyncNowVote.no);
    expect(decoded.hardVetoCandidateIds, {'wildcard'});
  });

  test('encoded consensus ballot survives Group Zync encryption', () async {
    final now = DateTime.now().toUtc();
    final room = GroupRoomBootstrap.generate(now: now);
    final round = ZyncNowConsensusTransportRound(
      roundNumber: 7,
      method: ZyncNowConsensusMethod.eliminateOne,
      candidates: candidates,
    );
    const participantId = 'ABCDEFGHIJKLMNOPQRSTUVWX';
    const ballot = ZyncNowConsensusBallot(
      participantId: participantId,
      eliminateCandidateId: 'wildcard',
    );

    final privateInput = round.encodeBallot(ballot);
    final encrypted = await GroupCrypto.encryptPrivateInput(
      room: room.qr,
      input: privateInput,
    );
    expect(encrypted, isNot(contains('wildcard')));

    final decrypted = await GroupCrypto.decryptPrivateInput(
      room: room,
      participantId: participantId,
      roundNumber: 7,
      opaquePayload: encrypted,
      now: now.add(const Duration(minutes: 1)),
    );
    final decoded = round.decodeBallot(decrypted);

    expect(decoded.eliminateCandidateId, 'wildcard');
  });

  test('consensus result maps back to bounded result option ID', () {
    final round = ZyncNowConsensusTransportRound(
      roundNumber: 8,
      method: ZyncNowConsensusMethod.quickVote,
      candidates: candidates,
    );
    final result = ZyncNowConsensusEngine.resolve(
      candidates: candidates,
      participantIds: const ['a', 'b'],
      method: ZyncNowConsensusMethod.quickVote,
      ballots: const [
        ZyncNowConsensusBallot(
          participantId: 'a',
          ratings: {
            'safe': ZyncNowVote.okay,
            'discovery': ZyncNowVote.love,
            'wildcard': ZyncNowVote.no,
          },
        ),
        ZyncNowConsensusBallot(
          participantId: 'b',
          ratings: {
            'safe': ZyncNowVote.okay,
            'discovery': ZyncNowVote.love,
            'wildcard': ZyncNowVote.no,
          },
        ),
      ],
    );

    final optionId = round.optionIdForResult(result);
    expect(optionId, isNotNull);
    expect(round.candidateIdForOption(optionId!), 'discovery');
  });

  test('unknown bounded option is rejected', () {
    final round = ZyncNowConsensusTransportRound(
      roundNumber: 9,
      method: ZyncNowConsensusMethod.eliminateOne,
      candidates: candidates,
    );

    expect(
      () => round.encodeOptionBallot(
        participantId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
        ratingsByOptionId: const {},
        eliminateOptionId: 'ZYNCNOW_OPTION_99999999',
      ),
      throwsArgumentError,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/group_discovery_service.dart';
import 'package:zync/core/group_zync_protocol.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/zync_now_engine.dart';

GroupParticipantProfile _profile(
  String id,
  List<SelectedInterest> interests,
) =>
    GroupParticipantProfile(
      participantId: id,
      language: 'en',
      interests: interests,
    );

SelectedInterest _interest(
  String id, [
  InterestStrength strength = InterestStrength.like,
]) =>
    SelectedInterest(id: id, strength: strength);

void main() {
  const p1 = 'ABCDEFGHIJKLMNOPQRSTUVWX';
  const p2 = 'ZYXWVUTSRQPONMLKJIHGFEDC';
  const p3 = 'AAAABBBBCCCCDDDDEEEEFFFF';
  const p4 = 'FFFFEEEEDDDDCCCCBBBBAAAA';

  test('hidden cluster uses exact canonical IDs only', () {
    final plan = GroupDiscoveryPlanner.build(
      participants: [
        _profile(p1, [_interest('sports.badminton')]),
        _profile(p2, [_interest('sports.badminton')]),
        _profile(p3, [_interest('sports.tennis')]),
      ],
      seed: 'exact-only',
      limit: 10,
    );

    final badminton = plan.candidates.firstWhere(
      (candidate) => candidate.interestId == 'sports.badminton',
    );

    expect(badminton.mechanic, GroupDiscoveryMechanic.hiddenCluster);
    expect(badminton.participantIds.toSet(), {p1, p2});
    expect(badminton.participantIds, isNot(contains(p3)));
  });

  test('related racket interests never create a false shared claim', () {
    final plan = GroupDiscoveryPlanner.build(
      participants: [
        _profile(p1, [_interest('sports.badminton')]),
        _profile(p2, [_interest('sports.tennis')]),
        _profile(p3, [_interest('sports.pickleball')]),
      ],
      seed: 'no-fake-shared',
      limit: 10,
    );

    expect(
      plan.candidates.where(
        (candidate) =>
            candidate.mechanic == GroupDiscoveryMechanic.hiddenCluster ||
            candidate.mechanic == GroupDiscoveryMechanic.allTogether ||
            candidate.mechanic == GroupDiscoveryMechanic.majorityPattern,
      ),
      isEmpty,
    );
  });

  test('all-together signal requires exact ID equality across everyone', () {
    final plan = GroupDiscoveryPlanner.build(
      participants: [
        _profile(p1, [_interest('food.coffee')]),
        _profile(p2, [_interest('food.coffee')]),
        _profile(p3, [_interest('food.coffee')]),
        _profile(p4, [_interest('food.coffee')]),
      ],
      seed: 'all',
      limit: 5,
    );

    final all = plan.candidates.firstWhere(
      (candidate) => candidate.interestId == 'food.coffee',
    );
    expect(all.mechanic, GroupDiscoveryMechanic.allTogether);
    expect(all.participantIds.toSet(), {p1, p2, p3, p4});
  });

  test('unique loved interest can become Who Knows This', () {
    final plan = GroupDiscoveryPlanner.build(
      participants: [
        _profile(
          p1,
          [_interest('outdoors.bouldering', InterestStrength.love)],
        ),
        _profile(p2, [_interest('food.coffee')]),
        _profile(p3, [_interest('media.movies')]),
      ],
      seed: 'expert',
      limit: 10,
    );

    expect(
      plan.candidates.any(
        (candidate) =>
            candidate.interestId == 'outdoors.bouldering' &&
            candidate.mechanic == GroupDiscoveryMechanic.whoKnowsThis &&
            candidate.participantIds.single == p1,
      ),
      isTrue,
    );
  });

  test('fairness penalty can reduce repeated targeting', () {
    final noPenalty = GroupDiscoveryPlanner.build(
      participants: [
        _profile(
          p1,
          [
            _interest('outdoors.bouldering', InterestStrength.love),
            _interest('food.coffee', InterestStrength.love),
          ],
        ),
        _profile(p2, [_interest('sports.badminton')]),
        _profile(p3, [_interest('media.movies')]),
      ],
      seed: 'fairness',
      limit: 10,
    );
    final bouldering = noPenalty.candidates.firstWhere(
      (candidate) => candidate.interestId == 'outdoors.bouldering',
    );

    final penalized = GroupDiscoveryPlanner.build(
      participants: [
        _profile(
          p1,
          [
            _interest('outdoors.bouldering', InterestStrength.love),
            _interest('food.coffee', InterestStrength.love),
          ],
        ),
        _profile(p2, [_interest('sports.badminton')]),
        _profile(p3, [_interest('media.movies')]),
      ],
      seed: 'fairness',
      limit: 10,
      previousTargetCounts: {p1: 3},
    );
    final same = penalized.candidates.firstWhere(
      (candidate) => candidate.interestId == 'outdoors.bouldering',
    );

    expect(same.score, lessThan(bouldering.score));
  });

  test('group participants feed the shared N>=2 Zync Now engine', () {
    final participants = [
      _profile(
        p1,
        [_interest('sports.badminton', InterestStrength.love)],
      ),
      _profile(
        p2,
        [_interest('sports.badminton', InterestStrength.like)],
      ),
      _profile(
        p3,
        [_interest('sports.tennis', InterestStrength.like)],
      ),
    ];

    final zyncNowParticipants =
        GroupDiscoveryPlanner.toZyncNowParticipants(participants);
    expect(zyncNowParticipants, hasLength(3));
    expect(zyncNowParticipants.first, isA<ZyncNowParticipant>());

    final suggestions = ZyncNowEngine.generate(
      participants: zyncNowParticipants,
      mode: ZyncNowMode.familiar,
      seed: 'group-now',
    );
    expect(suggestions, isNotEmpty);
    expect(
      suggestions.any(
        (candidate) =>
            candidate.sourceInterestIds.contains('sports.badminton'),
      ),
      isTrue,
    );
  });
}

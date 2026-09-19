import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/group_discovery_service.dart';
import 'package:zync/core/group_interaction_director.dart';
import 'package:zync/core/group_zync_protocol.dart';

const p1 = 'ABCDEFGHIJKLMNOPQRSTUVWX';
const p2 = 'ZYXWVUTSRQPONMLKJIHGFEDC';
const p3 = 'AAAABBBBCCCCDDDDEEEEFFFF';

GroupParticipantProfile _p(
  String id, {
  String nickname = '',
}) =>
    GroupParticipantProfile(
      participantId: id,
      nickname: nickname,
      language: 'zh-Hant',
      interests: const [],
    );

GroupDiscoveryCandidate _candidate({
  required GroupDiscoveryMechanic mechanic,
  required String interestId,
  required List<String> participantIds,
}) =>
    GroupDiscoveryCandidate(
      id: 'test.${mechanic.name}.$interestId',
      mechanic: mechanic,
      interestId: interestId,
      participantIds: participantIds,
      score: 100,
    );

void main() {
  final participants = [
    _p(p1, nickname: 'Alex'),
    _p(p2),
    _p(p3),
  ];

  test('Hidden Cluster requires private subset guess before reveal', () {
    final round = GroupInteractionDirector.build(
      candidate: _candidate(
        mechanic: GroupDiscoveryMechanic.hiddenCluster,
        interestId: 'sports.badminton',
        participantIds: const [p1, p2],
      ),
      participants: participants,
      locale: 'zh-HK',
    );

    expect(round.input.privateInputRequired, isTrue);
    expect(round.input.kind, GroupInputKind.participantSet);
    expect(round.input.requiredSelections, 2);
    expect(round.input.options, hasLength(3));
    expect(round.prompt, contains('2'));
    expect(round.revealTitle, contains('羽毛球'));
    expect(round.targetParticipantIds, [p1, p2]);
  });

  test('Only One asks for exactly one private participant guess', () {
    final round = GroupInteractionDirector.build(
      candidate: _candidate(
        mechanic: GroupDiscoveryMechanic.onlyOne,
        interestId: 'outdoors.bouldering',
        participantIds: const [p3],
      ),
      participants: participants,
      locale: 'zh-Hant',
    );

    expect(round.input.kind, GroupInputKind.participantSingle);
    expect(round.input.requiredSelections, 1);
    expect(round.prompt, contains('抱石'));
    expect(round.revealBody, isNotEmpty);
  });

  test('Who Knows This produces a teach-us follow-up', () {
    final round = GroupInteractionDirector.build(
      candidate: _candidate(
        mechanic: GroupDiscoveryMechanic.whoKnowsThis,
        interestId: 'food.coffee',
        participantIds: const [p1],
      ),
      participants: participants,
      locale: 'en',
    );

    expect(round.input.privateInputRequired, isTrue);
    expect(round.prompt, contains('Coffee'));
    expect(round.followUp.toLowerCase(), contains('teach'));
    expect(round.revealBody, 'Alex');
  });

  test('All Together reveals directly without fake private input', () {
    final round = GroupInteractionDirector.build(
      candidate: _candidate(
        mechanic: GroupDiscoveryMechanic.allTogether,
        interestId: 'media.movies',
        participantIds: const [p1, p2, p3],
      ),
      participants: participants,
      locale: 'zh-Hans',
    );

    expect(round.input.kind, GroupInputKind.none);
    expect(round.input.privateInputRequired, isFalse);
    expect(round.input.requiredSelections, 0);
    expect(round.revealTitle, contains('电影'));
  });

  test('blank nicknames reuse deterministic Zync aliases', () {
    final first = GroupInteractionDirector.build(
      candidate: _candidate(
        mechanic: GroupDiscoveryMechanic.onlyOne,
        interestId: 'sports.badminton',
        participantIds: const [p2],
      ),
      participants: participants,
      locale: 'zh-Hant',
    );
    final second = GroupInteractionDirector.build(
      candidate: _candidate(
        mechanic: GroupDiscoveryMechanic.onlyOne,
        interestId: 'sports.badminton',
        participantIds: const [p2],
      ),
      participants: participants,
      locale: 'zh-Hant',
    );

    expect(first.revealBody, isNotEmpty);
    expect(first.revealBody, second.revealBody);
    expect(first.revealBody, isNot(p2));
  });

  test('all currently supported locales have usable local mechanic copy', () {
    for (final locale in [
      'en',
      'zh-Hant',
      'zh-Hans',
      'ja',
      'ko',
      'es',
      'fr',
      'pt',
    ]) {
      final round = GroupInteractionDirector.build(
        candidate: _candidate(
          mechanic: GroupDiscoveryMechanic.hiddenCluster,
          interestId: 'sports.badminton',
          participantIds: const [p1, p2],
        ),
        participants: participants,
        locale: locale,
      );
      expect(round.title.trim(), isNotEmpty, reason: locale);
      expect(round.prompt.trim(), isNotEmpty, reason: locale);
      expect(round.revealTitle.trim(), isNotEmpty, reason: locale);
      expect(round.followUp.trim(), isNotEmpty, reason: locale);
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/group_zync_protocol.dart';
import 'package:zync/core/group_zync_session.dart';

GroupParticipantProfile _p(String id) => GroupParticipantProfile(
      participantId: id,
      language: 'en',
      interests: const [],
    );

void main() {
  const hostId = 'ABCDEFGHIJKLMNOPQRSTUVWX';
  const p2 = 'ZYXWVUTSRQPONMLKJIHGFEDC';
  const p3 = 'AAAABBBBCCCCDDDDEEEEFFFF';
  const p4 = 'FFFFEEEEDDDDCCCCBBBBAAAA';

  test('Group Zync lobby starts only when at least three are ready', () {
    var session = GroupZyncSession.lobby(
      roomId: 'ROOMABCDEFGHIJKLMNOPQRST',
      hostParticipant: _p(hostId),
    );
    session = session.join(_p(p2)).join(_p(p3));

    expect(session.participantCount, 3);
    expect(session.readyCount, 1);
    expect(session.canStart, isFalse);

    session = session.setReady(p2, true);
    expect(session.canStart, isFalse);

    session = session.setReady(p3, true);
    expect(session.phase, GroupRoomPhase.ready);
    expect(session.canStart, isTrue);
  });

  test('late joins are rejected once a round is prepared', () {
    var session = GroupZyncSession.lobby(
      roomId: 'ROOMABCDEFGHIJKLMNOPQRST',
      hostParticipant: _p(hostId),
    )
        .join(_p(p2))
        .join(_p(p3))
        .setReady(p2, true)
        .setReady(p3, true)
        .prepareRound('hidden_cluster');

    expect(session.phase, GroupRoomPhase.roundPrepared);
    expect(
      () => session.join(_p(p4)),
      throwsStateError,
    );
  });

  test('authoritative round state follows input lock reveal reaction complete',
      () {
    var session = GroupZyncSession.lobby(
      roomId: 'ROOMABCDEFGHIJKLMNOPQRST',
      hostParticipant: _p(hostId),
    )
        .join(_p(p2))
        .join(_p(p3))
        .setReady(p2, true)
        .setReady(p3, true)
        .prepareRound('hidden_cluster');

    session = session.openInput();
    expect(session.phase, GroupRoomPhase.inputOpen);
    session = session.lockInput();
    expect(session.phase, GroupRoomPhase.inputLocked);
    session = session.reveal();
    expect(session.phase, GroupRoomPhase.reveal);
    session = session.openReaction();
    expect(session.phase, GroupRoomPhase.reaction);
    session = session.completeRound();
    expect(session.phase, GroupRoomPhase.complete);
    session = session.offerZyncNow();
    expect(session.phase, GroupRoomPhase.zyncNowOptional);
  });

  test('participant departure before start removes them cleanly', () {
    var session = GroupZyncSession.lobby(
      roomId: 'ROOMABCDEFGHIJKLMNOPQRST',
      hostParticipant: _p(hostId),
    ).join(_p(p2));

    session = session.leaveBeforeStart(p2);
    expect(session.participantCount, 1);
    expect(session.participants.containsKey(p2), isFalse);
  });

  test('bounded state exposes counts but not participant profiles', () {
    final session = GroupZyncSession.lobby(
      roomId: 'ROOMABCDEFGHIJKLMNOPQRST',
      hostParticipant: _p(hostId),
    ).join(_p(p2));

    final state = session.boundedState();
    expect(state.participantCount, 2);
    expect(state.readyCount, 1);
    expect(state.revealParticipantIds, isEmpty);
    expect(state.revealInterestId, isNull);
  });
}

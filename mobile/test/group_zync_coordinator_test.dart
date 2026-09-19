import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/group_discovery_service.dart';
import 'package:zync/core/group_relay_service.dart';
import 'package:zync/core/group_zync_coordinator.dart';
import 'package:zync/core/group_zync_protocol.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/zync_now_engine.dart';

const hostProfile = LocalProfile(
  localId: 'host-local-permanent',
  nickname: 'Host',
  language: 'zh-Hant',
  interests: [
    SelectedInterest(
      id: 'sports.badminton',
      strength: InterestStrength.love,
    ),
  ],
);

const guest1Profile = LocalProfile(
  localId: 'guest-1-local-permanent',
  nickname: 'Guest One',
  language: 'zh-Hant',
  interests: [
    SelectedInterest(
      id: 'sports.badminton',
      strength: InterestStrength.love,
    ),
  ],
);

const guest2Profile = LocalProfile(
  localId: 'guest-2-local-permanent',
  nickname: 'Guest Two',
  language: 'zh-Hant',
  interests: [
    SelectedInterest(
      id: 'outdoors.bouldering',
      strength: InterestStrength.like,
    ),
  ],
);

void main() {
  test('three-device Group Zync foundation runs join input reveal and Zync Now',
      () async {
    final relay = _MemoryGroupRelay();
    final host = await GroupHostCoordinator.create(
      relay: relay,
      hostProfile: hostProfile,
      maxParticipants: 4,
      shareNickname: true,
    );

    final guest1 = await GroupParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guest1Profile,
      shareNickname: true,
    );
    final guest2 = await GroupParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guest2Profile,
      shareNickname: true,
    );

    await expectLater(
      relay.leave(
        room: host.room.qr,
        participantId: guest1.participant.participantId,
        participantToken: guest2.participantToken,
      ),
      throwsA(
        isA<GroupRelayException>().having(
          (error) => error.kind,
          'kind',
          GroupRelayFailureKind.unauthorized,
        ),
      ),
    );

    await host.refreshLobby();
    expect(host.session.participantCount, 3);
    expect(host.session.readyCount, 3);
    expect(host.session.canStart, isTrue);

    final round = await host.prepareNextRound(seed: 'three-device');
    expect(round.mechanic, GroupDiscoveryMechanic.hiddenCluster);
    expect(round.interestId, 'sports.badminton');
    expect(host.session.phase, GroupRoomPhase.inputOpen);

    await expectLater(
      relay.submitInput(
        room: host.room.qr,
        participantId: guest1.participant.participantId,
        participantToken: guest2.participantToken,
        roundNumber: host.session.roundNumber,
        payload: 'ForgedOpaqueInput',
      ),
      throwsA(
        isA<GroupRelayException>().having(
          (error) => error.kind,
          'kind',
          GroupRelayFailureKind.unauthorized,
        ),
      ),
    );

    final guest1State = await guest1.poll();
    final guest2State = await guest2.poll();
    expect(guest1State, isNotNull);
    expect(guest2State, isNotNull);
    expect(guest1State!.phase, GroupRoomPhase.inputOpen);
    expect(guest1State.requiredSelections, 2);
    expect(guest1State.options, hasLength(3));
    expect(guest1State.revealInterestId, isNull);

    await expectLater(
      guest1.submitSelection([guest1State.options.first.id]),
      throwsArgumentError,
    );

    final guesses = guest1State.options.take(2).map((item) => item.id).toList();
    await guest1.submitSelection(guesses);
    await guest2.submitSelection(guesses);

    await expectLater(
      host.lockInput(),
      throwsStateError,
      reason: 'Host must submit a private guess too',
    );

    final hostGuesses =
        round.input.options.take(2).map((item) => item.id).toList();
    host.submitHostSelection(hostGuesses);

    final collection = await host.collectRoundInputs();
    expect(collection.complete, isTrue);
    expect(collection.inputs, hasLength(3));
    expect(collection.missingParticipantIds, isEmpty);

    await host.lockInput();
    final inputs = await host.takeGuestInputs();
    expect(inputs, hasLength(2));
    expect(
      inputs.map((item) => item.participantId).toSet(),
      {
        guest1.participant.participantId,
        guest2.participant.participantId,
      },
    );

    await host.reveal();
    expect(host.session.phase, GroupRoomPhase.reveal);

    final reveal1 = await guest1.poll();
    final reveal2 = await guest2.poll();
    expect(reveal1, isNotNull);
    expect(reveal2, isNotNull);
    expect(reveal1!.phase, GroupRoomPhase.reveal);
    expect(reveal1.revealInterestId, 'sports.badminton');
    expect(reveal1.revealParticipantIds.toSet(), round.targetParticipantIds.toSet());

    await host.openReaction();
    await host.completeRound();
    expect(host.session.phase, GroupRoomPhase.complete);

    final zyncNow = host.generateZyncNow(
      mode: ZyncNowMode.familiar,
      seed: 'after-group-round',
    );
    expect(zyncNow, isNotEmpty);
    expect(
      zyncNow.any(
        (candidate) =>
            candidate.sourceInterestIds.contains('sports.badminton'),
      ),
      isTrue,
    );

    await host.offerZyncNow();
    expect(host.session.phase, GroupRoomPhase.zyncNowOptional);

    await host.end();
    expect(host.session.phase, GroupRoomPhase.ended);
    expect(relay.closed, isTrue);
  });

  test('host rejects semantically forged encrypted participant answer',
      () async {
    final relay = _MemoryGroupRelay();
    final host = await GroupHostCoordinator.create(
      relay: relay,
      hostProfile: hostProfile,
      maxParticipants: 4,
    );
    final guest1 = await GroupParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guest1Profile,
    );
    await GroupParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guest2Profile,
    );

    await host.refreshLobby();
    await host.prepareNextRound(seed: 'semantic-forgery');

    final forged = GroupPrivateInput(
      roundNumber: host.session.roundNumber,
      participantId: guest1.participant.participantId,
      answerIds: const [
        'NOT_A_REAL_PARTICIPANT_01',
        'NOT_A_REAL_PARTICIPANT_02',
      ],
    );
    final forgedPayload = await GroupCrypto.encryptPrivateInput(
      room: host.room.qr,
      input: forged,
    );
    await relay.submitInput(
      room: host.room.qr,
      participantId: guest1.participant.participantId,
      participantToken: guest1.participantToken,
      roundNumber: host.session.roundNumber,
      payload: forgedPayload,
    );

    final round = host.activeRound!;
    host.submitHostSelection(
      round.input.options
          .take(round.input.requiredSelections)
          .map((item) => item.id)
          .toList(),
    );

    await expectLater(
      host.lockInput(),
      throwsA(isA<FormatException>()),
      reason: 'Semantic forgery must fail before input is locked',
    );
  });

  test('host cannot lock while any ready participant has not answered',
      () async {
    final relay = _MemoryGroupRelay();
    final host = await GroupHostCoordinator.create(
      relay: relay,
      hostProfile: hostProfile,
      maxParticipants: 4,
    );
    final guest1 = await GroupParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guest1Profile,
    );
    await GroupParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guest2Profile,
    );

    await host.refreshLobby();
    final round = await host.prepareNextRound(seed: 'wait-for-everyone');
    final state = await guest1.poll();
    expect(state, isNotNull);

    host.submitHostSelection(
      round.input.options
          .take(round.input.requiredSelections)
          .map((item) => item.id)
          .toList(),
    );
    await guest1.submitSelection(
      state!.options
          .take(state.requiredSelections)
          .map((item) => item.id)
          .toList(),
    );

    final collection = await host.collectRoundInputs();
    expect(collection.complete, isFalse);
    expect(collection.missingParticipantIds, hasLength(1));

    await expectLater(
      host.lockInput(),
      throwsStateError,
    );

    expect(host.session.phase, GroupRoomPhase.inputOpen);
  });

  test('late Group Zync participant cannot join after host locks room',
      () async {
    final relay = _MemoryGroupRelay();
    final host = await GroupHostCoordinator.create(
      relay: relay,
      hostProfile: hostProfile,
      maxParticipants: 4,
    );
    await GroupParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guest1Profile,
    );
    await GroupParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guest2Profile,
    );

    await host.refreshLobby();
    await host.prepareNextRound(seed: 'lock-room');

    await expectLater(
      GroupParticipantCoordinator.join(
        relay: relay,
        room: host.room.qr,
        profile: const LocalProfile(
          localId: 'late-local',
          nickname: 'Late',
          language: 'en',
          interests: [
            SelectedInterest(
              id: 'food.coffee',
              strength: InterestStrength.like,
            ),
          ],
        ),
      ),
      throwsA(
        isA<GroupRelayException>().having(
          (error) => error.kind,
          'kind',
          GroupRelayFailureKind.locked,
        ),
      ),
    );
  });
}

class _MemoryGroupRelay implements GroupRelayClient {
  GroupRoomBootstrap? room;
  final Map<String, String> participants = {};
  final Map<String, String> participantTokens = {};
  final Map<int, Map<String, String>> inputs = {};
  bool locked = false;
  bool closed = false;
  int stateRevision = -1;
  String? statePayload;

  @override
  Future<void> createRoom(GroupRoomBootstrap room) async {
    this.room = room;
  }

  @override
  Future<int> join({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required String payload,
  }) async {
    if (closed) {
      throw const GroupRelayException(GroupRelayFailureKind.expired);
    }
    if (locked) {
      throw const GroupRelayException(GroupRelayFailureKind.locked);
    }
    if (participants.length >= room.maxParticipants - 1) {
      throw const GroupRelayException(GroupRelayFailureKind.full);
    }
    final previous = participants[participantId];
    final previousToken = participantTokens[participantId];
    if (previous != null &&
        (previous != payload || previousToken != participantToken)) {
      throw const GroupRelayException(GroupRelayFailureKind.conflict);
    }
    participants[participantId] = payload;
    participantTokens[participantId] = participantToken;
    return participants.length + 1;
  }

  @override
  Future<void> leave({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
  }) async {
    if (locked) {
      throw const GroupRelayException(GroupRelayFailureKind.locked);
    }
    if (participantTokens[participantId] != participantToken) {
      throw const GroupRelayException(GroupRelayFailureKind.unauthorized);
    }
    participants.remove(participantId);
    participantTokens.remove(participantId);
  }

  @override
  Future<GroupRelayHostSnapshot> takeParticipants(
    GroupRoomBootstrap room,
  ) async =>
      GroupRelayHostSnapshot(
        participantCount: participants.length + 1,
        maxParticipants: room.maxParticipants,
        locked: locked,
        participants: participants.entries
            .map(
              (entry) => GroupRelayParticipantEnvelope(
                participantId: entry.key,
                payload: entry.value,
              ),
            )
            .toList(growable: false),
      );

  @override
  Future<void> lockRoom(GroupRoomBootstrap room) async {
    locked = true;
  }

  @override
  Future<void> submitInput({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required int roundNumber,
    required String payload,
  }) async {
    if (!locked) {
      throw const GroupRelayException(GroupRelayFailureKind.locked);
    }
    if (!participants.containsKey(participantId) ||
        participantTokens[participantId] != participantToken) {
      throw const GroupRelayException(GroupRelayFailureKind.unauthorized);
    }
    final round = inputs.putIfAbsent(roundNumber, () => {});
    final previous = round[participantId];
    if (previous != null && previous != payload) {
      throw const GroupRelayException(GroupRelayFailureKind.conflict);
    }
    round[participantId] = payload;
  }

  @override
  Future<List<GroupRelayInputEnvelope>> takeInputs({
    required GroupRoomBootstrap room,
    required int roundNumber,
  }) async =>
      (inputs[roundNumber] ?? const <String, String>{})
          .entries
          .map(
            (entry) => GroupRelayInputEnvelope(
              participantId: entry.key,
              payload: entry.value,
            ),
          )
          .toList(growable: false);

  @override
  Future<void> publishState({
    required GroupRoomBootstrap room,
    required int revision,
    required String payload,
  }) async {
    if (revision < stateRevision) {
      throw const GroupRelayException(GroupRelayFailureKind.conflict);
    }
    if (revision == stateRevision &&
        statePayload != null &&
        statePayload != payload) {
      throw const GroupRelayException(GroupRelayFailureKind.conflict);
    }
    stateRevision = revision;
    statePayload = payload;
  }

  @override
  Future<GroupRelayStatePoll> pollState({
    required GroupJoinQrPayload room,
    required int sinceRevision,
  }) async {
    if (closed) {
      throw const GroupRelayException(GroupRelayFailureKind.expired);
    }
    final ready = statePayload != null && stateRevision > sinceRevision;
    return GroupRelayStatePoll(
      ready: ready,
      revision: stateRevision,
      participantCount: participants.length + 1,
      maxParticipants: room.maxParticipants,
      locked: locked,
      payload: ready ? statePayload : null,
    );
  }

  @override
  Future<void> closeRoom(GroupRoomBootstrap room) async {
    closed = true;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/group_relay_service.dart';
import 'package:zync/core/group_zync_protocol.dart';
import 'package:zync/core/interest_entity_metadata.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/zync_now_consensus.dart';
import 'package:zync/core/zync_now_constraints_transport.dart';
import 'package:zync/core/zync_now_engine.dart';
import 'package:zync/core/zync_now_room_coordinator.dart';

const hostProfile = LocalProfile(
  localId: 'host-local-only',
  nickname: 'Host',
  language: 'en',
  interests: [
    SelectedInterest(
      id: 'sports.badminton',
      strength: InterestStrength.love,
    ),
    SelectedInterest(
      id: 'food.coffee',
      strength: InterestStrength.like,
    ),
    SelectedInterest(
      id: 'media.movies',
      strength: InterestStrength.like,
    ),
  ],
);

const guestProfile = LocalProfile(
  localId: 'guest-local-only',
  nickname: 'Guest',
  language: 'en',
  interests: [
    SelectedInterest(
      id: 'sports.badminton',
      strength: InterestStrength.like,
    ),
    SelectedInterest(
      id: 'food.coffee',
      strength: InterestStrength.love,
    ),
    SelectedInterest(
      id: 'music.pop',
      strength: InterestStrength.like,
    ),
  ],
);

const mixedContext = ZyncNowPrivateContext(
  constraints: ZyncNowConstraints(
    duration: ActivityDurationBand.flexible,
    setting: ActivitySetting.either,
  ),
  novelty: ZyncNowNoveltyPreference.mixed,
);

void main() {
  test('two-device standalone Zync Now runs constraints vote and result',
      () async {
    final relay = _MemoryGroupRelay();
    final host = await ZyncNowRoomHostCoordinator.create(
      relay: relay,
      hostProfile: hostProfile,
      maxParticipants: 2,
    );

    expect(host.room.kind, SharedZyncRoomKind.zyncNow);

    final guest = await ZyncNowRoomParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guestProfile,
    );

    await host.refreshLobby();
    expect(host.participantCount, 2);
    expect(host.canStart, isTrue);

    await host.openPrivateConstraints(mixedContext);
    expect(host.stage, ZyncNowRoomStage.constraintsOpen);

    final constraintState = await guest.poll();
    expect(constraintState, isNotNull);
    expect(constraintState!.inputKind, 'zync_now_constraints');

    await guest.submitPrivateContext(mixedContext);
    final contexts = await host.collectPrivateContexts();
    expect(contexts.complete, isTrue);
    expect(contexts.contexts, hasLength(2));

    final finalists = await host.prepareConsensus(
      seed: 'pair-room',
    );
    expect(finalists.length, inInclusiveRange(2, 3));
    expect(host.stage, ZyncNowRoomStage.consensusOpen);

    final voteState = await guest.poll();
    expect(voteState, isNotNull);
    expect(voteState!.mechanicType, 'zync_now_consensus');
    expect(voteState.options, hasLength(finalists.length));

    final guestRatings = <String, ZyncNowVote>{
      for (var i = 0; i < voteState.options.length; i += 1)
        voteState.options[i].id:
            i == 1 ? ZyncNowVote.love : ZyncNowVote.okay,
    };
    await guest.submitConsensus(
      ratingsByOptionId: guestRatings,
    );

    host.submitHostBallot(
      ZyncNowConsensusBallot(
        participantId: host.hostParticipant.participantId,
        ratings: {
          for (var i = 0; i < finalists.length; i += 1)
            finalists[i].id:
                i == 1 ? ZyncNowVote.love : ZyncNowVote.okay,
        },
      ),
    );

    final ballots = await host.collectBallots();
    expect(ballots.complete, isTrue);
    expect(ballots.ballots, hasLength(2));

    await host.lockConsensus();
    expect(host.stage, ZyncNowRoomStage.consensusLocked);

    final result = await host.resolveConsensus(seed: 'pair-decision');
    expect(result.hasDecision, isTrue);
    expect(result.chosenCandidateId, finalists[1].id);
    expect(host.stage, ZyncNowRoomStage.result);

    final resultState = await guest.poll();
    expect(resultState, isNotNull);
    expect(resultState!.phase, GroupRoomPhase.zyncNowResult);
    expect(resultState.resultOptionId, isNotNull);
    expect(
      resultState.options.map((item) => item.id),
      contains(resultState.resultOptionId),
    );
  });

  test('standalone room cannot generate before every private context arrives',
      () async {
    final relay = _MemoryGroupRelay();
    final host = await ZyncNowRoomHostCoordinator.create(
      relay: relay,
      hostProfile: hostProfile,
      maxParticipants: 2,
    );
    await ZyncNowRoomParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guestProfile,
    );

    await host.refreshLobby();
    await host.openPrivateConstraints(mixedContext);

    await expectLater(
      host.prepareConsensus(seed: 'too-early'),
      throwsStateError,
    );
    expect(host.stage, ZyncNowRoomStage.constraintsOpen);
  });

  test('standalone consensus cannot lock before every private ballot arrives',
      () async {
    final relay = _MemoryGroupRelay();
    final host = await ZyncNowRoomHostCoordinator.create(
      relay: relay,
      hostProfile: hostProfile,
      maxParticipants: 2,
    );
    final guest = await ZyncNowRoomParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: guestProfile,
    );

    await host.refreshLobby();
    await host.openPrivateConstraints(mixedContext);
    await guest.poll();
    await guest.submitPrivateContext(mixedContext);
    final finalists = await host.prepareConsensus(seed: 'wait-for-ballot');

    host.submitHostBallot(
      ZyncNowConsensusBallot(
        participantId: host.hostParticipant.participantId,
        ratings: {
          for (final candidate in finalists)
            candidate.id: ZyncNowVote.okay,
        },
      ),
    );

    await expectLater(
      host.lockConsensus(),
      throwsStateError,
    );
    expect(host.stage, ZyncNowRoomStage.consensusOpen);
  });

  test('incompatible private constraints return needs-relaxation, not override',
      () async {
    final relay = _MemoryGroupRelay();
    const moviesHost = LocalProfile(
      localId: 'movies-host',
      nickname: '',
      language: 'en',
      interests: [
        SelectedInterest(
          id: 'media.movies',
          strength: InterestStrength.love,
        ),
      ],
    );
    const moviesGuest = LocalProfile(
      localId: 'movies-guest',
      nickname: '',
      language: 'en',
      interests: [
        SelectedInterest(
          id: 'media.movies',
          strength: InterestStrength.like,
        ),
      ],
    );
    const outdoorFamiliar = ZyncNowPrivateContext(
      constraints: ZyncNowConstraints(
        setting: ActivitySetting.outdoor,
      ),
      novelty: ZyncNowNoveltyPreference.familiar,
    );

    final host = await ZyncNowRoomHostCoordinator.create(
      relay: relay,
      hostProfile: moviesHost,
      maxParticipants: 2,
    );
    final guest = await ZyncNowRoomParticipantCoordinator.join(
      relay: relay,
      room: host.room.qr,
      profile: moviesGuest,
    );

    await host.refreshLobby();
    await host.openPrivateConstraints(outdoorFamiliar);
    await guest.poll();
    await guest.submitPrivateContext(outdoorFamiliar);

    final finalists = await host.prepareConsensus(seed: 'no-fit');
    expect(finalists.length, lessThan(2));
    expect(host.needsRelaxation, isTrue);
    expect(host.stage, ZyncNowRoomStage.result);

    final state = await guest.poll();
    expect(state, isNotNull);
    expect(state!.phase, GroupRoomPhase.zyncNowResult);
    expect(state.resultOptionId, isNull);
  });

  test('standalone participant rejects a Group Zync QR', () async {
    final relay = _MemoryGroupRelay();
    final groupRoom = GroupRoomBootstrap.generate(
      maxParticipants: 3,
      kind: SharedZyncRoomKind.groupZync,
    );
    await relay.createRoom(groupRoom);

    expect(
      () => ZyncNowRoomParticipantCoordinator.join(
        relay: relay,
        room: groupRoom.qr,
        profile: guestProfile,
      ),
      throwsA(isA<FormatException>()),
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

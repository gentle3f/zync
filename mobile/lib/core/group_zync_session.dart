import 'group_zync_protocol.dart';

class GroupParticipantPresence {
  const GroupParticipantPresence({
    required this.profile,
    required this.ready,
  });

  final GroupParticipantProfile profile;
  final bool ready;

  GroupParticipantPresence copyWith({bool? ready}) =>
      GroupParticipantPresence(
        profile: profile,
        ready: ready ?? this.ready,
      );
}

class GroupZyncSession {
  const GroupZyncSession({
    required this.roomId,
    required this.maxParticipants,
    required this.phase,
    required this.participants,
    required this.roundNumber,
    required this.revision,
    this.activeMechanicId = '',
  });

  final String roomId;
  final int maxParticipants;
  final GroupRoomPhase phase;
  final Map<String, GroupParticipantPresence> participants;
  final int roundNumber;
  final int revision;
  final String activeMechanicId;

  factory GroupZyncSession.lobby({
    required String roomId,
    int maxParticipants = 8,
    GroupParticipantProfile? hostParticipant,
  }) {
    if (maxParticipants < 3 || maxParticipants > 8) {
      throw ArgumentError.value(
        maxParticipants,
        'maxParticipants',
        'Group Zync supports 3 to 8 participants',
      );
    }
    final participants = <String, GroupParticipantPresence>{};
    if (hostParticipant != null) {
      participants[hostParticipant.participantId] = GroupParticipantPresence(
        profile: hostParticipant,
        ready: true,
      );
    }
    return GroupZyncSession(
      roomId: roomId,
      maxParticipants: maxParticipants,
      phase: GroupRoomPhase.lobby,
      participants: Map.unmodifiable(participants),
      roundNumber: 0,
      revision: 0,
    );
  }

  int get participantCount => participants.length;
  int get readyCount => participants.values.where((item) => item.ready).length;

  bool get canStart =>
      participantCount >= 3 &&
      participantCount <= maxParticipants &&
      readyCount == participantCount &&
      (phase == GroupRoomPhase.lobby || phase == GroupRoomPhase.ready);

  GroupZyncSession join(GroupParticipantProfile profile) {
    _requireLobbyLike('join');
    if (participants.containsKey(profile.participantId)) return this;
    if (participantCount >= maxParticipants) {
      throw StateError('Group Zync room is full');
    }
    final next = Map<String, GroupParticipantPresence>.from(participants)
      ..[profile.participantId] = GroupParticipantPresence(
        profile: profile,
        ready: false,
      );
    return _copy(
      participants: next,
      phase: GroupRoomPhase.lobby,
    );
  }

  GroupZyncSession leaveBeforeStart(String participantId) {
    _requireLobbyLike('leave');
    if (!participants.containsKey(participantId)) return this;
    final next = Map<String, GroupParticipantPresence>.from(participants)
      ..remove(participantId);
    return _copy(
      participants: next,
      phase: GroupRoomPhase.lobby,
    );
  }

  GroupZyncSession setReady(String participantId, bool ready) {
    _requireLobbyLike('ready');
    final current = participants[participantId];
    if (current == null) {
      throw StateError('Unknown Group Zync participant');
    }
    final next = Map<String, GroupParticipantPresence>.from(participants)
      ..[participantId] = current.copyWith(ready: ready);
    final allReady =
        next.length >= 3 && next.values.every((item) => item.ready);
    return _copy(
      participants: next,
      phase: allReady ? GroupRoomPhase.ready : GroupRoomPhase.lobby,
    );
  }

  GroupZyncSession prepareRound(String mechanicId) {
    if (!canStart && phase != GroupRoomPhase.complete) {
      throw StateError('Group Zync round cannot start yet');
    }
    if (mechanicId.trim().isEmpty) {
      throw ArgumentError.value(mechanicId, 'mechanicId');
    }
    return _copy(
      phase: GroupRoomPhase.roundPrepared,
      roundNumber: roundNumber + 1,
      activeMechanicId: mechanicId,
    );
  }

  GroupZyncSession openInput() =>
      _transition(GroupRoomPhase.roundPrepared, GroupRoomPhase.inputOpen);

  GroupZyncSession lockInput() =>
      _transition(GroupRoomPhase.inputOpen, GroupRoomPhase.inputLocked);

  GroupZyncSession reveal() =>
      _transition(GroupRoomPhase.inputLocked, GroupRoomPhase.reveal);

  GroupZyncSession openReaction() =>
      _transition(GroupRoomPhase.reveal, GroupRoomPhase.reaction);

  GroupZyncSession completeRound() {
    if (phase != GroupRoomPhase.reaction &&
        phase != GroupRoomPhase.reveal) {
      throw StateError('Invalid Group Zync transition to complete');
    }
    return _copy(phase: GroupRoomPhase.complete);
  }

  GroupZyncSession offerZyncNow() {
    if (phase != GroupRoomPhase.complete) {
      throw StateError('Zync Now can only follow a completed group round');
    }
    return _copy(phase: GroupRoomPhase.zyncNowOptional);
  }

  GroupZyncSession end() {
    if (phase == GroupRoomPhase.ended) return this;
    return _copy(phase: GroupRoomPhase.ended);
  }

  GroupBoundedState boundedState({
    String mechanicType = '',
    String title = '',
    String prompt = '',
    String inputKind = '',
    int requiredSelections = 0,
    List<GroupBoundedOption> options = const [],
    String followUp = '',
    int? hiddenSubsetSize,
    String? revealInterestId,
    List<String> revealParticipantIds = const [],
  }) =>
      GroupBoundedState(
        revision: revision,
        phase: phase,
        participantCount: participantCount,
        readyCount: readyCount,
        roundNumber: roundNumber,
        mechanicType: mechanicType,
        title: title,
        prompt: prompt,
        inputKind: inputKind,
        requiredSelections: requiredSelections,
        options: options,
        followUp: followUp,
        hiddenSubsetSize: hiddenSubsetSize,
        revealInterestId: revealInterestId,
        revealParticipantIds: revealParticipantIds,
      );

  GroupZyncSession _transition(
    GroupRoomPhase expected,
    GroupRoomPhase next,
  ) {
    if (phase != expected) {
      throw StateError(
        'Invalid Group Zync transition: ${phase.name} -> ${next.name}',
      );
    }
    return _copy(phase: next);
  }

  void _requireLobbyLike(String action) {
    if (phase != GroupRoomPhase.lobby && phase != GroupRoomPhase.ready) {
      throw StateError('Cannot $action after a Group Zync round has started');
    }
  }

  GroupZyncSession _copy({
    GroupRoomPhase? phase,
    Map<String, GroupParticipantPresence>? participants,
    int? roundNumber,
    String? activeMechanicId,
  }) =>
      GroupZyncSession(
        roomId: roomId,
        maxParticipants: maxParticipants,
        phase: phase ?? this.phase,
        participants: Map.unmodifiable(participants ?? this.participants),
        roundNumber: roundNumber ?? this.roundNumber,
        revision: revision + 1,
        activeMechanicId: activeMechanicId ?? this.activeMechanicId,
      );
}

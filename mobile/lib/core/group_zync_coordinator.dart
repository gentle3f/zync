import 'group_discovery_service.dart';
import 'group_interaction_director.dart';
import 'group_relay_service.dart';
import 'group_zync_protocol.dart';
import 'group_zync_session.dart';
import 'models.dart';
import 'zync_now_consensus.dart';
import 'zync_now_consensus_transport.dart';
import 'zync_now_engine.dart';

class GroupHostCoordinator {
  GroupHostCoordinator._({
    required this.relay,
    required this.room,
    required this.locale,
    required this.hostParticipant,
    required GroupZyncSession session,
  }) : _session = session;

  final GroupRelayClient relay;
  final GroupRoomBootstrap room;
  final String locale;
  final GroupParticipantProfile hostParticipant;

  GroupZyncSession _session;
  GroupInteractionRound? _activeRound;
  GroupPrivateInput? _hostInput;
  ZyncNowConsensusTransportRound? _activeZyncNowConsensus;
  ZyncNowConsensusBallot? _hostZyncNowBallot;
  ZyncNowConsensusResult? _zyncNowConsensusResult;

  GroupZyncSession get session => _session;
  GroupInteractionRound? get activeRound => _activeRound;
  ZyncNowConsensusTransportRound? get activeZyncNowConsensus =>
      _activeZyncNowConsensus;
  ZyncNowConsensusResult? get zyncNowConsensusResult =>
      _zyncNowConsensusResult;

  static Future<GroupHostCoordinator> create({
    required GroupRelayClient relay,
    required LocalProfile hostProfile,
    int maxParticipants = 8,
    bool shareNickname = false,
    DateTime? now,
  }) async {
    final room = GroupRoomBootstrap.generate(
      maxParticipants: maxParticipants,
      now: now,
    );
    final hostParticipant = GroupParticipantProfile.fromLocalProfile(
      participantId: generateGroupParticipantId(),
      profile: hostProfile,
      shareNickname: shareNickname,
    );
    await relay.createRoom(room);

    return GroupHostCoordinator._(
      relay: relay,
      room: room,
      locale: hostProfile.language,
      hostParticipant: hostParticipant,
      session: GroupZyncSession.lobby(
        roomId: room.roomId,
        maxParticipants: maxParticipants,
        hostParticipant: hostParticipant,
      ),
    );
  }

  Future<GroupZyncSession> refreshLobby() async {
    if (_session.phase != GroupRoomPhase.lobby &&
        _session.phase != GroupRoomPhase.ready) {
      return _session;
    }

    final snapshot = await relay.takeParticipants(room);
    var rebuilt = GroupZyncSession.lobby(
      roomId: room.roomId,
      maxParticipants: room.maxParticipants,
      hostParticipant: hostParticipant,
    );

    for (final envelope in snapshot.participants) {
      final participant = await GroupCrypto.decryptParticipant(
        room: room,
        participantId: envelope.participantId,
        opaquePayload: envelope.payload,
      );
      rebuilt = rebuilt.join(participant);
      rebuilt = rebuilt.setReady(participant.participantId, true);
    }

    _session = rebuilt;
    return _session;
  }

  Future<GroupInteractionRound> prepareNextRound({
    String seed = '',
    Map<String, int> previousTargetCounts = const {},
  }) async {
    if (!_session.canStart && _session.phase != GroupRoomPhase.complete) {
      throw StateError('Group Zync room is not ready to start a round');
    }

    final profiles = _session.participants.values
        .map((item) => item.profile)
        .toList(growable: false);
    final plan = GroupDiscoveryPlanner.build(
      participants: profiles,
      seed: seed,
      previousTargetCounts: previousTargetCounts,
    );
    if (plan.candidates.isEmpty) {
      throw StateError('No safe Group Zync discovery round is available');
    }

    final candidate = plan.candidates.first;
    final round = GroupInteractionDirector.build(
      candidate: candidate,
      participants: profiles,
      locale: locale,
    );

    if (_session.phase != GroupRoomPhase.complete) {
      await relay.lockRoom(room);
    }
    _session = _session.prepareRound(round.id);

    if (round.input.privateInputRequired) {
      _session = _session.openInput();
    } else {
      _session = _session.openInput().lockInput();
    }

    _activeRound = round;
    _hostInput = null;
    await _publishActiveRound();
    return round;
  }

  Future<void> lockInput({bool allowIncomplete = false}) async {
    final round = _requireRound();
    if (_session.phase != GroupRoomPhase.inputOpen) {
      throw StateError('Group Zync input is not open');
    }

    if (round.input.privateInputRequired) {
      final collection = await collectRoundInputs();
      if (!collection.complete && !allowIncomplete) {
        throw StateError(
          'Group Zync is still waiting for private input from '
          '${collection.missingParticipantIds.length} participant(s)',
        );
      }
    }

    _session = _session.lockInput();
    await _publishActiveRound();
  }

  void submitHostSelection(List<String> answerIds) {
    final round = _requireRound();
    if (_session.phase != GroupRoomPhase.inputOpen) {
      throw StateError('Group Zync private input is not open');
    }

    final input = GroupPrivateInput(
      roundNumber: _session.roundNumber,
      participantId: hostParticipant.participantId,
      answerIds: List.unmodifiable(answerIds),
    );
    _validateRoundInput(round, input);
    _hostInput = input;
  }

  Future<List<GroupPrivateInput>> takeGuestInputs() async {
    final round = _requireRound();
    final envelopes = await relay.takeInputs(
      room: room,
      roundNumber: _session.roundNumber,
    );
    final result = <GroupPrivateInput>[];
    final seen = <String>{};

    for (final envelope in envelopes) {
      if (!seen.add(envelope.participantId)) {
        throw const FormatException('Duplicate Group Zync input participant');
      }
      final input = await GroupCrypto.decryptPrivateInput(
        room: room,
        participantId: envelope.participantId,
        roundNumber: _session.roundNumber,
        opaquePayload: envelope.payload,
      );
      if (input.participantId == hostParticipant.participantId ||
          !_session.participants.containsKey(input.participantId)) {
        throw const FormatException('Unknown Group Zync input participant');
      }
      _validateRoundInput(round, input);
      result.add(input);
    }
    return List.unmodifiable(result);
  }

  Future<GroupRoundInputCollection> collectRoundInputs() async {
    final round = _requireRound();
    if (!round.input.privateInputRequired) {
      return GroupRoundInputCollection(
        inputs: const [],
        expectedParticipantIds: _session.participants.keys.toSet(),
      );
    }

    final guestInputs = await takeGuestInputs();
    final inputs = <GroupPrivateInput>[
      if (_hostInput != null) _hostInput!,
      ...guestInputs,
    ];

    return GroupRoundInputCollection(
      inputs: List.unmodifiable(inputs),
      expectedParticipantIds: _session.participants.keys.toSet(),
    );
  }

  Future<void> reveal() async {
    _requireRound();
    if (_session.phase != GroupRoomPhase.inputLocked) {
      throw StateError('Group Zync input must be locked before reveal');
    }
    _session = _session.reveal();
    await _publishActiveRound();
  }

  Future<void> openReaction() async {
    _requireRound();
    _session = _session.openReaction();
    await _publishActiveRound();
  }

  Future<void> completeRound() async {
    _requireRound();
    _session = _session.completeRound();
    await _publishActiveRound();
  }

  Future<void> offerZyncNow() async {
    _session = _session.offerZyncNow();
    await _publishActiveRound();
  }

  List<ZyncNowParticipant> zyncNowParticipants() =>
      GroupDiscoveryPlanner.toZyncNowParticipants(
        _session.participants.values
            .map((item) => item.profile)
            .toList(growable: false),
      );

  List<ZyncNowCandidate> generateZyncNow({
    required ZyncNowMode mode,
    ZyncNowConstraints constraints = const ZyncNowConstraints(),
    Set<String> priorActivityKeys = const {},
    String seed = '',
    int limit = 3,
  }) =>
      ZyncNowEngine.generate(
        participants: zyncNowParticipants(),
        mode: mode,
        constraints: constraints,
        priorActivityKeys: priorActivityKeys,
        seed: seed,
        limit: limit,
      );


  Future<ZyncNowConsensusTransportRound> startZyncNowConsensus({
    required List<ZyncNowCandidate> candidates,
    ZyncNowConsensusMethod method = ZyncNowConsensusMethod.quickVote,
  }) async {
    if (_session.phase != GroupRoomPhase.zyncNowOptional) {
      throw StateError('Zync Now consensus is not available yet');
    }

    _session = _session.startZyncNowConsensus(
      'zync_now_${method.name}',
    );
    final round = ZyncNowConsensusTransportRound(
      roundNumber: _session.roundNumber,
      method: method,
      candidates: candidates,
    );
    _activeZyncNowConsensus = round;
    _hostZyncNowBallot = null;
    _zyncNowConsensusResult = null;
    await _publishZyncNowConsensusState();
    return round;
  }

  void submitHostZyncNowBallot(ZyncNowConsensusBallot ballot) {
    final round = _requireZyncNowConsensus();
    if (_session.phase != GroupRoomPhase.zyncNowInputOpen) {
      throw StateError('Zync Now private vote is not open');
    }
    if (ballot.participantId != hostParticipant.participantId) {
      throw ArgumentError('Host ballot must use the host participant ID');
    }
    // Encode + decode gives host input the same structural validation as
    // encrypted guest ballots.
    _hostZyncNowBallot = round.decodeBallot(round.encodeBallot(ballot));
  }

  Future<GroupZyncNowBallotCollection> collectZyncNowBallots() async {
    final round = _requireZyncNowConsensus();
    final envelopes = await relay.takeInputs(
      room: room,
      roundNumber: round.roundNumber,
    );

    final ballots = <ZyncNowConsensusBallot>[
      if (_hostZyncNowBallot != null) _hostZyncNowBallot!,
    ];
    final seen = <String>{hostParticipant.participantId};

    for (final envelope in envelopes) {
      if (!seen.add(envelope.participantId)) {
        throw const FormatException('Duplicate Zync Now ballot participant');
      }
      if (!_session.participants.containsKey(envelope.participantId) ||
          envelope.participantId == hostParticipant.participantId) {
        throw const FormatException('Unknown Zync Now ballot participant');
      }

      final input = await GroupCrypto.decryptPrivateInput(
        room: room,
        participantId: envelope.participantId,
        roundNumber: round.roundNumber,
        opaquePayload: envelope.payload,
      );
      final ballot = round.decodeBallot(input);
      if (ballot.participantId != envelope.participantId) {
        throw const FormatException('Zync Now ballot identity mismatch');
      }
      ballots.add(ballot);
    }

    return GroupZyncNowBallotCollection(
      ballots: List.unmodifiable(ballots),
      expectedParticipantIds: _session.participants.keys.toSet(),
    );
  }

  Future<void> lockZyncNowConsensus() async {
    if (_session.phase != GroupRoomPhase.zyncNowInputOpen) {
      throw StateError('Zync Now private vote is not open');
    }
    final collection = await collectZyncNowBallots();
    if (!collection.complete) {
      throw StateError(
        'Zync Now is still waiting for '
        '${collection.missingParticipantIds.length} participant(s)',
      );
    }

    _session = _session.lockZyncNowInput();
    await _publishZyncNowConsensusState();
  }

  Future<ZyncNowConsensusResult> resolveZyncNowConsensus({
    String seed = '',
  }) async {
    final round = _requireZyncNowConsensus();
    if (_session.phase != GroupRoomPhase.zyncNowInputLocked) {
      throw StateError('Zync Now votes must be locked before resolving');
    }

    final collection = await collectZyncNowBallots();
    if (!collection.complete) {
      throw StateError('Zync Now consensus lost a participant ballot');
    }

    final result = ZyncNowConsensusEngine.resolve(
      candidates: round.candidates,
      participantIds: _session.participants.keys.toList(growable: false),
      ballots: collection.ballots,
      method: round.method,
      seed: seed,
    );

    _zyncNowConsensusResult = result;
    _session = _session.completeZyncNowConsensus();
    await _publishZyncNowConsensusState();
    return result;
  }

  Future<void> end() async {
    _session = _session.end();
    await relay.closeRoom(room);
  }

  void _validateRoundInput(
    GroupInteractionRound round,
    GroupPrivateInput input,
  ) {
    if (input.roundNumber != _session.roundNumber) {
      throw const FormatException('Wrong Group Zync input round');
    }
    if (input.answerIds.length != round.input.requiredSelections ||
        input.answerIds.toSet().length != input.answerIds.length) {
      throw const FormatException('Invalid Group Zync answer count');
    }
    final allowedAnswerIds =
        round.input.options.map((item) => item.id).toSet();
    if (input.answerIds.any((id) => !allowedAnswerIds.contains(id))) {
      throw const FormatException('Unknown Group Zync answer');
    }
  }

  ZyncNowConsensusTransportRound _requireZyncNowConsensus() {
    final round = _activeZyncNowConsensus;
    if (round == null) {
      throw StateError('No active Zync Now consensus round');
    }
    return round;
  }

  GroupInteractionRound _requireRound() {
    final round = _activeRound;
    if (round == null) {
      throw StateError('No active Group Zync round');
    }
    return round;
  }

  Future<void> _publishZyncNowConsensusState() async {
    final round = _requireZyncNowConsensus();
    final result = _zyncNowConsensusResult;

    final title = switch (_session.phase) {
      GroupRoomPhase.zyncNowInputOpen => _zyncNowCopy('voteTitle'),
      GroupRoomPhase.zyncNowInputLocked => _zyncNowCopy('lockedTitle'),
      GroupRoomPhase.zyncNowResult => _zyncNowCopy('resultTitle'),
      _ => 'Zync Now',
    };
    final prompt = switch (_session.phase) {
      GroupRoomPhase.zyncNowInputOpen => _zyncNowCopy(
          switch (round.method) {
            ZyncNowConsensusMethod.quickVote => 'quickPrompt',
            ZyncNowConsensusMethod.rank => 'rankPrompt',
            ZyncNowConsensusMethod.eliminateOne => 'eliminatePrompt',
          },
        ),
      GroupRoomPhase.zyncNowInputLocked => _zyncNowCopy('lockedPrompt'),
      GroupRoomPhase.zyncNowResult =>
        result?.status == ZyncNowConsensusStatus.needsRelaxation
            ? _zyncNowCopy('relaxPrompt')
            : _zyncNowCopy('resultPrompt'),
      _ => '',
    };

    final state = _session.boundedState(
      mechanicType: 'zync_now_consensus',
      title: title,
      prompt: prompt,
      inputKind: round.inputKind,
      requiredSelections: round.requiredSelections,
      options: round.optionsFor(locale),
      resultOptionId: result == null ? null : round.optionIdForResult(result),
    );
    final payload = await GroupCrypto.encryptBoundedState(
      room: room,
      state: state,
    );
    await relay.publishState(
      room: room,
      revision: state.revision,
      payload: payload,
    );
  }

  String _zyncNowCopy(String key) {
    final raw = locale.replaceAll('_', '-').toLowerCase();
    final language = raw.startsWith('zh')
        ? (raw.contains('hans') || raw.contains('-cn') || raw.contains('-sg')
            ? 'zh-Hans'
            : 'zh-Hant')
        : 'en';
    return (_zyncNowCopies[language] ?? _zyncNowCopies['en']!)[key] ??
        _zyncNowCopies['en']![key] ??
        '';
  }

  static const Map<String, Map<String, String>> _zyncNowCopies = {
    'en': {
      'voteTitle': 'Choose together',
      'quickPrompt': 'Rate each idea privately.',
      'rankPrompt': 'Rank the ideas privately.',
      'eliminatePrompt': 'Privately remove one idea.',
      'lockedTitle': 'Votes locked',
      'lockedPrompt': 'Everyone has answered. Zync is finding the best fit.',
      'resultTitle': 'Your Zync',
      'resultPrompt': 'This is the group choice.',
      'relaxPrompt': 'Nothing fits everyone yet. Relax one constraint and try again.',
    },
    'zh-Hant': {
      'voteTitle': '一齊揀',
      'quickPrompt': '每個人私下評價呢三個建議。',
      'rankPrompt': '每個人私下排好次序。',
      'eliminatePrompt': '每個人私下淘汰一個選擇。',
      'lockedTitle': '已收齊答案',
      'lockedPrompt': '大家都揀完，Zync 正在搵最適合全組嘅選擇。',
      'resultTitle': '今次就做呢個',
      'resultPrompt': '呢個係全組最後選擇。',
      'relaxPrompt': '暫時冇一個選擇適合所有人。放寬一個條件再試。',
    },
    'zh-Hans': {
      'voteTitle': '一起选',
      'quickPrompt': '每个人私下评价这三个建议。',
      'rankPrompt': '每个人私下排好顺序。',
      'eliminatePrompt': '每个人私下淘汰一个选择。',
      'lockedTitle': '已收齐答案',
      'lockedPrompt': '大家都选完了，Zync 正在找最适合全组的选择。',
      'resultTitle': '这次就做这个',
      'resultPrompt': '这是全组最后选择。',
      'relaxPrompt': '暂时没有一个选择适合所有人。放宽一个条件再试。',
    },
  };

  Future<void> _publishActiveRound() async {
    final round = _requireRound();
    final revealing = {
      GroupRoomPhase.reveal,
      GroupRoomPhase.reaction,
      GroupRoomPhase.complete,
      GroupRoomPhase.zyncNowOptional,
    }.contains(_session.phase);

    final reacting = {
      GroupRoomPhase.reaction,
      GroupRoomPhase.complete,
      GroupRoomPhase.zyncNowOptional,
    }.contains(_session.phase);

    final state = _session.boundedState(
      mechanicType: round.mechanic.name,
      title: revealing ? round.revealTitle : round.title,
      prompt: revealing ? round.revealBody : round.prompt,
      inputKind: round.input.kind.name,
      requiredSelections: round.input.requiredSelections,
      options: round.input.options
          .map(
            (item) => GroupBoundedOption(
              id: item.id,
              label: item.label,
            ),
          )
          .toList(growable: false),
      followUp: reacting ? round.followUp : '',
      hiddenSubsetSize:
          round.input.kind == GroupInputKind.participantSet
              ? round.input.requiredSelections
              : null,
      revealInterestId: revealing ? round.interestId : null,
      revealParticipantIds:
          revealing ? round.targetParticipantIds : const [],
    );
    final payload = await GroupCrypto.encryptBoundedState(
      room: room,
      state: state,
    );
    await relay.publishState(
      room: room,
      revision: state.revision,
      payload: payload,
    );
  }
}

class GroupRoundInputCollection {
  const GroupRoundInputCollection({
    required this.inputs,
    required this.expectedParticipantIds,
  });

  final List<GroupPrivateInput> inputs;
  final Set<String> expectedParticipantIds;

  Set<String> get submittedParticipantIds =>
      inputs.map((item) => item.participantId).toSet();

  Set<String> get missingParticipantIds =>
      expectedParticipantIds.difference(submittedParticipantIds);

  bool get complete => missingParticipantIds.isEmpty;
}

class GroupZyncNowBallotCollection {
  const GroupZyncNowBallotCollection({
    required this.ballots,
    required this.expectedParticipantIds,
  });

  final List<ZyncNowConsensusBallot> ballots;
  final Set<String> expectedParticipantIds;

  Set<String> get submittedParticipantIds =>
      ballots.map((item) => item.participantId).toSet();

  Set<String> get missingParticipantIds =>
      expectedParticipantIds.difference(submittedParticipantIds);

  bool get complete => missingParticipantIds.isEmpty;
}

class GroupParticipantCoordinator {
  GroupParticipantCoordinator._({
    required this.relay,
    required this.room,
    required this.participant,
    required this.participantToken,
    required this.participantCount,
  });

  final GroupRelayClient relay;
  final GroupJoinQrPayload room;
  final GroupParticipantProfile participant;

  /// Private write capability for this ephemeral room participant. It is never
  /// included in bounded room state or shared with other participants.
  final String participantToken;

  int participantCount;
  int _lastRevision = -1;
  GroupBoundedState? _latestState;

  int get lastRevision => _lastRevision;
  GroupBoundedState? get latestState => _latestState;

  static Future<GroupParticipantCoordinator> join({
    required GroupRelayClient relay,
    required GroupJoinQrPayload room,
    required LocalProfile profile,
    bool shareNickname = false,
  }) async {
    final participant = GroupParticipantProfile.fromLocalProfile(
      participantId: generateGroupParticipantId(),
      profile: profile,
      shareNickname: shareNickname,
    );
    final participantToken = generateGroupParticipantCapability();
    final payload = await GroupCrypto.encryptParticipant(
      room: room,
      participant: participant,
    );
    final participantCount = await relay.join(
      room: room,
      participantId: participant.participantId,
      participantToken: participantToken,
      payload: payload,
    );

    return GroupParticipantCoordinator._(
      relay: relay,
      room: room,
      participant: participant,
      participantToken: participantToken,
      participantCount: participantCount,
    );
  }

  Future<GroupBoundedState?> poll() async {
    final result = await relay.pollState(
      room: room,
      sinceRevision: _lastRevision,
    );
    participantCount = result.participantCount;
    if (!result.ready || result.payload == null) return null;

    final state = await GroupCrypto.decryptBoundedState(
      room: room,
      revision: result.revision,
      opaquePayload: result.payload!,
    );
    _lastRevision = state.revision;
    _latestState = state;
    return state;
  }

  Future<void> submitSelection(List<String> answerIds) async {
    final state = _latestState;
    if (state == null || state.phase != GroupRoomPhase.inputOpen) {
      throw StateError('Group Zync private input is not open');
    }
    if (state.requiredSelections <= 0 ||
        answerIds.length != state.requiredSelections ||
        answerIds.toSet().length != answerIds.length) {
      throw ArgumentError.value(
        answerIds,
        'answerIds',
        'Wrong number of Group Zync selections',
      );
    }
    final allowed = state.options.map((item) => item.id).toSet();
    if (answerIds.any((id) => !allowed.contains(id))) {
      throw ArgumentError.value(
        answerIds,
        'answerIds',
        'Unknown Group Zync selection',
      );
    }

    final input = GroupPrivateInput(
      roundNumber: state.roundNumber,
      participantId: participant.participantId,
      answerIds: List.unmodifiable(answerIds),
    );
    final payload = await GroupCrypto.encryptPrivateInput(
      room: room,
      input: input,
    );
    await relay.submitInput(
      room: room,
      participantId: participant.participantId,
      participantToken: participantToken,
      roundNumber: state.roundNumber,
      payload: payload,
    );
  }

  Future<void> submitZyncNowBallot({
    Map<String, ZyncNowVote> ratingsByOptionId = const {},
    List<String> rankedOptionIds = const [],
    String? eliminateOptionId,
    Set<String> hardVetoOptionIds = const {},
  }) async {
    final state = _latestState;
    if (state == null || state.phase != GroupRoomPhase.zyncNowInputOpen) {
      throw StateError('Zync Now private vote is not open');
    }

    final input = ZyncNowConsensusTransportRound.encodeBoundedOptionBallot(
      state: state,
      participantId: participant.participantId,
      ratingsByOptionId: ratingsByOptionId,
      rankedOptionIds: rankedOptionIds,
      eliminateOptionId: eliminateOptionId,
      hardVetoOptionIds: hardVetoOptionIds,
    );
    final payload = await GroupCrypto.encryptPrivateInput(
      room: room,
      input: input,
    );
    await relay.submitInput(
      room: room,
      participantId: participant.participantId,
      participantToken: participantToken,
      roundNumber: state.roundNumber,
      payload: payload,
    );
  }

  Future<void> leave() => relay.leave(
        room: room,
        participantId: participant.participantId,
        participantToken: participantToken,
      );
}

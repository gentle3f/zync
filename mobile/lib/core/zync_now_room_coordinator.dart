import 'group_relay_service.dart';
import 'group_zync_protocol.dart';
import 'models.dart';
import 'zync_now_consensus.dart';
import 'zync_now_consensus_transport.dart';
import 'zync_now_constraints_transport.dart';
import 'zync_now_engine.dart';

enum ZyncNowRoomStage {
  lobby,
  constraintsOpen,
  consensusOpen,
  consensusLocked,
  result,
  ended,
}

class ZyncNowContextCollection {
  const ZyncNowContextCollection({
    required this.contexts,
    required this.expectedParticipantIds,
  });

  final Map<String, ZyncNowPrivateContext> contexts;
  final Set<String> expectedParticipantIds;

  Set<String> get submittedParticipantIds => contexts.keys.toSet();

  Set<String> get missingParticipantIds =>
      expectedParticipantIds.difference(submittedParticipantIds);

  bool get complete => missingParticipantIds.isEmpty;
}

class ZyncNowBallotCollection {
  const ZyncNowBallotCollection({
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

class ZyncNowRoomHostCoordinator {
  ZyncNowRoomHostCoordinator._({
    required this.relay,
    required this.room,
    required this.locale,
    required this.hostParticipant,
  });

  final GroupRelayClient relay;
  final GroupRoomBootstrap room;
  final String locale;
  final GroupParticipantProfile hostParticipant;

  final Map<String, GroupParticipantProfile> _guestProfiles = {};
  int _revision = -1;
  int _roundNumber = 0;
  ZyncNowRoomStage _stage = ZyncNowRoomStage.lobby;

  ZyncNowPrivateContext? _hostContext;
  Map<String, ZyncNowPrivateContext> _contexts = const {};
  ZyncNowConsensusTransportRound? _consensusRound;
  ZyncNowConsensusBallot? _hostBallot;
  ZyncNowConsensusResult? _result;
  List<ZyncNowCandidate> _finalists = const [];
  bool _needsRelaxation = false;

  ZyncNowRoomStage get stage => _stage;
  int get participantCount => 1 + _guestProfiles.length;
  bool get canStart => participantCount >= 2;
  ZyncNowConsensusTransportRound? get consensusRound => _consensusRound;
  ZyncNowConsensusResult? get result => _result;
  List<ZyncNowCandidate> get finalists => _finalists;
  bool get needsRelaxation => _needsRelaxation;

  List<GroupParticipantProfile> get profiles => List.unmodifiable([
        hostParticipant,
        ..._guestProfiles.values,
      ]);

  static Future<ZyncNowRoomHostCoordinator> create({
    required GroupRelayClient relay,
    required LocalProfile hostProfile,
    int maxParticipants = 8,
    bool shareNickname = false,
    DateTime? now,
  }) async {
    final room = GroupRoomBootstrap.generate(
      maxParticipants: maxParticipants,
      kind: SharedZyncRoomKind.zyncNow,
      now: now,
    );
    final hostParticipant = GroupParticipantProfile.fromLocalProfile(
      participantId: generateGroupParticipantId(),
      profile: hostProfile,
      shareNickname: shareNickname,
    );

    await relay.createRoom(room);

    return ZyncNowRoomHostCoordinator._(
      relay: relay,
      room: room,
      locale: hostProfile.language,
      hostParticipant: hostParticipant,
    );
  }

  Future<void> refreshLobby() async {
    if (_stage != ZyncNowRoomStage.lobby) return;

    final snapshot = await relay.takeParticipants(room);
    if (snapshot.maxParticipants != room.maxParticipants) {
      throw const FormatException('Zync Now room capacity mismatch');
    }

    final seen = <String>{};
    final decoded = <String, GroupParticipantProfile>{};

    for (final envelope in snapshot.participants) {
      if (!seen.add(envelope.participantId) ||
          envelope.participantId == hostParticipant.participantId) {
        throw const FormatException('Invalid Zync Now participant set');
      }

      final participant = await GroupCrypto.decryptParticipant(
        room: room,
        participantId: envelope.participantId,
        opaquePayload: envelope.payload,
      );
      decoded[participant.participantId] = participant;
    }

    _guestProfiles
      ..clear()
      ..addAll(decoded);
  }

  Future<void> openPrivateConstraints(
    ZyncNowPrivateContext hostContext,
  ) async {
    if (_stage != ZyncNowRoomStage.lobby) {
      throw StateError('Zync Now room already started');
    }

    await refreshLobby();
    if (!canStart) {
      throw StateError('Zync Now requires at least two participants');
    }

    await relay.lockRoom(room);
    _hostContext = hostContext;
    _roundNumber = 1;
    _stage = ZyncNowRoomStage.constraintsOpen;
    await _publishConstraintsState();
  }

  Future<ZyncNowContextCollection> collectPrivateContexts() async {
    if (_stage != ZyncNowRoomStage.constraintsOpen) {
      throw StateError('Zync Now private constraints are not open');
    }
    final hostContext = _hostContext;
    if (hostContext == null) {
      throw StateError('Host Zync Now constraints are missing');
    }

    final envelopes = await relay.takeInputs(
      room: room,
      roundNumber: _roundNumber,
    );
    final contexts = <String, ZyncNowPrivateContext>{
      hostParticipant.participantId: hostContext,
    };
    final seen = <String>{};

    for (final envelope in envelopes) {
      if (!seen.add(envelope.participantId) ||
          !_guestProfiles.containsKey(envelope.participantId)) {
        throw const FormatException('Unknown Zync Now constraint participant');
      }

      final input = await GroupCrypto.decryptPrivateInput(
        room: room,
        participantId: envelope.participantId,
        roundNumber: _roundNumber,
        opaquePayload: envelope.payload,
      );
      contexts[envelope.participantId] =
          ZyncNowConstraintsTransport.decode(input);
    }

    return ZyncNowContextCollection(
      contexts: Map.unmodifiable(contexts),
      expectedParticipantIds:
          profiles.map((item) => item.participantId).toSet(),
    );
  }

  Future<List<ZyncNowCandidate>> prepareConsensus({
    Set<String> priorActivityKeys = const {},
    String seed = '',
  }) async {
    final collection = await collectPrivateContexts();
    if (!collection.complete) {
      throw StateError(
        'Zync Now is still waiting for private constraints from '
        '${collection.missingParticipantIds.length} participant(s)',
      );
    }

    _contexts = collection.contexts;
    final participants = [
      for (final profile in profiles)
        ZyncNowParticipant(
          id: profile.participantId,
          interests: profile.interests,
        ),
    ];
    final privateConstraints =
        ZyncNowConstraintsTransport.engineConstraints(_contexts);
    final modes =
        ZyncNowConstraintsTransport.preferredModes(_contexts.values);

    final buckets = <List<ZyncNowCandidate>>[
      for (final mode in modes)
        ZyncNowEngine.generate(
          participants: participants,
          mode: mode,
          participantConstraints: privateConstraints,
          priorActivityKeys: priorActivityKeys,
          seed: '$seed|${mode.name}',
          limit: 6,
        ),
    ];

    final chosen = <ZyncNowCandidate>[];
    final repeatKeys = <String>{};

    void addCandidate(ZyncNowCandidate candidate) {
      if (chosen.length >= 3 || !repeatKeys.add(candidate.repeatKey)) return;
      chosen.add(candidate);
    }

    for (final bucket in buckets) {
      if (bucket.isNotEmpty) addCandidate(bucket.first);
    }

    for (var offset = 0; chosen.length < 3; offset += 1) {
      var foundAny = false;
      for (final bucket in buckets) {
        if (offset >= bucket.length) continue;
        foundAny = true;
        addCandidate(bucket[offset]);
        if (chosen.length >= 3) break;
      }
      if (!foundAny) break;
    }

    _finalists = List.unmodifiable(chosen);
    _hostBallot = null;
    _result = null;

    if (_finalists.length < 2) {
      _needsRelaxation = true;
      _stage = ZyncNowRoomStage.result;
      await _publishResultState();
      return _finalists;
    }

    _needsRelaxation = false;
    _roundNumber = 2;
    _consensusRound = ZyncNowConsensusTransportRound(
      roundNumber: _roundNumber,
      method: ZyncNowConsensusMethod.quickVote,
      candidates: _finalists,
    );
    _stage = ZyncNowRoomStage.consensusOpen;
    await _publishConsensusState();
    return _finalists;
  }

  void submitHostBallot(ZyncNowConsensusBallot ballot) {
    final round = _requireConsensusRound();
    if (_stage != ZyncNowRoomStage.consensusOpen) {
      throw StateError('Zync Now consensus is not open');
    }
    if (ballot.participantId != hostParticipant.participantId) {
      throw ArgumentError('Host ballot must use host participant ID');
    }
    _hostBallot = round.decodeBallot(round.encodeBallot(ballot));
  }

  Future<ZyncNowBallotCollection> collectBallots() async {
    final round = _requireConsensusRound();
    if (_stage != ZyncNowRoomStage.consensusOpen &&
        _stage != ZyncNowRoomStage.consensusLocked) {
      throw StateError('Zync Now consensus is not active');
    }

    final envelopes = await relay.takeInputs(
      room: room,
      roundNumber: round.roundNumber,
    );
    final ballots = <ZyncNowConsensusBallot>[
      if (_hostBallot != null) _hostBallot!,
    ];
    final seen = <String>{hostParticipant.participantId};

    for (final envelope in envelopes) {
      if (!seen.add(envelope.participantId) ||
          !_guestProfiles.containsKey(envelope.participantId)) {
        throw const FormatException('Unknown Zync Now ballot participant');
      }

      final input = await GroupCrypto.decryptPrivateInput(
        room: room,
        participantId: envelope.participantId,
        roundNumber: round.roundNumber,
        opaquePayload: envelope.payload,
      );
      ballots.add(round.decodeBallot(input));
    }

    return ZyncNowBallotCollection(
      ballots: List.unmodifiable(ballots),
      expectedParticipantIds:
          profiles.map((item) => item.participantId).toSet(),
    );
  }

  Future<void> lockConsensus() async {
    if (_stage != ZyncNowRoomStage.consensusOpen) {
      throw StateError('Zync Now consensus is not open');
    }
    final collection = await collectBallots();
    if (!collection.complete) {
      throw StateError(
        'Zync Now is still waiting for '
        '${collection.missingParticipantIds.length} ballot(s)',
      );
    }

    _stage = ZyncNowRoomStage.consensusLocked;
    await _publishConsensusState();
  }

  Future<ZyncNowConsensusResult> resolveConsensus({
    String seed = '',
  }) async {
    final round = _requireConsensusRound();
    if (_stage != ZyncNowRoomStage.consensusLocked) {
      throw StateError('Zync Now consensus must be locked first');
    }
    final collection = await collectBallots();
    if (!collection.complete) {
      throw StateError('Zync Now lost a participant ballot');
    }

    final result = ZyncNowConsensusEngine.resolve(
      candidates: round.candidates,
      participantIds:
          profiles.map((item) => item.participantId).toList(growable: false),
      ballots: collection.ballots,
      method: round.method,
      seed: seed,
    );

    _result = result;
    _needsRelaxation =
        result.status == ZyncNowConsensusStatus.needsRelaxation;
    _stage = ZyncNowRoomStage.result;
    await _publishResultState();
    return result;
  }

  Future<void> close() async {
    if (_stage == ZyncNowRoomStage.ended) return;
    _stage = ZyncNowRoomStage.ended;
    await relay.closeRoom(room);
  }

  ZyncNowConsensusTransportRound _requireConsensusRound() {
    final round = _consensusRound;
    if (round == null) {
      throw StateError('No active Zync Now consensus round');
    }
    return round;
  }

  int _nextRevision() {
    _revision += 1;
    return _revision;
  }

  Future<void> _publishConstraintsState() async {
    final state = GroupBoundedState(
      revision: _nextRevision(),
      phase: GroupRoomPhase.zyncNowInputOpen,
      participantCount: participantCount,
      readyCount: participantCount,
      roundNumber: _roundNumber,
      mechanicType: 'zync_now_constraints',
      title: _copy('constraintsTitle'),
      prompt: _copy('constraintsPrompt'),
      inputKind: ZyncNowConstraintsTransport.inputKind,
    );
    await _publish(state);
  }

  Future<void> _publishConsensusState() async {
    final round = _requireConsensusRound();
    final locked = _stage == ZyncNowRoomStage.consensusLocked;
    final state = GroupBoundedState(
      revision: _nextRevision(),
      phase: locked
          ? GroupRoomPhase.zyncNowInputLocked
          : GroupRoomPhase.zyncNowInputOpen,
      participantCount: participantCount,
      readyCount: participantCount,
      roundNumber: round.roundNumber,
      mechanicType: 'zync_now_consensus',
      title: locked ? _copy('lockedTitle') : _copy('voteTitle'),
      prompt: locked ? _copy('lockedPrompt') : _copy('votePrompt'),
      inputKind: round.inputKind,
      requiredSelections: round.requiredSelections,
      options: round.optionsFor(locale),
    );
    await _publish(state);
  }

  Future<void> _publishResultState() async {
    final round = _consensusRound;
    final result = _result;
    final state = GroupBoundedState(
      revision: _nextRevision(),
      phase: GroupRoomPhase.zyncNowResult,
      participantCount: participantCount,
      readyCount: participantCount,
      roundNumber: _roundNumber,
      mechanicType: 'zync_now_result',
      title: _needsRelaxation
          ? _copy('noFitTitle')
          : _copy('resultTitle'),
      prompt: _needsRelaxation
          ? _copy('noFitPrompt')
          : _copy('resultPrompt'),
      inputKind: round?.inputKind ?? '',
      options: round?.optionsFor(locale) ?? const [],
      resultOptionId:
          result == null ? null : round?.optionIdForResult(result),
    );
    await _publish(state);
  }

  Future<void> _publish(GroupBoundedState state) async {
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

  String _copy(String key) {
    final raw = locale.replaceAll('_', '-').toLowerCase();
    final code = raw.startsWith('zh')
        ? (raw.contains('hans') || raw.contains('-cn') || raw.contains('-sg')
            ? 'zh-Hans'
            : 'zh-Hant')
        : 'en';
    return (_copyTable[code] ?? _copyTable['en']!)[key] ??
        _copyTable['en']![key] ??
        '';
  }

  static const Map<String, Map<String, String>> _copyTable = {
    'en': {
      'constraintsTitle': 'What works for you?',
      'constraintsPrompt':
          'Choose privately. Zync only uses this to remove bad fits.',
      'voteTitle': 'Choose together',
      'votePrompt': 'Rate each idea privately.',
      'lockedTitle': 'Votes locked',
      'lockedPrompt': 'Everyone answered. Zync is finding the best fit.',
      'resultTitle': 'Your Zync',
      'resultPrompt': 'This is the group choice.',
      'noFitTitle': 'Nothing fits everyone yet',
      'noFitPrompt':
          'Keep every hard veto. Relax one preference and try again.',
    },
    'zh-Hant': {
      'constraintsTitle': '你今次想點？',
      'constraintsPrompt': '私下揀。Zync 只會用嚟剔走唔適合你嘅選擇。',
      'voteTitle': '一齊揀',
      'votePrompt': '每個人私下評價呢幾個建議。',
      'lockedTitle': '已收齊答案',
      'lockedPrompt': '大家都揀完，Zync 正在搵最適合全組嘅選擇。',
      'resultTitle': '今次就做呢個',
      'resultPrompt': '呢個係全組最後選擇。',
      'noFitTitle': '暫時冇一個選擇適合所有人',
      'noFitPrompt': '所有 hard veto 繼續保留；放寬一個偏好再試。',
    },
    'zh-Hans': {
      'constraintsTitle': '你这次想怎样？',
      'constraintsPrompt': '私下选择。Zync 只会用来排除不适合你的选项。',
      'voteTitle': '一起选',
      'votePrompt': '每个人私下评价这些建议。',
      'lockedTitle': '已收齐答案',
      'lockedPrompt': '大家都选完了，Zync 正在找最适合全组的选择。',
      'resultTitle': '这次就做这个',
      'resultPrompt': '这是全组最后选择。',
      'noFitTitle': '暂时没有一个选择适合所有人',
      'noFitPrompt': '所有 hard veto 继续保留；放宽一个偏好再试。',
    },
  };
}

class ZyncNowRoomParticipantCoordinator {
  ZyncNowRoomParticipantCoordinator._({
    required this.relay,
    required this.room,
    required this.participant,
    required this.participantToken,
    required this.participantCount,
  });

  final GroupRelayClient relay;
  final GroupJoinQrPayload room;
  final GroupParticipantProfile participant;
  final String participantToken;
  final int participantCount;

  GroupBoundedState? _latestState;
  int _lastRevision = -1;

  GroupBoundedState? get latestState => _latestState;

  static Future<ZyncNowRoomParticipantCoordinator> join({
    required GroupRelayClient relay,
    required GroupJoinQrPayload room,
    required LocalProfile profile,
    bool shareNickname = false,
  }) async {
    if (room.kind != SharedZyncRoomKind.zyncNow) {
      throw const FormatException('Not a standalone Zync Now room');
    }

    final participantId = generateGroupParticipantId();
    final participantToken = generateGroupParticipantCapability();
    final participant = GroupParticipantProfile.fromLocalProfile(
      participantId: participantId,
      profile: profile,
      shareNickname: shareNickname,
    );
    final payload = await GroupCrypto.encryptParticipant(
      room: room,
      participant: participant,
    );
    final count = await relay.join(
      room: room,
      participantId: participantId,
      participantToken: participantToken,
      payload: payload,
    );

    return ZyncNowRoomParticipantCoordinator._(
      relay: relay,
      room: room,
      participant: participant,
      participantToken: participantToken,
      participantCount: count,
    );
  }

  Future<GroupBoundedState?> poll() async {
    final poll = await relay.pollState(
      room: room,
      sinceRevision: _lastRevision,
    );
    if (!poll.ready) return null;
    final payload = poll.payload;
    if (payload == null || payload.isEmpty) {
      throw const GroupRelayException(GroupRelayFailureKind.invalid);
    }

    final state = await GroupCrypto.decryptBoundedState(
      room: room,
      revision: poll.revision,
      opaquePayload: payload,
    );
    if (state.participantCount != poll.participantCount) {
      throw const GroupRelayException(GroupRelayFailureKind.invalid);
    }

    _lastRevision = state.revision;
    _latestState = state;
    return state;
  }

  Future<void> submitPrivateContext(
    ZyncNowPrivateContext context,
  ) async {
    final state = _latestState;
    if (state == null ||
        state.phase != GroupRoomPhase.zyncNowInputOpen ||
        state.inputKind != ZyncNowConstraintsTransport.inputKind) {
      throw StateError('Zync Now private constraints are not open');
    }

    final input = ZyncNowConstraintsTransport.encode(
      roundNumber: state.roundNumber,
      participantId: participant.participantId,
      context: context,
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

  Future<void> submitConsensus({
    Map<String, ZyncNowVote> ratingsByOptionId = const {},
    List<String> rankedOptionIds = const [],
    String? eliminateOptionId,
    Set<String> hardVetoOptionIds = const {},
  }) async {
    final state = _latestState;
    if (state == null ||
        state.phase != GroupRoomPhase.zyncNowInputOpen ||
        state.mechanicType != 'zync_now_consensus') {
      throw StateError('Zync Now consensus is not open');
    }

    final input =
        ZyncNowConsensusTransportRound.encodeBoundedOptionBallot(
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

  Future<void> leaveBeforeStart() => relay.leave(
        room: room,
        participantId: participant.participantId,
        participantToken: participantToken,
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zync/core/group_relay_service.dart';
import 'package:zync/core/group_zync_protocol.dart';
import 'package:zync/core/local_store.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/zync_now_consensus.dart';
import 'package:zync/core/zync_now_consensus_transport.dart';
import 'package:zync/core/zync_now_engine.dart';
import 'package:zync/l10n/generated/app_localizations.dart';
import 'package:zync/screens/group_zync_participant_screen.dart';
import 'package:zync/screens/zync_now_host_screen.dart';
import 'package:zync/screens/zync_now_participant_screen.dart';
import 'package:zync/ui/zync_design.dart';

void main() {
  const profile = LocalProfile(
    localId: 'guest-local-only',
    nickname: 'Guest',
    language: 'en',
    interests: [
      SelectedInterest(
        id: 'sports.badminton',
        strength: InterestStrength.like,
      ),
    ],
  );

  testWidgets(
    'card-focused Zync Now explains that the focus is a soft preference',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const focusedProfile = LocalProfile(
        localId: 'card-focus-host',
        nickname: 'Host',
        language: 'en',
        interests: [
          SelectedInterest(
            id: 'food.coffee',
            strength: InterestStrength.wantToTry,
          ),
        ],
      );
      final relay = _LobbyRelay();

      await tester.pumpWidget(
        _harness(
          ZyncNowHostScreen(
            profile: focusedProfile,
            relayClient: relay,
            preferredInterestId: 'food.coffee',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('zync-now-preferred-interest')),
        findsOneWidget,
      );
      expect(find.text('Starting from Coffee'), findsOneWidget);
      expect(
        find.text(
          'Zync will favor this interest when it fits everyone. Private limits and hard vetoes still win.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'standalone participant stores the chosen activity and returns into World',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final setup = await _resultSetup(
        kind: SharedZyncRoomKind.zyncNow,
      );
      bool? openWorld;

      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  key: const ValueKey('launch-participant'),
                  onPressed: () async {
                    openWorld = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => ZyncNowParticipantScreen(
                          profile: profile,
                          room: setup.room.qr,
                          relayClient: setup.relay,
                        ),
                      ),
                    );
                  },
                  child: const Text('Launch'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('launch-participant')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey('zync-now-participant-continue-world'),
        ),
        findsOneWidget,
      );

      final pending = await LocalStore.loadPendingZyncNowActivity();
      expect(pending, isNotNull);
      expect(pending!.candidateId, setup.candidate.id);
      expect(pending.repeatKey, setup.candidate.repeatKey);
      expect(pending.groupSize, setup.candidate.participantCount);

      await tester.pump(const Duration(seconds: 2));
      expect(await LocalStore.loadZyncNowActivities(), hasLength(1));

      await tester.tap(
        find.byKey(
          const ValueKey('zync-now-participant-continue-world'),
        ),
      );
      await tester.pumpAndSettle();

      expect(openWorld, isTrue);
      expect(find.byKey(const ValueKey('launch-participant')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Group Zync participant stores the chosen activity and returns into World',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final setup = await _resultSetup(
        kind: SharedZyncRoomKind.groupZync,
      );
      bool? openWorld;

      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  key: const ValueKey('launch-group-participant'),
                  onPressed: () async {
                    openWorld = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => GroupZyncParticipantScreen(
                          profile: profile,
                          room: setup.room.qr,
                          relayClient: setup.relay,
                        ),
                      ),
                    );
                  },
                  child: const Text('Launch group'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('launch-group-participant')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey('group-zync-participant-continue-world'),
        ),
        findsOneWidget,
      );

      final pending = await LocalStore.loadPendingZyncNowActivity();
      expect(pending, isNotNull);
      expect(pending!.candidateId, setup.candidate.id);
      expect(pending.templateId, setup.candidate.templateId);
      expect(pending.sourceInterestIds, setup.candidate.sourceInterestIds);

      await tester.pump(const Duration(seconds: 2));
      expect(await LocalStore.loadZyncNowActivities(), hasLength(1));

      await tester.tap(
        find.byKey(
          const ValueKey('group-zync-participant-continue-world'),
        ),
      );
      await tester.pumpAndSettle();

      expect(openWorld, isTrue);
      expect(
        find.byKey(const ValueKey('launch-group-participant')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<
    ({
      GroupRoomBootstrap room,
      ZyncNowCandidate candidate,
      _ResultRelay relay,
    })> _resultSetup({
  required SharedZyncRoomKind kind,
}) async {
  final room = GroupRoomBootstrap.generate(
    maxParticipants: kind == SharedZyncRoomKind.groupZync ? 3 : 2,
    kind: kind,
  );
  const candidate = ZyncNowCandidate(
    id: 'zyncnow.familiar.sports.badminton.activity.play_casual',
    kind: ZyncNowCandidateKind.safe,
    mode: ZyncNowMode.familiar,
    templateId: 'activity.play_casual',
    sourceInterestIds: ['sports.badminton'],
    repeatKey: 'activity.play_casual|sports.badminton',
    score: 80,
    selectedParticipantCount: 2,
    participantCount: 2,
  );
  final round = ZyncNowConsensusTransportRound(
    roundNumber: 2,
    method: ZyncNowConsensusMethod.quickVote,
    candidates: const [
      candidate,
      ZyncNowCandidate(
        id: 'zyncnow.familiar.food.coffee.activity.taste_compare',
        kind: ZyncNowCandidateKind.safe,
        mode: ZyncNowMode.familiar,
        templateId: 'activity.taste_compare',
        sourceInterestIds: ['food.coffee'],
        repeatKey: 'activity.taste_compare|food.coffee',
        score: 70,
        selectedParticipantCount: 2,
        participantCount: 2,
      ),
    ],
  );
  final options = round.optionsFor('en');
  final state = GroupBoundedState(
    revision: 1,
    phase: GroupRoomPhase.zyncNowResult,
    participantCount: kind == SharedZyncRoomKind.groupZync ? 3 : 2,
    readyCount: kind == SharedZyncRoomKind.groupZync ? 3 : 2,
    roundNumber: 2,
    mechanicType: 'zync_now_result',
    title: 'This is your Zync',
    prompt: 'Go make it real.',
    options: options,
    resultOptionId: options.first.id,
  );
  final payload = await GroupCrypto.encryptBoundedState(
    room: room,
    state: state,
  );
  return (
    room: room,
    candidate: candidate,
    relay: _ResultRelay(
      payload: payload,
      revision: state.revision,
      participantCount: state.participantCount,
      maxParticipants: room.maxParticipants,
    ),
  );
}

Widget _harness(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ZyncTheme.light(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

class _LobbyRelay implements GroupRelayClient {
  GroupRoomBootstrap? room;

  @override
  Future<void> createRoom(GroupRoomBootstrap room) async {
    this.room = room;
  }

  @override
  Future<GroupRelayHostSnapshot> takeParticipants(
    GroupRoomBootstrap room,
  ) async =>
      GroupRelayHostSnapshot(
        participantCount: 1,
        maxParticipants: room.maxParticipants,
        locked: false,
        participants: const [],
      );

  @override
  Future<void> closeRoom(GroupRoomBootstrap room) async {}

  @override
  Future<int> join({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required String payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> leave({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> lockRoom(GroupRoomBootstrap room) => throw UnimplementedError();

  @override
  Future<void> submitInput({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required int roundNumber,
    required String payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<GroupRelayInputEnvelope>> takeInputs({
    required GroupRoomBootstrap room,
    required int roundNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> publishState({
    required GroupRoomBootstrap room,
    required int revision,
    required String payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<GroupRelayStatePoll> pollState({
    required GroupJoinQrPayload room,
    required int sinceRevision,
  }) =>
      throw UnimplementedError();
}

class _ResultRelay implements GroupRelayClient {
  _ResultRelay({
    required this.payload,
    required this.revision,
    required this.participantCount,
    required this.maxParticipants,
  });

  final String payload;
  final int revision;
  final int participantCount;
  final int maxParticipants;

  @override
  Future<int> join({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required String payload,
  }) async =>
      participantCount;

  @override
  Future<GroupRelayStatePoll> pollState({
    required GroupJoinQrPayload room,
    required int sinceRevision,
  }) async =>
      sinceRevision < revision
          ? GroupRelayStatePoll(
              ready: true,
              revision: revision,
              participantCount: participantCount,
              maxParticipants: maxParticipants,
              locked: true,
              payload: payload,
            )
          : GroupRelayStatePoll(
              ready: false,
              revision: revision,
              participantCount: participantCount,
              maxParticipants: maxParticipants,
              locked: true,
            );

  @override
  Future<void> leave({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
  }) async {}

  @override
  Future<void> createRoom(GroupRoomBootstrap room) =>
      throw UnimplementedError();

  @override
  Future<GroupRelayHostSnapshot> takeParticipants(
    GroupRoomBootstrap room,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> lockRoom(GroupRoomBootstrap room) => throw UnimplementedError();

  @override
  Future<void> submitInput({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required int roundNumber,
    required String payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<GroupRelayInputEnvelope>> takeInputs({
    required GroupRoomBootstrap room,
    required int roundNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> publishState({
    required GroupRoomBootstrap room,
    required int revision,
    required String payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> closeRoom(GroupRoomBootstrap room) => throw UnimplementedError();
}

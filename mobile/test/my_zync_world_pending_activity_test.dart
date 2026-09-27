import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zync/core/cardverse_cloud_client.dart';
import 'package:zync/core/cardverse_inventory.dart';
import 'package:zync/core/cardverse_models.dart';
import 'package:zync/core/cardverse_session_store.dart';
import 'package:zync/core/local_store.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/progress_event.dart';
import 'package:zync/core/zync_now_engine.dart';
import 'package:zync/core/zync_now_memory.dart';
import 'package:zync/screens/my_zync_world_screen.dart';

class _FakeCloudClient extends CardverseCloudClient {
  _FakeCloudClient(this.snapshot);

  final CardverseInventorySnapshot snapshot;

  @override
  Future<CardverseInventorySnapshot> fetchInventorySnapshot(
    String sessionToken,
  ) async =>
      snapshot;
}

class _MemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

Future<ZyncNowCandidate> _candidate() async {
  final participants = [
    ZyncNowParticipant(
      id: 'a',
      interests: const [
        SelectedInterest(
          id: 'sports.badminton',
          strength: InterestStrength.love,
        ),
      ],
    ),
    ZyncNowParticipant(
      id: 'b',
      interests: const [
        SelectedInterest(
          id: 'sports.badminton',
          strength: InterestStrength.like,
        ),
      ],
    ),
  ];
  return ZyncNowEngine.generate(
    participants: participants,
    mode: ZyncNowMode.familiar,
    seed: 'world-pending-test',
  ).first;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'My Zync World offers a next real-world action when nothing is pending',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const profile = LocalProfile(
        localId: 'local-empty',
        nickname: 'Tester',
        language: 'en',
        interests: [],
      );
      final sessions = CardverseSessionStore(
        storage: _MemorySecureStore(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MyZyncWorldScreen(
            profile: profile,
            sessionStore: sessions,
            onProfileChanged: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zync-world-next-activity')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zync-world-start-next-activity')),
        findsOneWidget,
      );
      expect(find.text('Next step: leave the screen'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('zync-world-pending-activity')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'My Zync World surfaces pending real-world activity and counts completion',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1050);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final candidate = await _candidate();
      await LocalStore.recordZyncNowChoice(
        candidate: candidate,
        chosenAt: DateTime.utc(2026, 9, 19, 10),
      );

      const profile = LocalProfile(
        localId: 'local-test',
        nickname: 'Tester',
        language: 'en',
        interests: [],
      );
      final sessions = CardverseSessionStore(
        storage: _MemorySecureStore(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MyZyncWorldScreen(
            profile: profile,
            sessionStore: sessions,
            onProfileChanged: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zync-world-pending-activity')),
        findsOneWidget,
      );
      expect(find.text('Your next real-world move'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('zync-world-pending-complete')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zync-world-pending-keep')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zync-world-pending-skip')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('zync-world-pending-complete')),
      );
      await tester.pumpAndSettle();

      expect(find.text('You did it. It counts.'), findsOneWidget);
      expect(find.text('View quests & rewards'), findsOneWidget);

      await tester.tap(find.text('Stay in My Zync World'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zync-world-pending-activity')),
        findsNothing,
      );

      final memories = await LocalStore.loadZyncNowActivities();
      expect(memories.single.status, ZyncNowActivityStatus.completed);
      final events = await LocalStore.loadProgressEvents();
      expect(
        events.where(
          (event) => event.type == ZyncProgressEventType.triedTogetherCompleted,
        ),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'completed real-world interest marks the collected card as lived',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1050);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final candidate = await _candidate();
      final memory = await LocalStore.recordZyncNowChoice(
        candidate: candidate,
        chosenAt: DateTime.utc(2026, 9, 20, 10),
      );
      await LocalStore.recordZyncNowOutcome(
        memoryId: memory.id,
        status: ZyncNowActivityStatus.completed,
        at: DateTime.utc(2026, 9, 20, 12),
      );

      const profile = LocalProfile(
        localId: 'local-lived-card',
        nickname: 'Tester',
        language: 'en',
        interests: [],
      );
      final sessions = CardverseSessionStore(
        storage: _MemorySecureStore(),
      );
      await sessions.save(
        CardverseSessionCredential(
          token: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
        ),
      );

      const inventory = CardverseInventorySnapshot(
        accountId: 'account-lived-card',
        ledgerCursor: 1,
        drawTokens: 0,
        lockedDrawTokens: 0,
        claimedEligibilityKeys: <String>{},
        cards: <CardverseInventoryCard>[
          CardverseInventoryCard(
            variant: CardVariantKey(
              interestId: 'sports.badminton',
              finishId: 'normal',
              editionId: 'core_set_1',
            ),
            quantity: 1,
          ),
        ],
        unopenedPacks: <CardverseUnopenedPack>[],
      );
      final cloud = _FakeCloudClient(inventory);

      await tester.pumpWidget(
        MaterialApp(
          home: MyZyncWorldScreen(
            profile: profile,
            sessionStore: sessions,
            cloudClient: cloud,
            onProfileChanged: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(
        const ValueKey(
          'zync-world-card-sports.badminton::normal::core_set_1',
        ),
      );
      await tester.scrollUntilVisible(
        card,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(
          const ValueKey(
            'zync-world-lived-sports.badminton::normal::core_set_1',
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zync-world-card-real-life-status')),
        findsOneWidget,
      );
      expect(
        find.text('You have lived this beyond the card'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

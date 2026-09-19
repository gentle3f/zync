import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_proof_cache.dart';
import 'package:zync/core/cardverse_proof_capture.dart';
import 'package:zync/core/relay_service.dart';
import 'package:zync/core/secure_key_value_store.dart';

class _MemorySecureStore implements SecureKeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _ThrowingSecureStore implements SecureKeyValueStore {
  @override
  Future<String?> read(String key) => Future.error(StateError('locked'));

  @override
  Future<void> write(String key, String value) =>
      Future.error(StateError('locked'));

  @override
  Future<void> delete(String key) => Future.error(StateError('locked'));
}

class _FakeRelay implements RelayClient {
  int proofCalls = 0;

  @override
  Future<void> createSession({
    required String sessionId,
    required String hostToken,
    required DateTime expiresAt,
  }) async {}

  @override
  Future<RelayRespondResult> respond({
    required String sessionId,
    required String payload,
  }) async => const RelayRespondResult();

  @override
  Future<RelayTakeResult> take({
    required String sessionId,
    required String hostToken,
  }) async => const RelayTakeResult.waiting();

  @override
  Future<RelayProofResult> proof({
    required String sessionId,
    required String proofCapability,
  }) async {
    proofCalls += 1;
    if (proofCalls == 1) return const RelayProofResult.waiting();
    return const RelayProofResult.ready('ZP1.ready.signature');
  }

  @override
  Future<RelayConsumeResult> consume({
    required String sessionId,
    required String hostToken,
  }) async => const RelayConsumeResult();

  @override
  Future<void> cancel({
    required String sessionId,
    required String hostToken,
  }) async {}
}

void main() {
  test('scanner proof capture promotes capability into encrypted ticket', () async {
    final relay = _FakeRelay();
    final cache = CardverseProofCache(storage: _MemorySecureStore());

    await CardverseRelayProofCapture.captureScanner(
      relay: relay,
      sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      proofCapability: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
      clientEventId: 'relay:event:scanner',
      timezoneOffsetMinutes: 480,
      cache: cache,
      retryDelays: const [Duration.zero, Duration.zero],
    );

    expect(relay.proofCalls, 2);
    final tickets = await cache.loadTickets();
    expect(tickets, hasLength(1));
    expect(tickets.single.clientEventId, 'relay:event:scanner');
    expect(tickets.single.ticket, 'ZP1.ready.signature');
    expect(tickets.single.timezoneOffsetMinutes, 480);
    expect(await cache.loadCapabilities(), isEmpty);
  });

  test('host proof ticket is preserved without Cardverse login', () async {
    final cache = CardverseProofCache(storage: _MemorySecureStore());
    await CardverseRelayProofCapture.saveHostTicket(
      proofTicket: 'ZP1.host.signature',
      clientEventId: 'relay:event:host',
      capturedAt: DateTime.utc(2026, 9, 20),
      timezoneOffsetMinutes: 480,
      cache: cache,
    );

    final tickets = await cache.loadTickets(
      now: DateTime.utc(2026, 9, 20, 0, 1),
    );
    expect(tickets.single.ticket, 'ZP1.host.signature');
    expect(tickets.single.timezoneOffsetMinutes, 480);
  });

  test('secure-storage failure never breaks host Zync completion', () async {
    final cache = CardverseProofCache(storage: _ThrowingSecureStore());

    await CardverseRelayProofCapture.saveHostTicket(
      proofTicket: 'ZP1.host.signature',
      clientEventId: 'relay:event:host',
      timezoneOffsetMinutes: 480,
      cache: cache,
    );
  });

  test('secure-storage failure never breaks scanner Zync completion', () async {
    final relay = _FakeRelay();
    final cache = CardverseProofCache(storage: _ThrowingSecureStore());

    await CardverseRelayProofCapture.captureScanner(
      relay: relay,
      sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      proofCapability: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
      clientEventId: 'relay:event:scanner',
      timezoneOffsetMinutes: 480,
      cache: cache,
      retryDelays: const [Duration.zero, Duration.zero],
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zync/core/cardverse_proof_cache.dart';
import 'package:zync/core/cardverse_proof_capture.dart';
import 'package:zync/core/relay_service.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('scanner proof capture promotes capability into durable local ticket', () async {
    final relay = _FakeRelay();

    await CardverseRelayProofCapture.captureScanner(
      relay: relay,
      sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
      proofCapability: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
      clientEventId: 'relay:event:scanner',
      retryDelays: const [Duration.zero, Duration.zero],
    );

    expect(relay.proofCalls, 2);
    final tickets = await CardverseProofCache.loadTickets();
    expect(tickets, hasLength(1));
    expect(tickets.single.clientEventId, 'relay:event:scanner');
    expect(tickets.single.ticket, 'ZP1.ready.signature');
    expect(await CardverseProofCache.loadCapabilities(), isEmpty);
  });

  test('host proof ticket is preserved without requiring Cardverse login', () async {
    await CardverseRelayProofCapture.saveHostTicket(
      proofTicket: 'ZP1.host.signature',
      clientEventId: 'relay:event:host',
      capturedAt: DateTime.utc(2026, 9, 20),
    );

    final tickets = await CardverseProofCache.loadTickets(
      now: DateTime.utc(2026, 9, 20, 0, 1),
    );
    expect(tickets.single.ticket, 'ZP1.host.signature');
  });
}

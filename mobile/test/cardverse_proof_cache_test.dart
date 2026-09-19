import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zync/core/cardverse_proof_cache.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('proof ticket cache deduplicates by local event', () async {
    final first = PendingCardverseProofTicket(
      ticket: 'ZP1.first.signature',
      clientEventId: 'relay:event:host',
      capturedAt: DateTime.utc(2026, 9, 20),
    );
    final second = PendingCardverseProofTicket(
      ticket: 'ZP1.second.signature',
      clientEventId: 'relay:event:host',
      capturedAt: DateTime.utc(2026, 9, 20, 0, 1),
    );

    await CardverseProofCache.saveTicket(first);
    await CardverseProofCache.saveTicket(second);

    final items = await CardverseProofCache.loadTickets(
      now: DateTime.utc(2026, 9, 20, 0, 2),
    );
    expect(items, hasLength(1));
    expect(items.single.ticket, second.ticket);
  });

  test('stale relay capability is pruned locally', () async {
    await CardverseProofCache.saveCapability(
      PendingRelayProofCapability(
        sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
        proofCapability: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        clientEventId: 'relay:event:scanner',
        capturedAt: DateTime.utc(2026, 9, 20),
      ),
    );

    final items = await CardverseProofCache.loadCapabilities(
      now: DateTime.utc(2026, 9, 20, 0, 11),
    );
    expect(items, isEmpty);
  });
}

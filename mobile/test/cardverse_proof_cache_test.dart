import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_proof_cache.dart';
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

void main() {
  test('proof ticket cache is encrypted-store backed and deduplicates event', () async {
    final secure = _MemorySecureStore();
    final cache = CardverseProofCache(storage: secure);
    final first = PendingCardverseProofTicket(
      ticket: 'ZP1.first.signature',
      clientEventId: 'relay:event:host',
      capturedAt: DateTime.utc(2026, 9, 20),
      timezoneOffsetMinutes: 480,
    );
    final second = PendingCardverseProofTicket(
      ticket: 'ZP1.second.signature',
      clientEventId: 'relay:event:host',
      capturedAt: DateTime.utc(2026, 9, 20, 0, 1),
      timezoneOffsetMinutes: 480,
    );

    await cache.saveTicket(first);
    await cache.saveTicket(second);

    final items = await cache.loadTickets(
      now: DateTime.utc(2026, 9, 20, 0, 2),
    );
    expect(items, hasLength(1));
    expect(items.single.ticket, second.ticket);
    expect(secure.values.values.join(), contains('ZP1.second.signature'));
  });

  test('stale relay capability is pruned from encrypted store', () async {
    final secure = _MemorySecureStore();
    final cache = CardverseProofCache(storage: secure);
    await cache.saveCapability(
      PendingRelayProofCapability(
        sessionId: 'ABCDEFGHIJKLMNOPQRSTUVWX',
        proofCapability: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        clientEventId: 'relay:event:scanner',
        capturedAt: DateTime.utc(2026, 9, 20),
        timezoneOffsetMinutes: 480,
      ),
    );

    final items = await cache.loadCapabilities(
      now: DateTime.utc(2026, 9, 20, 0, 11),
    );
    expect(items, isEmpty);
  });
}

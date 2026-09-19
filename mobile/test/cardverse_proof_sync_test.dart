import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zync/core/cardverse_cloud_client.dart';
import 'package:zync/core/cardverse_proof_cache.dart';
import 'package:zync/core/cardverse_proof_sync.dart';
import 'package:zync/core/cardverse_session_store.dart';

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
  test('pending anonymous proof redeems only after secure session exists', () async {
    final secure = _MemorySecureStore();
    final proofs = CardverseProofCache(storage: secure);
    await proofs.saveTicket(
      PendingCardverseProofTicket(
        ticket: 'ZP1.pending.signature',
        clientEventId: 'relay:event:host',
        capturedAt: DateTime.utc(2026, 9, 20),
        timezoneOffsetMinutes: 480,
      ),
    );

    final sessions = CardverseSessionStore(storage: secure);
    var requests = 0;
    final cloud = CardverseCloudClient(
      baseUrl: 'https://zync.example',
      httpClient: MockClient((request) async {
        requests += 1;
        return http.Response('{"proofId":"proof-1"}', 200);
      }),
    );
    final sync = CardverseProofSync(
      cloud: cloud,
      sessions: sessions,
      proofs: proofs,
    );

    final beforeLogin = await sync.syncPending();
    expect(beforeLogin.redeemed, 0);
    expect(beforeLogin.remaining, 1);
    expect(requests, 0);

    await sessions.save(
      CardverseSessionCredential(
        token: 'D' * 43,
        expiresAt: DateTime.utc(2026, 10, 20),
      ),
    );

    final afterLogin = await sync.syncPending();
    expect(afterLogin.redeemed, 1);
    expect(afterLogin.remaining, 0);
    expect(requests, 1);
  });

  test('401 clears secure session but preserves pending proof', () async {
    final secure = _MemorySecureStore();
    final proofs = CardverseProofCache(storage: secure);
    await proofs.saveTicket(
      PendingCardverseProofTicket(
        ticket: 'ZP1.pending.signature',
        clientEventId: 'relay:event:host',
        capturedAt: DateTime.utc(2026, 9, 20),
        timezoneOffsetMinutes: 480,
      ),
    );

    final sessions = CardverseSessionStore(storage: secure);
    await sessions.save(
      CardverseSessionCredential(
        token: 'E' * 43,
        expiresAt: DateTime.utc(2026, 10, 20),
      ),
    );
    final cloud = CardverseCloudClient(
      baseUrl: 'https://zync.example',
      httpClient: MockClient(
        (_) async => http.Response(
          '{"error":"cardverse_session_invalid"}',
          401,
        ),
      ),
    );

    final result = await CardverseProofSync(
      cloud: cloud,
      sessions: sessions,
      proofs: proofs,
    ).syncPending();

    expect(result.sessionCleared, isTrue);
    expect(result.remaining, 1);
    expect(await sessions.load(now: DateTime.utc(2026, 9, 20)), isNull);
  });
}

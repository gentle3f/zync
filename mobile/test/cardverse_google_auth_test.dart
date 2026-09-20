import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_cloud_client.dart';
import 'package:zync/core/cardverse_google_auth.dart';
import 'package:zync/core/cardverse_proof_sync.dart';
import 'package:zync/core/cardverse_session_store.dart';
import 'package:zync/core/google_identity_bridge.dart';

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

class _FakeCloud extends CardverseCloudClient {
  _FakeCloud()
      : super(baseUrl: 'https://zync.example');

  String? seenProvider;
  String? seenChallengeId;
  String? seenIdToken;

  @override
  Future<CardverseAuthChallenge> createAuthChallenge(String provider) async {
    seenProvider = provider;
    return CardverseAuthChallenge(
      challengeId: 'challenge-1',
      provider: 'google',
      nonce: 'server-issued-single-use-nonce',
      expiresAt: DateTime.utc(2026, 9, 20, 9),
    );
  }

  @override
  Future<CardverseAuthResult> authenticateProvider({
    required String provider,
    required String challengeId,
    required String idToken,
  }) async {
    seenProvider = provider;
    seenChallengeId = challengeId;
    seenIdToken = idToken;
    return CardverseAuthResult(
      accountId: 'account-1',
      accountCreated: true,
      provider: 'google',
      session: CardverseSessionCredential(
        token: 'S' * 43,
        expiresAt: DateTime.utc(2026, 10, 20),
      ),
    );
  }
}

class _FakeGoogleIdentity implements GoogleIdentityProvider {
  String? seenClientId;
  String? seenNonce;

  @override
  Future<String> authenticate({
    required String serverClientId,
    required String nonce,
  }) async {
    seenClientId = serverClientId;
    seenNonce = nonce;
    return 'header.payload.signature';
  }
}

void main() {
  test('Google auth binds provider token request to server challenge nonce',
      () async {
    final cloud = _FakeCloud();
    final identity = _FakeGoogleIdentity();
    final secure = _MemorySecureStore();
    final sessions = CardverseSessionStore(storage: secure);
    var syncCalls = 0;

    final service = CardverseGoogleAuthService(
      cloud: cloud,
      sessions: sessions,
      identity: identity,
      serverClientId: '123.apps.googleusercontent.com',
      syncPendingProofs: () async {
        syncCalls += 1;
        return const CardverseProofSyncResult(
          redeemed: 0,
          discarded: 0,
          remaining: 0,
          sessionCleared: false,
        );
      },
    );

    final result = await service.signIn();

    expect(cloud.seenProvider, 'google');
    expect(identity.seenClientId, '123.apps.googleusercontent.com');
    expect(identity.seenNonce, 'server-issued-single-use-nonce');
    expect(cloud.seenChallengeId, 'challenge-1');
    expect(cloud.seenIdToken, 'header.payload.signature');
    expect(result.auth.accountId, 'account-1');
    expect(syncCalls, 1);
    expect(await sessions.load(now: DateTime.utc(2026, 9, 21)), isNotNull);
  });

  test('Google auth fails closed without a Web client id', () async {
    final service = CardverseGoogleAuthService(
      cloud: _FakeCloud(),
      sessions: CardverseSessionStore(storage: _MemorySecureStore()),
      identity: _FakeGoogleIdentity(),
      serverClientId: '',
      syncPendingProofs: () async => const CardverseProofSyncResult(
        redeemed: 0,
        discarded: 0,
        remaining: 0,
        sessionCleared: false,
      ),
    );

    await expectLater(
      service.signIn(),
      throwsA(
        isA<CardverseGoogleAuthException>().having(
          (error) => error.code,
          'code',
          'google_server_client_id_not_configured',
        ),
      ),
    );
  });
}

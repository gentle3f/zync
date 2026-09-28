import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/apple_identity_provider.dart';
import 'package:zync/core/cardverse_apple_auth.dart';
import 'package:zync/core/cardverse_cloud_client.dart';
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

class _FakeAppleCloud extends CardverseCloudClient {
  _FakeAppleCloud() : super(baseUrl: 'https://zync.example');

  String? seenChallengeProvider;
  String? seenAuthProvider;
  String? seenChallengeId;
  String? seenIdToken;
  String returnedChallengeProvider = 'apple';
  String returnedAuthProvider = 'apple';

  @override
  Future<CardverseAuthChallenge> createAuthChallenge(String provider) async {
    seenChallengeProvider = provider;
    return CardverseAuthChallenge(
      challengeId: 'apple-challenge-1',
      provider: returnedChallengeProvider,
      nonce: 'apple-server-single-use-nonce',
      expiresAt: DateTime.utc(2026, 9, 28, 10),
    );
  }

  @override
  Future<CardverseAuthResult> authenticateProvider({
    required String provider,
    required String challengeId,
    required String idToken,
  }) async {
    seenAuthProvider = provider;
    seenChallengeId = challengeId;
    seenIdToken = idToken;
    return CardverseAuthResult(
      accountId: 'account-apple-1',
      accountCreated: true,
      provider: returnedAuthProvider,
      session: CardverseSessionCredential(
        token: 'A' * 43,
        expiresAt: DateTime.utc(2026, 10, 28),
      ),
    );
  }
}

class _FakeAppleIdentity implements AppleIdentityProvider {
  String? seenNonce;

  @override
  Future<AppleIdentityCredential> authenticate({
    required String nonce,
  }) async {
    seenNonce = nonce;
    return const AppleIdentityCredential(
      idToken: 'apple.header.signature',
      authorizationCode: 'fresh-apple-authorization-code',
    );
  }
}

void main() {
  test('Apple auth binds provider token request to server challenge nonce',
      () async {
    final cloud = _FakeAppleCloud();
    final identity = _FakeAppleIdentity();
    final sessions = CardverseSessionStore(
      storage: _MemorySecureStore(),
    );
    var syncCalls = 0;

    final service = CardverseAppleAuthService(
      cloud: cloud,
      sessions: sessions,
      identity: identity,
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

    expect(cloud.seenChallengeProvider, 'apple');
    expect(identity.seenNonce, 'apple-server-single-use-nonce');
    expect(cloud.seenAuthProvider, 'apple');
    expect(cloud.seenChallengeId, 'apple-challenge-1');
    expect(cloud.seenIdToken, 'apple.header.signature');
    expect(result.auth.accountId, 'account-apple-1');
    expect(syncCalls, 1);
    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNotNull,
    );
  });


  test('Apple auth rejects a mismatched provider in auth response', () async {
    final cloud = _FakeAppleCloud()
      ..returnedAuthProvider = 'google';
    final identity = _FakeAppleIdentity();
    final sessions = CardverseSessionStore(
      storage: _MemorySecureStore(),
    );

    final service = CardverseAppleAuthService(
      cloud: cloud,
      sessions: sessions,
      identity: identity,
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
        isA<CardverseCloudException>().having(
          (error) => error.failure,
          'failure',
          CardverseCloudFailure.invalidResponse,
        ),
      ),
    );
    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNull,
    );
  });

  test('Apple auth fails closed if challenge provider is not apple', () async {
    final cloud = _FakeAppleCloud()
      ..returnedChallengeProvider = 'google';
    final identity = _FakeAppleIdentity();

    final service = CardverseAppleAuthService(
      cloud: cloud,
      sessions: CardverseSessionStore(
        storage: _MemorySecureStore(),
      ),
      identity: identity,
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
        isA<CardverseCloudException>().having(
          (error) => error.failure,
          'failure',
          CardverseCloudFailure.invalidResponse,
        ),
      ),
    );
    expect(identity.seenNonce, isNull);
    expect(cloud.seenAuthProvider, isNull);
  });
}
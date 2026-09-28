import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/apple_identity_provider.dart';
import 'package:zync/core/cardverse_account_deletion.dart';
import 'package:zync/core/cardverse_cloud_client.dart';
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

class _FakeDeleteCloud extends CardverseCloudClient {
  _FakeDeleteCloud() : super(baseUrl: 'https://zync.example');

  String? challengeProvider;
  String returnedChallengeProvider = 'google';
  String? sessionToken;
  String? provider;
  String? challengeId;
  String? idToken;
  String? authorizationCode;
  CardverseCloudException? deleteError;

  @override
  Future<CardverseAuthChallenge> createAuthChallenge(String provider) async {
    challengeProvider = provider;
    return CardverseAuthChallenge(
      challengeId: 'delete-challenge-$provider',
      provider: returnedChallengeProvider,
      nonce: 'delete-nonce-$provider',
      expiresAt: DateTime.utc(2026, 9, 28, 20),
    );
  }

  @override
  Future<void> deleteAccount({
    required String sessionToken,
    required String provider,
    required String challengeId,
    required String idToken,
    String? authorizationCode,
  }) async {
    this.sessionToken = sessionToken;
    this.provider = provider;
    this.challengeId = challengeId;
    this.idToken = idToken;
    this.authorizationCode = authorizationCode;
    final error = deleteError;
    if (error != null) throw error;
  }
}

class _FakeGoogleIdentity implements GoogleIdentityProvider {
  int calls = 0;
  String? serverClientId;
  String? nonce;

  @override
  Future<String> authenticate({
    required String serverClientId,
    required String nonce,
  }) async {
    calls += 1;
    this.serverClientId = serverClientId;
    this.nonce = nonce;
    return 'google.header.signature';
  }
}

class _FakeAppleIdentity implements AppleIdentityProvider {
  int calls = 0;
  String? nonce;

  @override
  Future<AppleIdentityCredential> authenticate({
    required String nonce,
  }) async {
    calls += 1;
    this.nonce = nonce;
    return const AppleIdentityCredential(
      idToken: 'apple.header.signature',
      authorizationCode: 'fresh-apple-delete-code',
    );
  }
}

Future<CardverseSessionStore> _sessions() async {
  final store = CardverseSessionStore(storage: _MemorySecureStore());
  await store.save(
    CardverseSessionCredential(
      token: 'S' * 43,
      expiresAt: DateTime.utc(2026, 10, 28),
    ),
  );
  return store;
}

void main() {
  test('Google deletion uses fresh challenge and clears session only on success',
      () async {
    final cloud = _FakeDeleteCloud()..returnedChallengeProvider = 'google';
    final sessions = await _sessions();
    final google = _FakeGoogleIdentity();
    final apple = _FakeAppleIdentity();
    final service = CardverseAccountDeletionService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: google,
      appleIdentity: apple,
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await service.deleteWithGoogle();

    expect(cloud.challengeProvider, 'google');
    expect(google.serverClientId, '123.apps.googleusercontent.com');
    expect(google.nonce, 'delete-nonce-google');
    expect(cloud.sessionToken, 'S' * 43);
    expect(cloud.provider, 'google');
    expect(cloud.challengeId, 'delete-challenge-google');
    expect(cloud.idToken, 'google.header.signature');
    expect(cloud.authorizationCode, isNull);
    expect(apple.calls, 0);
    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNull,
    );
  });

  test('Apple deletion sends fresh authorization code then clears session',
      () async {
    final cloud = _FakeDeleteCloud()..returnedChallengeProvider = 'apple';
    final sessions = await _sessions();
    final apple = _FakeAppleIdentity();
    final service = CardverseAccountDeletionService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: _FakeGoogleIdentity(),
      appleIdentity: apple,
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await service.deleteWithApple();

    expect(cloud.challengeProvider, 'apple');
    expect(apple.nonce, 'delete-nonce-apple');
    expect(cloud.provider, 'apple');
    expect(cloud.idToken, 'apple.header.signature');
    expect(cloud.authorizationCode, 'fresh-apple-delete-code');
    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNull,
    );
  });

  test('Apple-required conflict after Google preserves session', () async {
    final cloud = _FakeDeleteCloud()
      ..returnedChallengeProvider = 'google'
      ..deleteError = const CardverseCloudException(
        failure: CardverseCloudFailure.conflict,
        statusCode: 409,
        serverCode: 'cardverse_apple_reauth_required',
      );
    final sessions = await _sessions();
    final service = CardverseAccountDeletionService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: _FakeGoogleIdentity(),
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.deleteWithGoogle(),
      throwsA(
        isA<CardverseCloudException>().having(
          (error) => error.serverCode,
          'serverCode',
          'cardverse_apple_reauth_required',
        ),
      ),
    );

    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNotNull,
    );
  });

  test('Apple revoke/provider failure preserves local session', () async {
    final cloud = _FakeDeleteCloud()
      ..returnedChallengeProvider = 'apple'
      ..deleteError = const CardverseCloudException(
        failure: CardverseCloudFailure.unavailable,
        statusCode: 502,
        serverCode: 'cardverse_apple_revoke_failed',
      );
    final sessions = await _sessions();
    final service = CardverseAccountDeletionService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: _FakeGoogleIdentity(),
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.deleteWithApple(),
      throwsA(isA<CardverseCloudException>()),
    );

    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNotNull,
    );
  });

  test('401 during deletion clears stale local session', () async {
    final cloud = _FakeDeleteCloud()
      ..returnedChallengeProvider = 'google'
      ..deleteError = const CardverseCloudException(
        failure: CardverseCloudFailure.unauthorized,
        statusCode: 401,
        serverCode: 'cardverse_session_invalid',
      );
    final sessions = await _sessions();
    final service = CardverseAccountDeletionService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: _FakeGoogleIdentity(),
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.deleteWithGoogle(),
      throwsA(isA<CardverseCloudException>()),
    );

    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNull,
    );
  });

  test('delete fails before provider auth when session is missing', () async {
    final cloud = _FakeDeleteCloud();
    final google = _FakeGoogleIdentity();
    final service = CardverseAccountDeletionService(
      cloud: cloud,
      sessions: CardverseSessionStore(storage: _MemorySecureStore()),
      googleIdentity: google,
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.deleteWithGoogle(),
      throwsA(
        isA<CardverseAccountDeletionException>().having(
          (error) => error.code,
          'code',
          'cardverse_delete_session_missing',
        ),
      ),
    );
    expect(cloud.challengeProvider, isNull);
    expect(google.calls, 0);
  });

  test('challenge provider mismatch fails before destructive request', () async {
    final cloud = _FakeDeleteCloud()..returnedChallengeProvider = 'apple';
    final google = _FakeGoogleIdentity();
    final sessions = await _sessions();
    final service = CardverseAccountDeletionService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: google,
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.deleteWithGoogle(),
      throwsA(
        isA<CardverseCloudException>().having(
          (error) => error.failure,
          'failure',
          CardverseCloudFailure.invalidResponse,
        ),
      ),
    );
    expect(google.calls, 0);
    expect(cloud.provider, isNull);
    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNotNull,
    );
  });
}

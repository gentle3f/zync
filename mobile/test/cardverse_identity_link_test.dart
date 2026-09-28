import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/apple_identity_provider.dart';
import 'package:zync/core/cardverse_cloud_client.dart';
import 'package:zync/core/cardverse_identity_link.dart';
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

class _FakeLinkCloud extends CardverseCloudClient {
  _FakeLinkCloud() : super(baseUrl: 'https://zync.example');

  String challengeProvider = 'google';
  String? requestedChallengeProvider;
  String? seenSessionToken;
  String? seenProvider;
  String? seenChallengeId;
  String? seenIdToken;
  CardverseCloudException? linkError;

  @override
  Future<CardverseAuthChallenge> createAuthChallenge(String provider) async {
    requestedChallengeProvider = provider;
    return CardverseAuthChallenge(
      challengeId: 'challenge-link-1',
      provider: challengeProvider,
      nonce: 'server-link-nonce',
      expiresAt: DateTime.utc(2026, 9, 28, 13),
    );
  }

  @override
  Future<CardverseProviderLinkResult> linkProviderIdentity({
    required String sessionToken,
    required String provider,
    required String challengeId,
    required String idToken,
  }) async {
    seenSessionToken = sessionToken;
    seenProvider = provider;
    seenChallengeId = challengeId;
    seenIdToken = idToken;
    final error = linkError;
    if (error != null) throw error;
    return CardverseProviderLinkResult(
      provider: provider,
      linked: true,
      restored: false,
    );
  }
}

class _FakeGoogleIdentity implements GoogleIdentityProvider {
  String? clientId;
  String? nonce;
  int calls = 0;

  @override
  Future<String> authenticate({
    required String serverClientId,
    required String nonce,
  }) async {
    calls += 1;
    clientId = serverClientId;
    this.nonce = nonce;
    return 'google.header.signature';
  }
}

class _FakeAppleIdentity implements AppleIdentityProvider {
  String? nonce;
  int calls = 0;

  @override
  Future<AppleIdentityCredential> authenticate({
    required String nonce,
  }) async {
    calls += 1;
    this.nonce = nonce;
    return const AppleIdentityCredential(
      idToken: 'apple.header.signature',
      authorizationCode: 'fresh-apple-authorization-code',
    );
  }
}

Future<CardverseSessionStore> _signedInStore() async {
  final sessions = CardverseSessionStore(
    storage: _MemorySecureStore(),
  );
  await sessions.save(
    CardverseSessionCredential(
      token: 'S' * 43,
      expiresAt: DateTime.utc(2026, 10, 28),
    ),
  );
  return sessions;
}

void main() {
  test('Google link uses current session and exact server challenge nonce',
      () async {
    final cloud = _FakeLinkCloud();
    final google = _FakeGoogleIdentity();
    final apple = _FakeAppleIdentity();
    final sessions = await _signedInStore();

    final service = CardverseIdentityLinkService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: google,
      appleIdentity: apple,
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    final result = await service.linkGoogle();

    expect(result.provider, 'google');
    expect(cloud.requestedChallengeProvider, 'google');
    expect(google.clientId, '123.apps.googleusercontent.com');
    expect(google.nonce, 'server-link-nonce');
    expect(cloud.seenSessionToken, 'S' * 43);
    expect(cloud.seenProvider, 'google');
    expect(cloud.seenChallengeId, 'challenge-link-1');
    expect(cloud.seenIdToken, 'google.header.signature');
    expect(apple.calls, 0);
  });

  test('Apple link uses current session and exact server challenge nonce',
      () async {
    final cloud = _FakeLinkCloud()..challengeProvider = 'apple';
    final google = _FakeGoogleIdentity();
    final apple = _FakeAppleIdentity();
    final sessions = await _signedInStore();

    final service = CardverseIdentityLinkService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: google,
      appleIdentity: apple,
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    final result = await service.linkApple();

    expect(result.provider, 'apple');
    expect(cloud.requestedChallengeProvider, 'apple');
    expect(apple.nonce, 'server-link-nonce');
    expect(cloud.seenSessionToken, 'S' * 43);
    expect(cloud.seenProvider, 'apple');
    expect(cloud.seenIdToken, 'apple.header.signature');
    expect(google.calls, 0);
  });

  test('link fails before provider auth when no Cardverse session exists',
      () async {
    final cloud = _FakeLinkCloud();
    final google = _FakeGoogleIdentity();
    final service = CardverseIdentityLinkService(
      cloud: cloud,
      sessions: CardverseSessionStore(
        storage: _MemorySecureStore(),
      ),
      googleIdentity: google,
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.linkGoogle(),
      throwsA(
        isA<CardverseIdentityLinkException>().having(
          (error) => error.code,
          'code',
          'cardverse_link_session_missing',
        ),
      ),
    );
    expect(cloud.requestedChallengeProvider, isNull);
    expect(google.calls, 0);
  });

  test('challenge provider mismatch fails before identity provider call',
      () async {
    final cloud = _FakeLinkCloud()..challengeProvider = 'apple';
    final google = _FakeGoogleIdentity();
    final service = CardverseIdentityLinkService(
      cloud: cloud,
      sessions: await _signedInStore(),
      googleIdentity: google,
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.linkGoogle(),
      throwsA(
        isA<CardverseCloudException>().having(
          (error) => error.failure,
          'failure',
          CardverseCloudFailure.invalidResponse,
        ),
      ),
    );
    expect(google.calls, 0);
    expect(cloud.seenProvider, isNull);
  });

  test('401 during provider link clears stale local session', () async {
    final cloud = _FakeLinkCloud()
      ..linkError = const CardverseCloudException(
        failure: CardverseCloudFailure.unauthorized,
        statusCode: 401,
        serverCode: 'cardverse_session_invalid',
      );
    final sessions = await _signedInStore();
    final service = CardverseIdentityLinkService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: _FakeGoogleIdentity(),
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.linkGoogle(),
      throwsA(isA<CardverseCloudException>()),
    );
    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNull,
    );
  });

  test('409 identity ownership conflict preserves current local session',
      () async {
    final cloud = _FakeLinkCloud()
      ..linkError = const CardverseCloudException(
        failure: CardverseCloudFailure.conflict,
        statusCode: 409,
        serverCode: 'cardverse_identity_already_linked',
      );
    final sessions = await _signedInStore();
    final service = CardverseIdentityLinkService(
      cloud: cloud,
      sessions: sessions,
      googleIdentity: _FakeGoogleIdentity(),
      appleIdentity: _FakeAppleIdentity(),
      googleServerClientId: '123.apps.googleusercontent.com',
    );

    await expectLater(
      service.linkGoogle(),
      throwsA(
        isA<CardverseCloudException>()
            .having(
              (error) => error.failure,
              'failure',
              CardverseCloudFailure.conflict,
            )
            .having(
              (error) => error.serverCode,
              'serverCode',
              'cardverse_identity_already_linked',
            ),
      ),
    );
    expect(
      await sessions.load(now: DateTime.utc(2026, 9, 29)),
      isNotNull,
    );
  });
}
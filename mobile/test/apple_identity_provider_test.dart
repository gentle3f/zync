import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/apple_identity_provider.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('Apple identity is iOS-only in the Zync mobile contract', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = _FakeAppleIdentityClient();
    final provider = NativeAppleIdentityProvider(client: client);

    await expectLater(
      provider.authenticate(nonce: 'server-nonce'),
      throwsA(
        isA<AppleIdentityException>().having(
          (error) => error.code,
          'code',
          'apple_sign_in_platform_unsupported',
        ),
      ),
    );
    expect(client.calls, 0);
  });

  test('Apple identity forwards the exact Cardverse nonce', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final client = _FakeAppleIdentityClient();
    final provider = NativeAppleIdentityProvider(client: client);

    final credential = await provider.authenticate(
      nonce: 'server-issued-single-use-nonce',
    );

    expect(credential.idToken, 'header.payload.signature');
    expect(credential.authorizationCode, 'fresh-apple-authorization-code');
    expect(client.calls, 1);
    expect(client.nonce, 'server-issued-single-use-nonce');
  });

  test('Apple identity rejects an empty or oversized nonce before plugin use',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final client = _FakeAppleIdentityClient();
    final provider = NativeAppleIdentityProvider(client: client);

    await expectLater(
      provider.authenticate(nonce: ''),
      throwsA(
        isA<AppleIdentityException>().having(
          (error) => error.code,
          'code',
          'apple_sign_in_configuration_invalid',
        ),
      ),
    );
    await expectLater(
      provider.authenticate(nonce: 'x' * 513),
      throwsA(
        isA<AppleIdentityException>().having(
          (error) => error.code,
          'code',
          'apple_sign_in_configuration_invalid',
        ),
      ),
    );
    expect(client.calls, 0);
  });

  test('Apple identity rejects a malformed token returned by the plugin',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final client = _FakeAppleIdentityClient(idToken: 'not-a-jwt');
    final provider = NativeAppleIdentityProvider(client: client);

    await expectLater(
      provider.authenticate(nonce: 'server-nonce'),
      throwsA(
        isA<AppleIdentityException>().having(
          (error) => error.code,
          'code',
          'apple_sign_in_token_invalid',
        ),
      ),
    );
  });

  test('Apple identity rejects a missing authorization code', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final client = _FakeAppleIdentityClient(authorizationCode: '');
    final provider = NativeAppleIdentityProvider(client: client);

    await expectLater(
      provider.authenticate(nonce: 'server-nonce'),
      throwsA(
        isA<AppleIdentityException>().having(
          (error) => error.code,
          'code',
          'apple_sign_in_authorization_code_invalid',
        ),
      ),
    );
  });
}

class _FakeAppleIdentityClient implements AppleIdentityClient {
  _FakeAppleIdentityClient({
    this.idToken = 'header.payload.signature',
    this.authorizationCode = 'fresh-apple-authorization-code',
  });

  final String idToken;
  final String authorizationCode;
  int calls = 0;
  String? nonce;

  @override
  Future<AppleIdentityCredential> authenticate({
    required String nonce,
  }) async {
    calls += 1;
    this.nonce = nonce;
    return AppleIdentityCredential(
      idToken: idToken,
      authorizationCode: authorizationCode,
    );
  }
}
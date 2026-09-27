import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/google_identity_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('Google identity fails clearly on a non-mobile runtime', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    const provider = NativeGoogleIdentityProvider();

    await expectLater(
      provider.authenticate(
        serverClientId: '123.apps.googleusercontent.com',
        nonce: 'server-nonce',
      ),
      throwsA(
        isA<GoogleIdentityException>().having(
          (error) => error.code,
          'code',
          'google_sign_in_platform_unsupported',
        ),
      ),
    );
  });

  test('Google identity maps an absent Android MethodChannel bridge', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('zync/google_identity_test_missing_android');
    const provider = NativeGoogleIdentityProvider(channel: channel);

    expect(GoogleIdentityRuntime.nativeAndroidBridgeAvailable, isTrue);
    expect(GoogleIdentityRuntime.nativeMobileBridgeAvailable, isTrue);

    await expectLater(
      provider.authenticate(
        serverClientId: '123.apps.googleusercontent.com',
        nonce: 'server-nonce',
      ),
      throwsA(
        isA<GoogleIdentityException>().having(
          (error) => error.code,
          'code',
          'google_sign_in_native_bridge_missing',
        ),
      ),
    );
  });

  test('iOS provider binds app client, server client and challenge nonce',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final client = _FakeIosGoogleIdentityClient();
    final provider = NativeGoogleIdentityProvider(
      iosClient: client,
      iosClientId: 'ios-123.apps.googleusercontent.com',
    );

    final token = await provider.authenticate(
      serverClientId: 'server-456.apps.googleusercontent.com',
      nonce: 'server-one-time-nonce',
    );

    expect(token, 'header.payload.signature');
    expect(client.calls, 1);
    expect(client.clientId, 'ios-123.apps.googleusercontent.com');
    expect(client.serverClientId, 'server-456.apps.googleusercontent.com');
    expect(client.nonce, 'server-one-time-nonce');
  });

  test('iOS provider fails closed when dedicated iOS client id is absent',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final client = _FakeIosGoogleIdentityClient();
    final provider = NativeGoogleIdentityProvider(
      iosClient: client,
      iosClientId: '',
    );

    await expectLater(
      provider.authenticate(
        serverClientId: 'server-456.apps.googleusercontent.com',
        nonce: 'server-one-time-nonce',
      ),
      throwsA(
        isA<GoogleIdentityException>().having(
          (error) => error.code,
          'code',
          'google_sign_in_configuration_invalid',
        ),
      ),
    );
    expect(client.calls, 0);
  });

  test('Google identity rejects invalid native configuration before provider use',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final client = _FakeIosGoogleIdentityClient();
    final provider = NativeGoogleIdentityProvider(
      iosClient: client,
      iosClientId: 'ios-123.apps.googleusercontent.com',
    );

    await expectLater(
      provider.authenticate(
        serverClientId: 'not-a-google-client',
        nonce: '',
      ),
      throwsA(
        isA<GoogleIdentityException>().having(
          (error) => error.code,
          'code',
          'google_sign_in_configuration_invalid',
        ),
      ),
    );
    expect(client.calls, 0);
  });
}

class _FakeIosGoogleIdentityClient implements IosGoogleIdentityClient {
  int calls = 0;
  String? clientId;
  String? serverClientId;
  String? nonce;

  @override
  Future<String> authenticate({
    required String clientId,
    required String serverClientId,
    required String nonce,
  }) async {
    calls += 1;
    this.clientId = clientId;
    this.serverClientId = serverClientId;
    this.nonce = nonce;
    return 'header.payload.signature';
  }
}

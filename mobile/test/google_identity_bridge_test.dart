import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/google_identity_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('Google identity fails clearly on a non-Android runtime', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
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
    const channel = MethodChannel('zync/google_identity_test_missing');
    const provider = NativeGoogleIdentityProvider(channel: channel);

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
}

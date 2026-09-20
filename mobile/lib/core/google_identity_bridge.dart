import 'package:flutter/services.dart';

class GoogleIdentityException implements Exception {
  const GoogleIdentityException(this.code);

  final String code;
}

abstract interface class GoogleIdentityProvider {
  Future<String> authenticate({
    required String serverClientId,
    required String nonce,
  });
}

class NativeGoogleIdentityProvider implements GoogleIdentityProvider {
  const NativeGoogleIdentityProvider({
    MethodChannel channel = const MethodChannel('zync/google_identity'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<String> authenticate({
    required String serverClientId,
    required String nonce,
  }) async {
    final cleanClientId = serverClientId.trim();
    final cleanNonce = nonce.trim();
    if (!cleanClientId.endsWith('.apps.googleusercontent.com') ||
        cleanNonce.isEmpty ||
        cleanNonce.length > 512) {
      throw const GoogleIdentityException(
        'google_sign_in_configuration_invalid',
      );
    }

    try {
      final token = (await _channel.invokeMethod<String>(
        'authenticateGoogle',
        <String, Object>{
          'serverClientId': cleanClientId,
          'nonce': cleanNonce,
        },
      ))
          ?.trim();
      if (token == null || token.isEmpty || token.split('.').length != 3) {
        throw const GoogleIdentityException('google_sign_in_token_invalid');
      }
      return token;
    } on PlatformException catch (error) {
      throw GoogleIdentityException(
        error.code.trim().isEmpty ? 'google_sign_in_failed' : error.code.trim(),
      );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleIdentityException implements Exception {
  const AppleIdentityException(
    this.code, {
    this.detail = '',
  });

  final String code;
  final String detail;
}

abstract interface class AppleIdentityProvider {
  Future<String> authenticate({
    required String nonce,
  });
}

abstract interface class AppleIdentityClient {
  Future<String> authenticate({
    required String nonce,
  });
}

class PluginAppleIdentityClient implements AppleIdentityClient {
  const PluginAppleIdentityClient();

  @override
  Future<String> authenticate({
    required String nonce,
  }) async {
    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw const AppleIdentityException('apple_sign_in_unavailable');
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
        ],
        nonce: nonce,
      );
      final token = credential.identityToken?.trim();
      if (token == null || token.isEmpty || token.split('.').length != 3) {
        throw const AppleIdentityException('apple_sign_in_token_invalid');
      }
      return token;
    } on SignInWithAppleAuthorizationException catch (error) {
      final code = switch (error.code) {
        AuthorizationErrorCode.canceled => 'apple_sign_in_cancelled',
        AuthorizationErrorCode.notHandled ||
        AuthorizationErrorCode.notInteractive =>
          'apple_sign_in_unavailable',
        AuthorizationErrorCode.invalidResponse =>
          'apple_sign_in_token_invalid',
        _ => 'apple_sign_in_failed',
      };
      throw AppleIdentityException(
        code,
        detail: 'sign_in_with_apple:${error.code.name}',
      );
    } on SignInWithAppleNotSupportedException {
      throw const AppleIdentityException('apple_sign_in_unavailable');
    } on MissingPluginException {
      throw const AppleIdentityException('apple_sign_in_plugin_missing');
    } on AppleIdentityException {
      rethrow;
    } catch (error) {
      throw AppleIdentityException(
        'apple_sign_in_failed',
        detail: error.runtimeType.toString(),
      );
    }
  }
}

class AppleIdentityRuntime {
  const AppleIdentityRuntime._();

  static bool get nativeIosAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

class NativeAppleIdentityProvider implements AppleIdentityProvider {
  const NativeAppleIdentityProvider({
    AppleIdentityClient client = const PluginAppleIdentityClient(),
  }) : _client = client;

  final AppleIdentityClient _client;

  @override
  Future<String> authenticate({
    required String nonce,
  }) async {
    if (!AppleIdentityRuntime.nativeIosAvailable) {
      throw const AppleIdentityException(
        'apple_sign_in_platform_unsupported',
      );
    }

    final cleanNonce = nonce.trim();
    if (cleanNonce.isEmpty || cleanNonce.length > 512) {
      throw const AppleIdentityException(
        'apple_sign_in_configuration_invalid',
      );
    }

    final token = (await _client.authenticate(nonce: cleanNonce)).trim();
    if (token.isEmpty || token.split('.').length != 3) {
      throw const AppleIdentityException('apple_sign_in_token_invalid');
    }
    return token;
  }
}

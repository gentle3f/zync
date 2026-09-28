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

class AppleIdentityCredential {
  const AppleIdentityCredential({
    required this.idToken,
    required this.authorizationCode,
  });

  final String idToken;
  final String authorizationCode;
}

abstract interface class AppleIdentityProvider {
  Future<AppleIdentityCredential> authenticate({
    required String nonce,
  });
}

abstract interface class AppleIdentityClient {
  Future<AppleIdentityCredential> authenticate({
    required String nonce,
  });
}

class PluginAppleIdentityClient implements AppleIdentityClient {
  const PluginAppleIdentityClient();

  @override
  Future<AppleIdentityCredential> authenticate({
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
      final authorizationCode = credential.authorizationCode.trim();
      if (token == null || token.isEmpty || token.split('.').length != 3) {
        throw const AppleIdentityException('apple_sign_in_token_invalid');
      }
      if (authorizationCode.isEmpty || authorizationCode.length > 4096) {
        throw const AppleIdentityException(
          'apple_sign_in_authorization_code_invalid',
        );
      }
      return AppleIdentityCredential(
        idToken: token,
        authorizationCode: authorizationCode,
      );
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
  Future<AppleIdentityCredential> authenticate({
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

    final credential = await _client.authenticate(nonce: cleanNonce);
    final token = credential.idToken.trim();
    final authorizationCode = credential.authorizationCode.trim();
    if (token.isEmpty || token.split('.').length != 3) {
      throw const AppleIdentityException('apple_sign_in_token_invalid');
    }
    if (authorizationCode.isEmpty || authorizationCode.length > 4096) {
      throw const AppleIdentityException(
        'apple_sign_in_authorization_code_invalid',
      );
    }

    return AppleIdentityCredential(
      idToken: token,
      authorizationCode: authorizationCode,
    );
  }
}

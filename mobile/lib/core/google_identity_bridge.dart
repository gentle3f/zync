import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in_ios/google_sign_in_ios.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

class GoogleIdentityException implements Exception {
  const GoogleIdentityException(
    this.code, {
    this.detail = '',
  });

  final String code;
  final String detail;
}

abstract interface class GoogleIdentityProvider {
  Future<String> authenticate({
    required String serverClientId,
    required String nonce,
  });
}

abstract interface class IosGoogleIdentityClient {
  Future<String> authenticate({
    required String clientId,
    required String serverClientId,
    required String nonce,
  });
}

class PluginIosGoogleIdentityClient implements IosGoogleIdentityClient {
  const PluginIosGoogleIdentityClient();

  @override
  Future<String> authenticate({
    required String clientId,
    required String serverClientId,
    required String nonce,
  }) async {
    final plugin = GoogleSignInIOS();
    try {
      await plugin.init(
        InitParameters(
          clientId: clientId,
          serverClientId: serverClientId,
          nonce: nonce,
        ),
      );
      final auth = await plugin.authenticate(
        const AuthenticateParameters(),
      );
      final token = auth.authenticationTokens.idToken?.trim();
      if (token == null || token.isEmpty || token.split('.').length != 3) {
        throw const GoogleIdentityException('google_sign_in_token_invalid');
      }
      return token;
    } on GoogleSignInException catch (error) {
      final code = switch (error.code) {
        GoogleSignInExceptionCode.canceled => 'google_sign_in_cancelled',
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'google_sign_in_configuration_invalid',
        GoogleSignInExceptionCode.uiUnavailable =>
          'google_sign_in_native_bridge_missing',
        _ => 'google_sign_in_failed',
      };
      throw GoogleIdentityException(
        code,
        detail: 'google_sign_in_ios:${error.code.name}',
      );
    } on MissingPluginException {
      throw const GoogleIdentityException(
        'google_sign_in_native_bridge_missing',
      );
    } on PlatformException catch (error) {
      throw GoogleIdentityException(
        error.code.trim().isEmpty ? 'google_sign_in_failed' : error.code.trim(),
        detail: 'google_sign_in_ios:platform',
      );
    }
  }
}

class GoogleIdentityRuntime {
  const GoogleIdentityRuntime._();

  static const String iosClientId = String.fromEnvironment(
    'ZYNC_GOOGLE_IOS_CLIENT_ID',
  );

  static bool get nativeAndroidBridgeAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get nativeIosBridgeAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get iosClientConfigured =>
      iosClientId.trim().endsWith('.apps.googleusercontent.com');

  static bool get nativeMobileBridgeAvailable =>
      nativeAndroidBridgeAvailable || nativeIosBridgeAvailable;

  static bool get nativeGoogleLinkAvailable =>
      nativeAndroidBridgeAvailable ||
      (nativeIosBridgeAvailable && iosClientConfigured);

  static String get label {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}

class NativeGoogleIdentityProvider implements GoogleIdentityProvider {
  const NativeGoogleIdentityProvider({
    MethodChannel channel = const MethodChannel('zync/google_identity'),
    IosGoogleIdentityClient iosClient = const PluginIosGoogleIdentityClient(),
    String iosClientId = const String.fromEnvironment(
      'ZYNC_GOOGLE_IOS_CLIENT_ID',
    ),
  })  : _channel = channel,
        _iosClient = iosClient,
        _iosClientId = iosClientId;

  final MethodChannel _channel;
  final IosGoogleIdentityClient _iosClient;
  final String _iosClientId;

  @override
  Future<String> authenticate({
    required String serverClientId,
    required String nonce,
  }) async {
    if (!GoogleIdentityRuntime.nativeMobileBridgeAvailable) {
      throw const GoogleIdentityException(
        'google_sign_in_platform_unsupported',
      );
    }

    final cleanClientId = serverClientId.trim();
    final cleanNonce = nonce.trim();
    if (!cleanClientId.endsWith('.apps.googleusercontent.com') ||
        cleanNonce.isEmpty ||
        cleanNonce.length > 512) {
      throw const GoogleIdentityException(
        'google_sign_in_configuration_invalid',
      );
    }

    if (GoogleIdentityRuntime.nativeIosBridgeAvailable) {
      final cleanIosClientId = _iosClientId.trim();
      if (!cleanIosClientId.endsWith('.apps.googleusercontent.com')) {
        throw const GoogleIdentityException(
          'google_sign_in_configuration_invalid',
        );
      }
      return _iosClient.authenticate(
        clientId: cleanIosClientId,
        serverClientId: cleanClientId,
        nonce: cleanNonce,
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
    } on MissingPluginException {
      throw const GoogleIdentityException(
        'google_sign_in_native_bridge_missing',
      );
    } on PlatformException catch (error) {
      final details = error.details;
      String detail = '';
      if (details is Map) {
        const allowed = {
          'attempt',
          'exceptionType',
          'exceptionClass',
          'causeClass',
          'credentialType',
          'credentialSubtype',
          'credentialClass',
        };
        final parts = <String>[];
        for (final entry in details.entries) {
          final key = entry.key?.toString() ?? '';
          final value = entry.value?.toString() ?? '';
          if (allowed.contains(key) && value.isNotEmpty) {
            parts.add('$key=$value');
          }
        }
        detail = parts.join(', ');
      }
      throw GoogleIdentityException(
        error.code.trim().isEmpty ? 'google_sign_in_failed' : error.code.trim(),
        detail: detail,
      );
    }
  }
}

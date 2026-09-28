import 'apple_identity_provider.dart';
import 'cardverse_cloud_client.dart';
import 'cardverse_session_store.dart';
import 'google_identity_bridge.dart';

class CardverseAccountDeletionException implements Exception {
  const CardverseAccountDeletionException(this.code);

  final String code;
}

abstract interface class CardverseAccountDeletionController {
  Future<void> deleteWithGoogle();
  Future<void> deleteWithApple();
}

class CardverseAccountDeletionService
    implements CardverseAccountDeletionController {
  CardverseAccountDeletionService({
    required CardverseCloudClient cloud,
    required CardverseSessionStore sessions,
    required GoogleIdentityProvider googleIdentity,
    required AppleIdentityProvider appleIdentity,
    String googleServerClientId = const String.fromEnvironment(
      'ZYNC_GOOGLE_SERVER_CLIENT_ID',
    ),
  })  : _cloud = cloud,
        _sessions = sessions,
        _googleIdentity = googleIdentity,
        _appleIdentity = appleIdentity,
        _googleServerClientId = googleServerClientId.trim();

  final CardverseCloudClient _cloud;
  final CardverseSessionStore _sessions;
  final GoogleIdentityProvider _googleIdentity;
  final AppleIdentityProvider _appleIdentity;
  final String _googleServerClientId;

  bool get googleConfigured =>
      _googleServerClientId.endsWith('.apps.googleusercontent.com');

  Future<void> deleteWithGoogle() async {
    if (!googleConfigured) {
      throw const CardverseAccountDeletionException(
        'google_server_client_id_not_configured',
      );
    }

    final session = await _requireSession();
    final challenge = await _challengeFor('google');
    final idToken = await _googleIdentity.authenticate(
      serverClientId: _googleServerClientId,
      nonce: challenge.nonce,
    );

    await _delete(
      session: session,
      provider: 'google',
      challenge: challenge,
      idToken: idToken,
    );
  }

  Future<void> deleteWithApple() async {
    final session = await _requireSession();
    final challenge = await _challengeFor('apple');
    final credential = await _appleIdentity.authenticate(
      nonce: challenge.nonce,
    );

    await _delete(
      session: session,
      provider: 'apple',
      challenge: challenge,
      idToken: credential.idToken,
      authorizationCode: credential.authorizationCode,
    );
  }

  Future<CardverseSessionCredential> _requireSession() async {
    final session = await _sessions.load();
    if (session == null) {
      throw const CardverseAccountDeletionException(
        'cardverse_delete_session_missing',
      );
    }
    return session;
  }

  Future<CardverseAuthChallenge> _challengeFor(String provider) async {
    final challenge = await _cloud.createAuthChallenge(provider);
    if (challenge.provider != provider) {
      throw const CardverseCloudException(
        failure: CardverseCloudFailure.invalidResponse,
      );
    }
    return challenge;
  }

  Future<void> _delete({
    required CardverseSessionCredential session,
    required String provider,
    required CardverseAuthChallenge challenge,
    required String idToken,
    String? authorizationCode,
  }) async {
    try {
      await _cloud.deleteAccount(
        sessionToken: session.token,
        provider: provider,
        challengeId: challenge.challengeId,
        idToken: idToken,
        authorizationCode: authorizationCode,
      );
    } on CardverseCloudException catch (error) {
      if (error.failure == CardverseCloudFailure.unauthorized) {
        await _sessions.clear();
      }
      rethrow;
    }

    // The backend removes all account sessions on successful deletion. Remove
    // the local bearer credential only after the destructive transaction has
    // definitely completed.
    await _sessions.clear();
  }
}
import 'apple_identity_provider.dart';
import 'cardverse_cloud_client.dart';
import 'cardverse_session_store.dart';
import 'google_identity_bridge.dart';

class CardverseIdentityLinkException implements Exception {
  const CardverseIdentityLinkException(this.code);

  final String code;
}

class CardverseIdentityLinkService {
  CardverseIdentityLinkService({
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

  Future<CardverseProviderLinkResult> linkGoogle() async {
    if (!googleConfigured) {
      throw const CardverseIdentityLinkException(
        'google_server_client_id_not_configured',
      );
    }

    final session = await _requireSession();
    final challenge = await _challengeFor('google');
    final idToken = await _googleIdentity.authenticate(
      serverClientId: _googleServerClientId,
      nonce: challenge.nonce,
    );
    return _link(
      session: session,
      provider: 'google',
      challenge: challenge,
      idToken: idToken,
    );
  }

  Future<CardverseProviderLinkResult> linkApple() async {
    final session = await _requireSession();
    final challenge = await _challengeFor('apple');
    final idToken = await _appleIdentity.authenticate(
      nonce: challenge.nonce,
    );
    return _link(
      session: session,
      provider: 'apple',
      challenge: challenge,
      idToken: idToken,
    );
  }

  Future<CardverseSessionCredential> _requireSession() async {
    final session = await _sessions.load();
    if (session == null) {
      throw const CardverseIdentityLinkException(
        'cardverse_link_session_missing',
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

  Future<CardverseProviderLinkResult> _link({
    required CardverseSessionCredential session,
    required String provider,
    required CardverseAuthChallenge challenge,
    required String idToken,
  }) async {
    try {
      return await _cloud.linkProviderIdentity(
        sessionToken: session.token,
        provider: provider,
        challengeId: challenge.challengeId,
        idToken: idToken,
      );
    } on CardverseCloudException catch (error) {
      if (error.failure == CardverseCloudFailure.unauthorized) {
        await _sessions.clear();
      }
      rethrow;
    }
  }
}

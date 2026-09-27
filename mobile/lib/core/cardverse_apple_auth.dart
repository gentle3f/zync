import 'apple_identity_provider.dart';
import 'cardverse_cloud_client.dart';
import 'cardverse_proof_sync.dart';
import 'cardverse_session_store.dart';

class CardverseAppleSignInResult {
  const CardverseAppleSignInResult({
    required this.auth,
    required this.proofSync,
  });

  final CardverseAuthResult auth;
  final CardverseProofSyncResult? proofSync;
}

class CardverseAppleAuthService {
  CardverseAppleAuthService({
    required CardverseCloudClient cloud,
    required CardverseSessionStore sessions,
    required AppleIdentityProvider identity,
    required Future<CardverseProofSyncResult> Function() syncPendingProofs,
  })  : _cloud = cloud,
        _sessions = sessions,
        _identity = identity,
        _syncPendingProofs = syncPendingProofs;

  factory CardverseAppleAuthService.configured() {
    final cloud = CardverseCloudClient();
    final sessions = CardverseSessionStore();
    final proofSync = CardverseProofSync(
      cloud: cloud,
      sessions: sessions,
    );
    return CardverseAppleAuthService(
      cloud: cloud,
      sessions: sessions,
      identity: const NativeAppleIdentityProvider(),
      syncPendingProofs: proofSync.syncPending,
    );
  }

  final CardverseCloudClient _cloud;
  final CardverseSessionStore _sessions;
  final AppleIdentityProvider _identity;
  final Future<CardverseProofSyncResult> Function() _syncPendingProofs;

  Future<CardverseAppleSignInResult> signIn() async {
    final challenge = await _cloud.createAuthChallenge('apple');
    if (challenge.provider != 'apple') {
      throw const CardverseCloudException(
        failure: CardverseCloudFailure.invalidResponse,
      );
    }

    final idToken = await _identity.authenticate(
      nonce: challenge.nonce,
    );
    final auth = await _cloud.authenticateProvider(
      provider: 'apple',
      challengeId: challenge.challengeId,
      idToken: idToken,
    );
    if (auth.provider != 'apple') {
      throw const CardverseCloudException(
        failure: CardverseCloudFailure.invalidResponse,
      );
    }
    await _sessions.save(auth.session);

    CardverseProofSyncResult? proofSync;
    try {
      proofSync = await _syncPendingProofs();
    } catch (_) {
      // Login remains valid if pending-proof maintenance fails.
    }

    return CardverseAppleSignInResult(
      auth: auth,
      proofSync: proofSync,
    );
  }
}

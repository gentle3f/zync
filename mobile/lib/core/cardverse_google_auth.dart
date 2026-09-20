import 'cardverse_cloud_client.dart';
import 'cardverse_proof_sync.dart';
import 'cardverse_session_store.dart';
import 'google_identity_bridge.dart';

class CardverseGoogleAuthException implements Exception {
  const CardverseGoogleAuthException(this.code);

  final String code;
}

class CardverseGoogleSignInResult {
  const CardverseGoogleSignInResult({
    required this.auth,
    required this.proofSync,
  });

  final CardverseAuthResult auth;
  final CardverseProofSyncResult? proofSync;
}

class CardverseGoogleAuthService {
  CardverseGoogleAuthService({
    required CardverseCloudClient cloud,
    required CardverseSessionStore sessions,
    required GoogleIdentityProvider identity,
    required Future<CardverseProofSyncResult> Function() syncPendingProofs,
    String serverClientId = const String.fromEnvironment(
      'ZYNC_GOOGLE_SERVER_CLIENT_ID',
    ),
  })  : _cloud = cloud,
        _sessions = sessions,
        _identity = identity,
        _syncPendingProofs = syncPendingProofs,
        _serverClientId = serverClientId.trim();

  factory CardverseGoogleAuthService.configured() {
    final cloud = CardverseCloudClient();
    final sessions = CardverseSessionStore();
    final proofSync = CardverseProofSync(
      cloud: cloud,
      sessions: sessions,
    );
    return CardverseGoogleAuthService(
      cloud: cloud,
      sessions: sessions,
      identity: const NativeGoogleIdentityProvider(),
      syncPendingProofs: proofSync.syncPending,
    );
  }

  final CardverseCloudClient _cloud;
  final CardverseSessionStore _sessions;
  final GoogleIdentityProvider _identity;
  final Future<CardverseProofSyncResult> Function() _syncPendingProofs;
  final String _serverClientId;

  bool get configured =>
      _serverClientId.endsWith('.apps.googleusercontent.com');

  Future<CardverseGoogleSignInResult> signIn() async {
    if (!configured) {
      throw const CardverseGoogleAuthException(
        'google_server_client_id_not_configured',
      );
    }

    final challenge = await _cloud.createAuthChallenge('google');
    final idToken = await _identity.authenticate(
      serverClientId: _serverClientId,
      nonce: challenge.nonce,
    );
    final auth = await _cloud.authenticateProvider(
      provider: 'google',
      challengeId: challenge.challengeId,
      idToken: idToken,
    );
    await _sessions.save(auth.session);

    CardverseProofSyncResult? proofSync;
    try {
      proofSync = await _syncPendingProofs();
    } catch (_) {
      // A successful login must remain valid even if local proof-queue
      // maintenance fails. Pending proofs stay locally queued for a later sync.
    }

    return CardverseGoogleSignInResult(
      auth: auth,
      proofSync: proofSync,
    );
  }
}

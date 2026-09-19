import 'cardverse_cloud_client.dart';
import 'cardverse_proof_cache.dart';
import 'cardverse_session_store.dart';

class CardverseProofSyncResult {
  const CardverseProofSyncResult({
    required this.redeemed,
    required this.discarded,
    required this.remaining,
    required this.sessionCleared,
  });

  final int redeemed;
  final int discarded;
  final int remaining;
  final bool sessionCleared;
}

class CardverseProofSync {
  CardverseProofSync({
    required CardverseCloudClient cloud,
    required CardverseSessionStore sessions,
    CardverseProofCache? proofs,
  })  : _cloud = cloud,
        _sessions = sessions,
        _proofs = proofs ?? CardverseProofCache();

  final CardverseCloudClient _cloud;
  final CardverseSessionStore _sessions;
  final CardverseProofCache _proofs;

  Future<CardverseProofSyncResult> syncPending() async {
    final credential = await _sessions.load();
    final pending = await _proofs.loadTickets();
    if (credential == null || pending.isEmpty) {
      return CardverseProofSyncResult(
        redeemed: 0,
        discarded: 0,
        remaining: pending.length,
        sessionCleared: false,
      );
    }

    var redeemed = 0;
    var discarded = 0;
    var sessionCleared = false;

    for (final proof in pending) {
      try {
        await _cloud.redeemProof(
          sessionToken: credential.token,
          ticket: proof.ticket,
          clientEventId: proof.clientEventId,
          timezoneOffsetMinutes: proof.timezoneOffsetMinutes,
        );
        await _proofs.removeTicket(
          ticket: proof.ticket,
          clientEventId: proof.clientEventId,
        );
        redeemed += 1;
      } on CardverseCloudException catch (error) {
        if (error.failure == CardverseCloudFailure.unauthorized) {
          await _sessions.clear();
          sessionCleared = true;
          break;
        }

        final irrecoverable =
            error.serverCode == 'cardverse_proof_ticket_invalid' ||
            error.serverCode == 'cardverse_proof_ticket_expired' ||
            error.serverCode == 'cardverse_proof_ticket_already_redeemed';
        if (irrecoverable) {
          await _proofs.removeTicket(
            ticket: proof.ticket,
            clientEventId: proof.clientEventId,
          );
          discarded += 1;
          continue;
        }

        // Network failures, disabled server, and transient 5xx stay queued.
        break;
      }
    }

    final remaining = (await _proofs.loadTickets()).length;
    return CardverseProofSyncResult(
      redeemed: redeemed,
      discarded: discarded,
      remaining: remaining,
      sessionCleared: sessionCleared,
    );
  }
}

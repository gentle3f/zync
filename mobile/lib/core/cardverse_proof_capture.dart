import 'dart:async';

import 'cardverse_proof_cache.dart';
import 'relay_service.dart';

class CardverseRelayProofCapture {
  const CardverseRelayProofCapture._();

  static Future<void> saveHostTicket({
    required String? proofTicket,
    required String clientEventId,
    DateTime? capturedAt,
    int? timezoneOffsetMinutes,
    CardverseProofCache? cache,
  }) async {
    final ticket = proofTicket?.trim() ?? '';
    if (ticket.isEmpty) return;
    final localNow = capturedAt ?? DateTime.now();
    final offset =
        timezoneOffsetMinutes ?? localNow.timeZoneOffset.inMinutes;
    await (cache ?? CardverseProofCache()).saveTicket(
      PendingCardverseProofTicket(
        ticket: ticket,
        clientEventId: clientEventId,
        capturedAt: localNow.toUtc(),
        timezoneOffsetMinutes: offset,
      ),
    );
  }

  static Future<void> captureScanner({
    required RelayClient relay,
    required String sessionId,
    required String? proofCapability,
    required String clientEventId,
    int? timezoneOffsetMinutes,
    CardverseProofCache? cache,
    List<Duration> retryDelays = const [
      Duration.zero,
      Duration(milliseconds: 650),
      Duration(milliseconds: 1200),
      Duration(milliseconds: 2200),
    ],
  }) async {
    final capability = proofCapability?.trim() ?? '';
    if (capability.isEmpty) return;

    final proofCache = cache ?? CardverseProofCache();
    final localNow = DateTime.now();
    final capturedAt = localNow.toUtc();
    final offset =
        timezoneOffsetMinutes ?? localNow.timeZoneOffset.inMinutes;
    for (final delay in retryDelays) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      try {
        final result = await relay.proof(
          sessionId: sessionId,
          proofCapability: capability,
        );
        if (result.isReady && result.proofTicket != null) {
          await proofCache.saveTicket(
            PendingCardverseProofTicket(
              ticket: result.proofTicket!,
              clientEventId: clientEventId,
              capturedAt: capturedAt,
              timezoneOffsetMinutes: offset,
            ),
          );
          await proofCache.removeCapability(
            sessionId: sessionId,
            clientEventId: clientEventId,
          );
          return;
        }
      } on RelayException catch (error) {
        if (error.kind == RelayFailureKind.expired ||
            error.kind == RelayFailureKind.invalid) {
          await proofCache.removeCapability(
            sessionId: sessionId,
            clientEventId: clientEventId,
          );
          return;
        }
      }
    }

    await proofCache.saveCapability(
      PendingRelayProofCapability(
        sessionId: sessionId,
        proofCapability: capability,
        clientEventId: clientEventId,
        capturedAt: capturedAt,
        timezoneOffsetMinutes: offset,
      ),
    );
  }

  static Future<void> resumePending(
    RelayClient relay, {
    CardverseProofCache? cache,
  }) async {
    final proofCache = cache ?? CardverseProofCache();
    final pending = await proofCache.loadCapabilities();
    for (final item in pending) {
      unawaited(
        captureScanner(
          relay: relay,
          sessionId: item.sessionId,
          proofCapability: item.proofCapability,
          clientEventId: item.clientEventId,
          timezoneOffsetMinutes: item.timezoneOffsetMinutes,
          cache: proofCache,
          retryDelays: const [Duration.zero],
        ),
      );
    }
  }
}

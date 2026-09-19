import 'cardverse_models.dart';
import 'cardverse_reward_grant.dart';

enum CardversePackEntitlementKind {
  standard,
  discovery,
}

class CardverseUnopenedPackEntitlement {
  const CardverseUnopenedPackEntitlement._({
    required this.packId,
    required this.sourceGrantId,
    required this.kind,
    required this.issuedAt,
    required this.serverVersion,
  });

  final String packId;
  final String sourceGrantId;
  final CardversePackEntitlementKind kind;
  final DateTime issuedAt;
  final int serverVersion;

  factory CardverseUnopenedPackEntitlement.fromServerGrant({
    required CardverseRewardGrantReceipt grant,
    required String packId,
    required int serverVersion,
  }) {
    if (!grant.serverAuthoritative ||
        serverVersion < 1 ||
        !grant.unopenedPackIds.contains(packId)) {
      throw const FormatException(
        'Invalid unopened Cardverse pack entitlement',
      );
    }

    final kind = switch (grant.kind) {
      CardverseRewardGrantKind.standardPack =>
        CardversePackEntitlementKind.standard,
      CardverseRewardGrantKind.discoveryPack =>
        CardversePackEntitlementKind.discovery,
      CardverseRewardGrantKind.drawToken =>
        throw const FormatException(
          'Draw Token reward does not create a pack entitlement',
        ),
    };

    return CardverseUnopenedPackEntitlement._(
      packId: packId,
      sourceGrantId: grant.grantId,
      kind: kind,
      issuedAt: grant.issuedAt,
      serverVersion: serverVersion,
    );
  }

  CardversePackOpenRequest createOpenRequest({
    required String idempotencyKey,
    int clientRevealVersion = 1,
  }) {
    return CardversePackOpenRequest.fromJson({
      'packId': packId,
      'idempotencyKey': idempotencyKey,
      'clientRevealVersion': clientRevealVersion,
    });
  }

  bool acceptsReceipt({
    required CardversePackOpenRequest request,
    required CardversePackOpenReceipt receipt,
  }) {
    return receipt.serverAuthoritative &&
        request.packId == packId &&
        receipt.packId == packId &&
        receipt.idempotencyKey == request.idempotencyKey;
  }
}

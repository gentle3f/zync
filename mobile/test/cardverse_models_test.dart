import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_models.dart';

void main() {
  const baseVariant = CardVariantKey(
    interestId: 'sports.badminton',
    finishId: 'holo',
    editionId: 'core_set_1',
  );

  test('card visual identity depends on canonical ID and art version only', () {
    final first = CardVisualIdentity.seedFor(
      interestId: 'sports.badminton',
      artSystemVersion: 1,
    );
    final same = CardVisualIdentity.seedFor(
      interestId: 'sports.badminton',
      artSystemVersion: 1,
    );
    final nextVersion = CardVisualIdentity.seedFor(
      interestId: 'sports.badminton',
      artSystemVersion: 2,
    );

    expect(first, same);
    expect(first, isNot(nextVersion));
  });

  test('base interest definition contains no intrinsic rarity tier', () {
    final card = CardDefinition.fromInterest(
      interestId: 'sports.badminton',
      cardNumber: 47,
      artSystemVersion: 1,
      visualFamily: 'sports_racket',
    );
    const finish = CardFinishDefinition(
      id: 'holo',
      tier: CardFinishTier.holo,
      ownershipKind: CardOwnershipKind.stackable,
    );

    expect(card.interestId, 'sports.badminton');
    expect(card.visualFamily, 'sports_racket');
    expect(finish.tier, CardFinishTier.holo);
  });

  test('variant key round-trips independently from localized labels', () {
    final parsed = CardVariantKey.parse(baseVariant.value);

    expect(parsed, baseVariant);
    expect(parsed.value, 'sports.badminton::holo::core_set_1');
  });

  test('Encounter Starter and Achievement editions are soulbound', () {
    for (final edition in [
      CardverseTradabilityPolicy.encounterEdition(),
      CardverseTradabilityPolicy.starterEdition(),
      CardverseTradabilityPolicy.achievementEdition(),
    ]) {
      expect(
        CardverseTradabilityPolicy.canTrade(edition: edition),
        isFalse,
      );
    }
  });

  test('ordinary Core edition is tradable', () {
    final edition = CardverseTradabilityPolicy.coreEdition();

    expect(
      CardverseTradabilityPolicy.canTrade(edition: edition),
      isTrue,
    );
  });

  test('locked unique instance cannot be traded even in Core edition', () {
    final instance = CardInstance.validated(
      instanceId: 'instance-1',
      ownerAccountId: 'account-a',
      variant: baseVariant,
      acquiredAt: DateTime.utc(2026, 9, 19),
      acquisitionSource: CardAcquisitionSource.pack,
      locked: true,
    );

    expect(
      CardverseTradabilityPolicy.canTrade(
        edition: CardverseTradabilityPolicy.coreEdition(),
        instance: instance,
      ),
      isFalse,
    );
  });

  test('stackable balance reserves quantity against double-spend', () {
    final balance = StackableCardBalance.validated(
      accountId: 'account-a',
      variant: baseVariant,
      quantity: 4,
      lockedQuantity: 2,
      version: 7,
    );

    expect(balance.availableQuantity, 2);
    expect(
      () => StackableCardBalance.validated(
        accountId: 'account-a',
        variant: baseVariant,
        quantity: 1,
        lockedQuantity: 2,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('Google and Apple identities link to one internal account', () {
    final account = CardverseAccount(
      accountId: 'internal-zync-account-uuid',
      identityLinks: [
        CardverseIdentityLink(
          provider: CardverseIdentityProvider.google,
          providerSubject: 'google-subject',
          linkedAt: DateTime.utc(2026, 9, 19),
        ),
        CardverseIdentityLink(
          provider: CardverseIdentityProvider.apple,
          providerSubject: 'apple-subject',
          linkedAt: DateTime.utc(2026, 9, 20),
        ),
      ],
    );

    expect(account.identityLinks, hasLength(2));
    expect(account.accountId, isNot('google-subject'));
    expect(account.accountId, isNot('apple-subject'));
  });

  test('pack-open request accepts idempotency but never client RNG controls', () {
    final request = CardversePackOpenRequest.fromJson(const {
      'packId': 'pack-123',
      'idempotencyKey': 'open-attempt-abc',
      'clientRevealVersion': 1,
    });

    expect(request.packId, 'pack-123');
    expect(request.toJson().containsKey('seed'), isFalse);
    expect(request.toJson().containsKey('result'), isFalse);

    expect(
      () => CardversePackOpenRequest.fromJson(const {
        'packId': 'pack-123',
        'idempotencyKey': 'open-attempt-abc',
        'clientRevealVersion': 1,
        'seed': 'let-client-reroll',
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => CardversePackOpenRequest.fromJson(const {
        'packId': 'pack-123',
        'idempotencyKey': 'open-attempt-abc',
        'clientRevealVersion': 1,
        'cards': ['legendary'],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('pack receipt requires a server roll ID and immutable result items', () {
    final receipt = CardversePackOpenReceipt.serverValidated(
      packId: 'pack-123',
      serverRollId: 'roll-server-1',
      idempotencyKey: 'open-attempt-abc',
      rolledAt: DateTime.utc(2026, 9, 19, 10),
      items: const [
        CardversePackResultItem(
          variant: baseVariant,
          quantity: 1,
        ),
      ],
    );

    expect(receipt.serverAuthoritative, isTrue);
    expect(receipt.items, hasLength(1));

    expect(
      () => CardversePackOpenReceipt.serverValidated(
        packId: 'pack-123',
        serverRollId: '',
        idempotencyKey: 'open-attempt-abc',
        rolledAt: DateTime.utc(2026, 9, 19, 10),
        items: const [
          CardversePackResultItem(
            variant: baseVariant,
            quantity: 1,
          ),
        ],
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

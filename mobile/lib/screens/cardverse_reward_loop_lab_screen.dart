import 'package:flutter/material.dart';

import '../core/cardverse_models.dart';
import '../core/cardverse_pack_entitlement.dart';
import '../core/cardverse_reward_grant.dart';
import '../core/progress_event.dart';
import '../core/quest_engine.dart';
import '../ui/zync_design.dart';
import 'cardverse_pack_opening_lab_screen.dart';

class CardverseRewardLoopLabScreen extends StatefulWidget {
  const CardverseRewardLoopLabScreen({super.key});

  @override
  State<CardverseRewardLoopLabScreen> createState() =>
      _CardverseRewardLoopLabScreenState();
}

class _CardverseRewardLoopLabScreenState
    extends State<CardverseRewardLoopLabScreen> {
  late final ZyncQuestRewardEligibility _eligibility = _proofEligibility();
  late final CardverseQuestRewardClaimRequest _claim =
      CardverseQuestRewardClaimRequest.fromEligibility(
        eligibility: _eligibility,
        idempotencyKey: 'lab-quest-claim-1',
      );

  CardverseRewardGrantReceipt? _grant;
  CardverseUnopenedPackEntitlement? _entitlement;
  CardversePackOpenReceipt? _packReceipt;

  bool get _isZh =>
      Localizations.localeOf(context).toLanguageTag().toLowerCase().startsWith(
            'zh',
          );

  static ZyncQuestRewardEligibility _proofEligibility() {
    final snapshot = ZyncQuestEngine.evaluate(
      events: [
        ZyncProgressEvent(
          id: 'lab-event-1',
          type: ZyncProgressEventType.oneToOneZync,
          source: ZyncProgressSource.oneToOne,
          occurredAt: DateTime.utc(2026, 9, 18, 3),
          participantCount: 2,
          interestCategories: const ['sports'],
        ),
        ZyncProgressEvent(
          id: 'lab-event-2',
          type: ZyncProgressEventType.oneToOneZync,
          source: ZyncProgressSource.oneToOne,
          occurredAt: DateTime.utc(2026, 9, 18, 10),
          participantCount: 2,
          interestCategories: const ['food'],
        ),
        ZyncProgressEvent(
          id: 'lab-event-3',
          type: ZyncProgressEventType.triedTogetherCompleted,
          source: ZyncProgressSource.zyncNow,
          occurredAt: DateTime.utc(2026, 9, 19, 10),
          participantCount: 3,
          interestCategories: const ['music'],
        ),
      ],
      now: DateTime.utc(2026, 9, 19, 12),
      timezoneOffset: const Duration(hours: 8),
    );

    return snapshot.progress
        .firstWhere(
          (item) => item.definition.id == 'weekly_real_world_three',
        )
        .eligibility!;
  }

  void _simulateServerGrant() {
    final grant = CardverseRewardGrantReceipt.serverValidated(
      grantId: 'lab-server-grant-1',
      eligibilityKey: _eligibility.key,
      questId: _eligibility.questId,
      idempotencyKey: _claim.idempotencyKey,
      kind: CardverseRewardGrantKind.standardPack,
      amount: 1,
      issuedAt: DateTime.utc(2026, 9, 19, 12, 5),
      serverSequence: 9001,
      unopenedPackIds: const ['lab-server-pack-1'],
    );

    final entitlement =
        CardverseUnopenedPackEntitlement.fromServerGrant(
      grant: grant,
      packId: grant.unopenedPackIds.single,
      serverVersion: 1,
    );

    final openRequest = entitlement.createOpenRequest(
      idempotencyKey: 'lab-pack-open-1',
    );

    final receipt = CardversePackOpenReceipt.serverValidated(
      packId: entitlement.packId,
      serverRollId: 'lab-server-roll-1',
      idempotencyKey: openRequest.idempotencyKey,
      rolledAt: DateTime.utc(2026, 9, 19, 12, 6),
      items: const [
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'sports.badminton',
            finishId: 'normal',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'food.sushi',
            finishId: 'foil',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'technology.ai',
            finishId: 'holo',
            editionId: 'discovery',
          ),
          quantity: 1,
        ),
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'music.piano',
            finishId: 'prism',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
        CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'travel.japan',
            finishId: 'legendary',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
      ],
    );

    if (!grant.matchesEligibility(_eligibility) ||
        !entitlement.acceptsReceipt(
          request: openRequest,
          receipt: receipt,
        )) {
      throw StateError('Reward Loop Lab contract mismatch');
    }

    setState(() {
      _grant = grant;
      _entitlement = entitlement;
      _packReceipt = receipt;
    });
  }

  Future<void> _openPack() async {
    final receipt = _packReceipt;
    if (receipt == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardversePackOpeningLabScreen(
          receipt: receipt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 2),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Cardverse Reward Loop Lab',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const _MockServerBadge(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('reward-loop-lab'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  children: [
                    ZyncSurface(
                      backgroundColor: const Color(0xFFFFF7F2),
                      borderColor: ZyncPalette.peach,
                      child: Text(
                        _isZh
                            ? '只驗證完整Cardverse loop。Server grant同pack receipt係mock；正式Quest Board仍然冇Claim掣。'
                            : 'Validates the full Cardverse loop only. Server grants and pack receipts are mocked; the real Quest Board still has no Claim button.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _step(
                      1,
                      _isZh ? '真實世界行動完成' : 'Real-world actions completed',
                      _isZh
                          ? '2次 1:1 Zync + 1次 Tried Together'
                          : '2 one-to-one Zyncs + 1 Tried Together',
                      true,
                    ),
                    _connector(),
                    _step(
                      2,
                      _isZh ? 'Quest只產生Eligibility' : 'Quest creates eligibility only',
                      'weekly_real_world_three · 3 / 3',
                      true,
                    ),
                    const SizedBox(height: 10),
                    _claimCard(),
                    const SizedBox(height: 16),
                    _connector(),
                    _step(
                      3,
                      _isZh ? 'Server重新驗證同發獎' : 'Server revalidates and grants',
                      _grant == null
                          ? (_isZh
                              ? '未執行 mock server validation'
                              : 'Mock server validation not run')
                          : 'grantId: ${_grant!.grantId}',
                      _grant != null,
                    ),
                    const SizedBox(height: 12),
                    if (_grant == null)
                      FilledButton.icon(
                        key: const ValueKey('reward-loop-simulate-server'),
                        onPressed: _simulateServerGrant,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(
                          _isZh ? '模擬Server驗證' : 'Simulate server validation',
                        ),
                      )
                    else
                      _grantCard(),
                    const SizedBox(height: 16),
                    _connector(),
                    _step(
                      4,
                      _isZh ? '得到未開卡包' : 'Receive unopened pack',
                      _entitlement == null
                          ? (_isZh ? '未有pack entitlement' : 'No pack entitlement yet')
                          : 'packId: ${_entitlement!.packId}',
                      _entitlement != null,
                    ),
                    if (_packReceipt != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('reward-loop-open-pack'),
                        onPressed: _openPack,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _isZh
                              ? '進入Receipt-driven開包'
                              : 'Open receipt-driven pack',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _connector(),
                    _step(
                      5,
                      'Reveal → Collection',
                      _isZh
                          ? '動畫只揭曉已commit結果；真正雲端inventory由server ledger更新。'
                          : 'Animation only reveals committed results; real cloud inventory is updated by the server ledger.',
                      false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _claimCard() => ZyncSurface(
        shadow: false,
        backgroundColor: const Color(0xFFF1EEFF),
        borderColor: const Color(0xFFE0D9FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isZh ? 'Client Claim' : 'Client claim payload',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _row('questId', _claim.questId),
            _row(
              'proofEventIds',
              '${_claim.proofEventIds.length} bounded IDs',
            ),
            _row('idempotency', _claim.idempotencyKey),
            const SizedBox(height: 8),
            Text(
              _isZh
                  ? '冇 rewardKind、amount、packId、cards、finish。'
                  : 'No rewardKind, amount, packId, cards or finish.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF176B57),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );

  Widget _grantCard() => ZyncSurface(
        shadow: false,
        backgroundColor: const Color(0xFFE8F8F1),
        borderColor: const Color(0xFFBDECDD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('kind', _grant!.kind.name),
            _row('amount', '${_grant!.amount}'),
            _row('unopenedPackId', _grant!.unopenedPackIds.single),
            _row('serverSequence', '${_grant!.serverSequence}'),
          ],
        ),
      );

  Widget _step(
    int number,
    String title,
    String subtitle,
    bool complete,
  ) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZyncIconTile(
            icon: complete ? Icons.check_rounded : Icons.circle_outlined,
            size: 42,
            backgroundColor:
                complete ? ZyncPalette.mint : const Color(0xFFE9E5FF),
            foregroundColor:
                complete ? const Color(0xFF176B57) : ZyncPalette.plum,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _connector() => Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Container(
          width: 2,
          height: 18,
          color: const Color(0xFFD9D2E5),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
}

class _MockServerBadge extends StatelessWidget {
  const _MockServerBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9B7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'MOCK SERVER',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF7A5200),
                fontWeight: FontWeight.w900,
              ),
        ),
      );
}

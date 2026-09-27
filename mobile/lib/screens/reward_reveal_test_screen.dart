import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/cardverse_models.dart';
import '../screens/cardverse_pack_opening_lab_screen.dart';
import '../ui/zync_design.dart';
import '../widgets/cardverse_single_draw_reveal.dart';

class RewardRevealTestScreen extends StatelessWidget {
  const RewardRevealTestScreen({super.key});

  static CardverseSingleDrawReceipt proofSingleDrawReceipt() =>
      CardverseSingleDrawReceipt.serverValidated(
        drawId: 'reward-lab-single-draw-1',
        idempotencyKey: 'reward-lab-single-draw-idempotency-1',
        rolledAt: DateTime.utc(2026, 9, 27, 12),
        item: const CardversePackResultItem(
          variant: CardVariantKey(
            interestId: 'technology.ai',
            finishId: 'holo',
            editionId: 'core_set_1',
          ),
          quantity: 1,
        ),
      );

  static CardversePackOpenReceipt proofPackReceipt() =>
      CardversePackOpenReceipt.serverValidated(
        packId: 'reward-lab-pack-1',
        serverRollId: 'reward-lab-pack-roll-1',
        idempotencyKey: 'reward-lab-pack-idempotency-1',
        rolledAt: DateTime.utc(2026, 9, 27, 12, 5),
        items: const [
          CardversePackResultItem(
            variant: CardVariantKey(
              interestId: 'books.reading',
              finishId: 'normal',
              editionId: 'core_set_1',
            ),
            quantity: 1,
          ),
          CardversePackResultItem(
            variant: CardVariantKey(
              interestId: 'food.coffee',
              finishId: 'foil',
              editionId: 'core_set_1',
            ),
            quantity: 1,
          ),
          CardversePackResultItem(
            variant: CardVariantKey(
              interestId: 'technology.ai',
              finishId: 'holo',
              editionId: 'core_set_1',
            ),
            quantity: 1,
          ),
          CardversePackResultItem(
            variant: CardVariantKey(
              interestId: 'books.reading',
              finishId: 'prism',
              editionId: 'discovery',
            ),
            quantity: 1,
          ),
          CardversePackResultItem(
            variant: CardVariantKey(
              interestId: 'food.coffee',
              finishId: 'legendary',
              editionId: 'core_set_1',
            ),
            quantity: 1,
          ),
        ],
      );

  bool get _apiConfigured =>
      const String.fromEnvironment('ZYNC_API_BASE').trim().isNotEmpty;

  bool get _googleClientConfigured => const String.fromEnvironment(
        'ZYNC_GOOGLE_SERVER_CLIENT_ID',
      )
          .trim()
          .endsWith('.apps.googleusercontent.com');

  String get _platformLabel {
    if (kIsWeb) return 'Web / Chrome';
    return defaultTargetPlatform.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            children: [
              Text(
                'Reward Reveal Test',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Local proof receipts only. No account, token, pack inventory, '
                'backend RNG or economy mutation is required.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: ZyncPalette.inkSoft),
              ),
              const SizedBox(height: 20),
              _FlowCard(
                key: const ValueKey('reward-lab-single-draw-card'),
                icon: Icons.style_rounded,
                title: 'Single Draw — 1 Card',
                subtitle:
                    'No booster wrapper. One card back → Reveal → suspense → '
                    'flip → bloom → rarity payoff → real card front.',
                buttonLabel: 'Test Single Draw',
                onPressed: () => showCardverseSingleDrawReveal(
                  context: context,
                  receipt: proofSingleDrawReceipt(),
                  locale: 'en',
                ),
              ),
              const SizedBox(height: 14),
              _FlowCard(
                key: const ValueKey('reward-lab-pack-opening-card'),
                icon: Icons.inventory_2_outlined,
                title: 'Pack Opening — 5 Cards',
                subtitle:
                    'B — Split Open. See a layered stack through the first split, '
                    'extract the full stack, reveal 5 cards one by one, then recap.',
                buttonLabel: 'Test 5-Card Pack',
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => CardversePackOpeningLabScreen(
                      receipt: proofPackReceipt(),
                      labMode: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ZyncSurface(
                key: const ValueKey('reward-lab-google-diagnostics'),
                shadow: false,
                borderColor: const Color(0xFFE0D9FF),
                backgroundColor: const Color(0xFFF7F5FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google link diagnostics',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _DiagnosticRow(label: 'Runtime', value: _platformLabel),
                    _DiagnosticRow(
                      label: 'ZYNC_API_BASE',
                      value: _apiConfigured ? 'configured' : 'not configured',
                    ),
                    _DiagnosticRow(
                      label: 'Google Web client ID',
                      value:
                          _googleClientConfigured ? 'configured' : 'not configured',
                    ),
                    _DiagnosticRow(
                      label: 'Identity bridge',
                      value: kIsWeb
                          ? 'Android-native only in this build'
                          : 'Generated Android wrapper required',
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Chrome can test both reward reveal flows above without '
                        'Google. Account linking is intentionally diagnosed '
                        'separately because this build has no web Google identity '
                        'implementation.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: ZyncPalette.inkSoft),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ZyncSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ZyncIconTile(
                icon: icon,
                size: 48,
                backgroundColor: const Color(0xFFF1EEFF),
                foregroundColor: ZyncPalette.plum,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: ZyncPalette.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

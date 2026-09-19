import 'package:flutter/material.dart';

import '../core/cardverse_models.dart';
import '../core/cardverse_pack_reveal.dart';
import '../core/interest_catalog.dart';
import '../ui/zync_design.dart';
import '../widgets/zync_card_preview.dart';

class CardversePackOpeningLabScreen extends StatefulWidget {
  const CardversePackOpeningLabScreen({
    super.key,
    this.receipt,
    this.initialRevealedCount = 0,
  });

  final CardversePackOpenReceipt? receipt;
  final int initialRevealedCount;

  static CardversePackOpenReceipt proofReceipt() =>
      CardversePackOpenReceipt.serverValidated(
        packId: 'proof-standard-pack-1',
        serverRollId: 'proof-server-roll-1',
        idempotencyKey: 'proof-open-attempt-1',
        rolledAt: DateTime.utc(2026, 9, 19, 16),
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
              interestId: 'food.coffee',
              finishId: 'foil',
              editionId: 'core_set_1',
            ),
            quantity: 1,
          ),
          CardversePackResultItem(
            variant: CardVariantKey(
              interestId: 'outdoors.bouldering',
              finishId: 'holo',
              editionId: 'core_set_1',
            ),
            quantity: 1,
          ),
          CardversePackResultItem(
            variant: CardVariantKey(
              interestId: 'music.piano',
              finishId: 'prism',
              editionId: 'discovery',
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

  @override
  State<CardversePackOpeningLabScreen> createState() =>
      _CardversePackOpeningLabScreenState();
}

class _CardversePackOpeningLabScreenState
    extends State<CardversePackOpeningLabScreen> {
  late final CardversePackRevealPlan _plan;
  late CardversePackRevealCursor _cursor;

  late bool _started;
  late bool _showRecap;
  bool _revealing = false;

  String get _locale => Localizations.localeOf(context).toLanguageTag();
  bool get _isZh => _locale.toLowerCase().startsWith('zh');

  @override
  void initState() {
    super.initState();
    _plan = CardversePackRevealPlan.fromReceipt(
      widget.receipt ?? CardversePackOpeningLabScreen.proofReceipt(),
    );
    _cursor = _plan.cursor(
      revealedCount: widget.initialRevealedCount,
    );
    _started = widget.initialRevealedCount > 0;
    _showRecap = _cursor.complete;
  }

  Future<void> _revealNext() async {
    final next = _cursor.nextItem;
    if (next == null || _revealing) return;

    setState(() => _revealing = true);

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final delay = CardverseRevealTiming.suspenseFor(
      next.finish,
      reduceMotion: reduceMotion,
    );

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (!mounted) return;
    setState(() {
      _cursor = _cursor.revealNext();
      _revealing = false;
    });
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
                        'Cardverse Pack Lab',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _ReceiptBadge(
                      rollId: _plan.serverRollId,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: !_started
                      ? _sealedPack()
                      : _showRecap
                          ? _recap()
                          : _revealStage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sealedPack() => ListView(
        key: const ValueKey('pack-lab-sealed'),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 34),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: 5 / 7,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF332A52),
                        Color(0xFF725B9D),
                        Color(0xFF264E5F),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const _PackCoverPattern(),
                      Padding(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          children: [
                            const Spacer(),
                            const ZyncMark(
                              size: 82,
                              strokeWidth: 7,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'ZYNC',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isZh ? '探索卡包' : 'DISCOVERY PACK',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.84),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.24),
                                ),
                              ),
                              child: Text(
                                _isZh
                                    ? '5 張 · 結果已由 server 鎖定'
                                    : '5 cards · server result locked',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            key: const ValueKey('pack-lab-open'),
            onPressed: () => setState(() => _started = true),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(_isZh ? '打開卡包' : 'Open Pack'),
          ),
          const SizedBox(height: 12),
          Text(
            _isZh
                ? 'Lab只驗開包UX。5張結果已存在receipt，動畫唔會改卡、finish或者次序。'
                : 'This lab validates reveal UX only. All 5 cards already exist in the receipt; animation cannot change the cards, finishes or order.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ZyncPalette.inkSoft,
                ),
          ),
        ],
      );

  Widget _revealStage() {
    final revealedCount = _cursor.revealedCount;
    final last = revealedCount == 0
        ? null
        : _plan.items[revealedCount - 1];
    final next = _cursor.nextItem;

    return ListView(
      key: ValueKey('pack-lab-reveal-$revealedCount'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        _progressHeader(),
        const SizedBox(height: 22),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: last == null
                ? _faceDownCard(
                    index: 1,
                  )
                : ZyncCardPreview(
                    key: ValueKey(
                      'pack-revealed-card-${last.variant.interestId}',
                    ),
                    recipe: last.recipe,
                    title: InterestCatalog.byId(
                      last.variant.interestId,
                    )!
                        .labelFor(_locale),
                    subtitle: _finishLabel(last.finish),
                    finish: last.finish,
                    editionLabel: last.editionLabel,
                    cardNumberLabel:
                        '$revealedCount / ${_plan.items.length}',
                    animateFinish: last.focusAnimationRecommended,
                  ),
          ),
        ),
        const SizedBox(height: 22),
        if (_revealing) ...[
          Center(
            child: Column(
              children: [
                const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                const SizedBox(height: 10),
                Text(
                  _isZh ? '揭曉中…' : 'Revealing…',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ] else if (_cursor.complete) ...[
          FilledButton.icon(
            key: const ValueKey('pack-lab-recap-button'),
            onPressed: () => setState(() => _showRecap = true),
            icon: const Icon(Icons.grid_view_rounded),
            label: Text(_isZh ? '睇今次卡包' : 'See Pack Recap'),
          ),
        ] else ...[
          FilledButton.icon(
            key: const ValueKey('pack-lab-reveal-next'),
            onPressed: _revealNext,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(
              revealedCount == 0
                  ? (_isZh ? '揭曉第 1 張' : 'Reveal card 1')
                  : (_isZh
                      ? '揭曉第 ${revealedCount + 1} 張'
                      : 'Reveal card ${revealedCount + 1}'),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 9),
            Text(
              _isZh
                  ? '下一張仍然係已鎖定receipt入面第 ${revealedCount + 1} 張。'
                  : 'The next reveal is still card ${revealedCount + 1} from the locked receipt.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ZyncPalette.inkSoft,
                  ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _progressHeader() => Column(
        children: [
          Row(
            children: [
              Text(
                _isZh ? '開包進度' : 'Pack progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${_cursor.revealedCount} / ${_plan.items.length}',
                key: const ValueKey('pack-lab-progress-label'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < _plan.items.length; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 7,
                    decoration: BoxDecoration(
                      color: i < _cursor.revealedCount
                          ? ZyncPalette.plum
                          : const Color(0xFFE3DFE8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (i != _plan.items.length - 1)
                  const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      );

  Widget _faceDownCard({required int index}) => AspectRatio(
        aspectRatio: 5 / 7,
        child: Container(
          key: ValueKey('pack-face-down-$index'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2F294A),
                Color(0xFF5C4A7B),
                Color(0xFF244B59),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.62),
              width: 2,
            ),
          ),
          child: const Center(
            child: ZyncMark(
              size: 92,
              strokeWidth: 7,
            ),
          ),
        ),
      );

  Widget _recap() => ListView(
        key: const ValueKey('pack-lab-recap'),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
        children: [
          const Center(
            child: ZyncIconTile(
              icon: Icons.celebration_outlined,
              size: 68,
              backgroundColor: ZyncPalette.mint,
              foregroundColor: Color(0xFF176B57),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isZh ? '卡包完成' : 'Pack complete',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            _isZh
                ? '呢5張全部來自同一個 server receipt。'
                : 'All 5 cards came from the same server receipt.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GridView.builder(
            key: const ValueKey('pack-lab-recap-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _plan.items.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 5 / 7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final item = _plan.items[index];
              return ZyncCardPreview(
                key: ValueKey(
                  'pack-recap-card-${item.variant.interestId}',
                ),
                recipe: item.recipe,
                title: InterestCatalog.byId(
                  item.variant.interestId,
                )!
                    .labelFor(_locale),
                subtitle: _finishLabel(item.finish),
                finish: item.finish,
                editionLabel: item.editionLabel,
                cardNumberLabel: '${index + 1} / ${_plan.items.length}',
              );
            },
          ),
          const SizedBox(height: 18),
          ZyncSurface(
            shadow: false,
            backgroundColor: const Color(0xFFF1EEFF),
            borderColor: const Color(0xFFE0D9FF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: ZyncPalette.plum,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'serverRollId: ${_plan.serverRollId}',
                    key: const ValueKey('pack-lab-server-roll-id'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  String _finishLabel(CardFinishTier finish) => switch (finish) {
        CardFinishTier.normal => 'Normal',
        CardFinishTier.foil => 'Foil',
        CardFinishTier.holo => 'Holo',
        CardFinishTier.prism => 'Prism',
        CardFinishTier.legendary => 'Legendary',
        CardFinishTier.secret => 'Secret',
      };
}

class _ReceiptBadge extends StatelessWidget {
  const _ReceiptBadge({required this.rollId});

  final String rollId;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: rollId,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'RECEIPT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF176B57),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      );
}

class _PackCoverPattern extends StatelessWidget {
  const _PackCoverPattern();

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _PackCoverPainter(),
      );
}

class _PackCoverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final gap = size.width / 5;
    for (var x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        line,
      );
    }

    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.50, size.height * 0.42),
        size.width * (0.18 + i * 0.10),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PackCoverPainter oldDelegate) => false;
}

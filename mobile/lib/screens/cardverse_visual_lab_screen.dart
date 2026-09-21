import 'package:flutter/material.dart';

import '../core/card_visual_recipe.dart';
import '../core/cardverse_models.dart';
import '../core/interest_catalog.dart';
import '../ui/zync_design.dart';
import '../widgets/zync_card_preview.dart';

class CardverseVisualLabScreen extends StatelessWidget {
  const CardverseVisualLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final recipes = CardVisualRecipeResolver.expandedProofBatch();

    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            key: const ValueKey('cardverse-visual-lab'),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: const Text('Cardverse Visual Lab'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                sliver: SliverToBoxAdapter(
                  child: ZyncSurface(
                    shadow: false,
                    backgroundColor: const Color(0xFFF1EEFF),
                    borderColor: const Color(0xFFE0D9FF),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ZyncIconTile(
                          icon: Icons.auto_awesome_rounded,
                          backgroundColor: Color(0xFFE9E5FF),
                          foregroundColor: ZyncPalette.plum,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _copy(
                              locale,
                              en:
                                  '50-card art-direction review batch. Grid cards stay static for performance; tap one to inspect finish motion and visual identity.',
                              zhHant:
                                  '50 張卡美術方向審閱批次。Grid 保持靜態慳效能；撳一張可以檢查閃卡動態同視覺辨識度。',
                              zhHans:
                                  '50 张卡美术方向审阅批次。网格保持静态节省性能；点一张可以检查闪卡动态和视觉辨识度。',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final columns = width >= 1050
                        ? 5
                        : width >= 760
                            ? 4
                            : width >= 520
                                ? 3
                                : 2;

                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final recipe = recipes[index];
                          final interest =
                              InterestCatalog.byId(recipe.interestId)!;
                          final finish =
                              _proofFinishForIndex(index);
                          final encounter = index == 1;

                          return GestureDetector(
                            key: ValueKey(
                              'card-lab-item-${recipe.interestId}',
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _CardverseCardDetailScreen(
                                  recipe: recipe,
                                  initialFinish: finish,
                                  editionLabel:
                                      encounter ? 'ENCOUNTER' : 'CORE',
                                  title: interest.labelFor(locale),
                                  subtitle: _subtitle(
                                    locale,
                                    recipe.categoryKit,
                                    recipe.visualFamily,
                                    encounter: encounter,
                                  ),
                                ),
                              ),
                            ),
                            child: Hero(
                              tag: 'card-lab-${recipe.interestId}',
                              child: ZyncCardPreview(
                                recipe: recipe,
                                title: interest.labelFor(locale),
                                subtitle: _subtitle(
                                  locale,
                                  recipe.categoryKit,
                                  recipe.visualFamily,
                                  encounter: encounter,
                                ),
                                finish: finish,
                                editionLabel:
                                    encounter ? 'ENCOUNTER' : 'CORE',
                                cardNumberLabel:
                                    'P${(index + 1).toString().padLeft(2, '0')}',
                              ),
                            ),
                          );
                        },
                        childCount: recipes.length,
                      ),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: 5 / 7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static CardFinishTier _proofFinishForIndex(int index) {
    const finishes = [
      CardFinishTier.normal,
      CardFinishTier.foil,
      CardFinishTier.holo,
      CardFinishTier.prism,
      CardFinishTier.legendary,
      CardFinishTier.secret,
    ];
    return finishes[index % finishes.length];
  }

  static String _subtitle(
    String locale,
    String categoryKit,
    String visualFamily, {
    required bool encounter,
  }) {
    if (encounter) {
      return _copy(
        locale,
        en: 'Discovered through a Zync',
        zhHant: '透過一次 Zync 發現',
        zhHans: '通过一次 Zync 发现',
      );
    }

    return '$categoryKit · $visualFamily';
  }

  static String _copy(
    String locale, {
    required String en,
    required String zhHant,
    required String zhHans,
  }) {
    final raw = locale.replaceAll('_', '-').toLowerCase();
    if (!raw.startsWith('zh')) return en;
    if (raw.contains('hans') ||
        raw.contains('-cn') ||
        raw.contains('-sg')) {
      return zhHans;
    }
    return zhHant;
  }
}

class _CardverseCardDetailScreen extends StatefulWidget {
  const _CardverseCardDetailScreen({
    required this.recipe,
    required this.initialFinish,
    required this.editionLabel,
    required this.title,
    required this.subtitle,
  });

  final CardVisualRecipe recipe;
  final CardFinishTier initialFinish;
  final String editionLabel;
  final String title;
  final String subtitle;

  @override
  State<_CardverseCardDetailScreen> createState() =>
      _CardverseCardDetailScreenState();
}

class _CardverseCardDetailScreenState
    extends State<_CardverseCardDetailScreen> {
  late CardFinishTier _finish = widget.initialFinish;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();

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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const _FocusOnlyBadge(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('cardverse-card-detail'),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 390,
                        ),
                        child: Hero(
                          tag: 'card-lab-${widget.recipe.interestId}',
                          child: ZyncCardPreview(
                            recipe: widget.recipe,
                            title: widget.title,
                            subtitle: widget.subtitle,
                            finish: _finish,
                            editionLabel: widget.editionLabel,
                            cardNumberLabel: 'VISUAL PROOF',
                            animateFinish: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      CardverseVisualLabScreen._copy(
                        locale,
                        en: 'Finish comparison',
                        zhHant: '閃卡層次比較',
                        zhHans: '闪卡层次比较',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final finish in CardFinishTier.values)
                          ChoiceChip(
                            key: ValueKey(
                              'finish-chip-${finish.name}',
                            ),
                            label: Text(_finishLabel(finish)),
                            selected: _finish == finish,
                            onSelected: (_) {
                              setState(() => _finish = finish);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ZyncSurface(
                      shadow: false,
                      backgroundColor: const Color(0xFFFFF7F2),
                      borderColor: ZyncPalette.peach,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.accessibility_new_rounded,
                            color: ZyncPalette.orangeDeep,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              CardverseVisualLabScreen._copy(
                                locale,
                                en:
                                    'Animated shimmer is focus-only. Reduce Motion automatically falls back to a static finish.',
                                zhHant:
                                    '動態閃光只會喺 focus card 出現；開啟 Reduce Motion 後會自動退回靜態效果。',
                                zhHans:
                                    '动态闪光只会在焦点卡出现；开启 Reduce Motion 后会自动回退为静态效果。',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RecipeReadout(recipe: widget.recipe),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _finishLabel(CardFinishTier finish) => switch (finish) {
        CardFinishTier.normal => 'Normal',
        CardFinishTier.foil => 'Foil',
        CardFinishTier.holo => 'Holo',
        CardFinishTier.prism => 'Prism',
        CardFinishTier.legendary => 'Legendary',
        CardFinishTier.secret => 'Secret',
      };
}

class _FocusOnlyBadge extends StatelessWidget {
  const _FocusOnlyBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'FOCUS FX',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF176B57),
                fontWeight: FontWeight.w800,
              ),
        ),
      );
}

class _RecipeReadout extends StatelessWidget {
  const _RecipeReadout({required this.recipe});

  final CardVisualRecipe recipe;

  @override
  Widget build(BuildContext context) => ZyncSurface(
        shadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated recipe',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            _row(context, 'ID', recipe.interestId),
            _row(context, 'Kit', recipe.categoryKit),
            _row(context, 'Family', recipe.visualFamily),
            _row(context, 'Scene', recipe.sceneGrammar),
            _row(context, 'Palette', '${recipe.paletteSlot}'),
            _row(context, 'Seed', recipe.visualSeed),
          ],
        ),
      );

  Widget _row(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 68,
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

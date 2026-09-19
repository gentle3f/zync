import 'package:flutter/material.dart';

import '../core/card_visual_recipe.dart';
import '../core/cardverse_models.dart';
import '../core/interest_catalog.dart';
import '../ui/zync_design.dart';
import '../widgets/zync_card_preview.dart';

enum _CollectionFilter {
  all,
  owned,
  missing,
  encounter,
  wantToTry,
}

class CardverseCollectionLabScreen extends StatefulWidget {
  const CardverseCollectionLabScreen({super.key});

  @override
  State<CardverseCollectionLabScreen> createState() =>
      _CardverseCollectionLabScreenState();
}

class _CardverseCollectionLabScreenState
    extends State<CardverseCollectionLabScreen> {
  late final List<_CollectionProofItem> _items = _buildProofItems();
  late final Set<String> _wantToTryIds = {
    for (var i = 0; i < _items.length; i++)
      if (_items[i].owned && i % 9 == 2) _items[i].recipe.interestId,
  };

  _CollectionFilter _filter = _CollectionFilter.all;

  String get _locale => Localizations.localeOf(context).toLanguageTag();
  bool get _isZh => _locale.toLowerCase().startsWith('zh');

  int get _ownedCount => _items.where((item) => item.owned).length;
  int get _missingCount => _items.length - _ownedCount;
  int get _encounterCount =>
      _items.where((item) => item.owned && item.encounter).length;

  List<_CollectionProofItem> get _visibleItems => switch (_filter) {
        _CollectionFilter.all => _items,
        _CollectionFilter.owned =>
          _items.where((item) => item.owned).toList(growable: false),
        _CollectionFilter.missing =>
          _items.where((item) => !item.owned).toList(growable: false),
        _CollectionFilter.encounter => _items
            .where((item) => item.owned && item.encounter)
            .toList(growable: false),
        _CollectionFilter.wantToTry => _items
            .where(
              (item) =>
                  item.owned &&
                  _wantToTryIds.contains(item.recipe.interestId),
            )
            .toList(growable: false),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            key: const ValueKey('cardverse-collection-lab'),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white.withValues(alpha: 0.94),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: Text(
                  _isZh
                      ? 'My Zync World · 收藏實驗室'
                      : 'My Zync World · Collection Lab',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ZyncSurface(
                        backgroundColor: const Color(0xFFFFF7F2),
                        borderColor: ZyncPalette.peach,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ZyncIconTile(
                              icon: Icons.science_outlined,
                              backgroundColor: ZyncPalette.peach,
                              foregroundColor: ZyncPalette.orangeDeep,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isZh
                                    ? 'Prototype inventory：呢度只係用50張proof card驗Collection UX，冇真正鑄卡、冇雲端資產。'
                                    : 'Prototype inventory: this uses 50 proof cards to validate collection UX. No cards or cloud assets are being minted.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _summaryCard(),
                      const SizedBox(height: 14),
                      _filterStrip(),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
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
                        (context, index) =>
                            _collectionTile(_visibleItems[index]),
                        childCount: _visibleItems.length,
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

  Widget _summaryCard() => ZyncSurface(
        shadow: false,
        backgroundColor: const Color(0xFFF1EEFF),
        borderColor: const Color(0xFFE0D9FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_ownedCount / ${_items.length} ${_isZh ? '已發現' : 'discovered'}',
              key: const ValueKey('collection-discovered-count'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _ownedCount / _items.length,
                minHeight: 9,
                backgroundColor: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statChip(
                  Icons.help_outline_rounded,
                  _isZh ? '$_missingCount 張未發現' : '$_missingCount missing',
                ),
                _statChip(
                  Icons.hub_outlined,
                  _isZh
                      ? '$_encounterCount 張 Encounter'
                      : '$_encounterCount Encounter',
                ),
                _statChip(
                  Icons.auto_awesome_outlined,
                  _isZh
                      ? '${_wantToTryIds.length} 個想試'
                      : '${_wantToTryIds.length} Want to Try',
                ),
              ],
            ),
          ],
        ),
      );

  Widget _statChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: ZyncPalette.plum),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );

  Widget _filterStrip() => SizedBox(
        height: 42,
        child: ListView(
          key: const ValueKey('collection-filter-strip'),
          scrollDirection: Axis.horizontal,
          children: [
            _filterChip(
              _CollectionFilter.all,
              _isZh ? '全部 50' : 'All 50',
            ),
            _filterChip(
              _CollectionFilter.owned,
              _isZh ? '已擁有 $_ownedCount' : 'Owned $_ownedCount',
            ),
            _filterChip(
              _CollectionFilter.missing,
              _isZh ? '未發現 $_missingCount' : 'Missing $_missingCount',
            ),
            _filterChip(
              _CollectionFilter.encounter,
              'Encounter $_encounterCount',
            ),
            _filterChip(
              _CollectionFilter.wantToTry,
              _isZh
                  ? '想試 ${_wantToTryIds.length}'
                  : 'Want to Try ${_wantToTryIds.length}',
            ),
          ],
        ),
      );

  Widget _filterChip(_CollectionFilter filter, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          key: ValueKey('collection-filter-${filter.name}'),
          label: Text(label),
          selected: _filter == filter,
          onSelected: (_) => setState(() => _filter = filter),
        ),
      );

  Widget _collectionTile(_CollectionProofItem item) {
    if (!item.owned) {
      return _MissingCardSilhouette(
        key: ValueKey('binder-missing-${item.recipe.interestId}'),
        categoryKit: item.recipe.categoryKit,
        locale: _locale,
      );
    }

    final interest = InterestCatalog.byId(item.recipe.interestId)!;
    final wantToTry = _wantToTryIds.contains(item.recipe.interestId);

    return GestureDetector(
      key: ValueKey('binder-card-${item.recipe.interestId}'),
      onTap: () => _openDetail(item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ZyncCardPreview(
            recipe: item.recipe,
            title: interest.labelFor(_locale),
            subtitle: item.encounter
                ? (_isZh
                    ? '透過一次 Zync 發現'
                    : 'Discovered through a Zync')
                : item.recipe.visualFamily,
            finish: item.finish,
            editionLabel: item.encounter ? 'ENCOUNTER' : 'CORE',
            cardNumberLabel: 'LAB',
          ),
          if (item.quantity > 1)
            Positioned(
              right: 8,
              bottom: 8,
              child: _OverlayBadge(
                label: '×${item.quantity}',
                icon: Icons.content_copy_rounded,
              ),
            ),
          if (wantToTry)
            Positioned(
              left: 8,
              bottom: 8,
              child: _OverlayBadge(
                label: _isZh ? '想試' : 'TRY',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openDetail(_CollectionProofItem item) async {
    final interest = InterestCatalog.byId(item.recipe.interestId)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CollectionCardDetailSheet(
        item: item,
        title: interest.labelFor(_locale),
        locale: _locale,
        initialWantToTry:
            _wantToTryIds.contains(item.recipe.interestId),
        onWantToTryChanged: (value) {
          if (!mounted) return;
          setState(() {
            if (value) {
              _wantToTryIds.add(item.recipe.interestId);
            } else {
              _wantToTryIds.remove(item.recipe.interestId);
            }
          });
        },
      ),
    );
  }

  static List<_CollectionProofItem> _buildProofItems() {
    final recipes = CardVisualRecipeResolver.expandedProofBatch();
    return List.unmodifiable([
      for (var i = 0; i < recipes.length; i++)
        _CollectionProofItem(
          recipe: recipes[i],
          owned: i % 4 != 0,
          quantity: i % 4 == 0 ? 0 : (i % 5 == 0 ? 3 : 1),
          encounter: i % 4 != 0 && i % 11 == 1,
          finish: CardFinishTier.values[
              i % CardFinishTier.values.length],
        ),
    ]);
  }
}

class _CollectionProofItem {
  const _CollectionProofItem({
    required this.recipe,
    required this.owned,
    required this.quantity,
    required this.encounter,
    required this.finish,
  });

  final CardVisualRecipe recipe;
  final bool owned;
  final int quantity;
  final bool encounter;
  final CardFinishTier finish;
}

class _MissingCardSilhouette extends StatelessWidget {
  const _MissingCardSilhouette({
    super.key,
    required this.categoryKit,
    required this.locale,
  });

  final String categoryKit;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isZh = locale.toLowerCase().startsWith('zh');
    return AspectRatio(
      aspectRatio: 5 / 7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD7D2DE),
            width: 2,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE9E6ED),
              Color(0xFFD7D2DE),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MissingPatternPainter(),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: Color(0xFF8B8493),
                ),
                const SizedBox(height: 10),
                Text(
                  '???',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                        color: const Color(0xFF746D7B),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isZh ? '未發現' : 'Not discovered',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF746D7B),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoryKit,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF918A98),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final gap = size.width / 6;
    for (var x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MissingPatternPainter oldDelegate) => false;
}

class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: ZyncPalette.plum),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ZyncPalette.plum,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      );
}

class _CollectionCardDetailSheet extends StatefulWidget {
  const _CollectionCardDetailSheet({
    required this.item,
    required this.title,
    required this.locale,
    required this.initialWantToTry,
    required this.onWantToTryChanged,
  });

  final _CollectionProofItem item;
  final String title;
  final String locale;
  final bool initialWantToTry;
  final ValueChanged<bool> onWantToTryChanged;

  @override
  State<_CollectionCardDetailSheet> createState() =>
      _CollectionCardDetailSheetState();
}

class _CollectionCardDetailSheetState
    extends State<_CollectionCardDetailSheet> {
  late bool _wantToTry = widget.initialWantToTry;

  bool get _isZh => widget.locale.toLowerCase().startsWith('zh');

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.62,
      maxChildSize: 0.96,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDFCFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          key: const ValueKey('collection-card-detail'),
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D2DE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: ZyncCardPreview(
                  recipe: widget.item.recipe,
                  title: widget.title,
                  subtitle: widget.item.encounter
                      ? (_isZh
                          ? '透過一次 Zync 發現'
                          : 'Discovered through a Zync')
                      : widget.item.recipe.visualFamily,
                  finish: widget.item.finish,
                  editionLabel:
                      widget.item.encounter ? 'ENCOUNTER' : 'CORE',
                  cardNumberLabel: 'COLLECTION LAB',
                  animateFinish: true,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ZyncSurface(
              shadow: false,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(
                    Icons.inventory_2_outlined,
                    _isZh
                        ? '擁有 ×${widget.item.quantity}'
                        : 'Owned ×${widget.item.quantity}',
                  ),
                  _infoChip(
                    Icons.auto_awesome_outlined,
                    _finishLabel(widget.item.finish),
                  ),
                  if (widget.item.encounter)
                    _infoChip(
                      Icons.lock_outline_rounded,
                      _isZh
                          ? 'Encounter · 不可交易'
                          : 'Encounter · Soulbound',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('collection-want-to-try-toggle'),
              onPressed: () {
                setState(() => _wantToTry = !_wantToTry);
                widget.onWantToTryChanged(_wantToTry);
              },
              icon: Icon(
                _wantToTry
                    ? Icons.check_circle_outline_rounded
                    : Icons.auto_awesome_rounded,
              ),
              label: Text(
                _wantToTry
                    ? (_isZh ? '已加入 Want to Try' : 'In Want to Try')
                    : (_isZh ? '加入 Want to Try' : 'Add to Want to Try'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isZh
                  ? '正式版本會直接連到同一個 Interest DNA canonical ID；已經 Like／Love 嘅興趣絕對唔會被降級。'
                  : 'The real version maps to the same canonical Interest DNA ID. Existing Like/Love strength is never downgraded.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ZyncPalette.inkSoft,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
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

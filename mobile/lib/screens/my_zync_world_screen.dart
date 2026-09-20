import 'package:flutter/material.dart';

import '../core/card_visual_recipe.dart';
import '../core/cardverse_cloud_client.dart';
import '../core/cardverse_inventory.dart';
import '../core/cardverse_models.dart';
import '../core/cardverse_session_store.dart';
import '../core/interest_catalog.dart';
import '../ui/zync_design.dart';
import '../widgets/zync_card_preview.dart';
import 'cardverse_account_lab_screen.dart';
import 'cardverse_pack_opening_lab_screen.dart';
import 'quest_board_screen.dart';

class MyZyncWorldScreen extends StatefulWidget {
  const MyZyncWorldScreen({super.key});

  @override
  State<MyZyncWorldScreen> createState() => _MyZyncWorldScreenState();
}

class _MyZyncWorldScreenState extends State<MyZyncWorldScreen> {
  late final CardverseCloudClient _cloud;
  late final CardverseSessionStore _sessions;

  CardverseSessionCredential? _session;
  CardverseInventorySnapshot? _inventory;
  bool _loading = true;
  String _error = '';
  String? _openingPackId;

  bool get _isZh =>
      Localizations.localeOf(context).toLanguageTag().startsWith('zh');
  String get _locale => Localizations.localeOf(context).toLanguageTag();

  @override
  void initState() {
    super.initState();
    _cloud = CardverseCloudClient();
    _sessions = CardverseSessionStore();
    _load();
  }

  @override
  void dispose() {
    _cloud.close();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }

    final session = await _sessions.load();
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _inventory = null;
        _loading = false;
      });
      return;
    }

    try {
      final inventory = await _cloud.fetchInventorySnapshot(session.token);
      if (!mounted) return;
      setState(() {
        _session = session;
        _inventory = inventory;
        _loading = false;
      });
    } on CardverseCloudException catch (error) {
      if (error.failure == CardverseCloudFailure.unauthorized) {
        await _sessions.clear();
        if (!mounted) return;
        setState(() {
          _session = null;
          _inventory = null;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _session = session;
        _inventory = null;
        _loading = false;
        _error = _isZh
            ? '暫時連接唔到你嘅 Cardverse 收藏。'
            : 'Your Cardverse collection is temporarily unavailable.';
      });
    }
  }

  Future<void> _connectAccount() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const CardverseAccountLabScreen(),
      ),
    );
    await _load();
  }

  Future<void> _openPack(CardverseUnopenedPack pack) async {
    final session = _session;
    if (session == null || _openingPackId != null) return;

    setState(() => _openingPackId = pack.packId);
    try {
      final request = CardversePackOpenRequest.fromJson({
        'packId': pack.packId,
        'idempotencyKey': 'pack-open:${pack.packId}',
        'clientRevealVersion': 1,
      });
      final receipt = await _cloud.openPack(
        sessionToken: session.token,
        request: request,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CardversePackOpeningLabScreen(
            receipt: receipt,
            labMode: false,
          ),
        ),
      );
      await _load();
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      final message = error.failure == CardverseCloudFailure.disabled
          ? (_isZh
              ? 'Cardverse 開包功能喺呢個環境仲未開啟。'
              : 'Pack opening is not enabled in this environment yet.')
          : (_isZh
              ? '今次開包未完成。已鎖定嘅 server 結果唔會因為重試而 reroll。'
              : 'The pack did not open. A retry cannot reroll a server-locked result.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _openingPackId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'My Zync World',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _load,
                      tooltip: _isZh ? '更新' : 'Refresh',
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(onRefresh: _load, child: _body()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_session == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        children: [
          _hero(),
          const SizedBox(height: 18),
          ZyncSurface(
            borderColor: const Color(0xFFE0D9FF),
            backgroundColor: const Color(0xFFF7F5FF),
            child: Column(
              children: [
                const ZyncIconTile(
                  icon: Icons.cloud_outlined,
                  size: 68,
                  backgroundColor: Color(0xFFE9E5FF),
                  foregroundColor: ZyncPalette.plum,
                ),
                const SizedBox(height: 14),
                Text(
                  _isZh ? '保留你嘅收藏' : 'Keep your collection',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 7),
                Text(
                  _isZh
                      ? '連接帳戶之後，卡包、卡牌同獎勵先可以跨裝置保存。'
                      : 'Connect an account so packs, cards and rewards can survive reinstalls and move across devices.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const ValueKey('zync-world-connect-account'),
                  onPressed: _connectAccount,
                  icon: const Icon(Icons.login_rounded),
                  label: Text(
                    _isZh ? '連接 Cardverse 帳戶' : 'Connect Cardverse account',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_error.isNotEmpty || _inventory == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _hero(),
          const SizedBox(height: 18),
          ZyncSurface(
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined, size: 44),
                const SizedBox(height: 12),
                Text(_error),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _load,
                  child: Text(_isZh ? '再試' : 'Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final inventory = _inventory!;
    return ListView(
      key: const ValueKey('my-zync-world-live'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        _hero(),
        const SizedBox(height: 18),
        _stats(inventory),
        const SizedBox(height: 22),
        _sectionTitle(
          _isZh ? '未開卡包' : 'Unopened packs',
          Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 10),
        if (inventory.unopenedPacks.isEmpty)
          _emptyPacks()
        else
          for (final pack in inventory.unopenedPacks) ...[
            _packTile(pack),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 22),
        _sectionTitle(
          _isZh ? '我的收藏' : 'My collection',
          Icons.auto_awesome_mosaic_outlined,
        ),
        const SizedBox(height: 10),
        if (inventory.cards.isEmpty)
          _emptyCollection()
        else
          _collectionGrid(inventory),
      ],
    );
  }

  Widget _hero() => ZyncSurface(
        padding: EdgeInsets.zero,
        borderColor: ZyncPalette.peach,
        backgroundColor: const Color(0xFFFFF3EB),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: ConnectionBackdrop()),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ZyncIconTile(
                      icon: Icons.public_rounded,
                      size: 56,
                      backgroundColor: Colors.white,
                      foregroundColor: ZyncPalette.plum,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Zync World',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isZh
                                ? '你喺真實世界 Zync、探索同一齊做嘅事，會慢慢變成屬於你嘅興趣世界。'
                                : 'Real-world Zyncs, discoveries and things you do together grow into a world that is yours.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _stats(CardverseInventorySnapshot inventory) => Row(
        children: [
          Expanded(
            child: _statCard(
              '${inventory.discoveredVariants}',
              _isZh ? '卡牌款式' : 'card variants',
              Icons.style_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              '${inventory.unopenedPacks.length}',
              _isZh ? '未開卡包' : 'unopened packs',
              Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              '${inventory.availableDrawTokens}',
              'Draw Tokens',
              Icons.brightness_5_outlined,
            ),
          ),
        ],
      );

  Widget _statCard(String value, String label, IconData icon) => ZyncSurface(
        shadow: false,
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Icon(icon, size: 21, color: ZyncPalette.plum),
            const SizedBox(height: 7),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );

  Widget _sectionTitle(String title, IconData icon) => Row(
        children: [
          Icon(icon, color: ZyncPalette.plum),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      );

  Widget _emptyPacks() => ZyncSurface(
        shadow: false,
        child: Row(
          children: [
            const ZyncIconTile(
              icon: Icons.explore_outlined,
              backgroundColor: Color(0xFFFFE9B7),
              foregroundColor: Color(0xFF8B5A00),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isZh
                    ? '完成探索任務可以得到由 server 發出嘅卡包。'
                    : 'Complete Curiosity quests to earn packs issued by the server.',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuestBoardScreen()),
              ),
              child: Text(_isZh ? '睇任務' : 'Quests'),
            ),
          ],
        ),
      );

  Widget _packTile(CardverseUnopenedPack pack) {
    final busy = _openingPackId == pack.packId;
    final discovery = pack.packType == 'discovery';
    return ZyncSurface(
      shadow: false,
      borderColor: discovery
          ? const Color(0xFFE0D9FF)
          : const Color(0xFFFFD9BE),
      backgroundColor: discovery
          ? const Color(0xFFF7F5FF)
          : const Color(0xFFFFF7F2),
      child: Row(
        children: [
          ZyncIconTile(
            icon: discovery
                ? Icons.travel_explore_rounded
                : Icons.auto_awesome_rounded,
            backgroundColor: discovery
                ? const Color(0xFFE9E5FF)
                : ZyncPalette.peach,
            foregroundColor:
                discovery ? ZyncPalette.plum : ZyncPalette.orangeDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discovery
                      ? (_isZh ? '探索卡包' : 'Discovery Pack')
                      : (_isZh ? '標準卡包' : 'Standard Pack'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _isZh
                      ? '5 張 · 結果由 server 決定'
                      : '5 cards · server-authoritative draw',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton(
            key: ValueKey('zync-world-open-pack-${pack.packId}'),
            onPressed: busy ? null : () => _openPack(pack),
            child: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isZh ? '開包' : 'Open'),
          ),
        ],
      ),
    );
  }

  Widget _emptyCollection() => ZyncSurface(
        shadow: false,
        child: Column(
          children: [
            const ZyncIconTile(
              icon: Icons.style_outlined,
              size: 60,
              backgroundColor: Color(0xFFE9E5FF),
              foregroundColor: ZyncPalette.plum,
            ),
            const SizedBox(height: 12),
            Text(
              _isZh ? '第一張卡仲未出現' : 'Your first card is still waiting',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              _isZh
                  ? '完成任務、拎卡包、打開之後，真正嘅雲端收藏就會出現喺呢度。'
                  : 'Finish a quest, earn a pack and open it. Your real cloud collection will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _collectionGrid(CardverseInventorySnapshot inventory) {
    final renderable = inventory.cards
        .where(
          (item) =>
              CardVisualRecipeResolver.resolve(item.variant.interestId) != null,
        )
        .toList(growable: false);

    if (renderable.isEmpty) {
      return ZyncSurface(
        shadow: false,
        child: Text(
          _isZh
              ? '收藏已同步，但現有卡牌暫時未有可用嘅視覺 recipe。'
              : 'Your collection synced, but these cards do not have a renderable visual recipe yet.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 480
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: renderable.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 5 / 7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            final item = renderable[index];
            final recipe =
                CardVisualRecipeResolver.resolve(item.variant.interestId)!;
            final interest = InterestCatalog.byId(item.variant.interestId);
            final finish = _finish(item.variant.finishId);
            return Stack(
              fit: StackFit.expand,
              children: [
                ZyncCardPreview(
                  recipe: recipe,
                  title: interest?.labelFor(_locale) ??
                      item.variant.interestId,
                  subtitle: _finishLabel(finish),
                  finish: finish,
                  editionLabel: _edition(item.variant.editionId),
                  cardNumberLabel: '×${item.quantity}',
                ),
                if (item.quantity > 1)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '×${item.quantity}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  CardFinishTier _finish(String raw) => switch (raw) {
        'foil' => CardFinishTier.foil,
        'holo' => CardFinishTier.holo,
        'prism' => CardFinishTier.prism,
        'legendary' => CardFinishTier.legendary,
        'secret' => CardFinishTier.secret,
        _ => CardFinishTier.normal,
      };

  String _finishLabel(CardFinishTier finish) => switch (finish) {
        CardFinishTier.normal => 'Normal',
        CardFinishTier.foil => 'Foil',
        CardFinishTier.holo => 'Holo',
        CardFinishTier.prism => 'Prism',
        CardFinishTier.legendary => 'Legendary',
        CardFinishTier.secret => 'Secret',
      };

  String _edition(String raw) {
    final value = raw.toLowerCase();
    if (value.startsWith('core')) return 'CORE';
    if (value.startsWith('event')) return 'EVENT';
    if (value == 'encounter') return 'ENCOUNTER';
    if (value == 'discovery') return 'DISCOVERY';
    if (value == 'starter') return 'STARTER';
    if (value == 'achievement') return 'ACHIEVEMENT';
    return raw.toUpperCase();
  }
}

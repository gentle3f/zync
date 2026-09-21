import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/achievement_service.dart';
import '../core/card_interest_bridge.dart';
import '../core/card_visual_recipe.dart';
import '../core/cardverse_cloud_client.dart';
import '../core/cardverse_inventory.dart';
import '../core/cardverse_models.dart';
import '../core/cardverse_session_store.dart';
import '../core/interest_catalog.dart';
import '../core/local_store.dart';
import '../core/models.dart';
import '../core/quest_engine.dart';
import '../ui/zync_design.dart';
import '../widgets/zync_card_preview.dart';
import 'achievement_screen.dart';
import 'cardverse_account_screen.dart';
import 'cardverse_pack_opening_lab_screen.dart';
import 'quest_board_screen.dart';

class MyZyncWorldScreen extends StatefulWidget {
  const MyZyncWorldScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  final LocalProfile profile;
  final Future<void> Function(LocalProfile profile) onProfileChanged;

  @override
  State<MyZyncWorldScreen> createState() => _MyZyncWorldScreenState();
}

class _MyZyncWorldScreenState extends State<MyZyncWorldScreen> {
  late final CardverseCloudClient _cloud;
  late final CardverseSessionStore _sessions;
  late LocalProfile _profile;

  CardverseSessionCredential? _session;
  CardverseInventorySnapshot? _inventory;
  AchievementSnapshot? _achievement;
  ZyncQuestBoardSnapshot? _quests;
  bool _loading = true;
  String _error = '';
  String? _openingPackId;
  bool _claimingDaily = false;
  bool _drawingCard = false;

  bool get _isZh =>
      Localizations.localeOf(context).toLanguageTag().startsWith('zh');
  String get _locale => Localizations.localeOf(context).toLanguageTag();

  @override
  void initState() {
    super.initState();
    _cloud = CardverseCloudClient();
    _sessions = CardverseSessionStore();
    _profile = widget.profile;
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

    final history = await LocalStore.loadHistory();
    final events = await LocalStore.loadProgressEvents();
    final achievement = AchievementService.evaluate(
      history,
      events: events,
    );
    final now = DateTime.now();
    final quests = ZyncQuestEngine.evaluate(
      events: events,
      now: now,
      timezoneOffset: now.timeZoneOffset,
    );
    final session = await _sessions.load();
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _inventory = null;
        _achievement = achievement;
        _quests = quests;
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
        _achievement = achievement;
        _quests = quests;
        _loading = false;
      });
    } on CardverseCloudException catch (error) {
      if (error.failure == CardverseCloudFailure.unauthorized) {
        await _sessions.clear();
        if (!mounted) return;
        setState(() {
          _session = null;
          _inventory = null;
          _achievement = achievement;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _session = session;
        _inventory = null;
        _achievement = achievement;
        _quests = quests;
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
        builder: (_) => const CardverseAccountScreen(
          returnOnSignIn: true,
        ),
      ),
    );
    await _load();
  }

  DateTime _dailyCycleStart() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final localClock = now.toUtc().add(offset);
    final localDay = DateTime.utc(
      localClock.year,
      localClock.month,
      localClock.day,
    );
    return localDay.subtract(offset);
  }

  String _dailyEligibilityKey() =>
      'daily_login:${_dailyCycleStart().toIso8601String()}';

  bool _dailyClaimed(CardverseInventorySnapshot inventory) =>
      inventory.claimedEligibilityKeys.contains(_dailyEligibilityKey());

  Future<void> _claimDailyDraw(
    CardverseInventorySnapshot inventory,
  ) async {
    final session = _session;
    if (session == null || _claimingDaily || _dailyClaimed(inventory)) {
      return;
    }

    setState(() => _claimingDaily = true);
    try {
      final cycle = _dailyCycleStart();
      await _cloud.claimDailyLogin(
        sessionToken: session.token,
        idempotencyKey:
            'daily-login:${cycle.millisecondsSinceEpoch}',
        timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isZh
                ? '今日卡牌抽取 +1。'
                : 'Your daily card draw is ready.',
          ),
        ),
      );
      await _load();
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        CardverseCloudFailure.conflict => _isZh
            ? '今日嘅登入獎勵已經領取。'
            : 'Today\'s login reward is already claimed.',
        CardverseCloudFailure.disabled => _isZh
            ? 'Daily Draw 喺呢個環境仲未開啟。'
            : 'Daily Draw is not enabled in this environment yet.',
        _ => _isZh
            ? '今日獎勵暫時未能領取，請稍後再試。'
            : 'The daily reward could not be claimed. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _claimingDaily = false);
    }
  }

  Future<void> _drawOneCard(
    CardverseInventorySnapshot inventory,
  ) async {
    final session = _session;
    if (session == null ||
        _drawingCard ||
        inventory.availableDrawTokens < 1) {
      return;
    }

    setState(() => _drawingCard = true);
    try {
      final receipt = await _cloud.redeemDrawToken(
        sessionToken: session.token,
        request: CardverseDrawTokenRequest(
          idempotencyKey:
              'draw:${inventory.accountId}:${inventory.ledgerCursor}:${inventory.availableDrawTokens}',
        ),
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      await _showSingleDraw(receipt);
      await _load();
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        CardverseCloudFailure.conflict => _isZh
            ? 'Draw Token 狀態已更新，重新整理後再試。'
            : 'Your Draw Token balance changed. Refresh and try again.',
        CardverseCloudFailure.disabled => _isZh
            ? '單卡抽取喺呢個環境仲未開啟。'
            : 'Single-card draws are not enabled in this environment yet.',
        _ => _isZh
            ? '今次抽卡未完成；未確認成功前唔會喺畫面假裝出卡。'
            : 'The draw did not complete. No card is shown unless the server confirms it.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _drawingCard = false);
    }
  }

  Future<void> _showSingleDraw(
    CardverseSingleDrawReceipt receipt,
  ) async {
    final item = receipt.item;
    final recipe =
        CardVisualRecipeResolver.resolve(item.variant.interestId);
    final interest = InterestCatalog.byId(item.variant.interestId);
    final title =
        interest?.labelFor(_locale) ?? item.variant.interestId;
    final finish = _finish(item.variant.finishId);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDFCFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D2DE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isZh ? '你抽到一張新卡' : 'You drew a card',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                _isZh
                    ? '結果由 Cardverse server 決定；1 個 Draw Token 已經使用。'
                    : 'The Cardverse server decided this result; 1 Draw Token was used.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ZyncPalette.inkSoft),
              ),
              const SizedBox(height: 18),
              if (recipe != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 330),
                  child: AspectRatio(
                    aspectRatio: 5 / 7,
                    child: ZyncCardPreview(
                      recipe: recipe,
                      title: title,
                      subtitle: _finishLabel(finish),
                      finish: finish,
                      editionLabel: _edition(item.variant.editionId),
                      cardNumberLabel: 'NEW',
                      animateFinish: true,
                    ),
                  ),
                )
              else
                ZyncSurface(
                  shadow: false,
                  child: ListTile(
                    leading: const Icon(Icons.style_outlined),
                    title: Text(title),
                    subtitle: Text(_finishLabel(finish)),
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(_isZh ? '加入收藏' : 'Add to collection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          _progressHub(),
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
                    _isZh ? '連接 Zync 帳戶' : 'Connect Zync account',
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
        _hero(inventory: inventory),
        const SizedBox(height: 16),
        _dailyDrawPanel(inventory),
        const SizedBox(height: 16),
        _progressHub(),
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

  Widget _hero({CardverseInventorySnapshot? inventory}) {
    final achievement = _achievement;
    final unlocked = achievement?.unlockedCount ?? 0;
    final packs = inventory?.unopenedPacks.length ?? 0;
    final tokens = inventory?.availableDrawTokens ?? 0;

    return ZyncHeroPanel(
      startColor: const Color(0xFFF2EEFF),
      endColor: const Color(0xFFFFF1E8),
      accentColor: ZyncPalette.plum,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZyncIconTile(
                icon: Icons.public_rounded,
                size: 54,
                backgroundColor: Colors.white,
                foregroundColor: ZyncPalette.plum,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Zync World',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isZh
                          ? '你每一次真人 Zync、探索同一齊做嘅事，都會令呢個世界再大一點。'
                          : 'Every real Zync, discovery and thing you do together makes this world a little bigger.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ZyncMetricPill(
                  icon: Icons.emoji_events_rounded,
                  value: '$unlocked',
                  label: _isZh ? '成就' : 'trophies',
                  accentColor: const Color(0xFF8B5A00),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ZyncMetricPill(
                  icon: Icons.inventory_2_outlined,
                  value: '$packs',
                  label: _isZh ? '卡包' : 'packs',
                  accentColor: ZyncPalette.orangeDeep,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ZyncMetricPill(
                  icon: Icons.auto_awesome_rounded,
                  value: '$tokens',
                  label: 'Draws',
                  accentColor: ZyncPalette.plum,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressHub() {
    final achievement = _achievement;
    final quests = _quests;
    final trophyValue = achievement == null
        ? '—'
        : '${achievement.unlockedCount} / ${achievement.progress.length}';
    final daily = quests?.progress
            .where(
              (item) =>
                  item.definition.cadence == ZyncQuestCadence.daily,
            )
            .toList(growable: false) ??
        const <ZyncQuestProgress>[];
    final dailyDone = daily.where((item) => item.complete).length;
    final dailyValue =
        daily.isEmpty ? '—' : '$dailyDone / ${daily.length}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZyncSectionHeading(
          icon: Icons.timeline_rounded,
          title: _isZh ? '今日進度' : 'Today in your world',
          subtitle: _isZh
              ? '做真實世界嘅事，收藏同成就自然會跟住成長。'
              : 'Do things in the real world and your collection grows with you.',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _progressTile(
                icon: Icons.emoji_events_outlined,
                value: trophyValue,
                label: _isZh ? '已解鎖成就' : 'trophies unlocked',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AchievementScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _progressTile(
                icon: Icons.task_alt_rounded,
                value: dailyValue,
                label: _isZh ? '今日任務' : 'today tasks',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QuestBoardScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _progressTile({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E2F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: ZyncPalette.plum, size: 22),
              const SizedBox(height: 9),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: ZyncPalette.inkSoft),
              ),
            ],
          ),
        ),
      );

  Widget _dailyDrawPanel(CardverseInventorySnapshot inventory) {
    final claimed = _dailyClaimed(inventory);
    final tokens = inventory.availableDrawTokens;

    return ZyncHeroPanel(
      padding: const EdgeInsets.all(18),
      startColor: const Color(0xFFFFF5D9),
      endColor: const Color(0xFFFFE8D8),
      accentColor: const Color(0xFFD88B00),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ZyncIconTile(
                icon: Icons.wb_sunny_rounded,
                size: 48,
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF9A6500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isZh ? '今日一抽' : 'Your Daily Draw',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        claimed
                            ? (_isZh
                                ? '今日 check-in 已完成；你有 $tokens 次抽卡可以用。'
                                : 'Check-in complete. You have $tokens draw${tokens == 1 ? '' : 's'} ready.')
                            : (_isZh
                                ? '今日返嚟，就送你 1 次卡牌抽取。'
                                : 'Come back today and claim 1 card draw.'),
                        key: ValueKey('${claimed}_$tokens'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: ZyncPalette.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ZyncStatusPill(
                icon: claimed
                    ? Icons.check_circle_rounded
                    : Icons.card_giftcard_rounded,
                label: claimed
                    ? (_isZh ? '今日已領' : 'Claimed today')
                    : (_isZh ? '今日 +1 Draw' : '+1 draw today'),
                foregroundColor: claimed
                    ? const Color(0xFF176B57)
                    : const Color(0xFF8B5A00),
                backgroundColor: claimed
                    ? const Color(0xFFDDF5EC)
                    : Colors.white.withValues(alpha: 0.72),
              ),
              const Spacer(),
              Text(
                _isZh ? '現有 $tokens' : '$tokens available',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!claimed)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('daily-card-draw-claim'),
                onPressed: _claimingDaily
                    ? null
                    : () => _claimDailyDraw(inventory),
                icon: _claimingDaily
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.card_giftcard_rounded),
                label: Text(
                  _isZh
                      ? '領取今日抽卡'
                      : 'Claim today\'s draw',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ZyncPalette.ink,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (!claimed) const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('draw-one-card'),
              onPressed: tokens > 0 && !_drawingCard
                  ? () => _drawOneCard(inventory)
                  : null,
              icon: _drawingCard
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                tokens > 0
                    ? (_isZh
                        ? '抽 1 張卡 · 使用 1 Draw'
                        : 'Draw 1 card · use 1 draw')
                    : (_isZh
                        ? '完成今日 check-in 或任務先有抽卡'
                        : 'Check in or complete tasks to earn a draw'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) =>
      ZyncSectionHeading(
        icon: icon,
        title: title,
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
                    ? '完成探索任務可以拎到新卡包。'
                    : 'Complete Curiosity quests to earn new card packs.',
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
                      ? '5 張 · 開包結果已安全鎖定'
                      : '5 cards · result safely locked',
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
                GestureDetector(
                  key: ValueKey(
                    'zync-world-card-${item.variant.value}',
                  ),
                  onTap: () => _openCardDetail(
                    item: item,
                    recipe: recipe,
                    title: interest?.labelFor(_locale) ??
                        item.variant.interestId,
                    finish: finish,
                  ),
                  child: ZyncCardPreview(
                    recipe: recipe,
                    title: interest?.labelFor(_locale) ??
                        item.variant.interestId,
                    subtitle: _finishLabel(finish),
                    finish: finish,
                    editionLabel: _edition(item.variant.editionId),
                    cardNumberLabel: '×${item.quantity}',
                  ),
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

  Future<void> _openCardDetail({
    required CardverseInventoryCard item,
    required CardVisualRecipe recipe,
    required String title,
    required CardFinishTier finish,
  }) async {
    final interestId = item.variant.interestId;
    final current = _profile.interests
        .where((entry) => entry.id == interestId)
        .firstOrNull;
    var wantToTry =
        current?.strength == InterestStrength.wantToTry;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final currentStrength = _profile.interests
              .where((entry) => entry.id == interestId)
              .firstOrNull
              ?.strength;
          final stronger = currentStrength == InterestStrength.like ||
              currentStrength == InterestStrength.love;

          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.62,
            maxChildSize: 0.96,
            builder: (context, controller) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFDFCFB),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
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
                        recipe: recipe,
                        title: title,
                        subtitle: _finishLabel(finish),
                        finish: finish,
                        editionLabel: _edition(item.variant.editionId),
                        cardNumberLabel: '×${item.quantity}',
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
                        Chip(
                          avatar: const Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                          ),
                          label: Text(
                            _isZh
                                ? '擁有 ×${item.quantity}'
                                : 'Owned ×${item.quantity}',
                          ),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.auto_awesome_outlined,
                            size: 16,
                          ),
                          label: Text(_finishLabel(finish)),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.layers_outlined,
                            size: 16,
                          ),
                          label: Text(
                            _edition(item.variant.editionId),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (stronger)
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: Icon(
                        currentStrength == InterestStrength.love
                            ? Icons.favorite_rounded
                            : Icons.thumb_up_alt_rounded,
                      ),
                      label: Text(
                        _isZh
                            ? (currentStrength == InterestStrength.love
                                ? '已經係 Interest DNA · Love'
                                : '已經係 Interest DNA · Like')
                            : (currentStrength == InterestStrength.love
                                ? 'Already in Interest DNA · Love'
                                : 'Already in Interest DNA · Like'),
                      ),
                    )
                  else
                    FilledButton.icon(
                      key: const ValueKey(
                        'zync-world-want-to-try-toggle',
                      ),
                      onPressed: () async {
                        final nextInterests = wantToTry
                            ? CardInterestIntentBridge.removeWantToTry(
                                existing: _profile.interests,
                                interestId: interestId,
                              )
                            : CardInterestIntentBridge.upsertWantToTry(
                                existing: _profile.interests,
                                interestId: interestId,
                              );
                        final nextProfile = _profile.copyWith(
                          interests: nextInterests,
                        );
                        await widget.onProfileChanged(nextProfile);
                        if (!mounted) return;
                        setState(() => _profile = nextProfile);
                        setSheetState(() => wantToTry = !wantToTry);
                      },
                      icon: Icon(
                        wantToTry
                            ? Icons.check_circle_outline_rounded
                            : Icons.auto_awesome_rounded,
                      ),
                      label: Text(
                        wantToTry
                            ? (_isZh
                                ? '已加入 Want to Try'
                                : 'In Want to Try')
                            : (_isZh
                                ? '加入 Want to Try'
                                : 'Add to Want to Try'),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    _isZh
                        ? '卡牌同 Interest DNA 用同一個 canonical 興趣。加入 Want to Try 唔會覆蓋你原本嘅 Like／Love。'
                        : 'Cards and Interest DNA share the same canonical interest. Want to Try never downgrades an existing Like or Love.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: ZyncPalette.inkSoft),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

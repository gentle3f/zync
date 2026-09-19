import 'package:flutter/material.dart';

import '../core/local_store.dart';
import '../core/quest_engine.dart';
import '../ui/zync_design.dart';

class QuestBoardScreen extends StatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  State<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends State<QuestBoardScreen> {
  bool _loading = true;
  ZyncQuestBoardSnapshot? _snapshot;
  String? _error;

  String get _locale => Localizations.localeOf(context).toLanguageTag();
  bool get _isZh => _locale.toLowerCase().startsWith('zh');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final events = await LocalStore.loadProgressEvents();
      final now = DateTime.now();
      final snapshot = ZyncQuestEngine.evaluate(
        events: events,
        now: now,
        timezoneOffset: now.timeZoneOffset,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _isZh ? '暫時讀唔到任務進度。' : 'Could not load quest progress.';
      });
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
                padding: const EdgeInsets.fromLTRB(10, 6, 14, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _isZh ? '探索任務板' : 'Curiosity Board',
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
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZyncIconTile(
                icon: Icons.cloud_off_outlined,
                size: 68,
                backgroundColor: Color(0xFFF1EEFF),
                foregroundColor: ZyncPalette.plum,
              ),
              const SizedBox(height: 18),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _load,
                child: Text(_isZh ? '再試' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final daily = _snapshot!.progress
        .where(
          (item) => item.definition.cadence == ZyncQuestCadence.daily,
        )
        .toList(growable: false);
    final weekly = _snapshot!.progress
        .where(
          (item) => item.definition.cadence == ZyncQuestCadence.weekly,
        )
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: [
          ZyncSurface(
            backgroundColor: const Color(0xFFFFF7F2),
            borderColor: ZyncPalette.peach,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZyncIconTile(
                  icon: Icons.explore_outlined,
                  backgroundColor: ZyncPalette.peach,
                  foregroundColor: ZyncPalette.orangeDeep,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isZh
                            ? '任務只獎勵真實互動'
                            : 'Quests reward real-world action',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isZh
                            ? '唔需要撳五個screen、睇廣告或者掛機。Zync、識新朋友、真係一齊做活動先會推進。'
                            : 'No tap-grind, ad watching or idle farming. Progress comes from Zyncs, new people and activities you actually do together.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionHeader(
            icon: Icons.wb_sunny_outlined,
            title: _isZh ? '今日' : 'Today',
            subtitle: _isZh ? '每日按你手機本地時間重設' : 'Resets at your local midnight',
          ),
          const SizedBox(height: 10),
          for (final item in daily) ...[
            _questCard(item),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          _sectionHeader(
            icon: Icons.calendar_view_week_outlined,
            title: _isZh ? '今週' : 'This week',
            subtitle: _isZh ? '星期一開始新一週' : 'New week starts Monday',
          ),
          const SizedBox(height: 10),
          for (final item in weekly) ...[
            _questCard(item),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          ZyncSurface(
            shadow: false,
            backgroundColor: const Color(0xFFF1EEFF),
            borderColor: const Color(0xFFE0D9FF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.cloud_done_outlined,
                  color: ZyncPalette.plum,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isZh
                        ? '獎勵目前只計「有資格」。等 Cardverse 雲端收藏及帳戶啟用後，server 會重新驗證先真正發 Draw Token／Pack；手機本機唔可以自己鑄卡。'
                        : 'Rewards currently track eligibility only. When Cardverse cloud accounts are enabled, the server will revalidate before issuing Draw Tokens or Packs; the phone cannot mint inventory itself.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) =>
      Row(
        children: [
          ZyncIconTile(
            icon: icon,
            size: 40,
            backgroundColor: const Color(0xFFE9E5FF),
            foregroundColor: ZyncPalette.plum,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _questCard(ZyncQuestProgress progress) {
    final copy = _questCopy(progress.definition.id);
    final complete = progress.complete;

    return ZyncSurface(
      shadow: false,
      borderColor: complete
          ? const Color(0xFFBDECDD)
          : ZyncPalette.line,
      backgroundColor: complete
          ? const Color(0xFFF1FBF7)
          : Colors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZyncIconTile(
                icon: complete
                    ? Icons.check_circle_rounded
                    : copy.icon,
                size: 42,
                backgroundColor: complete
                    ? ZyncPalette.mint
                    : copy.background,
                foregroundColor: complete
                    ? const Color(0xFF176B57)
                    : copy.foreground,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      copy.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
              backgroundColor: const Color(0xFFEFEAF4),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${progress.current.clamp(0, progress.definition.target)} / '
                '${progress.definition.target}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              _rewardChip(progress),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rewardChip(ZyncQuestProgress progress) {
    final reward = progress.definition.reward;
    final label = switch (reward.kind) {
      ZyncQuestRewardKind.drawToken =>
        '${reward.amount} Draw Token',
      ZyncQuestRewardKind.standardPack =>
        _isZh ? '${reward.amount} 標準卡包' : '${reward.amount} Standard Pack',
      ZyncQuestRewardKind.discoveryPack =>
        _isZh ? '${reward.amount} 探索卡包' : '${reward.amount} Discovery Pack',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: progress.complete
            ? ZyncPalette.mint
            : const Color(0xFFFFF0E5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            progress.complete
                ? Icons.verified_outlined
                : Icons.card_giftcard_outlined,
            size: 15,
            color: progress.complete
                ? const Color(0xFF176B57)
                : ZyncPalette.orangeDeep,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  _QuestCopy _questCopy(String id) {
    return switch (id) {
      'daily_make_a_zync' => _QuestCopy(
          icon: Icons.person_add_alt_1_outlined,
          background: ZyncPalette.mint,
          foreground: const Color(0xFF176B57),
          title: _isZh ? '同一個人 Zync' : 'Make one Zync',
          description: _isZh
              ? '完成一次面對面 1:1 Zync。'
              : 'Complete one face-to-face 1:1 Zync.',
        ),
      'daily_tried_together' => _QuestCopy(
          icon: Icons.bolt_rounded,
          background: ZyncPalette.peach,
          foreground: ZyncPalette.orangeDeep,
          title: _isZh ? '真係一齊做' : 'Actually do it together',
          description: _isZh
              ? '完成一個 Zync Now 選出嚟嘅活動。'
              : 'Complete an activity chosen by Zync Now.',
        ),
      'weekly_meet_two_new_people' => _QuestCopy(
          icon: Icons.people_alt_outlined,
          background: ZyncPalette.mint,
          foreground: const Color(0xFF176B57),
          title: _isZh ? '識兩個新朋友' : 'Meet two new people',
          description: _isZh
              ? '今週同兩個未 Zync 過嘅人完成 1:1 Zync。'
              : 'Complete 1:1 Zyncs with two people you have not Zynced before.',
        ),
      'weekly_real_world_three' => _QuestCopy(
          icon: Icons.directions_walk_rounded,
          background: const Color(0xFFE9E5FF),
          foreground: ZyncPalette.plum,
          title: _isZh ? '三次真實世界行動' : 'Three real-world actions',
          description: _isZh
              ? '1:1 Zync 同 Tried Together 都會計。'
              : 'Both 1:1 Zyncs and Tried Together count.',
        ),
      'weekly_three_interest_worlds' => _QuestCopy(
          icon: Icons.public_rounded,
          background: const Color(0xFFFFE9B7),
          foreground: const Color(0xFF8B5A00),
          title: _isZh ? '探索三個興趣世界' : 'Explore three interest worlds',
          description: _isZh
              ? '透過真實互動接觸三個不同興趣類別。'
              : 'Touch three different interest categories through real interactions.',
        ),
      _ => _QuestCopy(
          icon: Icons.task_alt_rounded,
          background: const Color(0xFFE9E5FF),
          foreground: ZyncPalette.plum,
          title: id,
          description: '',
        ),
    };
  }
}

class _QuestCopy {
  const _QuestCopy({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String description;
}

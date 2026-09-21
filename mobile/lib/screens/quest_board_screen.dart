import 'package:flutter/material.dart';

import '../core/cardverse_cloud_client.dart';
import '../core/cardverse_proof_sync.dart';
import '../core/cardverse_reward_grant.dart';
import '../core/cardverse_session_store.dart';
import '../core/local_store.dart';
import '../core/quest_engine.dart';
import '../ui/zync_design.dart';
import 'cardverse_account_lab_screen.dart';

class QuestBoardScreen extends StatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  State<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends State<QuestBoardScreen> {
  late final CardverseCloudClient _cloud;
  late final CardverseSessionStore _sessions;

  bool _loading = true;
  bool _signedIn = false;
  ZyncQuestBoardSnapshot? _snapshot;
  Set<String> _claimedEligibilityKeys = const {};
  String? _claimingKey;
  String? _error;

  String get _locale => Localizations.localeOf(context).toLanguageTag();
  bool get _isZh => _locale.toLowerCase().startsWith('zh');

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
        _error = null;
      });
    }

    try {
      final events = await LocalStore.loadProgressEvents();
      final now = DateTime.now();
      final snapshot = ZyncQuestEngine.evaluate(
        events: events,
        now: now,
        timezoneOffset: now.timeZoneOffset,
      );

      var signedIn = false;
      var claimed = <String>{};
      final session = await _sessions.load();
      if (session != null) {
        signedIn = true;
        try {
          final sync = CardverseProofSync(
            cloud: _cloud,
            sessions: _sessions,
          );
          final syncResult = await sync.syncPending();
          if (syncResult.sessionCleared) {
            signedIn = false;
          } else {
            final inventory =
                await _cloud.fetchInventorySnapshot(session.token);
            claimed = inventory.claimedEligibilityKeys.toSet();
          }
        } on CardverseCloudException catch (error) {
          if (error.failure == CardverseCloudFailure.unauthorized) {
            await _sessions.clear();
            signedIn = false;
          }
          // Quest progress remains useful even if cloud state is unavailable.
        }
      }

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _signedIn = signedIn;
        _claimedEligibilityKeys = Set.unmodifiable(claimed);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _isZh
            ? '暫時讀唔到任務進度。'
            : 'Could not load quest progress.';
      });
    }
  }

  Future<void> _claim(ZyncQuestProgress progress) async {
    final eligibility = progress.eligibility;
    if (eligibility == null || _claimingKey != null) return;

    if (!_signedIn) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const CardverseAccountLabScreen(),
        ),
      );
      await _load();
      return;
    }

    final session = await _sessions.load();
    if (session == null) {
      await _load();
      return;
    }

    setState(() => _claimingKey = eligibility.key);
    try {
      final request = CardverseQuestRewardClaimRequest.fromEligibility(
        eligibility: eligibility,
        idempotencyKey:
            'quest:${eligibility.questId}:${eligibility.cycleStart.millisecondsSinceEpoch}',
      );
      final receipt = await _cloud.claimQuestReward(
        sessionToken: session.token,
        request: request,
      );
      if (!receipt.matchesEligibility(eligibility)) {
        throw const CardverseCloudException(
          failure: CardverseCloudFailure.invalidResponse,
        );
      }
      if (!mounted) return;

      final rewardText = switch (receipt.kind) {
        CardverseRewardGrantKind.drawToken =>
          _isZh ? '${receipt.amount} Draw Token 已到帳' : '${receipt.amount} Draw Token added',
        CardverseRewardGrantKind.standardPack =>
          _isZh ? '標準卡包已加入 My Zync World' : 'Standard Pack added to My Zync World',
        CardverseRewardGrantKind.discoveryPack =>
          _isZh ? '探索卡包已加入 My Zync World' : 'Discovery Pack added to My Zync World',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rewardText)),
      );
      await _load();
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        CardverseCloudFailure.disabled =>
          _isZh
              ? '呢個 QA 環境仲未開啟雲端任務獎勵。'
              : 'Cloud quest rewards are not enabled in this QA environment yet.',
        CardverseCloudFailure.unauthorized =>
          _isZh
              ? 'Cardverse 登入已過期，請重新登入。'
              : 'Your Cardverse session expired. Please sign in again.',
        CardverseCloudFailure.conflict =>
          _isZh
              ? '呢個任務獎勵已經領取。'
              : 'This quest reward was already claimed.',
        _ =>
          _isZh
              ? '今次領取未完成，請稍後再試。'
              : 'The reward claim did not complete. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      if (error.failure == CardverseCloudFailure.unauthorized) {
        await _sessions.clear();
      }
      await _load();
    } finally {
      if (mounted) setState(() => _claimingKey = null);
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
    final lifetime = _snapshot!.progress
        .where(
          (item) => item.definition.cadence == ZyncQuestCadence.lifetime,
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
                            ? '唔需要撳五個 screen、睇廣告或者掛機。每日、每週同永久任務都係靠真人 Zync 同真係一齊做嘢推進。'
                            : 'No tap-grind, ad watching or idle farming. Daily, weekly and lifetime tasks progress through real Zyncs and things you actually do together.',
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
          _sectionHeader(
            icon: Icons.all_inclusive_rounded,
            title: _isZh ? '永久任務' : 'Lifetime',
            subtitle: _isZh
                ? '唔會重設；一路累積你真實世界嘅 Zync 經歷'
                : 'Never resets; it grows with your real-world Zync history',
          ),
          const SizedBox(height: 10),
          for (final item in lifetime) ...[
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
                    _signedIn
                        ? (_isZh
                            ? '完成任務後可以向 Cardverse server 領取獎勵。Server 會重新驗證先發 Draw Token／Pack；手機本機永遠唔可以自己鑄卡。'
                            : 'Completed quests can now be claimed from the Cardverse server. The server revalidates before issuing Draw Tokens or Packs; the phone can never mint inventory itself.')
                        : (_isZh
                            ? '任務進度已經準備好。連接 Cardverse 帳戶之後，完成嘅任務先可以向 server 領取真正獎勵。'
                            : 'Your quest progress is ready. Connect Cardverse to claim real server-issued rewards for completed quests.'),
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
          if (complete && progress.eligibility != null) ...[
            const SizedBox(height: 12),
            _claimAction(progress),
          ],
        ],
      ),
    );
  }

  Widget _claimAction(ZyncQuestProgress progress) {
    final eligibility = progress.eligibility!;
    final claimed = _claimedEligibilityKeys.contains(eligibility.key);
    final busy = _claimingKey == eligibility.key;

    if (claimed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.cloud_done_outlined),
          label: Text(_isZh ? '已領取' : 'Claimed'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: ValueKey('quest-claim-${progress.definition.id}'),
        onPressed: busy ? null : () => _claim(progress),
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _signedIn
                    ? Icons.card_giftcard_rounded
                    : Icons.login_rounded,
              ),
        label: Text(
          _signedIn
              ? (_isZh ? '領取獎勵' : 'Claim reward')
              : (_isZh ? '登入後領取' : 'Sign in to claim'),
        ),
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
          title: _isZh ? '今日 Zync 一次' : 'Make one Zync today',
          description: _isZh
              ? '完成一次面對面 1:1 Zync。'
              : 'Complete one face-to-face 1:1 Zync.',
        ),
      'daily_tried_together' => _QuestCopy(
          icon: Icons.bolt_rounded,
          background: ZyncPalette.peach,
          foreground: ZyncPalette.orangeDeep,
          title: _isZh ? '今日真係一齊做' : 'Actually do it together',
          description: _isZh
              ? '完成一個 Zync Now 揀出嚟嘅活動。'
              : 'Complete an activity chosen by Zync Now.',
        ),
      'daily_two_real_world_actions' => _QuestCopy(
          icon: Icons.directions_walk_rounded,
          background: const Color(0xFFFFE9B7),
          foreground: const Color(0xFF8B5A00),
          title: _isZh ? '今日兩次真實行動' : 'Two real actions today',
          description: _isZh
              ? '1:1 Zync 同 Tried Together 都會計。'
              : 'Both 1:1 Zyncs and Tried Together count.',
        ),
      'weekly_three_zyncs' => _QuestCopy(
          icon: Icons.people_alt_outlined,
          background: ZyncPalette.mint,
          foreground: const Color(0xFF176B57),
          title: _isZh ? '今週 Zync 三次' : 'Three Zyncs this week',
          description: _isZh
              ? '完成三次真人 1:1 Zync。'
              : 'Complete three real 1:1 Zyncs.',
        ),
      'weekly_two_tried_together' => _QuestCopy(
          icon: Icons.bolt_rounded,
          background: ZyncPalette.peach,
          foreground: ZyncPalette.orangeDeep,
          title: _isZh ? '今週做兩次' : 'Do two things together',
          description: _isZh
              ? '真實完成兩個 Zync Now 活動。'
              : 'Complete two Zync Now activities in real life.',
        ),
      'weekly_group_activity' => _QuestCopy(
          icon: Icons.groups_3_outlined,
          background: const Color(0xFFE9E5FF),
          foreground: ZyncPalette.plum,
          title: _isZh ? '約齊一班人' : 'Get a group together',
          description: _isZh
              ? '完成一次三人或以上嘅 Tried Together。'
              : 'Complete one Tried Together activity with 3+ people.',
        ),
      'weekly_five_real_world_actions' => _QuestCopy(
          icon: Icons.explore_outlined,
          background: const Color(0xFFFFE9B7),
          foreground: const Color(0xFF8B5A00),
          title: _isZh ? '今週五次真實行動' : 'Five real-world actions',
          description: _isZh
              ? '今週累積五次 1:1 Zync 或 Tried Together。'
              : 'Complete five 1:1 Zync or Tried Together actions this week.',
        ),
      'lifetime_five_zyncs' => _QuestCopy(
          icon: Icons.handshake_outlined,
          background: ZyncPalette.mint,
          foreground: const Color(0xFF176B57),
          title: _isZh ? '人生頭五次 Zync' : 'Your first five Zyncs',
          description: _isZh
              ? '永久累積完成五次真人 1:1 Zync。'
              : 'Complete five real 1:1 Zyncs over your Zync journey.',
        ),
      'lifetime_three_tried_together' => _QuestCopy(
          icon: Icons.rocket_launch_outlined,
          background: ZyncPalette.peach,
          foreground: ZyncPalette.orangeDeep,
          title: _isZh ? '由傾到做三次' : 'Three times from talk to action',
          description: _isZh
              ? '永久累積完成三次 Tried Together。'
              : 'Complete three Tried Together activities over time.',
        ),
      'lifetime_three_group_activities' => _QuestCopy(
          icon: Icons.diversity_3_outlined,
          background: const Color(0xFFE9E5FF),
          foreground: ZyncPalette.plum,
          title: _isZh ? '群體動起來' : 'Group momentum',
          description: _isZh
              ? '永久累積三次三人或以上嘅活動。'
              : 'Complete three activities with groups of 3+ people.',
        ),
      'lifetime_eight_real_world_actions' => _QuestCopy(
          icon: Icons.public_rounded,
          background: const Color(0xFFFFE9B7),
          foreground: const Color(0xFF8B5A00),
          title: _isZh ? '真實世界八步' : 'Eight steps into real life',
          description: _isZh
              ? '永久累積八次真實 Zync 行動。'
              : 'Complete eight real-world Zync actions over time.',
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

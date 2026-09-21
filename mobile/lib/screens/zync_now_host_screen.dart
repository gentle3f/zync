import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/group_relay_service.dart';
import '../core/local_store.dart';
import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../core/zync_now_consensus.dart';
import '../core/zync_now_constraints_transport.dart';
import '../core/zync_now_engine.dart';
import '../core/zync_now_memory.dart';
import '../core/zync_now_relaxation.dart';
import '../core/zync_now_room_coordinator.dart';
import '../ui/zync_design.dart';
import '../widgets/zync_now_constraints_form.dart';

class ZyncNowHostScreen extends StatefulWidget {
  const ZyncNowHostScreen({
    super.key,
    required this.profile,
    this.relayClient,
  });

  final LocalProfile profile;
  final GroupRelayClient? relayClient;

  @override
  State<ZyncNowHostScreen> createState() => _ZyncNowHostScreenState();
}

class _ZyncNowHostScreenState extends State<ZyncNowHostScreen> {
  late final GroupRelayClient _relay;
  ZyncNowRoomHostCoordinator? _coordinator;
  Timer? _timer;

  bool _creating = true;
  bool _polling = false;
  bool _busy = false;
  bool _showHostConstraints = false;
  bool _hostBallotSubmitted = false;
  bool _activityRecorded = false;
  bool _hidePendingFollowUp = false;
  ZyncNowActivityMemory? _pendingActivity;

  int _contextCount = 0;
  int _ballotCount = 0;
  String? _error;

  final Map<String, ZyncNowVote> _ratings = {};
  final Set<String> _hardVetoes = {};

  String get _locale => Localizations.localeOf(context).toLanguageTag();
  bool get _isZh => _locale.toLowerCase().startsWith('zh');

  @override
  void initState() {
    super.initState();
    _relay = widget.relayClient ?? HttpGroupRelayClient();
    unawaited(_create());
  }

  @override
  void dispose() {
    _timer?.cancel();
    final coordinator = _coordinator;
    if (coordinator != null &&
        coordinator.stage != ZyncNowRoomStage.ended) {
      unawaited(coordinator.close());
    }
    super.dispose();
  }

  Future<void> _create() async {
    try {
      final coordinator = await ZyncNowRoomHostCoordinator.create(
        relay: _relay,
        hostProfile: widget.profile,
        maxParticipants: 8,
      );
      final memories = await LocalStore.loadZyncNowActivities();
      ZyncNowActivityMemory? pending;
      for (final memory in memories) {
        if (memory.status == ZyncNowActivityStatus.chosen) {
          pending = memory;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _coordinator = coordinator;
        _pendingActivity = pending;
        _creating = false;
        _error = null;
      });
      _timer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => unawaited(_refresh()),
      );
      await _refresh();
    } catch (_) {
      _fail();
    }
  }

  Future<void> _refresh() async {
    final coordinator = _coordinator;
    if (coordinator == null || _polling || _busy || !mounted) return;
    _polling = true;
    try {
      switch (coordinator.stage) {
        case ZyncNowRoomStage.lobby:
          await coordinator.refreshLobby();
        case ZyncNowRoomStage.constraintsOpen:
          final collection = await coordinator.collectPrivateContexts();
          _contextCount = collection.contexts.length;
          if (collection.complete) {
            _busy = true;
            try {
              final prior = await LocalStore.recentZyncNowActivityKeys();
              await coordinator.prepareConsensus(
                priorActivityKeys: prior,
                seed: coordinator.room.roomId,
              );
              _ratings.clear();
              _hardVetoes.clear();
            } finally {
              _busy = false;
            }
          }
        case ZyncNowRoomStage.consensusOpen:
          final collection = await coordinator.collectBallots();
          _ballotCount = collection.ballots.length;
        case ZyncNowRoomStage.consensusLocked ||
              ZyncNowRoomStage.result ||
              ZyncNowRoomStage.ended:
          break;
      }
      if (mounted) {
        setState(() => _error = null);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = LocalizedDomainText.groupConnectionIssue(_locale);
        });
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _recordPendingOutcome(
    ZyncNowActivityStatus status,
  ) async {
    final memory = _pendingActivity;
    if (memory == null || status == ZyncNowActivityStatus.chosen) return;
    setState(() => _busy = true);
    try {
      await LocalStore.recordZyncNowOutcome(
        memoryId: memory.id,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _pendingActivity = null;
        _hidePendingFollowUp = false;
      });
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retryRelaxation(
    ZyncNowRelaxationKind kind,
  ) async {
    final coordinator = _coordinator;
    if (coordinator == null || _busy) return;
    setState(() => _busy = true);
    try {
      final prior = await LocalStore.recentZyncNowActivityKeys();
      await coordinator.retryWithRelaxation(
        kind,
        priorActivityKeys: prior,
        seed: coordinator.room.roomId,
      );
      _ratings.clear();
      _hardVetoes.clear();
      _hostBallotSubmitted = false;
      _ballotCount = 0;
      if (mounted) setState(() => _error = null);
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fail() {
    if (!mounted) return;
    setState(() {
      _creating = false;
      _error = LocalizedDomainText.groupConnectionIssue(_locale);
    });
  }

  Future<void> _submitHostContext(ZyncNowPrivateContext context) async {
    final coordinator = _coordinator;
    if (coordinator == null || _busy) return;
    setState(() => _busy = true);
    try {
      await coordinator.openPrivateConstraints(context);
      final collection = await coordinator.collectPrivateContexts();
      if (!mounted) return;
      setState(() {
        _contextCount = collection.contexts.length;
        _showHostConstraints = false;
        _error = null;
      });
      if (collection.complete) {
        final prior = await LocalStore.recentZyncNowActivityKeys();
        await coordinator.prepareConsensus(
          priorActivityKeys: prior,
          seed: coordinator.room.roomId,
        );
        if (mounted) setState(() {});
      }
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitHostBallot() async {
    final coordinator = _coordinator;
    final round = coordinator?.consensusRound;
    if (coordinator == null ||
        round == null ||
        _ratings.length != round.candidates.length ||
        _hostBallotSubmitted) {
      return;
    }

    try {
      coordinator.submitHostBallot(
        ZyncNowConsensusBallot(
          participantId: coordinator.hostParticipant.participantId,
          ratings: Map.unmodifiable(_ratings),
          hardVetoCandidateIds: {
            for (final optionId in _hardVetoes)
              round.candidateIdForOption(optionId),
          },
        ),
      );
      final collection = await coordinator.collectBallots();
      if (!mounted) return;
      setState(() {
        _hostBallotSubmitted = true;
        _ballotCount = collection.ballots.length;
      });
    } catch (_) {
      _fail();
    }
  }

  Future<void> _decide() async {
    final coordinator = _coordinator;
    if (coordinator == null || _busy) return;
    setState(() => _busy = true);
    try {
      await coordinator.lockConsensus();
      final result = await coordinator.resolveConsensus(
        seed: '${coordinator.room.roomId}:consensus',
      );

      if (result.hasDecision) {
        HapticFeedback.heavyImpact();
      }
      if (result.hasDecision && !_activityRecorded) {
        final candidate = coordinator.finalists.firstWhere(
          (item) => item.id == result.chosenCandidateId,
        );
        final memory =
            await LocalStore.recordZyncNowChoice(candidate: candidate);
        _pendingActivity = memory;
        _activityRecorded = true;
      }

      if (mounted) setState(() {});
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
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
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
                child: Row(
                  children: [
                    const ZyncMark(size: 36, strokeWidth: 3.8),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        LocalizedDomainText.zyncNowTitle(_locale),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
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
    if (_creating) {
      return const Center(child: CircularProgressIndicator());
    }

    final coordinator = _coordinator;
    if (coordinator == null) {
      return _message(
        Icons.wifi_off_rounded,
        _error ?? LocalizedDomainText.groupConnectionIssue(_locale),
        action: FilledButton(
          onPressed: () {
            setState(() {
              _creating = true;
              _error = null;
            });
            unawaited(_create());
          },
          child: Text(_isZh ? '再試' : 'Retry'),
        ),
      );
    }

    return switch (coordinator.stage) {
      ZyncNowRoomStage.lobby =>
        _showHostConstraints ? _hostConstraints() : _lobby(coordinator),
      ZyncNowRoomStage.constraintsOpen => _waitingForContexts(coordinator),
      ZyncNowRoomStage.consensusOpen => _consensus(coordinator),
      ZyncNowRoomStage.consensusLocked => _message(
          Icons.lock_clock_outlined,
          _isZh ? '已收齊答案' : 'Everyone answered',
          subtitle: _isZh
              ? 'Zync 正在搵最適合所有人嘅選擇。'
              : 'Zync is finding the best fit for everyone.',
        ),
      ZyncNowRoomStage.result => _result(coordinator),
      ZyncNowRoomStage.ended => _message(
          Icons.check_circle_outline_rounded,
          _isZh ? 'Zync Now 完成' : 'Zync Now complete',
        ),
    };
  }

  Widget _lobby(ZyncNowRoomHostCoordinator coordinator) => ListView(
        key: const ValueKey('zync-now-host-lobby'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          ZyncHeroPanel(
            startColor: const Color(0xFFEFFAF6),
            endColor: const Color(0xFFF2EEFF),
            accentColor: const Color(0xFF176B57),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZyncIconTile(
                  icon: Icons.bolt_rounded,
                  size: 54,
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF176B57),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isZh
                            ? '唔使再問「我哋做咩好？」'
                            : 'Stop asking “what should we do?”',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isZh
                            ? '大家私下講底線，Zync 只帶出全組都接受到嘅選擇。'
                            : 'Everyone sets private boundaries. Zync only brings back options the whole group can accept.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_pendingActivity != null && !_hidePendingFollowUp) ...[
            _pendingFollowUp(),
            const SizedBox(height: 18),
          ],
          ZyncSurface(
            borderColor: ZyncPalette.mint,
            backgroundColor: const Color(0xFFF1FBF7),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: QrImageView(
                    data: coordinator.room.qr.encode(),
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  _isZh
                      ? '其他人用 Zync 嘅「掃描」加入。'
                      : 'Others join using Scan in Zync.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _statusCard(
            icon: Icons.groups_2_outlined,
            text: _isZh
                ? '房間已有 ${coordinator.participantCount} 人'
                : '${coordinator.participantCount} people in the room',
            complete: coordinator.canStart,
          ),
          const SizedBox(height: 12),
          Text(
            coordinator.canStart
                ? (_isZh
                    ? '已經可以開始；其他人喺你鎖房前仍然可以加入。'
                    : 'Ready to start. More people may join until you lock the room.')
                : (_isZh
                    ? '至少要 2 個人先可以開始 Zync Now。'
                    : 'Zync Now needs at least 2 people.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: coordinator.canStart && !_busy
                ? () => setState(() => _showHostConstraints = true)
                : null,
            icon: const Icon(Icons.tune_rounded),
            label: Text(
              _isZh ? '開始，先揀我嘅偏好' : 'Start with my preferences',
            ),
          ),
          if (_error != null) _errorText(),
        ],
      );

  Widget _hostConstraints() => ListView(
        key: const ValueKey('zync-now-host-constraints'),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _showHostConstraints = false),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _isZh ? '你今次想點？' : 'What works for you?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ZyncNowConstraintsForm(
            enabled: !_busy,
            onSubmit: _submitHostContext,
          ),
          if (_error != null) _errorText(),
        ],
      );

  Widget _waitingForContexts(ZyncNowRoomHostCoordinator coordinator) {
    final complete = _contextCount >= coordinator.participantCount;
    return _message(
      Icons.tune_rounded,
      _isZh ? '等大家私下揀' : 'Waiting for private preferences',
      subtitle: _isZh
          ? '已收到 $_contextCount / ${coordinator.participantCount} 份。你睇唔到其他人揀咗咩。'
          : '$_contextCount of ${coordinator.participantCount} submitted. Their choices are not shown to the room.',
      action: complete
          ? const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : null,
    );
  }

  Widget _consensus(ZyncNowRoomHostCoordinator coordinator) {
    final round = coordinator.consensusRound!;
    final complete =
        _hostBallotSubmitted &&
        _ballotCount >= coordinator.participantCount;

    if (_hostBallotSubmitted) {
      return _message(
        Icons.how_to_vote_outlined,
        _isZh ? '等埋其他人投票' : 'Waiting for everyone’s vote',
        subtitle: _isZh
            ? '已收到 $_ballotCount / ${coordinator.participantCount} 票。'
            : '$_ballotCount of ${coordinator.participantCount} ballots received.',
        action: complete
            ? FilledButton.icon(
                onPressed: _busy ? null : _decide,
                icon: const Icon(Icons.bolt_rounded),
                label: Text(_isZh ? 'Zync 幫我哋決定' : 'Let Zync decide'),
              )
            : null,
      );
    }

    return ListView(
      key: ValueKey('zync-now-host-vote-${round.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Text(
          _isZh ? '三個選擇，私下投票' : 'Three options, private vote',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 7),
        Text(
          _isZh
              ? '每個人只評自己接受程度；其他人睇唔到你點揀。'
              : 'Rate only your own comfort. Others do not see your ballot.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < round.candidates.length; i += 1) ...[
          Builder(
            builder: (context) {
              final candidate = round.candidates[i];
              final optionId = round.optionIdForCandidate(candidate.id);
              return ZyncSurface(
                shadow: false,
                borderColor: _hardVetoes.contains(optionId)
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : ZyncPalette.line,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kindBadge(candidate.kind),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            candidate.titleFor(_locale),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      candidate.instructionFor(_locale),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final vote in ZyncNowVote.values)
                          ChoiceChip(
                            label: Text(_voteLabel(vote)),
                            selected: _ratings[candidate.id] == vote,
                            onSelected: (_) {
                              setState(() {
                                _ratings[candidate.id] = vote;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilterChip(
                      label: Text(
                        _isZh
                            ? '呢個真係做唔到'
                            : 'I really can’t do this',
                      ),
                      selected: _hardVetoes.contains(optionId),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _hardVetoes.add(optionId);
                          } else {
                            _hardVetoes.remove(optionId);
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: _ratings.length == round.candidates.length
              ? _submitHostBallot
              : null,
          icon: const Icon(Icons.lock_rounded),
          label: Text(_isZh ? '鎖定我的票' : 'Lock my vote'),
        ),
        if (_error != null) _errorText(),
      ],
    );
  }

  Widget _result(ZyncNowRoomHostCoordinator coordinator) {
    final result = coordinator.result;
    ZyncNowCandidate? chosen;
    if (result?.chosenCandidateId != null) {
      for (final candidate in coordinator.finalists) {
        if (candidate.id == result!.chosenCandidateId) {
          chosen = candidate;
          break;
        }
      }
    }

    if (coordinator.needsRelaxation || chosen == null) {
      final relaxations = coordinator.availableRelaxations;
      return _message(
        Icons.tune_rounded,
        _isZh
            ? '暫時冇一個選擇適合所有人'
            : 'Nothing fits everyone yet',
        subtitle: _isZh
            ? 'Zync 冇忽略任何 hard veto。只可以明確放寬一個 soft preference再試。'
            : 'Zync did not override any hard veto. Explicitly relax one soft preference to try again.',
        action: Column(
          children: [
            if (relaxations.isNotEmpty) ...[
              for (final kind in relaxations) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _retryRelaxation(kind),
                    icon: Icon(_relaxationIcon(kind)),
                    label: Text(_relaxationLabel(kind)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(_isZh ? '今次算啦' : 'Leave it for now'),
            ),
          ],
        ),
      );
    }

    return ListView(
      key: const ValueKey('zync-now-host-result'),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
      children: [
        const Center(
          child: ZyncIconTile(
            icon: Icons.bolt_rounded,
            size: 82,
            backgroundColor: ZyncPalette.mint,
            foregroundColor: Color(0xFF176B57),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isZh ? '今次就做呢個' : 'This is your Zync',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        ZyncHeroPanel(
          startColor: const Color(0xFFEFFAF6),
          endColor: const Color(0xFFF3F0FF),
          accentColor: const Color(0xFF176B57),
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZyncStatusPill(
                icon: Icons.check_circle_rounded,
                label: _isZh ? '全組可接受' : 'Works for the group',
                foregroundColor: const Color(0xFF176B57),
                backgroundColor: Colors.white.withValues(alpha: 0.78),
              ),
              const SizedBox(height: 14),
              Text(
                chosen.titleFor(_locale),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                chosen.instructionFor(_locale),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _isZh
              ? '已經記低今次選擇，之後會降低短期重複機會。'
              : 'Saved locally so Zync can avoid repeating it too soon.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check_rounded),
          label: Text(_isZh ? '就呢個' : 'Let’s do it'),
        ),
      ],
    );
  }

  Widget _pendingFollowUp() {
    final memory = _pendingActivity!;
    final candidate = memory.toCandidate();

    return ZyncSurface(
      backgroundColor: const Color(0xFFFFF7F2),
      borderColor: ZyncPalette.peach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ZyncIconTile(
                icon: Icons.history_rounded,
                backgroundColor: ZyncPalette.peach,
                foregroundColor: ZyncPalette.orangeDeep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isZh ? '上次嗰個，真係做咗未？' : 'Did you do your last Zync?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            candidate.titleFor(_locale),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 7),
          Text(
            candidate.instructionFor(_locale),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _recordPendingOutcome(
                          ZyncNowActivityStatus.completed,
                        ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isZh ? '做咗' : 'Yes, we did it'),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _hidePendingFollowUp = true),
                child: Text(_isZh ? '未做住' : 'Not yet'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _recordPendingOutcome(
                          ZyncNowActivityStatus.skipped,
                        ),
                child: Text(_isZh ? '最後冇做' : 'We skipped it'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kindBadge(ZyncNowCandidateKind kind) {
    final label = switch (kind) {
      ZyncNowCandidateKind.safe => _isZh ? '穩陣' : 'Safe',
      ZyncNowCandidateKind.discovery => _isZh ? '發現' : 'Discovery',
      ZyncNowCandidateKind.wildcard => 'Wildcard',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: switch (kind) {
          ZyncNowCandidateKind.safe => ZyncPalette.mint,
          ZyncNowCandidateKind.discovery => ZyncPalette.peach,
          ZyncNowCandidateKind.wildcard => const Color(0xFFE9E5FF),
        },
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String text,
    required bool complete,
  }) =>
      ZyncSurface(
        shadow: false,
        backgroundColor:
            complete ? const Color(0xFFE8F8F1) : const Color(0xFFF1EEFF),
        borderColor:
            complete ? const Color(0xFFBDECDD) : const Color(0xFFE0D9FF),
        child: Row(
          children: [
            Icon(
              complete ? Icons.check_circle_rounded : icon,
              color: complete
                  ? const Color(0xFF176B57)
                  : ZyncPalette.plum,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );

  Widget _message(
    IconData icon,
    String title, {
    String? subtitle,
    Widget? action,
  }) =>
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ZyncIconTile(
                icon: icon,
                size: 72,
                backgroundColor: const Color(0xFFF1EEFF),
                foregroundColor: ZyncPalette.plum,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 20),
                action,
              ],
              if (_error != null) _errorText(),
            ],
          ),
        ),
      );

  Widget _errorText() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );

  IconData _relaxationIcon(ZyncNowRelaxationKind kind) => switch (kind) {
        ZyncNowRelaxationKind.time => Icons.schedule_rounded,
        ZyncNowRelaxationKind.cost => Icons.payments_outlined,
        ZyncNowRelaxationKind.energy => Icons.directions_run_rounded,
        ZyncNowRelaxationKind.setting => Icons.wb_sunny_outlined,
        ZyncNowRelaxationKind.novelty => Icons.explore_outlined,
      };

  String _relaxationLabel(ZyncNowRelaxationKind kind) {
    if (_isZh) {
      return switch (kind) {
        ZyncNowRelaxationKind.time => '放寬時間',
        ZyncNowRelaxationKind.cost => '放寬預算',
        ZyncNowRelaxationKind.energy => '活動強度都可以',
        ZyncNowRelaxationKind.setting => '室內室外都可以',
        ZyncNowRelaxationKind.novelty => '熟悉／新鮮都可以',
      };
    }
    return switch (kind) {
      ZyncNowRelaxationKind.time => 'Relax time',
      ZyncNowRelaxationKind.cost => 'Relax budget',
      ZyncNowRelaxationKind.energy => 'Any energy level',
      ZyncNowRelaxationKind.setting => 'Indoor or outdoor',
      ZyncNowRelaxationKind.novelty => 'Broaden novelty',
    };
  }

  String _voteLabel(ZyncNowVote vote) => switch (vote) {
        ZyncNowVote.love => _isZh ? '😍 好想做' : '😍 Love',
        ZyncNowVote.okay => _isZh ? '👍 可以' : '👍 Okay',
        ZyncNowVote.no => _isZh ? '✋ 唔想' : '✋ No',
      };
}

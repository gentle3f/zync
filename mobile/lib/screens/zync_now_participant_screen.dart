import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/group_relay_service.dart';
import '../core/group_zync_protocol.dart';
import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../core/zync_now_consensus.dart';
import '../core/zync_now_constraints_transport.dart';
import '../core/zync_now_room_coordinator.dart';
import '../ui/zync_design.dart';
import '../widgets/zync_now_constraints_form.dart';

class ZyncNowParticipantScreen extends StatefulWidget {
  const ZyncNowParticipantScreen({
    super.key,
    required this.profile,
    required this.room,
    this.relayClient,
  });

  final LocalProfile profile;
  final GroupJoinQrPayload room;
  final GroupRelayClient? relayClient;

  @override
  State<ZyncNowParticipantScreen> createState() =>
      _ZyncNowParticipantScreenState();
}

class _ZyncNowParticipantScreenState
    extends State<ZyncNowParticipantScreen> {
  late final GroupRelayClient _relay;
  ZyncNowRoomParticipantCoordinator? _coordinator;
  Timer? _timer;
  bool _joining = true;
  bool _polling = false;
  String? _error;
  final Set<int> _submittedRounds = {};
  final Map<String, ZyncNowVote> _ratings = {};
  final Set<String> _hardVetoes = {};

  String get _locale => Localizations.localeOf(context).toLanguageTag();
  bool get _isZh => _locale.toLowerCase().startsWith('zh');

  @override
  void initState() {
    super.initState();
    _relay = widget.relayClient ?? HttpGroupRelayClient();
    unawaited(_join());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _join() async {
    try {
      final coordinator = await ZyncNowRoomParticipantCoordinator.join(
        relay: _relay,
        room: widget.room,
        profile: widget.profile,
      );
      if (!mounted) return;
      setState(() {
        _coordinator = coordinator;
        _joining = false;
        _error = null;
      });
      _timer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => unawaited(_poll()),
      );
      await _poll();
    } catch (_) {
      _fail();
    }
  }

  Future<void> _poll() async {
    final coordinator = _coordinator;
    if (coordinator == null || _polling || !mounted) return;
    _polling = true;
    try {
      final previous = coordinator.latestState;
      final previousRound = previous?.roundNumber;
      final previousPhase = previous?.phase;
      final state = await coordinator.poll();
      if (!mounted || state == null) return;
      if (previousPhase != state.phase &&
          state.phase == GroupRoomPhase.zyncNowResult) {
        HapticFeedback.heavyImpact();
      }
      if (previousRound != state.roundNumber) {
        _ratings.clear();
        _hardVetoes.clear();
      }
      setState(() => _error = null);
    } on GroupRelayException catch (error) {
      if (error.kind == GroupRelayFailureKind.expired) {
        _timer?.cancel();
      }
      _fail();
    } catch (_) {
      _fail();
    } finally {
      _polling = false;
    }
  }

  void _fail() {
    if (!mounted) return;
    setState(() {
      _joining = false;
      _error = LocalizedDomainText.groupConnectionIssue(_locale);
    });
  }

  Future<void> _submitConstraints(ZyncNowPrivateContext context) async {
    final coordinator = _coordinator;
    final state = coordinator?.latestState;
    if (coordinator == null || state == null) return;
    try {
      await coordinator.submitPrivateContext(context);
      if (!mounted) return;
      setState(() => _submittedRounds.add(state.roundNumber));
    } catch (_) {
      _fail();
    }
  }

  Future<void> _submitVote() async {
    final coordinator = _coordinator;
    final state = coordinator?.latestState;
    if (coordinator == null ||
        state == null ||
        _ratings.length != state.options.length) {
      return;
    }
    try {
      await coordinator.submitConsensus(
        ratingsByOptionId: Map.unmodifiable(_ratings),
        hardVetoOptionIds: Set.unmodifiable(_hardVetoes),
      );
      if (!mounted) return;
      setState(() => _submittedRounds.add(state.roundNumber));
    } catch (_) {
      _fail();
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
    if (_joining) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _coordinator == null) {
      return _message(
        Icons.wifi_off_rounded,
        _error!,
        action: FilledButton(
          onPressed: () {
            setState(() {
              _joining = true;
              _error = null;
            });
            unawaited(_join());
          },
          child: Text(_isZh ? '再試' : 'Retry'),
        ),
      );
    }

    final coordinator = _coordinator!;
    final state = coordinator.latestState;
    if (state == null) {
      return _message(
        Icons.bolt_rounded,
        _isZh ? '已加入 Zync Now' : 'You’re in Zync Now',
        subtitle: _isZh
            ? '等 host 開始。你嘅偏好之後會私下提交。'
            : 'Waiting for the host. Your preferences will be submitted privately.',
      );
    }

    if (state.inputKind == 'zync_now_constraints' &&
        state.phase == GroupRoomPhase.zyncNowInputOpen) {
      if (_submittedRounds.contains(state.roundNumber)) {
        return _waiting(
          _isZh ? '偏好已鎖定' : 'Preferences locked',
          _isZh ? '等埋其他人…' : 'Waiting for everyone else…',
        );
      }
      return ListView(
        key: ValueKey('now-constraints-${state.roundNumber}'),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: [
          Text(
            state.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          Text(
            state.prompt,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ZyncNowConstraintsForm(
            onSubmit: _submitConstraints,
          ),
        ],
      );
    }

    if (state.mechanicType == 'zync_now_consensus' &&
        state.phase == GroupRoomPhase.zyncNowInputOpen) {
      if (_submittedRounds.contains(state.roundNumber)) {
        return _waiting(
          _isZh ? '已投票' : 'Vote locked',
          _isZh ? '等埋其他人…' : 'Waiting for everyone else…',
        );
      }
      return _vote(state);
    }

    if (state.phase == GroupRoomPhase.zyncNowInputLocked) {
      return _waiting(
        _isZh ? '已收齊答案' : 'Everyone answered',
        _isZh
            ? 'Zync 正在搵最適合所有人嘅選擇。'
            : 'Zync is finding the best fit for everyone.',
      );
    }

    if (state.phase == GroupRoomPhase.zyncNowResult) {
      return _result(state);
    }

    return _waiting(
      _isZh ? '等緊下一步…' : 'Waiting for the next step…',
      '',
    );
  }

  Widget _vote(GroupBoundedState state) => ListView(
        key: ValueKey('now-vote-${state.roundNumber}'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Text(
            state.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          Text(
            state.prompt,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            LocalizedDomainText.privateAnswerHint(_locale),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: ZyncPalette.plum),
          ),
          const SizedBox(height: 18),
          for (final option in state.options) ...[
            ZyncSurface(
              shadow: false,
              borderColor: _hardVetoes.contains(option.id)
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : ZyncPalette.line,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final vote in ZyncNowVote.values)
                        ChoiceChip(
                          label: Text(_voteLabel(vote)),
                          selected: _ratings[option.id] == vote,
                          onSelected: (_) {
                            setState(() => _ratings[option.id] = vote);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilterChip(
                    label: Text(
                      _isZh ? '呢個真係做唔到' : 'I really can’t do this',
                    ),
                    selected: _hardVetoes.contains(option.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _hardVetoes.add(option.id);
                        } else {
                          _hardVetoes.remove(option.id);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed:
                _ratings.length == state.options.length ? _submitVote : null,
            icon: const Icon(Icons.lock_rounded),
            label: Text(_isZh ? '鎖定我的票' : 'Lock my vote'),
          ),
        ],
      );

  Widget _result(GroupBoundedState state) {
    GroupBoundedOption? chosen;
    for (final option in state.options) {
      if (option.id == state.resultOptionId) {
        chosen = option;
        break;
      }
    }

    final hasDecision = state.resultOptionId != null;
    return ListView(
      key: ValueKey('zync-now-participant-result-${state.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
      children: [
        ZyncHeroPanel(
          startColor: hasDecision
              ? const Color(0xFFEFFAF6)
              : const Color(0xFFFFF3EB),
          endColor: const Color(0xFFF2EEFF),
          accentColor: hasDecision
              ? const Color(0xFF176B57)
              : ZyncPalette.orange,
          child: Column(
            children: [
              ZyncIconTile(
                icon: hasDecision
                    ? Icons.bolt_rounded
                    : Icons.tune_rounded,
                size: 72,
                backgroundColor: Colors.white,
                foregroundColor: hasDecision
                    ? const Color(0xFF176B57)
                    : ZyncPalette.orangeDeep,
              ),
              const SizedBox(height: 18),
              Text(
                state.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if ((chosen?.label ?? state.prompt).isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  chosen?.label ?? state.prompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check_rounded),
          label: Text(_isZh ? '完成' : 'Done'),
        ),
      ],
    );
  }

  Widget _waiting(String title, String subtitle) => _message(
        Icons.lock_clock_outlined,
        title,
        subtitle: subtitle,
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      );

  String _voteLabel(ZyncNowVote vote) => switch (vote) {
        ZyncNowVote.love => _isZh ? '😍 好想做' : '😍 Love',
        ZyncNowVote.okay => _isZh ? '👍 可以' : '👍 Okay',
        ZyncNowVote.no => _isZh ? '✋ 唔想' : '✋ No',
      };
}

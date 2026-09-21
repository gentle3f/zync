import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/group_relay_service.dart';
import '../core/group_zync_coordinator.dart';
import '../core/group_zync_protocol.dart';
import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../core/zync_now_consensus.dart';
import '../ui/zync_design.dart';

class GroupZyncParticipantScreen extends StatefulWidget {
  const GroupZyncParticipantScreen({
    super.key,
    required this.profile,
    required this.room,
    this.relayClient,
  });

  final LocalProfile profile;
  final GroupJoinQrPayload room;
  final GroupRelayClient? relayClient;

  @override
  State<GroupZyncParticipantScreen> createState() =>
      _GroupZyncParticipantScreenState();
}

class _GroupZyncParticipantScreenState
    extends State<GroupZyncParticipantScreen> {
  late final GroupRelayClient _relay;
  GroupParticipantCoordinator? _coordinator;
  GroupBoundedState? _state;
  Timer? _pollTimer;
  bool _joining = true;
  bool _polling = false;
  bool _submitted = false;
  String? _error;

  final Set<String> _selected = {};
  final Map<String, ZyncNowVote> _ratings = {};
  final List<String> _ranking = [];
  final Set<String> _hardVetoes = {};
  String? _eliminateOptionId;

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  @override
  void initState() {
    super.initState();
    _relay = widget.relayClient ?? HttpGroupRelayClient();
    unawaited(_join());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _join() async {
    try {
      final coordinator = await GroupParticipantCoordinator.join(
        relay: _relay,
        room: widget.room,
        profile: widget.profile,
        shareNickname: true,
      );
      if (!mounted) return;
      setState(() {
        _coordinator = coordinator;
        _joining = false;
        _error = null;
      });
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => unawaited(_poll()),
      );
      await _poll();
    } catch (_) {
      _setError();
    }
  }

  void _setError() {
    if (!mounted) return;
    setState(() {
      _joining = false;
      _error = LocalizedDomainText.groupConnectionIssue(_locale);
    });
  }

  Future<void> _poll() async {
    final coordinator = _coordinator;
    if (coordinator == null || _polling || !mounted) return;
    _polling = true;
    try {
      final next = await coordinator.poll();
      if (!mounted || next == null) return;
      final changedRound =
          _state == null ||
          next.roundNumber != _state!.roundNumber ||
          next.phase != _state!.phase;
      final revealMoment = changedRound &&
          (next.phase == GroupRoomPhase.reveal ||
              next.phase == GroupRoomPhase.reaction ||
              next.phase == GroupRoomPhase.zyncNowResult);
      if (revealMoment) {
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _state = next;
        _error = null;
        if (changedRound) {
          _submitted = false;
          _selected.clear();
          _ratings.clear();
          _ranking.clear();
          _hardVetoes.clear();
          _eliminateOptionId = null;
        }
      });
    } on GroupRelayException catch (error) {
      if (!mounted) return;
      if (error.kind == GroupRelayFailureKind.expired) {
        _pollTimer?.cancel();
      }
      setState(() {
        _error = LocalizedDomainText.groupConnectionIssue(_locale);
      });
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

  Future<void> _submitGroupSelection() async {
    final coordinator = _coordinator;
    final state = _state;
    if (coordinator == null || state == null || _submitted) return;
    try {
      await coordinator.submitSelection(_selected.toList(growable: false));
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (_) {
      _setError();
    }
  }

  Future<void> _submitZyncNow() async {
    final coordinator = _coordinator;
    final state = _state;
    if (coordinator == null || state == null || _submitted) return;

    try {
      final method = state.inputKind;
      if (method == 'zync_now_quick_vote') {
        if (_ratings.length != state.options.length) return;
        await coordinator.submitZyncNowBallot(
          ratingsByOptionId: Map.unmodifiable(_ratings),
          hardVetoOptionIds: Set.unmodifiable(_hardVetoes),
        );
      } else if (method == 'zync_now_rank') {
        if (_ranking.length != state.options.length) return;
        await coordinator.submitZyncNowBallot(
          rankedOptionIds: List.unmodifiable(_ranking),
          hardVetoOptionIds: Set.unmodifiable(_hardVetoes),
        );
      } else if (method == 'zync_now_eliminate_one') {
        final eliminated = _eliminateOptionId;
        if (eliminated == null) return;
        await coordinator.submitZyncNowBallot(
          eliminateOptionId: eliminated,
          hardVetoOptionIds: Set.unmodifiable(_hardVetoes),
        );
      } else {
        throw const FormatException('Unknown Zync Now input kind');
      }
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (_) {
      _setError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _body(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
        child: Row(
          children: [
            const ZyncMark(size: 36, strokeWidth: 3.8),
            const SizedBox(width: 9),
            Text(
              LocalizedDomainText.groupZyncTitle(_locale),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      );

  Widget _body() {
    if (_joining) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _state == null) {
      return _messageState(
        icon: Icons.wifi_off_rounded,
        title: _error!,
        action: FilledButton(
          onPressed: () {
            setState(() {
              _joining = true;
              _error = null;
            });
            unawaited(_join());
          },
          child: Text(_retryLabel()),
        ),
      );
    }

    final state = _state;
    if (state == null) {
      return _messageState(
        icon: Icons.groups_2_outlined,
        title: LocalizedDomainText.waitingForHost(_locale),
        subtitle: LocalizedDomainText.groupReadyCount(
          _coordinator?.participantCount ?? 1,
          widget.room.maxParticipants,
          _locale,
        ),
      );
    }

    if (state.phase == GroupRoomPhase.inputOpen) {
      return _groupInput(state);
    }
    if (state.phase == GroupRoomPhase.zyncNowInputOpen) {
      return _zyncNowInput(state);
    }

    return switch (state.phase) {
      GroupRoomPhase.inputLocked ||
      GroupRoomPhase.zyncNowInputLocked =>
        _messageState(
          icon: Icons.lock_clock_outlined,
          title: state.title.isEmpty
              ? LocalizedDomainText.answerSubmitted(_locale)
              : state.title,
          subtitle: state.prompt,
        ),
      GroupRoomPhase.reveal ||
      GroupRoomPhase.reaction ||
      GroupRoomPhase.complete =>
        _revealState(state),
      GroupRoomPhase.zyncNowResult => _zyncNowResult(state),
      GroupRoomPhase.ended => _messageState(
          icon: Icons.check_circle_outline_rounded,
          title: _completeLabel(),
        ),
      _ => _messageState(
          icon: Icons.groups_2_outlined,
          title: LocalizedDomainText.waitingForHost(_locale),
          subtitle: LocalizedDomainText.groupReadyCount(
            state.participantCount,
            widget.room.maxParticipants,
            _locale,
          ),
        ),
    };
  }

  Widget _groupInput(GroupBoundedState state) {
    if (_submitted) {
      return _messageState(
        icon: Icons.lock_outline_rounded,
        title: LocalizedDomainText.answerSubmitted(_locale),
      );
    }

    return ListView(
      key: ValueKey('group-input-${state.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text(state.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(state.prompt, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text(
          LocalizedDomainText.privateAnswerHint(_locale),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: ZyncPalette.plum),
        ),
        const SizedBox(height: 20),
        for (final option in state.options) ...[
          _optionTile(
            option: option,
            selected: _selected.contains(option.id),
            onTap: () {
              setState(() {
                if (_selected.contains(option.id)) {
                  _selected.remove(option.id);
                } else if (_selected.length < state.requiredSelections) {
                  _selected.add(option.id);
                }
              });
            },
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _selected.length == state.requiredSelections
              ? _submitGroupSelection
              : null,
          icon: const Icon(Icons.lock_rounded),
          label: Text(_lockAnswerLabel(state.requiredSelections)),
        ),
      ],
    );
  }

  Widget _zyncNowInput(GroupBoundedState state) {
    if (_submitted) {
      return _messageState(
        icon: Icons.lock_outline_rounded,
        title: LocalizedDomainText.answerSubmitted(_locale),
      );
    }

    return ListView(
      key: ValueKey('zync-now-input-${state.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text(
          state.title.isEmpty
              ? LocalizedDomainText.zyncNowTitle(_locale)
              : state.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(state.prompt, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text(
          LocalizedDomainText.privateAnswerHint(_locale),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: ZyncPalette.plum),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < state.options.length; i += 1) ...[
          _zyncNowOption(state, state.options[i]),
          const SizedBox(height: 11),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _zyncNowReady(state) ? _submitZyncNow : null,
          icon: const Icon(Icons.lock_rounded),
          label: Text(_lockChoiceLabel()),
        ),
      ],
    );
  }

  Widget _zyncNowOption(
    GroupBoundedState state,
    GroupBoundedOption option,
  ) {
    final method = state.inputKind;
    return ZyncSurface(
      shadow: false,
      borderColor: _hardVetoes.contains(option.id)
          ? Colors.redAccent.withValues(alpha: 0.5)
          : ZyncPalette.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(option.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (method == 'zync_now_quick_vote')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final vote in ZyncNowVote.values)
                  ChoiceChip(
                    label: Text(_voteLabel(vote)),
                    selected: _ratings[option.id] == vote,
                    onSelected: (_) =>
                        setState(() => _ratings[option.id] = vote),
                  ),
              ],
            )
          else if (method == 'zync_now_rank')
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _ranking.remove(option.id);
                  _ranking.add(option.id);
                });
              },
              icon: CircleAvatar(
                radius: 11,
                child: Text(
                  _ranking.contains(option.id)
                      ? '${_ranking.indexOf(option.id) + 1}'
                      : '–',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              label: Text(
                _ranking.contains(option.id)
                    ? _rankLabel(_ranking.indexOf(option.id) + 1)
                    : _rankHint(),
              ),
            )
          else
            ChoiceChip(
              label: Text(_eliminateLabel()),
              selected: _eliminateOptionId == option.id,
              onSelected: (_) =>
                  setState(() => _eliminateOptionId = option.id),
            ),
          const SizedBox(height: 8),
          FilterChip(
            label: Text(_hardVetoLabel()),
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
    );
  }

  bool _zyncNowReady(GroupBoundedState state) => switch (state.inputKind) {
        'zync_now_quick_vote' => _ratings.length == state.options.length,
        'zync_now_rank' => _ranking.length == state.options.length,
        'zync_now_eliminate_one' => _eliminateOptionId != null,
        _ => false,
      };

  Widget _revealState(GroupBoundedState state) => ListView(
        key: ValueKey(
          'group-reveal-${state.roundNumber}-${state.phase.name}',
        ),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          ZyncHeroPanel(
            startColor: const Color(0xFFFFF2E8),
            endColor: const Color(0xFFF2EEFF),
            accentColor: ZyncPalette.orange,
            child: Column(
              children: [
                const ZyncIconTile(
                  icon: Icons.auto_awesome_rounded,
                  size: 68,
                  backgroundColor: Colors.white,
                  foregroundColor: ZyncPalette.orangeDeep,
                ),
                const SizedBox(height: 18),
                Text(
                  state.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  state.prompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          if (state.followUp.isNotEmpty) ...[
            const SizedBox(height: 16),
            ZyncSurface(
              backgroundColor: const Color(0xFFF1EEFF),
              borderColor: const Color(0xFFE0D9FF),
              child: Text(
                state.followUp,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ],
      );

  Widget _zyncNowResult(GroupBoundedState state) {
    GroupBoundedOption? chosen;
    for (final option in state.options) {
      if (option.id == state.resultOptionId) {
        chosen = option;
        break;
      }
    }

    return ListView(
      key: ValueKey('zync-now-result-${state.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 32),
      children: [
        ZyncHeroPanel(
          startColor: const Color(0xFFEFFAF6),
          endColor: const Color(0xFFF2EEFF),
          accentColor: const Color(0xFF176B57),
          child: Column(
            children: [
              const ZyncIconTile(
                icon: Icons.bolt_rounded,
                size: 72,
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF176B57),
              ),
              const SizedBox(height: 18),
              Text(
                state.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                chosen?.label ?? state.prompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (chosen != null && state.prompt.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  state.prompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _optionTile({
    required GroupBoundedOption option,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: selected ? ZyncPalette.peach : ZyncPalette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? ZyncPalette.orange : ZyncPalette.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? ZyncPalette.orangeDeep
                      : ZyncPalette.inkSoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _messageState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) =>
      Center(
        key: ValueKey('$icon-$title'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ZyncIconTile(
                icon: icon,
                size: 68,
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
                const SizedBox(height: 22),
                action,
              ],
            ],
          ),
        ),
      );

  bool get _isZh => _locale.toLowerCase().startsWith('zh');

  String _retryLabel() => _isZh ? '再試' : 'Retry';

  String _completeLabel() => _isZh ? '今次 Zync 完成' : 'Zync complete';

  String _lockAnswerLabel(int count) => _isZh
      ? (count == 1 ? '鎖定答案' : '鎖定 $count 個答案')
      : (count == 1 ? 'Lock answer' : 'Lock $count answers');

  String _lockChoiceLabel() => _isZh ? '鎖定我的選擇' : 'Lock my choice';

  String _voteLabel(ZyncNowVote vote) => switch (vote) {
        ZyncNowVote.love => _isZh ? '😍 好想做' : '😍 Love',
        ZyncNowVote.okay => _isZh ? '👍 可以' : '👍 Okay',
        ZyncNowVote.no => _isZh ? '✋ 唔想' : '✋ No',
      };

  String _rankLabel(int rank) => _isZh ? '第 $rank 位' : 'Rank $rank';

  String _rankHint() => _isZh ? '按你想做嘅次序逐個揀' : 'Tap in your preferred order';

  String _eliminateLabel() => _isZh ? '淘汰呢個' : 'Eliminate this';

  String _hardVetoLabel() =>
      _isZh ? '呢個我真係做唔到' : 'I really can’t do this';
}

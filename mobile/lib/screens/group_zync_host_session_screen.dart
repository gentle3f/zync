import 'dart:async';

import 'package:flutter/material.dart';

import '../core/group_zync_coordinator.dart';
import '../core/group_zync_protocol.dart';
import '../core/local_store.dart';
import '../core/localized_domain_text.dart';
import '../core/zync_now_consensus.dart';
import '../core/zync_now_engine.dart';
import '../ui/zync_design.dart';

class GroupZyncHostSessionScreen extends StatefulWidget {
  const GroupZyncHostSessionScreen({
    super.key,
    required this.coordinator,
  });

  final GroupHostCoordinator coordinator;

  @override
  State<GroupZyncHostSessionScreen> createState() =>
      _GroupZyncHostSessionScreenState();
}

class _GroupZyncHostSessionScreenState
    extends State<GroupZyncHostSessionScreen> {
  Timer? _timer;
  bool _polling = false;
  bool _busy = false;
  String? _error;

  final Set<String> _hostSelections = {};
  bool _hostSubmitted = false;
  int _submittedCount = 0;
  final Map<String, int> _targetCounts = {};

  ZyncNowMode? _zyncNowMode;
  final Map<String, ZyncNowVote> _hostRatings = {};
  bool _hostConsensusSubmitted = false;
  int _consensusSubmittedCount = 0;
  bool _activityRecorded = false;

  GroupHostCoordinator get _host => widget.coordinator;
  String get _locale => Localizations.localeOf(context).toLanguageTag();
  bool get _isZh => _locale.toLowerCase().startsWith('zh');

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => unawaited(_refresh()),
    );
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_host.session.phase != GroupRoomPhase.ended) {
      unawaited(_host.end());
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_polling || !mounted) return;
    _polling = true;
    try {
      if (_host.session.phase == GroupRoomPhase.inputOpen) {
        final collection = await _host.collectRoundInputs();
        _submittedCount = collection.inputs.length;
      } else if (_host.session.phase == GroupRoomPhase.zyncNowInputOpen) {
        final collection = await _host.collectZyncNowBallots();
        _consensusSubmittedCount = collection.ballots.length;
      }
      if (mounted) setState(() => _error = null);
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

  Future<void> _submitRoundAnswer() async {
    final round = _host.activeRound;
    if (round == null || _hostSubmitted) return;
    try {
      _host.submitHostSelection(_hostSelections.toList(growable: false));
      final collection = await _host.collectRoundInputs();
      if (!mounted) return;
      setState(() {
        _hostSubmitted = true;
        _submittedCount = collection.inputs.length;
      });
    } catch (_) {
      _fail();
    }
  }

  Future<void> _reveal() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_host.session.phase == GroupRoomPhase.inputOpen) {
        await _host.lockInput();
      }
      await _host.reveal();
      if (mounted) setState(() {});
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reaction() async {
    try {
      await _host.openReaction();
      if (mounted) setState(() {});
    } catch (_) {
      _fail();
    }
  }

  Future<void> _completeRound() async {
    try {
      final targets = _host.activeRound?.targetParticipantIds ?? const [];
      for (final id in targets) {
        _targetCounts[id] = (_targetCounts[id] ?? 0) + 1;
      }
      await _host.completeRound();
      if (mounted) setState(() {});
    } catch (_) {
      _fail();
    }
  }

  Future<void> _anotherRound() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _host.prepareNextRound(
        seed: '${_host.room.roomId}:${_host.session.roundNumber + 1}',
        previousTargetCounts: _targetCounts,
      );
      _hostSelections.clear();
      _hostSubmitted = false;
      _submittedCount = 0;
      if (mounted) setState(() {});
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerZyncNow() async {
    try {
      await _host.offerZyncNow();
      if (!mounted) return;
      setState(() {
        _zyncNowMode = null;
        _hostRatings.clear();
        _hostConsensusSubmitted = false;
        _consensusSubmittedCount = 0;
      });
    } catch (_) {
      _fail();
    }
  }

  Future<void> _chooseMode(ZyncNowMode mode) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _zyncNowMode = mode;
      _error = null;
    });
    try {
      final prior = await LocalStore.recentZyncNowActivityKeys();
      final candidates = _host.generateZyncNow(
        mode: mode,
        priorActivityKeys: prior,
        seed: '${_host.room.roomId}:now:${mode.name}',
        limit: 3,
      );
      if (candidates.length < 2) {
        if (!mounted) return;
        setState(() {
          _error = _isZh
              ? '呢個模式暫時得一個強選擇，試下另一個模式。'
              : 'This mode only has one strong option. Try another mode.';
        });
        return;
      }

      await _host.startZyncNowConsensus(
        candidates: candidates.take(3).toList(growable: false),
        method: ZyncNowConsensusMethod.quickVote,
      );
      if (!mounted) return;
      setState(() {
        _hostRatings.clear();
        _hostConsensusSubmitted = false;
        _consensusSubmittedCount = 0;
      });
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitHostConsensus() async {
    final round = _host.activeZyncNowConsensus;
    if (round == null ||
        _hostRatings.length != round.candidates.length ||
        _hostConsensusSubmitted) {
      return;
    }
    try {
      _host.submitHostZyncNowBallot(
        ZyncNowConsensusBallot(
          participantId: _host.hostParticipant.participantId,
          ratings: Map.unmodifiable(_hostRatings),
        ),
      );
      final collection = await _host.collectZyncNowBallots();
      if (!mounted) return;
      setState(() {
        _hostConsensusSubmitted = true;
        _consensusSubmittedCount = collection.ballots.length;
      });
    } catch (_) {
      _fail();
    }
  }

  Future<void> _decide() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _host.lockZyncNowConsensus();
      final result = await _host.resolveZyncNowConsensus(
        seed: '${_host.room.roomId}:decision',
      );
      if (result.hasDecision && !_activityRecorded) {
        final round = _host.activeZyncNowConsensus!;
        final candidate = round.candidates.firstWhere(
          (item) => item.id == result.chosenCandidateId,
        );
        await LocalStore.recordZyncNowChoice(candidate: candidate);
        _activityRecorded = true;
      }
      if (mounted) setState(() {});
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fail() {
    if (!mounted) return;
    setState(() {
      _error = LocalizedDomainText.groupConnectionIssue(_locale);
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
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
                child: Row(
                  children: [
                    const ZyncMark(size: 36, strokeWidth: 3.8),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        LocalizedDomainText.groupZyncTitle(_locale),
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
    return switch (_host.session.phase) {
      GroupRoomPhase.inputOpen ||
      GroupRoomPhase.inputLocked =>
        _roundInput(),
      GroupRoomPhase.reveal ||
      GroupRoomPhase.reaction =>
        _revealView(),
      GroupRoomPhase.complete => _afterRound(),
      GroupRoomPhase.zyncNowOptional => _modePicker(),
      GroupRoomPhase.zyncNowInputOpen ||
      GroupRoomPhase.zyncNowInputLocked =>
        _consensus(),
      GroupRoomPhase.zyncNowResult => _result(),
      _ => _center(
          Icons.hourglass_top_rounded,
          _isZh ? '準備緊…' : 'Preparing…',
        ),
    };
  }

  Widget _roundInput() {
    final round = _host.activeRound!;
    final locked = _host.session.phase == GroupRoomPhase.inputLocked;

    if (!round.input.privateInputRequired || locked) {
      return _center(
        Icons.auto_awesome_rounded,
        round.title,
        subtitle: round.prompt,
        action: FilledButton.icon(
          onPressed: _busy ? null : _reveal,
          icon: const Icon(Icons.visibility_rounded),
          label: Text(_isZh ? '揭曉' : 'Reveal'),
        ),
      );
    }

    final complete =
        _hostSubmitted &&
        _submittedCount >= _host.session.participantCount;

    return ListView(
      key: ValueKey('host-input-${_host.session.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Text(round.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(round.prompt, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text(
          LocalizedDomainText.privateAnswerHint(_locale),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: ZyncPalette.plum),
        ),
        const SizedBox(height: 18),
        if (!_hostSubmitted) ...[
          for (final option in round.input.options) ...[
            _selectTile(
              id: option.id,
              label: option.label,
              selected: _hostSelections.contains(option.id),
              maxSelections: round.input.requiredSelections,
            ),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed:
                _hostSelections.length == round.input.requiredSelections
                    ? _submitRoundAnswer
                    : null,
            icon: const Icon(Icons.lock_rounded),
            label: Text(_isZh ? '鎖定我的答案' : 'Lock my answer'),
          ),
        ] else ...[
          _progress(
            _isZh
                ? '已收到 $_submittedCount / ${_host.session.participantCount} 個答案'
                : '$_submittedCount of ${_host.session.participantCount} answers received',
            complete,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: complete && !_busy ? _reveal : null,
            icon: const Icon(Icons.visibility_rounded),
            label: Text(_isZh ? '收齊，揭曉' : 'Reveal'),
          ),
        ],
        if (_error != null) _errorText(),
      ],
    );
  }

  Widget _revealView() {
    final round = _host.activeRound!;
    final reaction = _host.session.phase == GroupRoomPhase.reaction;
    return ListView(
      key: ValueKey('host-reveal-${_host.session.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(22, 40, 22, 30),
      children: [
        const Center(
          child: ZyncIconTile(
            icon: Icons.auto_awesome_rounded,
            size: 76,
            backgroundColor: ZyncPalette.peach,
            foregroundColor: ZyncPalette.orangeDeep,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          round.revealTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          round.revealBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (reaction) ...[
          const SizedBox(height: 18),
          ZyncSurface(
            backgroundColor: const Color(0xFFF1EEFF),
            borderColor: const Color(0xFFE0D9FF),
            child: Text(
              round.followUp,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: reaction ? _completeRound : _reaction,
          icon: Icon(
            reaction
                ? Icons.check_circle_outline_rounded
                : Icons.chat_bubble_outline_rounded,
          ),
          label: Text(
            reaction
                ? (_isZh ? '完成呢一回合' : 'Finish this round')
                : (_isZh ? '一齊回應' : 'React together'),
          ),
        ),
      ],
    );
  }

  Widget _afterRound() => _center(
        Icons.hub_outlined,
        _isZh ? '下一步？' : 'What next?',
        subtitle: _isZh
            ? '再發現一個連結，或者直接解決「我哋做咩好？」'
            : 'Discover another connection, or solve “what should we do?” now.',
        action: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _anotherRound,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(LocalizedDomainText.anotherGroupRound(_locale)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _offerZyncNow,
                icon: const Icon(Icons.bolt_rounded),
                label: Text(LocalizedDomainText.zyncNowGroupCta(_locale)),
              ),
            ),
          ],
        ),
      );

  Widget _modePicker() => ListView(
        key: const ValueKey('host-zync-now-modes'),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          Text(
            LocalizedDomainText.zyncNowTitle(_locale),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          Text(
            LocalizedDomainText.zyncNowGroupCta(_locale),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          for (final mode in ZyncNowMode.values) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _busy ? null : () => _chooseMode(mode),
                borderRadius: BorderRadius.circular(20),
                child: ZyncSurface(
                  shadow: false,
                  child: Row(
                    children: [
                      ZyncIconTile(
                        icon: _modeIcon(mode),
                        backgroundColor:
                            mode == ZyncNowMode.surprise
                                ? const Color(0xFFE9E5FF)
                                : ZyncPalette.peach,
                        foregroundColor:
                            mode == ZyncNowMode.surprise
                                ? ZyncPalette.plum
                                : ZyncPalette.orangeDeep,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          _modeLabel(mode),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_busy && _zyncNowMode == mode)
                        const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_error != null) _errorText(),
        ],
      );

  Widget _consensus() {
    final round = _host.activeZyncNowConsensus!;
    final locked =
        _host.session.phase == GroupRoomPhase.zyncNowInputLocked;
    final complete =
        _hostConsensusSubmitted &&
        _consensusSubmittedCount >= _host.session.participantCount;

    return ListView(
      key: ValueKey('host-consensus-${round.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Text(
          LocalizedDomainText.zyncNowTitle(_locale),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _isZh
              ? '每個人私下評價，Zync 幫全組搵最合理選擇。'
              : 'Everyone rates privately. Zync finds the best fit.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        if (!_hostConsensusSubmitted && !locked) ...[
          for (final candidate in round.candidates) ...[
            ZyncSurface(
              shadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.titleFor(_locale),
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
                          selected: _hostRatings[candidate.id] == vote,
                          onSelected: (_) {
                            setState(() {
                              _hostRatings[candidate.id] = vote;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed:
                _hostRatings.length == round.candidates.length
                    ? _submitHostConsensus
                    : null,
            icon: const Icon(Icons.lock_rounded),
            label: Text(_isZh ? '鎖定我的評價' : 'Lock my ratings'),
          ),
        ] else ...[
          _progress(
            _isZh
                ? '已收到 $_consensusSubmittedCount / ${_host.session.participantCount} 票'
                : '$_consensusSubmittedCount of ${_host.session.participantCount} ballots received',
            complete,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: complete && !locked && !_busy ? _decide : null,
            icon: const Icon(Icons.bolt_rounded),
            label: Text(_isZh ? 'Zync 幫我哋決定' : 'Let Zync decide'),
          ),
          if (locked)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
        if (_error != null) _errorText(),
      ],
    );
  }

  Widget _result() {
    final result = _host.zyncNowConsensusResult;
    final round = _host.activeZyncNowConsensus;
    ZyncNowCandidate? chosen;
    if (result?.chosenCandidateId != null && round != null) {
      for (final candidate in round.candidates) {
        if (candidate.id == result!.chosenCandidateId) {
          chosen = candidate;
          break;
        }
      }
    }

    return _center(
      Icons.bolt_rounded,
      result?.status == ZyncNowConsensusStatus.needsRelaxation
          ? (_isZh ? '未有一個選擇適合所有人' : 'Nothing fits everyone yet')
          : (_isZh ? '今次就做呢個' : 'This is your Zync'),
      subtitle:
          chosen?.titleFor(_locale) ??
          (_isZh ? '今次先放寬一個條件再試。' : 'Relax one constraint and try again.'),
      action: result?.hasDecision == true
          ? FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded),
              label: Text(_isZh ? '完成' : 'Done'),
            )
          : null,
    );
  }

  Widget _selectTile({
    required String id,
    required String label,
    required bool selected,
    required int maxSelections,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (_hostSelections.contains(id)) {
                _hostSelections.remove(id);
              } else if (_hostSelections.length < maxSelections) {
                _hostSelections.add(id);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: selected ? ZyncPalette.peach : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? ZyncPalette.orange : ZyncPalette.line,
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
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _progress(String title, bool complete) => ZyncSurface(
        backgroundColor:
            complete ? const Color(0xFFE8F8F1) : const Color(0xFFF1EEFF),
        borderColor:
            complete ? const Color(0xFFBDECDD) : const Color(0xFFE0D9FF),
        child: Row(
          children: [
            Icon(
              complete
                  ? Icons.check_circle_rounded
                  : Icons.how_to_vote_outlined,
              color: complete
                  ? const Color(0xFF176B57)
                  : ZyncPalette.plum,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );

  Widget _center(
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
              if (subtitle != null) ...[
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

  IconData _modeIcon(ZyncNowMode mode) => switch (mode) {
        ZyncNowMode.familiar => Icons.favorite_outline_rounded,
        ZyncNowMode.passThePassion => Icons.swap_horiz_rounded,
        ZyncNowMode.newToEveryone => Icons.explore_outlined,
        ZyncNowMode.meetInTheMiddle => Icons.merge_type_rounded,
        ZyncNowMode.surprise => Icons.casino_outlined,
      };

  String _modeLabel(ZyncNowMode mode) {
    if (_isZh) {
      return switch (mode) {
        ZyncNowMode.familiar => '大家本身都鍾意',
        ZyncNowMode.passThePassion => '一個識，其他人試',
        ZyncNowMode.newToEveryone => '全部人都未試過',
        ZyncNowMode.meetInTheMiddle => '將大家興趣混埋',
        ZyncNowMode.surprise => 'Surprise us',
      };
    }
    return switch (mode) {
      ZyncNowMode.familiar => 'Something we already like',
      ZyncNowMode.passThePassion => 'One knows, others discover',
      ZyncNowMode.newToEveryone => 'New to everyone',
      ZyncNowMode.meetInTheMiddle => 'Meet in the middle',
      ZyncNowMode.surprise => 'Surprise us',
    };
  }

  String _voteLabel(ZyncNowVote vote) => switch (vote) {
        ZyncNowVote.love => _isZh ? '😍 好想做' : '😍 Love',
        ZyncNowVote.okay => _isZh ? '👍 可以' : '👍 Okay',
        ZyncNowVote.no => _isZh ? '✋ 唔想' : '✋ No',
      };
}

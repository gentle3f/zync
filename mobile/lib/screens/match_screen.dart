import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ai_service.dart';
import '../core/analytics_service.dart';
import '../core/interest_catalog.dart';
import '../core/language_support.dart';
import '../core/local_store.dart';
import '../core/models.dart';
import '../core/zync_alias.dart';
import '../core/zync_session_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

/// Unified post-scan Zync Session: impact, one connection, conversation, recap.
class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    required this.peer,
    required this.match,
    required this.newMatchCount,
    this.sessionSeed = '',
    this.previousSharedIds = const {},
    this.isRepeatPeer = false,
    this.localIsMatchMine = true,
  });

  final QrProfilePayload peer;
  final MatchResult match;
  final int newMatchCount;
  final String sessionSeed;
  final Set<String> previousSharedIds;
  final bool isRepeatPeer;
  final bool localIsMatchMine;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  static const _qaDebug = bool.fromEnvironment(
    'ZYNC_QA_DEBUG',
    defaultValue: false,
  );

  final _ai = const AiService();
  late final List<ZyncConnection> _connections;
  late final ZyncCrossover? _crossover;
  final Map<String, AiQuestionResult> _questions = {};
  final Set<String> _loadingQuestions = {};

  Timer? _impactTimer;
  bool _impactDone = false;
  bool _recap = false;
  bool _exploreHub = false;
  MatchResult? _activeExploreMatch;
  String? _activeExploreKey;
  String? _activeExploreLabel;
  String _activeExploreKind = 'about';
  bool? _activeOwnerIsMatchMine;
  int _revealedIndex = -1;
  ConversationMode _mode = ConversationMode.fun;

  @override
  void initState() {
    super.initState();
    _connections = ZyncSessionService.exactConnections(
      widget.match,
      previousSharedIds: widget.previousSharedIds,
      markNewConnections: widget.isRepeatPeer,
      sessionSeed: widget.sessionSeed,
    );
    _crossover = ZyncSessionService.bestCrossover(
      widget.match,
      sessionSeed: widget.sessionSeed,
    );
    _impactTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _impactDone = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ensureQuestion(prefetch: true));
    });
  }

  @override
  void dispose() {
    _impactTimer?.cancel();
    super.dispose();
  }

  String get _peerName => ZyncAlias.displayName(
        nickname: widget.peer.nickname,
        localId: widget.peer.localId,
        locale: Localizations.localeOf(context).toLanguageTag(),
      );

  ZyncConnection? get _currentConnection =>
      _revealedIndex >= 0 && _revealedIndex < _connections.length
          ? _connections[_revealedIndex]
          : null;

  String _baseConnectionKey() {
    if (_activeExploreKey != null) return _activeExploreKey!;
    final current = _currentConnection;
    if (current != null) return 'shared:${current.id}';
    return _crossover?.connectionKey ?? '';
  }

  String _questionMapKey() => '${_baseConnectionKey()}|${_mode.name}';

  Future<void> _ensureQuestion({bool prefetch = false}) async {
    if (_connections.isNotEmpty && _revealedIndex < 0 && !prefetch) return;

    final match = _activeExploreMatch ??
        (_connections.isNotEmpty
            ? (_revealedIndex >= 0
                ? _connections[_revealedIndex].focusedMatch
                : _connections.first.focusedMatch)
            : _crossover?.focusedMatch);
    final connectionKey = _activeExploreKey ??
        (_connections.isNotEmpty
            ? (_revealedIndex >= 0
                ? 'shared:${_connections[_revealedIndex].id}'
                : 'shared:${_connections.first.id}')
            : _crossover?.connectionKey);
    if (match == null || connectionKey == null || connectionKey.isEmpty) return;

    final mapKey = '$connectionKey|${_mode.name}';
    final existing = _questions[mapKey];
    if (existing?.fromAi == true) {
      if (!prefetch) unawaited(_rememberQuestion(connectionKey, existing!));
      return;
    }
    if (_loadingQuestions.contains(mapKey)) return;

    final language = Localizations.localeOf(context).toLanguageTag();
    final requestedMode = _mode;
    final fallback = existing ??
        _ai.localFallback(
          language: language,
          secondaryLanguage: widget.peer.language,
          match: match,
        );

    if (mounted) {
      setState(() {
        _questions[mapKey] = fallback;
        _loadingQuestions.add(mapKey);
      });
    } else {
      _questions[mapKey] = fallback;
      _loadingQuestions.add(mapKey);
    }

    AiQuestionResult? aiResult;
    for (var attempt = 0; attempt < 3 && aiResult == null; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: attempt == 1 ? 900 : 2200));
        if (!mounted) return;
      }
      aiResult = await _ai.generateAiQuestion(
        language: language,
        secondaryLanguage: widget.peer.language,
        mode: requestedMode,
        match: match,
        sessionSeed: widget.sessionSeed,
        connectionKey: connectionKey,
      );
    }
    if (!mounted) return;

    final finalResult = aiResult ?? fallback;
    setState(() {
      _questions[mapKey] = finalResult;
      _loadingQuestions.remove(mapKey);
    });

    if (!prefetch || _baseConnectionKey() == connectionKey) {
      unawaited(_rememberQuestion(connectionKey, finalResult));
    }

    unawaited(
      ZyncAnalytics.instance.track(
        AnalyticsEvent.questionGenerated,
        properties: {
          'mode': requestedMode.name,
          'source': finalResult.fromAi ? 'ai' : 'fallback',
          'match_type': _connections.isEmpty ? 'crossover' : 'shared',
          'bilingual': finalResult.secondaryQuestion?.isNotEmpty ?? false,
        },
      ),
    );
  }

  Future<void> _rememberQuestion(
    String connectionKey,
    AiQuestionResult result,
  ) async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    String? label;
    if (connectionKey.startsWith('shared:')) {
      final id = connectionKey.substring('shared:'.length);
      label = InterestCatalog.byId(id)?.labelFor(locale) ?? id;
    } else if (_crossover != null && connectionKey == _crossover!.connectionKey) {
      final mine = InterestCatalog.byId(_crossover!.mine.id)?.labelFor(locale) ??
          _crossover!.mine.customLabel ??
          _crossover!.mine.id;
      final theirs =
          InterestCatalog.byId(_crossover!.theirs.id)?.labelFor(locale) ??
              _crossover!.theirs.customLabel ??
              _crossover!.theirs.id;
      label = '$mine × $theirs';
    }

    await LocalStore.recordQuestion(
      peerId: widget.peer.localId,
      memory: ZyncQuestionMemory(
        connectionKey: connectionKey,
        question: result.question,
        secondaryQuestion: result.secondaryQuestion,
        connectionLabel: label,
        mode: _mode.name,
        kind: connectionKey.startsWith('shared:') ? 'shared' : 'crossover',
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _revealFirst() async {
    if (_connections.isEmpty || !mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _revealedIndex = 0);
    unawaited(_ensureQuestion());
  }

  Future<void> _revealAnother() async {
    if (_revealedIndex + 1 >= _connections.length) {
      setState(() => _recap = true);
      return;
    }
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _revealedIndex += 1;
      _mode = ConversationMode.fun;
    });
    unawaited(_ensureQuestion());
  }

  Future<void> _pickMode() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<ConversationMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.changeVibe, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ConversationMode.values.map((mode) {
                  return ChoiceChip(
                    label: Text(_modeLabel(l10n, mode)),
                    selected: mode == _mode,
                    onSelected: (_) => Navigator.of(context).pop(mode),
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == _mode || !mounted) return;
    setState(() => _mode = picked);
    unawaited(
      ZyncAnalytics.instance.track(
        AnalyticsEvent.modeSelected,
        properties: {'mode': picked.name},
      ),
    );
    unawaited(_ensureQuestion());
  }

  void _finish() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    if (!_impactDone) return _impactScreen(context);
    if (_recap) return _recapScreen(context);
    if (_connections.isEmpty) return _crossoverScreen(context);
    if (_revealedIndex < 0) return _hiddenScreen(context);
    return _connectionScreen(context);
  }

  Widget _shell(BuildContext context, Widget child) {
    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Row(
                  children: [
                    const ZyncMark(size: 36, strokeWidth: 3.8),
                    const SizedBox(width: 9),
                    Text('Zync', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: _finish,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _impactScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exact = _connections.isNotEmpty;
    return _shell(
      context,
      Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 10, 26, 42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.86, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Opacity(
                opacity: ((value - 0.86) / 0.14).clamp(0, 1),
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: exact ? ZyncPalette.peach : const Color(0xFFE9E5FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: exact
                      ? const ZyncMark(size: 72, strokeWidth: 6.2)
                      : const Icon(Icons.hub_outlined, size: 52, color: ZyncPalette.plum),
                ),
                const SizedBox(height: 26),
                Text(
                  exact ? l10n.youZync : l10n.differentInterests,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  exact ? l10n.hiddenConnections(_connections.length) : l10n.stillConnection,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ZyncPalette.inkSoft,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                Text(_peerName, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hiddenScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _shell(
      context,
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZyncIconTile(
                icon: Icons.visibility_off_outlined,
                size: 72,
                backgroundColor: Color(0xFFFFEEE5),
                foregroundColor: ZyncPalette.orangeDeep,
              ),
              const SizedBox(height: 22),
              Text(
                l10n.hiddenConnections(_connections.length),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 9),
              Text(
                _peerName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('zync-reveal-first'),
                  onPressed: _revealFirst,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(l10n.revealConnection),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _connectionScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final connection = _connections[_revealedIndex];
    final detail = connection.primary;
    final local = widget.localIsMatchMine ? detail.mine : detail.theirs;
    final peer = widget.localIsMatchMine ? detail.theirs : detail.mine;
    final label = InterestCatalog.byId(detail.id)?.labelFor(locale) ??
        detail.merged.customLabel ??
        detail.id;
    final questionKey = _questionMapKey();
    final result = _questions[questionKey];
    final loading = _loadingQuestions.contains(questionKey);
    final last = _revealedIndex == _connections.length - 1;

    return _shell(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.connectionProgress(_revealedIndex + 1, _connections.length),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: ZyncPalette.inkSoft),
                ),
              ),
              if (connection.isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: ZyncPalette.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.newConnection,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF176B57),
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          KeyedSubtree(
            key: ValueKey('zync-connection-${connection.id}'),
            child: ZyncSurface(
              borderColor: ZyncPalette.peach,
              backgroundColor: const Color(0xFFFFF7F2),
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
              child: Column(
              children: [
                const ZyncIconTile(
                  icon: Icons.auto_awesome_rounded,
                  size: 58,
                  backgroundColor: ZyncPalette.peach,
                  foregroundColor: ZyncPalette.orangeDeep,
                ),
                const SizedBox(height: 18),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.12),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.strengthContrast(
                    _strengthLabel(l10n, local.strength),
                    _peerName,
                    _strengthLabel(l10n, peer.strength),
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
                ),
                if (connection.context.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 7,
                    runSpacing: 7,
                    children: connection.context.map((contextItem) {
                      final contextLabel = InterestCatalog.byId(contextItem.id)?.labelFor(locale) ??
                          contextItem.merged.customLabel ??
                          contextItem.id;
                      return Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(contextLabel),
                      );
                    }).toList(growable: false),
                  ),
                ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _questionCard(context, result: result, loading: loading),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickMode,
            icon: const Icon(Icons.tune_rounded),
            label: Text('${l10n.changeVibe}: ${_modeLabel(l10n, _mode)}'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('zync-next-connection'),
            onPressed: _revealAnother,
            icon: Icon(last ? Icons.check_rounded : Icons.visibility_outlined),
            label: Text(last ? l10n.sessionRecap : l10n.revealAnother),
          ),
        ],
      ),
    );
  }

  Widget _crossoverScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final crossover = _crossover;
    if (crossover == null) {
      return _shell(
        context,
        Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(l10n.stillConnection, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    String label(SelectedInterest item) =>
        InterestCatalog.byId(item.id)?.labelFor(locale) ?? item.customLabel ?? item.id;
    final result = _questions[_questionMapKey()];
    final loading = _loadingQuestions.contains(_questionMapKey());

    return _shell(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            l10n.stillConnection,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          ZyncSurface(
            borderColor: const Color(0xFFE5DFFF),
            backgroundColor: const Color(0xFFF7F4FF),
            child: Column(
              children: [
                Text(l10n.crossoverIntro, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 14),
                Text(
                  '${label(crossover.mine)}  ×  ${label(crossover.theirs)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _questionCard(context, result: result, loading: loading),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickMode,
            icon: const Icon(Icons.tune_rounded),
            label: Text('${l10n.changeVibe}: ${_modeLabel(l10n, _mode)}'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => setState(() => _recap = true),
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.sessionRecap),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(
    BuildContext context, {
    required AiQuestionResult? result,
    required bool loading,
  }) {
    final l10n = AppLocalizations.of(context);
    final secondary = result?.secondaryQuestion;
    return ZyncSurface(
      padding: const EdgeInsets.all(20),
      borderColor: const Color(0xFFE5DFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ZyncIconTile(
                icon: Icons.chat_bubble_outline_rounded,
                size: 42,
                backgroundColor: Color(0xFFE9E5FF),
                foregroundColor: ZyncPalette.plum,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(l10n.talkAboutThis, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading || result == null)
            Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.3),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.findingQuestion)),
              ],
            )
          else ...[
            Text(
              result.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.4),
            ),
            if (secondary != null && secondary.isNotEmpty) ...[
              const SizedBox(height: 17),
              Divider(color: ZyncPalette.line.withValues(alpha: 0.9)),
              const SizedBox(height: 12),
              Text(
                ZyncLanguage.nativeName(result.secondaryLanguage ?? widget.peer.language),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: ZyncPalette.plum),
              ),
              const SizedBox(height: 7),
              Text(
                secondary,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.4),
              ),
            ],
            if (_qaDebug) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    result.fromAi ? Icons.auto_awesome_rounded : Icons.offline_bolt_outlined,
                    size: 15,
                  ),
                  label: Text(result.fromAi ? 'AI' : 'Local fallback'),
                ),
              ),
            ],
            if (!result.fromAi && !loading) ...[
              const SizedBox(height: 10),
              Text(
                l10n.aiUnavailable,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ZyncPalette.inkSoft),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _recapScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final count = _connections.isNotEmpty ? _connections.length : (_crossover == null ? 0 : 1);

    final labels = _connections.isNotEmpty
        ? _connections
            .map(
              (connection) =>
                  InterestCatalog.byId(connection.id)?.labelFor(locale) ??
                  connection.primary.merged.customLabel ??
                  connection.id,
            )
            .toList(growable: false)
        : _crossover == null
            ? const <String>[]
            : <String>[
                '${InterestCatalog.byId(_crossover.mine.id)?.labelFor(locale) ?? _crossover.mine.customLabel ?? _crossover.mine.id} × '
                    '${InterestCatalog.byId(_crossover.theirs.id)?.labelFor(locale) ?? _crossover.theirs.customLabel ?? _crossover.theirs.id}',
              ];

    return _shell(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
        children: [
          const Center(
            child: ZyncIconTile(
              icon: Icons.favorite_rounded,
              size: 72,
              backgroundColor: ZyncPalette.peach,
              foregroundColor: ZyncPalette.orangeDeep,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.sessionRecap,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sessionRecapCount(count, _peerName),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 9,
            runSpacing: 9,
            children: labels
                .map(
                  (label) => Chip(
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 17),
                    label: Text(label),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: _finish,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.finishZync),
          ),
        ],
      ),
    );
  }

  String _strengthLabel(AppLocalizations l10n, InterestStrength strength) => switch (strength) {
        InterestStrength.love => l10n.love,
        InterestStrength.like => l10n.like,
        InterestStrength.wantToTry => l10n.wantToTry,
      };

  String _modeLabel(AppLocalizations l10n, ConversationMode mode) => switch (mode) {
        ConversationMode.easy => l10n.modeEasy,
        ConversationMode.fun => l10n.modeFun,
        ConversationMode.debate => l10n.modeDebate,
        ConversationMode.deep => l10n.modeDeep,
        ConversationMode.guess => l10n.modeGuess,
        ConversationMode.surprise => l10n.modeSurprise,
      };
}

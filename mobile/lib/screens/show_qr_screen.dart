import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/analytics_service.dart';
import '../core/local_store.dart';
import '../core/matching_service.dart';
import '../core/models.dart';
import '../core/relay_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';
import 'match_screen.dart';

class ShowQrScreen extends StatefulWidget {
  const ShowQrScreen({
    super.key,
    required this.profile,
    this.relayClient,
    this.bootstrapFactory,
  });

  final LocalProfile profile;
  final RelayClient? relayClient;
  final RelayBootstrap Function(LocalProfile profile)? bootstrapFactory;

  @override
  State<ShowQrScreen> createState() => _ShowQrScreenState();
}

enum _HostRelayStatus { preparing, waiting, connectionIssue, expired, startIssue }

class _ShowQrScreenState extends State<ShowQrScreen> with WidgetsBindingObserver {
  late final RelayClient _relay;
  RelayBootstrap? _bootstrap;
  String? _payload;
  Timer? _pollTimer;
  _HostRelayStatus _status = _HostRelayStatus.preparing;
  bool _polling = false;
  bool _sessionCreated = false;
  bool _leavingForMatch = false;
  int _pollAttempt = 0;

  @override
  void initState() {
    super.initState();
    _relay = widget.relayClient ?? HttpRelayClient();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startSession());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final bootstrap = _bootstrap;
      if (bootstrap != null && _sessionCreated && DateTime.now().toUtc().isBefore(bootstrap.expiresAt)) {
        unawaited(_pollNow());
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    final bootstrap = _bootstrap;
    if (bootstrap != null && _sessionCreated && !_leavingForMatch) {
      unawaited(_relay.cancel(sessionId: bootstrap.sessionId, hostToken: bootstrap.hostToken));
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    _pollTimer?.cancel();
    final old = _bootstrap;
    if (old != null && _sessionCreated) {
      unawaited(_relay.cancel(sessionId: old.sessionId, hostToken: old.hostToken));
    }

    final bootstrap = widget.bootstrapFactory?.call(widget.profile) ?? RelayBootstrap.generate(widget.profile);
    if (!mounted) return;
    setState(() {
      _bootstrap = bootstrap;
      _payload = null;
      _status = _HostRelayStatus.preparing;
      _sessionCreated = false;
      _pollAttempt = 0;
    });

    try {
      await _relay.createSession(
        sessionId: bootstrap.sessionId,
        hostToken: bootstrap.hostToken,
        expiresAt: bootstrap.expiresAt,
      );
      if (!mounted || _bootstrap?.sessionId != bootstrap.sessionId) return;
      final payload = bootstrap.qr.encode();
      setState(() {
        _payload = payload;
        _sessionCreated = true;
        _status = _HostRelayStatus.waiting;
      });
      unawaited(
        ZyncAnalytics.instance.track(
          AnalyticsEvent.qrGenerated,
          properties: {
            'interest_count': widget.profile.interests.length,
            'transport': 'handshake_v2',
          },
        ),
      );
      _schedulePoll(const Duration(milliseconds: 700));
    } catch (_) {
      if (!mounted || _bootstrap?.sessionId != bootstrap.sessionId) return;
      setState(() => _status = _HostRelayStatus.startIssue);
    }
  }

  void _schedulePoll([Duration? delay]) {
    _pollTimer?.cancel();
    if (!mounted || !_sessionCreated || _leavingForMatch) return;
    final bootstrap = _bootstrap;
    if (bootstrap == null) return;
    if (!DateTime.now().toUtc().isBefore(bootstrap.expiresAt)) {
      setState(() => _status = _HostRelayStatus.expired);
      return;
    }
    final nextDelay = delay ?? switch (_pollAttempt) {
      < 10 => const Duration(milliseconds: 1300),
      < 30 => const Duration(milliseconds: 2400),
      _ => const Duration(seconds: 5),
    };
    _pollTimer = Timer(nextDelay, () => unawaited(_pollNow()));
  }

  Future<void> _pollNow() async {
    if (_polling || !mounted || !_sessionCreated || _leavingForMatch) return;
    final bootstrap = _bootstrap;
    if (bootstrap == null) return;
    if (!DateTime.now().toUtc().isBefore(bootstrap.expiresAt)) {
      _pollTimer?.cancel();
      setState(() => _status = _HostRelayStatus.expired);
      return;
    }

    _polling = true;
    _pollAttempt += 1;
    try {
      final result = await _relay.take(
        sessionId: bootstrap.sessionId,
        hostToken: bootstrap.hostToken,
      );
      if (!mounted || _bootstrap?.sessionId != bootstrap.sessionId) return;
      if (!result.isReady) {
        if (_status != _HostRelayStatus.waiting) {
          setState(() => _status = _HostRelayStatus.waiting);
        }
        _schedulePoll();
        return;
      }

      final peer = await RelayCrypto.decryptPeerResponse(
        bootstrap: bootstrap,
        opaquePayload: result.payload!,
      );
      if (peer.localId == widget.profile.localId) {
        await _relay.consume(sessionId: bootstrap.sessionId, hostToken: bootstrap.hostToken);
        if (!mounted) return;
        setState(() => _status = _HostRelayStatus.startIssue);
        return;
      }

      final match = MatchingService.compare(
        bootstrap.hostProfile.interests,
        peer.interests,
        sessionSeed: bootstrap.sessionId,
      );
      final previous = await LocalStore.findHistory(peer.localId);
      final previousIds = previous?.previousSharedIds.toSet() ?? <String>{};
      final currentIds = match.shared.map((item) => item.id).toSet();
      final newCount = currentIds.difference(previousIds).length;
      await LocalStore.recordZync(
        peerId: peer.localId,
        peerNickname: peer.nickname,
        sharedIds: currentIds.toList(),
      );
      await _relay.consume(sessionId: bootstrap.sessionId, hostToken: bootstrap.hostToken);

      final analytics = <Future<void>>[
        ZyncAnalytics.instance.track(
          AnalyticsEvent.matchComplete,
          properties: {
            'has_match': match.shared.isNotEmpty,
            'repeat_peer': previous != null,
          },
        ),
        ZyncAnalytics.instance.track(
          AnalyticsEvent.matchCount,
          properties: {'count': match.shared.length},
        ),
        if (previous != null)
          ZyncAnalytics.instance.track(
            AnalyticsEvent.zyncAgain,
            properties: {'prior_sessions': previous.sessionCount},
          ),
      ];
      unawaited(Future.wait(analytics));

      if (!mounted) return;
      _leavingForMatch = true;
      _sessionCreated = false;
      _pollTimer?.cancel();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MatchScreen(
            peer: peer,
            match: match,
            newMatchCount: previous == null ? 0 : newCount,
            sessionSeed: bootstrap.sessionId,
          ),
        ),
      );
    } on RelayException catch (error) {
      if (!mounted || _bootstrap?.sessionId != bootstrap.sessionId) return;
      if (error.kind == RelayFailureKind.expired) {
        _pollTimer?.cancel();
        setState(() => _status = _HostRelayStatus.expired);
      } else if (error.kind == RelayFailureKind.invalid) {
        setState(() => _status = _HostRelayStatus.startIssue);
      } else {
        setState(() => _status = _HostRelayStatus.connectionIssue);
        _schedulePoll(const Duration(seconds: 3));
      }
    } on FormatException {
      if (!mounted || _bootstrap?.sessionId != bootstrap.sessionId) return;
      await _relay.consume(sessionId: bootstrap.sessionId, hostToken: bootstrap.hostToken);
      if (!mounted) return;
      setState(() => _status = _HostRelayStatus.startIssue);
    } catch (_) {
      if (!mounted || _bootstrap?.sessionId != bootstrap.sessionId) return;
      setState(() => _status = _HostRelayStatus.connectionIssue);
      _schedulePoll(const Duration(seconds: 3));
    } finally {
      _polling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.showMyQr)),
      body: ConnectionBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final normalOneScreen = constraints.maxHeight >= 650 && textScale <= 1.15;
              final content = _buildContent(
                context,
                l10n,
                compact: constraints.maxHeight < 760,
              );
              if (normalOneScreen) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: content,
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n, {
    required bool compact,
  }) {
    final payload = _payload;
    final statusText = switch (_status) {
      _HostRelayStatus.preparing => l10n.zyncing,
      _HostRelayStatus.waiting => l10n.waitingForScan,
      _HostRelayStatus.connectionIssue => l10n.relayConnectionIssue,
      _HostRelayStatus.expired => l10n.relayExpired,
      _HostRelayStatus.startIssue => l10n.relayStartIssue,
    };
    final canRegenerate = _status == _HostRelayStatus.expired || _status == _HostRelayStatus.startIssue;
    final markSize = compact ? 48.0 : 56.0;
    final qrMax = compact ? 214.0 : 250.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ZyncMark(size: markSize, strokeWidth: compact ? 4.7 : 5.3),
        SizedBox(height: compact ? 10 : 16),
        Text(
          l10n.readyToZync,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.tagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
        ),
        SizedBox(height: compact ? 14 : 20),
        ZyncSurface(
          padding: EdgeInsets.all(compact ? 11 : 14),
          radius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: ZyncPalette.line),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final qrSize = constraints.maxWidth.clamp(170.0, qrMax).toDouble();
                    if (payload == null) {
                      return SizedBox(
                        width: qrSize,
                        height: qrSize,
                        child: const Center(
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(strokeWidth: 2.8),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: QrImageView(
                        data: payload,
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        size: qrSize,
                        padding: EdgeInsets.zero,
                        gapless: true,
                        semanticsLabel: l10n.showMyQr,
                        errorStateBuilder: (context, error) => SizedBox(
                          width: qrSize,
                          height: qrSize,
                          child: Center(
                            child: Text(
                              l10n.invalidQr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: ZyncPalette.ink,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: ZyncPalette.ink,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (widget.profile.nickname.isNotEmpty) ...[
                SizedBox(height: compact ? 10 : 14),
                Text(widget.profile.nickname, style: Theme.of(context).textTheme.titleLarge),
              ],
              SizedBox(height: compact ? 9 : 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Container(
                  key: ValueKey(_status),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: canRegenerate ? ZyncPalette.peach : ZyncPalette.cream,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        canRegenerate ? Icons.refresh_rounded : Icons.lock_clock_outlined,
                        size: 19,
                        color: canRegenerate ? ZyncPalette.orangeDeep : ZyncPalette.inkSoft,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(statusText, style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
              if (canRegenerate) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _startSession,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.regenerateQr),
                  ),
                ),
              ],
              SizedBox(height: compact ? 8 : 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 17, color: ZyncPalette.inkSoft),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.qrPrivacy,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

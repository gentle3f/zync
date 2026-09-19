import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/group_relay_service.dart';
import '../core/group_zync_coordinator.dart';
import '../core/group_zync_protocol.dart';
import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../ui/zync_design.dart';
import 'group_zync_host_session_screen.dart';

class GroupZyncHostLobbyScreen extends StatefulWidget {
  const GroupZyncHostLobbyScreen({
    super.key,
    required this.profile,
    this.relayClient,
  });

  final LocalProfile profile;
  final GroupRelayClient? relayClient;

  @override
  State<GroupZyncHostLobbyScreen> createState() =>
      _GroupZyncHostLobbyScreenState();
}

class _GroupZyncHostLobbyScreenState
    extends State<GroupZyncHostLobbyScreen> {
  late final GroupRelayClient _relay;
  GroupHostCoordinator? _coordinator;
  Timer? _timer;
  bool _creating = true;
  bool _polling = false;
  bool _starting = false;
  bool _handedOff = false;
  String? _error;

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
    if (!_handedOff &&
        coordinator != null &&
        coordinator.session.phase != GroupRoomPhase.ended) {
      unawaited(coordinator.end());
    }
    super.dispose();
  }

  Future<void> _create() async {
    try {
      final coordinator = await GroupHostCoordinator.create(
        relay: _relay,
        hostProfile: widget.profile,
        maxParticipants: 8,
        shareNickname: true,
      );
      if (!mounted) return;
      setState(() {
        _coordinator = coordinator;
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
    if (coordinator == null || _polling || _starting || !mounted) return;
    _polling = true;
    try {
      await coordinator.refreshLobby();
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

  void _fail() {
    if (!mounted) return;
    setState(() {
      _creating = false;
      _error = LocalizedDomainText.groupConnectionIssue(_locale);
    });
  }

  Future<void> _start() async {
    final coordinator = _coordinator;
    if (coordinator == null || !coordinator.session.canStart || _starting) {
      return;
    }
    setState(() => _starting = true);
    try {
      await coordinator.prepareNextRound(
        seed: '${coordinator.room.roomId}:1',
      );
      if (!mounted) return;
      _timer?.cancel();
      _handedOff = true;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GroupZyncHostSessionScreen(
            coordinator: coordinator,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = LocalizedDomainText.groupConnectionIssue(_locale);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = _coordinator;
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
              Expanded(
                child: coordinator == null
                    ? _loading()
                    : _lobby(coordinator),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loading() {
    if (_creating) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ZyncIconTile(
              icon: Icons.wifi_off_rounded,
              size: 68,
              backgroundColor: Color(0xFFF1EEFF),
              foregroundColor: ZyncPalette.plum,
            ),
            const SizedBox(height: 18),
            Text(
              _error ?? LocalizedDomainText.groupConnectionIssue(_locale),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                setState(() {
                  _creating = true;
                  _error = null;
                });
                unawaited(_create());
              },
              child: Text(_isZh ? '再試' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lobby(GroupHostCoordinator coordinator) {
    final session = coordinator.session;
    return ListView(
      key: const ValueKey('group-host-lobby'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text(
          LocalizedDomainText.groupZyncSubtitle(_locale),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 18),
        ZyncSurface(
          borderColor: ZyncPalette.peach,
          backgroundColor: const Color(0xFFFFF7F2),
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
              const SizedBox(height: 14),
              Text(
                LocalizedDomainText.groupHostHint(_locale),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const ZyncIconTile(
              icon: Icons.groups_2_outlined,
              backgroundColor: ZyncPalette.mint,
              foregroundColor: Color(0xFF176B57),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocalizedDomainText.groupReadyCount(
                  session.participantCount,
                  session.maxParticipants,
                  _locale,
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: session.participants.values.map((presence) {
            final name = presence.profile.nickname.trim();
            final id = presence.profile.participantId;
            final short = id.substring(0, id.length < 4 ? id.length : 4);
            return Chip(
              avatar: const Icon(Icons.person_outline_rounded, size: 18),
              label: Text(name.isEmpty ? 'Zync $short' : name),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 18),
        Text(
          session.canStart
              ? LocalizedDomainText.everyoneReady(_locale)
              : LocalizedDomainText.groupNeedThree(_locale),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: session.canStart
                    ? const Color(0xFF176B57)
                    : ZyncPalette.inkSoft,
              ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('group-start-round'),
          onPressed: session.canStart && !_starting ? _start : null,
          icon: _starting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(LocalizedDomainText.startFirstRound(_locale)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/local_store.dart';
import '../core/matching_service.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import 'match_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key, required this.profile});
  final LocalProfile profile;

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handle(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.map((barcode) => barcode.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final peer = QrProfilePayload.decode(raw);
      if (peer.localId == widget.profile.localId) {
        throw const FormatException('Cannot Zync with yourself');
      }
      final match = MatchingService.compare(widget.profile.interests, peer.interests);
      final previous = await LocalStore.findHistory(peer.localId);
      final previousIds = previous?.previousSharedIds.toSet() ?? <String>{};
      final currentIds = match.shared.map((item) => item.id).toSet();
      final newCount = currentIds.difference(previousIds).length;
      await LocalStore.recordZync(
        peerId: peer.localId,
        peerNickname: peer.nickname,
        sharedIds: currentIds.toList(),
      );
      await _controller.stop();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MatchScreen(peer: peer, match: match, newMatchCount: previous == null ? 0 : newCount),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = AppLocalizations.of(context).invalidQr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handle),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: Card(
              color: Colors.black.withValues(alpha: 0.72),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? l10n.scanHint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    if (_processing) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

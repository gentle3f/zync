import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/local_store.dart';
import '../core/matching_service.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';
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

  Future<void> _retryCamera() async {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _error = null;
    });
    try {
      if (_controller.value.isRunning) {
        await _controller.stop();
      }
      await _controller.start();
    } catch (_) {
      // MobileScanner keeps the structured camera error in controller.value;
      // the errorBuilder below renders the localized recovery UI.
    }
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          l10n.scanTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handle,
            errorBuilder: (context, error) => ScannerPreviewErrorState(
              error: error,
              onRetry: _retryCamera,
            ),
            placeholderBuilder: (context) => const ColoredBox(
              color: Colors.black,
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: ZyncPalette.orange,
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, cameraState, _) {
              if (!cameraState.isInitialized || cameraState.error != null) {
                return const SizedBox.shrink();
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: Container(color: Colors.black.withValues(alpha: 0.22)),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: SizedBox(
                        width: 278,
                        height: 278,
                        child: CustomPaint(painter: const _ScannerFramePainter()),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 236,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ZyncPalette.orange.withValues(alpha: 0),
                              ZyncPalette.orange,
                              ZyncPalette.orange.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ZyncPalette.orange.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 26,
                    child: SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ZyncPalette.ink.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (_error == null ? ZyncPalette.orange : Colors.redAccent)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _error == null ? Icons.qr_code_scanner_rounded : Icons.error_outline_rounded,
                                color: _error == null ? ZyncPalette.orange : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error ?? l10n.scanHint,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                              ),
                            ),
                            if (_processing) ...[
                              const SizedBox(width: 12),
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: ZyncPalette.orange,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ScannerPreviewErrorState extends StatelessWidget {
  const ScannerPreviewErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissionDenied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final unsupported = error.errorCode == MobileScannerErrorCode.unsupported;
    final title = permissionDenied
        ? l10n.cameraPermissionTitle
        : unsupported
            ? l10n.cameraUnavailableTitle
            : l10n.cameraErrorTitle;
    final body = permissionDenied
        ? l10n.cameraPermissionBody
        : unsupported
            ? l10n.cameraUnavailableBody
            : l10n.cameraErrorBody;
    final icon = permissionDenied
        ? Icons.no_photography_outlined
        : unsupported
            ? Icons.videocam_off_outlined
            : Icons.camera_alt_outlined;

    return ColoredBox(
      color: ZyncPalette.ink,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 96, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ZyncSurface(
                padding: const EdgeInsets.all(24),
                radius: 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: ZyncPalette.peach,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 34, color: ZyncPalette.orangeDeep),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: ZyncPalette.inkSoft,
                            height: 1.45,
                          ),
                    ),
                    if (!unsupported) ...[
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 28.0;
    const length = 50.0;
    const stroke = 5.0;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = ZyncPalette.orange.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, radius + length)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(radius + length, 0)
      ..moveTo(size.width - radius - length, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, radius + length)
      ..moveTo(size.width, size.height - radius - length)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(size.width, size.height, size.width - radius, size.height)
      ..lineTo(size.width - radius - length, size.height)
      ..moveTo(radius + length, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, size.height - radius - length);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

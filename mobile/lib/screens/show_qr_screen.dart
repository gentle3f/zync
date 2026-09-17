import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/analytics_service.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

class ShowQrScreen extends StatefulWidget {
  const ShowQrScreen({super.key, required this.profile});
  final LocalProfile profile;

  @override
  State<ShowQrScreen> createState() => _ShowQrScreenState();
}

class _ShowQrScreenState extends State<ShowQrScreen> {
  late final String _payload;

  @override
  void initState() {
    super.initState();
    _payload = QrProfilePayload.fromProfile(widget.profile).encode();
    unawaited(
      ZyncAnalytics.instance.track(
        AnalyticsEvent.qrGenerated,
        properties: {
          'interest_count': widget.profile.interests.length,
          'transport': _payload.startsWith(QrProfilePayload.compressedPrefix) ? 'compressed' : 'legacy',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.showMyQr)),
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              child: Column(
                children: [
                  const ZyncMark(size: 58, strokeWidth: 5.5),
                  const SizedBox(height: 18),
                  Text(
                    l10n.readyToZync,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
                  ),
                  const SizedBox(height: 28),
                  ZyncSurface(
                    padding: const EdgeInsets.all(14),
                    radius: 30,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: ZyncPalette.line),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final qrSize = constraints.maxWidth.clamp(180.0, 300.0).toDouble();
                              return Center(
                                child: QrImageView(
                                  data: _payload,
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
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: ZyncPalette.orangeDeep),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.invalidQr,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
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
                          const SizedBox(height: 18),
                          Text(widget.profile.nickname, style: Theme.of(context).textTheme.titleLarge),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: ZyncPalette.cream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 19, color: ZyncPalette.inkSoft),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  l10n.qrPrivacy,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

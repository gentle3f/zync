import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

class ShowQrScreen extends StatelessWidget {
  const ShowQrScreen({super.key, required this.profile});
  final LocalProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payload = QrProfilePayload.fromProfile(profile).encode();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.showMyQr)),
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
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
                    padding: const EdgeInsets.all(18),
                    radius: 30,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: ZyncPalette.line),
                          ),
                          child: QrImageView(
                            data: payload,
                            version: QrVersions.auto,
                            size: 272,
                            gapless: false,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: ZyncPalette.ink,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: ZyncPalette.ink,
                            ),
                          ),
                        ),
                        if (profile.nickname.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(profile.nickname, style: Theme.of(context).textTheme.titleLarge),
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

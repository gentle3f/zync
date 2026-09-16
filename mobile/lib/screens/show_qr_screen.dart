import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';

class ShowQrScreen extends StatelessWidget {
  const ShowQrScreen({super.key, required this.profile});
  final LocalProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payload = QrProfilePayload.fromProfile(profile).encode();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.showMyQr)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.readyToZync, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 270,
                      gapless: false,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (profile.nickname.isNotEmpty)
                  Text(profile.nickname, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(l10n.qrPrivacy, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

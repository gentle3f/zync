import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';
import 'history_screen.dart';
import 'interest_dna_screen.dart';
import 'interest_setup_screen.dart';
import 'scan_qr_screen.dart';
import 'show_qr_screen.dart';

const _privacyUrl = String.fromEnvironment('ZYNC_PRIVACY_URL');

Uri? _configuredPrivacyUri() {
  final uri = Uri.tryParse(_privacyUrl.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

Future<void> _openPrivacyPolicy(BuildContext context, Uri uri, String failureMessage) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  final LocalProfile profile;
  final Future<void> Function(LocalProfile profile) onProfileChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = profile.nickname.trim();
    final greeting = name.isEmpty ? l10n.homeGreeting : '${l10n.homeGreeting} $name';
    final privacyUri = _configuredPrivacyUri();

    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Row(
                children: [
                  const ZyncMark(size: 38, strokeWidth: 4),
                  const SizedBox(width: 10),
                  Text('Zync', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: l10n.edit,
                    onPressed: () async {
                      final result = await Navigator.of(context).push<LocalProfile>(
                        MaterialPageRoute(
                          builder: (_) => InterestSetupScreen(
                            profile: profile,
                            onSaved: onProfileChanged,
                            editing: true,
                          ),
                        ),
                      );
                      if (result != null) await onProfileChanged(result);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(greeting, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                l10n.interestsCount(profile.interests.length),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
              ),
              const SizedBox(height: 24),
              ZyncSurface(
                padding: EdgeInsets.zero,
                borderColor: ZyncPalette.peach,
                backgroundColor: const Color(0xFFFFF3EB),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: IgnorePointer(child: ConnectionBackdrop())),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ZyncIconTile(
                                  icon: Icons.auto_awesome_rounded,
                                  size: 52,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.zyncWithSomeone, style: Theme.of(context).textTheme.titleLarge),
                                      const SizedBox(height: 5),
                                      Text(l10n.tagline, style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: _PrimaryAction(
                                    icon: Icons.qr_code_2_rounded,
                                    label: l10n.showMyQr,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => ShowQrScreen(profile: profile)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SecondaryAction(
                                    icon: Icons.qr_code_scanner_rounded,
                                    label: l10n.scanSomeone,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => ScanQrScreen(profile: profile)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _MenuTile(
                icon: Icons.favorite_outline_rounded,
                iconBackground: ZyncPalette.peach,
                iconForeground: ZyncPalette.orangeDeep,
                title: l10n.myInterests,
                subtitle: l10n.interestsCount(profile.interests.length),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InterestSetupScreen(
                      profile: profile,
                      onSaved: onProfileChanged,
                      editing: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.people_alt_outlined,
                iconBackground: ZyncPalette.mint,
                iconForeground: const Color(0xFF167A62),
                title: l10n.peopleHistory,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.bubble_chart_outlined,
                iconBackground: const Color(0xFFE9E5FF),
                iconForeground: ZyncPalette.plum,
                title: l10n.interestDna,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => InterestDnaScreen(profile: profile)),
                ),
              ),
              if (privacyUri != null) ...[
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.privacy_tip_outlined,
                  iconBackground: const Color(0xFFE8F0FF),
                  iconForeground: const Color(0xFF315F9E),
                  title: l10n.privacyPolicy,
                  onTap: () {
                    _openPrivacyPolicy(context, privacyUri, l10n.privacyPolicyUnavailable);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, maxLines: 2, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 62),
          backgroundColor: ZyncPalette.ink,
          foregroundColor: Colors.white,
        ),
      );
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, maxLines: 2, textAlign: TextAlign.center),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 62),
          backgroundColor: Colors.white.withValues(alpha: 0.8),
        ),
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: ZyncPalette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ZyncPalette.line),
            ),
            child: Row(
              children: [
                ZyncIconTile(
                  icon: icon,
                  backgroundColor: iconBackground,
                  foregroundColor: iconForeground,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ZyncPalette.inkSoft),
              ],
            ),
          ),
        ),
      );
}

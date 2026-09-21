import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';
import 'group_zync_host_lobby_screen.dart';
import 'history_screen.dart';
import 'interest_dna_screen.dart';
import 'interest_setup_screen.dart';
import 'my_zync_world_screen.dart';
import 'scan_qr_screen.dart';
import 'show_qr_screen.dart';
import 'social_links_screen.dart';
import 'zync_now_host_screen.dart';

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
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final oneScreen = constraints.maxHeight >= 680 && constraints.maxWidth >= 330 && textScale <= 1.15;
              if (oneScreen) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: _buildOneScreen(context, l10n, greeting, privacyUri),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: _buildScrollable(context, l10n, greeting, privacyUri),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return Row(
        children: [
          const ZyncMark(size: 38, strokeWidth: 4),
          const SizedBox(width: 10),
          Text('Zync', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.alternate_email_rounded),
            tooltip: l10n.socialLinks,
            onPressed: () async {
              final result = await Navigator.of(context).push<LocalProfile>(
                MaterialPageRoute(
                  builder: (_) => SocialLinksScreen(
                    profile: profile,
                    onSaved: onProfileChanged,
                  ),
                ),
              );
              if (result != null) await onProfileChanged(result);
            },
          ),
          const SizedBox(width: 4),
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
      );
  }

  Widget _hero(BuildContext context, AppLocalizations l10n, {required bool compact}) => ZyncSurface(
        padding: EdgeInsets.zero,
        borderColor: ZyncPalette.peach,
        backgroundColor: const Color(0xFFFFF3EB),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: ConnectionBackdrop())),
              Padding(
                padding: EdgeInsets.all(compact ? 17 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZyncIconTile(
                          icon: Icons.auto_awesome_rounded,
                          size: compact ? 46 : 52,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.zyncWithSomeone, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 3),
                              Text(l10n.tagline, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 14 : 22),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryAction(
                            icon: Icons.qr_code_2_rounded,
                            label: l10n.showMyQr,
                            compact: compact,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ShowQrScreen(profile: profile)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SecondaryAction(
                            icon: Icons.qr_code_scanner_rounded,
                            label: l10n.scanSomeone,
                            compact: compact,
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
      );

  List<_MenuSpec> _menuSpecs(BuildContext context, AppLocalizations l10n, Uri? privacyUri) => [
        _MenuSpec(
          icon: Icons.public_rounded,
          iconBackground: const Color(0xFFE9E5FF),
          iconForeground: ZyncPalette.plum,
          title: 'My Zync World',
          subtitle: Localizations.localeOf(context)
                  .toLanguageTag()
                  .toLowerCase()
                  .startsWith('zh')
              ? '收藏、每日抽卡、成就與任務'
              : 'Collection, Daily Draw, trophies and quests',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyZyncWorldScreen(
                profile: profile,
                onProfileChanged: onProfileChanged,
              ),
            ),
          ),
        ),
        _MenuSpec(
          icon: Icons.bolt_rounded,
          iconBackground: ZyncPalette.mint,
          iconForeground: const Color(0xFF176B57),
          title: LocalizedDomainText.zyncNowTitle(
            Localizations.localeOf(context).toLanguageTag(),
          ),
          subtitle: LocalizedDomainText.zyncNowGroupCta(
            Localizations.localeOf(context).toLanguageTag(),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ZyncNowHostScreen(profile: profile),
            ),
          ),
        ),
        _MenuSpec(
          icon: Icons.groups_2_outlined,
          iconBackground: const Color(0xFFE9E5FF),
          iconForeground: ZyncPalette.plum,
          title: LocalizedDomainText.groupZyncTitle(
            Localizations.localeOf(context).toLanguageTag(),
          ),
          subtitle: LocalizedDomainText.groupZyncSubtitle(
            Localizations.localeOf(context).toLanguageTag(),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupZyncHostLobbyScreen(profile: profile),
            ),
          ),
        ),
        _MenuSpec(
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
        _MenuSpec(
          icon: Icons.people_alt_outlined,
          iconBackground: ZyncPalette.mint,
          iconForeground: const Color(0xFF167A62),
          title: l10n.peopleHistory,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
        _MenuSpec(
          icon: Icons.bubble_chart_outlined,
          iconBackground: const Color(0xFFE9E5FF),
          iconForeground: ZyncPalette.plum,
          title: l10n.interestDna,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InterestDnaScreen(profile: profile)),
          ),
        ),
        if (privacyUri != null)
          _MenuSpec(
            icon: Icons.privacy_tip_outlined,
            iconBackground: const Color(0xFFE8F0FF),
            iconForeground: const Color(0xFF315F9E),
            title: l10n.privacyPolicy,
            onTap: () => _openPrivacyPolicy(context, privacyUri, l10n.privacyPolicyUnavailable),
          ),
      ];

  Widget _buildOneScreen(BuildContext context, AppLocalizations l10n, String greeting, Uri? privacyUri) {
    final specs = _menuSpecs(context, l10n, privacyUri);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, l10n),
        const SizedBox(height: 14),
        Text(greeting, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(
          l10n.interestsCount(profile.interests.length),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
        ),
        const SizedBox(height: 14),
        _hero(context, l10n, compact: true),
        const SizedBox(height: 14),
        Expanded(
          child: _menuGrid(specs),
        ),
      ],
    );
  }

  Widget _menuGrid(List<_MenuSpec> specs) {
    final rowCount = (specs.length / 2).ceil();
    return Column(
      children: [
        for (var row = 0; row < rowCount; row++) ...[
          Expanded(child: _menuRow(specs, row * 2)),
          if (row != rowCount - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _menuRow(List<_MenuSpec> specs, int start) {
    final first = start < specs.length ? specs[start] : null;
    final second = start + 1 < specs.length ? specs[start + 1] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: first == null ? const SizedBox.shrink() : _MenuTile.fromSpec(first, compact: true)),
        const SizedBox(width: 10),
        Expanded(child: second == null ? const SizedBox.shrink() : _MenuTile.fromSpec(second, compact: true)),
      ],
    );
  }

  List<Widget> _buildScrollable(BuildContext context, AppLocalizations l10n, String greeting, Uri? privacyUri) {
    final specs = _menuSpecs(context, l10n, privacyUri);
    return [
      _header(context, l10n),
      const SizedBox(height: 30),
      Text(greeting, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      Text(
        l10n.interestsCount(profile.interests.length),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
      ),
      const SizedBox(height: 24),
      _hero(context, l10n, compact: false),
      const SizedBox(height: 24),
      for (var i = 0; i < specs.length; i++) ...[
        _MenuTile.fromSpec(specs[i]),
        if (i != specs.length - 1) const SizedBox(height: 12),
      ],
    ];
  }
}

class _MenuSpec {
  const _MenuSpec({
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
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.icon, required this.label, required this.onTap, this.compact = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, maxLines: 2, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          minimumSize: Size(0, compact ? 54 : 62),
          backgroundColor: ZyncPalette.ink,
          foregroundColor: Colors.white,
        ),
      );
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.icon, required this.label, required this.onTap, this.compact = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, maxLines: 2, textAlign: TextAlign.center),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, compact ? 54 : 62),
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
    this.compact = false,
  });

  factory _MenuTile.fromSpec(_MenuSpec spec, {bool compact = false}) => _MenuTile(
        icon: spec.icon,
        iconBackground: spec.iconBackground,
        iconForeground: spec.iconForeground,
        title: spec.title,
        subtitle: spec.subtitle,
        onTap: spec.onTap,
        compact: compact,
      );

  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(compact ? 18 : 22),
          onTap: onTap,
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16, vertical: compact ? 5 : 15),
            decoration: BoxDecoration(
              color: ZyncPalette.surface,
              borderRadius: BorderRadius.circular(compact ? 18 : 22),
              border: Border.all(color: ZyncPalette.line),
            ),
            child: compact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ZyncIconTile(
                        icon: icon,
                        size: 30,
                        backgroundColor: iconBackground,
                        foregroundColor: iconForeground,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  )
                : Row(
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

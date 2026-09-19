import 'package:flutter/material.dart';

import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({
    super.key,
    required this.profile,
    required this.onSaved,
  });

  final LocalProfile profile;
  final Future<void> Function(LocalProfile profile) onSaved;

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  final Map<SocialPlatform, TextEditingController> _controllers = {};
  final Map<SocialPlatform, bool> _share = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final platform in SocialPlatform.values) {
      SocialLink? existing;
      for (final link in widget.profile.socialLinks) {
        if (link.platform == platform) {
          existing = link;
          break;
        }
      }
      _controllers[platform] = TextEditingController(text: existing?.value ?? '');
      _share[platform] = existing?.shareAfterZync ?? false;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final links = <SocialLink>[];
    for (final platform in SocialPlatform.values) {
      final value = _controllers[platform]!.text.trim();
      if (value.isEmpty) continue;
      final link = SocialLink(
        platform: platform,
        value: value,
        shareAfterZync: _share[platform] ?? false,
      );
      if (link.profileUrl != null) links.add(link);
    }
    setState(() => _saving = true);
    final updated = widget.profile.copyWith(socialLinks: links);
    await widget.onSaved(updated);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialLinks)),
      body: ConnectionBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            ZyncSurface(
              shadow: false,
              backgroundColor: const Color(0xFFF8F5FF),
              borderColor: const Color(0xFFE5DFFF),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ZyncIconTile(
                    icon: Icons.link_rounded,
                    backgroundColor: Color(0xFFE9E5FF),
                    foregroundColor: ZyncPalette.plum,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.socialLinksSubtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.shareAfterZyncExplain,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: ZyncPalette.inkSoft, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final platform in SocialPlatform.values) ...[
              _SocialEditor(
                platform: platform,
                label: _platformLabel(l10n, platform),
                controller: _controllers[platform]!,
                share: _share[platform] ?? false,
                shareLabel: l10n.shareAfterZync,
                onShareChanged: (value) => setState(() {
                  _share[platform] = value;
                }),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.saveSocialLinks),
            ),
          ],
        ),
      ),
    );
  }

  String _platformLabel(
    AppLocalizations l10n,
    SocialPlatform platform,
  ) =>
      switch (platform) {
        SocialPlatform.instagram => l10n.instagram,
        SocialPlatform.threads => l10n.threads,
        SocialPlatform.facebook => l10n.facebook,
      };
}

class _SocialEditor extends StatelessWidget {
  const _SocialEditor({
    required this.platform,
    required this.label,
    required this.controller,
    required this.share,
    required this.shareLabel,
    required this.onShareChanged,
  });

  final SocialPlatform platform;
  final String label;
  final TextEditingController controller;
  final bool share;
  final String shareLabel;
  final ValueChanged<bool> onShareChanged;

  @override
  Widget build(BuildContext context) => ZyncSurface(
        shadow: false,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: label,
                hintText: platform == SocialPlatform.facebook
                    ? 'profile URL or username'
                    : '@username or profile URL',
                prefixIcon: Icon(_icon(platform)),
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Switch.adaptive(
                    value: share,
                    onChanged: onShareChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  IconData _icon(SocialPlatform platform) => switch (platform) {
        SocialPlatform.instagram => Icons.camera_alt_outlined,
        SocialPlatform.threads => Icons.alternate_email_rounded,
        SocialPlatform.facebook => Icons.people_outline_rounded,
      };
}

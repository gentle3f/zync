import 'package:flutter/material.dart';

import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import 'history_screen.dart';
import 'interest_dna_screen.dart';
import 'interest_setup_screen.dart';
import 'scan_qr_screen.dart';
import 'show_qr_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zync', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            name.isEmpty ? l10n.homeGreeting : '${l10n.homeGreeting} $name',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(l10n.interestsCount(profile.interests.length)),
          const SizedBox(height: 26),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.zyncWithSomeone, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ShowQrScreen(profile: profile)),
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: Text(l10n.showMyQr),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ScanQrScreen(profile: profile)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(l10n.scanSomeone),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MenuTile(
            icon: Icons.favorite_border,
            title: l10n.myInterests,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InterestSetupScreen(profile: profile, onSaved: onProfileChanged, editing: true),
              ),
            ),
          ),
          _MenuTile(
            icon: Icons.people_outline,
            title: l10n.peopleHistory,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          _MenuTile(
            icon: Icons.bubble_chart_outlined,
            title: l10n.interestDna,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InterestDnaScreen(profile: profile))),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

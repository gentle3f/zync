import 'package:flutter/material.dart';

import '../core/local_store.dart';
import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.peopleHistory)),
      body: ConnectionBackdrop(
        child: FutureBuilder<List<ZyncHistoryEntry>>(
          future: LocalStore.loadHistory(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.6)),
              );
            }
            final history = snapshot.data!;
            if (history.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: ZyncSurface(
                    shadow: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ZyncIconTile(
                          icon: Icons.people_alt_outlined,
                          size: 58,
                          backgroundColor: ZyncPalette.mint,
                          foregroundColor: Color(0xFF176B57),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noHistory, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(l10n.tagline, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = history[index];
                final safePrefix = entry.peerId.length >= 6 ? entry.peerId.substring(0, 6) : entry.peerId;
                final name = entry.peerNickname.trim().isEmpty ? 'Zync #$safePrefix' : entry.peerNickname;
                return ZyncSurface(
                  shadow: false,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                  child: Row(
                    children: [
                      const ZyncIconTile(
                        icon: Icons.person_outline_rounded,
                        backgroundColor: Color(0xFFE9E5FF),
                        foregroundColor: ZyncPalette.plum,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 3),
                            Text(
                              LocalizedDomainText.historyMeta(
                                matches: entry.previousSharedIds.length,
                                sessions: entry.sessionCount,
                                locale: locale,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(_shortDate(entry.lastZyncAt.toLocal()), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _shortDate(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

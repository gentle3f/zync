import 'package:flutter/material.dart';

import '../core/interest_catalog.dart';
import '../core/local_store.dart';
import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../core/zync_alias.dart';
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
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
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
                        Text(
                          l10n.noHistory,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.tagline,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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
                final name = ZyncAlias.displayName(
                  nickname: entry.peerNickname,
                  localId: entry.peerId,
                  locale: locale,
                );
                final questionCount = entry.recentQuestions.length;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ZyncHistoryDetailScreen(entry: entry),
                      ),
                    ),
                    child: ZyncSurface(
                      shadow: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 14,
                      ),
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
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  LocalizedDomainText.historyMeta(
                                    matches: entry.previousSharedIds.length,
                                    sessions: entry.sessionCount,
                                    locale: locale,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (questionCount > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '$questionCount conversation ${questionCount == 1 ? 'question' : 'questions'} saved',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: ZyncPalette.plum),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _shortDate(entry.lastZyncAt.toLocal()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                                color: ZyncPalette.inkSoft,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _shortDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class ZyncHistoryDetailScreen extends StatelessWidget {
  const ZyncHistoryDetailScreen({super.key, required this.entry});

  final ZyncHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final name = ZyncAlias.displayName(
      nickname: entry.peerNickname,
      localId: entry.peerId,
      locale: locale,
    );
    final shared = entry.previousSharedIds
        .map((id) => InterestCatalog.byId(id)?.labelFor(locale) ?? id)
        .toList(growable: false);
    final sharedIds = entry.previousSharedIds.toSet();
    final peerOnly = entry.peerInterests
        .where((item) => !sharedIds.contains(item.id))
        .toList()
      ..sort((a, b) {
        final strength = b.strength.wireValue.compareTo(a.strength.wireValue);
        return strength != 0 ? strength : a.id.compareTo(b.id);
      });

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ConnectionBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ZyncSurface(
              borderColor: const Color(0xFFE5DFFF),
              backgroundColor: const Color(0xFFF8F5FF),
              child: Row(
                children: [
                  const ZyncIconTile(
                    icon: Icons.auto_awesome_rounded,
                    size: 54,
                    backgroundColor: Color(0xFFE9E5FF),
                    foregroundColor: ZyncPalette.plum,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.sessionCount} Zync${entry.sessionCount == 1 ? '' : 's'} · last ${_shortDate(entry.lastZyncAt.toLocal())}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: ZyncPalette.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              icon: Icons.favorite_outline_rounded,
              title: 'Things you both like',
            ),
            const SizedBox(height: 10),
            if (shared.isEmpty)
              const _EmptyMemory(text: 'No exact shared interests saved yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shared.map((label) => Chip(label: Text(label))).toList(),
              ),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Things you learned about them',
            ),
            const SizedBox(height: 10),
            if (peerOnly.isEmpty)
              const _EmptyMemory(text: 'Nothing extra saved from their latest Zync yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: peerOnly.take(18).map((interest) {
                  final label = InterestCatalog.byId(interest.id)?.labelFor(locale) ??
                      interest.customLabel ??
                      interest.id;
                  final emoji = switch (interest.strength) {
                    InterestStrength.love => '❤️',
                    InterestStrength.like => '👍',
                    InterestStrength.wantToTry => '✨',
                  };
                  return Chip(label: Text('$emoji $label'));
                }).toList(),
              ),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Questions you talked about',
            ),
            const SizedBox(height: 10),
            if (entry.recentQuestions.isEmpty)
              const _EmptyMemory(
                text: 'Questions from your next Zync will be remembered here on this phone.',
              )
            else
              ...entry.recentQuestions.map(
                (memory) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ZyncSurface(
                    shadow: false,
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (memory.connectionLabel?.trim().isNotEmpty ?? false) ...[
                          Text(
                            memory.connectionLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: ZyncPalette.plum),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          memory.question,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(height: 1.35),
                        ),
                        if (memory.secondaryQuestion?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Text(
                            memory.secondaryQuestion!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: ZyncPalette.inkSoft),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${memory.mode} · ${_shortDate(memory.createdAt.toLocal())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 21, color: ZyncPalette.plum),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      );
}

class _EmptyMemory extends StatelessWidget {
  const _EmptyMemory({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => ZyncSurface(
        shadow: false,
        backgroundColor: Colors.white.withValues(alpha: 0.72),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: ZyncPalette.inkSoft),
        ),
      );
}

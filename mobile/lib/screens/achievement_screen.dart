import 'package:flutter/material.dart';

import '../core/achievement_service.dart';
import '../core/interest_catalog.dart';
import '../core/local_store.dart';
import '../core/localized_domain_text.dart';
import '../ui/zync_design.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(title: Text(LocalizedDomainText.achievementsTitle(locale))),
      body: ConnectionBackdrop(
        child: FutureBuilder(
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

            final achievement = AchievementService.evaluate(snapshot.data!);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              children: [
                ZyncSurface(
                  borderColor: const Color(0xFFE5DFFF),
                  backgroundColor: const Color(0xFFF8F5FF),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZyncIconTile(
                        icon: Icons.emoji_events_rounded,
                        size: 58,
                        backgroundColor: Color(0xFFFFE9B7),
                        foregroundColor: Color(0xFF8B5A00),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizedDomainText.achievementsTitle(locale),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              LocalizedDomainText.achievementsIntro(locale),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: ZyncPalette.inkSoft, height: 1.35),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LocalizedDomainText.achievementUnlockedMeta(
                                achievement.unlockedCount,
                                achievement.progress.length,
                                locale,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: ZyncPalette.plum),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                for (final item in achievement.progress) ...[
                  _AchievementCard(
                    item: item,
                    locale: locale,
                    icon: _iconFor(item.id),
                  ),
                  const SizedBox(height: 10),
                ],
                if (achievement.discoveredSports.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    LocalizedDomainText.taxonomy('sports', locale) == 'Sports'
                        ? 'Sports discovered'
                        : '已發現運動',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: achievement.discoveredSports
                        .map(
                          (id) => Chip(
                            avatar: const Icon(Icons.sports_rounded, size: 16),
                            label: Text(
                              InterestCatalog.byId(id)?.labelFor(locale) ?? id,
                            ),
                          ),
                        )
                        .toList()
                      ..sort((a, b) {
                        final at = (a.label as Text).data ?? '';
                        final bt = (b.label as Text).data ?? '';
                        return at.compareTo(bt);
                      }),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static IconData _iconFor(String id) => switch (id) {
        'first_zync' => Icons.auto_awesome_rounded,
        'people_five' => Icons.groups_2_rounded,
        'basketball_starting_five' => Icons.sports_basketball_rounded,
        'sports_five' => Icons.sports_rounded,
        'sports_ten' => Icons.explore_rounded,
        'curiosity_25' => Icons.collections_bookmark_rounded,
        _ => Icons.emoji_events_rounded,
      };
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.item,
    required this.locale,
    required this.icon,
  });

  final AchievementProgress item;
  final String locale;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final unlocked = item.unlocked;
    return ZyncSurface(
      shadow: false,
      borderColor: unlocked ? const Color(0xFFFFD98A) : ZyncPalette.line,
      backgroundColor: unlocked ? const Color(0xFFFFF8E8) : ZyncPalette.surface,
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZyncIconTile(
            icon: unlocked ? icon : Icons.lock_outline_rounded,
            size: 48,
            backgroundColor:
                unlocked ? const Color(0xFFFFE9B7) : const Color(0xFFF0F0F4),
            foregroundColor:
                unlocked ? const Color(0xFF8B5A00) : ZyncPalette.inkSoft,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizedDomainText.achievementTitle(item.id, locale),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  LocalizedDomainText.achievementDescription(item.id, locale),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: ZyncPalette.inkSoft, height: 1.35),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: item.fraction,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEDEAF3),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  LocalizedDomainText.achievementProgress(
                    item.current.clamp(0, item.target),
                    item.target,
                    locale,
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: unlocked ? const Color(0xFF8B5A00) : ZyncPalette.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

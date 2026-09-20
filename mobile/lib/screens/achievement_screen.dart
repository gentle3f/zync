import 'package:flutter/material.dart';

import '../core/achievement_service.dart';
import '../core/interest_catalog.dart';
import '../core/local_store.dart';
import '../core/localized_domain_text.dart';
import '../ui/zync_design.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  AchievementSnapshot? _achievement;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final history = await LocalStore.loadHistory();
    final events = await LocalStore.loadProgressEvents();
    final achievement = AchievementService.evaluate(
      history,
      events: events,
    );
    if (!mounted) return;
    setState(() {
      _achievement = achievement;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final achievement = _achievement;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizedDomainText.achievementsTitle(locale)),
      ),
      body: ConnectionBackdrop(
        child: _loading || achievement == null
            ? const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
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
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  LocalizedDomainText.achievementsIntro(locale),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: ZyncPalette.inkSoft,
                                        height: 1.35,
                                      ),
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
                    const SizedBox(height: 20),
                    for (final family in AchievementFamily.values) ...[
                      _FamilyHeader(
                        family: family,
                        locale: locale,
                        items: achievement.progress
                            .where((item) => item.family == family)
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 10),
                      for (final item in achievement.progress.where(
                        (item) => item.family == family,
                      )) ...[
                        _AchievementCard(
                          item: item,
                          locale: locale,
                          icon: _iconFor(item),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 10),
                    ],
                    if (achievement.discoveredSports.isNotEmpty) ...[
                      Text(
                        LocalizedDomainText.sportsDiscovered(locale),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: achievement.discoveredSports
                            .map(
                              (id) => Chip(
                                avatar: const Icon(
                                  Icons.sports_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  InterestCatalog.byId(id)?.labelFor(locale) ??
                                      id,
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
                ),
              ),
      ),
    );
  }

  static IconData _iconFor(AchievementProgress item) {
    return switch (item.id) {
      'first_zync' => Icons.auto_awesome_rounded,
      'people_five' ||
      'people_ten' ||
      'people_twentyfive' => Icons.groups_2_rounded,
      'familiar_face_three' ||
      'familiar_circle_three' ||
      'deep_circle_three' => Icons.handshake_outlined,
      'conversation_modes_three' ||
      'conversation_modes_six' => Icons.forum_outlined,
      'basketball_starting_five' ||
      'basketball_full_roster' => Icons.sports_basketball_rounded,
      'football_starting_eleven' => Icons.sports_soccer_rounded,
      'badminton_doubles_four' ||
      'racket_four' => Icons.sports_tennis_rounded,
      'coffee_table_five' => Icons.local_cafe_outlined,
      'gaming_party_four' => Icons.sports_esports_outlined,
      'book_club_five' => Icons.menu_book_rounded,
      'ai_roundtable_three' => Icons.memory_rounded,
      'photo_walk_three' => Icons.photo_camera_outlined,
      'japan_crew_three' => Icons.travel_explore_rounded,
      'music_crew_five' => Icons.music_note_rounded,
      'sports_five' ||
      'sports_ten' ||
      'active_mix' => Icons.sports_rounded,
      'culture_mix' => Icons.theater_comedy_outlined,
      'maker_mix' => Icons.handyman_outlined,
      'taste_trip' => Icons.restaurant_outlined,
      'mind_body_mix' => Icons.self_improvement_rounded,
      'tried_together_first' ||
      'tried_together_three' ||
      'tried_together_ten' => Icons.bolt_rounded,
      'group_activity_first' ||
      'group_activity_three' => Icons.groups_3_outlined,
      'activity_categories_three' ||
      'activity_categories_five' => Icons.explore_outlined,
      'activity_modes_three' => Icons.shuffle_rounded,
      'real_world_actions_ten' ||
      'real_world_actions_twentyfive' => Icons.directions_walk_rounded,
      _ => switch (item.family) {
          AchievementFamily.connection => Icons.people_alt_outlined,
          AchievementFamily.discovery => Icons.explore_outlined,
          AchievementFamily.crew => Icons.diversity_3_outlined,
          AchievementFamily.realWorld => Icons.bolt_rounded,
        },
    };
  }
}

class _FamilyHeader extends StatelessWidget {
  const _FamilyHeader({
    required this.family,
    required this.locale,
    required this.items,
  });

  final AchievementFamily family;
  final String locale;
  final List<AchievementProgress> items;

  @override
  Widget build(BuildContext context) {
    final unlocked = items.where((item) => item.unlocked).length;
    final icon = switch (family) {
      AchievementFamily.connection => Icons.people_alt_outlined,
      AchievementFamily.discovery => Icons.explore_outlined,
      AchievementFamily.crew => Icons.diversity_3_outlined,
      AchievementFamily.realWorld => Icons.bolt_rounded,
    };

    return Row(
      children: [
        ZyncIconTile(
          icon: icon,
          size: 40,
          backgroundColor: const Color(0xFFE9E5FF),
          foregroundColor: ZyncPalette.plum,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            LocalizedDomainText.achievementFamilyTitle(
              family.name,
              locale,
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Text(
          '$unlocked / ${items.length}',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: ZyncPalette.inkSoft),
        ),
      ],
    );
  }
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
      backgroundColor:
          unlocked ? const Color(0xFFFFF8E8) : ZyncPalette.surface,
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZyncIconTile(
            icon: unlocked ? icon : Icons.lock_outline_rounded,
            size: 48,
            backgroundColor: unlocked
                ? const Color(0xFFFFE9B7)
                : const Color(0xFFF0F0F4),
            foregroundColor: unlocked
                ? const Color(0xFF8B5A00)
                : ZyncPalette.inkSoft,
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
                  LocalizedDomainText.achievementDescription(
                    item.id,
                    locale,
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: ZyncPalette.inkSoft,
                        height: 1.35,
                      ),
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
                    item.current.clamp(0, item.target).toInt(),
                    item.target,
                    locale,
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: unlocked
                            ? const Color(0xFF8B5A00)
                            : ZyncPalette.inkSoft,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

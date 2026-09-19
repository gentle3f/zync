import 'models.dart';

/// Localisation policy for catalog leaves.
///
/// Generic concepts should have explicit zh-Hant and zh-Hans labels. Proper
/// titles, named franchises and artists may legitimately keep their native or
/// official display name until an approved/common Chinese title is curated.
///
/// This policy is intentionally semantic rather than "every row must have
/// Chinese", because forcing machine-like translations onto proper names would
/// make the catalog worse.
class InterestLocalizationPolicy {
  const InterestLocalizationPolicy._();

  /// Deep family clusters still being migrated. These are explicit debt, not
  /// a claim that English-only generic labels are acceptable. Remove a cluster
  /// from this set as soon as its zh-Hant/zh-Hans batch lands; CI will then
  /// enforce the translations permanently.
  static const Set<String> migrationBacklogClusters = {
  };

  static const Set<String> _properNameClusters = {
    'game_titles',
    'gaming/franchises',
    'tabletop/boardgame_titles',
    'tabletop/ttrpg',
    'movies/classics',
    'movies/modern_evergreen',
    'tv/drama',
    'tv/comedy_variety',
    'anime/title',
    'music/artists_global',
    'music/kpop_artists',
    'music/japanese_artists',
    'music/hk_cantopop',
    'music/mandopop_artists',
    'books/evergreen_titles',
    'travel/destinations',
  };

  /// A small number of legacy mixed clusters contain named properties alongside
  /// generic concepts. These IDs are proper-name exceptions.
  static const Set<String> _properNameIds = {
    'entertainment.ghibli',
    'entertainment.one_piece',
    'entertainment.naruto',
    'entertainment.dragon_ball',
    'entertainment.demon_slayer',
    'entertainment.attack_on_titan',
    'entertainment.jujutsu_kaisen',
    'entertainment.spy_x_family',
    'entertainment.pokemon_anime',
    'entertainment.gundam',
    'entertainment.marvel',
    'entertainment.dc',
    'entertainment.star_wars',
    'entertainment.star_trek',
    'entertainment.harry_potter',
    'entertainment.lord_of_the_rings',
    'entertainment.disney',
    'entertainment.pixar',
    'gaming.dungeons_and_dragons',
    'gaming.warhammer',
    'gaming.magic_the_gathering',
    'gaming.pokemon_tcg',
    'gaming.yu_gi_oh',
    'gaming.catan',
    'gaming.ticket_to_ride',
    'gaming.carcassonne',
    'gaming.gloomhaven',
  };

  static bool requiresChinese(InterestDefinition item) {
    if (_properNameIds.contains(item.id)) return false;
    if (_properNameClusters.contains(item.cluster)) return false;
    if (migrationBacklogClusters.contains(item.cluster)) return false;
    return true;
  }

  static bool isMigrationBacklog(InterestDefinition item) =>
      migrationBacklogClusters.contains(item.cluster);

  static bool hasRequiredChinese(InterestDefinition item) {
    if (!requiresChinese(item)) return true;
    final hant = item.labels['zh-Hant']?.trim() ?? '';
    final hans = item.labels['zh-Hans']?.trim() ?? '';
    return hant.isNotEmpty && hans.isNotEmpty;
  }
}

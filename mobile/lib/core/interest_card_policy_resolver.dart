import 'interest_entity_metadata.dart';
import 'models.dart';

class InterestCardPolicyDecision {
  const InterestCardPolicyDecision({
    required this.artPolicy,
    required this.baselineArtEligible,
    required this.ipSensitive,
    required this.partnerOpportunity,
    required this.reasonCode,
    required this.eventAffinityPriority,
    this.partnerType,
    this.proxyFamily,
  });

  final CardArtPolicy artPolicy;
  final bool baselineArtEligible;
  final bool ipSensitive;
  final bool partnerOpportunity;
  final String reasonCode;
  final String eventAffinityPriority;
  final String? partnerType;
  final String? proxyFamily;
}

/// Keeps interest matching broad while preventing unlicensed official-looking
/// branded/franchise collectibles from entering the baseline art pipeline.
class InterestCardPolicyResolver {
  const InterestCardPolicyResolver._();

  static const Set<String> _licensedClusters = {
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
    'cars/brands',
    'platforms/brands',
  };

  static const Set<String> _licensedIds = {
    'collecting.lego',
    'motorsport.formula1',
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
    'entertainment.youtube',
  };

  static InterestCardPolicyDecision resolve(InterestDefinition item) {
    if (_licensedIds.contains(item.id) || _licensedClusters.contains(item.cluster)) {
      return InterestCardPolicyDecision(
        artPolicy: CardArtPolicy.licensedOnly,
        baselineArtEligible: false,
        ipSensitive: true,
        partnerOpportunity: true,
        reasonCode: _reasonFor(item),
        eventAffinityPriority: 'proxy_only',
        partnerType: _partnerTypeFor(item),
        proxyFamily: _proxyFamilyFor(item),
      );
    }

    final explicit = InterestEntityMetadataRegistry.byInterestId(item.id)?.card;
    if (explicit != null && explicit.artPolicy != CardArtPolicy.notCollectible) {
      return InterestCardPolicyDecision(
        artPolicy: explicit.artPolicy,
        baselineArtEligible: explicit.artPolicy == CardArtPolicy.originalGeneric ||
            explicit.artPolicy == CardArtPolicy.abstractOnly,
        ipSensitive: explicit.artPolicy == CardArtPolicy.licensedOnly,
        partnerOpportunity: explicit.artPolicy == CardArtPolicy.licensedOnly,
        reasonCode: 'explicit_metadata',
        eventAffinityPriority: _eventPriorityFor(item),
        partnerType: explicit.artPolicy == CardArtPolicy.licensedOnly ? _partnerTypeFor(item) : null,
        proxyFamily: explicit.artPolicy == CardArtPolicy.licensedOnly ? _proxyFamilyFor(item) : null,
      );
    }

    return InterestCardPolicyDecision(
      artPolicy: CardArtPolicy.originalGeneric,
      baselineArtEligible: true,
      ipSensitive: false,
      partnerOpportunity: false,
      reasonCode: 'generic_concept',
      eventAffinityPriority: _eventPriorityFor(item),
    );
  }

  static String _reasonFor(InterestDefinition item) {
    if (item.cluster == 'cars/brands') return 'car_brand_partner_only';
    if (item.cluster == 'platforms/brands') return 'platform_brand_partner_only';
    if (item.category == 'music') return 'named_music_artist_or_rightsholder';
    if (item.category == 'gaming') return 'named_game_or_tabletop_ip';
    if (item.category == 'entertainment') return 'named_screen_or_franchise_ip';
    if (item.category == 'learning' && item.cluster == 'books/evergreen_titles') return 'named_book_title_ip';
    return 'named_brand_or_ip';
  }

  static String _partnerTypeFor(InterestDefinition item) {
    if (item.cluster == 'cars/brands') return 'automotive_brand';
    if (item.cluster == 'platforms/brands') return 'platform_brand';
    if (item.category == 'music') return 'artist_label_rightsholder';
    if (item.category == 'gaming') return 'game_publisher_rightsholder';
    if (item.category == 'entertainment') return 'studio_network_rightsholder';
    if (item.category == 'learning') return 'publisher_author_rightsholder';
    return 'brand_or_rightsholder';
  }

  static String _proxyFamilyFor(InterestDefinition item) {
    if (item.cluster == 'cars/brands') return 'cars';
    if (item.cluster == 'platforms/brands') return 'online_video';
    if (item.category == 'music') return 'music';
    if (item.category == 'gaming') return item.cluster.startsWith('tabletop/') ? 'tabletop_gaming' : 'video_gaming';
    if (item.category == 'entertainment') {
      if (item.cluster.startsWith('anime/')) return 'anime';
      if (item.cluster.startsWith('tv/')) return 'tv';
      return 'cinema_screen';
    }
    if (item.category == 'learning') return 'reading';
    return 'generic_interest';
  }

  static String _eventPriorityFor(InterestDefinition item) {
    if (const {'lifestyle', 'wellness', 'sports', 'outdoors', 'food', 'travel', 'arts', 'crafts'}
        .contains(item.category)) return 'high';
    if (const {'gaming', 'music', 'entertainment', 'learning', 'technology', 'pets'}
        .contains(item.category)) return 'medium';
    return 'low';
  }
}

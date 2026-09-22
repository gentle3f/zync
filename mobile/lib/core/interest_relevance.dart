import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'interest_popularity_service.dart';
import 'models.dart';

class InterestRegion {
  const InterestRegion._();

  static const supported = <String>{
    'global', 'hk', 'tw', 'mo', 'cn', 'sg', 'jp', 'kr',
    'us', 'gb', 'au', 'ca', 'fr', 'es', 'pt', 'br', 'de', 'in',
  };

  static String current() =>
      fromLocale(WidgetsBinding.instance.platformDispatcher.locale);

  static String fromLocale(Locale locale) {
    final country = (locale.countryCode ?? '').trim().toUpperCase();
    if (country.isNotEmpty) {
      final mapped = switch (country) {
        'HK' => 'hk',
        'TW' => 'tw',
        'MO' => 'mo',
        'CN' => 'cn',
        'SG' => 'sg',
        'JP' => 'jp',
        'KR' => 'kr',
        'US' => 'us',
        'GB' => 'gb',
        'AU' => 'au',
        'CA' => 'ca',
        'FR' => 'fr',
        'ES' => 'es',
        'PT' => 'pt',
        'BR' => 'br',
        'DE' => 'de',
        'IN' => 'in',
        _ => 'global',
      };
      if (mapped != 'global') return mapped;
    }

    return switch (locale.languageCode.toLowerCase()) {
      'ja' => 'jp',
      'ko' => 'kr',
      _ => 'global',
    };
  }

  static String canonical(String raw) {
    final normalized = raw.trim().toLowerCase();
    return supported.contains(normalized) ? normalized : 'global';
  }
}

enum InterestLocality {
  none,
  optional,
  localSocial,
  venueBased,
  outdoorPlace,
  destinationBased,
  eventBased,
}

enum InterestSocialMode {
  solo,
  pair,
  smallGroup,
  team,
  community,
  spectator,
}

class InterestActivityMetadata {
  const InterestActivityMetadata({
    required this.locality,
    required this.socialModes,
    this.requiresVenue = false,
    this.requiresPartner = false,
    this.timeSensitive = false,
    this.seasonal = false,
  });

  final InterestLocality locality;
  final Set<InterestSocialMode> socialModes;
  final bool requiresVenue;
  final bool requiresPartner;
  final bool timeSensitive;
  final bool seasonal;
}

class InterestRelevance {
  const InterestRelevance._();

  static const double priorWeight = 750;
  static const double maxBehaviourWeight = 0.30;
  static const double maxBehaviourAdjustment = 8;
  static const double benchmarkSelectionRate = 0.25;

  static double baseScore(InterestDefinition item, String region) {
    final r = math.max(0, item.rank);
    final rankPrior = (96 - 12 * math.log(1 + (r / 100))).clamp(35.0, 96.0);
    final launchAudience = _launchAudienceBoost(item);
    final actionability = _actionabilityBoost(item);
    final regional = _regionalBoost(item, InterestRegion.canonical(region));
    return ((rankPrior * 0.55) + launchAudience + actionability + regional)
        .clamp(10.0, 100.0);
  }

  static double score(
    InterestDefinition item, {
    required String region,
    InterestPopularitySnapshot? popularity,
  }) {
    final base = baseScore(item, region);
    if (popularity == null) return base;

    final combined = _combine(
      popularity.previous[item.id],
      popularity.older[item.id],
    );
    final proposed = _blend(base, combined);
    return proposed.clamp(
      base - maxBehaviourAdjustment,
      base + maxBehaviourAdjustment,
    );
  }

  static int compare(
    InterestDefinition a,
    InterestDefinition b, {
    required String region,
    InterestPopularitySnapshot? popularity,
  }) {
    final aScore = score(a, region: region, popularity: popularity);
    final bScore = score(b, region: region, popularity: popularity);
    final scoreOrder = bScore.compareTo(aScore);
    if (scoreOrder != 0) return scoreOrder;
    final rankOrder = a.rank.compareTo(b.rank);
    return rankOrder != 0 ? rankOrder : a.id.compareTo(b.id);
  }


  /// Rerank broad discovery so a legacy rank block cannot turn onboarding into
  /// a wall of one category or one fine-grained cluster.
  static List<InterestDefinition> diversified(
    Iterable<InterestDefinition> source, {
    required String region,
    InterestPopularitySnapshot? popularity,
    required int limit,
  }) {
    if (limit <= 0) return const <InterestDefinition>[];
    final remaining = source.toList()
      ..sort((a, b) => compare(
            a,
            b,
            region: region,
            popularity: popularity,
          ));
    final picked = <InterestDefinition>[];
    final categoryCounts = <String, int>{};
    final clusterCounts = <String, int>{};

    while (picked.length < limit && remaining.isNotEmpty) {
      final early = picked.length < 12;
      final categoryCap = early ? 3 : 6;
      final clusterCap = early ? 1 : 3;
      InterestDefinition? best;
      var bestAdjusted = double.negativeInfinity;

      for (final item in remaining) {
        final categoryCount = categoryCounts[item.category] ?? 0;
        final clusterCount = clusterCounts[item.cluster] ?? 0;
        if (categoryCount >= categoryCap || clusterCount >= clusterCap) continue;

        var adjusted = score(item, region: region, popularity: popularity)
            - (categoryCount * 1.2)
            - (clusterCount * 3.0);
        if (picked.isNotEmpty && picked.last.category == item.category) {
          adjusted -= 1.5;
        }
        if (picked.reversed.take(4).any((row) => row.cluster == item.cluster)) {
          adjusted -= 2.0;
        }
        if (adjusted > bestAdjusted) {
          bestAdjusted = adjusted;
          best = item;
        }
      }

      best ??= remaining.first;
      remaining.remove(best);
      picked.add(best);
      categoryCounts[best.category] = (categoryCounts[best.category] ?? 0) + 1;
      clusterCounts[best.cluster] = (clusterCounts[best.cluster] ?? 0) + 1;
    }
    return List.unmodifiable(picked);
  }

  static const Set<String> _audienceHigh = {
    'sports.gym', 'gaming.video', 'media.movies', 'travel.general',
    'food.coffee', 'music.pop', 'sports.running', 'sports.hiking',
    'sports.basketball', 'media.anime', 'photography.general', 'gaming.board',
    'food.cooking', 'books.reading', 'technology.ai', 'music.concerts',
    'fashion.streetwear', 'learning.languages', 'outdoors.cycling',
    'outdoors.swimming', 'outdoors.bouldering', 'lifestyle.local_events',
    'lifestyle.escape_rooms', 'sports.run_clubs', 'food.cafe_hopping',
    'arts.dance', 'sports.american_football', 'sports.badminton',
  };

  static const Set<String> _audienceMedium = {
    'media.manga', 'technology.gadgets', 'music.rock', 'outdoors.camping',
    'travel.roadtrip', 'food.japanese', 'fashion.sneakers',
    'fashion.skincare', 'fashion.makeup', 'lifestyle.volunteering',
    'lifestyle.city_walks', 'arts.photo_walks', 'music.k_pop',
    'music.cantopop', 'music.karaoke', 'sports.table_tennis',
    'sports.pickleball', 'sports.football', 'sports.baseball', 'travel.japan',
    'learning.language_exchange', 'learning.student_societies',
    'learning.campus_events', 'lifestyle.game_nights', 'learning.campus_life',
    'sports.college_sports', 'sports.sports_watch_parties',
    'transport.car_meets', 'outdoors.state_parks',
    'entertainment.anime_conventions', 'lifestyle.online_communities',
    'entertainment.memes', 'lifestyle.study_cafes',
    'arts.painting_socials', 'lifestyle.pop_up_markets',
    'food.late_night_eats',
  };

  static const Set<String> _audienceLight = {
    'outdoors.night_hiking', 'lifestyle.cat_cafes', 'gaming.mahjong',
    'lifestyle.shopping', 'lifestyle.thrifting', 'lifestyle.craft_markets',
    'collecting.capsule_toys', 'gaming.claw_machines',
    'lifestyle.photo_booths', 'food.bubble_tea', 'food.hot_pot',
    'food.dessert_hunting', 'travel.staycations', 'learning.study_groups',
    'arts.kpop_dance', 'sports.american_football_fandom',
    'sports.college_football', 'sports.fantasy_football', 'sports.tailgating',
    'sports.recreational_sports_leagues', 'transport.pickup_trucks',
    'learning.greek_life', 'learning.homecoming',
    'entertainment.film_festivals', 'pets.dog_parks',
    'wellness.reformer_pilates',
  };

  static double _launchAudienceBoost(InterestDefinition item) {
    if (_audienceHigh.contains(item.id)) return 25;
    if (_audienceMedium.contains(item.id)) return 18;
    if (_audienceLight.contains(item.id)) return 10;
    return 0;
  }

  static double _actionabilityBoost(InterestDefinition item) {
    final cluster = item.cluster;
    const activeClusters = {
      'social', 'campus', 'fitness', 'photography', 'coffee', 'dance',
      'running', 'hiking', 'cycling', 'tabletop',
    };
    var boost = 0.0;
    if (activeClusters.any(
      (value) => cluster == value || cluster.startsWith('$value/'),
    )) {
      boost += 4;
    }
    if (const {'lifestyle', 'arts', 'food', 'travel', 'wellness'}
        .contains(item.category)) {
      boost += 2;
    }
    return boost;
  }

  static InterestSignalCount? _combine(
    InterestSignalCount? previous,
    InterestSignalCount? older,
  ) {
    if (previous == null && older == null) return null;
    return InterestSignalCount(
      impressions: (previous?.impressions ?? 0) + (older?.impressions ?? 0),
      selections: (previous?.selections ?? 0) + (older?.selections ?? 0),
    );
  }

  static double _blend(double base, InterestSignalCount? signal) {
    if (signal == null || signal.impressions <= 0) return base;
    final impressions = signal.impressions.toDouble();
    final rate = (signal.selections / impressions).clamp(0.0, 1.0);
    final behaviourScore =
        ((rate / benchmarkSelectionRate) * 100).clamp(0.0, 100.0);
    final confidence = impressions / (impressions + priorWeight);
    final dataWeight = confidence * maxBehaviourWeight;
    return base * (1 - dataWeight) + behaviourScore * dataWeight;
  }

  static double _regionalBoost(InterestDefinition item, String region) {
    final id = item.id;
    final cluster = item.cluster;
    double boost = 0;

    bool inIds(Set<String> ids) => ids.contains(id);
    bool clusterStarts(String value) => cluster == value || cluster.startsWith('$value/');

    switch (region) {
      case 'hk':
      case 'mo':
        if (inIds({
          'sports.hiking', 'sports.badminton', 'travel.japan',
          'music.cantopop', 'music.k_pop', 'food.cafe_hopping',
          'music.karaoke', 'arts.photo_walks', 'outdoors.night_hiking',
        })) {
          boost += 20;
        } else if (inIds({
          'sports.gym', 'gaming.video', 'media.anime', 'photography.general',
          'photography.street', 'gaming.board', 'sports.basketball',
          'sports.table_tennis', 'outdoors.bouldering', 'music.concerts',
          'sports.run_clubs', 'lifestyle.escape_rooms', 'lifestyle.city_walks',
          'lifestyle.local_events', 'learning.student_societies',
          'learning.campus_events', 'learning.language_exchange',
          'food.bubble_tea', 'food.hot_pot', 'food.dessert_hunting',
          'fashion.streetwear', 'lifestyle.study_cafes',
          'arts.painting_socials', 'lifestyle.pop_up_markets',
          'food.late_night_eats',
        })) {
          boost += 12;
        } else if (inIds({
          'travel.korea', 'travel.staycations', 'learning.study_groups',
          'lifestyle.cat_cafes', 'outdoors.dragon_boat', 'arts.kpop_dance',
          'gaming.mahjong', 'lifestyle.shopping', 'lifestyle.thrifting',
          'lifestyle.craft_markets', 'collecting.capsule_toys',
          'gaming.claw_machines', 'lifestyle.photo_booths',
          'fashion.sneakers', 'fashion.skincare', 'fashion.makeup',
          'outdoors.urban_hiking',
        })) {
          boost += 6;
        }
        if (clusterStarts('music/hk_cantopop')) boost += 8;
        if (inIds({'food.hong_kong', 'food.cantonese', 'food.dim_sum'})) {
          boost += 4;
        }
        break;
      case 'tw':
        if (id == 'food.taiwanese') boost += 24;
        if (id == 'music.mandopop') boost += 18;
        if (id == 'sports.baseball') boost += 18;
        if (id == 'music.karaoke') boost += 10;
        if (clusterStarts('music/mandopop_artists')) boost += 16;
        if (id == 'music.style.taiwan_indie') boost += 20;
        if (inIds({
          'food.dish.taiwanese_beef_noodles',
          'food.dish.lu_rou_fan',
          'food.dish.gua_bao',
          'food.dish.oyster_omelette',
          'food.dish.stinky_tofu',
          'entertainment.tv_drama.someday_or_one_day',
          'entertainment.tv_drama.the_victims_game',
          'entertainment.tv_drama.copycat_killer',
          'entertainment.tv_drama.the_world_between_us',
          'entertainment.tv_drama.wave_makers',
        })) {
          boost += 18;
        }
        break;
      case 'jp':
        if (id == 'music.j_pop') boost += 22;
        if (id == 'music.city_pop') boost += 16;
        if (id == 'music.karaoke') boost += 10;
        if (id == 'sports.baseball') boost += 14;
        if (clusterStarts('music/japanese_artists')) boost += 20;
        if (clusterStarts('anime') || clusterStarts('anime_manga')) boost += 15;
        if (_containsJapanese(item)) boost += 8;
        break;
      case 'kr':
        if (id == 'music.k_pop') boost += 24;
        if (id == 'entertainment.k_drama') boost += 24;
        if (id == 'sports.baseball') boost += 10;
        if (clusterStarts('music/kpop_artists')) boost += 22;
        if (_containsKorean(item)) boost += 12;
        break;
      case 'cn':
        if (id == 'music.mandopop') boost += 18;
        if (id == 'entertainment.c_drama') boost += 22;
        if (clusterStarts('music/mandopop_artists')) boost += 16;
        if (id == 'entertainment.movie_subgenre.chinese_cinema') boost += 14;
        if (inIds({'food.cantonese', 'food.sichuan', 'food.hot_pot'})) boost += 10;
        break;
      case 'sg':
        if (id == 'food.singaporean') boost += 24;
        if (id == 'food.malaysian') boost += 10;
        if (id == 'sports.badminton') boost += 16;
        if (id == 'music.mandopop') boost += 7;
        if (inIds({
          'food.dish.hainanese_chicken_rice',
          'food.dish.laksa',
          'food.dish.bak_kut_teh',
          'food.dish.satay',
        })) {
          boost += 18;
        }
        break;
      case 'us':
        if (inIds({
          'sports.american_football', 'sports.college_sports',
          'sports.college_football', 'learning.campus_life',
          'outdoors.state_parks',
        })) {
          boost += 20;
        } else if (inIds({
          'sports.basketball', 'sports.baseball', 'sports.pickleball',
          'travel.roadtrip', 'transport.car_meets',
          'sports.sports_watch_parties', 'lifestyle.game_nights',
        })) {
          boost += 12;
        } else if (inIds({
          'sports.gym', 'gaming.video', 'media.movies', 'music.pop',
          'food.coffee', 'sports.hiking', 'media.anime', 'gaming.board',
          'music.concerts', 'sports.running', 'entertainment.memes',
          'lifestyle.online_communities', 'entertainment.anime_conventions',
        })) {
          boost += 6;
        }
        break;
      case 'gb':
        if (id == 'sports.football') boost += 18;
        if (id == 'sports.rugby') boost += 12;
        break;
      case 'au':
        if (id == 'sports.rugby') boost += 14;
        if (id == 'sports.cricket') boost += 18;
        if (id == 'outdoors.surfing') boost += 10;
        break;
      case 'ca':
        if (id == 'sports.ice_hockey') boost += 22;
        break;
      case 'br':
      case 'es':
      case 'pt':
        if (id == 'sports.football') boost += 18;
        break;
      default:
        break;
    }

    return boost.clamp(0.0, 30.0);
  }

  static bool _containsJapanese(InterestDefinition item) {
    final re = RegExp(r'[\u3040-\u30ff]');
    return item.labels.values.any(re.hasMatch) || item.aliases.any(re.hasMatch);
  }

  static bool _containsKorean(InterestDefinition item) {
    final re = RegExp(r'[\uac00-\ud7af]');
    return item.labels.values.any(re.hasMatch) || item.aliases.any(re.hasMatch);
  }

  static InterestActivityMetadata activityMetadata(InterestDefinition item) {
    final cluster = item.cluster;
    if (item.category == 'travel') {
      return const InterestActivityMetadata(
        locality: InterestLocality.destinationBased,
        socialModes: {InterestSocialMode.solo, InterestSocialMode.smallGroup},
        timeSensitive: true,
        seasonal: true,
      );
    }
    if (item.category == 'outdoors') {
      return const InterestActivityMetadata(
        locality: InterestLocality.outdoorPlace,
        socialModes: {InterestSocialMode.solo, InterestSocialMode.smallGroup},
        seasonal: true,
      );
    }
    if (item.category == 'sports') {
      final solo = item.id == 'sports.running' || item.id == 'sports.hiking';
      return InterestActivityMetadata(
        locality: InterestLocality.localSocial,
        socialModes: solo
            ? const {InterestSocialMode.solo, InterestSocialMode.smallGroup}
            : const {InterestSocialMode.pair, InterestSocialMode.smallGroup, InterestSocialMode.team},
        requiresVenue: !solo,
        requiresPartner: !solo,
        timeSensitive: !solo,
      );
    }
    if (item.category == 'gaming' && cluster.startsWith('tabletop')) {
      return const InterestActivityMetadata(
        locality: InterestLocality.localSocial,
        socialModes: {InterestSocialMode.pair, InterestSocialMode.smallGroup},
        requiresPartner: true,
        timeSensitive: true,
      );
    }
    if (item.id == 'music.karaoke') {
      return const InterestActivityMetadata(
        locality: InterestLocality.venueBased,
        socialModes: {InterestSocialMode.pair, InterestSocialMode.smallGroup},
        requiresVenue: true,
      );
    }
    if (item.id == 'music.concerts') {
      return const InterestActivityMetadata(
        locality: InterestLocality.eventBased,
        socialModes: {InterestSocialMode.community, InterestSocialMode.spectator},
        requiresVenue: true,
        timeSensitive: true,
      );
    }
    if (item.category == 'food') {
      return const InterestActivityMetadata(
        locality: InterestLocality.optional,
        socialModes: {InterestSocialMode.solo, InterestSocialMode.smallGroup},
      );
    }
    return const InterestActivityMetadata(
      locality: InterestLocality.none,
      socialModes: {InterestSocialMode.community},
    );
  }
}

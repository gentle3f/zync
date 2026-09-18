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
  static const double maxWeeklyMove = 6;
  static const double benchmarkSelectionRate = 0.25;

  static double baseScore(InterestDefinition item, String region) {
    final r = math.max(0, item.rank);
    final global = (96 - 12 * math.log(1 + (r / 100))).clamp(35.0, 96.0);
    return (global + _regionalBoost(item, InterestRegion.canonical(region)))
        .clamp(10.0, 100.0);
  }

  static double score(
    InterestDefinition item, {
    required String region,
    InterestPopularitySnapshot? popularity,
  }) {
    final base = baseScore(item, region);
    if (popularity == null) return base;

    final older = _blend(base, popularity.older[item.id]);
    final proposed = _blend(base, popularity.previous[item.id]);
    return proposed.clamp(older - maxWeeklyMove, older + maxWeeklyMove);
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
        if (id == 'music.cantopop') boost += 25;
        if (clusterStarts('music/hk_cantopop')) boost += 22;
        if (id == 'gaming.mahjong') boost += 20;
        if (id == 'sports.badminton') boost += 12;
        if (id == 'sports.hiking') boost += 16;
        if (id == 'music.karaoke') boost += 10;
        if (inIds({
          'food.hong_kong', 'food.cantonese', 'food.dim_sum',
          'entertainment.movie_subgenre.hong_kong_action_cinema',
          'entertainment.movie_subgenre.hong_kong_new_wave',
          'entertainment.modern_film.infernal_affairs',
          'entertainment.modern_film.in_the_mood_for_love',
          'entertainment.modern_film.chungking_express',
          'entertainment.modern_film.fallen_angels',
          'entertainment.modern_film.happy_together',
          'entertainment.modern_film.a_better_tomorrow',
          'entertainment.modern_film.hard_boiled',
          'entertainment.modern_film.police_story',
          'entertainment.modern_film.drunken_master',
          'entertainment.modern_film.kung_fu_hustle',
          'entertainment.modern_film.shaolin_soccer',
          'entertainment.modern_film.ip_man',
          'entertainment.modern_film.the_grandmaster',
        })) {
          boost += 18;
        }
        if (inIds({
          'food.dish.cantonese_roast_meat',
          'food.dish.char_siu',
          'food.dish.roast_goose',
          'food.dish.claypot_rice',
          'food.dish.wonton_noodles',
          'food.dish.beef_brisket_noodles',
          'food.dish.hong_kong_milk_tea',
          'food.dish.pineapple_bun',
          'food.dish.egg_tart',
          'food.dish.french_toast_hong_kong_style',
        })) {
          boost += 18;
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
        if (id == 'sports.american_football') boost += 22;
        if (id == 'sports.baseball') boost += 16;
        if (id == 'sports.basketball') boost += 14;
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

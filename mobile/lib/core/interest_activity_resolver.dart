import 'interest_card_policy_resolver.dart';
import 'interest_entity_metadata.dart';
import 'interest_localization_policy.dart';
import 'models.dart';

/// Resolves a safe Phase-1 activity profile for an official interest.
///
/// Explicit per-interest metadata always wins. Generic taxonomy defaults then
/// provide scalable coverage for low-risk families. Proper titles / artists /
/// franchises do not receive automatic defaults yet: they need a curated entity
/// type / rights-aware rule or explicit metadata.
///
/// This is intentionally conservative. Unsupported does not mean "never"; it
/// means "do not auto-generate a real-world activity from this concept yet".
class InterestActivityResolver {
  const InterestActivityResolver._();

  static ActivityProfile? resolve(InterestDefinition item) {
    final explicit =
        InterestEntityMetadataRegistry.byInterestId(item.id)?.activity;
    if (explicit != null) return explicit;

    // Rights-aware partner/title classifications must never fall through to a
    // generic activity merely because their localization metadata is complete.
    if (InterestCardPolicyResolver.resolve(item).ipSensitive) return null;

    // Localization remains a secondary proper-name boundary for legacy items
    // that have not yet received a full entity/card classification.
    if (!InterestLocalizationPolicy.requiresChinese(item)) return null;

    final cluster = item.cluster;

    if (item.category == 'sports') {
      if (const {'racket', 'team_ball'}.contains(cluster)) {
        return _socialSport;
      }
      if (cluster == 'running') return _running;
      if (cluster == 'mind_sports') return _mindSport;
      // Combat, precision, skating and other higher-risk families stay explicit.
      return null;
    }

    if (item.category == 'gaming') return _gaming;

    if (item.category == 'music') {
      if (cluster.contains('making')) return _musicMaking;
      return _musicListening;
    }

    if (item.category == 'entertainment') {
      if (cluster == 'audio') return _listenAndDiscuss;
      return _watchAndDiscuss;
    }

    if (item.category == 'arts') {
      if (cluster == 'dance') return _dance;
      if (cluster.contains('photography')) return _photography;
      return _creativeMaking;
    }

    if (item.category == 'crafts') return _creativeMaking;

    if (item.category == 'learning' && cluster.contains('books')) {
      return _reading;
    }

    if (item.category == 'food') {
      if (const {'food.cafe_hopping', 'food.brunch'}.contains(item.id)) {
        return _socialExploration;
      }
      if (cluster == 'cooking' ||
          cluster == 'cuisines' ||
          cluster == 'food_types' ||
          cluster == 'coffee' ||
          cluster == 'food/cuisines' ||
          cluster == 'food/dishes') {
        return _foodMaking;
      }
      // Deep drinks include alcohol, so they are not auto-enabled.
      return null;
    }

    if (item.category == 'lifestyle') {
      if (cluster == 'shopping') return _browseAndCompare;
      if (cluster == 'social') {
        if (const {'lifestyle.bars', 'lifestyle.nightlife'}.contains(item.id)) {
          return null;
        }
        return _socialExploration;
      }
      return null;
    }

    if (item.category == 'wellness') {
      if (const {
        'wellness.meditation',
        'wellness.mindfulness',
        'wellness.breathwork',
        'wellness.self_care',
        'wellness.recovery',
        'wellness.digital_detox',
      }.contains(item.id)) {
        return _wellnessReset;
      }
      if (const {'wellness.spa', 'wellness.sound_bath'}.contains(item.id)) {
        return _wellnessExperience;
      }
      return null;
    }

    return null;
  }

  static const ActivityProfile _socialSport = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
    energy: {ActivityEnergy.moderate, ActivityEnergy.active},
    settings: {ActivitySetting.indoor, ActivitySetting.outdoor},
    costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    equipmentLikely: true,
    locationDependency: LocationDependency.genericSpace,
    crossoverTags: {'movement', 'friendly-competition'},
    templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
  );

  static const ActivityProfile _running = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.practice, ActivityVerb.challenge},
    energy: {ActivityEnergy.moderate, ActivityEnergy.active},
    settings: {ActivitySetting.outdoor, ActivitySetting.either},
    costBands: {ActivityCostBand.free, ActivityCostBand.low},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.genericSpace,
    crossoverTags: {'movement', 'outdoors', 'challenge'},
    templateIds: {'activity.shared_mini_challenge'},
  );

  static const ActivityProfile _mindSport = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
    costBands: {ActivityCostBand.free, ActivityCostBand.low},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'strategy', 'friendly-competition'},
    templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
  );

  static const ActivityProfile _gaming = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
    costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    equipmentLikely: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'gaming', 'challenge', 'co-op'},
    templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
  );

  static const ActivityProfile _musicListening = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.listen, ActivityVerb.discuss},
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {
      ActivitySetting.indoor,
      ActivitySetting.outdoor,
      ActivitySetting.homePossible,
    },
    costBands: {ActivityCostBand.free, ActivityCostBand.low},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'music', 'listening', 'conversation'},
    templateIds: {'activity.listen_and_compare', 'activity.peer_teaches_beginner'},
  );

  static const ActivityProfile _musicMaking = ActivityProfile(
    eligible: true,
    verbs: {
      ActivityVerb.practice,
      ActivityVerb.learn,
      ActivityVerb.challenge,
      ActivityVerb.listen,
    },
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
    costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    equipmentLikely: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'music', 'creative', 'performance'},
    templateIds: {'activity.peer_teaches_beginner', 'activity.shared_mini_challenge'},
  );

  static const ActivityProfile _watchAndDiscuss = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.watch, ActivityVerb.discuss},
    energy: {ActivityEnergy.chill},
    settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
    costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'screen', 'story', 'conversation'},
    templateIds: {'activity.watch_and_compare'},
  );

  static const ActivityProfile _photography = ActivityProfile(
    eligible: true,
    verbs: {
      ActivityVerb.make,
      ActivityVerb.learn,
      ActivityVerb.explore,
      ActivityVerb.challenge,
    },
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.either},
    costBands: {ActivityCostBand.free, ActivityCostBand.low},
    durationBands: {
      ActivityDurationBand.under30m,
      ActivityDurationBand.under90m,
      ActivityDurationBand.halfDay,
    },
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'photography', 'creative', 'exploration'},
    templateIds: {'activity.photo_theme_challenge', 'activity.peer_teaches_beginner'},
  );

  static const ActivityProfile _dance = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.practice, ActivityVerb.learn, ActivityVerb.challenge},
    energy: {ActivityEnergy.moderate, ActivityEnergy.active},
    settings: {ActivitySetting.indoor, ActivitySetting.outdoor},
    costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.genericSpace,
    crossoverTags: {'dance', 'movement', 'music', 'social'},
    templateIds: {'activity.peer_teaches_beginner', 'activity.shared_mini_challenge'},
  );

  static const ActivityProfile _creativeMaking = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.make, ActivityVerb.learn, ActivityVerb.challenge},
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
    costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {
      ActivityDurationBand.under30m,
      ActivityDurationBand.under90m,
      ActivityDurationBand.halfDay,
    },
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    equipmentLikely: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'creative', 'making'},
    templateIds: {'activity.create_together', 'activity.peer_teaches_beginner'},
  );

  static const ActivityProfile _reading = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.read, ActivityVerb.discuss},
    energy: {ActivityEnergy.chill},
    settings: {
      ActivitySetting.indoor,
      ActivitySetting.outdoor,
      ActivitySetting.homePossible,
    },
    costBands: {ActivityCostBand.free, ActivityCostBand.low},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'reading', 'story', 'conversation'},
    templateIds: {'activity.read_and_compare'},
  );

  static const ActivityProfile _listenAndDiscuss = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.listen, ActivityVerb.discuss},
    energy: {ActivityEnergy.chill},
    settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.homePossible},
    costBands: {ActivityCostBand.free, ActivityCostBand.low},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'audio', 'story', 'conversation'},
    templateIds: {'activity.listen_and_compare'},
  );

  static const ActivityProfile _browseAndCompare = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.explore, ActivityVerb.challenge, ActivityVerb.discuss},
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.either},
    costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
    minGroupSize: 2,
    maxGroupSize: 8,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.dedicatedVenue,
    crossoverTags: {'discovery', 'shopping', 'conversation'},
    templateIds: {'activity.browse_theme_challenge', 'activity.shared_exploration'},
  );

  static const ActivityProfile _socialExploration = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.explore, ActivityVerb.discuss, ActivityVerb.challenge},
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.either},
    costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
    minGroupSize: 2,
    maxGroupSize: 8,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.dedicatedVenue,
    crossoverTags: {'social', 'discovery', 'conversation'},
    templateIds: {'activity.shared_exploration', 'activity.shared_mini_challenge'},
  );

  static const ActivityProfile _wellnessReset = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.practice, ActivityVerb.discuss},
    energy: {ActivityEnergy.chill},
    settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.homePossible, ActivitySetting.either},
    costBands: {ActivityCostBand.free, ActivityCostBand.low},
    durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
    minGroupSize: 2,
    maxGroupSize: 8,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'wellness', 'reset', 'low-pressure'},
    templateIds: {'activity.simple_wellness_reset'},
  );

  static const ActivityProfile _wellnessExperience = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.explore, ActivityVerb.practice},
    energy: {ActivityEnergy.chill},
    settings: {ActivitySetting.indoor},
    costBands: {ActivityCostBand.low, ActivityCostBand.medium, ActivityCostBand.high},
    durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
    minGroupSize: 2,
    maxGroupSize: 8,
    firstTimerFriendly: true,
    locationDependency: LocationDependency.dedicatedVenue,
    crossoverTags: {'wellness', 'experience', 'relaxation'},
    templateIds: {'activity.shared_exploration'},
  );

  static const ActivityProfile _foodMaking = ActivityProfile(
    eligible: true,
    verbs: {ActivityVerb.make, ActivityVerb.learn, ActivityVerb.discuss},
    energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
    settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
    costBands: {ActivityCostBand.low, ActivityCostBand.medium},
    durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
    minGroupSize: 2,
    maxGroupSize: 8,
    peerTeachable: true,
    firstTimerFriendly: true,
    equipmentLikely: true,
    locationDependency: LocationDependency.none,
    crossoverTags: {'food', 'making', 'conversation'},
    templateIds: {'activity.make_and_compare', 'activity.peer_teaches_beginner'},
  );
}

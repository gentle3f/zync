enum ZyncEntityKind {
  interestConcept,
  mediaFranchise,
  brandAffinity,
  activityExperience,
  venue,
  place,
  community,
  intent,
}

enum ActivityVerb {
  play,
  make,
  learn,
  watch,
  listen,
  read,
  discuss,
  explore,
  practice,
  challenge,
}

enum ActivityEnergy { chill, moderate, active }

enum ActivitySetting { indoor, outdoor, either, homePossible }

enum ActivityCostBand { free, low, medium, high }

enum ActivityDurationBand { under30m, under90m, halfDay, flexible }

enum LocationDependency { none, genericSpace, dedicatedVenue }

enum CardArtPolicy { originalGeneric, abstractOnly, licensedOnly, notCollectible }

class ActivityProfile {
  const ActivityProfile({
    required this.eligible,
    this.verbs = const {},
    this.energy = const {},
    this.settings = const {},
    this.costBands = const {},
    this.durationBands = const {},
    this.minGroupSize = 2,
    this.maxGroupSize = 8,
    this.peerTeachable = false,
    this.firstTimerFriendly = false,
    this.equipmentLikely = false,
    this.locationDependency = LocationDependency.none,
    this.crossoverTags = const {},
    this.templateIds = const {},
  });

  final bool eligible;
  final Set<ActivityVerb> verbs;
  final Set<ActivityEnergy> energy;
  final Set<ActivitySetting> settings;
  final Set<ActivityCostBand> costBands;
  final Set<ActivityDurationBand> durationBands;
  final int minGroupSize;
  final int maxGroupSize;
  final bool peerTeachable;
  final bool firstTimerFriendly;
  final bool equipmentLikely;
  final LocationDependency locationDependency;
  final Set<String> crossoverTags;
  final Set<String> templateIds;
}

class CardProfile {
  const CardProfile({
    required this.collectible,
    this.cardNumber,
    this.visualFamily = '',
    this.iconKey = '',
    this.categoryKit = '',
    this.artPolicy = CardArtPolicy.notCollectible,
    this.supportedEditions = const {'core'},
  });

  final bool collectible;

  /// Deliberately optional until the full released card numbering scheme is
  /// frozen. Never renumber a released card merely because catalog order moves.
  final int? cardNumber;

  final String visualFamily;
  final String iconKey;
  final String categoryKit;
  final CardArtPolicy artPolicy;
  final Set<String> supportedEditions;
}

class InterestEntityMetadata {
  const InterestEntityMetadata({
    required this.interestId,
    this.kind = ZyncEntityKind.interestConcept,
    this.activity,
    this.card,
  });

  final String interestId;
  final ZyncEntityKind kind;
  final ActivityProfile? activity;
  final CardProfile? card;
}

/// Additive metadata around the existing canonical catalog. This registry must
/// never change exact-match semantics: canonical ID equality remains the only
/// way two selected interests become an exact shared interest.
///
/// The first entries are intentionally representative, not an attempt to finish
/// all 3,000+ interests in one risky migration.
class InterestEntityMetadataRegistry {
  const InterestEntityMetadataRegistry._();

  static const Map<String, InterestEntityMetadata> entries = {
    'sports.badminton': InterestEntityMetadata(
      interestId: 'sports.badminton',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.moderate, ActivityEnergy.active},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor},
        costBands: {ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.genericSpace,
        crossoverTags: {'racket', 'movement', 'friendly-competition'},
        templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'sports_racket',
        iconKey: 'shuttlecock',
        categoryKit: 'sports',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'sports.tennis': InterestEntityMetadata(
      interestId: 'sports.tennis',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.moderate, ActivityEnergy.active},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor},
        costBands: {ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.genericSpace,
        crossoverTags: {'racket', 'movement', 'friendly-competition'},
        templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'sports_racket',
        iconKey: 'tennis_ball',
        categoryKit: 'sports',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'sports.running': InterestEntityMetadata(
      interestId: 'sports.running',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.practice, ActivityVerb.challenge},
        energy: {ActivityEnergy.moderate, ActivityEnergy.active},
        settings: {ActivitySetting.outdoor, ActivitySetting.either},
        costBands: {ActivityCostBand.free, ActivityCostBand.low},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        firstTimerFriendly: true,
        locationDependency: LocationDependency.genericSpace,
        crossoverTags: {'movement', 'outdoors', 'challenge'},
        templateIds: {'activity.shared_mini_challenge'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'sports_running',
        iconKey: 'running',
        categoryKit: 'sports',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'sports.hiking': InterestEntityMetadata(
      interestId: 'sports.hiking',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.explore, ActivityVerb.practice},
        energy: {ActivityEnergy.moderate, ActivityEnergy.active},
        settings: {ActivitySetting.outdoor},
        costBands: {ActivityCostBand.free, ActivityCostBand.low},
        durationBands: {ActivityDurationBand.halfDay, ActivityDurationBand.flexible},
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.genericSpace,
        crossoverTags: {'outdoors', 'nature', 'photography'},
        templateIds: {'activity.shared_exploration'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'outdoors_trail',
        iconKey: 'trail',
        categoryKit: 'outdoors',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'outdoors.bouldering': InterestEntityMetadata(
      interestId: 'outdoors.bouldering',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.active},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor},
        costBands: {ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.dedicatedVenue,
        crossoverTags: {'climbing', 'movement', 'challenge'},
        templateIds: {'activity.peer_teaches_beginner', 'activity.shared_mini_challenge'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'outdoors_climbing',
        iconKey: 'bouldering',
        categoryKit: 'outdoors',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'food.coffee': InterestEntityMetadata(
      interestId: 'food.coffee',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.make, ActivityVerb.learn, ActivityVerb.discuss},
        energy: {ActivityEnergy.chill},
        settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'taste', 'making', 'conversation'},
        templateIds: {'activity.make_and_compare', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'food_drink',
        iconKey: 'coffee',
        categoryKit: 'food',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'collecting.lego': InterestEntityMetadata(
      interestId: 'collecting.lego',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.make, ActivityVerb.challenge},
        energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
        settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'building', 'creative', 'challenge'},
        templateIds: {'activity.create_together', 'activity.shared_mini_challenge'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'collecting_building',
        iconKey: 'building_bricks',
        categoryKit: 'collecting',
        artPolicy: CardArtPolicy.abstractOnly,
      ),
    ),
    'motorsport.formula1': InterestEntityMetadata(
      interestId: 'motorsport.formula1',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.watch, ActivityVerb.discuss, ActivityVerb.challenge},
        energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
        settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.free, ActivityCostBand.low},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'motorsport', 'strategy', 'watching'},
        templateIds: {'activity.watch_and_compare', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'motorsport_racing',
        iconKey: 'race_car_abstract',
        categoryKit: 'motorsport',
        artPolicy: CardArtPolicy.abstractOnly,
      ),
    ),
    'sports.basketball': InterestEntityMetadata(
      interestId: 'sports.basketball',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.moderate, ActivityEnergy.active},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor},
        costBands: {ActivityCostBand.free, ActivityCostBand.low},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.genericSpace,
        crossoverTags: {'ball', 'movement', 'friendly-competition'},
        templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'sports_team_ball',
        iconKey: 'basketball',
        categoryKit: 'sports',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'sports.table_tennis': InterestEntityMetadata(
      interestId: 'sports.table_tennis',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.moderate, ActivityEnergy.active},
        settings: {ActivitySetting.indoor},
        costBands: {ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.genericSpace,
        crossoverTags: {'racket', 'movement', 'friendly-competition'},
        templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'sports_racket',
        iconKey: 'table_tennis',
        categoryKit: 'sports',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'sports.pickleball': InterestEntityMetadata(
      interestId: 'sports.pickleball',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.moderate, ActivityEnergy.active},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor},
        costBands: {ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.genericSpace,
        crossoverTags: {'racket', 'movement', 'friendly-competition'},
        templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'sports_racket',
        iconKey: 'pickleball',
        categoryKit: 'sports',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'outdoors.swimming': InterestEntityMetadata(
      interestId: 'outdoors.swimming',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.practice, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.moderate, ActivityEnergy.active},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor},
        costBands: {ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: false,
        firstTimerFriendly: false,
        equipmentLikely: true,
        locationDependency: LocationDependency.dedicatedVenue,
        crossoverTags: {'water', 'movement', 'fitness'},
        templateIds: {'activity.shared_mini_challenge'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'outdoors_water',
        iconKey: 'swimming',
        categoryKit: 'outdoors',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'wellness.yoga': InterestEntityMetadata(
      interestId: 'wellness.yoga',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.practice, ActivityVerb.learn},
        energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: false,
        locationDependency: LocationDependency.none,
        crossoverTags: {'wellness', 'movement', 'mind-body'},
        templateIds: {'activity.peer_teaches_beginner', 'activity.shared_mini_challenge'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'wellness_mind_body',
        iconKey: 'yoga',
        categoryKit: 'wellness',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'food.cooking': InterestEntityMetadata(
      interestId: 'food.cooking',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.make, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
        settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'food', 'making', 'creative'},
        templateIds: {'activity.make_and_compare', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'food_cooking',
        iconKey: 'cooking',
        categoryKit: 'food',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'photography.general': InterestEntityMetadata(
      interestId: 'photography.general',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.make, ActivityVerb.learn, ActivityVerb.explore, ActivityVerb.challenge},
        energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.either},
        costBands: {ActivityCostBand.free, ActivityCostBand.low},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: false,
        locationDependency: LocationDependency.none,
        crossoverTags: {'photography', 'creative', 'exploration'},
        templateIds: {'activity.photo_theme_challenge', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'arts_photography',
        iconKey: 'camera',
        categoryKit: 'arts',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'photography.street': InterestEntityMetadata(
      interestId: 'photography.street',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.make, ActivityVerb.explore, ActivityVerb.challenge},
        energy: {ActivityEnergy.moderate},
        settings: {ActivitySetting.outdoor},
        costBands: {ActivityCostBand.free, ActivityCostBand.low},
        durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: false,
        locationDependency: LocationDependency.genericSpace,
        crossoverTags: {'photography', 'creative', 'exploration', 'walking'},
        templateIds: {'activity.photo_theme_challenge'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'arts_photography',
        iconKey: 'street_camera',
        categoryKit: 'arts',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'media.movies': InterestEntityMetadata(
      interestId: 'media.movies',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.watch, ActivityVerb.discuss},
        energy: {ActivityEnergy.chill},
        settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: true,
        firstTimerFriendly: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'screen', 'story', 'conversation'},
        templateIds: {'activity.watch_and_compare'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'entertainment_cinema',
        iconKey: 'film',
        categoryKit: 'entertainment',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'music.pop': InterestEntityMetadata(
      interestId: 'music.pop',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.listen, ActivityVerb.discuss, ActivityVerb.challenge},
        energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.free, ActivityCostBand.low},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'music', 'listening', 'conversation'},
        templateIds: {'activity.listen_and_compare'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'music_genre',
        iconKey: 'music_note',
        categoryKit: 'music',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'gaming.video': InterestEntityMetadata(
      interestId: 'gaming.video',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.play, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
        settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'gaming', 'challenge', 'co-op'},
        templateIds: {'activity.play_casual', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'gaming_general',
        iconKey: 'gamepad',
        categoryKit: 'gaming',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'books.reading': InterestEntityMetadata(
      interestId: 'books.reading',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.read, ActivityVerb.discuss},
        energy: {ActivityEnergy.chill},
        settings: {ActivitySetting.indoor, ActivitySetting.outdoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.free, ActivityCostBand.low},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m},
        peerTeachable: true,
        firstTimerFriendly: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'reading', 'story', 'conversation'},
        templateIds: {'activity.read_and_compare'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'learning_books',
        iconKey: 'book',
        categoryKit: 'learning',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),
    'crafts.diy': InterestEntityMetadata(
      interestId: 'crafts.diy',
      activity: ActivityProfile(
        eligible: true,
        verbs: {ActivityVerb.make, ActivityVerb.learn, ActivityVerb.challenge},
        energy: {ActivityEnergy.chill, ActivityEnergy.moderate},
        settings: {ActivitySetting.indoor, ActivitySetting.homePossible},
        costBands: {ActivityCostBand.free, ActivityCostBand.low, ActivityCostBand.medium},
        durationBands: {ActivityDurationBand.under30m, ActivityDurationBand.under90m, ActivityDurationBand.halfDay},
        peerTeachable: true,
        firstTimerFriendly: true,
        equipmentLikely: true,
        locationDependency: LocationDependency.none,
        crossoverTags: {'crafts', 'creative', 'making'},
        templateIds: {'activity.create_together', 'activity.peer_teaches_beginner'},
      ),
      card: CardProfile(
        collectible: true,
        visualFamily: 'crafts_diy',
        iconKey: 'tools',
        categoryKit: 'crafts',
        artPolicy: CardArtPolicy.originalGeneric,
      ),
    ),

  };

  static InterestEntityMetadata? byInterestId(String id) => entries[id];

  static Iterable<InterestEntityMetadata> get zyncNowEligible =>
      entries.values.where((item) => item.activity?.eligible ?? false);

  static Iterable<InterestEntityMetadata> get collectible =>
      entries.values.where((item) => item.card?.collectible ?? false);
}

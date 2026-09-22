import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_activity_resolver.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/interest_entity_metadata.dart';

void main() {
  test('explicit metadata wins even when taxonomy has no automatic default', () {
    final bouldering = InterestCatalog.byId('outdoors.bouldering');
    expect(bouldering, isNotNull);

    final profile = InterestActivityResolver.resolve(bouldering!);
    expect(profile, isNotNull);
    expect(profile!.eligible, isTrue);
    expect(profile.locationDependency, LocationDependency.dedicatedVenue);
  });

  test('generic taxonomy defaults scale beyond hand-written metadata', () {
    final strategy = InterestCatalog.byId('gaming.rpg');
    final shoegaze = InterestCatalog.byId('music.style.shoegaze');

    expect(strategy, isNotNull);
    expect(shoegaze, isNotNull);
    expect(
      InterestEntityMetadataRegistry.byInterestId('gaming.rpg'),
      isNull,
      reason: 'test must exercise taxonomy default rather than explicit override',
    );
    expect(
      InterestEntityMetadataRegistry.byInterestId('music.style.shoegaze'),
      isNull,
      reason: 'test must exercise taxonomy default rather than explicit override',
    );

    final strategyProfile = InterestActivityResolver.resolve(strategy!);
    final shoegazeProfile = InterestActivityResolver.resolve(shoegaze!);

    expect(strategyProfile, isNotNull);
    expect(strategyProfile!.verbs, contains(ActivityVerb.play));
    expect(shoegazeProfile, isNotNull);
    expect(shoegazeProfile!.verbs, contains(ActivityVerb.listen));
  });

  test('proper titles and franchises are not auto-enabled as activities', () {
    final minecraft = InterestCatalog.byId('gaming.minecraft');
    final classicFilm =
        InterestCatalog.byId('entertainment.classic_film.the_godfather');
    final jojo = InterestCatalog.byId('anime.jojo');

    expect(minecraft, isNotNull);
    expect(classicFilm, isNotNull);
    expect(jojo, isNotNull);
    expect(InterestActivityResolver.resolve(minecraft!), isNull);
    expect(InterestActivityResolver.resolve(classicFilm!), isNull);
    expect(InterestActivityResolver.resolve(jojo!), isNull);
  });

  test('higher-risk sport families stay unsupported without explicit review', () {
    final boxing = InterestCatalog.byId('sports.boxing');
    final shooting = InterestCatalog.byId('sports.shooting_sport');

    expect(boxing, isNotNull);
    expect(shooting, isNotNull);
    expect(InterestActivityResolver.resolve(boxing!), isNull);
    expect(InterestActivityResolver.resolve(shooting!), isNull);
  });

  test('new social and wellness concepts can feed safe Zync Now activities', () {
    final thrifting = InterestCatalog.byId('lifestyle.thrifting')!;
    final cityWalks = InterestCatalog.byId('lifestyle.city_walks')!;
    final cafeHopping = InterestCatalog.byId('food.cafe_hopping')!;
    final brunch = InterestCatalog.byId('food.brunch')!;
    final selfCare = InterestCatalog.byId('wellness.self_care')!;
    final podcasts = InterestCatalog.byId('entertainment.podcasts')!;
    expect(InterestActivityResolver.resolve(thrifting)!.templateIds, contains('activity.browse_theme_challenge'));
    expect(InterestActivityResolver.resolve(cityWalks), isNotNull);
    expect(InterestActivityResolver.resolve(cafeHopping)!.templateIds, contains('activity.shared_exploration'));
    expect(InterestActivityResolver.resolve(brunch)!.templateIds, contains('activity.shared_exploration'));
    expect(InterestActivityResolver.resolve(selfCare)!.templateIds, contains('activity.simple_wellness_reset'));
    expect(InterestActivityResolver.resolve(podcasts)!.verbs, contains(ActivityVerb.listen));
  });

  test('health-adjacent wellness concepts stay matchable but are not auto-prescribed', () {
    expect(InterestActivityResolver.resolve(InterestCatalog.byId('wellness.nutrition')!), isNull);
    expect(InterestActivityResolver.resolve(InterestCatalog.byId('wellness.massage')!), isNull);
  });

  test('brand affinities remain matchable but do not auto-generate activities', () {
    expect(InterestActivityResolver.resolve(InterestCatalog.byId('transport.car_brand.porsche')!), isNull);
    expect(InterestActivityResolver.resolve(InterestCatalog.byId('entertainment.youtube')!), isNull);
  });

  test('dance and performance use movement/performance semantics', () {
    final salsa = InterestCatalog.byId('arts.salsa_dancing')!;
    final acting = InterestCatalog.byId('arts.acting')!;

    final salsaProfile = InterestActivityResolver.resolve(salsa)!;
    final actingProfile = InterestActivityResolver.resolve(acting)!;

    expect(salsaProfile.verbs, contains(ActivityVerb.practice));
    expect(salsaProfile.crossoverTags, contains('dance'));
    expect(actingProfile.verbs, contains(ActivityVerb.practice));
    expect(actingProfile.crossoverTags, contains('performance'));
  });

  test('creator-like gaming concepts do not fall through to casual play semantics', () {
    final modding = InterestCatalog.search('game modding', 'en').first;
    final escapeDesign = InterestCatalog.byId('gaming.escape_room_design')!;
    final streaming = InterestCatalog.byId('gaming.game_streaming')!;

    expect(InterestActivityResolver.resolve(modding)!.verbs, contains(ActivityVerb.make));
    expect(InterestActivityResolver.resolve(escapeDesign)!.verbs, contains(ActivityVerb.make));
    expect(InterestActivityResolver.resolve(streaming), isNull);
  });

  test('abstract-only art policy does not incorrectly ban safe activity semantics', () {
    final bookTok = InterestCatalog.byId('learning.book_genre.booktok')!;
    final profile = InterestActivityResolver.resolve(bookTok);

    expect(profile, isNotNull);
    expect(profile!.verbs, contains(ActivityVerb.read));
    expect(profile.verbs, contains(ActivityVerb.discuss));
  });

  test('live culture avoids music-making and home-viewing fallthrough', () {
    final concerts = InterestCatalog.byId('music.concerts')!;
    final theatre = InterestCatalog.byId('entertainment.theatre_going')!;

    final concertProfile = InterestActivityResolver.resolve(concerts)!;
    final theatreProfile = InterestActivityResolver.resolve(theatre)!;

    expect(concertProfile.verbs, isNot(contains(ActivityVerb.practice)));
    expect(concertProfile.verbs, contains(ActivityVerb.explore));
    expect(concertProfile.locationDependency, LocationDependency.dedicatedVenue);

    expect(theatreProfile.verbs, contains(ActivityVerb.watch));
    expect(theatreProfile.verbs, contains(ActivityVerb.explore));
    expect(theatreProfile.settings, isNot(contains(ActivitySetting.homePossible)));
    expect(theatreProfile.locationDependency, LocationDependency.dedicatedVenue);
  });

  test('new dining and local-culture interests use low-risk exploration semantics', () {
    final yumCha = InterestCatalog.byId('food.yum_cha')!;
    final templeFairs = InterestCatalog.byId('lifestyle.temple_fairs')!;

    expect(
      InterestActivityResolver.resolve(yumCha)!.templateIds,
      contains('activity.shared_exploration'),
    );
    expect(
      InterestActivityResolver.resolve(templeFairs)!.templateIds,
      contains('activity.shared_exploration'),
    );
  });

  test('party and boat-party interests remain conservative despite social taxonomy', () {
    expect(
      InterestActivityResolver.resolve(InterestCatalog.byId('lifestyle.parties')!),
      isNull,
    );
    expect(
      InterestActivityResolver.resolve(InterestCatalog.byId('lifestyle.boat_parties')!),
      isNull,
    );
  });

  test('deep drink taxonomy is not automatically made an activity pool', () {
    final redWine = InterestCatalog.search('Red Wine', 'en').firstWhere(
      (item) => item.labels['en'] == 'Red Wine',
    );

    expect(redWine.cluster, 'food/drinks');
    expect(InterestActivityResolver.resolve(redWine), isNull);
  });
}

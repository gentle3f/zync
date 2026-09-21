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

    expect(minecraft, isNotNull);
    expect(classicFilm, isNotNull);
    expect(InterestActivityResolver.resolve(minecraft!), isNull);
    expect(InterestActivityResolver.resolve(classicFilm!), isNull);
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
    final selfCare = InterestCatalog.byId('wellness.self_care')!;
    final podcasts = InterestCatalog.byId('entertainment.podcasts')!;
    expect(InterestActivityResolver.resolve(thrifting)!.templateIds, contains('activity.browse_theme_challenge'));
    expect(InterestActivityResolver.resolve(cityWalks), isNotNull);
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

  test('deep drink taxonomy is not automatically made an activity pool', () {
    final redWine = InterestCatalog.search('Red Wine', 'en').firstWhere(
      (item) => item.labels['en'] == 'Red Wine',
    );

    expect(redWine.cluster, 'food/drinks');
    expect(InterestActivityResolver.resolve(redWine), isNull);
  });
}

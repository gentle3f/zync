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
    final strategy = InterestCatalog.byId('gaming.strategy');
    final shoegaze = InterestCatalog.byId('music.style.shoegaze');

    expect(strategy, isNotNull);
    expect(shoegaze, isNotNull);
    expect(
      InterestEntityMetadataRegistry.byInterestId('gaming.strategy'),
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

  test('deep drink taxonomy is not automatically made an activity pool', () {
    final redWine = InterestCatalog.search('Red Wine', 'en').firstWhere(
      (item) => item.labels['en'] == 'Red Wine',
    );

    expect(redWine.cluster, 'food/drinks');
    expect(InterestActivityResolver.resolve(redWine), isNull);
  });
}

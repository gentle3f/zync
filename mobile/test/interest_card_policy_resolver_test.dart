import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_card_policy_resolver.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/interest_entity_metadata.dart';

void main() {
  test('generic interests remain eligible for original Zync card art', () {
    final badminton = InterestCardPolicyResolver.resolve(InterestCatalog.byId('sports.badminton')!);
    final filmNoir = InterestCardPolicyResolver.resolve(InterestCatalog.search('Film Noir', 'en').first);
    expect(badminton.artPolicy, CardArtPolicy.originalGeneric);
    expect(badminton.baselineArtEligible, isTrue);
    expect(filmNoir.artPolicy, CardArtPolicy.originalGeneric);
    expect(filmNoir.ipSensitive, isFalse);
  });

  test('named artists, titles, games and brands are partner-only for card art', () {
    for (final id in const [
      'collecting.lego',
      'motorsport.formula1',
      'transport.car_brand.porsche',
      'entertainment.youtube',
      'entertainment.classic_film.the_godfather',
      'gaming.franchise.minecraft',
      'anime.jojo',
      'wellness.crossfit',
      'technology.chatgpt',
      'technology.android',
      'technology.apple',
      'motorsport.motogp',
      'motorsport.formula_e',
      'motorsport.wec',
      'motorsport.le_mans',
      'travel.style_deep.disney_parks_travel',
      'travel.style_deep.universal_studios_travel',
    ]) {
      final item = InterestCatalog.byId(id);
      expect(item, isNotNull, reason: 'missing policy fixture $id');
      final policy = InterestCardPolicyResolver.resolve(item!);
      expect(policy.artPolicy, CardArtPolicy.licensedOnly, reason: id);
      expect(policy.baselineArtEligible, isFalse, reason: id);
      expect(policy.ipSensitive, isTrue, reason: id);
      expect(policy.partnerOpportunity, isTrue, reason: id);
    }
  });

  test('car brand keeps a future partner unlock instead of baseline art', () {
    final policy = InterestCardPolicyResolver.resolve(InterestCatalog.byId('transport.car_brand.porsche')!);
    expect(policy.partnerType, 'automotive_brand');
    expect(policy.proxyFamily, 'cars');
    expect(policy.eventAffinityPriority, 'proxy_only');
  });
}

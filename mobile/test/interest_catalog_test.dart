import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/matching_service.dart';
import 'package:zync/core/models.dart';

void main() {
  test('bundled catalog reaches deep V1 coverage, stays unique, and preserves legacy IDs', () {
    expect(InterestCatalog.count, greaterThanOrEqualTo(2500));
    expect(InterestCatalog.count, lessThanOrEqualTo(3600));
    expect(InterestCatalog.seed.map((item) => item.id).toSet(), hasLength(InterestCatalog.count));

    for (final legacyId in const [
      'sports.badminton',
      'anime.jojo',
      'motorsport.formula1',
      'technology.ai',
      'food.coffee',
      'transport.railways',
      'collecting.lego',
    ]) {
      expect(InterestCatalog.byId(legacyId), isNotNull, reason: 'missing legacy ID $legacyId');
    }
  });

  test('same category never exposes two canonical IDs with the same English concept', () {
    final seen = <String, String>{};
    final collisions = <String>[];
    for (final item in InterestCatalog.seed) {
      final label = InterestCatalog.normalizeText(item.labels['en'] ?? '');
      if (label.isEmpty) continue;
      final key = '${item.category}|$label';
      final previous = seen[key];
      if (previous == null) {
        seen[key] = item.id;
      } else if (previous != item.id) {
        collisions.add('$label: $previous <> ${item.id}');
      }
    }
    expect(collisions, isEmpty, reason: collisions.take(60).join('\n'));
  });

  test('search handles aliases, Chinese terms, prefixes, titles and niche interests locally', () {
    expect(InterestCatalog.search('F1', 'en').first.id, 'motorsport.formula1');
    expect(InterestCatalog.search('羽球', 'zh-Hant').first.id, 'sports.badminton');
    expect(InterestCatalog.search('韓劇', 'zh-Hant').first.id, 'entertainment.k_drama');
    expect(InterestCatalog.search('bould', 'en').map((item) => item.id), contains('outdoors.bouldering'));
    expect(InterestCatalog.search('手沖咖啡', 'zh-Hant').first.id, 'food.pour_over');
    expect(
      InterestCatalog.search('琅琊榜', 'zh-Hant').map((item) => item.id),
      contains('entertainment.tv_drama.nirvana_in_fire'),
    );
    expect(
      InterestCatalog.search('사랑의 불시착', 'ko').map((item) => item.id),
      contains('entertainment.tv_drama.crash_landing_on_you'),
    );
    expect(
      InterestCatalog.search('shoegaze', 'en').map((item) => item.id),
      contains('music.style.shoegaze'),
    );
    expect(
      InterestCatalog.search('The Godfather', 'en').map((item) => item.id),
      contains('entertainment.classic_film.the_godfather'),
    );
  });

  test('Hong Kong Chinese locale resolves Traditional Chinese labels', () {
    expect(InterestCatalog.byId('sports.tennis')!.labelFor('zh-HK'), '網球');
    expect(InterestCatalog.byId('food.coffee')!.labelFor('zh-Hant'), '咖啡');
    expect(
      InterestCatalog.byId('entertainment.tv_drama.crash_landing_on_you')!.labelFor('zh-HK'),
      '愛的迫降',
    );
    expect(
      InterestCatalog.byId('entertainment.modern_film.spirited_away')!.labelFor('zh-HK'),
      '千與千尋',
    );
  });

  test('normalized two and three-level taxonomy browses old and deep catalog together', () {
    final entertainmentL2 = InterestCatalog.clustersForCategory('entertainment');
    expect(entertainmentL2, containsAll(<String>['movies', 'tv_drama', 'anime_manga', 'franchises']));

    final movieL3 = InterestCatalog.subclustersFor('entertainment', 'movies');
    expect(movieL3, containsAll(<String>['general', 'subgenres', 'classics', 'modern_evergreen', 'making']));

    final classics = InterestCatalog.popular(
      category: 'entertainment',
      cluster: 'movies',
      subcluster: 'classics',
      limit: 200,
    );
    expect(classics.map((item) => item.id), contains('entertainment.classic_film.casablanca'));

    final musicL2 = InterestCatalog.clustersForCategory('music');
    expect(musicL2, containsAll(<String>['genres_styles', 'artists', 'making']));
    final artistL3 = InterestCatalog.subclustersFor('music', 'artists');
    expect(artistL3, containsAll(<String>['artists_global', 'kpop_artists', 'japanese_artists', 'hk_cantopop', 'mandopop_artists']));
  });

  test('instant custom interests need no AI and normalize to a stable cross-device ID', () {
    final a = InterestCatalog.instantSelection('Indoor   Bouldering!!');
    final b = InterestCatalog.instantSelection(' indoor bouldering ');

    expect(a.id, b.id);
    expect(a.id, startsWith('custom.'));
    expect(a.customLabel, 'Indoor Bouldering!!');
    expect(a.customCategory, 'other');
  });

  test('known labels and aliases instantly resolve to canonical IDs instead of custom IDs', () {
    final f1 = InterestCatalog.instantSelection('formula one');
    final coffee = InterestCatalog.instantSelection('咖啡');

    expect(f1.id, 'motorsport.formula1');
    expect(f1.customLabel, isNull);
    expect(coffee.id, 'food.coffee');
    expect(coffee.customLabel, isNull);
  });

  test('related graph recommends nearby interests but never turns them into exact matches', () {
    final related = InterestCatalog.relatedTo(const ['sports.badminton'], limit: 12).map((item) => item.id).toList();

    expect(related, contains('sports.tennis'));
    expect(related, contains('sports.table_tennis'));
    expect(related, isNot(contains('sports.badminton')));

    const badminton = [SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love)];
    const tennis = [SelectedInterest(id: 'sports.tennis', strength: InterestStrength.love)];
    final match = MatchingService.compare(badminton, tennis);
    expect(match.shared, isEmpty);
    expect(match.onlyMine.single.id, 'sports.badminton');
    expect(match.onlyTheirs.single.id, 'sports.tennis');
  });

  test('category discovery remains bounded even with the deep catalog', () {
    expect(InterestCatalog.categories.length, greaterThanOrEqualTo(15));
    expect(InterestCatalog.popular(limit: 36), hasLength(36));
    expect(InterestCatalog.search('', 'en', limit: 40).length, lessThanOrEqualTo(40));
  });
}

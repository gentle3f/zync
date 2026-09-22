import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/interest_catalog_part16.dart';
import 'package:zync/core/interest_localization.dart';
import 'package:zync/core/matching_service.dart';
import 'package:zync/core/models.dart';

void main() {
  test('bundled catalog reaches deep V1 coverage, stays unique, and preserves legacy IDs', () {
    expect(InterestCatalog.count, 4053);
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

  test('same category never exposes ambiguous normalized search terms', () {
    final seen = <String, String>{};
    final collisions = <String>[];

    for (final item in InterestCatalog.seed) {
      final terms = <String>{
        ...item.labels.values,
        ...item.aliases,
        ...InterestLocaleRegistry.allLocalizedAliases(item.id),
        item.id.split('.').last.replaceAll('_', ' '),
      };

      for (final raw in terms) {
        final term = InterestCatalog.normalizeText(raw);
        if (term.isEmpty) continue;
        final key = '${item.category}|$term';
        final previous = seen[key];
        if (previous == null) {
          seen[key] = item.id;
        } else if (previous != item.id) {
          collisions.add('$term: $previous <> ${item.id}');
        }
      }
    }

    expect(collisions, isEmpty, reason: collisions.take(80).join('\n'));
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

  test('release-gap interests and car-brand affinities are searchable', () {
    for (final query in const [
      'triathlon', 'pottery', 'model making', 'scrapbooking', 'creative writing',
      'food photography', 'foraging', 'clubbing', 'shopping', 'thrifting',
      'flea markets', 'debating', 'PC building', 'hair styling', 'fragrance',
      'figurines', 'model cars', 'driving', 'stand-up comedy', 'podcasts',
      'massage', 'nutrition', 'self care', 'healthy eating',
    ]) {
      expect(InterestCatalog.search(query, 'en'), isNotEmpty, reason: 'release-gap query should resolve: $query');
    }
    expect(InterestCatalog.search('Porsche', 'en').first.id, 'transport.car_brand.porsche');
    expect(InterestCatalog.search('Mercedes', 'en').first.id, 'transport.car_brand.mercedes_benz');
    expect(InterestCatalog.search('BYD', 'en').first.id, 'transport.car_brand.byd');
  });

  test('everyday breadth expansion covers offline, maker, family and creator interests', () {
    final expected = <String, String>{
      'powerlifting': 'wellness.powerlifting',
      'salsa dancing': 'arts.salsa_dancing',
      'forest bathing': 'outdoors.forest_bathing',
      'bookbinding': 'crafts.bookbinding',
      'language exchange': 'learning.language_exchange',
      'homelab': 'technology.homelab',
      'comic collecting': 'collecting.comic_collecting',
      'parenting': 'lifestyle.parenting',
      'acting': 'arts.acting',
      'jigsaw puzzles': 'learning.jigsaw_puzzles',
      'motion graphics': 'arts.motion_graphics',
      'side hustles': 'business.side_hustles',
      'photo walks': 'arts.photo_walks',
    };

    for (final entry in expected.entries) {
      expect(
        InterestCatalog.search(entry.key, 'en').first.id,
        entry.value,
        reason: 'unexpected canonical for ${entry.key}',
      );
    }
  });

  test('Asia campus career and maker expansion resolves stable canonical IDs', () {
    final expected = <String, String>{
      'yum cha': 'food.yum_cha',
      'KTV': 'music.karaoke',
      'cha chaan teng': 'food.hong_kong',
      'river tracing': 'outdoors.river_tracing',
      'dragon boat racing': 'sports.dragon_boat_racing',
      'Model United Nations': 'learning.model_united_nations',
      'robotics club': 'technology.robotics',
      'debate club': 'learning.debating',
      'Moot Court': 'learning.moot_court',
      'bonsai': 'lifestyle.bonsai',
      'aquarium keeping': 'pets.fish',
      'dog agility': 'pets.dog_agility',
      'legal profession': 'career.legal_profession',
      'nursing': 'career.nursing',
      'cloud engineering': 'career.cloud_engineering',
      'metalworking': 'crafts.metalworking',
      'pottery wheel': 'crafts.pottery_wheel',
      'night hiking': 'outdoors.night_hiking',
      'junk boat parties': 'lifestyle.boat_parties',
    };

    for (final entry in expected.entries) {
      expect(
        InterestCatalog.search(entry.key, 'en').first.id,
        entry.value,
        reason: 'unexpected canonical for ${entry.key}',
      );
    }
  });

  test('USA Spanish and Hong Kong colloquial aliases resolve to canonicals', () {
    final cases = <(String, String, String)>[
      ('básquet', 'es', 'sports.basketball'),
      ('boba', 'es', 'food.bubble_tea'),
      ('tiendas de segunda mano', 'es', 'lifestyle.thrifting'),
      ('fútbol americano universitario', 'es', 'sports.college_football'),
      ('行山', 'zh-Hant', 'sports.hiking'),
      ('打機', 'zh-Hant', 'gaming.video'),
      ('唱K', 'zh-Hant', 'music.karaoke'),
      ('打邊爐', 'zh-Hant', 'food.hot_pot'),
      ('夾公仔', 'zh-Hant', 'gaming.claw_machines'),
      ('兄弟會', 'zh-Hant', 'learning.greek_life'),
    ];
    for (final row in cases) {
      expect(
        InterestCatalog.search(row.$1, row.$2).first.id,
        row.$3,
        reason: 'regional alias search failed for ${row.$1} (${row.$2})',
      );
    }
  });

  test('USA Spanish and Hong Kong alias V2 covers remaining colloquial gaps', () {
    final cases = <(String, String, String)>[
      ('ir de compras', 'es', 'lifestyle.shopping'),
      ('foto callejera', 'es', 'photography.street'),
      ('fans del fútbol americano', 'es', 'sports.american_football_fandom'),
      ('viajar a Corea', 'es', 'travel.korea'),
      ('韓舞', 'zh-Hant', 'arts.kpop_dance'),
      ('美妝', 'zh-Hant', 'fashion.makeup'),
      ('護膚', 'zh-Hant', 'fashion.skincare'),
      ('街拍', 'zh-Hant', 'photography.street'),
      ('市區行山', 'zh-Hant', 'outdoors.urban_hiking'),
      ('去韓國', 'zh-Hant', 'travel.korea'),
    ];
    for (final row in cases) {
      expect(
        InterestCatalog.search(row.$1, row.$2).first.id,
        row.$3,
        reason: 'launch alias V2 search failed for ${row.$1} (${row.$2})',
      );
    }
  });

  test('USA Spanish and Hong Kong alias V3 expands cars pets social and fitness', () {
    final cases = <(String, String, String)>[
      ('carros', 'es', 'motorsport.cars'),
      ('motos', 'es', 'transport.motorcycles'),
      ('sacar al perro', 'es', 'pets.dog_walking'),
      ('salir de fiesta', 'es', 'lifestyle.nightlife'),
      ('parques de diversiones', 'es', 'lifestyle.theme_parks'),
      ('levantar pesas', 'es', 'wellness.weightlifting'),
      ('揸車', 'zh-Hant', 'transport.driving'),
      ('老爺車', 'zh-Hant', 'transport.classic_cars'),
      ('放狗', 'zh-Hant', 'pets.dog_walking'),
      ('掃街', 'zh-Hant', 'food.street_food'),
      ('夜蒲', 'zh-Hant', 'lifestyle.nightlife'),
      ('拍拖', 'zh-Hant', 'lifestyle.date_nights'),
    ];
    for (final row in cases) {
      expect(
        InterestCatalog.search(row.$1, row.$2).first.id,
        row.$3,
        reason: 'launch alias V3 search failed for ${row.$1} (${row.$2})',
      );
    }
  });

  test('localized alias packs merge instead of overwriting older aliases', () {
    expect(
      InterestLocaleRegistry.aliasesFor('sports.sports_watch_parties', 'es'),
      containsAll(<String>[
        'Fiestas para ver el partido',
        'ver el partido',
        'fiesta para ver el partido',
      ]),
    );
    expect(
      InterestLocaleRegistry.aliasesFor(
        'sports.sports_watch_parties',
        'zh-Hant',
      ),
      containsAll(<String>['睇波派對', '睇波', '觀賽聚會']),
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

    final artsL2 = InterestCatalog.clustersForCategory('arts');
    expect(artsL2, containsAll(<String>['dance', 'performance', 'media_creation']));

    final lifestyleL2 = InterestCatalog.clustersForCategory('lifestyle');
    expect(lifestyleL2, containsAll(<String>['home', 'social', 'shopping', 'family']));

    final careerL2 = InterestCatalog.clustersForCategory('career');
    expect(
      careerL2,
      containsAll(<String>['legal', 'healthcare', 'education', 'engineering', 'finance', 'operations', 'research']),
    );

    final learningL2 = InterestCatalog.clustersForCategory('learning');
    expect(learningL2, contains('campus'));

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

  test('cross-category exact ambiguity is surfaced instead of first-winning', () {
    final persona = InterestCatalog.exactMatches('Persona');
    expect(
      persona.map((item) => item.id),
      containsAll(<String>[
        'entertainment.classic_film.persona',
        'gaming.franchise.persona',
      ]),
    );
    expect(InterestCatalog.exact('Persona'), isNull);
    expect(() => InterestCatalog.instantSelection('Persona'), throwsFormatException);

    expect(InterestCatalog.exact('Badminton')!.id, 'sports.badminton');
    expect(
      InterestCatalog.exact('City-Building Games')!.id,
      'gaming.subgenre.city_builder',
    );
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

  test('every seeded top-level category remains browsable', () {
    final seeded = InterestCatalog.seed.map((item) => item.category).toSet();
    expect(InterestCatalog.categories.toSet(), seeded);
    expect(InterestCatalog.categories, contains('career'));
  });

  test('quick start represents every top-level world before popularity fill', () {
    final quick = InterestCatalog.quickStart(limit: 24);
    expect(quick, hasLength(24));

    final represented = quick.map((item) => item.category).toSet();
    expect(represented, containsAll(InterestCatalog.categories));
    expect(represented.length, InterestCatalog.categories.length);
  });


  test('Part 16 is searchable in every launch locale', () {
    final cases = <(String, String, String)>[
      ('Afición al fútbol americano', 'es', 'sports.american_football_fandom'),
      ('Marchés éphémères', 'fr', 'lifestyle.pop_up_markets'),
      ('Fãs de basquetebol', 'pt', 'sports.basketball_fandom'),
      ('大学スポーツ', 'ja', 'sports.college_sports'),
      ('스터디 카페', 'ko', 'lifestyle.study_cafes'),
      ('車聚', 'zh-Hant', 'transport.car_meets'),
      ('夜宵', 'zh-Hans', 'food.late_night_eats'),
    ];
    for (final row in cases) {
      expect(
        InterestCatalog.search(row.$1, row.$2).first.id,
        row.$3,
        reason: 'localized search failed for ${row.$1} (${row.$2})',
      );
    }
  });

  test('Part 16 carries explicit labels for all eight supported locales', () {
    expect(kInterestCatalogPart16Ids, hasLength(118));
    for (final id in kInterestCatalogPart16Ids) {
      final item = InterestCatalog.byId(id);
      expect(item, isNotNull, reason: 'Part 16 ID missing: $id');
      for (final locale in InterestLocaleRegistry.supportedLocales) {
        expect(
          item!.labels[locale]?.trim(),
          isNotEmpty,
          reason: '$id missing explicit $locale label',
        );
      }
    }
  });

  test('USA and Hong Kong broad discovery use launch-sector ranking with diversity', () {
    final us = InterestCatalog.search('', 'en', region: 'us', limit: 30);
    final hk = InterestCatalog.search('', 'zh-Hant', region: 'hk', limit: 30);

    expect(us.take(8).map((item) => item.id), contains('sports.american_football'));
    expect(us.map((item) => item.id), containsAll(<String>[
      'learning.campus_life',
      'lifestyle.game_nights',
      'outdoors.state_parks',
      'sports.college_sports',
      'transport.car_meets',
    ]));

    expect(hk.take(8).map((item) => item.id), containsAll(<String>[
      'sports.hiking',
      'sports.badminton',
      'sports.gym',
      'food.cafe_hopping',
    ]));
    expect(hk.map((item) => item.id), containsAll(<String>[
      'media.anime',
      'outdoors.bouldering',
      'music.k_pop',
      'lifestyle.local_events',
      'music.cantopop',
      'arts.photo_walks',
      'music.karaoke',
    ]));

    for (final rows in [us.take(12), hk.take(12)]) {
      final counts = <String, int>{};
      for (final item in rows) {
        counts[item.category] = (counts[item.category] ?? 0) + 1;
      }
      expect(counts.values.every((count) => count <= 3), isTrue);
    }
  });

  test('category discovery remains bounded even with the deep catalog', () {
    expect(InterestCatalog.categories.length, greaterThanOrEqualTo(15));
    expect(InterestCatalog.popular(limit: 36), hasLength(36));
    expect(InterestCatalog.search('', 'en', limit: 40).length, lessThanOrEqualTo(40));
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/interest_popularity_service.dart';
import 'package:zync/core/interest_relevance.dart';

void main() {
  test('device region resolution is coarse and never needs GPS', () {
    expect(InterestRegion.fromLocale(const Locale('zh', 'HK')), 'hk');
    expect(InterestRegion.fromLocale(const Locale('zh', 'TW')), 'tw');
    expect(InterestRegion.fromLocale(const Locale('ja')), 'jp');
    expect(InterestRegion.fromLocale(const Locale('zh')), 'global');
    expect(InterestRegion.canonical('unknown-region'), 'global');
  });

  test('regional priors promote locally relevant interests without changing IDs', () {
    final cantopop = InterestCatalog.byId('music.cantopop')!;
    final badminton = InterestCatalog.byId('sports.badminton')!;
    expect(
      InterestRelevance.baseScore(cantopop, 'hk'),
      greaterThan(InterestRelevance.baseScore(cantopop, 'global')),
    );
    expect(
      InterestRelevance.baseScore(badminton, 'sg'),
      greaterThan(InterestRelevance.baseScore(badminton, 'global')),
    );
    expect(cantopop.id, 'music.cantopop');
  });

  test('regional ranking changes discovery order while canonical IDs stay stable', () {
    final hkMusic = InterestCatalog.popular(category: 'music', region: 'hk', limit: 100);
    final globalMusic = InterestCatalog.popular(category: 'music', region: 'global', limit: 100);
    final hkIndex = hkMusic.map((item) => item.id).toList().indexOf('music.cantopop');
    final globalIndex = globalMusic.map((item) => item.id).toList().indexOf('music.cantopop');

    expect(hkIndex, greaterThanOrEqualTo(0));
    expect(globalIndex, greaterThanOrEqualTo(0));
    expect(hkIndex, lessThan(globalIndex));
    expect(InterestCatalog.byId('music.cantopop')!.id, 'music.cantopop');
  });

  test('behavioural learning is prior-weighted and bounded around the curated base', () {
    final item = InterestCatalog.byId('music.cantopop')!;
    final base = InterestRelevance.baseScore(item, 'hk');
    final snapshot = InterestPopularitySnapshot(
      region: 'hk',
      previousWeek: '2026-09-14',
      olderWeek: '2026-09-07',
      previous: {
        item.id: const InterestSignalCount(impressions: 100000, selections: 100000),
      },
      older: const {},
    );
    final learned = InterestRelevance.score(item, region: 'hk', popularity: snapshot);
    expect(
      (learned - base).abs(),
      lessThanOrEqualTo(InterestRelevance.maxBehaviourAdjustment + 0.0001),
    );
  });

  test('small samples barely move the human prior', () {
    final item = InterestCatalog.byId('sports.badminton')!;
    final base = InterestRelevance.baseScore(item, 'hk');
    final snapshot = InterestPopularitySnapshot(
      region: 'hk',
      previousWeek: '2026-09-14',
      olderWeek: '2026-09-07',
      previous: {
        item.id: const InterestSignalCount(impressions: 10, selections: 10),
      },
      older: const {},
    );
    final learned = InterestRelevance.score(item, region: 'hk', popularity: snapshot);
    expect((learned - base).abs(), lessThan(1));
  });

  test('activity metadata preserves physical-locality dimension for future phases', () {
    final badminton = InterestCatalog.byId('sports.badminton')!;
    final movie = InterestCatalog.byId('entertainment.classic_film.casablanca')!;

    expect(
      InterestRelevance.activityMetadata(badminton).locality,
      InterestLocality.localSocial,
    );
    expect(
      InterestRelevance.activityMetadata(movie).locality,
      InterestLocality.none,
    );
  });
}

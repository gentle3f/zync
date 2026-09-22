import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/interest_catalog_part16.dart';
import 'package:zync/core/interest_localization.dart';
import 'package:zync/core/interest_localization_audit.dart';
import 'package:zync/core/interest_localization_policy.dart';
import 'package:zync/core/models.dart';

void main() {
  test('generic interest catalog is fully localized in both Chinese scripts', () {
    final audit = InterestLocalizationAudit.run();

    expect(audit.total, InterestCatalog.count);
    expect(audit.requiresChinese, greaterThan(0));
    expect(
      audit.missingZhHantIds,
      isEmpty,
      reason:
          'Missing zh-Hant generic interests: ${audit.missingZhHantIds.take(120).join(', ')}',
    );
    expect(
      audit.missingZhHansIds,
      isEmpty,
      reason:
          'Missing zh-Hans generic interests: ${audit.missingZhHansIds.take(120).join(', ')}',
    );
    expect(
      audit.migrationBacklog,
      0,
      reason:
          'Translation debt must be explicit and cleared before Cardverse mass rendering.',
    );
    expect(audit.complete, isTrue);
  });

  test('known generic leaves remain translated after future catalog edits', () {
    for (final id in const [
      'sports.table_tennis',
      'sports.squash',
      'sports.pickleball',
      'sports.volleyball',
      'sports.baseball',
      'outdoors.bouldering',
      'wellness.yoga',
      'food.cooking',
      'photography.general',
      'media.movies',
    ]) {
      final item = InterestCatalog.byId(id);
      expect(item, isNotNull, reason: 'Missing canonical interest: $id');
      expect(
        InterestLocalizationPolicy.requiresChinese(item!),
        isTrue,
        reason: '$id should be treated as a generic concept',
      );
      expect(
        item.labels['zh-Hant']?.trim(),
        isNotEmpty,
        reason: '$id lost its Traditional Chinese label',
      );
      expect(
        item.labels['zh-Hans']?.trim(),
        isNotEmpty,
        reason: '$id lost its Simplified Chinese label',
      );
    }
  });

  test('proper-name policy exceptions are not mistaken for generic debt', () {
    final destination = InterestCatalog.seed.firstWhere(
      (item) => item.cluster == 'travel/destinations',
    );

    expect(
      InterestLocalizationPolicy.requiresChinese(destination),
      isFalse,
    );
  });


  test('Part 16 is an eight-locale certified translation batch', () {
    final batch = InterestCatalog.seed
        .where((item) => kInterestCatalogPart16Ids.contains(item.id))
        .toList(growable: false);
    final audit = InterestLocalizationAudit.run(catalog: batch);

    expect(batch, hasLength(119));
    expect(audit.fullLocaleComplete, isTrue);
    for (final locale in InterestLocaleRegistry.supportedLocales) {
      expect(
        audit.missingForLocale(locale),
        isEmpty,
        reason: 'Part 16 is missing $locale translations',
      );
    }
  });

  test('Part 16 localized labels are unique inside each category and locale', () {
    final batch = InterestCatalog.seed
        .where((item) => kInterestCatalogPart16Ids.contains(item.id));
    for (final locale in InterestLocaleRegistry.supportedLocales) {
      final seen = <String, String>{};
      final collisions = <String>[];
      for (final item in batch) {
        final label = InterestCatalog.normalizeText(item.labels[locale] ?? '');
        final key = '${item.category}|$label';
        final previous = seen[key];
        if (previous == null) {
          seen[key] = item.id;
        } else if (previous != item.id) {
          collisions.add('$locale:$label: $previous <> ${item.id}');
        }
      }
      expect(collisions, isEmpty, reason: collisions.join('\n'));
    }
  });


  test('staged bulk localization covers 2502 rows across all eight locales', () {
    final audit = InterestLocalizationAudit.run();

    expect(audit.total, 4054);
    expect(audit.missingForLocale('zh-Hant'), isEmpty);
    expect(audit.missingForLocale('zh-Hans'), isEmpty);
    for (final locale in const ['es', 'fr', 'pt', 'ja', 'ko']) {
      expect(
        audit.missingForLocale(locale),
        hasLength(1552),
        reason: 'unexpected staged debt for $locale',
      );
    }

    final fullyLocalized = InterestCatalog.seed.where(
      (item) => InterestLocaleRegistry.supportedLocales.every(
        (locale) => (item.labels[locale]?.trim() ?? '').isNotEmpty,
      ),
    );
    expect(fullyLocalized, hasLength(2502));
  });

  test('legacy launch interests resolve in the five newly localized languages', () {
    final cases = <(String, String, String)>[
      ('Bádminton', 'es', 'sports.badminton'),
      ('Randonnée', 'fr', 'sports.hiking'),
      ('Viagens pelo Japão', 'pt', 'travel.japan'),
      ('写真', 'ja', 'photography.general'),
      ('헬스·피트니스', 'ko', 'sports.gym'),
    ];
    for (final row in cases) {
      expect(
        InterestCatalog.search(row.$1, row.$2).first.id,
        row.$3,
        reason: 'localized legacy search failed for ${row.$1}',
      );
    }
  });

  test('audit identifies missing scripts independently', () {
    const synthetic = InterestDefinition(
      id: 'sports.synthetic_badminton',
      category: 'sports',
      cluster: 'racket',
      rank: 99999,
      labels: {
        'en': 'Synthetic Badminton',
        'zh-Hant': '測試羽毛球',
      },
    );

    final audit = InterestLocalizationAudit.run(catalog: const [synthetic]);

    expect(audit.missingZhHantIds, isEmpty);
    expect(audit.missingZhHansIds, ['sports.synthetic_badminton']);
    expect(audit.complete, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_catalog.dart';
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

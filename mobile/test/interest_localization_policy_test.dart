import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/interest_localization_policy.dart';

void main() {
  test('generic catalog leaves require explicit Traditional and Simplified Chinese', () {
    final missing = <String>[];

    for (final item in InterestCatalog.seed) {
      if (!InterestLocalizationPolicy.hasRequiredChinese(item)) {
        missing.add('${item.id} | ${item.labels['en'] ?? item.id} | ${item.cluster}');
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'Generic interests missing zh-Hant/zh-Hans:\n${missing.take(120).join('\n')}',
    );
  });

  test('proper-name policy does not weaken exact interest identity', () {
    final minecraft = InterestCatalog.byId('gaming.minecraft');
    final badminton = InterestCatalog.byId('sports.badminton');

    expect(minecraft, isNotNull);
    expect(badminton, isNotNull);
    expect(InterestLocalizationPolicy.requiresChinese(minecraft!), isFalse);
    expect(InterestLocalizationPolicy.requiresChinese(badminton!), isTrue);
  });
}

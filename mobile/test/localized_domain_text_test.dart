import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/localized_domain_text.dart';

void main() {
  test('all current taxonomy navigation keys have Chinese translations', () {
    final missingTraditional = <String>{};
    final missingSimplified = <String>{};

    for (final category in InterestCatalog.categories) {
      for (final l2 in InterestCatalog.clustersForCategory(category)) {
        if (!LocalizedDomainText.hasTaxonomyTranslation(l2, 'zh-Hant')) {
          missingTraditional.add(l2);
        }
        if (!LocalizedDomainText.hasTaxonomyTranslation(l2, 'zh-Hans')) {
          missingSimplified.add(l2);
        }

        for (final l3 in InterestCatalog.subclustersFor(category, l2)) {
          if (!LocalizedDomainText.hasTaxonomyTranslation(l3, 'zh-Hant')) {
            missingTraditional.add(l3);
          }
          if (!LocalizedDomainText.hasTaxonomyTranslation(l3, 'zh-Hans')) {
            missingSimplified.add(l3);
          }
        }
      }
    }

    expect(
      missingTraditional,
      isEmpty,
      reason: 'Missing zh-Hant taxonomy labels: ${missingTraditional.toList()..sort()}',
    );
    expect(
      missingSimplified,
      isEmpty,
      reason: 'Missing zh-Hans taxonomy labels: ${missingSimplified.toList()..sort()}',
    );
  });

  test('sports racket family renders as localized navigation text', () {
    expect(LocalizedDomainText.taxonomy('racket', 'zh-HK'), '球拍運動');
    expect(LocalizedDomainText.taxonomy('racket', 'zh-Hant'), '球拍運動');
    expect(LocalizedDomainText.taxonomy('racket', 'zh-Hans'), '球拍运动');
  });
}

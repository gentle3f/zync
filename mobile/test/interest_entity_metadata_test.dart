import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/activity_templates.dart';
import 'package:zync/core/interest_catalog.dart';
import 'package:zync/core/interest_entity_metadata.dart';
import 'package:zync/core/matching_service.dart';
import 'package:zync/core/models.dart';

void main() {
  test('metadata overlay only references existing official canonical interests', () {
    for (final entry in InterestEntityMetadataRegistry.entries.entries) {
      expect(entry.key, entry.value.interestId);
      expect(entry.key, isNot(startsWith('custom.')));
      expect(
        InterestCatalog.byId(entry.key),
        isNotNull,
        reason: 'metadata points to missing canonical interest ${entry.key}',
      );
    }
  });

  test('Zync Now activity metadata has valid group ranges and templates', () {
    for (final item in InterestEntityMetadataRegistry.zyncNowEligible) {
      final activity = item.activity!;
      expect(activity.minGroupSize, greaterThanOrEqualTo(2));
      expect(activity.maxGroupSize, greaterThanOrEqualTo(activity.minGroupSize));
      expect(activity.templateIds, isNotEmpty);

      for (final templateId in activity.templateIds) {
        expect(
          ActivityTemplates.byId[templateId],
          isNotNull,
          reason: '${item.interestId} references missing activity template $templateId',
        );
      }
    }
  });

  test('collectible metadata has enough visual information for a renderer', () {
    for (final item in InterestEntityMetadataRegistry.collectible) {
      final card = item.card!;
      expect(card.visualFamily.trim(), isNotEmpty);
      expect(card.iconKey.trim(), isNotEmpty);
      expect(card.categoryKit.trim(), isNotEmpty);
      expect(card.artPolicy, isNot(CardArtPolicy.notCollectible));
    }
  });

  test('activity templates have valid participant ranges and localized fallback text', () {
    for (final template in ActivityTemplates.byId.values) {
      expect(template.minGroupSize, greaterThanOrEqualTo(2));
      expect(template.maxGroupSize, greaterThanOrEqualTo(template.minGroupSize));
      expect(template.titleFor('en').trim(), isNotEmpty);
      expect(template.titleFor('zh-HK').trim(), isNotEmpty);
      expect(template.instructionFor('zh-Hans').trim(), isNotEmpty);
    }
  });

  test('metadata does not alter exact-match semantics', () {
    const badminton = [
      SelectedInterest(id: 'sports.badminton', strength: InterestStrength.love),
    ];
    const tennis = [
      SelectedInterest(id: 'sports.tennis', strength: InterestStrength.love),
    ];

    expect(InterestEntityMetadataRegistry.byInterestId('sports.badminton'), isNotNull);
    expect(InterestEntityMetadataRegistry.byInterestId('sports.tennis'), isNotNull);

    final result = MatchingService.compare(badminton, tennis);
    expect(result.shared, isEmpty);
    expect(result.onlyMine.single.id, 'sports.badminton');
    expect(result.onlyTheirs.single.id, 'sports.tennis');
  });
}

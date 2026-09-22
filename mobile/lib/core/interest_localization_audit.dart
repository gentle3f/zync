import 'interest_catalog.dart';
import 'interest_localization_policy.dart';
import 'interest_localization.dart';
import 'models.dart';

class InterestLocalizationAuditResult {
  const InterestLocalizationAuditResult({
    required this.total,
    required this.requiresChinese,
    required this.properNameOrPolicyExempt,
    required this.migrationBacklog,
    required this.missingZhHantIds,
    required this.missingZhHansIds,
    required this.missingByLocale,
  });

  final int total;
  final int requiresChinese;
  final int properNameOrPolicyExempt;
  final int migrationBacklog;
  final List<String> missingZhHantIds;
  final List<String> missingZhHansIds;
  final Map<String, List<String>> missingByLocale;

  List<String> missingForLocale(String locale) =>
      missingByLocale[InterestLocaleRegistry.canonicalLocale(locale)] ?? const [];

  bool get fullLocaleComplete => InterestLocaleRegistry.supportedLocales.every(
        (locale) => missingForLocale(locale).isEmpty,
      );

  Set<String> get missingAnyIds => {
        ...missingZhHantIds,
        ...missingZhHansIds,
      };

  bool get complete =>
      missingZhHantIds.isEmpty && missingZhHansIds.isEmpty;

  Map<String, int> missingByCluster(Iterable<InterestDefinition> catalog) {
    final missing = missingAnyIds;
    final counts = <String, int>{};
    for (final item in catalog) {
      if (!missing.contains(item.id)) continue;
      counts[item.cluster] = (counts[item.cluster] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }
}

class InterestLocalizationAudit {
  const InterestLocalizationAudit._();

  static InterestLocalizationAuditResult run({
    Iterable<InterestDefinition>? catalog,
  }) {
    final items = (catalog ?? InterestCatalog.seed).toList(growable: false);
    final missingHant = <String>[];
    final missingHans = <String>[];
    var required = 0;
    var backlog = 0;
    final missingByLocale = <String, List<String>>{
      for (final locale in InterestLocaleRegistry.supportedLocales) locale: <String>[],
    };

    for (final item in items) {
      for (final locale in InterestLocaleRegistry.supportedLocales) {
        final explicit = item.labels[locale]?.trim() ?? '';
        if (explicit.isEmpty) missingByLocale[locale]!.add(item.id);
      }
      if (InterestLocalizationPolicy.isMigrationBacklog(item)) {
        backlog += 1;
      }
      if (!InterestLocalizationPolicy.requiresChinese(item)) {
        continue;
      }
      required += 1;

      final hant = item.labels['zh-Hant']?.trim() ?? '';
      final hans = item.labels['zh-Hans']?.trim() ?? '';
      if (hant.isEmpty) missingHant.add(item.id);
      if (hans.isEmpty) missingHans.add(item.id);
    }

    missingHant.sort();
    missingHans.sort();
    for (final ids in missingByLocale.values) {
      ids.sort();
    }

    return InterestLocalizationAuditResult(
      total: items.length,
      requiresChinese: required,
      properNameOrPolicyExempt: items.length - required,
      migrationBacklog: backlog,
      missingZhHantIds: List.unmodifiable(missingHant),
      missingZhHansIds: List.unmodifiable(missingHans),
      missingByLocale: Map.unmodifiable({
        for (final entry in missingByLocale.entries)
          entry.key: List<String>.unmodifiable(entry.value),
      }),
    );
  }
}

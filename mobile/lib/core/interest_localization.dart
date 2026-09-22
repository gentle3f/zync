import 'interest_locale_part16.dart';
import 'models.dart';

class InterestLocaleRegistry {
  const InterestLocaleRegistry._();

  static const supportedLocales = <String>{
    'en', 'zh-Hant', 'zh-Hans', 'es', 'fr', 'pt', 'ja', 'ko',
  };

  static final Map<String, Map<String, String>> _labels = _parseLabels();
  static final Map<String, Map<String, List<String>>> _localizedAliases =
      _parseLocalizedAliases();

  static const Map<String, List<String>> _globalAliasAdditions = {
    'technology.programming': ['Coding Club'],
    'photography.general': ['Photography Club'],
    'gaming.chess': ['Chess Club'],
    'gaming.esports': ['Esports Club'],
    'learning.entrepreneurship': ['Entrepreneurship Club'],
    'arts.acting': ['Drama Club'],
    'arts.musical_theatre': ['School Musical'],
    'music.choir': ['School Choir'],
    'sports.gym': ['Strength Training', 'Home Gym'],
    'food.cafe_hopping': ['Coffee Shops'],
    'lifestyle.houseplants': ['Plant Parenting'],
    'food.cooking': ['Home Cooking'],
    'lifestyle.gardening': ['Backyard Gardening'],
    'transport.car_detailing': ['Auto Detailing'],
    'gaming.subgenre.life_sim': ['Life Simulation Games'],
  };

  static String canonicalLocale(String locale) {
    final normalized = locale.replaceAll('_', '-');
    final lower = normalized.toLowerCase();
    if (lower.startsWith('zh')) {
      return lower.contains('hant') ||
              lower.contains('-hk') ||
              lower.contains('-tw') ||
              lower.contains('-mo')
          ? 'zh-Hant'
          : 'zh-Hans';
    }
    final base = normalized.split('-').first.toLowerCase();
    return supportedLocales.contains(base) ? base : 'en';
  }

  static InterestDefinition apply(InterestDefinition item) {
    final overlay = _labels[item.id];
    final aliases = <String>{
      ...item.aliases,
      ...?_globalAliasAdditions[item.id],
    }.where((value) => value.trim().isNotEmpty).toList(growable: false);
    if (overlay == null && aliases.length == item.aliases.length) return item;
    return InterestDefinition(
      id: item.id,
      category: item.category,
      labels: {
        ...item.labels,
        ...?overlay,
      },
      aliases: aliases,
      cluster: item.cluster,
      rank: item.rank,
    );
  }

  static List<String> aliasesFor(String id, String locale) {
    final code = canonicalLocale(locale);
    return _localizedAliases[id]?[code] ?? const <String>[];
  }

  static Iterable<String> allLocalizedAliases(String id) sync* {
    final byLocale = _localizedAliases[id];
    if (byLocale == null) return;
    for (final aliases in byLocale.values) {
      yield* aliases;
    }
  }

  static Map<String, Map<String, String>> _parseLabels() {
    final result = <String, Map<String, String>>{};
    for (final line in kInterestLocalePart16Raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('|');
      if (parts.length != 8) {
        throw StateError('Invalid interest locale row: $trimmed');
      }
      result[parts[0]] = {
        'zh-Hant': parts[1],
        'zh-Hans': parts[2],
        'es': parts[3],
        'fr': parts[4],
        'pt': parts[5],
        'ja': parts[6],
        'ko': parts[7],
      };
    }
    return Map.unmodifiable({
      for (final entry in result.entries)
        entry.key: Map.unmodifiable(entry.value),
    });
  }

  static Map<String, Map<String, List<String>>> _parseLocalizedAliases() {
    final result = <String, Map<String, List<String>>>{};
    for (final line in kInterestLocaleAliasesPart16Raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('|');
      if (parts.length != 3) {
        throw StateError('Invalid localized alias row: $trimmed');
      }
      final locale = canonicalLocale(parts[1]);
      final aliases = parts[2]
          .split(';')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      (result[parts[0]] ??= <String, List<String>>{})[locale] = aliases;
    }
    return Map.unmodifiable({
      for (final entry in result.entries)
        entry.key: Map.unmodifiable(entry.value),
    });
  }
}

import 'models.dart';

/// Existing V1 canonical concepts that predate the deep taxonomy. New curated
/// family rows may mention them for completeness, but must never mint a second
/// canonical ID for the same concept. This list is intentionally explicit: any
/// other same-category duplicate still fails the catalog semantic audit.
const Set<String> _legacyCanonicalConcepts = {
  'gaming|sandbox_games',
  'music|reggae',
  'music|jazz',
  'music|world_music',
  'learning|science_fiction_books',
  'learning|business_books',
};

/// Parses compact, bundled interest rows.
///
/// Format: id|category|cluster|rank|en|zh-Hant|zh-Hans|aliases(; separated)
List<InterestDefinition> parseInterestCatalogRows(String raw) {
  final result = <InterestDefinition>[];
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('|');
    if (parts.length != 8) {
      throw StateError('Invalid bundled interest row: $trimmed');
    }
    final labels = <String, String>{'en': parts[4]};
    if (parts[5].isNotEmpty) labels['zh-Hant'] = parts[5];
    if (parts[6].isNotEmpty) labels['zh-Hans'] = parts[6];
    result.add(
      InterestDefinition(
        id: parts[0],
        category: parts[1],
        cluster: parts[2],
        rank: int.parse(parts[3]),
        labels: labels,
        aliases: parts[7].isEmpty ? const [] : parts[7].split(';'),
      ),
    );
  }
  return List.unmodifiable(result);
}

/// Builds a curated family of interests with one shared taxonomy path.
///
/// [cluster] may contain `/` to express L2/L3 hierarchy, for example
/// `movies/drama` or `gaming/strategy`.
///
/// Compact rows deliberately support two authoring forms:
/// - `English`
/// - `English|aliases`
/// - `English|zh-Hant|zh-Hans`
/// - `English|zh-Hant|native/alternate aliases|zh-Hans`
///
/// The four-column form is useful for Asian titles: the native Japanese/Korean
/// title stays searchable as an alias while Chinese UI gets the correct script.
/// Explicit six-column rows are also accepted as
/// `English|aliases|zh-Hant|zh-Hans|ja|ko` for entries that need localized
/// display labels in all four bundled Asian locales.
///
/// IDs are generated once from the frozen English label plus [idPrefix]. Do not
/// rename an existing row after release; add aliases/translations instead so
/// canonical IDs remain stable.
List<InterestDefinition> parseInterestFamily({
  required String idPrefix,
  required String category,
  required String cluster,
  required int rankStart,
  required String raw,
}) {
  final result = <InterestDefinition>[];
  var offset = 0;
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('|').map((part) => part.trim()).toList();
    if (parts.isEmpty || parts.length > 6) {
      throw StateError('Invalid interest family row: $trimmed');
    }
    final en = parts[0];
    if (en.isEmpty) throw StateError('Interest family label is empty');
    final slug = _catalogSlug(en);
    if (slug.isEmpty) throw StateError('Interest family slug is empty: $en');
    final rank = rankStart + offset;
    offset++;

    if (_legacyCanonicalConcepts.contains('$category|$slug')) {
      continue;
    }

    final labels = <String, String>{'en': en};
    final aliases = <String>{};

    switch (parts.length) {
      case 1:
        break;
      case 2:
        aliases.addAll(_splitAliases(parts[1]));
        break;
      case 3:
        if (parts[1].isNotEmpty) {
          labels['zh-Hant'] = parts[1];
          aliases.add(parts[1]);
        }
        if (parts[2].isNotEmpty) {
          labels['zh-Hans'] = parts[2];
          aliases.add(parts[2]);
        }
        break;
      case 4:
        if (parts[1].isNotEmpty) {
          labels['zh-Hant'] = parts[1];
          aliases.add(parts[1]);
        }
        aliases.addAll(_splitAliases(parts[2]));
        if (parts[3].isNotEmpty) {
          labels['zh-Hans'] = parts[3];
          aliases.add(parts[3]);
        }
        break;
      case 5:
      case 6:
        aliases.addAll(_splitAliases(parts[1]));
        if (parts[2].isNotEmpty) labels['zh-Hant'] = parts[2];
        if (parts[3].isNotEmpty) labels['zh-Hans'] = parts[3];
        if (parts.length > 4 && parts[4].isNotEmpty) labels['ja'] = parts[4];
        if (parts.length > 5 && parts[5].isNotEmpty) labels['ko'] = parts[5];
        break;
    }

    aliases.remove(en);
    aliases.removeWhere((value) => value.isEmpty);
    result.add(
      InterestDefinition(
        id: '$idPrefix.$slug',
        category: category,
        cluster: cluster,
        rank: rank,
        labels: labels,
        aliases: aliases.toList(growable: false),
      ),
    );
  }
  return List.unmodifiable(result);
}

Iterable<String> _splitAliases(String value) =>
    value.split(';').map((item) => item.trim()).where((item) => item.isNotEmpty);

String _catalogSlug(String value) {
  var text = value.toLowerCase().replaceAll('&', ' and ');
  const folds = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
  };
  folds.forEach((from, to) => text = text.replaceAll(from, to));
  return text
      .replaceAll(RegExp(r'''[’'"`´]'''), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

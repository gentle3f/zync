import 'models.dart';

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
/// `movies/drama` or `gaming/strategy`. The compact row format is:
///
///   English label|aliases (; separated)|zh-Hant|zh-Hans
///
/// Only the English label is required. IDs are generated once from the frozen
/// English label plus [idPrefix]. Do not rename an existing row after release;
/// add aliases or display translations instead so canonical IDs stay stable.
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
    final parts = trimmed.split('|');
    if (parts.length > 4) {
      throw StateError('Invalid interest family row: $trimmed');
    }
    final en = parts[0].trim();
    if (en.isEmpty) throw StateError('Interest family label is empty');
    final slug = _catalogSlug(en);
    if (slug.isEmpty) throw StateError('Interest family slug is empty: $en');
    final labels = <String, String>{'en': en};
    if (parts.length > 2 && parts[2].trim().isNotEmpty) labels['zh-Hant'] = parts[2].trim();
    if (parts.length > 3 && parts[3].trim().isNotEmpty) labels['zh-Hans'] = parts[3].trim();
    result.add(
      InterestDefinition(
        id: '$idPrefix.$slug',
        category: category,
        cluster: cluster,
        rank: rankStart + offset,
        labels: labels,
        aliases: parts.length > 1 && parts[1].trim().isNotEmpty
            ? parts[1].split(';').map((value) => value.trim()).where((value) => value.isNotEmpty).toList(growable: false)
            : const [],
      ),
    );
    offset++;
  }
  return List.unmodifiable(result);
}

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

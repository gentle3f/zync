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

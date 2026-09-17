import 'interest_catalog_part1.dart';
import 'interest_catalog_part2.dart';
import 'interest_catalog_part3.dart';
import 'interest_catalog_part4.dart';
import 'interest_catalog_part5.dart';
import 'interest_catalog_part6.dart';
import 'models.dart';

class InterestCatalog {
  const InterestCatalog._();

  static final List<InterestDefinition> seed = List.unmodifiable([
    ...kInterestCatalogPart1,
    ...kInterestCatalogPart2,
    ...kInterestCatalogPart3,
    ...kInterestCatalogPart4,
    ...kInterestCatalogPart5,
    ...kInterestCatalogPart6,
  ]);

  static final Map<String, InterestDefinition> _byId = {
    for (final item in seed) item.id: item,
  };

  static final List<String> categories = _buildCategories();

  static InterestDefinition? byId(String id) => _byId[id];

  static int get count => seed.length;

  static InterestDefinition? exact(String input) {
    final q = normalizeText(input);
    if (q.isEmpty) return null;
    for (final item in seed) {
      if (_exactTerms(item).contains(q)) return item;
    }
    return null;
  }

  static List<InterestDefinition> search(
    String query,
    String locale, {
    String? category,
    int limit = 80,
  }) {
    final q = normalizeText(query);
    final pool = category == null || category.isEmpty
        ? seed
        : seed.where((item) => item.category == category);

    if (q.isEmpty) {
      final items = pool.toList()..sort(_rankCompare);
      return items.take(limit).toList(growable: false);
    }

    final scored = <({InterestDefinition item, int score})>[];
    for (final item in pool) {
      final score = _searchScore(item, q);
      if (score != null) scored.add((item: item, score: score));
    }
    scored.sort((a, b) {
      final score = a.score.compareTo(b.score);
      if (score != 0) return score;
      return _rankCompare(a.item, b.item);
    });
    return scored.map((row) => row.item).take(limit).toList(growable: false);
  }

  static List<InterestDefinition> popular({String? category, int limit = 36}) {
    final items = (category == null || category.isEmpty
            ? seed
            : seed.where((item) => item.category == category))
        .toList()
      ..sort(_rankCompare);
    return items.take(limit).toList(growable: false);
  }

  /// Returns discovery suggestions only. Related interests are never considered
  /// exact matches; matching continues to use canonical IDs exclusively.
  static List<InterestDefinition> relatedTo(
    Iterable<String> selectedIds, {
    int limit = 18,
  }) {
    final selected = selectedIds.toSet();
    if (selected.isEmpty) return popular(limit: limit);
    final selectedDefs = selected.map(byId).whereType<InterestDefinition>().toList();
    if (selectedDefs.isEmpty) return popular(limit: limit);

    final clusters = <String, int>{};
    final categories = <String, int>{};
    for (final item in selectedDefs) {
      if (item.cluster.isNotEmpty) clusters[item.cluster] = (clusters[item.cluster] ?? 0) + 1;
      categories[item.category] = (categories[item.category] ?? 0) + 1;
    }

    final candidates = seed.where((item) => !selected.contains(item.id)).map((item) {
      final clusterHits = item.cluster.isEmpty ? 0 : (clusters[item.cluster] ?? 0);
      final categoryHits = categories[item.category] ?? 0;
      final relationship = clusterHits > 0
          ? 0 - (clusterHits * 20)
          : categoryHits > 0
              ? 100 - (categoryHits * 5)
              : 1000;
      return (item: item, score: relationship + item.rank);
    }).where((row) => row.score < 1000 + 120).toList()
      ..sort((a, b) {
        final score = a.score.compareTo(b.score);
        if (score != 0) return score;
        return _rankCompare(a.item, b.item);
      });

    return candidates.map((row) => row.item).take(limit).toList(growable: false);
  }

  /// Creates an immediately usable local interest without any network/AI gate.
  /// Exact catalog labels/aliases resolve to their canonical ID. Otherwise the
  /// same normalized free text deterministically maps to the same custom ID on
  /// different devices.
  static SelectedInterest instantSelection(String input) {
    final known = exact(input);
    if (known != null) {
      return SelectedInterest(id: known.id, strength: InterestStrength.like);
    }
    final display = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = normalizeText(display);
    if (normalized.length < 2) {
      throw const FormatException('Interest is too short');
    }
    return SelectedInterest(
      id: 'custom.${_stableId(normalized)}',
      strength: InterestStrength.like,
      customLabel: display,
      customCategory: 'other',
    );
  }

  static String normalizeText(String value) {
    var text = value.trim().toLowerCase();
    const folds = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
    };
    folds.forEach((from, to) => text = text.replaceAll(from, to));
    text = text
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'''[’'"`´]'''), '')
        .replaceAll(RegExp(r'[^a-z0-9\u3400-\u9fff\u3040-\u30ff\uac00-\ud7af]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text;
  }

  static int _rankCompare(InterestDefinition a, InterestDefinition b) {
    final rank = a.rank.compareTo(b.rank);
    if (rank != 0) return rank;
    return a.id.compareTo(b.id);
  }

  static Set<String> _exactTerms(InterestDefinition item) {
    return {
      normalizeText(item.id),
      normalizeText(item.id.split('.').last.replaceAll('_', ' ')),
      ...item.labels.values.map(normalizeText),
      ...item.aliases.map(normalizeText),
    }..remove('');
  }

  static int? _searchScore(InterestDefinition item, String q) {
    final terms = <String>{
      ...item.labels.values.map(normalizeText),
      ...item.aliases.map(normalizeText),
      normalizeText(item.id.split('.').last.replaceAll('_', ' ')),
    }..remove('');
    if (terms.contains(q)) return 0;
    if (terms.any((term) => term.startsWith(q))) return 10;
    if (terms.any((term) => term.split(' ').any((token) => token.startsWith(q)))) return 20;
    if (terms.any((term) => term.contains(q))) return 30;
    final id = normalizeText(item.id.replaceAll('.', ' ').replaceAll('_', ' '));
    if (id.contains(q)) return 40;
    final category = normalizeText(item.category);
    if (category.contains(q)) return 50;
    return null;
  }

  static String _stableId(String normalized) {
    int fnv(String value, int seed) {
      var hash = seed & 0xffffffff;
      for (final unit in value.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x01000193) & 0xffffffff;
      }
      return hash;
    }

    final a = fnv(normalized, 0x811c9dc5);
    final b = fnv(normalized.split('').reversed.join(), 0x9e3779b9);
    return '${a.toRadixString(16).padLeft(8, '0')}${b.toRadixString(16).padLeft(8, '0')}';
  }

  static List<String> _buildCategories() {
    const preferred = [
      'sports',
      'wellness',
      'outdoors',
      'gaming',
      'music',
      'entertainment',
      'food',
      'travel',
      'arts',
      'crafts',
      'technology',
      'science',
      'learning',
      'transport',
      'motorsport',
      'collecting',
      'fashion',
      'lifestyle',
      'pets',
      'business',
    ];
    final available = seed.map((item) => item.category).toSet();
    return preferred.where(available.contains).toList(growable: false);
  }
}

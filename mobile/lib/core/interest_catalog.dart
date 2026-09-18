import 'interest_catalog_part1.dart';
import 'interest_catalog_part2.dart';
import 'interest_catalog_part3.dart';
import 'interest_catalog_part4.dart';
import 'interest_catalog_part5.dart';
import 'interest_catalog_part6.dart';
import 'interest_catalog_part7.dart';
import 'interest_catalog_part8.dart';
import 'interest_catalog_part9.dart';
import 'interest_catalog_part10.dart';
import 'interest_popularity_service.dart';
import 'interest_relevance.dart';
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
    ...kInterestCatalogPart7,
    ...kInterestCatalogPart8,
    ...kInterestCatalogPart9,
    ...kInterestCatalogPart10,
  ]);

  static final Map<String, InterestDefinition> _byId = {
    for (final item in seed) item.id: item,
  };

  /// Pre-normalized once per process so typing into search never has to rebuild
  /// thousands of normalized label/alias strings on every keystroke.
  static final List<_InterestSearchRow> _searchIndex = [
    for (final item in seed)
      _InterestSearchRow(
        item: item,
        terms: _searchTerms(item),
        normalizedId: normalizeText(item.id.replaceAll('.', ' ').replaceAll('_', ' ')),
        normalizedCategory: normalizeText(item.category),
      ),
  ];

  /// Earlier bundled IDs win when a label/alias is shared. The semantic audit
  /// prevents same-category duplicate concepts, while cross-category terms can
  /// still intentionally point to the first long-lived canonical definition.
  static final Map<String, InterestDefinition> _exactIndex = _buildExactIndex();

  static final List<String> categories = _buildCategories();

  static InterestDefinition? byId(String id) => _byId[id];

  static int get count => seed.length;

  static InterestDefinition? exact(String input) {
    final q = normalizeText(input);
    if (q.isEmpty) return null;
    return _exactIndex[q];
  }

  static List<InterestDefinition> search(
    String query,
    String locale, {
    String? category,
    String region = 'global',
    InterestPopularitySnapshot? popularity,
    int limit = 80,
  }) {
    final q = normalizeText(query);
    if (q.isEmpty) {
      final items = (category == null || category.isEmpty
              ? seed
              : seed.where((item) => item.category == category))
          .toList()
        ..sort((a, b) => InterestRelevance.compare(
              a,
              b,
              region: region,
              popularity: popularity,
            ));
      return items.take(limit).toList(growable: false);
    }

    final scored = <({InterestDefinition item, int score})>[];
    for (final row in _searchIndex) {
      if (category != null && category.isNotEmpty && row.item.category != category) continue;
      final score = _searchScore(row, q);
      if (score != null) scored.add((item: row.item, score: score));
    }
    scored.sort((a, b) {
      final score = a.score.compareTo(b.score);
      if (score != 0) return score;
      return InterestRelevance.compare(
        a.item,
        b.item,
        region: region,
        popularity: popularity,
      );
    });
    return scored.map((row) => row.item).take(limit).toList(growable: false);
  }

  static List<String> clustersForCategory(String category) {
    final bestRank = <String, int>{};
    for (final item in seed.where((item) => item.category == category)) {
      final path = _taxonomyPath(item);
      if (path.l2.isEmpty) continue;
      final current = bestRank[path.l2];
      if (current == null || item.rank < current) bestRank[path.l2] = item.rank;
    }
    final rows = bestRank.entries.toList()
      ..sort((a, b) {
        final rank = a.value.compareTo(b.value);
        return rank != 0 ? rank : a.key.compareTo(b.key);
      });
    return rows.map((entry) => entry.key).toList(growable: false);
  }

  static List<String> subclustersFor(String category, String cluster) {
    final bestRank = <String, int>{};
    for (final item in seed.where((item) => item.category == category)) {
      final path = _taxonomyPath(item);
      if (path.l2 != cluster || path.l3 == null || path.l3!.isEmpty) continue;
      final current = bestRank[path.l3!];
      if (current == null || item.rank < current) bestRank[path.l3!] = item.rank;
    }
    final rows = bestRank.entries.toList()
      ..sort((a, b) {
        final rank = a.value.compareTo(b.value);
        return rank != 0 ? rank : a.key.compareTo(b.key);
      });
    return rows.map((entry) => entry.key).toList(growable: false);
  }

  static List<InterestDefinition> popular({
    String? category,
    String? cluster,
    String? subcluster,
    String region = 'global',
    InterestPopularitySnapshot? popularity,
    int limit = 36,
  }) {
    Iterable<InterestDefinition> items = seed;
    if (category != null && category.isNotEmpty) {
      items = items.where((item) => item.category == category);
    }
    if (cluster != null && cluster.isNotEmpty) {
      items = items.where((item) {
        final path = _taxonomyPath(item);
        if (path.l2 != cluster) return false;
        if (subcluster == null || subcluster.isEmpty) return true;
        return path.l3 == subcluster;
      });
    }
    final sorted = items.toList()
      ..sort((a, b) => InterestRelevance.compare(
            a,
            b,
            region: region,
            popularity: popularity,
          ));
    return sorted.take(limit).toList(growable: false);
  }

  /// Related interests are discovery-only. Matching still uses exact canonical
  /// IDs, so nearby concepts are never falsely reported as shared interests.
  static List<InterestDefinition> relatedTo(
    Iterable<String> selectedIds, {
    String region = 'global',
    InterestPopularitySnapshot? popularity,
    int limit = 18,
  }) {
    final selected = selectedIds.toSet();
    if (selected.isEmpty) {
      return popular(region: region, popularity: popularity, limit: limit);
    }
    final selectedDefs = selected.map(byId).whereType<InterestDefinition>().toList();
    if (selectedDefs.isEmpty) {
      return popular(region: region, popularity: popularity, limit: limit);
    }

    final fullClusters = <String, int>{};
    final rootClusters = <String, int>{};
    final categories = <String, int>{};
    for (final item in selectedDefs) {
      final path = _taxonomyPath(item);
      final root = '${item.category}/${path.l2}';
      final full = path.l3 == null ? root : '$root/${path.l3}';
      fullClusters[full] = (fullClusters[full] ?? 0) + 1;
      rootClusters[root] = (rootClusters[root] ?? 0) + 1;
      categories[item.category] = (categories[item.category] ?? 0) + 1;
    }

    final candidates = seed.where((item) => !selected.contains(item.id)).map((item) {
      final path = _taxonomyPath(item);
      final root = '${item.category}/${path.l2}';
      final full = path.l3 == null ? root : '$root/${path.l3}';
      final fullHits = fullClusters[full] ?? 0;
      final rootHits = rootClusters[root] ?? 0;
      final categoryHits = categories[item.category] ?? 0;
      final relationship = fullHits > 0
          ? 0 - (fullHits * 30)
          : rootHits > 0
              ? 70 - (rootHits * 15)
              : categoryHits > 0
                  ? 160 - (categoryHits * 5)
                  : 1000;
      return (item: item, relationship: relationship);
    }).where((row) => row.relationship < 1000).toList()
      ..sort((a, b) {
        final relationship = a.relationship.compareTo(b.relationship);
        if (relationship != 0) return relationship;
        return InterestRelevance.compare(
          a.item,
          b.item,
          region: region,
          popularity: popularity,
        );
      });

    return candidates.map((row) => row.item).take(limit).toList(growable: false);
  }

  static SelectedInterest instantSelection(String input) {
    final known = exact(input);
    if (known != null) {
      return SelectedInterest(id: known.id, strength: InterestStrength.like);
    }
    final display = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = normalizeText(display);
    if (normalized.length < 2) throw const FormatException('Interest is too short');
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
    return rank != 0 ? rank : a.id.compareTo(b.id);
  }

  static Set<String> _searchTerms(InterestDefinition item) {
    return {
      ...item.labels.values.map(normalizeText),
      ...item.aliases.map(normalizeText),
      normalizeText(item.id.split('.').last.replaceAll('_', ' ')),
    }..remove('');
  }

  static Set<String> _exactTerms(InterestDefinition item) {
    return {
      normalizeText(item.id),
      ..._searchTerms(item),
    }..remove('');
  }

  static Map<String, InterestDefinition> _buildExactIndex() {
    final result = <String, InterestDefinition>{};
    for (final item in seed) {
      for (final term in _exactTerms(item)) {
        result.putIfAbsent(term, () => item);
      }
    }
    return Map.unmodifiable(result);
  }

  static int? _searchScore(_InterestSearchRow row, String q) {
    if (row.terms.contains(q)) return 0;
    if (row.terms.any((term) => term.startsWith(q))) return 10;
    if (row.terms.any((term) => term.split(' ').any((token) => token.startsWith(q)))) return 20;
    if (row.terms.any((term) => term.contains(q))) return 30;
    if (row.normalizedId.contains(q)) return 40;
    if (row.normalizedCategory.contains(q)) return 50;
    return null;
  }

  static ({String l2, String? l3}) _taxonomyPath(InterestDefinition item) {
    final raw = item.cluster.trim();
    final segments = raw.isEmpty ? <String>[] : raw.split('/');
    final root = segments.isEmpty ? 'general' : segments.first;
    final leaf = segments.length > 1 ? segments[1] : null;

    switch (item.category) {
      case 'entertainment':
        if (root == 'movies') return (l2: 'movies', l3: leaf);
        if (root == 'tv') return (l2: 'tv_drama', l3: leaf);
        if (root == 'anime') return (l2: 'anime_manga', l3: leaf);
        if (root == 'screen') {
          if (item.id == 'media.tv') return (l2: 'tv_drama', l3: 'general');
          if (item.id == 'entertainment.film_making' || item.id == 'entertainment.screenwriting') {
            return (l2: 'movies', l3: 'making');
          }
          return (l2: 'movies', l3: 'general');
        }
        if (root == 'anime_manga') {
          const franchiseIds = {
            'anime.jojo', 'entertainment.ghibli', 'entertainment.one_piece',
            'entertainment.naruto', 'entertainment.dragon_ball',
            'entertainment.demon_slayer', 'entertainment.attack_on_titan',
            'entertainment.jujutsu_kaisen', 'entertainment.spy_x_family',
            'entertainment.pokemon_anime', 'entertainment.gundam',
          };
          return (l2: 'anime_manga', l3: franchiseIds.contains(item.id) ? 'titles_franchises' : 'general');
        }
        if (root == 'pop_culture') {
          if (const {'entertainment.k_drama', 'entertainment.c_drama', 'entertainment.j_drama'}.contains(item.id)) {
            return (l2: 'tv_drama', l3: 'drama');
          }
          if (const {'entertainment.reality_tv', 'entertainment.variety_shows'}.contains(item.id)) {
            return (l2: 'tv_drama', l3: 'comedy_variety');
          }
          return (l2: 'franchises', l3: null);
        }
        break;
      case 'music':
        if (root == 'music_genres') return (l2: 'genres_styles', l3: null);
        if (root == 'music_making') return (l2: 'making', l3: null);
        if (root == 'music') {
          if (leaf == 'styles') return (l2: 'genres_styles', l3: null);
          if (leaf != null &&
              (leaf.endsWith('artists') ||
                  leaf == 'artists_global' ||
                  leaf == 'hk_cantopop' ||
                  leaf == 'mandopop_artists')) {
            return (l2: 'artists', l3: leaf);
          }
        }
        break;
      case 'gaming':
        if (root == 'gaming') return (l2: 'video_games', l3: leaf);
        if (root == 'gaming_general') return (l2: 'video_games', l3: 'general');
        if (root == 'game_genres') return (l2: 'video_games', l3: 'subgenres');
        if (root == 'game_titles') return (l2: 'video_games', l3: 'franchises');
        if (root == 'tabletop') return (l2: 'tabletop', l3: leaf ?? 'general');
        break;
      case 'learning':
        if (root == 'books') return (l2: 'books', l3: leaf ?? 'general');
        break;
      case 'food':
        if (root == 'food') return (l2: leaf ?? 'general', l3: null);
        if (root == 'cuisines') return (l2: 'cuisines', l3: null);
        if (root == 'food_types') return (l2: 'dishes', l3: null);
        if (root == 'coffee') return (l2: 'drinks', l3: null);
        if (root == 'cooking') return (l2: 'cooking', l3: null);
        break;
      case 'travel':
        if (root == 'travel') return (l2: leaf ?? 'general', l3: null);
        if (root == 'travel_destinations') return (l2: 'destinations', l3: null);
        if (root == 'travel_styles') return (l2: 'styles', l3: null);
        if (root == 'travel_general') return (l2: 'general', l3: null);
        break;
    }
    return (l2: root, l3: leaf);
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
      'sports', 'wellness', 'outdoors', 'gaming', 'music', 'entertainment',
      'food', 'travel', 'arts', 'crafts', 'technology', 'science', 'learning',
      'transport', 'motorsport', 'collecting', 'fashion', 'lifestyle', 'pets',
      'business',
    ];
    final available = seed.map((item) => item.category).toSet();
    return preferred.where(available.contains).toList(growable: false);
  }
}

class _InterestSearchRow {
  const _InterestSearchRow({
    required this.item,
    required this.terms,
    required this.normalizedId,
    required this.normalizedCategory,
  });

  final InterestDefinition item;
  final Set<String> terms;
  final String normalizedId;
  final String normalizedCategory;
}

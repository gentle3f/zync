import 'dart:convert';

import 'package:http/http.dart' as http;

final RegExp _canonicalInterestId = RegExp(r'^[a-z0-9][a-z0-9._-]{1,95}$');

class InterestSignalCount {
  const InterestSignalCount({
    required this.impressions,
    required this.selections,
  });

  final int impressions;
  final int selections;

  factory InterestSignalCount.fromJson(Object? raw) {
    if (raw is! Map) {
      return const InterestSignalCount(impressions: 0, selections: 0);
    }
    final map = Map<String, dynamic>.from(raw);
    return InterestSignalCount(
      impressions: ((map['impressions'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
      selections: ((map['selections'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
    );
  }
}

class InterestPopularitySnapshot {
  const InterestPopularitySnapshot({
    required this.region,
    required this.previousWeek,
    required this.olderWeek,
    required this.previous,
    required this.older,
  });

  final String region;
  final String previousWeek;
  final String olderWeek;
  final Map<String, InterestSignalCount> previous;
  final Map<String, InterestSignalCount> older;

  static InterestPopularitySnapshot empty(String region) => InterestPopularitySnapshot(
        region: region,
        previousWeek: '',
        olderWeek: '',
        previous: const {},
        older: const {},
      );

  factory InterestPopularitySnapshot.fromJson(
    Map<String, dynamic> json, {
    required String fallbackRegion,
  }) {
    Map<String, InterestSignalCount> parseMap(Object? raw) {
      if (raw is! Map) return const {};
      final output = <String, InterestSignalCount>{};
      for (final entry in raw.entries) {
        final id = entry.key.toString();
        if (!_canonicalInterestId.hasMatch(id) || id.startsWith('custom.')) continue;
        output[id] = InterestSignalCount.fromJson(entry.value);
      }
      return Map.unmodifiable(output);
    }

    return InterestPopularitySnapshot(
      region: (json['region'] as String?)?.trim().toLowerCase() ?? fallbackRegion,
      previousWeek: (json['previousWeek'] as String?) ?? '',
      olderWeek: (json['olderWeek'] as String?) ?? '',
      previous: parseMap(json['previous']),
      older: parseMap(json['older']),
    );
  }
}

class InterestPopularityService {
  InterestPopularityService({
    this.baseUrl = const String.fromEnvironment('ZYNC_API_BASE'),
    this.enabled = const bool.fromEnvironment(
      'ZYNC_INTEREST_LEARNING_ENABLED',
      defaultValue: false,
    ),
    http.Client? client,
  }) : _client = client ?? http.Client();

  static final instance = InterestPopularityService();

  final String baseUrl;
  final bool enabled;
  final http.Client _client;
  final Set<String> _impressions = <String>{};
  final Set<String> _selections = <String>{};

  void noteImpression(String id) {
    if (!enabled || !_isCanonical(id)) return;
    _impressions.add(id);
  }

  void noteSelection(String id) {
    if (!enabled || !_isCanonical(id)) return;
    _impressions.add(id);
    _selections.add(id);
  }

  Future<InterestPopularitySnapshot> fetchSnapshot(String region) async {
    final canonicalRegion = _sanitizeRegion(region);
    final root = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (!enabled || root.isEmpty) {
      return InterestPopularitySnapshot.empty(canonicalRegion);
    }

    try {
      final response = await _client
          .get(Uri.parse('$root/api/v1/interest-popularity?region=$canonicalRegion'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        return InterestPopularitySnapshot.empty(canonicalRegion);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return InterestPopularitySnapshot.empty(canonicalRegion);
      return InterestPopularitySnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
        fallbackRegion: canonicalRegion,
      );
    } catch (_) {
      return InterestPopularitySnapshot.empty(canonicalRegion);
    }
  }

  Future<void> flush(String region) async {
    final canonicalRegion = _sanitizeRegion(region);
    final root = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (!enabled || root.isEmpty || _impressions.isEmpty) return;

    final impressions = _impressions.toList(growable: false);
    final selections = _selections.where(_impressions.contains).toList(growable: false);
    _impressions.clear();
    _selections.clear();

    try {
      await _client
          .post(
            Uri.parse('$root/api/v1/interest-popularity'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'version': 1,
              'region': canonicalRegion,
              'impressions': impressions,
              'selections': selections,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Aggregate learning is best-effort and must never block local onboarding.
    }
  }

  bool _isCanonical(String id) =>
      _canonicalInterestId.hasMatch(id) && !id.startsWith('custom.');

  String _sanitizeRegion(String raw) {
    final value = raw.trim().toLowerCase();
    return RegExp(r'^[a-z]{2,8}$').hasMatch(value) ? value : 'global';
  }
}

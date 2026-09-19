import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AnalyticsEvent {
  const AnalyticsEvent._();

  static const appOpen = 'app_open';
  static const interestSetupComplete = 'interest_setup_complete';
  static const interestAdded = 'interest_added';
  static const qrGenerated = 'qr_generated';
  static const qrScanned = 'qr_scanned';
  static const matchComplete = 'match_complete';
  static const matchCount = 'match_count';
  static const questionGenerated = 'question_generated';
  static const questionNext = 'question_next';
  static const modeSelected = 'mode_selected';
  static const zyncAgain = 'zync_again';
  static const connectionRevealed = 'connection_revealed';
  static const sessionContinue = 'session_continue';
  static const sessionRecap = 'session_recap';

  static const values = <String>{
    appOpen,
    interestSetupComplete,
    interestAdded,
    qrGenerated,
    qrScanned,
    matchComplete,
    matchCount,
    questionGenerated,
    questionNext,
    modeSelected,
    zyncAgain,
    connectionRevealed,
    sessionContinue,
    sessionRecap,
  };
}

class ZyncAnalytics {
  ZyncAnalytics({
    this.baseUrl = const String.fromEnvironment('ZYNC_API_BASE'),
    this.enabled = const bool.fromEnvironment(
      'ZYNC_ANALYTICS_ENABLED',
      defaultValue: false,
    ),
    http.Client? client,
  }) : _client = client ?? http.Client();

  static final instance = ZyncAnalytics();
  static const _uuid = Uuid();
  static const _installIdKey = 'zync.analytics.install_id.v1';
  static const _allowedPropertyKeys = <String>{
    'locale',
    'profile_ready',
    'source',
    'selected_count',
    'interest_count',
    'transport',
    'has_match',
    'repeat_peer',
    'count',
    'mode',
    'match_type',
    'bilingual',
    'prior_sessions',
    'revealed_count',
    'total_count',
    'remaining_count',
    'interaction_type',
    'continue_source',
  };

  final String baseUrl;
  final bool enabled;
  final http.Client _client;
  String? _sessionId;

  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    // V1 ships analytics OFF by default. This check happens before any
    // installation/session identifier is created or any network request is made.
    if (!enabled) return;

    final root = baseUrl.trim();
    if (root.isEmpty || !AnalyticsEvent.values.contains(event)) return;

    try {
      final installId = await _loadOrCreateInstallId();
      final sessionId = _sessionId ??= _uuid.v4();
      await _client
          .post(
            Uri.parse('${root.replaceAll(RegExp(r'/$'), '')}/api/v1/analytics'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'event': event,
              'installId': installId,
              'sessionId': sessionId,
              'properties': sanitizeProperties(properties),
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Analytics is best-effort and must never block the core local-first flow.
    }
  }

  static Map<String, Object> sanitizeProperties(Map<String, Object?> input) {
    final output = <String, Object>{};
    for (final entry in input.entries) {
      if (!_allowedPropertyKeys.contains(entry.key)) continue;
      final value = entry.value;
      if (value is bool) {
        output[entry.key] = value;
      } else if (value is num && value.isFinite) {
        output[entry.key] = value;
      } else if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          output[entry.key] = trimmed.length <= 40 ? trimmed : trimmed.substring(0, 40);
        }
      }
    }
    return output;
  }

  Future<String> _loadOrCreateInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _uuid.v4();
    await prefs.setString(_installIdKey, created);
    return created;
  }
}

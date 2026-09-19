import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/analytics_service.dart';

void main() {
  test('analytics is disabled by default unless explicitly enabled at build time', () {
    final analytics = ZyncAnalytics(baseUrl: 'https://example.test');
    expect(analytics.enabled, isFalse);
  });

  test('analytics client strips raw content and unknown properties', () {
    final clean = ZyncAnalytics.sanitizeProperties({
      'mode': 'fun',
      'count': 3,
      'bilingual': true,
      'interaction_type': 'guess',
      'continue_source': 'reveal_next',
      'revealed_count': 2,
      'remaining_count': 3,
      'interest_name': 'Anime',
      'canonical_interest_id': 'anime.jojo',
      'peer_id': 'peer-secret',
      'nickname': 'Gentle',
      'qr_payload': '{raw}',
    });

    expect(clean['mode'], 'fun');
    expect(clean['count'], 3);
    expect(clean['bilingual'], true);
    expect(clean['interaction_type'], 'guess');
    expect(clean['continue_source'], 'reveal_next');
    expect(clean['revealed_count'], 2);
    expect(clean['remaining_count'], 3);
    expect(clean.containsKey('interest_name'), isFalse);
    expect(clean.containsKey('canonical_interest_id'), isFalse);
    expect(clean.containsKey('peer_id'), isFalse);
    expect(clean.containsKey('nickname'), isFalse);
    expect(clean.containsKey('qr_payload'), isFalse);
  });

  test('analytics event set includes privacy-safe meaningful Zync progression', () {
    expect(
      AnalyticsEvent.values,
      {
        'app_open',
        'interest_setup_complete',
        'interest_added',
        'qr_generated',
        'qr_scanned',
        'match_complete',
        'match_count',
        'question_generated',
        'question_next',
        'mode_selected',
        'zync_again',
        'connection_revealed',
        'session_continue',
        'session_recap',
      },
    );
  });
}

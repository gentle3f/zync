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
      'interest_name': 'Anime',
      'canonical_interest_id': 'anime.jojo',
      'peer_id': 'peer-secret',
      'nickname': 'Gentle',
      'qr_payload': '{raw}',
    });

    expect(clean['mode'], 'fun');
    expect(clean['count'], 3);
    expect(clean['bilingual'], true);
    expect(clean.containsKey('interest_name'), isFalse);
    expect(clean.containsKey('canonical_interest_id'), isFalse);
    expect(clean.containsKey('peer_id'), isFalse);
    expect(clean.containsKey('nickname'), isFalse);
    expect(clean.containsKey('qr_payload'), isFalse);
  });

  test('analytics event set matches the frozen V1 product spec', () {
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
      },
    );
  });
}

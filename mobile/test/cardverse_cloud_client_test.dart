import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zync/core/cardverse_cloud_client.dart';

void main() {
  test('cloud client never sends accountId when redeeming a proof', () async {
    late http.Request seen;
    final client = CardverseCloudClient(
      baseUrl: 'https://zync.example',
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode({
            'proofId': 'proof-1',
            'clientEventId': 'event-1',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await client.redeemProof(
      sessionToken: 'A' * 43,
      ticket: 'ZP1.payload.signature',
      clientEventId: 'event-1',
      timezoneOffsetMinutes: 480,
    );

    expect(seen.url.path, '/api/v1/cardverse/proofs/redeem');
    expect(seen.headers['authorization'], 'Bearer NaN');
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(body.containsKey('accountId'), isFalse);
    expect(body['timezoneOffsetMinutes'], 480);
  });

  test('cloud client maps 401 to unauthorized without leaking token', () async {
    final client = CardverseCloudClient(
      baseUrl: 'https://zync.example',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'cardverse_session_invalid'}),
          401,
        ),
      ),
    );

    await expectLater(
      client.fetchInventory('B' * 43),
      throwsA(
        isA<CardverseCloudException>()
            .having(
              (error) => error.failure,
              'failure',
              CardverseCloudFailure.unauthorized,
            )
            .having(
              (error) => error.serverCode,
              'serverCode',
              'cardverse_session_invalid',
            ),
      ),
    );
  });

  test('non-HTTPS API base fails closed', () async {
    final client = CardverseCloudClient(
      baseUrl: 'http://zync.example',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    await expectLater(
      client.fetchInventory('C' * 43),
      throwsA(
        isA<CardverseCloudException>().having(
          (error) => error.failure,
          'failure',
          CardverseCloudFailure.unavailable,
        ),
      ),
    );
  });
}

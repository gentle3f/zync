import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zync/core/cardverse_cloud_client.dart';

void main() {
  test('cloud client never sends accountId when redeeming a proof', () async {
    late http.Request seen;
    final sessionToken = 'A' * 43;
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
      sessionToken: sessionToken,
      ticket: 'ZP1.payload.signature',
      clientEventId: 'event-1',
      timezoneOffsetMinutes: 480,
    );

    expect(seen.url.path, '/api/v1/cardverse/proofs/redeem');
    expect(seen.headers['authorization'], 'Bearer $sessionToken');
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

  test('provider link sends session bearer and provider proof only', () async {
    late http.Request seen;
    final sessionToken = 'L' * 43;
    final client = CardverseCloudClient(
      baseUrl: 'https://zync.example',
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode({
            'provider': 'apple',
            'linked': true,
            'restored': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await client.linkProviderIdentity(
      sessionToken: sessionToken,
      provider: 'apple',
      challengeId: 'challenge-link-1',
      idToken: 'header.payload.signature',
    );

    expect(seen.url.path, '/api/v1/cardverse/auth/link');
    expect(seen.headers['authorization'], 'Bearer $sessionToken');
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(body, {
      'provider': 'apple',
      'challengeId': 'challenge-link-1',
      'idToken': 'header.payload.signature',
    });
    expect(body.containsKey('accountId'), isFalse);
    expect(result.provider, 'apple');
    expect(result.linked, isTrue);
    expect(result.restored, isFalse);
  });

  test('provider link preserves 409 ownership conflict code', () async {
    final client = CardverseCloudClient(
      baseUrl: 'https://zync.example',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'cardverse_identity_already_linked'}),
          409,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    await expectLater(
      client.linkProviderIdentity(
        sessionToken: 'M' * 43,
        provider: 'google',
        challengeId: 'challenge-link-2',
        idToken: 'header.payload.signature',
      ),
      throwsA(
        isA<CardverseCloudException>()
            .having(
              (error) => error.failure,
              'failure',
              CardverseCloudFailure.conflict,
            )
            .having(
              (error) => error.serverCode,
              'serverCode',
              'cardverse_identity_already_linked',
            ),
      ),
    );
  });

  test('account delete sends destructive confirmation and Apple code only when provided', () async {
    final requests = <http.Request>[];
    final client = CardverseCloudClient(
      baseUrl: 'https://zync.example',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('', 204);
      }),
    );

    await client.deleteAccount(
      sessionToken: 'D' * 43,
      provider: 'google',
      challengeId: 'challenge-delete-google',
      idToken: 'google.header.signature',
    );
    await client.deleteAccount(
      sessionToken: 'D' * 43,
      provider: 'apple',
      challengeId: 'challenge-delete-apple',
      idToken: 'apple.header.signature',
      authorizationCode: 'fresh-apple-code',
    );

    expect(requests, hasLength(2));
    for (final request in requests) {
      expect(request.url.path, '/api/v1/cardverse/account/delete');
      expect(request.headers['authorization'], 'Bearer ${'D' * 43}');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['confirmation'], 'DELETE_ACCOUNT_V2');
      expect(body.containsKey('accountId'), isFalse);
    }

    final google = jsonDecode(requests[0].body) as Map<String, dynamic>;
    expect(google, {
      'confirmation': 'DELETE_ACCOUNT_V2',
      'provider': 'google',
      'challengeId': 'challenge-delete-google',
      'idToken': 'google.header.signature',
    });

    final apple = jsonDecode(requests[1].body) as Map<String, dynamic>;
    expect(apple, {
      'confirmation': 'DELETE_ACCOUNT_V2',
      'provider': 'apple',
      'challengeId': 'challenge-delete-apple',
      'idToken': 'apple.header.signature',
      'authorizationCode': 'fresh-apple-code',
    });
  });

  test('account delete preserves Apple reauth server code', () async {
    final client = CardverseCloudClient(
      baseUrl: 'https://zync.example',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'cardverse_apple_reauth_required'}),
          409,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    await expectLater(
      client.deleteAccount(
        sessionToken: 'E' * 43,
        provider: 'google',
        challengeId: 'challenge-delete',
        idToken: 'google.header.signature',
      ),
      throwsA(
        isA<CardverseCloudException>()
            .having(
              (error) => error.failure,
              'failure',
              CardverseCloudFailure.conflict,
            )
            .having(
              (error) => error.serverCode,
              'serverCode',
              'cardverse_apple_reauth_required',
            ),
      ),
    );
  });

}

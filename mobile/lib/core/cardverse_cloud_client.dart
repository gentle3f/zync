import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cardverse_session_store.dart';

enum CardverseCloudFailure {
  unavailable,
  unauthorized,
  rejected,
  conflict,
  disabled,
  invalidResponse,
}

class CardverseCloudException implements Exception {
  const CardverseCloudException({
    required this.failure,
    this.statusCode,
    this.serverCode = '',
  });

  final CardverseCloudFailure failure;
  final int? statusCode;
  final String serverCode;
}

class CardverseAuthChallenge {
  const CardverseAuthChallenge({
    required this.challengeId,
    required this.provider,
    required this.nonce,
    required this.expiresAt,
  });

  final String challengeId;
  final String provider;
  final String nonce;
  final DateTime expiresAt;
}

class CardverseAuthResult {
  const CardverseAuthResult({
    required this.accountId,
    required this.accountCreated,
    required this.provider,
    required this.session,
  });

  final String accountId;
  final bool accountCreated;
  final String provider;
  final CardverseSessionCredential session;
}

class CardverseCloudClient {
  CardverseCloudClient({
    this.baseUrl = const String.fromEnvironment('ZYNC_API_BASE'),
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Uri _uri(String path) {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    final uri = Uri.tryParse('$trimmed$path');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const CardverseCloudException(
        failure: CardverseCloudFailure.unavailable,
      );
    }
    return uri;
  }

  Future<Map<String, dynamic>> _send({
    required String method,
    required String path,
    String? bearerToken,
    Map<String, dynamic>? body,
    Set<int> successStatuses = const {200},
  }) async {
    try {
      final headers = <String, String>{
        'accept': 'application/json',
        if (body != null) 'content-type': 'application/json',
        if (bearerToken != null) 'authorization': 'Bearer $bearerToken',
      };
      final request = http.Request(method, _uri(path))
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);

      final streamed = await _http.send(request).timeout(
            const Duration(seconds: 10),
          );
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : _decodeObject(response.body);

      if (!successStatuses.contains(response.statusCode)) {
        final serverCode = (decoded['error'] as String?)?.trim() ?? '';
        throw CardverseCloudException(
          failure: _failureFor(response.statusCode),
          statusCode: response.statusCode,
          serverCode: serverCode,
        );
      }
      return decoded;
    } on CardverseCloudException {
      rethrow;
    } catch (_) {
      throw const CardverseCloudException(
        failure: CardverseCloudFailure.unavailable,
      );
    }
  }

  Map<String, dynamic> _decodeObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Mapped below.
    }
    throw const CardverseCloudException(
      failure: CardverseCloudFailure.invalidResponse,
    );
  }

  CardverseCloudFailure _failureFor(int status) {
    if (status == 401) return CardverseCloudFailure.unauthorized;
    if (status == 404) return CardverseCloudFailure.disabled;
    if (status == 409) return CardverseCloudFailure.conflict;
    if (status >= 400 && status < 500) {
      return CardverseCloudFailure.rejected;
    }
    return CardverseCloudFailure.unavailable;
  }

  Future<CardverseAuthChallenge> createAuthChallenge(String provider) async {
    final body = await _send(
      method: 'POST',
      path: '/api/v1/cardverse/auth/challenge',
      body: {'provider': provider},
    );
    final challengeId = (body['challengeId'] as String?)?.trim() ?? '';
    final returnedProvider = (body['provider'] as String?)?.trim() ?? '';
    final nonce = (body['nonce'] as String?)?.trim() ?? '';
    final expiresAt = DateTime.tryParse(
      (body['expiresAt'] as String?) ?? '',
    )?.toUtc();
    if (challengeId.isEmpty ||
        returnedProvider.isEmpty ||
        nonce.isEmpty ||
        expiresAt == null) {
      throw const CardverseCloudException(
        failure: CardverseCloudFailure.invalidResponse,
      );
    }
    return CardverseAuthChallenge(
      challengeId: challengeId,
      provider: returnedProvider,
      nonce: nonce,
      expiresAt: expiresAt,
    );
  }

  Future<CardverseAuthResult> authenticateProvider({
    required String provider,
    required String challengeId,
    required String idToken,
  }) async {
    final body = await _send(
      method: 'POST',
      path: '/api/v1/cardverse/auth/provider',
      body: {
        'provider': provider,
        'challengeId': challengeId,
        'idToken': idToken,
      },
    );
    final account = body['account'];
    final accountId = account is Map
        ? (account['id'] as String?)?.trim() ?? ''
        : '';
    final sessionToken = (body['sessionToken'] as String?)?.trim() ?? '';
    final sessionExpiresAt = DateTime.tryParse(
      (body['sessionExpiresAt'] as String?) ?? '',
    )?.toUtc();
    final returnedProvider = (body['provider'] as String?)?.trim() ?? '';
    if (accountId.isEmpty ||
        !RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(sessionToken) ||
        sessionExpiresAt == null ||
        returnedProvider.isEmpty) {
      throw const CardverseCloudException(
        failure: CardverseCloudFailure.invalidResponse,
      );
    }
    return CardverseAuthResult(
      accountId: accountId,
      accountCreated: body['accountCreated'] == true,
      provider: returnedProvider,
      session: CardverseSessionCredential(
        token: sessionToken,
        expiresAt: sessionExpiresAt,
      ),
    );
  }

  Future<Map<String, dynamic>> fetchInventory(String sessionToken) =>
      _send(
        method: 'GET',
        path: '/api/v1/cardverse/inventory',
        bearerToken: sessionToken,
      );

  Future<Map<String, dynamic>> redeemProof({
    required String sessionToken,
    required String ticket,
    required String clientEventId,
    required int timezoneOffsetMinutes,
  }) =>
      _send(
        method: 'POST',
        path: '/api/v1/cardverse/proofs/redeem',
        bearerToken: sessionToken,
        body: {
          'ticket': ticket,
          'clientEventId': clientEventId,
          'timezoneOffsetMinutes': timezoneOffsetMinutes,
        },
      );

  Future<void> logout(String sessionToken) async {
    await _send(
      method: 'POST',
      path: '/api/v1/cardverse/auth/logout',
      bearerToken: sessionToken,
      successStatuses: const {204},
    );
  }

  void close() => _http.close();
}

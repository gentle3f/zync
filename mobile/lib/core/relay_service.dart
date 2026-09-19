import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

const zyncRelayProtocolVersion = 2;
const zyncRelaySessionLifetime = Duration(minutes: 3);
const _maxClockWindow = Duration(minutes: 5);
const _maxDecodedBytes = 64 * 1024;
const _handshakePrefix = 'ZH2:';
final _sessionIdPattern = RegExp(r'^[A-Za-z0-9_-]{22,64}$');

String _base64UrlNoPad(List<int> bytes) => base64UrlEncode(bytes).replaceAll('=', '');

List<int> _base64UrlDecodeNoPad(String value) {
  final padding = (4 - value.length % 4) % 4;
  return base64Url.decode('$value${'=' * padding}');
}

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256), growable: false);
}

class RelayBootstrap {
  const RelayBootstrap({
    required this.sessionId,
    required this.hostToken,
    required this.secretBytes,
    required this.expiresAt,
    required this.hostProfile,
  });

  final String sessionId;
  final String hostToken;
  final List<int> secretBytes;
  final DateTime expiresAt;
  final QrProfilePayload hostProfile;

  factory RelayBootstrap.generate(LocalProfile profile, {DateTime? now}) {
    final current = (now ?? DateTime.now()).toUtc();
    return RelayBootstrap(
      sessionId: _base64UrlNoPad(_randomBytes(18)),
      hostToken: _base64UrlNoPad(_randomBytes(24)),
      secretBytes: _randomBytes(32),
      expiresAt: current.add(zyncRelaySessionLifetime),
      hostProfile: QrProfilePayload.fromProfile(profile),
    );
  }

  ZyncHandshakeQrPayload get qr => ZyncHandshakeQrPayload(
        protocolVersion: zyncRelayProtocolVersion,
        sessionId: sessionId,
        secretBytes: secretBytes,
        expiresAt: expiresAt,
        hostProfile: hostProfile,
      );
}

class ZyncHandshakeQrPayload {
  const ZyncHandshakeQrPayload({
    required this.protocolVersion,
    required this.sessionId,
    required this.secretBytes,
    required this.expiresAt,
    required this.hostProfile,
  });

  final int protocolVersion;
  final String sessionId;
  final List<int> secretBytes;
  final DateTime expiresAt;
  final QrProfilePayload hostProfile;

  String encode() {
    final body = jsonEncode({
      'v': protocolVersion,
      'sid': sessionId,
      'exp': expiresAt.toUtc().millisecondsSinceEpoch,
      'k': _base64UrlNoPad(secretBytes),
      'p': hostProfile.toCompactJson(),
    });
    final compressed = zlib.encode(utf8.encode(body));
    return '$_handshakePrefix${_base64UrlNoPad(compressed)}';
  }

  factory ZyncHandshakeQrPayload.decode(String raw, {DateTime? now}) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(_handshakePrefix)) {
      throw const FormatException('Not a Zync handshake QR');
    }
    try {
      final compressed = _base64UrlDecodeNoPad(trimmed.substring(_handshakePrefix.length));
      final decoded = zlib.decode(compressed);
      if (decoded.length > _maxDecodedBytes) throw const FormatException('Handshake QR is too large');
      final json = Map<String, dynamic>.from(jsonDecode(utf8.decode(decoded)) as Map);
      final version = (json['v'] as num?)?.toInt() ?? 0;
      if (version != zyncRelayProtocolVersion) throw const FormatException('Unsupported handshake version');
      final sessionId = (json['sid'] as String?)?.trim() ?? '';
      if (!_sessionIdPattern.hasMatch(sessionId)) throw const FormatException('Invalid handshake session');
      final secret = _base64UrlDecodeNoPad((json['k'] as String?) ?? '');
      if (secret.length != 32) throw const FormatException('Invalid handshake secret');
      final expiresMs = (json['exp'] as num?)?.toInt();
      if (expiresMs == null) throw const FormatException('Invalid handshake expiry');
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true);
      final current = (now ?? DateTime.now()).toUtc();
      final remaining = expiresAt.difference(current);
      if (remaining <= Duration.zero || remaining > _maxClockWindow) {
        throw const FormatException('Expired handshake');
      }
      final profileMap = Map<String, dynamic>.from(json['p'] as Map);
      final host = QrProfilePayload.decode(jsonEncode(profileMap));
      return ZyncHandshakeQrPayload(
        protocolVersion: version,
        sessionId: sessionId,
        secretBytes: secret,
        expiresAt: expiresAt,
        hostProfile: host,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid Zync handshake QR');
    }
  }
}

class RelayCrypto {
  const RelayCrypto._();

  static final _algorithm = AesGcm.with256bits();

  static List<int> _aad(String sessionId) => utf8.encode('zync-relay-v2:$sessionId');

  static Future<String> encryptPeerResponse({
    required ZyncHandshakeQrPayload handshake,
    required LocalProfile scannerProfile,
  }) async {
    final clear = utf8.encode(jsonEncode({
      'v': zyncRelayProtocolVersion,
      'sid': handshake.sessionId,
      'exp': handshake.expiresAt.toUtc().millisecondsSinceEpoch,
      'p': QrProfilePayload.fromProfile(scannerProfile).toCompactJson(),
    }));
    if (clear.length > _maxDecodedBytes) throw const FormatException('Peer response is too large');
    final box = await _algorithm.encrypt(
      clear,
      secretKey: SecretKey(handshake.secretBytes),
      aad: _aad(handshake.sessionId),
    );
    final envelope = utf8.encode(jsonEncode({
      'n': _base64UrlNoPad(box.nonce),
      'c': _base64UrlNoPad(box.cipherText),
      'm': _base64UrlNoPad(box.mac.bytes),
    }));
    return _base64UrlNoPad(envelope);
  }

  static Future<QrProfilePayload> decryptPeerResponse({
    required RelayBootstrap bootstrap,
    required String opaquePayload,
    DateTime? now,
  }) async {
    try {
      final envelopeBytes = _base64UrlDecodeNoPad(opaquePayload);
      if (envelopeBytes.length > _maxDecodedBytes) throw const FormatException('Relay envelope is too large');
      final envelope = Map<String, dynamic>.from(jsonDecode(utf8.decode(envelopeBytes)) as Map);
      final nonce = _base64UrlDecodeNoPad((envelope['n'] as String?) ?? '');
      final cipherText = _base64UrlDecodeNoPad((envelope['c'] as String?) ?? '');
      final mac = _base64UrlDecodeNoPad((envelope['m'] as String?) ?? '');
      final clear = await _algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKey(bootstrap.secretBytes),
        aad: _aad(bootstrap.sessionId),
      );
      if (clear.length > _maxDecodedBytes) throw const FormatException('Relay response is too large');
      final json = Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
      if ((json['v'] as num?)?.toInt() != zyncRelayProtocolVersion) {
        throw const FormatException('Unsupported relay response');
      }
      if (json['sid'] != bootstrap.sessionId) throw const FormatException('Relay session mismatch');
      final responseExpiry = (json['exp'] as num?)?.toInt();
      if (responseExpiry != bootstrap.expiresAt.toUtc().millisecondsSinceEpoch) {
        throw const FormatException('Relay expiry mismatch');
      }
      final current = (now ?? DateTime.now()).toUtc();
      if (!current.isBefore(bootstrap.expiresAt)) throw const FormatException('Relay response expired');
      final profileMap = Map<String, dynamic>.from(json['p'] as Map);
      return QrProfilePayload.decode(jsonEncode(profileMap));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid encrypted relay response');
    }
  }
}

enum RelayFailureKind { unavailable, expired, alreadyAnswered, invalid }

class RelayException implements Exception {
  const RelayException(this.kind);
  final RelayFailureKind kind;
}

class RelayTakeResult {
  const RelayTakeResult.waiting() : payload = null;
  const RelayTakeResult.ready(this.payload);
  final String? payload;
  bool get isReady => payload != null;
}

class RelayRespondResult {
  const RelayRespondResult({this.proofCapability});
  final String? proofCapability;
}

class RelayConsumeResult {
  const RelayConsumeResult({this.proofTicket});
  final String? proofTicket;
}

class RelayProofResult {
  const RelayProofResult.waiting() : proofTicket = null;
  const RelayProofResult.ready(this.proofTicket);

  final String? proofTicket;
  bool get isReady => proofTicket != null;
}

abstract class RelayClient {
  Future<void> createSession({
    required String sessionId,
    required String hostToken,
    required DateTime expiresAt,
  });
  Future<RelayRespondResult> respond({
    required String sessionId,
    required String payload,
  });
  Future<RelayTakeResult> take({
    required String sessionId,
    required String hostToken,
  });
  Future<RelayProofResult> proof({
    required String sessionId,
    required String proofCapability,
  });
  Future<RelayConsumeResult> consume({
    required String sessionId,
    required String hostToken,
  });
  Future<void> cancel({required String sessionId, required String hostToken});
}

class HttpRelayClient implements RelayClient {
  HttpRelayClient({this.baseUrl = const String.fromEnvironment('ZYNC_API_BASE')});

  final String baseUrl;

  Uri? get _uri {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    final uri = Uri.tryParse('$trimmed/api/v1/relay');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  Future<({int status, Map<String, dynamic> body})> _post(Map<String, dynamic> body) async {
    final uri = _uri;
    if (uri == null) throw const RelayException(RelayFailureKind.unavailable);
    try {
      final response = await http
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      return (status: response.statusCode, body: decoded);
    } catch (_) {
      throw const RelayException(RelayFailureKind.unavailable);
    }
  }

  RelayException _mapFailure(int status) {
    if (status == 409) return const RelayException(RelayFailureKind.alreadyAnswered);
    if (status == 410) return const RelayException(RelayFailureKind.expired);
    if (status == 400 || status == 403 || status == 413 || status == 502) {
      return const RelayException(RelayFailureKind.invalid);
    }
    return const RelayException(RelayFailureKind.unavailable);
  }

  @override
  Future<void> createSession({
    required String sessionId,
    required String hostToken,
    required DateTime expiresAt,
  }) async {
    final result = await _post({
      'action': 'create',
      'protocolVersion': zyncRelayProtocolVersion,
      'sessionId': sessionId,
      'hostToken': hostToken,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    });
    if (result.status != 201 && result.status != 200) throw _mapFailure(result.status);
  }

  @override
  Future<RelayRespondResult> respond({
    required String sessionId,
    required String payload,
  }) async {
    final result = await _post({
      'action': 'respond',
      'protocolVersion': zyncRelayProtocolVersion,
      'sessionId': sessionId,
      'payload': payload,
    });
    if (result.status != 200) throw _mapFailure(result.status);
    final capability =
        (result.body['proofCapability'] as String?)?.trim();
    if (capability != null &&
        capability.isNotEmpty &&
        !RegExp(r'^[A-Za-z0-9_-]{43}

  @override
  Future<RelayTakeResult> take({required String sessionId, required String hostToken}) async {
    final result = await _post({
      'action': 'take',
      'protocolVersion': zyncRelayProtocolVersion,
      'sessionId': sessionId,
      'hostToken': hostToken,
    });
    if (result.status != 200) throw _mapFailure(result.status);
    if (result.body['status'] == 'waiting') return const RelayTakeResult.waiting();
    final payload = (result.body['payload'] as String?)?.trim();
    if (result.body['status'] != 'ready' || payload == null || payload.isEmpty) {
      throw const RelayException(RelayFailureKind.invalid);
    }
    return RelayTakeResult.ready(payload);
  }

  @override
  Future<RelayProofResult> proof({
    required String sessionId,
    required String proofCapability,
  }) async {
    final result = await _post({
      'action': 'proof',
      'protocolVersion': zyncRelayProtocolVersion,
      'sessionId': sessionId,
      'proofCapability': proofCapability,
    });
    if (result.status != 200) throw _mapFailure(result.status);
    if (result.body['status'] == 'waiting') {
      return const RelayProofResult.waiting();
    }
    final ticket = (result.body['proofTicket'] as String?)?.trim();
    if (result.body['status'] != 'ready' ||
        ticket == null ||
        !ticket.startsWith('ZP1.')) {
      throw const RelayException(RelayFailureKind.invalid);
    }
    return RelayProofResult.ready(ticket);
  }

  Future<Map<String, dynamic>> _hostAction(
    String action,
    String sessionId,
    String hostToken,
  ) async {
    final result = await _post({
      'action': action,
      'protocolVersion': zyncRelayProtocolVersion,
      'sessionId': sessionId,
      'hostToken': hostToken,
    });
    if (result.status != 200) throw _mapFailure(result.status);
    return result.body;
  }

  @override
  Future<RelayConsumeResult> consume({
    required String sessionId,
    required String hostToken,
  }) async {
    try {
      final body = await _hostAction('consume', sessionId, hostToken);
      final ticket = (body['proofTicket'] as String?)?.trim();
      if (ticket != null &&
          ticket.isNotEmpty &&
          !ticket.startsWith('ZP1.')) {
        throw const RelayException(RelayFailureKind.invalid);
      }
      return RelayConsumeResult(
        proofTicket: ticket == null || ticket.isEmpty ? null : ticket,
      );
    } catch (_) {
      // Best effort after authenticated decrypt. TTL remains the hard cleanup guarantee.
      return const RelayConsumeResult();
    }
  }

  @override
  Future<void> cancel({
    required String sessionId,
    required String hostToken,
  }) async {
    try {
      await _hostAction('cancel', sessionId, hostToken);
    } catch (_) {
      // Best effort only. Server-side TTL is the hard cleanup guarantee.
    }
  }
}
).hasMatch(capability)) {
      throw const RelayException(RelayFailureKind.invalid);
    }
    return RelayRespondResult(
      proofCapability:
          capability == null || capability.isEmpty ? null : capability,
    );
  }

  @override
  Future<RelayTakeResult> take({required String sessionId, required String hostToken}) async {
    final result = await _post({
      'action': 'take',
      'protocolVersion': zyncRelayProtocolVersion,
      'sessionId': sessionId,
      'hostToken': hostToken,
    });
    if (result.status != 200) throw _mapFailure(result.status);
    if (result.body['status'] == 'waiting') return const RelayTakeResult.waiting();
    final payload = (result.body['payload'] as String?)?.trim();
    if (result.body['status'] != 'ready' || payload == null || payload.isEmpty) {
      throw const RelayException(RelayFailureKind.invalid);
    }
    return RelayTakeResult.ready(payload);
  }

  Future<void> _delete(String action, String sessionId, String hostToken) async {
    final result = await _post({
      'action': action,
      'protocolVersion': zyncRelayProtocolVersion,
      'sessionId': sessionId,
      'hostToken': hostToken,
    });
    if (result.status != 200) throw _mapFailure(result.status);
  }

  @override
  Future<void> consume({required String sessionId, required String hostToken}) async {
    try {
      await _delete('consume', sessionId, hostToken);
    } catch (_) {
      // Best effort after authenticated decrypt. TTL remains the hard cleanup guarantee.
    }
  }

  @override
  Future<void> cancel({required String sessionId, required String hostToken}) async {
    try {
      await _delete('cancel', sessionId, hostToken);
    } catch (_) {
      // Best effort only. Server-side TTL is the hard cleanup guarantee.
    }
  }
}

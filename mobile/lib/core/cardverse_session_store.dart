import 'dart:convert';

import 'secure_key_value_store.dart';

export 'secure_key_value_store.dart'
    show FlutterSecureKeyValueStore, SecureKeyValueStore;

class CardverseSessionCredential {
  const CardverseSessionCredential({
    required this.token,
    required this.expiresAt,
  });

  final String token;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !now.toUtc().isBefore(expiresAt.toUtc());
}

class CardverseSessionStore {
  CardverseSessionStore({
    SecureKeyValueStore? storage,
  }) : _storage = storage ?? FlutterSecureKeyValueStore();

  static const _credentialKey = 'zync.cardverse.session.credential.v1';
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{32,128}$');

  final SecureKeyValueStore _storage;

  Future<void> save(CardverseSessionCredential credential) async {
    final token = credential.token.trim();
    final expiry = credential.expiresAt.toUtc();
    if (!_tokenPattern.hasMatch(token) ||
        !expiry.isAfter(
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        )) {
      throw const FormatException('Invalid Cardverse session credential');
    }

    // One encrypted value avoids token/expiry split-brain after process death.
    await _storage.write(
      _credentialKey,
      jsonEncode({
        'v': 1,
        'token': token,
        'expiresAt': expiry.toIso8601String(),
      }),
    );
  }

  Future<CardverseSessionCredential?> load({
    DateTime? now,
  }) async {
    final raw = (await _storage.read(_credentialKey))?.trim() ?? '';
    if (raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['v'] != 1) {
        throw const FormatException('Invalid secure session blob');
      }
      final token = (decoded['token'] as String?)?.trim() ?? '';
      final expiry = DateTime.tryParse(
        (decoded['expiresAt'] as String?) ?? '',
      )?.toUtc();
      if (!_tokenPattern.hasMatch(token) || expiry == null) {
        throw const FormatException('Invalid secure session blob');
      }

      final credential = CardverseSessionCredential(
        token: token,
        expiresAt: expiry,
      );
      if (credential.isExpired(now ?? DateTime.now())) {
        await clear();
        return null;
      }
      return credential;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() => _storage.delete(_credentialKey);
}

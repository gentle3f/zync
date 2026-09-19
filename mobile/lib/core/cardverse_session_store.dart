import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CardverseSessionCredential {
  const CardverseSessionCredential({
    required this.token,
    required this.expiresAt,
  });

  final String token;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !now.toUtc().isBefore(expiresAt.toUtc());
}

abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class CardverseSessionStore {
  CardverseSessionStore({
    SecureKeyValueStore? storage,
  }) : _storage = storage ?? FlutterSecureKeyValueStore();

  static const _tokenKey = 'zync.cardverse.session.token.v1';
  static const _expiryKey = 'zync.cardverse.session.expiry.v1';
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{32,128}$');

  final SecureKeyValueStore _storage;

  Future<void> save(CardverseSessionCredential credential) async {
    final token = credential.token.trim();
    final expiry = credential.expiresAt.toUtc();
    if (!_tokenPattern.hasMatch(token) ||
        !expiry.isAfter(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))) {
      throw const FormatException('Invalid Cardverse session credential');
    }

    // Write expiry first so a partial write can never expose an unbounded token.
    await _storage.write(_expiryKey, expiry.toIso8601String());
    try {
      await _storage.write(_tokenKey, token);
    } catch (_) {
      await _storage.delete(_expiryKey);
      rethrow;
    }
  }

  Future<CardverseSessionCredential?> load({
    DateTime? now,
  }) async {
    final token = (await _storage.read(_tokenKey))?.trim() ?? '';
    final expiryRaw = (await _storage.read(_expiryKey))?.trim() ?? '';
    final expiry = DateTime.tryParse(expiryRaw)?.toUtc();

    if (!_tokenPattern.hasMatch(token) || expiry == null) {
      if (token.isNotEmpty || expiryRaw.isNotEmpty) {
        await clear();
      }
      return null;
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
  }

  Future<void> clear() async {
    await _storage.delete(_tokenKey);
    await _storage.delete(_expiryKey);
  }
}

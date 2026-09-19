import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_session_store.dart';

class _MemorySecureStore implements SecureKeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  test('Cardverse session is stored behind secure key-value abstraction', () async {
    final secure = _MemorySecureStore();
    final store = CardverseSessionStore(storage: secure);
    final credential = CardverseSessionCredential(
      token: 'A' * 43,
      expiresAt: DateTime.utc(2026, 10, 20),
    );

    await store.save(credential);
    final loaded = await store.load(now: DateTime.utc(2026, 9, 20));

    expect(loaded, isNotNull);
    expect(loaded!.token, credential.token);
    expect(loaded.expiresAt, credential.expiresAt);
    expect(secure.values.values, contains(credential.token));
  });

  test('expired secure session is deleted instead of reused', () async {
    final secure = _MemorySecureStore();
    final store = CardverseSessionStore(storage: secure);
    await store.save(
      CardverseSessionCredential(
        token: 'B' * 43,
        expiresAt: DateTime.utc(2026, 9, 19),
      ),
    );

    expect(
      await store.load(now: DateTime.utc(2026, 9, 20)),
      isNull,
    );
    expect(secure.values, isEmpty);
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_session_store.dart';
import 'package:zync/screens/cardverse_account_screen.dart';

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

Future<void> _pumpAccount(
  WidgetTester tester, {
  required TargetPlatform platform,
}) async {
  debugDefaultTargetPlatformOverride = platform;
  await tester.pumpWidget(
    MaterialApp(
      home: CardverseAccountScreen(
        sessionStore: CardverseSessionStore(
          storage: _MemorySecureStore(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('iOS signed-out account offers Sign in with Apple', (tester) async {
    try {
      await _pumpAccount(
        tester,
        platform: TargetPlatform.iOS,
      );

      expect(
        find.byKey(const ValueKey('zync-account-apple-sign-in')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android signed-out account does not show Apple sign-in',
      (tester) async {
    try {
      await _pumpAccount(
        tester,
        platform: TargetPlatform.android,
      );

      expect(
        find.byKey(const ValueKey('zync-account-apple-sign-in')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('zync-account-google-sign-in')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

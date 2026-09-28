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
  bool signedIn = false,
}) async {
  debugDefaultTargetPlatformOverride = platform;
  final store = CardverseSessionStore(
    storage: _MemorySecureStore(),
  );
  if (signedIn) {
    await store.save(
      CardverseSessionCredential(
        token: 'S' * 43,
        expiresAt: DateTime.utc(2099, 1, 1),
      ),
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      home: CardverseAccountScreen(
        sessionStore: store,
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
      expect(
        find.byKey(const ValueKey('zync-account-provider-recovery')),
        findsNothing,
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

  testWidgets('iOS signed-in account exposes provider recovery surface',
      (tester) async {
    try {
      await _pumpAccount(
        tester,
        platform: TargetPlatform.iOS,
        signedIn: true,
      );

      expect(
        find.byKey(const ValueKey('zync-account-provider-recovery')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zync-account-link-apple')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zync-account-apple-sign-in')),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android signed-in account keeps recovery surface hidden',
      (tester) async {
    try {
      await _pumpAccount(
        tester,
        platform: TargetPlatform.android,
        signedIn: true,
      );

      expect(
        find.byKey(const ValueKey('zync-account-provider-recovery')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('zync-account-link-apple')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('zync-account-sign-out')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

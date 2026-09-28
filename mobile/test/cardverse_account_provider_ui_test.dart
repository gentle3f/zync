import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/cardverse_account_deletion.dart';
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

class _FakeDeletionController implements CardverseAccountDeletionController {
  int googleCalls = 0;
  int appleCalls = 0;

  @override
  Future<void> deleteWithGoogle() async {
    googleCalls += 1;
  }

  @override
  Future<void> deleteWithApple() async {
    appleCalls += 1;
  }
}

Future<void> _pumpAccount(
  WidgetTester tester, {
  required TargetPlatform platform,
  bool signedIn = false,
  CardverseAccountDeletionController? deletionController,
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
        accountDeletionController: deletionController,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _scrollToDeleteAccount(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('zync-account-delete-account')),
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
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
      await _scrollToDeleteAccount(tester);
      await _scrollToDeleteAccount(tester);
      expect(
        find.byKey(const ValueKey('zync-account-delete-account')),
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
      expect(
        find.byKey(const ValueKey('zync-account-delete-account')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('delete account requires confirmation before provider verification',
      (tester) async {
    final deletion = _FakeDeletionController();
    try {
      await _pumpAccount(
        tester,
        platform: TargetPlatform.iOS,
        signedIn: true,
        deletionController: deletion,
      );

      await _scrollToDeleteAccount(tester);
      await tester.tap(
        find.byKey(const ValueKey('zync-account-delete-account')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zync-account-delete-confirm')),
        findsOneWidget,
      );
      expect(deletion.googleCalls, 0);
      expect(deletion.appleCalls, 0);

      await tester.tap(
        find.byKey(const ValueKey('zync-account-delete-cancel')),
      );
      await tester.pumpAndSettle();

      expect(deletion.googleCalls, 0);
      expect(deletion.appleCalls, 0);
      expect(
        find.byKey(const ValueKey('zync-account-delete-account')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS account deletion uses explicit Apple verification and signs out',
      (tester) async {
    final deletion = _FakeDeletionController();
    try {
      await _pumpAccount(
        tester,
        platform: TargetPlatform.iOS,
        signedIn: true,
        deletionController: deletion,
      );

      await _scrollToDeleteAccount(tester);
      await tester.tap(
        find.byKey(const ValueKey('zync-account-delete-account')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('zync-account-delete-confirm')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zync-account-delete-apple')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('zync-account-delete-apple')),
      );
      await tester.pumpAndSettle();

      expect(deletion.appleCalls, 1);
      expect(deletion.googleCalls, 0);
      expect(
        find.byKey(const ValueKey('zync-account-delete-account')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('zync-account-apple-sign-in')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android account deletion can use explicit Google verification',
      (tester) async {
    final deletion = _FakeDeletionController();
    try {
      await _pumpAccount(
        tester,
        platform: TargetPlatform.android,
        signedIn: true,
        deletionController: deletion,
      );

      await _scrollToDeleteAccount(tester);
      await tester.tap(
        find.byKey(const ValueKey('zync-account-delete-account')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('zync-account-delete-confirm')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zync-account-delete-google')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('zync-account-delete-google')),
      );
      await tester.pumpAndSettle();

      expect(deletion.googleCalls, 1);
      expect(deletion.appleCalls, 0);
      expect(
        find.byKey(const ValueKey('zync-account-delete-account')),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

}
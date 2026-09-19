import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zync/l10n/generated/app_localizations.dart';
import 'package:zync/screens/scan_qr_screen.dart';
import 'package:zync/ui/zync_design.dart';

void main() {
  testWidgets('permission-denied scanner state is localized and recoverable', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      _harness(
        ScannerPreviewErrorState(
          error: const MobileScannerException(errorCode: MobileScannerErrorCode.permissionDenied),
          onRetry: () async => retryCount += 1,
        ),
        locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
    );

    expect(find.text('需要相機權限'), findsOneWidget);
    expect(find.textContaining('手機設定'), findsOneWidget);
    expect(find.text('再試'), findsOneWidget);
    expect(find.textContaining('MobileScanner'), findsNothing);

    await tester.tap(find.text('再試'));
    await tester.pump();
    expect(retryCount, 1);
  });

  testWidgets('unsupported-camera state gives a useful nontechnical fallback', (tester) async {
    await tester.pumpWidget(
      _harness(
        ScannerPreviewErrorState(
          error: const MobileScannerException(errorCode: MobileScannerErrorCode.unsupported),
          onRetry: () async {},
        ),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(find.textContaining('show your own QR'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}

Widget _harness(Widget home, {required Locale locale}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ZyncTheme.light(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: home),
  );
}

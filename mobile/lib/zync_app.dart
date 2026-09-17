import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/analytics_service.dart';
import 'core/language_support.dart';
import 'core/local_store.dart';
import 'core/models.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/interest_setup_screen.dart';
import 'ui/zync_design.dart';

class ZyncApp extends StatefulWidget {
  const ZyncApp({super.key});

  @override
  State<ZyncApp> createState() => _ZyncAppState();
}

class _ZyncAppState extends State<ZyncApp> {
  LocalProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final locale = ZyncLanguage.canonical(PlatformDispatcher.instance.locale.toLanguageTag());
    final profile = await LocalStore.loadOrCreateProfile(language: locale);
    unawaited(
      ZyncAnalytics.instance.track(
        AnalyticsEvent.appOpen,
        properties: {
          'locale': locale,
          'profile_ready': profile.interests.length >= 5,
        },
      ),
    );
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _save(LocalProfile profile) async {
    await LocalStore.saveProfile(profile);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zync',
      theme: ZyncTheme.light(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: profile == null
          ? const _ZyncLoadingScreen()
          : profile.interests.length < 5
              ? InterestSetupScreen(profile: profile, onSaved: _save)
              : HomeScreen(profile: profile, onProfileChanged: _save),
    );
  }
}

class _ZyncLoadingScreen extends StatelessWidget {
  const _ZyncLoadingScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ConnectionBackdrop(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ZyncMark(size: 72, strokeWidth: 6),
                const SizedBox(height: 20),
                Text(
                  'Zync',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ],
            ),
          ),
        ),
      );
}

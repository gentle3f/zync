import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/local_store.dart';
import 'core/models.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/interest_setup_screen.dart';

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
    final locale = PlatformDispatcher.instance.locale.toLanguageTag();
    final profile = await LocalStore.loadOrCreateProfile(language: locale);
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6A21),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF8),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: profile == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : profile.interests.length < 5
              ? InterestSetupScreen(profile: profile, onSaved: _save)
              : HomeScreen(profile: profile, onProfileChanged: _save),
    );
  }
}

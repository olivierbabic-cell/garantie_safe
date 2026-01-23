// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/theme/app_theme.dart';
import 'package:garantie_safe/core/security/app_lock_gate.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/core/locale_controller.dart';

// Screens
import 'home/home_screen.dart';
import 'features/onboarding/onboarding_welcome_screen.dart';
import 'features/items/items_list_screen.dart';
import 'features/scan_ocr/scan_stub_screen.dart';
import 'features/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.instance.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Garantie Safe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,

          // null => System
          locale: locale,

          // gen-l10n
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          // optional: de_CH -> de fallback
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale == null) return supportedLocales.first;
            for (final s in supportedLocales) {
              if (s.languageCode == deviceLocale.languageCode) return s;
            }
            return supportedLocales.first;
          },

          home: const _StartGate(),
          routes: {
            '/home': (_) => const AppLockGate(child: HomeScreen()),
            '/onboarding': (_) => const OnboardingWelcomeScreen(),
            '/items': (_) => const ItemsListScreen(),
            '/scan': (_) => const ScanStubScreen(),
            '/settings': (_) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

class _StartGate extends StatefulWidget {
  const _StartGate();

  @override
  State<_StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<_StartGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final done = await Prefs.getOnboardingDone();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      done == true ? '/home' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

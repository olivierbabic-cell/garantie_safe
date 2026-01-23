import 'package:flutter/material.dart';
import 'package:garantie_safe/core/prefs.dart';

class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  /// null = System / Device Sprache
  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  Future<void> init() async {
    locale.value =
        await Prefs.getPreferredLocale(); // null oder Locale('de') etc.
  }

  Future<void> setLanguage(String code) async {
    // code: 'system' | 'de' | 'en' | ...
    if (code == 'system') {
      await Prefs.setLanguage(null);
      locale.value = null;
      return;
    }
    await Prefs.setLanguage(code);
    locale.value = Locale(code);
  }
}

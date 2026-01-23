import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  // Keys
  static const _kOnbDone = 'onboarding_done';
  static const _kDarkMode = 'settings_dark_mode';

  // Sprache: null => System, 'de' | 'en'
  static const _kLanguage = 'settings_language';

  // Payment Methods (Onboarding -> Item Edit)
  // WICHTIG: wir nutzen den bestehenden Key, damit deine alten Daten wieder erscheinen
  static const _kPaymentMethods = 'onb_payment_methods';

  // Optionaler Legacy-Key (falls du irgendwo schon "payment_methods" gespeichert hast)
  static const _kPaymentMethodsLegacy = 'payment_methods';

  // ===== Onboarding =====
  static Future<bool> getOnboardingDone() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kOnbDone) ?? false;
  }

  static Future<void> setOnboardingDone(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kOnbDone, v);
  }

  static Future<void> resetOnboarding() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kOnbDone);
  }

  // ===== Dark Mode =====
  static Future<bool> getDarkMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kDarkMode, value);
  }

  // ===== Sprache =====
  static Future<String?> getLanguage() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLanguage); // 'de' | 'en' | null
  }

  static Future<void> setLanguage(String? code) async {
    final sp = await SharedPreferences.getInstance();
    if (code == null || code.isEmpty) {
      await sp.remove(_kLanguage); // null = System
    } else {
      await sp.setString(_kLanguage, code);
    }
  }

  /// Locale für MaterialApp:
  /// - null => Device-Sprache
  /// - Locale('de') / Locale('en') => fix
  static Future<Locale?> getPreferredLocale() async {
    final code = await getLanguage(); // 'de' | 'en' | null
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  // ===== Payment Methods =====
  static Future<List<String>> getPaymentMethods() async {
    final sp = await SharedPreferences.getInstance();

    // Primär (korrekter Key)
    final v = sp.getStringList(_kPaymentMethods);
    if (v != null && v.isNotEmpty) return v;

    // Fallback (legacy)
    final legacy = sp.getStringList(_kPaymentMethodsLegacy);
    if (legacy != null && legacy.isNotEmpty) {
      // einmal migrieren, damit alles wieder konsistent ist
      await sp.setStringList(_kPaymentMethods, legacy);
      return legacy;
    }

    return <String>[];
  }

  static Future<void> setPaymentMethods(List<String> methods) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kPaymentMethods, methods);
  }
}

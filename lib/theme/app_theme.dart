import 'package:flutter/material.dart';

/// Sehr simples, helles App-Theme (nur Light Mode).
/// - Material 3 AN
/// - Primärfarbe Blau
/// - Checkboxen: NICHT ausgefüllt, nur Umrandung + Häkchen
class AppTheme {
  static ThemeData get light {
    final seed = const Color(0xFF2F82FF); // Primär (Blau)

    final base = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final scheme = base.colorScheme;

    // Checkboxen zurück auf „Outline + Häkchen“, nicht „gefüllt“
    final checkboxTheme = CheckboxThemeData(
      // Box NICHT füllen – immer transparent
      fillColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
      // Randfarbe (ausgewählt & nicht ausgewählt)
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
          width: 2,
        ),
      ),
      // Häkchen-Farbe (wenn ausgewählt)
      checkColor: WidgetStatePropertyAll(scheme.primary),
      // leichte Rundung
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      // Splash dezenter
      overlayColor:
          WidgetStatePropertyAll(scheme.primary.withValues(alpha: 0.08)),
    );

    // Buttons schlicht
    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: scheme.primary,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Karten minimal
    final cardTheme = const CardTheme(
      elevation: 0,
      margin: EdgeInsets.zero,
    );

    // Input-Felder schlicht
    final inputTheme = InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return base.copyWith(
      checkboxTheme: checkboxTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      inputDecorationTheme: inputTheme,
    );
  }
}

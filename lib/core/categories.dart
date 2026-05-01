import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class Categories {
  // stabile Codes (DB)
  static const String electronics = 'electronics';
  static const String household = 'household';
  static const String vehicle = 'vehicle';
  static const String clothing = 'clothing';
  static const String services = 'services';
  static const String tools = 'tools';
  static const String other = 'other';

  // UI kann "nicht gesetzt" anzeigen, aber DB soll idealerweise null speichern,
  // wenn nichts gewählt wurde. Darum ist notSet KEIN DB-Code.
  static const String notSet = 'not_set';

  static const List<String> all = <String>[
    electronics,
    household,
    vehicle,
    clothing,
    services,
    tools,
    other,
  ];

  static String label(BuildContext context, String? code) {
    final t = AppLocalizations.of(context)!;
    switch (code) {
      case electronics:
        return t.cat_electronics;
      case household:
        return t.cat_household;
      case vehicle:
        return t.cat_vehicle;
      case clothing:
        return t.cat_clothing;
      case services:
        return t.cat_services;
      case other:
        return t.cat_other;
      case tools:
        return t.cat_tools;
      default:
        return t.cat_not_set;
    }
  }

  static IconData icon(String? code) {
    switch (code) {
      case electronics:
        return Icons.devices_outlined;
      case household:
        return Icons.home_outlined;
      case vehicle:
        return Icons.directions_car_outlined;
      case clothing:
        return Icons.checkroom_outlined;
      case services:
        return Icons.build_outlined;
      case tools:
        return Icons.handyman_outlined;
      case other:
        return Icons.inventory_2_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  /// Accent color for category (used for icons, borders, highlights)
  static Color accentColor(String? code) {
    switch (code) {
      case electronics:
        return const Color(0xFF3B82F6); // Blue
      case household:
        return const Color(0xFF10B981); // Green
      case vehicle:
        return const Color(0xFFF59E0B); // Amber
      case clothing:
        return const Color(0xFF8B5CF6); // Purple
      case services:
        return const Color(0xFF06B6D4); // Cyan
      case tools:
        return const Color(0xFFF97316); // Orange
      case other:
        return const Color(0xFF6B7280); // Neutral Grey
      default:
        return const Color(0xFF6B7280); // Neutral Grey
    }
  }

  /// Light background color for category (extremely subtle, almost white)
  static Color lightBackground(String? code) {
    switch (code) {
      case electronics:
        return const Color(0xFFEFF6FF); // Very light blue
      case household:
        return const Color(0xFFECFDF5); // Very light green
      case vehicle:
        return const Color(0xFFFFFBEB); // Very light amber
      case clothing:
        return const Color(0xFFF5F3FF); // Very light purple
      case services:
        return const Color(0xFFECFEFF); // Very light cyan
      case tools:
        return const Color(0xFFFFF7ED); // Very light orange
      case other:
        return const Color(0xFFF9FAFB); // Very light grey
      default:
        return const Color(0xFFF9FAFB); // Very light grey
    }
  }

  /// Legacy color method - now returns accentColor
  @Deprecated('Use accentColor instead')
  static Color color(String? code) => accentColor(code);
}

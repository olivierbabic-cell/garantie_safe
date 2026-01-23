import 'package:flutter/widgets.dart';
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
}

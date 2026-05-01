import 'package:flutter/material.dart';

/// Category color configuration
///
/// These colors are FUNCTIONAL UI logic, not branding.
/// They represent warranty item categories (electronics, home, vehicle, etc.)
/// and should remain consistent across white-label versions.
///
/// Category colors are separate from brand colors because:
/// - They serve a functional purpose (visual categorization)
/// - Changing them would confuse users who learn to associate colors with categories
/// - They need to be visually distinct from each other
///
/// NOTE: These should NOT change when rebranding the app.

class AppCategoryColors {
  // Prevent instantiation
  AppCategoryColors._();

  // Electronics - Blue
  static const Color electronics = Color(0xFF3B82F6);

  // Home & Living - Green
  static const Color home = Color(0xFF10B981);

  // Vehicle - Red
  static const Color vehicle = Color(0xFFEF4444);

  // Clothing & Accessories - Purple
  static const Color clothing = Color(0xFFA855F7);

  // Services & Subscriptions - Orange
  static const Color service = Color(0xFFF59E0B);

  // Tools & Equipment - Indigo
  static const Color tools = Color(0xFF6366F1);

  // Other / Miscellaneous - Slate
  static const Color other = Color(0xFF64748B);

  /// Get category color by category name/type
  /// Returns a default color if category is not recognized
  static Color forCategory(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return electronics;
      case 'home':
      case 'living':
        return home;
      case 'vehicle':
      case 'car':
      case 'auto':
        return vehicle;
      case 'clothing':
      case 'accessories':
        return clothing;
      case 'service':
      case 'services':
      case 'subscription':
        return service;
      case 'tools':
      case 'equipment':
        return tools;
      default:
        return other;
    }
  }
}

/// Semantic color configuration
///
/// These are also FUNCTIONAL (success, warning, error states)
/// and should remain consistent across white-label versions.

class AppSemanticColors {
  // Prevent instantiation
  AppSemanticColors._();

  // Success states - Green
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  // Warning states - Orange
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Error states - Red
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Info states - Blue
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
}

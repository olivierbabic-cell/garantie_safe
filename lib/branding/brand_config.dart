import 'package:flutter/material.dart';

/// Brand configuration class for white-labeling / rebranding
///
/// This class contains all brand-specific values that change when
/// creating a white-label version or rebranding the app:
/// - App name
/// - Logo asset path
/// - Primary brand colors
/// - Base UI colors (background, surface, borders, text)
///
/// To create a new brand, create a new instance of AppBrandConfig
/// with different values and set it as AppBrand.current
///
/// Example:
/// ```dart
/// final myBrand = AppBrandConfig(
///   appName: 'My App',
///   logoAsset: 'assets/my_logo.png',
///   primary: Color(0xFF3B82F6),
///   primaryDark: Color(0xFF2563EB),
///   primaryLight: Color(0xFFEFF6FF),
///   background: Color(0xFFFFFFFF),
///   surface: Color(0xFFFFFFFF),
///   border: Color(0xFFE5E7EB),
///   textPrimary: Color(0xFF111827),
///   textSecondary: Color(0xFF6B7280),
/// );
/// ```

class AppBrandConfig {
  /// Display name of the app (shown in UI, app bar, etc.)
  final String appName;

  /// Path to the logo asset
  final String logoAsset;

  // ============================================================
  // BRAND COLORS (these change per brand)
  // ============================================================

  /// Primary brand color (buttons, highlights, etc.)
  final Color primary;

  /// Darker shade of primary color
  final Color primaryDark;

  /// Lighter shade of primary color (for backgrounds, hover states)
  final Color primaryLight;

  // ============================================================
  // BASE UI COLORS (typically white/neutral, but customizable)
  // ============================================================

  /// Main background color
  final Color background;

  /// Surface color (cards, containers)
  final Color surface;

  /// Subtle surface variant
  final Color surfaceVariant;

  /// Border color
  final Color border;

  /// Lighter border color
  final Color borderLight;

  /// Divider color
  final Color divider;

  /// Primary text color
  final Color textPrimary;

  /// Secondary text color
  final Color textSecondary;

  /// Tertiary text color
  final Color textTertiary;

  /// Disabled text color
  final Color textDisabled;

  const AppBrandConfig({
    required this.appName,
    required this.logoAsset,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  })  : surfaceVariant = background,
        borderLight = border,
        divider = border,
        textTertiary = textSecondary,
        textDisabled = textSecondary;
}

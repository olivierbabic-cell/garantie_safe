import 'package:flutter/material.dart';
import '../branding/app_brand.dart';
import 'functional_colors.dart';

/// Global design tokens - Single source of truth for all visual design decisions
///
/// This file centralizes:
/// - Colors (from brand config + functional colors)
/// - Typography scale
/// - Spacing system
/// - Border radius values
/// - Shadow definitions
///
/// Usage: AppDesignTokens.colors.primary, AppDesignTokens.spacing.md
///
/// NOTE: Brand colors now come from AppBrand.current
/// This allows easy rebranding without editing this file

class AppDesignTokens {
  // Prevent instantiation
  AppDesignTokens._();

  static const colors = AppColors();
  static const typography = AppTypography();
  static const spacing = AppSpacing();
  static const radii = AppRadii();
  static const shadows = AppShadows();
}

// ============================================================
// COLORS (Brand + Functional)
// ============================================================

class AppColors {
  const AppColors();

  // ============================================================
  // BRAND COLORS (from AppBrand.current)
  // These automatically change when rebranding
  // ============================================================

  // Base colors
  Color get background => AppBrand.current.background;
  Color get surface => AppBrand.current.surface;
  Color get surfaceVariant =>
      AppBrand.current.background; // Derived: same as background

  // Borders and dividers
  Color get border => AppBrand.current.border;
  Color get borderLight => AppBrand.current.border; // Derived: same as border
  Color get divider => AppBrand.current.border; // Derived: same as border

  // Text colors
  Color get textPrimary => AppBrand.current.textPrimary;
  Color get textSecondary => AppBrand.current.textSecondary;
  Color get textTertiary =>
      AppBrand.current.textSecondary; // Derived: same as textSecondary
  Color get textDisabled =>
      AppBrand.current.textSecondary; // Derived: same as textSecondary

  // Primary brand colors
  Color get primary => AppBrand.current.primary;
  Color get primaryLight => AppBrand.current.primaryLight;
  Color get primaryDark => AppBrand.current.primaryDark;
  Color get primaryTint =>
      AppBrand.current.primaryLight; // Derived: same as primaryLight

  // ============================================================
  // FUNCTIONAL COLORS (from AppSemanticColors)
  // These DO NOT change when rebranding - they serve UI functions
  // ============================================================

  // Semantic colors
  Color get success => AppSemanticColors.success;
  Color get successLight => AppSemanticColors.successLight;
  Color get warning => AppSemanticColors.warning;
  Color get warningLight => AppSemanticColors.warningLight;
  Color get error => AppSemanticColors.error;
  Color get errorLight => AppSemanticColors.errorLight;
  Color get info => AppSemanticColors.info;
  Color get infoLight => AppSemanticColors.infoLight;

  // Category colors (from AppCategoryColors)
  Color get categoryElectronics => AppCategoryColors.electronics;
  Color get categoryHome => AppCategoryColors.home;
  Color get categoryVehicle => AppCategoryColors.vehicle;
  Color get categoryClothing => AppCategoryColors.clothing;
  Color get categoryService => AppCategoryColors.service;
  Color get categoryTools => AppCategoryColors.tools;
  Color get categoryOther => AppCategoryColors.other;
}

// ============================================================
// TYPOGRAPHY
// ============================================================

class AppTypography {
  const AppTypography();

  // Screen title (e.g., "Backup & Restore", "Settings")
  TextStyle get screenTitle => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.5,
      );

  // Section header (e.g., "Backup Actions", "Restore")
  TextStyle get sectionHeader => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
      );

  // Card title (e.g., warranty item name)
  TextStyle get cardTitle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // Subsection header (smaller than section header)
  TextStyle get subsectionHeader => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // Body text (standard reading text)
  TextStyle get body => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // Body medium (slightly emphasized)
  TextStyle get bodyMedium => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  // Secondary text (less important information)
  TextStyle get secondary => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // Caption (small text, disclaimers, timestamps)
  TextStyle get caption => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
      );

  // Label (form labels, list labels)
  TextStyle get label => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  // Button text
  TextStyle get button => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );
}

// ============================================================
// SPACING SYSTEM
// ============================================================

class AppSpacing {
  const AppSpacing();

  // Spacing scale (4pt base)
  double get xxs => 4.0; // 4px
  double get xs => 8.0; // 8px
  double get sm => 12.0; // 12px
  double get md => 16.0; // 16px
  double get lg => 20.0; // 20px
  double get xl => 24.0; // 24px
  double get xxl => 32.0; // 32px
  double get xxxl => 40.0; // 40px

  // Common edge insets
  EdgeInsets get screenPadding => EdgeInsets.all(lg); // 20px
  EdgeInsets get cardPadding => EdgeInsets.all(md); // 16px
  EdgeInsets get listItemPadding => EdgeInsets.symmetric(
        horizontal: md,
        vertical: sm,
      ); // 16h, 12v
  EdgeInsets get buttonPadding => EdgeInsets.symmetric(
        horizontal: xl,
        vertical: md,
      ); // 24h, 16v

  // Section spacing
  double get sectionSpacing => xxl; // 32px between major sections
  double get cardSpacing => md; // 16px between cards
  double get listItemSpacing => xs; // 8px between list items
}

// ============================================================
// BORDER RADIUS
// ============================================================

class AppRadii {
  const AppRadii();

  double get xs => 4.0;
  double get sm => 8.0;
  double get md => 12.0;
  double get lg => 16.0;
  double get xl => 18.0;
  double get xxl => 20.0;
  double get full => 999.0; // Pill shape

  // Common border radius
  BorderRadius get card => BorderRadius.circular(md); // 12px
  BorderRadius get button => BorderRadius.circular(xl); // 18px
  BorderRadius get input => BorderRadius.circular(md); // 12px
  BorderRadius get dialog => BorderRadius.circular(lg); // 16px
}

// ============================================================
// SHADOWS
// ============================================================

class AppShadows {
  const AppShadows();

  // Subtle card shadow
  List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Elevated element (modals, dropdowns)
  List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // Very subtle (hover states, slight elevation)
  List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
}

// ============================================================
// HELPER EXTENSIONS
// ============================================================

/// Extension on BuildContext to access design tokens easily
extension AppDesignContext on BuildContext {
  AppColors get colors => AppDesignTokens.colors;
  AppTypography get typography => AppDesignTokens.typography;
  AppSpacing get spacing => AppDesignTokens.spacing;
  AppRadii get radii => AppDesignTokens.radii;
  AppShadows get shadows => AppDesignTokens.shadows;
}

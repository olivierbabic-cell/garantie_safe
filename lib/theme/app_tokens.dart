import 'package:flutter/material.dart';
import '../branding/app_brand.dart';

/// Design tokens for non-brand UI constants
///
/// These values are NOT part of branding and should remain consistent
/// across white-label versions:
/// - Spacing scale
/// - Border radius values
/// - Button dimensions
/// - Shadow definitions
/// - Typography scale
///
/// Brand-specific colors are in AppBrand.current

class AppTokens {
  // Prevent instantiation
  AppTokens._();

  static const spacing = AppSpacing();
  static const radii = AppRadii();
  static const buttons = AppButtonTokens();
  static const shadows = AppShadows();
  static const typography = AppTypography();
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
  double get xxl => 24.0;
  double get full => 999.0; // Pill shape

  // Common border radius
  BorderRadius get card => BorderRadius.circular(md); // 12px
  BorderRadius get button => BorderRadius.circular(xl); // 18px
  BorderRadius get input => BorderRadius.circular(md); // 12px
  BorderRadius get dialog => BorderRadius.circular(lg); // 16px
}

// ============================================================
// BUTTON TOKENS
// ============================================================

class AppButtonTokens {
  const AppButtonTokens();

  // Button dimensions (consistent across all button types)
  double get height => 54.0;
  double get borderRadius => 18.0;
  double get iconSize => 22.0;
  double get iconSpacing => 12.0;
  double get horizontalPadding => 24.0;
  double get fontSize => 16.0;
  FontWeight get fontWeight => FontWeight.w500;

  // Min widths
  double get minWidth => 120.0;
  double get minWidthCompact => 80.0;
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
// HELPER EXTENSIONS
// ============================================================

/// Extension on BuildContext to access design tokens easily
extension AppTokensContext on BuildContext {
  AppSpacing get spacing => AppTokens.spacing;
  AppRadii get radii => AppTokens.radii;
  AppButtonTokens get buttonTokens => AppTokens.buttons;
  AppShadows get shadows => AppTokens.shadows;
  AppTypography get typography => AppTokens.typography;
}

/// Extension for accessing brand colors via context
/// This provides backward compatibility with existing code
extension AppBrandContext on BuildContext {
  Color get brandPrimary => AppBrand.current.primary;
  Color get brandPrimaryDark => AppBrand.current.primaryDark;
  Color get brandPrimaryLight => AppBrand.current.primaryLight;
  Color get brandBackground => AppBrand.current.background;
  Color get brandSurface => AppBrand.current.surface;
}

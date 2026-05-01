import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'app_tokens.dart';
import '../branding/app_brand.dart';

/// Comprehensive app theme with design system integration
///
/// Features:
/// - Material 3 enabled
/// - White-based UI (no grey surfaces, customizable via brand config)
/// - Consistent color system from design tokens + brand config
/// - Typography scale (from AppTokens)
/// - Component theming (cards, buttons, inputs, etc.)
/// - Premium, minimal aesthetic
///
/// Brand colors come from AppBrand.current
/// Design tokens (spacing, typography, etc.) come from AppTokens
///
/// To rebrand: Change AppBrand.current to a different brand config

class AppTheme {
  static ThemeData get light {
    const colors = AppColors();
    final typography = AppTokens.typography;
    final radii = AppTokens.radii;

    // Create color scheme from brand + design tokens
    final colorScheme = ColorScheme.light(
      primary: AppBrand.current.primary,
      onPrimary: Colors.white,
      primaryContainer: AppBrand.current.primaryLight,
      onPrimaryContainer: AppBrand.current.primaryDark,
      secondary: AppBrand.current.textSecondary,
      onSecondary: Colors.white,
      surface: AppBrand.current.surface,
      onSurface: AppBrand.current.textPrimary,
      error: colors.error,
      onError: Colors.white,
      errorContainer: colors.errorLight,
      onErrorContainer: colors.error,
      outline: AppBrand.current.border,
      outlineVariant: AppBrand.current.borderLight,
      surfaceContainerHighest: AppBrand.current.surfaceVariant,
    );

    // Define text theme from design tokens
    final textTheme = TextTheme(
      // Display styles (screen titles)
      displayLarge: typography.screenTitle.copyWith(color: colors.textPrimary),
      displayMedium:
          typography.sectionHeader.copyWith(color: colors.textPrimary),
      displaySmall: typography.cardTitle.copyWith(color: colors.textPrimary),

      // Headline styles
      headlineLarge: typography.screenTitle.copyWith(color: colors.textPrimary),
      headlineMedium:
          typography.sectionHeader.copyWith(color: colors.textPrimary),
      headlineSmall:
          typography.subsectionHeader.copyWith(color: colors.textPrimary),

      // Title styles
      titleLarge: typography.cardTitle.copyWith(color: colors.textPrimary),
      titleMedium:
          typography.subsectionHeader.copyWith(color: colors.textPrimary),
      titleSmall: typography.label.copyWith(color: colors.textPrimary),

      // Body styles
      bodyLarge: typography.body.copyWith(color: colors.textPrimary),
      bodyMedium: typography.body.copyWith(color: colors.textSecondary),
      bodySmall: typography.secondary.copyWith(color: colors.textSecondary),

      // Label styles
      labelLarge: typography.button.copyWith(color: colors.textPrimary),
      labelMedium: typography.label.copyWith(color: colors.textPrimary),
      labelSmall: typography.caption.copyWith(color: colors.textSecondary),
    );

    // Checkbox theme (outline style, not filled)
    final checkboxTheme = CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.border,
          width: 2,
        ),
      ),
      checkColor: WidgetStatePropertyAll(colors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      overlayColor:
          WidgetStatePropertyAll(colors.primary.withValues(alpha: 0.08)),
    );

    // Elevated button theme (use AppButtons in practice)
    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: colors.primary,
        minimumSize: const Size.fromHeight(54), // Match AppButton system
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl), // 18px
        ),
        textStyle: typography.button,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );

    // Outlined button theme
    final outlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl),
        ),
        side: BorderSide(color: colors.border, width: 1.5),
        textStyle: typography.button,
      ),
    );

    // Text button theme
    final textButtonTheme = TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        textStyle: typography.button,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );

    // Input decoration theme
    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.md),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.md),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.md),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.md),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.md),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: typography.body.copyWith(color: colors.textTertiary),
      labelStyle: typography.label.copyWith(color: colors.textSecondary),
    );

    // Card theme
    final cardTheme = CardThemeData(
      color: colors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.md),
        side: BorderSide(color: colors.border, width: 1),
      ),
      margin: const EdgeInsets.all(0), // Control margin externally
    );

    // AppBar theme
    final appBarTheme = AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle:
          typography.screenTitle.copyWith(color: colors.textPrimary),
      iconTheme: IconThemeData(color: colors.textPrimary),
    );

    // Divider theme
    final dividerTheme = DividerThemeData(
      color: colors.divider,
      thickness: 1,
      space: 1,
    );

    // List tile theme
    final listTileTheme = ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      iconColor: colors.primary,
      textColor: colors.textPrimary,
      titleTextStyle: typography.body.copyWith(color: colors.textPrimary),
      subtitleTextStyle:
          typography.secondary.copyWith(color: colors.textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      scaffoldBackgroundColor: AppBrand.current.background,

      // Component themes
      checkboxTheme: checkboxTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      textButtonTheme: textButtonTheme,
      inputDecorationTheme: inputTheme,
      cardTheme: cardTheme,
      appBarTheme: appBarTheme,
      dividerTheme: dividerTheme,
      listTileTheme: listTileTheme,

      // Disable default splash/ripple (we'll use custom when needed)
      splashFactory: InkRipple.splashFactory,

      // Icon theme
      iconTheme: IconThemeData(
        color: colors.textPrimary,
        size: 24,
      ),
    );
  }
}

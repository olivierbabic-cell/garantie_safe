import 'package:flutter/material.dart';
import 'brand_config.dart';
import 'garantie_safe_brand.dart';

/// Central brand management class
///
/// This class provides access to the current brand configuration.
/// To rebrand the entire app, simply change the `current` reference
/// to a different AppBrandConfig instance.
///
/// Usage:
/// ```dart
/// Text(AppBrand.current.appName)
/// Image.asset(AppBrand.current.logoAsset)
/// Container(color: AppBrand.current.primary)
/// ```
///
/// To white-label:
/// 1. Create new brand config (e.g., brand_config_acme.dart)
/// 2. Import it here
/// 3. Change `current = acmeBrand;`
/// 4. Rebuild app

class AppBrand {
  // Prevent instantiation
  AppBrand._();

  /// The currently active brand configuration
  ///
  /// CHANGE THIS to rebrand the entire app!
  /// Example:
  /// ```dart
  /// static final current = acmeBrand;  // Use alternative brand
  /// ```
  static final AppBrandConfig current = garantieSafeBrand;

  // Quick access helpers (optional, for convenience)
  static String get appName => current.appName;
  static String get logoAsset => current.logoAsset;
  static Color get primary => current.primary;
  static Color get primaryDark => current.primaryDark;
  static Color get primaryLight => current.primaryLight;
}

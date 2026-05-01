import 'package:flutter/material.dart';
import 'brand_config.dart';

/// Default brand configuration for "Garantie Safe"
///
/// This is the original brand configuration. To create a white-label
/// version, create a new file (e.g., brand_config_acme.dart) with
/// different values and change AppBrand.current to use it.

final garantieSafeBrand = AppBrandConfig(
  appName: 'Garantie Safe',
  logoAsset: 'assets/logo.png', // TODO: Update with actual logo path

  // Garantie Safe blue branding - modern blue color scheme
  primary: Color(0xFF3B82F6), // Modern blue
  primaryDark: Color(0xFF2563EB), // Darker blue for emphasis
  primaryLight: Color(0xFFEFF6FF), // Light blue surface

  // Surface colors - clean white UI
  background: Color(0xFFFFFFFF), // White background
  surface: Color(0xFFFFFFFF), // White cards/surfaces

  // Border colors - subtle gray
  border: Color(0xFFE5E7EB), // Light gray borders

  // Text colors - high contrast for readability
  textPrimary: Color(0xFF111827), // Dark gray for primary text
  textSecondary: Color(0xFF6B7280), // Medium gray for secondary text
);

// Example: How to create an alternative brand
// To rebrand, create a new brand config and set it as AppBrand.current
//
// final acmeBrand = AppBrandConfig(
//   appName: 'Acme Warranty',
//   logoAsset: 'assets/acme_logo.png',
//   primary: Color(0xFFFF5722),      // Orange
//   primaryDark: Color(0xFFE64A19),  // Dark orange
//   primaryLight: Color(0xFFFFE5DB), // Light orange tint
//   background: Color(0xFFFFFFFF),   // White
//   surface: Color(0xFFFFFFFF),      // White
//   border: Color(0xFFE5E7EB),       // Gray
//   textPrimary: Color(0xFF111827),  // Dark gray
//   textSecondary: Color(0xFF6B7280),// Medium gray
// );

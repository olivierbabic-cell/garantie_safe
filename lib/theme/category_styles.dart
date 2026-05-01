import 'package:flutter/material.dart';
import 'functional_colors.dart';

/// Category visual style configuration
///
/// Provides complete styling for warranty item categories including:
/// - Accent color (main category color)
/// - Light background (for cards, chips, badges)
/// - Icon representation
/// - Display label
///
/// These are FUNCTIONAL UI elements, separate from branding,
/// and should remain consistent across white-label versions.

class CategoryStyle {
  final String id;
  final String label;
  final Color accentColor;
  final Color lightBackground;
  final IconData icon;

  const CategoryStyle({
    required this.id,
    required this.label,
    required this.accentColor,
    required this.lightBackground,
    required this.icon,
  });

  /// Creates a light version of the accent color for backgrounds
  static Color _lighten(Color color) {
    // Mix 90% white with 10% of the accent color for a very light background
    return Color.alphaBlend(
      color.withValues(alpha: 0.1),
      Colors.white,
    );
  }
}

/// Predefined category styles for all warranty item categories
class AppCategoryStyles {
  // Prevent instantiation
  AppCategoryStyles._();

  // Electronics - Blue
  static final electronics = CategoryStyle(
    id: 'electronics',
    label: 'Electronics',
    accentColor: AppCategoryColors.electronics,
    lightBackground: CategoryStyle._lighten(AppCategoryColors.electronics),
    icon: Icons.devices,
  );

  // Home & Living - Green
  static final home = CategoryStyle(
    id: 'home',
    label: 'Home & Living',
    accentColor: AppCategoryColors.home,
    lightBackground: CategoryStyle._lighten(AppCategoryColors.home),
    icon: Icons.home,
  );

  // Vehicle - Red
  static final vehicle = CategoryStyle(
    id: 'vehicle',
    label: 'Vehicle',
    accentColor: AppCategoryColors.vehicle,
    lightBackground: CategoryStyle._lighten(AppCategoryColors.vehicle),
    icon: Icons.directions_car,
  );

  // Clothing & Accessories - Purple
  static final clothing = CategoryStyle(
    id: 'clothing',
    label: 'Clothing & Accessories',
    accentColor: AppCategoryColors.clothing,
    lightBackground: CategoryStyle._lighten(AppCategoryColors.clothing),
    icon: Icons.checkroom,
  );

  // Services & Subscriptions - Orange
  static final service = CategoryStyle(
    id: 'service',
    label: 'Services & Subscriptions',
    accentColor: AppCategoryColors.service,
    lightBackground: CategoryStyle._lighten(AppCategoryColors.service),
    icon: Icons.miscellaneous_services,
  );

  // Tools & Equipment - Indigo
  static final tools = CategoryStyle(
    id: 'tools',
    label: 'Tools & Equipment',
    accentColor: AppCategoryColors.tools,
    lightBackground: CategoryStyle._lighten(AppCategoryColors.tools),
    icon: Icons.construction,
  );

  // Other / Miscellaneous - Slate
  static final other = CategoryStyle(
    id: 'other',
    label: 'Other',
    accentColor: AppCategoryColors.other,
    lightBackground: CategoryStyle._lighten(AppCategoryColors.other),
    icon: Icons.category,
  );

  /// Get list of all available category styles
  static List<CategoryStyle> get all => [
        electronics,
        home,
        vehicle,
        clothing,
        service,
        tools,
        other,
      ];

  /// Get category style by ID
  /// Returns 'other' style if category is not found
  static CategoryStyle forId(String categoryId) {
    switch (categoryId.toLowerCase()) {
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

  /// Get category style by color (for backwards compatibility)
  /// Returns the category that matches the given color
  static CategoryStyle? forColor(Color color) {
    for (final category in all) {
      if (category.accentColor.value == color.value) {
        return category;
      }
    }
    return null;
  }
}

/// Extension for easy access to category styles via BuildContext
extension CategoryStylesContext on BuildContext {
  CategoryStyle getCategoryStyle(String categoryId) {
    return AppCategoryStyles.forId(categoryId);
  }
}

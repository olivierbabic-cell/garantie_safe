import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/category_styles.dart';

/// Reusable category icon component
///
/// Displays category icon in a colored rounded container using:
/// - CategoryStyle configuration
/// - Subtle category-colored background
/// - Accent icon color
/// - Consistent sizing
///
/// Usage:
/// ```dart
/// AppCategoryIcon(
///   categoryId: 'electronics',
/// )
/// ```
///
/// Or with custom style:
/// ```dart
/// AppCategoryIcon.custom(
///   icon: Icons.home,
///   accentColor: Colors.blue,
///   backgroundColor: Colors.blue.withOpacity(0.1),
/// )
/// ```
class AppCategoryIcon extends StatelessWidget {
  final CategoryStyle categoryStyle;
  final double size;
  final double iconSize;

  const AppCategoryIcon({
    super.key,
    required this.categoryStyle,
    this.size = 42,
    this.iconSize = 20,
  });

  /// Create from category ID
  factory AppCategoryIcon.fromCategoryId({
    required String categoryId,
    double size = 42,
    double iconSize = 20,
  }) {
    return AppCategoryIcon(
      categoryStyle: AppCategoryStyles.forId(categoryId),
      size: size,
      iconSize: iconSize,
    );
  }

  /// Create with custom icon and colors
  factory AppCategoryIcon.custom({
    required IconData icon,
    required Color accentColor,
    Color? backgroundColor,
    double size = 42,
    double iconSize = 20,
  }) {
    final style = CategoryStyle(
      id: 'custom',
      label: 'Custom',
      accentColor: accentColor,
      lightBackground: backgroundColor ?? accentColor.withValues(alpha: 0.1),
      icon: icon,
    );

    return AppCategoryIcon(
      categoryStyle: style,
      size: size,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: categoryStyle.lightBackground,
        borderRadius: BorderRadius.circular(AppTokens.radii.md),
      ),
      child: Icon(
        categoryStyle.icon,
        size: iconSize,
        color: categoryStyle.accentColor,
      ),
    );
  }
}

/// Compact category badge with icon and label
///
/// Usage:
/// ```dart
/// AppCategoryBadge(
///   categoryId: 'electronics',
/// )
/// ```
class AppCategoryBadge extends StatelessWidget {
  final CategoryStyle categoryStyle;
  final bool compact;

  const AppCategoryBadge({
    super.key,
    required this.categoryStyle,
    this.compact = false,
  });

  /// Create from category ID
  factory AppCategoryBadge.fromCategoryId({
    required String categoryId,
    bool compact = false,
  }) {
    return AppCategoryBadge(
      categoryStyle: AppCategoryStyles.forId(categoryId),
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? EdgeInsets.symmetric(
              horizontal: AppTokens.spacing.xs,
              vertical: AppTokens.spacing.xxs,
            )
          : EdgeInsets.symmetric(
              horizontal: AppTokens.spacing.sm,
              vertical: AppTokens.spacing.xs,
            ),
      decoration: BoxDecoration(
        color: categoryStyle.lightBackground,
        borderRadius: BorderRadius.circular(AppTokens.radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            categoryStyle.icon,
            size: compact ? 12 : 14,
            color: categoryStyle.accentColor,
          ),
          SizedBox(width: AppTokens.spacing.xxs),
          Text(
            categoryStyle.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: categoryStyle.accentColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

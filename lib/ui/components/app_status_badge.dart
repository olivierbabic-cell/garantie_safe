import 'package:flutter/material.dart';
import '../../branding/app_brand.dart';
import '../../theme/app_tokens.dart';
import '../../theme/functional_colors.dart';

/// Status badge type - determines the color scheme
enum AppStatusType {
  active,
  expiring,
  expired,
  noWarranty,
  success,
  warning,
  error,
  info,
  neutral,
}

/// Reusable status badge component
///
/// Displays status with semantic color coding:
/// - Soft tinted background
/// - Readable text
/// - Pill/rounded style
/// - Compact and modern
///
/// Usage:
/// ```dart
/// AppStatusBadge(
///   label: 'Active',
///   type: AppStatusType.active,
/// )
/// ```
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType type;
  final IconData? icon;
  final bool compact;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.current;

    // Determine colors based on type
    Color accentColor;
    Color backgroundColor;

    switch (type) {
      case AppStatusType.active:
      case AppStatusType.success:
        accentColor = AppSemanticColors.success;
        backgroundColor = AppSemanticColors.successLight;
        break;
      case AppStatusType.expiring:
      case AppStatusType.warning:
        accentColor = AppSemanticColors.warning;
        backgroundColor = AppSemanticColors.warningLight;
        break;
      case AppStatusType.expired:
      case AppStatusType.error:
        accentColor = AppSemanticColors.error;
        backgroundColor = AppSemanticColors.errorLight;
        break;
      case AppStatusType.info:
        accentColor = AppSemanticColors.info;
        backgroundColor = AppSemanticColors.infoLight;
        break;
      case AppStatusType.noWarranty:
      case AppStatusType.neutral:
        accentColor = brand.textSecondary;
        backgroundColor = brand.background;
        break;
    }

    return Container(
      padding: compact
          ? EdgeInsets.symmetric(
              horizontal: AppTokens.spacing.xs,
              vertical: AppTokens.spacing.xxs,
            )
          : EdgeInsets.symmetric(
              horizontal: AppTokens.spacing.sm,
              vertical: AppTokens.spacing.xs - 2,
            ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTokens.radii.md),
        border:
            type == AppStatusType.noWarranty || type == AppStatusType.neutral
                ? Border.all(color: brand.border, width: 1)
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 12 : 14,
              color: accentColor,
            ),
            SizedBox(width: AppTokens.spacing.xxs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w600,
              color: accentColor,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

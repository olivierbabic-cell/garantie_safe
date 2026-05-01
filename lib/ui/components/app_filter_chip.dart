import 'package:flutter/material.dart';
import '../../branding/app_brand.dart';
import '../../theme/app_tokens.dart';

/// Reusable filter chip component for selection filters
///
/// Provides a modern, clean chip design with:
/// - Selected state: accent-tinted background
/// - Unselected state: white background with subtle border
/// - Optional icon support
/// - Compact premium spacing
///
/// Usage:
/// ```dart
/// AppFilterChip(
///   label: 'Active',
///   isSelected: _selectedFilter == 'active',
///   onTap: () => setState(() => _selectedFilter = 'active'),
/// )
/// ```
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.current;

    final backgroundColor =
        isSelected ? brand.primary.withValues(alpha: 0.1) : brand.surface;

    final borderColor =
        isSelected ? brand.primary.withValues(alpha: 0.3) : brand.border;

    final textColor = isSelected ? brand.primary : brand.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radii.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTokens.spacing.md,
            vertical: AppTokens.spacing.sm - 2,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTokens.radii.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
                SizedBox(width: AppTokens.spacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper for a row of filter chips with consistent spacing
///
/// Usage:
/// ```dart
/// AppFilterChipRow(
///   children: [
///     AppFilterChip(label: 'All', isSelected: true, onTap: () {}),
///     AppFilterChip(label: 'Active', isSelected: false, onTap: () {}),
///   ],
/// )
/// ```
class AppFilterChipRow extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppFilterChipRow({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: AppTokens.spacing.lg),
      child: Wrap(
        spacing: AppTokens.spacing.xs,
        runSpacing: AppTokens.spacing.xs,
        children: children,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Reusable component widgets - Consistent UI building blocks
///
/// All components use design tokens for consistent styling across the app.
/// Components include:
/// - AppCard: White card with subtle border/shadow
/// - AppSectionHeader: Consistent section title styling
/// - AppListRow: Settings/list row with icon + text + trailing
/// - AppIconContainer: Consistent colored icon backgrounds
/// - AppEmptyState: Centered empty state messages
/// - AppDivider: Standard divider lines

// ============================================================
// APP CARD
// ============================================================

/// Standard white card with subtle border and optional shadow
///
/// Usage:
/// ```dart
/// AppCard(
///   child: Text('Card content'),
///   onTap: () => print('Tapped'),
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool withShadow;
  final bool withBorder;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.withShadow = true,
    this.withBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radii = context.radii;
    final shadows = context.shadows;
    final spacing = context.spacing;

    final cardWidget = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: radii.card,
        border: withBorder
            ? Border.all(
                color: colors.border,
                width: 1,
              )
            : null,
        boxShadow: withShadow ? shadows.card : null,
      ),
      padding: padding ?? spacing.cardPadding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radii.card,
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

/// Consistent section header with optional action button
///
/// Usage:
/// ```dart
/// AppSectionHeader(
///   title: 'My Section',
///   action: TextButton(
///     onPressed: () {},
///     child: Text('See All'),
///   ),
/// )
/// ```
class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;
  final bool divider;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final colors = context.colors;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding ?? EdgeInsets.only(bottom: spacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: typography.sectionHeader.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
        if (divider) AppDivider(),
      ],
    );
  }
}

// ============================================================
// LIST ROW
// ============================================================

/// Standard list row with leading icon, text, and optional trailing widget
///
/// Usage:
/// ```dart
/// AppListRow(
///   icon: Icons.settings,
///   title: 'Settings',
///   subtitle: 'Configure app',
///   trailing: Icon(Icons.chevron_right),
///   onTap: () => navigate(),
/// )
/// ```
class AppListRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const AppListRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final colors = context.colors;
    final spacing = context.spacing;

    Widget content = Padding(
      padding: padding ?? spacing.listItemPadding,
      child: Row(
        children: [
          if (icon != null) ...[
            AppIconContainer(
              icon: icon!,
              color: iconColor ?? colors.primary,
              size: 20,
            ),
            SizedBox(width: spacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: typography.body.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: spacing.xxs),
                  Text(
                    subtitle!,
                    style: typography.secondary.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: spacing.md),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

// ============================================================
// ICON CONTAINER
// ============================================================

/// Consistent circular/rounded icon container with background
///
/// Usage:
/// ```dart
/// AppIconContainer(
///   icon: Icons.home,
///   color: Colors.blue,
///   size: 24,
/// )
/// ```
class AppIconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool circular;
  final EdgeInsetsGeometry? padding;

  const AppIconContainer({
    super.key,
    required this.icon,
    required this.color,
    this.size = 20,
    this.circular = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radii = context.radii;
    final spacing = context.spacing;

    return Container(
      padding: padding ?? EdgeInsets.all(spacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: circular
            ? BorderRadius.circular(radii.full)
            : BorderRadius.circular(radii.sm),
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

/// Centered empty state message with icon and text
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.inbox,
///   title: 'No items',
///   message: 'Add your first warranty to get started',
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final colors = context.colors;
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: spacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colors.textTertiary,
            ),
            SizedBox(height: spacing.lg),
            Text(
              title,
              style: typography.sectionHeader.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: spacing.sm),
              Text(
                message!,
                style: typography.secondary.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: spacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DIVIDER
// ============================================================

/// Standard divider line
class AppDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;

  const AppDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Divider(
      height: height ?? 1,
      thickness: thickness ?? 1,
      color: color ?? colors.divider,
    );
  }
}

// ============================================================
// INFO BANNER
// ============================================================

/// Info banner for notifications, tips, or warnings
///
/// Usage:
/// ```dart
/// AppInfoBanner(
///   type: BannerType.info,
///   message: 'Backup completed successfully',
///   icon: Icons.check_circle,
/// )
/// ```
enum BannerType { info, success, warning, error }

class AppInfoBanner extends StatelessWidget {
  final BannerType type;
  final String message;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const AppInfoBanner({
    super.key,
    required this.type,
    required this.message,
    this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final spacing = context.spacing;
    final radii = context.radii;

    Color backgroundColor;
    Color iconColor;
    IconData defaultIcon;

    switch (type) {
      case BannerType.success:
        backgroundColor = colors.successLight;
        iconColor = colors.success;
        defaultIcon = Icons.check_circle;
        break;
      case BannerType.warning:
        backgroundColor = colors.warningLight;
        iconColor = colors.warning;
        defaultIcon = Icons.warning;
        break;
      case BannerType.error:
        backgroundColor = colors.errorLight;
        iconColor = colors.error;
        defaultIcon = Icons.error;
        break;
      case BannerType.info:
        backgroundColor = colors.infoLight;
        iconColor = colors.info;
        defaultIcon = Icons.info;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radii.input,
      ),
      child: Row(
        children: [
          Icon(
            icon ?? defaultIcon,
            size: 20,
            color: iconColor,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              message,
              style: typography.secondary.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            SizedBox(width: spacing.sm),
            InkWell(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 18,
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

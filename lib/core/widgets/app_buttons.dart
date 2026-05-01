import 'package:flutter/material.dart';

/// App-wide button design system for consistent visual language
///
/// Provides 4 button types:
/// - AppPrimaryButton: Main actions (filled, accent color)
/// - AppSecondaryButton: Important secondary actions (white bg, border, accent text)
/// - AppSoftButton: Supportive actions (light tint bg, accent text)
/// - AppGhostButton: Lightweight tertiary actions (transparent, accent text only)
///
/// All buttons share:
/// - Consistent height (54px)
/// - Consistent border radius (18px)
/// - Consistent padding (horizontal 24px)
/// - Medium/semi-bold typography (w500)
/// - Optional left-aligned icons
/// - Disabled state support
/// - Loading state support
/// - Full-width or constrained-width support

/// Shared button specifications
class _AppButtonSpec {
  static const double height = 54.0;
  static const double borderRadius = 18.0;
  static const double iconSize = 22.0;
  static const double iconSpacing = 12.0;
  static const double horizontalPadding = 24.0;
  static const double fontSize = 16.0;
  static const FontWeight fontWeight = FontWeight.w500;
}

/// Primary button for main actions on a screen
///
/// Visual: Filled with accent color, white text, optional subtle shadow
/// Usage: Backup now, Buy lifetime unlock, Start scan
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.maxWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: colorScheme.primary.withOpacity(0.3),
        disabledForegroundColor: Colors.white.withOpacity(0.5),
        minimumSize:
            Size(fullWidth ? double.infinity : 0, _AppButtonSpec.height),
        padding: const EdgeInsets.symmetric(
          horizontal: _AppButtonSpec.horizontalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_AppButtonSpec.borderRadius),
        ),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      child: _buildContent(context),
    );

    if (!fullWidth && maxWidth != null) {
      button = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: _AppButtonSpec.iconSize,
        height: _AppButtonSpec.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _AppButtonSpec.iconSize),
          SizedBox(width: _AppButtonSpec.iconSpacing),
          Text(
            label,
            style: const TextStyle(
              fontSize: _AppButtonSpec.fontSize,
              fontWeight: _AppButtonSpec.fontWeight,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: _AppButtonSpec.fontSize,
        fontWeight: _AppButtonSpec.fontWeight,
      ),
    );
  }
}

/// Secondary button for important secondary actions
///
/// Visual: White background, subtle border, accent-colored text and icon
/// Usage: Share backup file, Restore from backup, Restore from file
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.maxWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.primary.withOpacity(0.3),
        minimumSize:
            Size(fullWidth ? double.infinity : 0, _AppButtonSpec.height),
        padding: const EdgeInsets.symmetric(
          horizontal: _AppButtonSpec.horizontalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_AppButtonSpec.borderRadius),
        ),
        side: BorderSide(
          color:
              onPressed == null ? Colors.grey.shade200 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: _buildContent(context, colorScheme.primary),
    );

    if (!fullWidth && maxWidth != null) {
      button = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(BuildContext context, Color accentColor) {
    if (isLoading) {
      return SizedBox(
        width: _AppButtonSpec.iconSize,
        height: _AppButtonSpec.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: accentColor,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _AppButtonSpec.iconSize),
          SizedBox(width: _AppButtonSpec.iconSpacing),
          Text(
            label,
            style: const TextStyle(
              fontSize: _AppButtonSpec.fontSize,
              fontWeight: _AppButtonSpec.fontWeight,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: _AppButtonSpec.fontSize,
        fontWeight: _AppButtonSpec.fontWeight,
      ),
    );
  }
}

/// Soft button for supportive actions
///
/// Visual: Very light accent-tinted background, accent text and icon, no heavy border
/// Usage: Setup cloud backup, Export to cloud, Restore purchase
class AppSoftButton extends StatelessWidget {
  const AppSoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.maxWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Ultra-light accent tint background
    final backgroundColor = colorScheme.primary.withOpacity(0.08);
    final disabledBackgroundColor = Colors.grey.shade100;

    Widget button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: colorScheme.primary,
        disabledBackgroundColor: disabledBackgroundColor,
        disabledForegroundColor: colorScheme.primary.withOpacity(0.3),
        minimumSize:
            Size(fullWidth ? double.infinity : 0, _AppButtonSpec.height),
        padding: const EdgeInsets.symmetric(
          horizontal: _AppButtonSpec.horizontalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_AppButtonSpec.borderRadius),
        ),
        elevation: 0,
      ),
      child: _buildContent(context, colorScheme.primary),
    );

    if (!fullWidth && maxWidth != null) {
      button = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(BuildContext context, Color accentColor) {
    if (isLoading) {
      return SizedBox(
        width: _AppButtonSpec.iconSize,
        height: _AppButtonSpec.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: accentColor,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _AppButtonSpec.iconSize),
          SizedBox(width: _AppButtonSpec.iconSpacing),
          Text(
            label,
            style: const TextStyle(
              fontSize: _AppButtonSpec.fontSize,
              fontWeight: _AppButtonSpec.fontWeight,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: _AppButtonSpec.fontSize,
        fontWeight: _AppButtonSpec.fontWeight,
      ),
    );
  }
}

/// Ghost/text button for lightweight tertiary actions
///
/// Visual: Transparent background, no border, accent-colored text
/// Usage: Learn more, Later, Restore purchase (text-only variant)
class AppGhostButton extends StatelessWidget {
  const AppGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.maxWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget button = TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.primary.withOpacity(0.3),
        minimumSize:
            Size(fullWidth ? double.infinity : 0, _AppButtonSpec.height),
        padding: const EdgeInsets.symmetric(
          horizontal: _AppButtonSpec.horizontalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_AppButtonSpec.borderRadius),
        ),
      ),
      child: _buildContent(context, colorScheme.primary),
    );

    if (!fullWidth && maxWidth != null) {
      button = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(BuildContext context, Color accentColor) {
    if (isLoading) {
      return SizedBox(
        width: _AppButtonSpec.iconSize,
        height: _AppButtonSpec.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: accentColor,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _AppButtonSpec.iconSize),
          SizedBox(width: _AppButtonSpec.iconSpacing),
          Text(
            label,
            style: const TextStyle(
              fontSize: _AppButtonSpec.fontSize,
              fontWeight: _AppButtonSpec.fontWeight,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: _AppButtonSpec.fontSize,
        fontWeight: _AppButtonSpec.fontWeight,
      ),
    );
  }
}

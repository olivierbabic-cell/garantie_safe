import 'package:flutter/material.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_components.dart';
import '../../theme/design_tokens.dart';

/// Example screen demonstrating the design system
///
/// This shows how to use:
/// - Design tokens (colors, typography, spacing)
/// - Reusable components (AppCard, AppSectionHeader, AppListRow, etc.)
/// - Button system (AppPrimaryButton, AppSecondaryButton, etc.)
///
/// Compare this clean, consistent code to typical screens with hardcoded values!

class ExampleDesignSystemScreen extends StatelessWidget {
  const ExampleDesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Design System Example',
          style: context.typography.screenTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: context.spacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            AppInfoBanner(
              type: BannerType.info,
              message: 'This screen demonstrates the design system components',
            ),
            SizedBox(height: context.spacing.sectionSpacing),

            // Section 1: Typography
            AppSectionHeader(
              title: 'Typography',
              divider: true,
            ),
            SizedBox(height: context.spacing.md),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Screen Title (28px, w600)',
                    style: context.typography.screenTitle,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'Section Header (18px, w600)',
                    style: context.typography.sectionHeader,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'Card Title (16px, w600)',
                    style: context.typography.cardTitle,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'Body text (16px, w400) - This is regular reading text',
                    style: context.typography.body,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'Secondary text (14px, w400) - Less important info',
                    style: context.typography.secondary,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'Caption (12px, w400) - Timestamps, disclaimers',
                    style: context.typography.caption,
                  ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.sectionSpacing),

            // Section 2: Colors
            AppSectionHeader(title: 'Colors'),
            SizedBox(height: context.spacing.md),

            AppCard(
              child: Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  _ColorChip(
                    label: 'Primary',
                    color: context.colors.primary,
                  ),
                  _ColorChip(
                    label: 'Success',
                    color: context.colors.success,
                  ),
                  _ColorChip(
                    label: 'Warning',
                    color: context.colors.warning,
                  ),
                  _ColorChip(
                    label: 'Error',
                    color: context.colors.error,
                  ),
                  _ColorChip(
                    label: 'Electronics',
                    color: context.colors.categoryElectronics,
                  ),
                  _ColorChip(
                    label: 'Home',
                    color: context.colors.categoryHome,
                  ),
                  _ColorChip(
                    label: 'Vehicle',
                    color: context.colors.categoryVehicle,
                  ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.sectionSpacing),

            // Section 3: List Rows
            AppSectionHeader(title: 'List Rows'),
            SizedBox(height: context.spacing.md),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListRow(
                    icon: Icons.settings,
                    iconColor: context.colors.primary,
                    title: 'Settings',
                    subtitle: 'Configure app preferences',
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => _showSnackBar(context, 'Settings tapped'),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.notifications,
                    iconColor: context.colors.warning,
                    title: 'Notifications',
                    subtitle: 'Manage notification settings',
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => _showSnackBar(context, 'Notifications tapped'),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.lock,
                    iconColor: context.colors.error,
                    title: 'Privacy',
                    subtitle: 'Data and security settings',
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => _showSnackBar(context, 'Privacy tapped'),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.sectionSpacing),

            // Section 4: Icon Containers
            AppSectionHeader(title: 'Icon Containers'),
            SizedBox(height: context.spacing.md),

            AppCard(
              child: Wrap(
                spacing: context.spacing.md,
                runSpacing: context.spacing.md,
                children: [
                  Column(
                    children: [
                      AppIconContainer(
                        icon: Icons.phone_android,
                        color: context.colors.categoryElectronics,
                        size: 24,
                      ),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        'Electronics',
                        style: context.typography.caption,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      AppIconContainer(
                        icon: Icons.home,
                        color: context.colors.categoryHome,
                        size: 24,
                      ),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        'Home',
                        style: context.typography.caption,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      AppIconContainer(
                        icon: Icons.directions_car,
                        color: context.colors.categoryVehicle,
                        size: 24,
                      ),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        'Vehicle',
                        style: context.typography.caption,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      AppIconContainer(
                        icon: Icons.build,
                        color: context.colors.categoryTools,
                        size: 24,
                        circular: false,
                      ),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        'Tools',
                        style: context.typography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.sectionSpacing),

            // Section 5: Buttons
            AppSectionHeader(title: 'Buttons'),
            SizedBox(height: context.spacing.md),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPrimaryButton(
                    label: 'Primary Button',
                    icon: Icons.check,
                    onPressed: () => _showSnackBar(context, 'Primary tapped'),
                  ),
                  SizedBox(height: context.spacing.md),
                  AppSecondaryButton(
                    label: 'Secondary Button',
                    icon: Icons.close,
                    onPressed: () => _showSnackBar(context, 'Secondary tapped'),
                  ),
                  SizedBox(height: context.spacing.md),
                  AppSoftButton(
                    label: 'Soft Button',
                    icon: Icons.info_outline,
                    onPressed: () => _showSnackBar(context, 'Soft tapped'),
                  ),
                  SizedBox(height: context.spacing.md),
                  AppGhostButton(
                    label: 'Ghost Button',
                    icon: Icons.delete_outline,
                    onPressed: () => _showSnackBar(context, 'Ghost tapped'),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.sectionSpacing),

            // Section 6: Banners
            AppSectionHeader(title: 'Info Banners'),
            SizedBox(height: context.spacing.md),

            Column(
              children: [
                AppInfoBanner(
                  type: BannerType.success,
                  message: 'Operation completed successfully!',
                ),
                SizedBox(height: context.spacing.sm),
                AppInfoBanner(
                  type: BannerType.warning,
                  message: 'Warning: Please review before proceeding',
                ),
                SizedBox(height: context.spacing.sm),
                AppInfoBanner(
                  type: BannerType.error,
                  message: 'Error: Something went wrong',
                ),
                SizedBox(height: context.spacing.sm),
                AppInfoBanner(
                  type: BannerType.info,
                  message:
                      'Tip: You can customize your preferences in settings',
                  onDismiss: () => _showSnackBar(context, 'Banner dismissed'),
                ),
              ],
            ),
            SizedBox(height: context.spacing.sectionSpacing),

            // Bottom spacing
            SizedBox(height: context.spacing.xl),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Color chip widget for displaying color swatches
class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(context.radii.sm),
            border: Border.all(
              color: context.colors.border,
              width: 1,
            ),
          ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          label,
          style: context.typography.caption,
        ),
      ],
    );
  }
}

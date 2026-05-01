# Design System Guide

## Overview

This is the **single source of truth** for all visual design decisions in the Garantie Safe app. The design system provides:

- ✅ **Consistent colors** - No more hardcoded `Colors.blue[500]` scattered everywhere
- ✅ **Typography scale** - 6 levels of text styles for clear hierarchy
- ✅ **Spacing system** - Systematic 4pt-based scale (no random padding values)
- ✅ **Reusable components** - AppCard, AppSectionHeader, AppButtons, etc.
- ✅ **Premium aesthetic** - White-based, minimal, professional

---

## File Structure

```
lib/theme/
├── design_tokens.dart       # Core design constants (colors, typography, spacing)
├── app_theme.dart            # ThemeData configuration
lib/core/widgets/
├── app_buttons.dart          # Button system (4 types)
├── app_components.dart       # Reusable components (cards, headers, etc.)
```

---

## Quick Start

### Import the design tokens

```dart
import 'package:garantie_safe/theme/design_tokens.dart';
```

### Access via context (easiest way)

```dart
@override
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(context.spacing.md),  // 16px
    decoration: BoxDecoration(
      color: context.colors.surface,               // White
      borderRadius: context.radii.card,            // 12px
    ),
    child: Text(
      'Hello',
      style: context.typography.body,              // 16px, w400
    ),
  );
}
```

### Access via static constants

```dart
Container(
  padding: EdgeInsets.all(AppDesignTokens.spacing.md),
  color: AppDesignTokens.colors.primary,
  child: Text(
    'Hello',
    style: AppDesignTokens.typography.body,
  ),
)
```

---

## Color System

### Base Colors (White UI)

```dart
context.colors.background       // #FFFFFF - Pure white
context.colors.surface          // #FFFFFF - Pure white
context.colors.surfaceVariant   // #FAFAFA - Very subtle off-white

context.colors.border           // #E5E5E5 - Very light neutral
context.colors.borderLight      // #F0F0F0 - Even lighter
context.colors.divider          // #EEEEEE
```

### Text Colors

```dart
context.colors.textPrimary      // #1A1A1A - Near black
context.colors.textSecondary    // #666666 - Soft grey
context.colors.textTertiary     // #999999 - Lighter grey
context.colors.textDisabled     // #CCCCCC - Very light grey
```

### Accent Color (Primary Blue)

```dart
context.colors.primary          // #2F82FF - Vibrant blue
context.colors.primaryLight     // #5B9FFF - Lighter blue
context.colors.primaryDark      // #1A6FEE - Darker blue
context.colors.primaryTint      // #E8F2FF - Ultra-light blue tint
```

### Semantic Colors

```dart
// Success (green)
context.colors.success          // #10B981
context.colors.successLight     // #D1FAE5

// Warning (orange)
context.colors.warning          // #F59E0B
context.colors.warningLight     // #FEF3C7

// Error (red)
context.colors.error            // #EF4444
context.colors.errorLight       // #FEE2E2

// Info (blue)
context.colors.info             // #3B82F6
context.colors.infoLight        // #DBEAFE
```

### Category Colors

```dart
context.colors.categoryElectronics  // #3B82F6 - Blue
context.colors.categoryHome         // #10B981 - Green
context.colors.categoryVehicle      // #EF4444 - Red
context.colors.categoryClothing     // #A855F7 - Purple
context.colors.categoryService      // #F59E0B - Orange
context.colors.categoryTools        // #6366F1 - Indigo
context.colors.categoryOther        // #64748B - Slate
```

**Example: Category icon background**

```dart
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: context.colors.categoryElectronics.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(
    Icons.phone_android,
    color: context.colors.categoryElectronics,
  ),
)
```

---

## Typography System

### 6 Text Levels

```dart
// 1. Screen Title (28px, w600)
Text('Backup & Restore', style: context.typography.screenTitle)

// 2. Section Header (18px, w600)
Text('Backup Actions', style: context.typography.sectionHeader)

// 3. Card Title (16px, w600)
Text('iPhone 15 Pro', style: context.typography.cardTitle)

// 4. Subsection Header (15px, w600)
Text('Advanced Options', style: context.typography.subsectionHeader)

// 5. Body Text (16px, w400)
Text('This is regular body text', style: context.typography.body)

// 6. Secondary Text (14px, w400)
Text('Less important info', style: context.typography.secondary)

// 7. Caption (12px, w400)
Text('Timestamp or disclaimer', style: context.typography.caption)

// 8. Label (13px, w500)
Text('Form Label', style: context.typography.label)
```

### Customize text styles

```dart
Text(
  'Custom text',
  style: context.typography.body.copyWith(
    color: context.colors.primary,
    fontWeight: FontWeight.w600,
  ),
)
```

---

## Spacing System

### Scale (4pt base)

```dart
context.spacing.xxs    // 4px
context.spacing.xs     // 8px
context.spacing.sm     // 12px
context.spacing.md     // 16px
context.spacing.lg     // 20px
context.spacing.xl     // 24px
context.spacing.xxl    // 32px
context.spacing.xxxl   // 40px
```

### Common Patterns

```dart
// Screen padding (20px all sides)
Padding(
  padding: context.spacing.screenPadding,
  child: child,
)

// Card padding (16px all sides)
Padding(
  padding: context.spacing.cardPadding,
  child: child,
)

// List item padding (16h, 12v)
Padding(
  padding: context.spacing.listItemPadding,
  child: child,
)

// Button padding (24h, 16v)
Padding(
  padding: context.spacing.buttonPadding,
  child: child,
)
```

### Vertical Spacing

```dart
// Between major sections
SizedBox(height: context.spacing.sectionSpacing) // 32px

// Between cards
SizedBox(height: context.spacing.cardSpacing) // 16px

// Between list items
SizedBox(height: context.spacing.listItemSpacing) // 8px
```

---

## Border Radius

```dart
context.radii.xs       // 4px
context.radii.sm       // 8px
context.radii.md       // 12px
context.radii.lg       // 16px
context.radii.xl       // 18px
context.radii.xxl      // 20px
context.radii.full     // 999px (pill shape)

// Pre-configured
context.radii.card     // 12px
context.radii.button   // 18px
context.radii.input    // 12px
context.radii.dialog   // 16px
```

---

## Shadows

```dart
// Subtle card shadow
Container(
  decoration: BoxDecoration(
    boxShadow: context.shadows.card,
  ),
)

// Elevated (modals, dropdowns)
Container(
  decoration: BoxDecoration(
    boxShadow: context.shadows.elevated,
  ),
)

// Very subtle (hover states)
Container(
  decoration: BoxDecoration(
    boxShadow: context.shadows.subtle,
  ),
)
```

---

## Reusable Components

### AppCard

Standard white card with subtle border and optional shadow.

```dart
AppCard(
  child: Text('Card content'),
  onTap: () => print('Tapped'),
)

// Custom styling
AppCard(
  padding: EdgeInsets.all(24),
  backgroundColor: Colors.blue.shade50,
  withShadow: false,
  child: Text('Custom card'),
)
```

### AppSectionHeader

Consistent section headers with optional action button.

```dart
AppSectionHeader(
  title: 'My Section',
  action: TextButton(
    onPressed: () {},
    child: Text('See All'),
  ),
)

// With divider
AppSectionHeader(
  title: 'Settings',
  divider: true,
)
```

### AppListRow

Settings/list rows with icon, title, subtitle, and trailing widget.

```dart
AppListRow(
  icon: Icons.settings,
  iconColor: context.colors.primary,
  title: 'App Settings',
  subtitle: 'Configure preferences',
  trailing: Icon(Icons.chevron_right),
  onTap: () => navigateToSettings(),
)
```

### AppIconContainer

Colored icon backgrounds (circular or rounded).

```dart
AppIconContainer(
  icon: Icons.home,
  color: context.colors.categoryHome,
  size: 24,
)

// Square with rounded corners
AppIconContainer(
  icon: Icons.phone_android,
  color: context.colors.categoryElectronics,
  circular: false,
)
```

### AppEmptyState

Centered empty state with icon and message.

```dart
AppEmptyState(
  icon: Icons.inbox,
  title: 'No warranties yet',
  message: 'Add your first warranty to get started',
  action: AppPrimaryButton(
    label: 'Add Warranty',
    onPressed: () => navigateToAdd(),
  ),
)
```

### AppInfoBanner

Info/success/warning/error banners.

```dart
AppInfoBanner(
  type: BannerType.success,
  message: 'Backup completed successfully!',
  icon: Icons.check_circle,
  onDismiss: () => setState(() => showBanner = false),
)
```

### AppDivider

Standard divider line.

```dart
AppDivider()

// Custom
AppDivider(
  height: 2,
  thickness: 2,
  color: context.colors.primary,
)
```

---

## Button System

See [BUTTON_DESIGN_SYSTEM.md](BUTTON_DESIGN_SYSTEM.md) for full documentation.

```dart
// Primary action (filled blue)
AppPrimaryButton(
  label: 'Create Backup',
  icon: Icons.backup,
  onPressed: () => createBackup(),
)

// Secondary action (white with border)
AppSecondaryButton(
  label: 'Cancel',
  onPressed: () => Navigator.pop(context),
)

// Soft action (light tint background)
AppSoftButton(
  label: 'Learn More',
  icon: Icons.info_outline,
  onPressed: () => showInfo(),
)

// Ghost action (transparent)
AppGhostButton(
  label: 'Skip',
  onPressed: () => skip(),
)
```

---

## Migration Guide

### Before (Old Approach)

```dart
Container(
  padding: const EdgeInsets.all(20),  // Random value
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),  // Random radius
    border: Border.all(color: Colors.grey[300]!),
  ),
  child: Text(
    'Title',
    style: const TextStyle(
      fontSize: 18,  // Random size
      fontWeight: FontWeight.bold,
      color: Color(0xFF333333),  // Random color
    ),
  ),
)
```

### After (Design System)

```dart
AppCard(
  child: Text(
    'Title',
    style: context.typography.cardTitle,
  ),
)
```

**Benefits:**
- ✅ 80% less code
- ✅ Automatically consistent
- ✅ Easy to change globally
- ✅ Self-documenting

---

## Best Practices

### ✅ DO

```dart
// Use design tokens
Container(
  padding: EdgeInsets.all(context.spacing.md),
  color: context.colors.surface,
)

// Use typography styles
Text('Hello', style: context.typography.body)

// Use reusable components
AppCard(child: content)
```

### ❌ DON'T

```dart
// Don't hardcode random values
Container(
  padding: const EdgeInsets.all(17),  // ❌ Why 17?
  color: const Color(0xFFEEEEEE),     // ❌ Random grey
)

// Don't use inline TextStyle
Text(
  'Hello',
  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),  // ❌
)

// Don't duplicate component code
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[300]!),
  ),
  child: content,
)  // ❌ Use AppCard instead
```

---

## Examples

### Example 1: Settings Screen

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: context.typography.screenTitle),
      ),
      body: Padding(
        padding: context.spacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(title: 'Account'),
            SizedBox(height: context.spacing.md),
            
            AppCard(
              child: Column(
                children: [
                  AppListRow(
                    icon: Icons.person,
                    title: 'Profile',
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => navigateToProfile(),
                  ),
                  AppDivider(),
                  AppListRow(
                    icon: Icons.security,
                    title: 'Privacy',
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => navigateToPrivacy(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 2: Empty State

```dart
class WarrantyListScreen extends StatelessWidget {
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long,
        title: 'No warranties yet',
        message: 'Start adding your warranties to keep track',
        action: AppPrimaryButton(
          label: 'Add First Warranty',
          icon: Icons.add,
          onPressed: () => navigateToAdd(),
        ),
      );
    }
    
    return ListView.builder(
      padding: context.spacing.screenPadding,
      itemBuilder: (context, index) => buildWarrantyCard(index),
    );
  }
}
```

---

## Next Steps

1. **Audit existing screens** - Find hardcoded colors, spacing, text styles
2. **Replace with design tokens** - Use `context.colors.*`, `context.spacing.*`, etc.
3. **Use reusable components** - Replace custom containers with AppCard, etc.
4. **Remove inconsistencies** - No more random 15px, 17px, 23px values

---

## Questions?

- **Colors:** See `lib/theme/design_tokens.dart` → `AppColors`
- **Typography:** See `lib/theme/design_tokens.dart` → `AppTypography`
- **Spacing:** See `lib/theme/design_tokens.dart` → `AppSpacing`
- **Components:** See `lib/core/widgets/app_components.dart`
- **Buttons:** See [BUTTON_DESIGN_SYSTEM.md](BUTTON_DESIGN_SYSTEM.md)

**Remember:** This design system is the **single source of truth**. If you need a new color, spacing value, or component, add it to the design tokens first, then use it everywhere.

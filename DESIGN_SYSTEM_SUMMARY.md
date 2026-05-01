# Design System - Quick Reference

## Single Source of Truth for Visual Design

This design system eliminates **hardcoded colors, random spacing values, and inconsistent typography** across the app.

---

## 📦 Files

| File | Purpose |
|------|---------|
| `lib/theme/design_tokens.dart` | Core constants (colors, typography, spacing, radii, shadows) |
| `lib/theme/app_theme.dart` | ThemeData configuration integrating design tokens |
| `lib/core/widgets/app_buttons.dart` | 4 button types (Primary, Secondary, Soft, Ghost) |
| `lib/core/widgets/app_components.dart` | Reusable components (Card, Header, ListRow, etc.) |

---

## 🎨 Colors

```dart
// Access via context (recommended)
context.colors.primary          // #2F82FF blue
context.colors.background       // #FFFFFF white
context.colors.textPrimary      // #1A1A1A near black
context.colors.textSecondary    // #666666 soft grey

// Semantic
context.colors.success          // Green
context.colors.warning          // Orange  
context.colors.error            // Red

// Category colors
context.colors.categoryElectronics  // Blue
context.colors.categoryHome         // Green
context.colors.categoryVehicle      // Red
```

---

## 📝 Typography

```dart
context.typography.screenTitle     // 28px, w600 - "Backup & Restore"
context.typography.sectionHeader   // 18px, w600 - "Backup Actions"
context.typography.cardTitle       // 16px, w600 - "iPhone 15"
context.typography.body            // 16px, w400 - Regular text
context.typography.secondary       // 14px, w400 - Subtle text
context.typography.caption         // 12px, w400 - Timestamps
```

---

## 📏 Spacing

```dart
context.spacing.xxs     // 4px
context.spacing.xs      // 8px
context.spacing.sm      // 12px
context.spacing.md      // 16px   ← Most common
context.spacing.lg      // 20px
context.spacing.xl      // 24px
context.spacing.xxl     // 32px   ← Section spacing

// Pre-configured
context.spacing.screenPadding    // 20px all sides
context.spacing.cardPadding      // 16px all sides
```

---

## 🔘 Border Radius

```dart
context.radii.card      // 12px - Cards, containers
context.radii.button    // 18px - Buttons
context.radii.input     // 12px - Text fields
context.radii.dialog    // 16px - Modals
```

---

## 🧩 Components

### AppCard
```dart
AppCard(
  child: Text('Content'),
  onTap: () {},
)
```

### AppSectionHeader
```dart
AppSectionHeader(title: 'My Section')
```

### AppListRow
```dart
AppListRow(
  icon: Icons.settings,
  title: 'Settings',
  trailing: Icon(Icons.chevron_right),
  onTap: () {},
)
```

### AppEmptyState
```dart
AppEmptyState(
  icon: Icons.inbox,
  title: 'No items',
  message: 'Get started by adding your first item',
)
```

### AppInfoBanner
```dart
AppInfoBanner(
  type: BannerType.success,
  message: 'Saved successfully!',
)
```

---

## 🔳 Buttons

```dart
// Primary (filled blue)
AppPrimaryButton(
  label: 'Create Backup',
  icon: Icons.backup,
  onPressed: () {},
)

// Secondary (white with border)
AppSecondaryButton(
  label: 'Cancel',
  onPressed: () {},
)

// Soft (light tint bg)
AppSoftButton(
  label: 'Learn More',
  onPressed: () {},
)

// Ghost (transparent)
AppGhostButton(
  label: 'Skip',
  onPressed: () {},
)
```

All buttons: **54px height, 18px radius, consistent padding**

---

## ✅ Before & After

### ❌ Before (inconsistent)
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey[300]!),
  ),
  child: Text(
    'Title',
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### ✅ After (design system)
```dart
AppCard(
  child: Text(
    'Title',
    style: context.typography.cardTitle,
  ),
)
```

**Result:** 80% less code, automatically consistent, globally updateable

---

## 🚀 Migration Checklist

- [ ] Replace `Colors.blue[500]` → `context.colors.primary`
- [ ] Replace `EdgeInsets.all(20)` → `context.spacing.screenPadding`
- [ ] Replace `TextStyle(fontSize: 18, ...)` → `context.typography.sectionHeader`
- [ ] Replace custom containers → `AppCard`
- [ ] Replace custom headers → `AppSectionHeader`
- [ ] Replace ElevatedButton → `AppPrimaryButton`
- [ ] Use `context.radii.card` for BorderRadius
- [ ] Use spacing scale (4, 8, 12, 16, 20, 24, 32) - no random values

---

## 📖 Full Documentation

See [DESIGN_SYSTEM_GUIDE.md](DESIGN_SYSTEM_GUIDE.md) for comprehensive guide with examples.

---

## 💡 Pro Tips

1. **Always use `context.colors.*`** instead of hardcoded colors
2. **Use spacing scale values** (4, 8, 12, 16, 20, 24, 32) - no random numbers
3. **Use typography styles** instead of inline TextStyle
4. **Use reusable components** (AppCard, AppSectionHeader, etc.)
5. **Change design globally** by updating design_tokens.dart

**Remember:** If you need a new color/spacing/component, add it to `design_tokens.dart` first!

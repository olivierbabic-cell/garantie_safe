# UI Component Quick Reference

> Fast lookup guide for using the reusable component library

## Import Statement

```dart
import 'package:garantie_safe/ui/components/components.dart';
```

This single import gives you access to:
- `AppCard`, `AppListRow`, `AppSectionHeader`, `AppEmptyState` (core)
- `AppPrimaryButton`, `AppSecondaryButton`, `AppTextButton`, `AppIconButton` (core)
- `AppFilterChip`, `AppFilterChipRow` (new)
- `AppStatusBadge`, `AppStatusType` (new)
- `AppTimelineBar`, `TimelineUrgency` (new)
- `AppCategoryIcon`, `AppCategoryBadge` (new)

---

## Quick Component Lookup

### Filter Selection

```dart
// Single chip
AppFilterChip(
  label: 'Active',
  isSelected: true,
  onTap: () {},
)

// Row with spacing
AppFilterChipRow(
  children: [
    AppFilterChip(label: 'All', isSelected: false, onTap: () {}),
    AppFilterChip(label: 'Active', isSelected: true, onTap: () {}),
  ],
)
```

**Used for**: Filter chips, segmented controls, tag selection

---

### Status Display

```dart
AppStatusBadge(
  label: 'Active',
  type: AppStatusType.active,  // active, expiring, expired, success, warning, error
  icon: Icons.check,  // optional
  compact: true,  // optional, smaller padding
)
```

**Types**: `active`, `expiring`, `expired`, `noWarranty`, `success`, `warning`, `error`, `info`, `neutral`

**Used for**: Warranty status, backup status, sync status, error messages

---

### Warranty/Time Progress

```dart
// Automatic (from dates)
AppTimelineBar.fromDates(
  purchaseDate: item.purchaseDate,
  expiryDate: item.expiryDate,
  showPercentage: true,  // optional
)

// Manual
AppTimelineBar(
  remainingRatio: 0.7,  // 0.0 to 1.0
  urgency: TimelineUrgency.safe,  // safe, moderate, urgent, expired
)
```

**Used for**: Warranty expiry, subscription periods, trial timers

---

### Category Icons

```dart
// From category system
AppCategoryIcon.fromCategoryId(
  categoryId: 'electronics',
)

// Custom
AppCategoryIcon.custom(
  icon: Icons.home,
  accentColor: Colors.blue,
)

// With label
AppCategoryBadge.fromCategoryId(
  categoryId: 'vehicle',
  compact: true,
)
```

**Used for**: Receipt cards, category pickers, legends

---

### Cards

```dart
AppCard(
  padding: EdgeInsets.all(AppTokens.spacing.md),
  onTap: () {},  // optional
  child: YourContent(),
)
```

**Used for**: Receipt cards, setting sections, info panels

---

### List Rows

```dart
AppListRow(
  icon: Icons.settings,
  iconColor: AppBrand.current.primary,
  title: 'Settings',
  subtitle: 'Manage your preferences',  // optional
  trailing: Icon(Icons.chevron_right),  // optional
  onTap: () {},
)
```

**Used for**: Settings items, navigation lists, selectable options

---

### Section Headers

```dart
AppSectionHeader(
  title: 'Receipts',
  action: TextButton(...),  // optional
)
```

**Used for**: Section dividers, grouped content headers

---

### Empty States

```dart
AppEmptyState(
  icon: Icons.inbox_outlined,
  title: 'No receipts yet',
  message: 'Add your first receipt to get started',
  action: AppPrimaryButton(  // optional
    label: 'Add Receipt',
    onPressed: () {},
  ),
)
```

**Used for**: Empty lists, no search results, error states

---

### Buttons

```dart
// Primary action
AppPrimaryButton(
  label: 'Save',
  onPressed: () {},
  icon: Icons.save,  // optional
  isLoading: false,  // optional
)

// Secondary action
AppSecondaryButton(
  label: 'Cancel',
  onPressed: () {},
)

// Text button
AppTextButton(
  label: 'Skip',
  onPressed: () {},
)

// Icon button
AppIconButton(
  icon: Icons.more_vert,
  onPressed: () {},
)
```

**Used for**: Forms, dialogs, toolbars, action sheets

---

## Common Patterns

### Receipt/Item Card

```dart
AppCard(
  padding: EdgeInsets.symmetric(
    horizontal: AppTokens.spacing.md,
    vertical: AppTokens.spacing.sm,
  ),
  onTap: () => navigateToDetail(),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header: icon + title + menu
      Row(
        children: [
          AppCategoryIcon.fromCategoryId(categoryId: item.category),
          SizedBox(width: AppTokens.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppBrand.current.textPrimary,
                  ),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppBrand.current.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.more_vert,
            onPressed: () => showMenu(),
          ),
        ],
      ),
      SizedBox(height: AppTokens.spacing.sm),
      
      // Status badge
      AppStatusBadge(
        label: WarrantyStatusHelper.formatStatus(context, item.purchaseDate, item.expiryDate),
        type: WarrantyStatusHelper.getStatusType(
          WarrantyStatusHelper.getUrgency(item.purchaseDate, item.expiryDate),
        ),
        icon: Icons.schedule_outlined,
        compact: true,
      ),
      SizedBox(height: AppTokens.spacing.xs),
      
      // Progress bar
      AppTimelineBar.fromDates(
        purchaseDate: item.purchaseDate,
        expiryDate: item.expiryDate,
      ),
    ],
  ),
)
```

---

### Filter Bar

```dart
AppFilterChipRow(
  children: [
    AppFilterChip(
      label: t.filter_all,
      isSelected: currentFilter == FilterType.all,
      onTap: () => setFilter(FilterType.all),
    ),
    AppFilterChip(
      label: t.filter_active,
      isSelected: currentFilter == FilterType.active,
      onTap: () => setFilter(FilterType.active),
      icon: Icons.check_circle_outline,
    ),
    AppFilterChip(
      label: t.filter_expiring,
      isSelected: currentFilter == FilterType.expiring,
      onTap: () => setFilter(FilterType.expiring),
      icon: Icons.schedule,
    ),
    AppFilterChip(
      label: t.filter_expired,
      isSelected: currentFilter == FilterType.expired,
      onTap: () => setFilter(FilterType.expired),
      icon: Icons.error_outline,
    ),
  ],
)
```

---

### Settings Section

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    AppSectionHeader(title: 'General'),
    AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          AppListRow(
            icon: Icons.language,
            iconColor: AppBrand.current.primary,
            title: t.language,
            subtitle: 'English',
            trailing: Icon(Icons.chevron_right, color: AppBrand.current.textSecondary),
            onTap: () => showLanguagePicker(),
          ),
          Divider(height: 1),
          AppListRow(
            icon: Icons.notifications,
            iconColor: AppBrand.current.primary,
            title: t.notifications,
            subtitle: 'Enabled',
            trailing: Switch(value: true, onChanged: (v) {}),
            onTap: () => navigateToNotifications(),
          ),
        ],
      ),
    ),
  ],
)
```

---

### Status with Timeline

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    AppStatusBadge(
      label: 'Expires in 45 days',
      type: AppStatusType.warning,
      icon: Icons.schedule,
    ),
    Text(
      '15%',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppBrand.current.textSecondary,
      ),
    ),
  ],
),
SizedBox(height: AppTokens.spacing.xs),
AppTimelineBar.fromDates(
  purchaseDate: DateTime(2023, 1, 1),
  expiryDate: DateTime(2025, 1, 1),
),
```

---

## Spacing Reference

Use `AppTokens.spacing.*` instead of hardcoded values:

```dart
AppTokens.spacing.xs   = 4    // Minimal gap
AppTokens.spacing.sm   = 8    // Small gap
AppTokens.spacing.md   = 16   // Standard gap
AppTokens.spacing.lg   = 24   // Large gap
AppTokens.spacing.xl   = 32   // Extra-large gap
```

---

## Color Reference

Use `AppBrand.current.*` instead of hardcoded colors:

```dart
// Text colors
AppBrand.current.textPrimary      // Dark text (#111827)
AppBrand.current.textSecondary    // Gray text (#6B7280)

// UI colors
AppBrand.current.primary          // Accent color (#3B82F6)
AppBrand.current.border           // Border color (#E5E7EB)
AppBrand.current.background       // Background (#F3F4F6)

// Semantic colors (use AppSemanticColors)
AppSemanticColors.success         // Green (#10B981)
AppSemanticColors.warning         // Orange (#F59E0B)
AppSemanticColors.error           // Red (#EF4444)
AppSemanticColors.info            // Blue (#3B82F6)
```

---

## Radius Reference

Use `AppTokens.radii.*` instead of hardcoded values:

```dart
AppTokens.radii.xs   = 4    // Minimal rounding
AppTokens.radii.sm   = 8    // Small rounding
AppTokens.radii.md   = 12   // Standard (cards, chips)
AppTokens.radii.lg   = 16   // Large rounding
AppTokens.radii.xl   = 24   // Extra-large
AppTokens.radii.full = 999  // Fully rounded (pills)
```

---

## Anti-Patterns ❌

### DON'T hardcode colors
```dart
// ❌ BAD
Container(
  color: Color(0xFF3B82F6),
  child: Text('Hello', style: TextStyle(color: Color(0xFF111827))),
)

// ✅ GOOD
Container(
  color: AppBrand.current.primary,
  child: Text('Hello', style: TextStyle(color: AppBrand.current.textPrimary)),
)
```

### DON'T hardcode spacing
```dart
// ❌ BAD
Padding(
  padding: EdgeInsets.all(16),
  child: ...
)

// ✅ GOOD
Padding(
  padding: EdgeInsets.all(AppTokens.spacing.md),
  child: ...
)
```

### DON'T build custom cards
```dart
// ❌ BAD
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFFE5E7EB)),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: ...
  ),
)

// ✅ GOOD
AppCard(
  padding: EdgeInsets.all(AppTokens.spacing.md),
  child: ...
)
```

### DON'T build custom status badges
```dart
// ❌ BAD
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Color(0xFF10B981).withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
      SizedBox(width: 4),
      Text('Active', style: TextStyle(color: Color(0xFF10B981))),
    ],
  ),
)

// ✅ GOOD
AppStatusBadge(
  label: 'Active',
  type: AppStatusType.active,
  icon: Icons.check,
)
```

---

## Migration Checklist

When refactoring existing screens:

- [ ] Replace `Container` with `AppCard` for cards
- [ ] Replace custom filter chips with `AppFilterChip`
- [ ] Replace status text/rows with `AppStatusBadge`
- [ ] Replace custom progress bars with `AppTimelineBar`
- [ ] Replace hardcoded colors with `AppBrand.current.*`
- [ ] Replace hardcoded spacing with `AppTokens.spacing.*`
- [ ] Replace hardcoded radius with `AppTokens.radii.*`
- [ ] Replace custom category icons with `AppCategoryIcon`
- [ ] Use `AppListRow` for list items
- [ ] Use `AppEmptyState` for empty states

---

## Need More Details?

See `UI_COMPONENT_LIBRARY_SUMMARY.md` for:
- Complete component documentation
- Before/after refactoring examples
- Benefits and metrics
- Migration guides
- API reference

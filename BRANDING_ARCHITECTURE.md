# Branding Architecture Guide

## Overview

This guide explains the **centralized branding architecture** that enables easy rebranding and white-labeling of the Garantie Safe app.

---

## 🎯 Goal Achieved

**Before:** Brand-related values (app name, logo, colors) scattered across many files  
**After:** Single source of truth - change one file to rebrand entire app

---

## 📁 Folder Structure

```
lib/
├── branding/                    ← BRAND-SPECIFIC (change for white-labeling)
│   ├── brand_config.dart        ← AppBrandConfig class definition
│   ├── garantie_safe_brand.dart ← Default "Garantie Safe" brand
│   └── app_brand.dart           ← Central brand manager (AppBrand.current)
│
└── theme/                       ← FUNCTIONAL UI (same across brands)
    ├── app_tokens.dart          ← Spacing, radius, typography (brand-agnostic)
    ├── functional_colors.dart   ← Category & semantic colors (UI logic)
    ├── design_tokens.dart       ← Unified access (brand + functional)
    └── app_theme.dart           ← Theme configuration (reads from AppBrand.current)
```

---

## 🔑 Key Components

### 1. AppBrandConfig (Brand Definition)

**File:** `lib/branding/brand_config.dart`

Defines all brand-specific properties that change when rebranding:

```dart
class AppBrandConfig {
  final String appName;        // "Garantie Safe"
  final String logoAsset;      // "assets/logo.png"
  
  final Color primary;         // #2F82FF (blue)
  final Color primaryDark;     // Darker shade
  final Color primaryLight;    // Lighter shade
  final Color primaryTint;     // Ultra-light tint
  
  final Color background;      // White
  final Color surface;         // White
  final Color border;          // Light grey
  final Color textPrimary;     // Near black
  final Color textSecondary;   // Soft grey
  // ... etc
}
```

**Helper:** `AppBrandConfig.whiteUI()` factory provides sensible defaults for white-based UIs.

---

### 2. Default Brand Config

**File:** `lib/branding/garantie_safe_brand.dart`

```dart
final garantieSafeBrand = AppBrandConfig.whiteUI(
  appName: 'Garantie Safe',
  logoAsset: 'assets/logo.png',
  primary: Color(0xFF2F82FF),      // Blue
  primaryDark: Color(0xFF1A6FEE),
  primaryLight: Color(0xFF5B9FFF),
  primaryTint: Color(0xFFE8F2FF),
);
```

---

### 3. AppBrand (Central Manager)

**File:** `lib/branding/app_brand.dart`

```dart
class AppBrand {
  // THIS IS THE ONLY LINE YOU CHANGE TO REBRAND!
  static final AppBrandConfig current = garantieSafeBrand;
  
  // Convenience getters
  static String get appName => current.appName;
  static String get logoAsset => current.logoAsset;
  static Color get primary => current.primary;
}
```

---

### 4. AppTokens (Functional UI)

**File:** `lib/theme/app_tokens.dart`

**NOT brand-specific** - these stay the same across white-label versions:

```dart
class AppTokens {
  static const spacing = AppSpacing();    // 4, 8, 12, 16, 20, 24, 32
  static const radii = AppRadii();        // Border radius values
  static const buttons = AppButtonTokens(); // Button height: 54px, etc.
  static const shadows = AppShadows();    // Elevation shadows
  static const typography = AppTypography(); // Text styles
}
```

---

### 5. Functional Colors (UI Logic)

**File:** `lib/theme/functional_colors.dart`

**Category colors** (electronics, home, vehicle, etc.) and **semantic colors** (success, warning, error) are **NOT part of branding**.

```dart
class AppCategoryColors {
  static const Color electronics = Color(0xFF3B82F6); // Blue
  static const Color home = Color(0xFF10B981);        // Green
  static const Color vehicle = Color(0xFFEF4444);     // Red
  // ... etc
}

class AppSemanticColors {
  static const Color success = Color(0xFF10B981);     // Green
  static const Color warning = Color(0xFFF59E0B);     // Orange
  static const Color error = Color(0xFFEF4444);       // Red
}
```

**Why separate?** Because these serve **functional purposes** (visual categorization, UI states) and should remain consistent for usability.

---

### 6. Design Tokens (Unified Access)

**File:** `lib/theme/design_tokens.dart`

Provides unified access to **brand colors** (from `AppBrand.current`) and **functional colors**:

```dart
class AppColors {
  // BRAND COLORS (automatically change when rebranding)
  Color get primary => AppBrand.current.primary;
  Color get background => AppBrand.current.background;
  Color get textPrimary => AppBrand.current.textPrimary;
  
  // FUNCTIONAL COLORS (stay the same across brands)
  Color get success => AppSemanticColors.success;
  Color get categoryElectronics => AppCategoryColors.electronics;
}
```

**Usage:**
```dart
context.colors.primary        // Uses brand color
context.colors.success        // Uses functional color
```

---

### 7. AppTheme Integration

**File:** `lib/theme/app_theme.dart`

Theme automatically reads from `AppBrand.current`:

```dart
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: AppBrand.current.primary,      // ← Reads from brand
        surface: AppBrand.current.surface,
        // ...
      ),
      scaffoldBackgroundColor: AppBrand.current.background,
      // ...
    );
  }
}
```

---

## 🚀 How to Rebrand / White-Label

### Step 1: Create New Brand Config

Create `lib/branding/acme_brand.dart`:

```dart
import 'package:flutter/material.dart';
import 'brand_config.dart';

final acmeBrand = AppBrandConfig.whiteUI(
  appName: 'Acme Warranty',
  logoAsset: 'assets/acme_logo.png',
  
  // Orange branding instead of blue
  primary: Color(0xFFFF5722),
  primaryDark: Color(0xFFE64A19),
  primaryLight: Color(0xFFFF7043),
  primaryTint: Color(0xFFFFE5DB),
);
```

### Step 2: Change AppBrand.current

Edit `lib/branding/app_brand.dart`:

```dart
import 'acme_brand.dart';  // Import new brand

class AppBrand {
  // CHANGE THIS LINE:
  static final AppBrandConfig current = acmeBrand;  // ← Was: garantieSafeBrand
  // ...
}
```

### Step 3: Add Logo Asset

Add `assets/acme_logo.png` to your assets folder and update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/acme_logo.png
```

### Step 4: Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

**Done!** Entire app now uses Acme branding.

---

## 📊 What Changes Automatically

When you change `AppBrand.current`:

✅ **App name** in all UI text  
✅ **Logo** across all screens  
✅ **Primary color** (buttons, highlights, accents)  
✅ **Background colors**  
✅ **Surface colors** (cards, containers)  
✅ **Border colors**  
✅ **Text colors**  
✅ **Theme colors** (entire Material theme)

**No need to edit:**
- Individual screens
- Components
- Widgets
- Theme file
- Design tokens

---

## 🎨 Usage Examples

### Access Brand Name

```dart
Text(AppBrand.appName)  // "Garantie Safe" or "Acme Warranty"
```

### Access Logo

```dart
Image.asset(AppBrand.logoAsset)  // Automatically correct logo
```

### Access Brand Colors

```dart
// Via AppBrand directly
Container(color: AppBrand.primary)

// Via context (recommended)
Container(color: context.colors.primary)

// Via design tokens
Container(color: AppDesignTokens.colors.primary)
```

### Access Functional Colors (Category/Semantic)

```dart
// These DON'T change when rebranding
Container(color: context.colors.categoryElectronics)  // Always blue
Container(color: context.colors.success)               // Always green
```

### Access Design Tokens

```dart
// Spacing (same across all brands)
Padding(padding: EdgeInsets.all(context.spacing.md))  // 16px

// Typography (same across all brands)
Text('Title', style: context.typography.screenTitle)  // 28px, w600

// Border radius (same across all brands)
BorderRadius radius = context.radii.card;  // 12px
```

---

## 🔍 Architecture Principles

### 1. Separation of Concerns

| Type | Location | Changes on Rebrand? |
|------|----------|---------------------|
| **Brand** colors | `AppBrand.current` | ✅ Yes |
| **Functional** colors | `AppSemanticColors`, `AppCategoryColors` | ❌ No |
| **Spacing** | `AppTokens.spacing` | ❌ No |
| **Typography** | `AppTokens.typography` | ❌ No |
| **Shadows** | `AppTokens.shadows` | ❌ No |
| **Button dimensions** | `AppTokens.buttons` | ❌ No |

### 2. Single Source of Truth

**Before:**
- App name hardcoded in 15 places
- Logo path hardcoded in 8 places
- Primary color `#2F82FF` hardcoded in 50+ places

**After:**
- App name: 1 place (`AppBrand.current.appName`)
- Logo: 1 place (`AppBrand.current.logoAsset`)
- Primary color: 1 place (`AppBrand.current.primary`)

### 3. Easy White-Labeling

**Time to rebrand:**
- Create new brand config: 5 minutes
- Change `AppBrand.current`: 1 line
- Add logo asset: 2 minutes
- **Total: < 10 minutes**

---

## 📝 Migration from Old Code

### Before (Hardcoded)

```dart
Text('Garantie Safe', style: TextStyle(fontSize: 24))
Image.asset('assets/logo.png')
Container(color: Color(0xFF2F82FF))
```

### After (Branded)

```dart
Text(AppBrand.appName, style: context.typography.screenTitle)
Image.asset(AppBrand.logoAsset)
Container(color: AppBrand.primary)
```

---

## 🛡️ Best Practices

### ✅ DO

```dart
// Use AppBrand for brand-specific values
Text(AppBrand.appName)
Container(color: AppBrand.primary)

// Use AppTokens for UI constants
Padding(padding: context.spacing.screenPadding)
Text('Title', style: context.typography.cardTitle)

// Use functional colors for categories/semantics
Icon(Icons.phone, color: AppCategoryColors.electronics)
Container(color: AppSemanticColors.success)
```

### ❌ DON'T

```dart
// Don't hardcode app name
Text('Garantie Safe')  // ❌

// Don't hardcode colors
Container(color: Color(0xFF2F82FF))  // ❌

// Don't change category colors when rebranding
// (they serve a functional purpose)
```

---

## 🔮 Future Enhancements

Potential additions to the branding architecture:

1. **Font family override** per brand
2. **Dark mode** brand configs
3. **Multiple brands simultaneously** (runtime switching)
4. **Brand-specific copy/text** (translations per brand)
5. **Environment-based branding** (dev vs prod brands)

---

## 📚 File Reference

| File | Purpose | Edit on Rebrand? |
|------|---------|------------------|
| `branding/brand_config.dart` | Brand definition class | ❌ No (it's the template) |
| `branding/garantie_safe_brand.dart` | Default brand | ❌ No (keep for reference) |
| `branding/acme_brand.dart` *(create)* | Alternative brand | ✅ Create new |
| `branding/app_brand.dart` | Central brand manager | ✅ Change 1 line |
| `theme/app_tokens.dart` | Functional UI tokens | ❌ No |
| `theme/functional_colors.dart` | Category/semantic colors | ❌ No |
| `theme/design_tokens.dart` | Unified access | ❌ No |
| `theme/app_theme.dart` | Theme integration | ❌ No |

---

## 🎉 Summary

**Achievement:** Transformed scattered brand values into a **centralized, maintainable architecture**.

**Benefits:**
- ✅ Rebrand entire app by changing **1 line of code**
- ✅ Clear separation between **brand** and **functional** UI
- ✅ Easy to create **white-label versions**
- ✅ **Single source of truth** for all brand values
- ✅ Backward compatible with existing design system
- ✅ Clean folder structure (`branding/` vs `theme/`)

**Rebranding time:** < 10 minutes (vs hours of searching/replacing before)

---

## 💡 Quick Start Guide

To rebrand right now:

1. Create `lib/branding/your_brand.dart`
2. Copy `garantie_safe_brand.dart` as template
3. Change name, logo, colors
4. Edit `app_brand.dart`: `static final current = yourBrand;`
5. Add logo to assets
6. Rebuild

**That's it!** 🚀

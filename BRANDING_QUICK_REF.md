# Branding Quick Reference

## 🎯 Files Created

| File | Purpose |
|------|---------|
| `lib/branding/brand_config.dart` | Brand configuration class |
| `lib/branding/garantie_safe_brand.dart` | Default "Garantie Safe" brand |
| `lib/branding/app_brand.dart` | Central brand manager |
| `lib/theme/app_tokens.dart` | Non-brand UI tokens (spacing, radius, etc.) |
| `lib/theme/functional_colors.dart` | Category & semantic colors |
| `lib/theme/design_tokens.dart` | **Updated** to use AppBrand |
| `lib/theme/app_theme.dart` | **Updated** to use AppBrand |

---

## 🚀 To Rebrand in 3 Steps

### 1. Create Brand Config
```dart
// lib/branding/acme_brand.dart
final acmeBrand = AppBrandConfig.whiteUI(
  appName: 'Acme Warranty',
  logoAsset: 'assets/acme_logo.png',
  primary: Color(0xFFFF5722),
  primaryDark: Color(0xFFE64A19),
  primaryLight: Color(0xFFFF7043),
  primaryTint: Color(0xFFFFE5DB),
);
```

### 2. Change Current Brand
```dart
// lib/branding/app_brand.dart
import 'acme_brand.dart';

class AppBrand {
  static final AppBrandConfig current = acmeBrand; // ← Change this
}
```

### 3. Rebuild
```bash
flutter clean && flutter run
```

**Done!** 🎉

---

## 💻 Usage Examples

### Brand Name
```dart
Text(AppBrand.appName)  // "Garantie Safe" or "Acme Warranty"
AppBar(title: Text(AppBrand.appName))
```

### Logo
```dart
Image.asset(AppBrand.logoAsset)
```

### Brand Colors
```dart
// Direct access
Container(color: AppBrand.primary)

// Via context (recommended)
Container(color: context.colors.primary)
```

### Design Tokens
```dart
// Spacing
Padding(padding: context.spacing.screenPadding)  // 20px
SizedBox(height: context.spacing.md)             // 16px

// Typography
Text('Title', style: context.typography.screenTitle)  // 28px, w600
Text('Body', style: context.typography.body)          // 16px, w400

// Border Radius
BorderRadius radius = context.radii.card;        // 12px
BorderRadius buttonRadius = context.radii.button; // 18px

// Shadows
BoxShadow shadow = context.shadows.card;
```

### Functional Colors (Not Brand-Specific)
```dart
// Category colors (always the same)
Icon(Icons.phone, color: context.colors.categoryElectronics)  // Blue
Icon(Icons.home, color: context.colors.categoryHome)          // Green

// Semantic colors (always the same)
Container(color: context.colors.success)  // Green
Container(color: context.colors.error)    // Red
```

---

## 📁 Folder Structure

```
lib/
├── branding/              ← CHANGE WHEN REBRANDING
│   ├── brand_config.dart
│   ├── garantie_safe_brand.dart
│   └── app_brand.dart     ← EDIT: Change .current
│
└── theme/                 ← STAYS THE SAME
    ├── app_tokens.dart    ← Spacing, radius, typography
    ├── functional_colors.dart  ← Category, semantic
    ├── design_tokens.dart
    └── app_theme.dart
```

---

## 🎨 What's Brandable vs What's Not

### ✅ Brand-Specific (Changes on Rebrand)
- App name
- Logo
- Primary color (+ dark, light, tint variants)
- Background color
- Surface color
- Border colors
- Text colors

### ❌ Functional (Same Across Brands)
- Category colors (electronics, home, vehicle, etc.)
- Semantic colors (success, warning, error, info)
- Spacing scale (4, 8, 12, 16, 20, 24, 32)
- Typography scale
- Border radius values
- Button dimensions
- Shadows

---

## 🔑 Key Classes

### AppBrand
```dart
AppBrand.current       // Current brand config
AppBrand.appName       // "Garantie Safe"
AppBrand.logoAsset     // "assets/logo.png"
AppBrand.primary       // Color(0xFF2F82FF)
```

### AppTokens
```dart
AppTokens.spacing      // AppSpacing (4, 8, 12, 16, ...)
AppTokens.radii        // AppRadii (card, button, input, ...)
AppTokens.typography   // AppTypography (title, body, ...)
AppTokens.buttons      // AppButtonTokens (height: 54, ...)
AppTokens.shadows      // AppShadows (card, elevated, ...)
```

### AppCategoryColors
```dart
AppCategoryColors.electronics  // Blue
AppCategoryColors.home         // Green
AppCategoryColors.vehicle      // Red
AppCategoryColors.forCategory('electronics')  // Helper
```

### AppSemanticColors
```dart
AppSemanticColors.success   // Green
AppSemanticColors.warning   // Orange
AppSemanticColors.error     // Red
AppSemanticColors.info      // Blue
```

---

## ✅ Checklist for New Brand

- [ ] Create brand config file (`acme_brand.dart`)
- [ ] Set app name
- [ ] Set logo asset path
- [ ] Define primary color + variants
- [ ] Import in `app_brand.dart`
- [ ] Change `AppBrand.current`
- [ ] Add logo to `assets/`
- [ ] Update `pubspec.yaml` assets
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Test app

**Time:** ~10 minutes

---

## 📖 Documentation

- **Full Guide:** [BRANDING_ARCHITECTURE.md](BRANDING_ARCHITECTURE.md)
- **Summary:** [BRANDING_SUMMARY.md](BRANDING_SUMMARY.md)
- **This Card:** Keep open while coding!

---

## 💡 Pro Tips

1. **Never hardcode brand colors** - Always use `AppBrand.current.*`
2. **Use context extensions** - `context.colors.primary` is cleaner
3. **Keep category colors separate** - They're functional, not branding
4. **Use AppTokens for UI constants** - Spacing, typography, etc.
5. **Test with multiple brands** - Create test brand to verify architecture

---

## 🎯 Benefits Achieved

✅ **Single source of truth** - 1 line to change for rebrand  
✅ **Clean separation** - Brand vs functional UI  
✅ **Type-safe** - No magic strings  
✅ **Fast rebranding** - < 10 minutes per brand  
✅ **Maintainable** - Clear architecture  
✅ **Documented** - Comprehensive guides  

---

**Remember:** To rebrand, just change `AppBrand.current` and rebuild! 🚀

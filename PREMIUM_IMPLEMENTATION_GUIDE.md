# Premium/Freemium Implementation - Configuration Guide

## Overview

Successfully implemented a clean freemium + premium unlock flow with:
- ✅ 3 active items free
- ✅ One-time lifetime purchase for unlimited items
- ✅ No account system, no backend
- ✅ Offline-first architecture
- ✅ Premium survives reinstalls via store restore
- ✅ No forced online validation on app start

## Files Created

### 1. Premium Core
- `lib/features/premium/premium_exception.dart` - FreemiumLimitReachedException
- `lib/features/premium/premium_service.dart` - Main premium service
- `lib/features/premium/upgrade_dialog.dart` - Upgrade UI dialog

### 2. Localization
- Added 30+ premium strings to `lib/l10n/app_en.arb`
- Added German translations to `lib/l10n/app_de.arb`

## Files Modified

### 1. Core Infrastructure
- `pubspec.yaml` - Added `in_app_purchase: ^3.2.0`
- `lib/core/prefs.dart` - Added premium preferences (unlocked, source, last_checked_at)
- `lib/main.dart` - Added premium service initialization

### 2. Data Layer
- `lib/features/items/items_repository.dart`
  - Added `countActiveItems()` - counts items with deleted_at IS NULL
  - Added `checkCanCreateItem()` - throws FreemiumLimitReachedException if limit reached
  - Modified `upsert()` - checks limit before creating new items

### 3. UI Layer
- `lib/features/items/item_edit_screen.dart` - Catches FreemiumLimitReachedException, shows upgrade dialog
- `lib/features/items/multi_item_receipt_screen.dart` - Same freemium handling for batch create
- `lib/features/settings/settings_screen.dart` - Added premium status card with Upgrade/Restore buttons

## Configuration Required

### Step 1: Set Your Product ID

Open `lib/features/premium/premium_service.dart` and update:

```dart
// Product ID - CONFIGURE THIS FOR YOUR APP STORE
static const String productId = 'lifetime_unlock';  // ← Change this!
```

### Step 2: Configure in App Stores

#### For Android (Google Play Console):
1. Go to Google Play Console > Your App > Monetization > In-app products
2. Create new product:
   - **Product ID**: Must match `productId` in code (e.g., `lifetime_unlock`)
   - **Type**: Non-consumable
   - **Title**: "Premium Lifetime Unlock" (or your choice)
   - **Description**: "Unlock unlimited items with one-time payment"
   - **Price**: Set your price (e.g., $4.99)
3. Activate the product

#### For iOS (App Store Connect):
1. Go to App Store Connect > Your App > In-App Purchases
2. Create new in-app purchase:
   - **Type**: Non-Consumable
   - **Reference Name**: "Premium Lifetime Unlock"
   - **Product ID**: Must match `productId` in code (e.g., `lifetime_unlock`)
   - **Price**: Set your price tier
3. Submit for review with next app version

### Step 3: Testing

#### Debug Mode Bypass (Optional)
For easier development testing, uncomment this line in `premium_service.dart`:

```dart
Future<bool> isPremium() async {
  // Debug bypass for development
  if (kDebugMode) {
    return true;  // ← Uncomment this line for testing
  }
  // ...
}
```

**Important**: Comment it back out before release builds!

#### Manual Debug Unlock
Or use the debug methods (debug builds only):
```dart
// Unlock premium manually in debug
await PremiumService.instance.debugUnlock();

// Reset to free tier
await PremiumService.instance.debugReset();
```

## How It Works

### App Startup Flow
1. `main.dart` calls `PremiumService.instance.init()`
2. Service checks local premium flag (`premium_unlocked`)
3. If already true → User stays premium (no internet needed)
4. If false → Silent restore attempt in background (non-blocking)
5. App continues normally regardless of store connection

### Item Creation Flow
1. User creates new item → `ItemsRepository.upsert()` called
2. If new item (id == 0):
   - Calls `checkCanCreateItem()`
   - Counts active items (deleted_at IS NULL)
   - If count >= 3 AND not premium → throws `FreemiumLimitReachedException`
3. UI catches exception → shows upgrade dialog via `showUpgradeDialog()`
4. User can:
   - **Upgrade** → Opens platform purchase dialog
   - **Restore** → Restores previous purchase from store
   - **Not Now** → Dismisses dialog

### Purchase Flow
1. User taps "Upgrade" → `PremiumService.buyLifetimeUnlock()`
2. Platform purchase dialog appears (Google Play / App Store)
3. Purchase completes → Stream listener in `PremiumService` receives update
4. Service sets local flag: `premium_unlocked = true`
5. User can now create unlimited items

### Restore Flow
1. User taps "Restore Purchases" → `PremiumService.restorePurchases()`
2. Queries store for previous purchases
3. If found → Sets `premium_unlocked = true`
4. If not found → Shows friendly message

### Offline Behavior
- **Premium users**: Continue to work offline indefinitely
- **Free users**: Can use existing items offline, limit enforced locally
- **After reinstall**: Silent restore on next online connection
- **No scary errors**: App never blocks on store connection failures

## Premium State Storage

Stored in SharedPreferences via `Prefs` class:
```dart
premium_unlocked: bool          // True if premium
premium_unlock_source: string   // "purchase", "restore", or "debug"  
premium_last_checked_at: int    // Timestamp of last store check
```

## UI Components

### Settings Screen Premium Card
Shows:
- **Free tier**: Status, Upgrade button, Restore button
- **Premium**: Status, unlock source (purchase/restore)

### Upgrade Dialog
Shows when limit reached:
- Explanation of free tier limit (3 items)
- Premium benefits:
  - Unlimited items
  - One-time payment
  - No subscriptions
  - Works offline
- Price (fetched from store)
- Buttons: Upgrade / Restore / Not Now

## Edge Cases Handled

✅ **App offline**: Premium continues to work, store restore skipped gracefully  
✅ **Reinstall**: Silent restore recovers premium on next launch  
✅ **Delete item after hitting limit**: Can create new item (count decreases)  
✅ **Soft-deleted items**: Don't count toward limit (deleted_at IS NOT NULL)  
✅ **Purchase pending**: Completed automatically when finalized  
✅ **Purchase canceled**: User returns to free tier  
✅ **Purchase failed**: Shows error message, app continues  
✅ **Restore with no purchase**: Shows friendly "no purchase found" message  
✅ **Multiple devices**: Each device restores independently from store  

## Security Notes

This is an **offline-first, trust-based** implementation optimized for:
- ✅ Reliability
- ✅ User experience
- ✅ Offline functionality
- ✅ Low complexity

It is **NOT** optimized for:
- ❌ Maximum anti-tamper security
- ❌ Server-side receipt validation
- ❌ Preventing determined attackers

**Acceptable for**: Most indie/small apps where user trust > paranoid validation  
**Not ideal for**: Apps with very high-value monetization requiring server validation

## Testing Checklist

Before release:

- [ ] Set correct `productId` in `premium_service.dart`
- [ ] Create matching product in Google Play Console (Android)
- [ ] Create matching product in App Store Connect (iOS)
- [ ] Test purchase flow on real device with test account
- [ ] Test restore flow on second device
- [ ] Test offline premium persistence
- [ ] Test item limit enforcement (create 4th item as free user)
- [ ] Verify upgrade dialog appears correctly
- [ ] Comment out debug bypass in `isPremium()`
- [ ] Test that deleted items don't count toward limit

## Known Limitations

1. **Product configuration required**: You must set up the IAP product in both stores
2. **No server validation**: Premium status stored locally (trust-based)
3. **No family sharing**: Each device needs separate purchase/restore
4. **No cross-platform**: Android/iOS purchases don't sync (store limitation)

## Support

If users report premium not working after reinstall:
1. Check internet connection
2. Ensure same store account used for purchase
3. Tap "Restore Purchases" in Settings
4. Check store purchase history to confirm purchase exists

## Debug Commands

For development/testing only (won't work in release builds):

```dart
// Check current status
final isPremium = await PremiumService.instance.isPremium();
print('Premium: $isPremium');

// Manually unlock
await PremiumService.instance.debugUnlock();

// Reset to free
await PremiumService.instance.debugReset();
```

// lib/features/premium/premium_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:garantie_safe/core/prefs.dart';

/// Service for managing premium/freemium state
///
/// Free tier: 3 active items (deleted_at IS NULL)
/// Premium: One-time non-consumable purchase for unlimited items
///
/// Architecture:
/// - Offline-first: Local premium flag is trusted
/// - No forced online validation on app start
/// - Silent background restore if local flag is false
/// - Premium continues to work offline once unlocked
class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _initialized = false;

  // Product ID - CONFIGURE THIS FOR YOUR APP STORE
  // For Android: Set in Google Play Console
  // For iOS: Set in App Store Connect
  static const String productId = 'lifetime_unlock';

  // Free tier limit
  static const int maxFreeItems = 3;

  /// Initialize premium service
  /// Called on app startup
  /// - Restores from local flag if already premium
  /// - Silently tries store restore in background if not premium
  Future<void> init() async {
    if (_initialized) return;

    // Platform-specific initialization
    if (Platform.isAndroid) {
      // Enable pending purchases on Android - not needed for newer versions
      // The in_app_purchase package handles this automatically
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        debugPrint('Premium: Purchase stream error: $error');
      },
    );

    // Check if already premium from local flag
    final isPremiumLocal = await isPremium();
    if (isPremiumLocal) {
      debugPrint('Premium: Already premium (local flag)');
      _initialized = true;
      return;
    }

    // Not premium locally - try silent restore in background
    // This doesn't block app startup
    _trySilentRestoreInBackground();

    _initialized = true;
  }

  /// Dispose and clean up
  void dispose() {
    _subscription?.cancel();
  }

  /// Check if user has premium
  /// Returns true if premium is unlocked via purchase, restore, or debug override
  /// This is the source of truth for premium status
  ///
  /// Priority:
  /// 1. Debug override (if explicitly enabled in debug builds)
  /// 2. Real premium state from purchases (for both debug and release)
  Future<bool> isPremium() async {
    // Check for explicit debug override first (only in debug mode)
    if (kDebugMode) {
      final debugOverride = await Prefs.getDebugPremiumOverride();
      if (debugOverride != null) {
        return debugOverride; // Manual debug override takes precedence
      }
    }

    // Use real premium state (works in both debug and release)
    return await Prefs.getPremiumUnlocked();
  }

  /// Get current premium unlock source
  Future<String?> getPremiumSource() async {
    return await Prefs.getPremiumUnlockSource();
  }

  /// Get when premium was last verified with store
  Future<int?> getPremiumLastCheckedAt() async {
    return await Prefs.getPremiumLastCheckedAt();
  }

  /// Buy lifetime unlock
  /// Shows platform purchase dialog and waits for purchase completion
  /// Returns true if purchase initiated successfully, false otherwise
  Future<bool> buyLifetimeUnlock() async {
    try {
      debugPrint('Premium: Starting purchase flow...');

      // Check if store is available
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('Premium: Store not available');
        return false;
      }

      // Query product details
      final ProductDetailsResponse response =
          await _iap.queryProductDetails({productId});

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Premium: Product not found: $productId');
        return false;
      }

      if (response.productDetails.isEmpty) {
        debugPrint('Premium: No product details');
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      debugPrint('Premium: Initiating purchase...');

      // Capture state before purchase
      final wasPremiumBefore = await isPremium();

      // Buy non-consumable product
      final bool success =
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        debugPrint('Premium: Purchase initiation failed');
        return false;
      }

      debugPrint('Premium: Purchase initiated, waiting for completion...');

      // Poll for purchase completion (max 10 seconds)
      const maxAttempts = 20; // 20 × 500ms = 10 seconds
      const pollInterval = Duration(milliseconds: 500);

      for (int i = 0; i < maxAttempts; i++) {
        await Future.delayed(pollInterval);

        final isPremiumNow = await isPremium();

        // Purchase completed successfully
        if (!wasPremiumBefore && isPremiumNow) {
          debugPrint(
              'Premium: Purchase completed (detected after ${(i + 1) * 500}ms)');
          return true;
        }
      }

      debugPrint(
          'Premium: Purchase polling timeout (waiting for purchase stream)');
      return true; // Purchase initiated, stream will handle completion
    } catch (e) {
      debugPrint('Premium: Purchase error: $e');
      return false;
    }
  }

  /// Restore purchases from store
  /// Uses a bounded polling approach with timeout to detect purchase restoration
  /// Returns true if premium was successfully restored, false otherwise
  Future<bool> restorePurchases() async {
    try {
      debugPrint('Premium: Starting restore purchases...');

      // Check if store is available
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('Premium: Store not available for restore');
        return false;
      }

      // Capture initial premium state
      final wasPremiumBefore = await isPremium();
      debugPrint('Premium: Pre-restore state: premium=$wasPremiumBefore');

      // Initiate restore
      debugPrint('Premium: Initiating restore...');
      await _iap.restorePurchases();

      // Poll for premium state change with timeout
      // Check every 500ms for up to 10 seconds
      const maxAttempts = 20; // 20 * 500ms = 10 seconds
      const pollInterval = Duration(milliseconds: 500);

      debugPrint('Premium: Polling for restore completion...');
      for (int i = 0; i < maxAttempts; i++) {
        await Future.delayed(pollInterval);

        final isPremiumNow = await isPremium();

        // If premium state changed from false to true, restore succeeded
        if (!wasPremiumBefore && isPremiumNow) {
          debugPrint(
              'Premium: Restore successful (detected after ${(i + 1) * 500}ms)');
          return true;
        }

        // If already was premium, check if we're still premium
        if (wasPremiumBefore && isPremiumNow) {
          debugPrint(
              'Premium: Already premium (verified after ${(i + 1) * 500}ms)');
          return true;
        }
      }

      // Timeout reached - check final state
      final finalPremiumState = await isPremium();
      debugPrint(
          'Premium: Restore timeout reached, final state: $finalPremiumState');

      if (!finalPremiumState) {
        debugPrint('Premium: No previous purchase found after timeout');
      }

      return finalPremiumState;
    } catch (e) {
      debugPrint('Premium: Restore error: $e');
      return false;
    }
  }

  /// Try silent restore in background
  /// Called on app start if not premium
  /// Does not block UI or show errors
  Future<void> _trySilentRestoreInBackground() async {
    try {
      // Check if we recently tried restore (within 24h)
      final lastChecked = await Prefs.getPremiumLastCheckedAt();
      if (lastChecked != null) {
        final lastCheckedTime =
            DateTime.fromMillisecondsSinceEpoch(lastChecked);
        final timeSinceCheck = DateTime.now().difference(lastCheckedTime);
        if (timeSinceCheck.inHours < 24) {
          debugPrint(
              'Premium: Skipping silent restore (checked ${timeSinceCheck.inHours}h ago)');
          return;
        }
      }

      debugPrint('Premium: Attempting silent restore...');

      // Try restore without throwing errors
      await _iap.restorePurchases();

      // Update last checked time
      await Prefs.setPremiumLastCheckedAt(
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Premium: Silent restore failed (OK, app continues): $e');
      // Don't throw - app should continue normally
    }
  }

  /// Handle purchase updates from stream
  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('Premium: Purchase update: ${purchaseDetails.status}');

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify it's our product
        if (purchaseDetails.productID == productId) {
          // Successfully purchased or restored!
          await _unlockPremium(
            source: purchaseDetails.status == PurchaseStatus.purchased
                ? 'purchase'
                : 'restore',
          );
          debugPrint('Premium: Unlocked via ${purchaseDetails.status}');
        }
      }

      // Complete pending purchases
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
        debugPrint('Premium: Completed pending purchase');
      }
    }
  }

  /// Unlock premium locally
  Future<void> _unlockPremium({required String source}) async {
    await Prefs.setPremiumUnlocked(true);
    await Prefs.setPremiumUnlockSource(source);
    await Prefs.setPremiumLastCheckedAt(DateTime.now().millisecondsSinceEpoch);
    debugPrint('Premium: Premium unlocked (source: $source)');
  }

  /// Get product details for display
  Future<ProductDetails?> getProductDetails() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return null;

      final ProductDetailsResponse response =
          await _iap.queryProductDetails({productId});

      if (response.productDetails.isEmpty) return null;

      return response.productDetails.first;
    } catch (e) {
      debugPrint('Premium: Error getting product details: $e');
      return null;
    }
  }

  /// Debug: Manually unlock premium (debug builds only)
  /// Sets both the debug override flag and the real premium flag
  Future<void> debugUnlock() async {
    if (!kDebugMode) {
      throw StateError('Debug unlock only available in debug mode');
    }
    await Prefs.setDebugPremiumOverride(true);
    await _unlockPremium(source: 'debug');
    debugPrint('Premium: Debug unlocked (override + real flag)');
  }

  /// Debug: Reset premium status (debug builds only)
  /// Clears both the debug override flag and the real premium flag
  Future<void> debugReset() async {
    if (!kDebugMode) {
      throw StateError('Debug reset only available in debug mode');
    }
    await Prefs.setDebugPremiumOverride(false);
    await Prefs.setPremiumUnlocked(false);
    await Prefs.setPremiumUnlockSource(null);
    await Prefs.setPremiumLastCheckedAt(null);
    debugPrint('Premium: Reset to free tier (debug override cleared)');
  }
}

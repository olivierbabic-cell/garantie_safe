import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:garantie_safe/core/db/app_db.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/features/payments/payment_method.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

/// Service for managing payment methods
class PaymentMethodService {
  PaymentMethodService._();
  static final PaymentMethodService instance = PaymentMethodService._();

  /// Built-in payment method codes with stable IDs
  /// NEVER remove codes from this list - only add new ones
  /// Removed codes should be marked as archived in the database
  static const List<String> builtInCodes = [
    // Core payment methods (most common first)
    'cash',
    'debit_card',
    'credit_card',
    'visa',
    'mastercard',
    'american_express',
    'maestro',

    // Digital wallets
    'apple_pay',
    'google_pay',
    'samsung_pay',
    'paypal',

    // Regional/specialized
    'twint',
    'klarna',
    'gift_card_voucher',
    'bank_transfer',

    // Additional options
    'venmo',
    'cash_app',
    'other',
  ];

  /// Legacy code mappings for migration
  static const Map<String, String> legacyCodeMappings = {
    'debit': 'debit_card',
    'credit': 'credit_card',
    'applepay': 'apple_pay',
    'googlepay': 'google_pay',
    'invoice': 'klarna',
    'giftcard': 'gift_card_voucher',
    'financing': 'klarna',
  };

  /// Get localized label for a payment method
  static String getLabel(BuildContext context, PaymentMethod method) {
    final t = AppLocalizations.of(context)!;

    // Custom methods use their custom label
    if (!method.isBuiltIn && method.customLabel != null) {
      return method.customLabel!;
    }

    // Built-in methods use localization
    return _getBuiltInLabel(t, method.code);
  }

  /// Get localized label for a code (for backwards compatibility)
  static String getLabelByCode(BuildContext context, String code) {
    final t = AppLocalizations.of(context)!;
    return _getBuiltInLabel(t, code);
  }

  static String _getBuiltInLabel(AppLocalizations t, String code) {
    switch (code) {
      case 'cash':
        return t.pm_cash;
      case 'debit_card':
        return t.pm_debit_card;
      case 'credit_card':
        return t.pm_credit_card;
      case 'visa':
        return t.pm_visa;
      case 'mastercard':
        return t.pm_mastercard;
      case 'american_express':
        return t.pm_american_express;
      case 'maestro':
        return t.pm_maestro;
      case 'apple_pay':
        return t.pm_apple_pay;
      case 'google_pay':
        return t.pm_google_pay;
      case 'samsung_pay':
        return t.pm_samsung_pay;
      case 'paypal':
        return t.pm_paypal;
      case 'twint':
        return t.pm_twint;
      case 'klarna':
        return t.pm_klarna;
      case 'gift_card_voucher':
        return t.pm_gift_card_voucher;
      case 'bank_transfer':
        return t.pm_bank_transfer;
      case 'venmo':
        return t.pm_venmo;
      case 'cash_app':
        return t.pm_cash_app;
      case 'other':
        return t.pm_other;

      // Legacy codes (for old data)
      case 'debit':
        return t.pm_debit_card;
      case 'credit':
        return t.pm_credit_card;
      case 'applepay':
        return t.pm_apple_pay;
      case 'googlepay':
        return t.pm_google_pay;
      case 'invoice':
        return t.pm_klarna;
      case 'giftcard':
        return t.pm_gift_card_voucher;
      case 'financing':
        return t.pm_klarna;

      default:
        // Unknown code - return as-is
        return code;
    }
  }

  /// Initialize payment methods system
  /// Called on app startup to ensure built-in methods exist
  /// Also migrates from SharedPreferences if needed
  Future<void> initialize() async {
    final db = await AppDb.instance.database;

    // Check if already initialized
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM payment_methods'),
        ) ??
        0;

    if (count == 0) {
      // First-time initialization - migrate from SharedPreferences
      await _migrateFromPrefs(db);
    } else {
      // Already initialized - just ensure new built-in methods are added
      await _ensureBuiltInMethods(db);
    }
  }

  /// Migrate from SharedPreferences to database
  Future<void> _migrateFromPrefs(Database db) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final enabledCodesFromPrefs = await Prefs.getPaymentMethods();

    // Default methods to enable on fresh install
    const defaultEnabledCodes = ['cash', 'debit_card', 'credit_card'];

    // If prefs are empty (fresh install), use defaults. Otherwise, migrate prefs.
    final isFirstInstall = enabledCodesFromPrefs.isEmpty;

    // Create all built-in methods
    for (var i = 0; i < builtInCodes.length; i++) {
      final code = builtInCodes[i];

      // Enable if:
      // 1. Fresh install and it's a default method, OR
      // 2. Migrating and it was enabled in prefs
      final isEnabled = isFirstInstall
          ? defaultEnabledCodes.contains(code)
          : (enabledCodesFromPrefs.contains(code) ||
              _isLegacyCodeEnabled(code, enabledCodesFromPrefs));

      await db.insert(
        'payment_methods',
        {
          'code': code,
          'custom_label': null,
          'is_built_in': 1,
          'is_enabled': isEnabled ? 1 : 0,
          'is_archived': 0,
          'sort_order': i,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Migrate any unknown prefs codes as custom methods
    for (final code in enabledCodesFromPrefs) {
      if (!builtInCodes.contains(code) &&
          !legacyCodeMappings.containsKey(code)) {
        await db.insert(
          'payment_methods',
          {
            'code': code,
            'custom_label':
                code, // Use code as label for migrated custom methods
            'is_built_in': 0,
            'is_enabled': 1,
            'is_archived': 0,
            'sort_order': 999,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  bool _isLegacyCodeEnabled(
      String newCode, List<String> enabledCodesFromPrefs) {
    // Check if any legacy code that maps to this new code was enabled
    for (final entry in legacyCodeMappings.entries) {
      if (entry.value == newCode && enabledCodesFromPrefs.contains(entry.key)) {
        return true;
      }
    }
    return false;
  }

  /// Ensure all built-in methods exist (for app updates that add new methods)
  Future<void> _ensureBuiltInMethods(Database db) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    for (var i = 0; i < builtInCodes.length; i++) {
      final code = builtInCodes[i];

      // Try to insert - ignore if already exists
      await db.insert(
        'payment_methods',
        {
          'code': code,
          'custom_label': null,
          'is_built_in': 1,
          'is_enabled': 0, // New methods default to disabled
          'is_archived': 0,
          'sort_order': i,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Get all payment methods (including archived)
  Future<List<PaymentMethod>> getAll() async {
    // Ensure initialized
    await initialize();

    final db = await AppDb.instance.database;
    final maps = await db.query(
      'payment_methods',
      orderBy: 'sort_order ASC, code ASC',
    );
    return maps.map((m) => PaymentMethod.fromMap(m)).toList();
  }

  /// Get enabled payment methods (not archived)
  Future<List<PaymentMethod>> getEnabled() async {
    // Ensure initialized
    await initialize();

    final db = await AppDb.instance.database;
    final maps = await db.query(
      'payment_methods',
      where: 'is_enabled = ? AND is_archived = ?',
      whereArgs: [1, 0],
      orderBy: 'sort_order ASC, code ASC',
    );
    return maps.map((m) => PaymentMethod.fromMap(m)).toList();
  }

  /// Get method by code (for displaying existing items)
  Future<PaymentMethod?> getByCode(String code) async {
    // Ensure initialized
    await initialize();

    final db = await AppDb.instance.database;
    final maps = await db.query(
      'payment_methods',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isEmpty) {
      // Code not found - create a temporary archived method for display
      return _createArchivedMethodForCode(code);
    }

    return PaymentMethod.fromMap(maps.first);
  }

  /// Create archived method for unknown code (backwards compatibility)
  Future<PaymentMethod?> _createArchivedMethodForCode(String code) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final db = await AppDb.instance.database;

    // Insert as archived custom method
    await db.insert(
      'payment_methods',
      {
        'code': code,
        'custom_label': code,
        'is_built_in': 0,
        'is_enabled': 0,
        'is_archived': 1,
        'sort_order': 999,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return getByCode(code);
  }

  /// Add custom payment method
  Future<PaymentMethod> addCustomMethod(String label) async {
    // Ensure initialized
    await initialize();

    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Payment method label cannot be empty');
    }

    // Generate code from label (lowercase, replace spaces with underscores)
    final code = trimmed.toLowerCase().replaceAll(RegExp(r'[^\w]+'), '_');

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final db = await AppDb.instance.database;

    final id = await db.insert(
      'payment_methods',
      {
        'code': code,
        'custom_label': trimmed,
        'is_built_in': 0,
        'is_enabled': 1,
        'is_archived': 0,
        'sort_order': 999,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return PaymentMethod(
      id: id,
      code: code,
      customLabel: trimmed,
      isBuiltIn: false,
      isEnabled: true,
      isArchived: false,
      sortOrder: 999,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update payment method
  Future<void> update(PaymentMethod method) async {
    final db = await AppDb.instance.database;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    await db.update(
      'payment_methods',
      {...method.toMap(), 'updated_at': now},
      where: 'id = ?',
      whereArgs: [method.id],
    );
  }

  /// Toggle enabled status
  Future<void> toggleEnabled(PaymentMethod method) async {
    await update(method.copyWith(isEnabled: !method.isEnabled));
  }

  /// Archive method (soft delete)
  Future<void> archive(PaymentMethod method) async {
    await update(method.copyWith(isArchived: true, isEnabled: false));
  }

  /// Unarchive method
  Future<void> unarchive(PaymentMethod method) async {
    await update(method.copyWith(isArchived: false));
  }

  /// Delete custom method (only if not used by any items)
  Future<bool> deleteCustomMethod(PaymentMethod method) async {
    if (method.isBuiltIn) {
      throw StateError('Cannot delete built-in payment method');
    }

    // Check if used by any items
    final db = await AppDb.instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM items WHERE payment_method_code = ?',
            [method.code],
          ),
        ) ??
        0;

    if (count > 0) {
      // Used by items - archive instead
      await archive(method);
      return false;
    }

    // Not used - safe to delete
    await db.delete(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [method.id],
    );
    return true;
  }

  /// Update custom method label
  Future<void> updateCustomLabel(PaymentMethod method, String newLabel) async {
    if (method.isBuiltIn) {
      throw StateError('Cannot update label of built-in payment method');
    }

    final trimmed = newLabel.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Payment method label cannot be empty');
    }

    await update(method.copyWith(customLabel: trimmed));
  }

  /// Reorder payment methods
  Future<void> reorder(List<PaymentMethod> methods) async {
    final db = await AppDb.instance.database;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final batch = db.batch();
    for (var i = 0; i < methods.length; i++) {
      batch.update(
        'payment_methods',
        {'sort_order': i, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [methods[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get methods for selection (enabled + currently selected archived method)
  Future<List<PaymentMethod>> getForSelection({String? currentCode}) async {
    // Ensure initialized
    await initialize();

    final enabled = await getEnabled();

    // If current code is set and not in enabled list, add it
    if (currentCode != null && currentCode.isNotEmpty) {
      final isInEnabled = enabled.any((m) => m.code == currentCode);
      if (!isInEnabled) {
        final current = await getByCode(currentCode);
        if (current != null) {
          return [current, ...enabled];
        }
      }
    }

    return enabled;
  }

  /// Normalize code (handle legacy mappings)
  String normalizeCode(String code) {
    return legacyCodeMappings[code] ?? code;
  }
}

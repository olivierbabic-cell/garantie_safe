import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  static const _dbName = 'garantie_safe.db';
  static const _dbVersion = 6;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;

    // Check if database exists and is still open
    if (existing != null && existing.isOpen) {
      return existing;
    }

    // Database was closed or doesn't exist - clear cache and reopen
    if (existing != null && !existing.isOpen) {
      debugPrint('AppDb: Cached database was closed, reopening...');
      _db = null;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createV2(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await _upgradeToV2(db);
        }
        if (oldV < 3) {
          await _upgradeToV3(db);
        }
        if (oldV < 4) {
          await _upgradeToV4(db);
        }
        if (oldV < 5) {
          await _upgradeToV5(db);
        }
        if (oldV < 6) {
          await _upgradeToV6(db);
        }
      },
    );

    // Runtime schema guard: ensure deleted_at column exists
    await _ensureSchemaCorrect(db, path);

    _db = db;
    return db;
  }

  /// Check if the database file exists and has at least one item
  /// Used for startup routing to detect OS backup restores
  static Future<bool> hasDatabaseWithData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, _dbName);
      final file = File(path);

      if (!await file.exists()) {
        return false;
      }

      // Database exists, check if it has items
      final db = await openDatabase(path, readOnly: true);
      try {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM items');
        final count = result.first['count'] as int;
        return count > 0;
      } finally {
        await db.close();
      }
    } catch (e) {
      debugPrint('Error checking database: $e');
      return false;
    }
  }

  /// Runtime schema guard to self-heal missing columns
  Future<void> _ensureSchemaCorrect(Database db, String dbPath) async {
    try {
      // Check if deleted_at column exists
      final hasDeletedAt =
          await _columnExists(db, table: 'items', column: 'deleted_at');

      if (kDebugMode) {
        print(
            'DB path: $dbPath, version: $_dbVersion, hasDeletedAt: $hasDeletedAt');
      }

      if (!hasDeletedAt) {
        if (kDebugMode) {
          print('Missing deleted_at column - self-healing database schema');
        }

        // Add missing column
        await db.execute('ALTER TABLE items ADD COLUMN deleted_at INTEGER;');

        // Add index if it doesn't exist (this will fail silently if it exists)
        try {
          await db
              .execute('CREATE INDEX idx_items_deleted ON items(deleted_at);');
        } catch (e) {
          // Index might already exist, ignore
          if (kDebugMode) {
            print('Index creation skipped (may already exist): $e');
          }
        }

        if (kDebugMode) {
          print('Schema self-heal completed successfully');
        }
      }
    } catch (e) {
      // Log but don't crash - app can still function
      if (kDebugMode) {
        print('Schema guard error (non-fatal): $e');
      }
    }
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }

  Future<void> _createV2(Database db) async {
    // Items
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        merchant TEXT,
        category_code TEXT,
        purchase_date INTEGER NOT NULL,
        expiry_date INTEGER,
        warranty_years INTEGER,
        payment_method_code TEXT,
        notes TEXT,
        ocr_raw_text TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    await db.execute('CREATE INDEX idx_items_expiry ON items(expiry_date);');
    await db
        .execute('CREATE INDEX idx_items_purchase ON items(purchase_date);');

    // Attachments (1:n)
    await db.execute('''
      CREATE TABLE item_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        type TEXT NOT NULL,
        original_name TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE
      );
    ''');

    await db
        .execute('CREATE INDEX idx_attach_item ON item_attachments(item_id);');
    await db.execute(
        'CREATE INDEX idx_attach_item_sort ON item_attachments(item_id, sort_order);');
  }

  Future<void> _upgradeToV2(Database db) async {
    // 1) attachments table erstellen (falls nicht vorhanden)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        type TEXT NOT NULL,
        original_name TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attach_item ON item_attachments(item_id);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attach_item_sort ON item_attachments(item_id, sort_order);');

    // 2) Migration: wenn alte Spalte "attachment_path" existiert, migrieren wir in item_attachments
    final hasAttachmentPath =
        await _columnExists(db, table: 'items', column: 'attachment_path');
    if (hasAttachmentPath) {
      final rows = await db.query(
        'items',
        columns: ['id', 'attachment_path', 'created_at'],
        where: 'attachment_path IS NOT NULL AND attachment_path != ""',
      );

      for (final r in rows) {
        final itemId = r['id'] as int?;
        final path = r['attachment_path'] as String?;
        if (itemId == null || path == null || path.isEmpty) continue;

        // nur migrieren wenn noch kein Attachment existiert
        final existing = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM item_attachments WHERE item_id = ?',
          [itemId],
        ));
        if ((existing ?? 0) > 0) continue;

        final createdAt = (r['created_at'] as int?) ??
            DateTime.now().toUtc().millisecondsSinceEpoch;

        await db.insert(
          'item_attachments',
          {
            'item_id': itemId,
            'path': path,
            'type': _inferType(path),
            'original_name': null,
            'sort_order': 0,
            'created_at': createdAt,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      // Wir lassen die alte Spalte in SQLite drin (DROP COLUMN ist je nach SQLite-Version tricky).
      // Unser Code nutzt sie ab V2 nicht mehr -> stabil.
    }
  }

  Future<void> _upgradeToV3(Database db) async {
    // Add warranty_years column if it doesn't exist
    final hasWarrantyYears =
        await _columnExists(db, table: 'items', column: 'warranty_years');
    if (!hasWarrantyYears) {
      await db.execute('ALTER TABLE items ADD COLUMN warranty_years INTEGER;');
    }
  }

  Future<void> _upgradeToV4(Database db) async {
    // Add deleted_at column for soft delete (trash functionality)
    try {
      final hasDeletedAt =
          await _columnExists(db, table: 'items', column: 'deleted_at');
      if (!hasDeletedAt) {
        await db.execute('ALTER TABLE items ADD COLUMN deleted_at INTEGER;');
        await db
            .execute('CREATE INDEX idx_items_deleted ON items(deleted_at);');
      }
    } catch (e) {
      // Ignore duplicate column errors
      if (kDebugMode) {
        print('V4 migration error (likely duplicate column): $e');
      }
    }
  }

  Future<void> _upgradeToV5(Database db) async {
    // Add ocr_raw_text column for OCR metadata storage
    try {
      final hasOcrRawText =
          await _columnExists(db, table: 'items', column: 'ocr_raw_text');
      if (!hasOcrRawText) {
        await db.execute('ALTER TABLE items ADD COLUMN ocr_raw_text TEXT;');
      }
    } catch (e) {
      // Ignore duplicate column errors
      if (kDebugMode) {
        print('V5 migration error (likely duplicate column): $e');
      }
    }
  }

  Future<void> _upgradeToV6(Database db) async {
    // Create payment_methods table for flexible payment method management
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        custom_label TEXT,
        is_built_in INTEGER NOT NULL DEFAULT 0,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        is_archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payment_methods_code ON payment_methods(code);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payment_methods_enabled ON payment_methods(is_enabled, is_archived);');
  }

  static String _inferType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.pdf')) return 'pdf';
    if (p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp')) {
      return 'image';
    }
    return 'other';
  }

  Future<bool> _columnExists(Database db,
      {required String table, required String column}) async {
    final info = await db.rawQuery('PRAGMA table_info($table);');
    for (final row in info) {
      if ((row['name'] as String?) == column) return true;
    }
    return false;
  }

  /// Clear cached database instance - called by DatabaseManager when closing
  void clearCache() {
    debugPrint('AppDb: Clearing cached database instance');
    _db = null;
  }
}

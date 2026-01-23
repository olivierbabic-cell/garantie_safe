import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  static const _dbName = 'garantie_safe.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

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
      },
    );

    _db = db;
    return db;
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
}

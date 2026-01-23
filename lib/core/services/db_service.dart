import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../entities/warranty_item.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  static const _dbName = 'garantiesafe.db';

  // Wichtig: Version hochsetzen, damit onUpgrade läuft
  static const _dbVersion = 6;

  static const _table = 'items';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final file = p.join(dbPath, _dbName);

    return openDatabase(
      file,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migrationen ohne DROP TABLE
        await _ensureColumns(db);
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await _ensureColumns(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        merchant TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        expiry_date TEXT,
        payment_method TEXT,
        attachment_path TEXT,
        attachment_type TEXT,
        notes TEXT,
        category TEXT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_table}_purchase ON $_table(purchase_date);',
    );
  }

  Future<void> _ensureColumns(Database db) async {
    final cols = await _getColumnNames(db, _table);

    Future<void> addCol(String name, String type) async {
      if (!cols.contains(name)) {
        await db.execute('ALTER TABLE $_table ADD COLUMN $name $type;');
      }
    }

    await addCol('category', 'TEXT');
    await addCol('attachment_path', 'TEXT');
    await addCol('attachment_type', 'TEXT');
    await addCol('payment_method', 'TEXT');
    await addCol('notes', 'TEXT');
    await addCol('expiry_date', 'TEXT');
  }

  Future<Set<String>> _getColumnNames(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table);');
    return rows.map((r) => (r['name'] as String).toLowerCase()).toSet();
  }

  // CRUD

  Future<int> insertItem(WarrantyItem item) async {
    final db = await database;
    return db.insert(
      _table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateItem(int id, WarrantyItem item) async {
    final db = await database;
    return db.update(
      _table,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WarrantyItem>> getAllItems() async {
    final db = await database;
    final rows = await db.query(
      _table,
      orderBy: 'purchase_date DESC, id DESC',
    );
    return rows.map(WarrantyItem.fromMap).toList();
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }
}

// lib/features/items/items_db.dart
import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ItemsDb {
  static const String dbName = 'garantie_safe.db';
  static const int schemaVersion = 2;

  static final ItemsDb instance = ItemsDb._();
  ItemsDb._();

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, dbName);

    final opened = await openDatabase(
      dbPath,
      version: schemaVersion,
      onCreate: (d, _) async {
        await _createBase(d);
      },
      onUpgrade: (d, from, to) async {
        // Wir verlassen uns nicht blind auf Upgrade-Paths,
        // sondern sichern alles über ensureSchema ab.
        // Trotzdem: falls du später echte Migrationen brauchst,
        // kannst du sie hier ergänzen.
        await _upgrade(d, from, to);
      },
    );

    // Wichtig: Selbstheilung für bestehende DBs (alte Spalten fehlen etc.)
    await _ensureSchema(opened);

    _db = opened;
    return opened;
  }

  /// Erstellt eine minimal funktionsfähige items Tabelle.
  /// Danach ergänzt ensureSchema alles fehlende.
  Future<void> _createBase(Database d) async {
    await d.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL
      );
    ''');
  }

  Future<void> _upgrade(Database d, int from, int to) async {
    // absichtlich leer/leichtgewichtig – ensureSchema übernimmt.
  }

  Future<void> _ensureSchema(Database d) async {
    // Tabelle muss existieren (safety)
    await _createBase(d);

    final cols = await d.rawQuery("PRAGMA table_info('items')");
    final names = cols.map((e) => (e['name'] as String)).toSet();

    Future<void> addIfMissing(String name, String sqlTypeAndDefault) async {
      if (names.contains(name)) return;
      await d.execute("ALTER TABLE items ADD COLUMN $name $sqlTypeAndDefault;");
      names.add(name);
    }

    // === Columns für dein neues Model/Repo ===
    await addIfMissing("vault_id", "TEXT NOT NULL DEFAULT 'personal'");
    await addIfMissing("merchant", "TEXT");
    await addIfMissing("purchase_date_ms", "INTEGER");
    await addIfMissing("expiry_date_ms", "INTEGER");
    await addIfMissing("warranty_years", "INTEGER");
    await addIfMissing("category_code", "TEXT");
    await addIfMissing("payment_method_code", "TEXT");
    await addIfMissing("notes", "TEXT");
    await addIfMissing("attachment_path", "TEXT");
    await addIfMissing("attachment_type", "TEXT");
    await addIfMissing("created_at_ms", "INTEGER NOT NULL DEFAULT 0");
    await addIfMissing("updated_at_ms", "INTEGER NOT NULL DEFAULT 0");

    // === Indexes (safe create) ===
    await _createIndexSafe(
      d,
      "idx_items_vault_updated",
      "CREATE INDEX idx_items_vault_updated ON items (vault_id, updated_at_ms DESC);",
    );
    await _createIndexSafe(
      d,
      "idx_items_expiry",
      "CREATE INDEX idx_items_expiry ON items (expiry_date_ms);",
    );

    // Falls alte Datensätze created/updated auf 0 haben, initialisieren wir updated_at_ms,
    // damit die Sortierung nicht komisch ist.
    await _backfillTimestampsIfNeeded(d);
  }

  Future<void> _createIndexSafe(Database d, String name, String sql) async {
    try {
      await d.execute(sql);
    } catch (_) {
      // index exists -> ignore
    }
  }

  Future<void> _backfillTimestampsIfNeeded(Database d) async {
    try {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      // Setze updated_at_ms = now, wenn 0 oder NULL
      await d.execute('''
        UPDATE items
        SET updated_at_ms = ?
        WHERE updated_at_ms IS NULL OR updated_at_ms = 0
      ''', [now]);

      // Setze created_at_ms = updated_at_ms (oder now), wenn 0 oder NULL
      await d.execute('''
        UPDATE items
        SET created_at_ms = COALESCE(NULLIF(created_at_ms, 0), updated_at_ms, ?)
        WHERE created_at_ms IS NULL OR created_at_ms = 0
      ''', [now]);
    } catch (_) {
      // ignore
    }
  }
}

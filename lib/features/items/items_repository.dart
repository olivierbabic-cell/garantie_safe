import 'package:sqflite/sqflite.dart';

import 'item.dart';
import 'items_db.dart';

class ItemsRepository {
  final ItemsDb _db;

  ItemsRepository(this._db);

  Future<List<Item>> listItems({
    String vaultId = 'personal',
    int limit = 500,
  }) async {
    final d = await _db.db;
    final rows = await d.query(
      'items',
      where: 'vault_id = ?',
      whereArgs: [vaultId],
      orderBy: 'updated_at_ms DESC',
      limit: limit,
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<Item?> getById(String id) async {
    final d = await _db.db;
    final rows =
        await d.query('items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Item.fromMap(rows.first);
  }

  Future<void> upsert(Item item) async {
    final d = await _db.db;
    await d.insert(
      'items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteById(String id) async {
    final d = await _db.db;
    await d.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAttachment(String id, {int? updatedAtMs}) async {
    final d = await _db.db;
    final now = updatedAtMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    await d.update(
      'items',
      {
        'attachment_path': null,
        'attachment_type': null,
        'updated_at_ms': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

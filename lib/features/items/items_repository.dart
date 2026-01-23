import 'package:sqflite/sqflite.dart';

import '../../core/db/app_db.dart';
import 'item.dart';

class ItemsRepository {
  Future<Database> get _db async => AppDb.instance.database;

  Future<List<Item>> listItems({
    int limit = 500,
  }) async {
    final d = await _db;
    final rows = await d.query(
      'items',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<Item?> getById(int id) async {
    final d = await _db;
    final rows =
        await d.query('items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Item.fromMap(rows.first);
  }

  Future<int> upsert(Item item) async {
    final d = await _db;
    if (item.id == 0) {
      // New item - insert without id (AUTOINCREMENT)
      final map = item.toMap();
      map.remove('id');
      return await d.insert('items', map);
    } else {
      // Update existing
      await d.update(
        'items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      return item.id;
    }
  }

  Future<void> deleteById(int id) async {
    final d = await _db;
    await d.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}

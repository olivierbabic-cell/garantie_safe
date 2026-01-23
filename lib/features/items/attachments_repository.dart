import 'package:sqflite/sqflite.dart';

import '../../core/db/app_db.dart';
import 'item_attachment.dart';

class AttachmentsRepository {
  AttachmentsRepository({AppDb? db}) : _db = db ?? AppDb.instance;
  final AppDb _db;

  Future<List<ItemAttachment>> forItem(int itemId) async {
    final Database db = await _db.database;
    final rows = await db.query(
      ItemAttachment.table,
      where: '${ItemAttachment.cItemId} = ?',
      whereArgs: [itemId],
      orderBy: '${ItemAttachment.cSortOrder} ASC, ${ItemAttachment.cId} ASC',
    );
    return rows.map(ItemAttachment.fromMap).toList();
  }

  Future<ItemAttachment> add(ItemAttachment a) async {
    final Database db = await _db.database;

    final id = await db.insert(
      ItemAttachment.table,
      a.toMap()..remove(ItemAttachment.cId),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return ItemAttachment(
      id: id,
      itemId: a.itemId,
      path: a.path,
      type: a.type,
      originalName: a.originalName,
      sortOrder: a.sortOrder,
      createdAt: a.createdAt,
    );
  }

  Future<void> deleteById(int id) async {
    final Database db = await _db.database;
    await db.delete(
      ItemAttachment.table,
      where: '${ItemAttachment.cId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllForItem(int itemId) async {
    final Database db = await _db.database;
    await db.delete(
      ItemAttachment.table,
      where: '${ItemAttachment.cItemId} = ?',
      whereArgs: [itemId],
    );
  }
}

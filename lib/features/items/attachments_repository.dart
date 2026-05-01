import 'package:sqflite/sqflite.dart';

import '../../core/db/database_manager.dart';
import '../../core/backup_service.dart';
import 'item_attachment.dart';

class AttachmentsRepository {
  final DatabaseManager _dbManager;

  AttachmentsRepository({DatabaseManager? dbManager})
      : _dbManager = dbManager ?? DatabaseManager.instance;

  Future<Database> get _db async => _dbManager.getDatabase();

  Future<List<ItemAttachment>> forItem(int itemId) async {
    final db = await _db;
    final rows = await db.query(
      ItemAttachment.table,
      where: '${ItemAttachment.cItemId} = ?',
      whereArgs: [itemId],
      orderBy: '${ItemAttachment.cSortOrder} ASC, ${ItemAttachment.cId} ASC',
    );
    return rows.map(ItemAttachment.fromMap).toList();
  }

  Future<ItemAttachment> add(ItemAttachment a) async {
    final db = await _db;

    final id = await db.insert(
      ItemAttachment.table,
      a.toMap()..remove(ItemAttachment.cId),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    await BackupService.markDataChanged(reason: 'attachment_add');
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
    final db = await _db;
    await db.delete(
      ItemAttachment.table,
      where: '${ItemAttachment.cId} = ?',
      whereArgs: [id],
    );
    await BackupService.markDataChanged(reason: 'attachment_delete');
  }

  Future<void> deleteAllForItem(int itemId) async {
    final db = await _db;
    await db.delete(
      ItemAttachment.table,
      where: '${ItemAttachment.cItemId} = ?',
      whereArgs: [itemId],
    );
    await BackupService.markDataChanged(reason: 'attachment_delete_all');
  }

  /// Check if a file path is referenced by other attachments
  /// Returns count of attachments referencing this path (excluding the given attachment ID)
  Future<int> countOtherReferences(String path,
      {int? excludeAttachmentId}) async {
    final db = await _db;

    String where = '${ItemAttachment.cPath} = ?';
    List<Object?> whereArgs = [path];

    if (excludeAttachmentId != null) {
      where += ' AND ${ItemAttachment.cId} != ?';
      whereArgs.add(excludeAttachmentId);
    }

    final result = await db.query(
      ItemAttachment.table,
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get all attachment file paths for an item
  Future<List<String>> getFilePathsForItem(int itemId) async {
    final attachments = await forItem(itemId);
    return attachments.map((a) => a.path).toList();
  }
}

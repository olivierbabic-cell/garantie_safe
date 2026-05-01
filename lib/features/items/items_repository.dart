import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/db/database_manager.dart';
import '../../core/backup_service.dart';
import '../../core/services/warranty_notification_scheduler.dart';
import '../../features/premium/premium_service.dart';
import '../../features/premium/premium_exception.dart';
import 'item.dart';

class ItemsRepository {
  final DatabaseManager _dbManager;

  ItemsRepository({DatabaseManager? dbManager})
      : _dbManager = dbManager ?? DatabaseManager.instance;

  Future<Database> get _db async => _dbManager.getDatabase();

  Future<List<Item>> listItems({
    int limit = 500,
  }) async {
    final d = await _db;
    final rows = await d.query(
      'items',
      where: 'deleted_at IS NULL',
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

  /// Count active items (not deleted)
  Future<int> countActiveItems() async {
    final d = await _db;
    final result = await d.rawQuery(
      'SELECT COUNT(*) as count FROM items WHERE deleted_at IS NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if user can create new item (freemium limit)
  /// Throws FreemiumLimitReachedException if limit reached
  Future<void> checkCanCreateItem() async {
    // Check if premium
    final isPremium = await PremiumService.instance.isPremium();
    if (isPremium) {
      return; // Premium users have no limit
    }

    // Count active items
    final activeCount = await countActiveItems();

    // Check free tier limit
    if (activeCount >= PremiumService.maxFreeItems) {
      throw FreemiumLimitReachedException(
        currentCount: activeCount,
        maxFreeItems: PremiumService.maxFreeItems,
      );
    }
  }

  Future<int> upsert(Item item) async {
    final d = await _db;
    final int result;
    final bool isNew = item.id == 0;

    if (isNew) {
      // Check freemium limit before creating new item
      await checkCanCreateItem();

      // New item - insert without id (AUTOINCREMENT)
      final map = item.toMap();
      map.remove('id');
      result = await d.insert('items', map);
    } else {
      // Update existing - cancel old notifications first to prevent duplicates
      await WarrantyNotificationScheduler.cancelForItem(item.id);

      await d.update(
        'items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      result = item.id;
    }

    // Schedule/reschedule notifications for this item
    // IMPORTANT: Only schedule for active (non-deleted) items
    final savedItem = isNew ? (await getById(result))! : item;

    try {
      if (savedItem.deletedAt == null) {
        // Active item - schedule notifications
        await WarrantyNotificationScheduler.scheduleForItem(savedItem);
      } else {
        // Deleted item - ensure no notifications exist
        await WarrantyNotificationScheduler.cancelForItem(savedItem.id);
      }
    } catch (e) {
      // Don't fail the save if notification scheduling fails
      debugPrint(
          'Warning: Failed to schedule notifications for item ${savedItem.id}: $e');
    }

    // Mark data changed for delayed backup
    await BackupService.markDataChanged(reason: 'item_save');

    return result;
  }

  Future<void> deleteById(int id) async {
    final d = await _db;
    // Soft delete: set deleted_at timestamp
    await d.update(
      'items',
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Cancel notifications when item is deleted/trashed
    await WarrantyNotificationScheduler.cancelForItem(id);

    // Mark data changed for delayed backup
    await BackupService.markDataChanged(reason: 'item_delete');
  }

  /// Get all deleted items (trash)
  Future<List<Item>> listDeletedItems({int limit = 500}) async {
    final d = await _db;
    final rows = await d.query(
      'items',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
      limit: limit,
    );
    return rows.map(Item.fromMap).toList();
  }

  /// Restore item from trash
  Future<void> restoreFromTrash(int id) async {
    final d = await _db;

    // First, cancel any existing notifications for this item
    // This ensures a clean state before rescheduling
    await WarrantyNotificationScheduler.cancelForItem(id);

    // Update the item to mark it as active (not deleted)
    await d.update(
      'items',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Reschedule notifications for the restored item
    final restoredItem = await getById(id);
    if (restoredItem != null) {
      try {
        await WarrantyNotificationScheduler.scheduleForItem(restoredItem);
      } catch (e) {
        debugPrint(
            'Warning: Failed to schedule notifications for restored item $id: $e');
      }
    }

    // Mark data changed for delayed backup
    await BackupService.markDataChanged(reason: 'item_restore');
  }

  /// Permanently delete item (hard delete)
  Future<void> permanentlyDelete(int id) async {
    final d = await _db;
    await d.delete('items', where: 'id = ?', whereArgs: [id]);

    // Cancel notifications when permanently deleted
    await WarrantyNotificationScheduler.cancelForItem(id);

    // Mark data changed for snapshot
    await BackupService.markDataChanged(reason: 'item_delete_permanent');
  }

  /// Purge old deleted items (deleted > 180 days ago)
  /// This is for automatic cleanup, not user-initiated
  Future<int> purgeOldDeletedItems() async {
    try {
      final d = await _db;
      final retentionLimit = DateTime.now()
          .subtract(const Duration(days: 180))
          .millisecondsSinceEpoch;

      // Find items to purge: deleted AND deleted_at > 180 days ago
      final rows = await d.query(
        'items',
        columns: ['id'],
        where: 'deleted_at IS NOT NULL AND deleted_at < ?',
        whereArgs: [retentionLimit],
      );

      int purgedCount = 0;
      for (final row in rows) {
        final id = row['id'] as int;
        await permanentlyDelete(id);
        purgedCount++;
      }

      return purgedCount;
    } catch (e) {
      // Log but don't crash if purge fails
      print('Purge old items error: $e');
      return 0;
    }
  }

  /// Restore all items from trash
  Future<int> restoreAllFromTrash() async {
    try {
      // Get all deleted items
      final deletedItems = await listDeletedItems(limit: 10000);

      // Restore each item
      for (final item in deletedItems) {
        await restoreFromTrash(item.id);
      }

      return deletedItems.length;
    } catch (e) {
      print('Restore all from trash error: $e');
      return 0;
    }
  }

  /// Empty trash - permanently delete all deleted items
  Future<int> emptyTrash() async {
    try {
      final d = await _db;

      // Get all deleted items
      final rows = await d.query(
        'items',
        columns: ['id'],
        where: 'deleted_at IS NOT NULL',
      );

      int deletedCount = 0;
      for (final row in rows) {
        final id = row['id'] as int;
        await permanentlyDelete(id);
        deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      print('Empty trash error: $e');
      return 0;
    }
  }
}

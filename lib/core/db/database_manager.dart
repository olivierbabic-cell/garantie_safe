import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'app_db.dart';

/// Singleton DatabaseManager - single source of truth for database lifecycle
/// Ensures database is never accessed after close and properly reopened after restore
class DatabaseManager {
  DatabaseManager._();
  static final DatabaseManager instance = DatabaseManager._();

  Database? _db;
  bool _isRestoring = false;

  /// Get the database instance - opens if null or closed
  Future<Database> getDatabase() async {
    // Wait if restore is in progress
    while (_isRestoring) {
      debugPrint('DatabaseManager: Waiting for restore to complete...');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return await _getDatabaseInternal();
  }

  /// Internal database getter without restore check - used by reopenDatabase
  Future<Database> _getDatabaseInternal() async {
    final existing = _db;

    // Check if database exists and is open
    if (existing != null && existing.isOpen) {
      return existing;
    }

    // Open new database instance
    debugPrint('DatabaseManager: Opening database...');
    _db = await AppDb.instance.database;
    debugPrint('DatabaseManager: Database opened successfully');
    return _db!;
  }

  /// Close the database and clear the cached instance
  Future<void> closeDatabase() async {
    debugPrint('DatabaseManager: Closing database...');
    final db = _db;
    _db = null;

    if (db != null && db.isOpen) {
      await db.close();
      debugPrint('DatabaseManager: Database closed');
    } else {
      debugPrint('DatabaseManager: Database was already closed or null');
    }

    // Clear AppDb cache to prevent returning closed database
    AppDb.instance.clearCache();
  }

  /// Reopen database - used after restore
  Future<void> reopenDatabase() async {
    debugPrint('DatabaseManager: Reopening database...');
    await closeDatabase();
    await _getDatabaseInternal(); // Bypass restore check
    debugPrint('DatabaseManager: Database reopened successfully');
  }

  /// Mark restore as in progress - prevents database access during restore
  void setRestoring(bool restoring) {
    _isRestoring = restoring;
    debugPrint(
        'DatabaseManager: Restore mode ${restoring ? "ENABLED" : "DISABLED"}');
  }

  /// Check if restore is in progress
  bool get isRestoring => _isRestoring;

  /// Check if database is currently open
  bool get isOpen => _db != null && _db!.isOpen;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_manager.dart';

/// Provider for DatabaseManager singleton
final databaseManagerProvider = Provider<DatabaseManager>((ref) {
  return DatabaseManager.instance;
});

/// Provider for restore state - tracks if restore is in progress
final isRestoringProvider = StateProvider<bool>((ref) => false);

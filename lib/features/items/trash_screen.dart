import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/features/items/items_repository.dart';
import 'package:garantie_safe/features/items/items_providers.dart';
import 'package:garantie_safe/features/items/item.dart';
import 'package:garantie_safe/features/items/attachments_repository.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  late Future<List<Item>> _deletedItemsFuture;
  final _itemsRepo = ItemsRepository();
  final _attachmentsRepo = AttachmentsRepository();

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  void _loadDeletedItems() {
    setState(() {
      _deletedItemsFuture = _itemsRepo.listDeletedItems();
    });
  }

  Future<void> _restoreItem(Item item) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trash_restore_confirm_title),
        content: Text(t.trash_restore_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.trash_restore),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _itemsRepo.restoreFromTrash(item.id);

      // Refresh items list so restored item appears immediately
      ref.invalidate(itemsListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.trash_restored)),
      );
      _loadDeletedItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.trash_error_display(e.toString()))),
      );
    }
  }

  Future<void> _deleteItemPermanently(Item item) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trash_delete_confirm_title),
        content: Text(t.trash_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.trash_delete_permanently),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get attachments for this item
      final attachments = await _attachmentsRepo.forItem(item.id);

      // Check which files can be safely deleted
      final filesToDelete = <String>[];
      for (final attachment in attachments) {
        final otherReferences = await _attachmentsRepo.countOtherReferences(
          attachment.path,
          excludeAttachmentId: attachment.id,
        );

        // Only delete file if no other items reference it
        if (otherReferences == 0) {
          filesToDelete.add(attachment.path);
        }
      }

      // Delete safe files from disk
      for (final filePath in filesToDelete) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted file: $filePath');
        }
      }

      // Permanently delete from database (deletes item and attachments)
      await _itemsRepo.permanentlyDelete(item.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.trash_deleted)),
      );
      _loadDeletedItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.trash_error_display(e.toString()))),
      );
    }
  }

  Future<void> _restoreAllFromTrash() async {
    final t = AppLocalizations.of(context)!;
    final items = await _deletedItemsFuture;

    if (items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trash_restore_all_title),
        content: Text(
          t.trash_restore_all_message(items.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.trash_restore),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final count = await _itemsRepo.restoreAllFromTrash();

      // Refresh items list so restored items appear immediately
      ref.invalidate(itemsListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.trash_restored_count(count))),
      );
      _loadDeletedItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.trash_error_display(e.toString()))),
      );
    }
  }

  Future<void> _emptyTrash() async {
    final t = AppLocalizations.of(context)!;
    final items = await _deletedItemsFuture;

    if (items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.trash_empty_title),
        content: Text(
          t.trash_empty_message(items.length),
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.trash_empty_button),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Collect all file paths referenced by trash items
      final allFilePaths = <String>{};
      for (final item in items) {
        final attachments = await _attachmentsRepo.forItem(item.id);
        allFilePaths.addAll(attachments.map((a) => a.path));
      }

      // Check which files can be safely deleted
      final filesToDelete = <String>[];
      for (final filePath in allFilePaths) {
        final otherReferences = await _attachmentsRepo.countOtherReferences(
          filePath,
        );

        // Only delete file if no other items reference it
        if (otherReferences == 0) {
          filesToDelete.add(filePath);
        }
      }

      // Delete safe files from disk
      for (final filePath in filesToDelete) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted file: $filePath');
        }
      }

      final count = await _itemsRepo.emptyTrash();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.trash_deleted_count(count))),
      );
      _loadDeletedItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.trash_title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'restore_all') {
                _restoreAllFromTrash();
              } else if (value == 'empty_trash') {
                _emptyTrash();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'restore_all',
                child: Row(
                  children: [
                    const Icon(Icons.restore),
                    const SizedBox(width: 8),
                    Text(t.trash_restore_all),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'empty_trash',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      t.trash_empty_button,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _deletedItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text(t.trash_error_display(snapshot.error.toString())));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.trash_empty,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.trash_items_kept_info,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info notice at top
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.trash_auto_delete_info,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Items list
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onErrorContainer,
                          child: const Icon(Icons.delete_outline),
                        ),
                        title: Text(item.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.merchant != null) Text(item.merchant!),
                            Text(
                              '${t.trash_deleted_on}: ${_formatDate(item.deletedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'restore') {
                              _restoreItem(item);
                            } else if (value == 'delete') {
                              _deleteItemPermanently(item);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'restore',
                              child: Row(
                                children: [
                                  const Icon(Icons.restore),
                                  const SizedBox(width: 8),
                                  Text(t.trash_restore),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_forever,
                                      color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.trash_delete_permanently,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

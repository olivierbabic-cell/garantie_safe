// lib/features/items/item_edit_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'item.dart';
import 'items_providers.dart';
import 'item_attachment.dart';
import 'attachments_repository.dart';

final attachmentsRepositoryProvider = Provider<AttachmentsRepository>((ref) {
  return AttachmentsRepository();
});

class ItemEditScreen extends ConsumerStatefulWidget {
  const ItemEditScreen({super.key, this.itemId});

  /// IMPORTANT: In unserem neuen System ist ID ein String.
  /// In der ListScreen geben wir immer .toString() rein, daher passt das immer.
  final String? itemId;

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _purchaseDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _expiryDate;

  bool _saving = false;
  bool _initialized = false;

  // Attachments state
  int? _savedItemId; // Item ID after save (needed for attachments)
  List<ItemAttachment> _attachments = [];
  bool _loadingAttachments = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _merchantCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Item? _findExisting(List<Item> items) {
    final id = widget.itemId;
    if (id == null || id.trim().isEmpty) return null;

    final idInt = int.tryParse(id);
    if (idInt == null) return null;

    for (final it in items) {
      if (it.id == idInt) return it;
    }
    return null;
  }

  void _initOnceFromExisting(Item? existing) {
    if (_initialized) return;
    _initialized = true;

    if (existing == null) return;

    _savedItemId = existing.id;
    _titleCtrl.text = existing.title;
    _merchantCtrl.text = existing.merchant ?? '';
    _notesCtrl.text = existing.notes ?? '';

    final pMs = existing.purchaseDate;
    _purchaseDate = DateUtils.dateOnly(
      DateTime.fromMillisecondsSinceEpoch(pMs),
    );

    final eMs = existing.expiryDate;
    if (eMs != null) {
      _expiryDate = DateUtils.dateOnly(
        DateTime.fromMillisecondsSinceEpoch(eMs),
      );
    }

    // Load attachments
    _loadAttachments();
  }

  Future<void> _save(Item? existing) async {
    final t = AppLocalizations.of(context)!;
    if (_saving) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final notifier = ref.read(itemsListProvider.notifier);
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      final title = _titleCtrl.text.trim();
      final merchant =
          _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim();
      final notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      final purchaseMs =
          DateUtils.dateOnly(_purchaseDate).toUtc().millisecondsSinceEpoch;
      final expiryMs = _expiryDate == null
          ? null
          : DateUtils.dateOnly(_expiryDate!).toUtc().millisecondsSinceEpoch;

      final item = (existing == null)
          ? Item(
              id: 0, // AUTOINCREMENT will assign
              vaultId: 'personal',
              title: title,
              merchant: merchant,
              purchaseDate: purchaseMs,
              expiryDate: expiryMs,
              categoryCode: null,
              paymentMethodCode: null,
              notes: notes,
              createdAt: nowMs,
              updatedAt: nowMs,
            )
          : existing.copyWith(
              title: title,
              merchant: merchant,
              purchaseDate: purchaseMs,
              expiryDate: expiryMs,
              notes: notes,
              updatedAt: nowMs,
            );

      await notifier.upsert(item);

      // Get the item ID after save (for new items)
      if (existing == null) {
        // Refresh to get the newly created item with its ID
        await notifier.refresh();
        final items = ref.read(itemsListProvider).value ?? [];
        // Find item by title (just created)
        final newItem = items.where((i) => i.title == title).firstOrNull;
        if (newItem != null) {
          _savedItemId = newItem.id;
        }
      } else {
        _savedItemId = existing.id;
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.save_failed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadAttachments() async {
    final itemId = _savedItemId;
    if (itemId == null || itemId == 0) {
      setState(() => _attachments = []);
      return;
    }

    setState(() => _loadingAttachments = true);
    try {
      final repo = ref.read(attachmentsRepositoryProvider);
      final atts = await repo.forItem(itemId);
      if (mounted) {
        setState(() {
          _attachments = atts;
          _loadingAttachments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAttachments = false);
      }
    }
  }

  Future<void> _addAttachment() async {
    final t = AppLocalizations.of(context)!;
    final itemId = _savedItemId;

    // Item must be saved first
    if (itemId == null || itemId == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(t.save_item_first ?? 'Please save the item first')),
      );
      return;
    }

    // Show source picker
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(t.camera ?? 'Camera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(t.gallery ?? 'Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(t.pdf ?? 'PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      String? filePath;
      String? originalName;
      AttachmentType type;

      if (source == 'camera' || source == 'gallery') {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (image == null) return;
        filePath = image.path;
        originalName = p.basename(filePath);
        type = AttachmentType.image;
      } else {
        // PDF
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result == null || result.files.isEmpty) return;
        filePath = result.files.first.path;
        if (filePath == null) return;
        originalName = result.files.first.name;
        type = AttachmentType.pdf;
      }

      // Copy file to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = p.extension(filePath);
      final newFileName = '${itemId}_$timestamp$extension';
      final newPath = p.join(attachmentsDir.path, newFileName);

      await File(filePath).copy(newPath);

      // Insert into database
      final repo = ref.read(attachmentsRepositoryProvider);
      final maxOrder = _attachments.isEmpty
          ? 0
          : _attachments
              .map((a) => a.sortOrder)
              .reduce((a, b) => a > b ? a : b);

      final attachment = ItemAttachment(
        itemId: itemId,
        path: newPath,
        type: type,
        originalName: originalName,
        sortOrder: maxOrder + 1,
        createdAt: DateTime.now(),
      );

      await repo.add(attachment);
      await _loadAttachments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.attachment_added ?? 'Attachment added')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeAttachment(ItemAttachment att) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.delete_title),
        content: Text(t.delete_attachment_confirm ?? 'Delete this attachment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Delete from database
      final repo = ref.read(attachmentsRepositoryProvider);
      await repo.deleteById(att.id!);

      // Delete file
      try {
        await File(att.path).delete();
      } catch (_) {
        // Ignore file deletion errors
      }

      await _loadAttachments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.attachment_deleted ?? 'Attachment deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openAttachment(ItemAttachment att) async {
    try {
      await OpenFilex.open(att.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
  }

  Future<void> _pickPurchaseDate() async {
    final t = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: t.items_pick_purchase_date,
    );
    if (picked != null && mounted) {
      setState(() {
        _purchaseDate = DateUtils.dateOnly(picked);
        // Optional: wenn expiry vor purchase liegt -> reset
        if (_expiryDate != null && _expiryDate!.isBefore(_purchaseDate)) {
          _expiryDate = null;
        }
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final t = AppLocalizations.of(context)!;
    final initial = _expiryDate ?? _purchaseDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _purchaseDate,
      lastDate: DateTime(2100),
      helpText: t.items_pick_expiry_date,
    );
    if (picked != null && mounted) {
      setState(() => _expiryDate = DateUtils.dateOnly(picked));
    }
  }

  void _clearExpiry() {
    setState(() => _expiryDate = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(itemsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? t.items_add : t.items_edit),
      ),
      body: SafeArea(
        child: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (items) {
            final existing = _findExisting(items);
            _initOnceFromExisting(existing);

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(labelText: t.items_name),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? t.field_required
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _merchantCtrl,
                    decoration: InputDecoration(labelText: t.items_merchant),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.items_purchase),
                    subtitle: Text(_fmt(_purchaseDate)),
                    trailing: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: _pickPurchaseDate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.items_expiry),
                    subtitle: Text(
                        _expiryDate == null ? t.not_set : _fmt(_expiryDate!)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_expiryDate != null)
                          IconButton(
                            tooltip: t.remove,
                            icon: const Icon(Icons.close),
                            onPressed: _clearExpiry,
                          ),
                        IconButton(
                          icon: const Icon(Icons.date_range),
                          onPressed: _pickExpiryDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: InputDecoration(labelText: t.item_notes),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Attachments section
                  _buildAttachmentsSection(t),

                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _save(existing),
                    icon: const Icon(Icons.check),
                    label: Text(t.save),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(AppLocalizations t) {
    final hasItem = _savedItemId != null && _savedItemId != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.attachments ?? 'Attachments',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (hasItem)
              TextButton.icon(
                onPressed: _addAttachment,
                icon: const Icon(Icons.add),
                label: Text(t.add ?? 'Add'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasItem)
          Text(
            t.save_item_first ?? 'Save the item first to add attachments',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          )
        else if (_loadingAttachments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_attachments.isEmpty)
          Text(
            t.no_attachments ?? 'No attachments yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          )
        else
          ..._attachments.map((att) => _buildAttachmentTile(att, t)),
      ],
    );
  }

  Widget _buildAttachmentTile(ItemAttachment att, AppLocalizations t) {
    IconData icon;
    switch (att.type) {
      case AttachmentType.image:
        icon = Icons.image;
        break;
      case AttachmentType.pdf:
        icon = Icons.picture_as_pdf;
        break;
      case AttachmentType.other:
        icon = Icons.insert_drive_file;
        break;
    }

    final displayName = att.originalName ?? p.basename(att.path);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_formatAttachmentType(att.type)),
        onTap: () => _openAttachment(att),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _removeAttachment(att),
          tooltip: t.delete,
        ),
      ),
    );
  }

  String _formatAttachmentType(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return 'Image';
      case AttachmentType.pdf:
        return 'PDF';
      case AttachmentType.other:
        return 'File';
    }
  }

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd.$mm.$yyyy';
  }
}

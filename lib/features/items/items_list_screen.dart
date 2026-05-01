// lib/features/items/items_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/backup_service.dart';
import 'package:garantie_safe/features/items/items_repository.dart';
import 'package:garantie_safe/features/backup/snapshot_chooser_screen.dart';
import 'package:garantie_safe/features/items/trash_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'item.dart';
import 'items_providers.dart';
import 'item_edit_screen.dart';
import '../scan_ocr/receipt_text_extraction_service.dart';
import '../scan_ocr/receipt_parser_service.dart';
import '../scan_ocr/receipt_image_quality_service.dart';
import '../scan_ocr/receipt_validation_dialogs.dart';
import 'multi_item_receipt_screen.dart';
import 'presentation/widgets/receipt_card.dart';
import 'package:garantie_safe/core/categories.dart';
import 'package:garantie_safe/core/widgets/import_source_sheet.dart';
import 'package:garantie_safe/ui/components/components.dart';
import 'package:garantie_safe/theme/app_tokens.dart';
import 'package:garantie_safe/theme/functional_colors.dart';
import 'package:garantie_safe/branding/app_brand.dart';

class ItemsListScreen extends ConsumerStatefulWidget {
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen> {
  int _filterIndex = 0; // 0 = active, 1 = soon, 2 = expired, 3 = all
  bool _showSafetyBanner = false;
  bool _checkingSafety = true;

  @override
  void initState() {
    super.initState();
    _checkForSafetyBanner();
  }

  Future<void> _checkForSafetyBanner() async {
    try {
      final itemsRepo = ItemsRepository();

      // Get active items count
      final activeItems = await itemsRepo.listItems();

      // Only show banner if no active items
      if (activeItems.isEmpty) {
        // Check for deleted items
        final deletedItems = await itemsRepo.listDeletedItems(limit: 1);
        final hasDeleted = deletedItems.isNotEmpty;

        // Check for snapshots
        final status = await BackupService.getBackupStatus();
        final hasBackups = status['hasBackup'] as bool? ?? false;

        if (mounted) {
          setState(() {
            _showSafetyBanner = hasDeleted || hasBackups;
            _checkingSafety = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _showSafetyBanner = false;
            _checkingSafety = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showSafetyBanner = false;
          _checkingSafety = false;
        });
      }
    }
  }

  /// Show unified import source picker (Photo or PDF)
  Future<void> _showAddOptions() async {
    final source = await showImportSourcePicker(context);

    if (source == null) return;

    switch (source) {
      case 'photo':
        await _importPhoto();
        break;
      case 'pdf':
        await _importPdf();
        break;
    }
  }

  /// Import photo from gallery
  Future<void> _importPhoto() async {
    final t = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    try {
      debugPrint('ItemsList: Gallery photo selected: ${pickedFile.path}');

      // Extract text from image using OCR
      final extractionResult =
          await ReceiptTextExtractionService.extractFromImage(pickedFile.path);

      debugPrint(
          'ItemsList: OCR extraction complete - ${extractionResult.lines.length} lines');

      // Parse merchant + date
      final parsedData = ReceiptParserService.parseText(
        extractionResult.rawText,
        extractionResult.lines,
      );

      debugPrint(
          'ItemsList: Parsing complete - merchant: ${parsedData.merchant}, date: ${parsedData.purchaseDate}');

      // === VALIDATE RECEIPT QUALITY ===
      debugPrint('ItemsList: Starting quality validation');
      final validation = ReceiptImageQualityService.validateReceipt(
        extractionResult: extractionResult,
        draft: parsedData,
        source: 'items_gallery',
      );

      // Handle validation result
      if (validation.isReject) {
        debugPrint('ItemsList: Quality result = REJECT - ${validation.reason}');
        debugPrint('ItemsList: Blocked by quality validation');
        // Receipt quality is too poor - show rejection dialog
        if (!mounted) return;
        await showReceiptRejectDialog(
          context: context,
          validation: validation,
          source: 'file',
          imagePath: pickedFile.path,
        );
        // User must retake - exit without processing
        return;
      } else if (validation.isWarning) {
        debugPrint(
            'ItemsList: Quality result = WARNING - ${validation.reason}');
        // Receipt quality is borderline - show warning and let user decide
        if (!mounted) return;
        final action = await showReceiptWarningDialog(
          context: context,
          validation: validation,
          source: 'file',
          imagePath: pickedFile.path,
        );

        if (action == ReceiptValidationAction.retake || action == null) {
          debugPrint('ItemsList: User chose to retake photo');
          debugPrint('ItemsList: Blocked by quality validation');
          return; // Exit without processing
        }
        debugPrint('ItemsList: User chose to use photo anyway');
        debugPrint('ItemsList: Continuing to OCR/parser after user override');
        // If user chose "use anyway", continue below
      } else {
        debugPrint('ItemsList: Quality result = ACCEPT');
        debugPrint('ItemsList: Continuing to OCR/parser');
      }

      // Validation passed or user chose to continue - copy file to attachments
      final attachmentPath = await _copyToAttachments(pickedFile.path);

      if (!mounted) return;
      await _showMultiItemChoice(parsedData, attachmentPath);

      // Refresh list
      if (mounted) {
        await ref.read(itemsListProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('ItemsList: Photo import error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scan_ocr_failed),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Import PDF document
  Future<void> _importPdf() async {
    final t = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.scan_file_access_error)),
      );
      return;
    }

    try {
      debugPrint('ItemsList: PDF selected: $filePath');

      // Extract text from PDF using OCR
      final extractionResult =
          await ReceiptTextExtractionService.extractFromPdf(filePath);

      debugPrint(
          'ItemsList: PDF extraction complete - ${extractionResult.lines.length} lines');

      // Parse merchant + date
      final parsedData = ReceiptParserService.parseText(
        extractionResult.rawText,
        extractionResult.lines,
      );

      debugPrint(
          'ItemsList: Parsing complete - merchant: ${parsedData.merchant}, date: ${parsedData.purchaseDate}');

      // === VALIDATE RECEIPT QUALITY ===
      debugPrint('ItemsList: Starting quality validation');
      final validation = ReceiptImageQualityService.validateReceipt(
        extractionResult: extractionResult,
        draft: parsedData,
        source: 'items_pdf',
      );

      // Handle validation result
      if (validation.isReject) {
        debugPrint('ItemsList: Quality result = REJECT - ${validation.reason}');
        debugPrint('ItemsList: Blocked by quality validation');
        // Receipt quality is too poor - show rejection dialog
        if (!mounted) return;
        await showReceiptRejectDialog(
          context: context,
          validation: validation,
          source: 'pdf',
          imagePath: filePath,
        );
        // User must re-select - exit without processing
        return;
      } else if (validation.isWarning) {
        debugPrint(
            'ItemsList: Quality result = WARNING - ${validation.reason}');
        // Receipt quality is borderline - show warning and let user decide
        if (!mounted) return;
        final action = await showReceiptWarningDialog(
          context: context,
          validation: validation,
          source: 'pdf',
          imagePath: null, // PDF has no image preview
        );

        if (action == ReceiptValidationAction.retake || action == null) {
          debugPrint('ItemsList: User chose to re-select PDF');
          debugPrint('ItemsList: Blocked by quality validation');
          return; // Exit without processing
        }
        debugPrint('ItemsList: User chose to use PDF anyway');
        debugPrint('ItemsList: Continuing to OCR/parser after user override');
        // If user chose "use anyway", continue below
      } else {
        debugPrint('ItemsList: Quality result = ACCEPT');
        debugPrint('ItemsList: Continuing to OCR/parser');
      }

      // Validation passed or user chose to continue - copy file to attachments
      final attachmentPath = await _copyToAttachments(filePath);

      if (!mounted) return;
      await _showMultiItemChoice(parsedData, attachmentPath);

      // Refresh list
      if (mounted) {
        await ref.read(itemsListProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('ItemsList: PDF import error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scan_ocr_failed),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Copy file to attachments directory
  Future<String> _copyToAttachments(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final extension = p.extension(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = 'scanned_$timestamp$extension';
    final targetPath = '${attachmentsDir.path}/$newFileName';

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  /// Show multi-item choice dialog
  Future<void> _showMultiItemChoice(
    ReceiptScanDraft parsedData,
    String attachmentPath,
  ) async {
    final t = AppLocalizations.of(context)!;

    // Always show choice dialog after successful receipt capture
    // User can decide whether one receipt contains one or multiple items
    // Show choice dialog
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.multi_item_choice_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.multi_item_choice_subtitle),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.inventory_2, color: Colors.white),
              ),
              title: Text(t.multi_item_create_one),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, 'single'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.inventory, color: Colors.white),
              ),
              title: Text(t.multi_item_create_multiple),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, 'multi'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (choice == 'multi') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiItemReceiptScreen(
            scannedData: parsedData,
            receiptFilePath: attachmentPath,
          ),
        ),
      );
    } else if (choice == 'single') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItemEditScreen(
            scannedData: parsedData,
            scannedFilePath: attachmentPath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(itemsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.items_title),
        actions: [
          IconButton(
            tooltip: t.settings_title,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
      body: Container(
        color: Colors.white, // Pure white background
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Safety Banner
            if (_showSafetyBanner && !_checkingSafety) ...[
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppTokens.spacing.md,
                  vertical: AppTokens.spacing.xs,
                ),
                padding: EdgeInsets.all(AppTokens.spacing.md + 2),
                decoration: BoxDecoration(
                  color: AppSemanticColors.warningLight,
                  borderRadius: BorderRadius.circular(AppTokens.radii.md),
                  border: Border.all(
                    color: AppSemanticColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppSemanticColors.warning.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppTokens.spacing.xs),
                          decoration: BoxDecoration(
                            color: AppSemanticColors.warning.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radii.sm),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: AppSemanticColors.warning,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: AppTokens.spacing.sm),
                        Expanded(
                          child: Text(
                            t.safety_no_warranties_found,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppBrand.current.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTokens.spacing.sm - 2),
                    Text(
                      'Your active warranties list is empty. You may have accidentally deleted items or need to restore from a backup.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppBrand.current.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: AppTokens.spacing.sm + 2),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon:
                                const Icon(Icons.restore_from_trash, size: 18),
                            label: Text(t.trash_restore_from_trash),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppSemanticColors.warning,
                              side: BorderSide(
                                color: AppSemanticColors.warning,
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radii.sm),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TrashScreen(),
                                ),
                              );
                              // Refresh and recheck after returning
                              await ref
                                  .read(itemsListProvider.notifier)
                                  .refresh();
                              _checkForSafetyBanner();
                            },
                          ),
                        ),
                        SizedBox(width: AppTokens.spacing.xs),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.backup, size: 18),
                            label: Text(t.backup_restore_backup_button),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppSemanticColors.warning,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radii.sm),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SnapshotChooserScreen(),
                                ),
                              );
                              // Refresh and recheck after returning
                              await ref
                                  .read(itemsListProvider.notifier)
                                  .refresh();
                              _checkForSafetyBanner();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            _FilterChips(
              index: _filterIndex,
              onChanged: (i) => setState(() => _filterIndex = i),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.read(itemsListProvider.notifier).refresh(),
                ),
                data: (items) {
                  final filtered = _applyFilter(items);
                  final shouldGroup = _shouldGroupByCategory();

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(itemsListProvider.notifier).refresh(),
                    child: filtered.isEmpty
                        ? _buildEmptyState(context, _filterIndex)
                        : shouldGroup
                            ? _GroupedItemsList(
                                items: filtered,
                                grouped: _groupByCategory(filtered),
                                onItemTap: (item) async {
                                  final changed =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => ItemEditScreen(
                                          itemId: item.id.toString()),
                                    ),
                                  );
                                  if (changed == true && mounted) {
                                    await ref
                                        .read(itemsListProvider.notifier)
                                        .refresh();
                                  }
                                },
                                onItemDelete: (item) async {
                                  final ok = await _confirmDelete(context, t);
                                  if (ok != true) return;
                                  await ref
                                      .read(itemsListProvider.notifier)
                                      .delete(item.id);
                                },
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final item = filtered[i];
                                  final itemId = item.id;

                                  return ReceiptCard(
                                    item: item,
                                    onTap: () async {
                                      final changed =
                                          await Navigator.of(context)
                                              .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => ItemEditScreen(
                                              itemId: itemId.toString()),
                                        ),
                                      );

                                      if (changed == true && mounted) {
                                        await ref
                                            .read(itemsListProvider.notifier)
                                            .refresh();
                                      }
                                    },
                                    onDelete: () async {
                                      final ok =
                                          await _confirmDelete(context, t);
                                      if (ok != true) return;

                                      await ref
                                          .read(itemsListProvider.notifier)
                                          .delete(itemId);
                                    },
                                  );
                                },
                              ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Item> _applyFilter(List<Item> items) {
    final today = DateUtils.dateOnly(DateTime.now());

    bool expired(Item i) {
      final ms = i.expiryDate;
      if (ms == null) return false;
      final expiry =
          DateUtils.dateOnly(DateTime.fromMillisecondsSinceEpoch(ms));
      return expiry.isBefore(today);
    }

    bool active(Item i) {
      final ms = i.expiryDate;
      if (ms == null) return true; // No warranty = still active
      final expiry =
          DateUtils.dateOnly(DateTime.fromMillisecondsSinceEpoch(ms));
      return !expiry.isBefore(today);
    }

    bool soon(Item i) {
      final ms = i.expiryDate;
      if (ms == null) return false;
      final expiry =
          DateUtils.dateOnly(DateTime.fromMillisecondsSinceEpoch(ms));
      final diffDays = expiry.difference(today).inDays;
      return diffDays >= 0 && diffDays <= 90; // Extended to 90 days (3 months)
    }

    switch (_filterIndex) {
      case 0: // Active
        return items.where(active).toList();
      case 1: // Expiring Soon
        return items.where(soon).toList();
      case 2: // Expired
        return items.where(expired).toList();
      case 3: // All
      default:
        return items;
    }
  }

  /// Group items by category for better organization
  Map<String, List<Item>> _groupByCategory(List<Item> items) {
    final Map<String, List<Item>> grouped = {};

    for (final item in items) {
      final category = item.categoryCode ?? 'other';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }

    // Sort categories by the order defined in Categories.all
    final sortedKeys = grouped.keys.toList();
    sortedKeys.sort((a, b) {
      final indexA = Categories.all.indexOf(a);
      final indexB = Categories.all.indexOf(b);
      if (indexA == -1 && indexB == -1) return 0;
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  /// Check if current filter should show grouped view
  bool _shouldGroupByCategory() {
    return _filterIndex == 0 || _filterIndex == 3; // Active or All
  }

  /// Build empty state based on current filter
  Widget _buildEmptyState(BuildContext context, int filterIndex) {
    final t = AppLocalizations.of(context)!;

    final (icon, title, message) = switch (filterIndex) {
      0 => (
          Icons.inbox_outlined,
          t.empty_all_title,
          t.empty_all_hint,
        ), // Active
      1 => (
          Icons.schedule_outlined,
          t.empty_soon_title,
          t.empty_soon_hint,
        ), // Due soon
      2 => (
          Icons.check_circle_outline,
          t.empty_expired_title,
          t.empty_expired_hint,
        ), // Expired
      3 => (
          Icons.inbox_outlined,
          t.empty_all_title,
          t.empty_all_hint,
        ), // All
      _ => (
          Icons.inbox_outlined,
          t.empty_all_title,
          t.empty_all_hint,
        ),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        AppEmptyState(
          icon: icon,
          title: title,
          message: message,
        ),
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, AppLocalizations t) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.delete_title),
        content: Text(t.delete_confirm),
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
  }
}

/* ======================= UI PARTS ======================= */

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTokens.spacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppFilterChip(
              label: t.filter_active,
              isSelected: index == 0,
              onTap: () => onChanged(0),
            ),
            SizedBox(width: AppTokens.spacing.xs),
            AppFilterChip(
              label: t.filter_due_soon,
              isSelected: index == 1,
              onTap: () => onChanged(1),
            ),
            SizedBox(width: AppTokens.spacing.xs),
            AppFilterChip(
              label: t.filter_expired,
              isSelected: index == 2,
              onTap: () => onChanged(2),
            ),
            SizedBox(width: AppTokens.spacing.xs),
            AppFilterChip(
              label: t.filter_all,
              isSelected: index == 3,
              onTap: () => onChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
          Text(t.error_generic_title),
          const SizedBox(height: 8),
          Text(
            message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(t.retry),
          ),
        ],
      ),
    );
  }
}

class _GroupedItemsList extends StatelessWidget {
  const _GroupedItemsList({
    required this.items,
    required this.grouped,
    required this.onItemTap,
    required this.onItemDelete,
  });

  final List<Item> items;
  final Map<String, List<Item>> grouped;
  final Function(Item) onItemTap;
  final Function(Item) onItemDelete;

  @override
  Widget build(BuildContext context) {
    // Build a flat list with headers and items
    final List<Widget> widgets = [];

    grouped.forEach((categoryCode, categoryItems) {
      // Add section header with category icon
      final categoryLabel = Categories.label(context, categoryCode);

      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppTokens.spacing.md,
            AppTokens.spacing.lg + 8,
            AppTokens.spacing.md,
            AppTokens.spacing.sm,
          ),
          child: Row(
            children: [
              AppCategoryIcon.fromCategoryId(
                categoryId: categoryCode,
                size: 36,
                iconSize: 18,
              ),
              SizedBox(width: AppTokens.spacing.sm),
              Text(
                categoryLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppBrand.current.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: AppTokens.spacing.xs),
              Text(
                '(${categoryItems.length})',
                style: TextStyle(
                  color: AppBrand.current.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

      // Add items in this category
      for (final item in categoryItems) {
        widgets.add(
          ReceiptCard(
            item: item,
            onTap: () => onItemTap(item),
            onDelete: () => onItemDelete(item),
          ),
        );
      }

      // Add spacing after section
      widgets.add(SizedBox(height: AppTokens.spacing.xs));
    });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding:
          EdgeInsets.fromLTRB(0, AppTokens.spacing.xs, 0, AppTokens.spacing.md),
      children: widgets,
    );
  }
}

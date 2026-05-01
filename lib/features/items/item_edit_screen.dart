// lib/features/items/item_edit_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/categories.dart';
import 'package:garantie_safe/features/payments/payment_methods_management_screen.dart';
import 'package:garantie_safe/features/payments/payment_method.dart';
import 'package:garantie_safe/features/payments/payment_method_service.dart';
import 'package:garantie_safe/features/premium/premium_exception.dart';
import 'package:garantie_safe/features/premium/upgrade_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/db/db_providers.dart';
import 'item.dart';
import 'items_providers.dart';
import 'item_attachment.dart';
import 'attachments_repository.dart';
import '../scan_ocr/receipt_parser_service.dart';
import '../scan_ocr/receipt_text_extraction_service.dart';
import '../scan_ocr/receipt_image_quality_service.dart';
import '../scan_ocr/receipt_validation_dialogs.dart';
import 'package:garantie_safe/ui/components/components.dart';
import 'package:garantie_safe/branding/app_brand.dart';
import 'package:garantie_safe/theme/app_tokens.dart';
import 'package:garantie_safe/theme/functional_colors.dart';

final attachmentsRepositoryProvider = Provider<AttachmentsRepository>((ref) {
  final dbManager = ref.watch(databaseManagerProvider);
  return AttachmentsRepository(dbManager: dbManager);
});

/// Represents an attachment added before item is saved
class PendingAttachment {
  final String localPath;
  final String? originalName;
  final AttachmentType type;
  final DateTime createdAt;

  PendingAttachment({
    required this.localPath,
    this.originalName,
    required this.type,
    required this.createdAt,
  });
}

class ItemEditScreen extends ConsumerStatefulWidget {
  const ItemEditScreen({
    super.key,
    this.itemId,
    this.scannedData,
    this.scannedFilePath,
  });

  /// IMPORTANT: In unserem neuen System ist ID ein String.
  /// In der ListScreen geben wir immer .toString() rein, daher passt das immer.
  final String? itemId;

  /// Optional: Scanned receipt data from OCR
  final ReceiptScanDraft? scannedData;

  /// Optional: Path to scanned file (image or PDF)
  final String? scannedFilePath;

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _paymentMethodCtrl = TextEditingController();

  DateTime _purchaseDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _expiryDate;
  int? _warrantyYears; // 2, 3, 5, custom, or null
  bool _hasCustomExpiry = false; // Track if user manually set expiry

  bool _saving = false;
  bool _initialized = false;

  // Attachments state
  int? _savedItemId; // Item ID after save (needed for attachments)
  List<ItemAttachment> _attachments = [];
  bool _loadingAttachments = false;
  final List<PendingAttachment> _pendingAttachments =
      []; // Attachments before item is saved

  // Payment methods state
  List<PaymentMethod> _availablePaymentMethods = [];
  bool _loadingPaymentMethods = true;
  String? _selectedPaymentMethod;

  // Category state
  String? _selectedCategory;

  // OCR metadata (internal storage, not shown in UI)
  String? _ocrRawText;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _initFromScannedData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _merchantCtrl.dispose();
    _notesCtrl.dispose();
    _paymentMethodCtrl.dispose();
    _cleanupPendingAttachments();
    super.dispose();
  }

  /// Clean up pending attachment files when user cancels
  Future<void> _cleanupPendingAttachments() async {
    for (final pending in _pendingAttachments) {
      try {
        final file = File(pending.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete pending file: $e');
      }
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingPaymentMethods = true);
    try {
      final methods = await PaymentMethodService.instance
          .getForSelection(currentCode: _selectedPaymentMethod);
      if (!mounted) return;
      setState(() {
        // If empty, use default fallback methods
        _availablePaymentMethods =
            methods.isEmpty ? _getDefaultPaymentMethods() : methods;
        _loadingPaymentMethods = false;
      });
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
      if (mounted) {
        setState(() {
          // On error, use default fallback methods
          _availablePaymentMethods = _getDefaultPaymentMethods();
          _loadingPaymentMethods = false;
        });
      }
    }
  }

  /// Get default payment methods as fallback when service returns empty
  List<PaymentMethod> _getDefaultPaymentMethods() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return [
      PaymentMethod(
        code: 'cash',
        customLabel: null,
        isBuiltIn: true,
        isEnabled: true,
        isArchived: false,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      PaymentMethod(
        code: 'debit_card',
        customLabel: null,
        isBuiltIn: true,
        isEnabled: true,
        isArchived: false,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      PaymentMethod(
        code: 'credit_card',
        customLabel: null,
        isBuiltIn: true,
        isEnabled: true,
        isArchived: false,
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Initialize form with scanned data if provided
  void _initFromScannedData() {
    // Add scanned file as pending attachment (even if OCR failed)
    _addScannedFileAttachment();

    // Prefill fields from scanned data (if available)
    final scanned = widget.scannedData;
    if (scanned == null) return;

    // Store OCR raw text internally (not shown to user)
    _ocrRawText = scanned.rawText;

    // Prefill merchant
    if (scanned.merchant != null && scanned.merchant!.isNotEmpty) {
      _merchantCtrl.text = scanned.merchant!;
    }

    // Prefill purchase date
    if (scanned.purchaseDate != null) {
      _purchaseDate = DateUtils.dateOnly(scanned.purchaseDate!);
    }

    // Prefill payment method
    if (scanned.paymentMethodCode != null) {
      _selectedPaymentMethod = scanned.paymentMethodCode;
    }

    // Do NOT autofill product name - user should enter manually
    // OCR Phase 1 only prefills merchant and purchase date

    // Do NOT append OCR text to notes - keep notes clean for user
  }

  /// Add scanned file as a pending attachment
  Future<void> _addScannedFileAttachment() async {
    final filePath = widget.scannedFilePath;
    if (filePath == null) return;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Scanned file not found: $filePath');
        return;
      }

      final extension = p.extension(filePath).toLowerCase();
      final AttachmentType type;
      if (extension == '.pdf') {
        type = AttachmentType.pdf;
      } else if (['.jpg', '.jpeg', '.png', '.heic'].contains(extension)) {
        type = AttachmentType.image;
      } else {
        type = AttachmentType.other;
      }

      final pending = PendingAttachment(
        localPath: filePath,
        originalName: p.basename(filePath),
        type: type,
        createdAt: DateTime.now(),
      );

      setState(() {
        _pendingAttachments.add(pending);
      });

      debugPrint('Added scanned file as pending attachment: $filePath');

      // Show success message
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.scan_success),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding scanned file: $e');
    }
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
    _selectedPaymentMethod = existing.paymentMethodCode;
    _selectedCategory = existing.categoryCode;

    final pMs = existing.purchaseDate;
    _purchaseDate = DateUtils.dateOnly(
      DateTime.fromMillisecondsSinceEpoch(pMs),
    );

    _warrantyYears = existing.warrantyYears;

    final eMs = existing.expiryDate;
    if (eMs != null) {
      _expiryDate = DateUtils.dateOnly(
        DateTime.fromMillisecondsSinceEpoch(eMs),
      );
      // Check if expiry was manually set (not matching calculated)
      if (_warrantyYears != null) {
        final calculated = _calculateExpiry(_purchaseDate, _warrantyYears!);
        _hasCustomExpiry = calculated != _expiryDate;
      } else {
        _hasCustomExpiry = true;
      }
    }

    // Load attachments
    _loadAttachments();
  }

  Future<void> _save(Item? existing) async {
    final t = AppLocalizations.of(context)!;
    if (_saving) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Validate expiry date is set
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.expiry_date_required),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if there are any attachments (pending or saved)
    final totalAttachments = _pendingAttachments.length + _attachments.length;
    if (totalAttachments == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.attachment_required)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final notifier = ref.read(itemsListProvider.notifier);
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      final title = _titleCtrl.text.trim();
      final merchant =
          _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim();
      final notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      final paymentMethod = _selectedPaymentMethod;

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
              warrantyYears: _warrantyYears,
              categoryCode: _selectedCategory,
              paymentMethodCode: paymentMethod,
              notes: notes,
              ocrRawText: _ocrRawText,
              createdAt: nowMs,
              updatedAt: nowMs,
            )
          : existing.copyWith(
              title: title,
              merchant: merchant,
              purchaseDate: purchaseMs,
              expiryDate: expiryMs,
              warrantyYears: _warrantyYears,
              categoryCode: _selectedCategory,
              paymentMethodCode: paymentMethod,
              notes: notes,
              ocrRawText: _ocrRawText,
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
          // Save pending attachments now that we have an item ID
          await _savePendingAttachments(newItem.id);
        }
      } else {
        _savedItemId = existing.id;
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FreemiumLimitReachedException {
      if (!mounted) return;

      // Show upgrade dialog when freemium limit is reached
      final upgraded = await showUpgradeDialog(context);

      if (upgraded) {
        // User upgraded - try saving again
        if (mounted) {
          setState(() => _saving = false);
          _save(existing); // Retry save
        }
      } else {
        // User declined upgrade
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.premium_limit_reached),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
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

    // Show source picker
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(t.camera),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(t.gallery),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(t.pdf),
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

        // === RECEIPT VALIDATION FOR IMAGES ===
        // Run OCR and validate receipt quality for warranty usability
        if (!mounted) return;

        debugPrint(
            'ItemEdit: Starting receipt validation for image: $filePath');

        // Show loading indicator while validating
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // Extract text from image using OCR
          final extractionResult =
              await ReceiptTextExtractionService.extractFromImage(filePath);

          debugPrint(
              'ItemEdit: OCR extraction complete - ${extractionResult.lines.length} lines');

          // Parse OCR text to extract merchant and date
          final parsedData = ReceiptParserService.parseText(
              extractionResult.rawText, extractionResult.lines);

          debugPrint(
              'ItemEdit: Parsing complete - merchant: ${parsedData.merchant}, date: ${parsedData.purchaseDate}');

          // Validate receipt quality
          final validation = ReceiptImageQualityService.validateReceipt(
            extractionResult: extractionResult,
            draft: parsedData,
            source: 'gallery_import',
          );

          // Dismiss loading indicator
          if (mounted) {
            Navigator.pop(context);
          }

          // Handle validation result
          if (validation.isReject) {
            debugPrint('ItemEdit: Receipt REJECTED - ${validation.reason}');
            // Receipt quality is too poor - show rejection dialog
            if (!mounted) return;
            await showReceiptRejectDialog(
              context: context,
              validation: validation,
              source: 'file',
              imagePath: filePath,
            );

            // User must retake (no option to continue)
            return; // Exit without saving
          } else if (validation.isWarning) {
            debugPrint('ItemEdit: Receipt WARNING - ${validation.reason}');
            // Receipt quality is borderline - show warning and let user decide
            if (!mounted) return;
            final action = await showReceiptWarningDialog(
              context: context,
              validation: validation,
              source: 'file',
              imagePath: filePath,
            );

            if (action == ReceiptValidationAction.retake || action == null) {
              debugPrint('ItemEdit: User chose to retake photo');
              return; // Exit without saving
            }
            debugPrint('ItemEdit: User chose to use photo anyway');
            // If user chose "use anyway", continue below
          } else {
            debugPrint('ItemEdit: Receipt ACCEPTED');
          }
          // If validation.isAccept, continue normally
        } catch (e) {
          // OCR/validation failed - allow user to continue but log the error
          debugPrint('ItemEdit: Receipt validation error: $e');
          if (mounted) {
            Navigator.pop(context); // Dismiss loading indicator
          }
          // Continue with save - don't block users if validation itself fails
        }
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

        // Note: Could add PDF validation here if needed in the future
      }

      // Copy file to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = p.extension(filePath);

      // If item doesn't exist yet, store in pending folder
      if (itemId == null || itemId == 0) {
        final pendingDir = Directory(p.join(attachmentsDir.path, 'pending'));
        if (!await pendingDir.exists()) {
          await pendingDir.create(recursive: true);
        }

        final newFileName = 'pending_$timestamp$extension';
        final newPath = p.join(pendingDir.path, newFileName);
        await File(filePath).copy(newPath);

        // Add to pending list
        setState(() {
          _pendingAttachments.add(
            PendingAttachment(
              localPath: newPath,
              originalName: originalName,
              type: type,
              createdAt: DateTime.now(),
            ),
          );
        });
      } else {
        // Item exists, save normally
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
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.attachment_added)),
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
        content: Text(t.delete_attachment_confirm),
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
      final repo = ref.read(attachmentsRepositoryProvider);

      // Check if other items reference this file
      final otherReferences = await repo.countOtherReferences(
        att.path,
        excludeAttachmentId: att.id,
      );

      // Delete from database
      await repo.deleteById(att.id!);

      // Only delete physical file if no other items reference it
      if (otherReferences == 0) {
        try {
          await File(att.path).delete();
          debugPrint('Deleted file: ${att.path}');
        } catch (e) {
          debugPrint('Could not delete file ${att.path}: $e');
          // Ignore file deletion errors
        }
      } else {
        debugPrint(
            'File ${att.path} still referenced by $otherReferences other attachment(s)');
      }

      await _loadAttachments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.attachment_deleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openAttachment(ItemAttachment att) async {
    final t = AppLocalizations.of(context)!;
    try {
      await OpenFilex.open(att.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.item_could_not_open_file(e.toString()))),
      );
    }
  }

  Future<void> _removePendingAttachment(PendingAttachment pending) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.delete_title),
        content: Text(t.delete_attachment_confirm),
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
      // Delete file
      try {
        await File(pending.localPath).delete();
      } catch (_) {
        // Ignore file deletion errors
      }

      setState(() {
        _pendingAttachments.remove(pending);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.attachment_deleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openPendingAttachment(PendingAttachment pending) async {
    try {
      await OpenFilex.open(pending.localPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
  }

  Future<void> _savePendingAttachments(int itemId) async {
    if (_pendingAttachments.isEmpty) return;

    try {
      final repo = ref.read(attachmentsRepositoryProvider);
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));

      // Get current max order from existing attachments
      int maxOrder = 0;
      try {
        final existing = await repo.forItem(itemId);
        if (existing.isNotEmpty) {
          maxOrder =
              existing.map((a) => a.sortOrder).reduce((a, b) => a > b ? a : b);
        }
      } catch (_) {
        // Ignore errors, start from 0
      }

      for (final pending in _pendingAttachments) {
        maxOrder++;

        // Move file from pending/ to main attachments/ folder
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = p.extension(pending.localPath);
        final newFileName = '${itemId}_$timestamp$extension';
        final newPath = p.join(attachmentsDir.path, newFileName);

        await File(pending.localPath).copy(newPath);

        // Delete pending file
        try {
          await File(pending.localPath).delete();
        } catch (_) {
          // Ignore deletion errors
        }

        // Insert into database
        final attachment = ItemAttachment(
          itemId: itemId,
          path: newPath,
          type: pending.type,
          originalName: pending.originalName,
          sortOrder: maxOrder,
          createdAt: pending.createdAt,
        );

        await repo.add(attachment);
      }

      // Clear pending list
      setState(() {
        _pendingAttachments.clear();
      });

      // Reload attachments to show newly saved ones
      await _loadAttachments();
    } catch (e) {
      debugPrint('Error saving pending attachments: $e');
      // Don't fail the whole save operation if attachments fail
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
        // Recalculate expiry if warranty years is set and no custom expiry
        if (_warrantyYears != null && !_hasCustomExpiry) {
          _expiryDate = _calculateExpiry(_purchaseDate, _warrantyYears!);
        }
        // Reset custom expiry if it's now before purchase
        if (_expiryDate != null && _expiryDate!.isBefore(_purchaseDate)) {
          _expiryDate = null;
          _hasCustomExpiry = false;
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
      setState(() {
        _expiryDate = DateUtils.dateOnly(picked);
        _hasCustomExpiry = true; // User manually set expiry
      });
    }
  }

  /// Unified date picker wrapper
  Future<void> _pickDate(bool isPurchaseDate) async {
    if (isPurchaseDate) {
      await _pickPurchaseDate();
    } else {
      await _pickExpiryDate();
    }
  }

  /// Show dialog for custom warranty duration input
  Future<void> _showCustomWarrantyDialog() async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: (_warrantyYears != null &&
              _warrantyYears != 2 &&
              _warrantyYears != 3 &&
              _warrantyYears != 5)
          ? _warrantyYears.toString()
          : '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter custom warranty duration'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.warranty_custom_years,
            hintText: 'Number of years (1-10)',
            border: OutlineInputBorder(),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid number')),
                );
                return;
              }
              if (value < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Minimum 1 year')),
                );
                return;
              }
              if (value > 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Maximum 10 years')),
                );
                return;
              }
              Navigator.pop(context, value);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );

    if (result != null) {
      _setWarrantyYears(result);
    }
  }

  void _setWarrantyYears(int? years) {
    setState(() {
      _warrantyYears = years;
      // Auto-calculate expiry if not custom
      if (years != null && !_hasCustomExpiry) {
        _expiryDate = _calculateExpiry(_purchaseDate, years);
      } else if (years == null && !_hasCustomExpiry) {
        _expiryDate = null;
      }
    });
  }

  DateTime _calculateExpiry(DateTime purchaseDate, int years) {
    return DateTime(
      purchaseDate.year + years,
      purchaseDate.month,
      purchaseDate.day,
    );
  }

  /// Build shared receipt draft from database (for "Add another product" feature)
  /// This ensures the data comes from persistent source, not UI state
  Future<Map<String, dynamic>?> _buildSharedReceiptDraftFromDatabase() async {
    final itemId = _savedItemId;
    if (itemId == null) return null;

    try {
      // Load item from database
      final itemsRepo = ref.read(itemsRepositoryProvider);
      final item = await itemsRepo.getById(itemId);
      if (item == null) return null;

      // Load attachments from database
      final attachmentsRepo = ref.read(attachmentsRepositoryProvider);
      final attachments = await attachmentsRepo.forItem(itemId);
      if (attachments.isEmpty) return null;

      // Get the first attachment (receipt)
      final receiptAttachment = attachments.first;

      // Build draft from database fields
      final sharedData = ReceiptScanDraft(
        merchant: item.merchant,
        purchaseDate: DateTime.fromMillisecondsSinceEpoch(item.purchaseDate),
        paymentMethodCode: item.paymentMethodCode,
        rawText: '', // Empty raw text (OCR text not needed for reuse)
      );

      return {
        'draft': sharedData,
        'filePath': receiptAttachment.path,
      };
    } catch (e) {
      debugPrint('Error building shared receipt draft from database: $e');
      return null;
    }
  }

  /// Add another product from the same receipt
  Future<void> _addAnotherProductFromReceipt() async {
    // Build draft from database (NOT from UI state)
    final result = await _buildSharedReceiptDraftFromDatabase();
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not load receipt data. Please save the item first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final sharedData = result['draft'] as ReceiptScanDraft;
    final filePath = result['filePath'] as String;

    // Navigate to new item creation with shared data
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemEditScreen(
          scannedData: sharedData,
          scannedFilePath: filePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(itemsListProvider);
    final brand = AppBrand.current;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.itemId == null ? t.items_add : t.items_edit),
        backgroundColor: Colors.white,
        elevation: 0,
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
                padding: EdgeInsets.zero,
                children: [
                  // Compact OCR summary (if scanned) - ONLY shown when data exists
                  if (widget.scannedData != null ||
                      widget.scannedFilePath != null) ...[
                    _buildOcrSummary(t),
                    SizedBox(height: AppTokens.spacing.lg),
                  ],

                  // Core Information Section - ALWAYS shown
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppTokens.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemId == null ? t.items_add : t.items_edit,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: brand.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: AppTokens.spacing.md),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            labelText: t.items_name,
                            hintText: t.items_name_hint,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.text,
                          enableSuggestions: true,
                          autocorrect: true,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: brand.textPrimary,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? t.field_required
                              : null,
                        ),
                        SizedBox(height: AppTokens.spacing.sm),
                        _buildCategoryField(t),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTokens.spacing.lg + 8),

                  // Warranty Section - ALWAYS shown
                  _buildWarrantySection(t),

                  SizedBox(height: AppTokens.spacing.lg + 8),

                  // Attachments Section - ALWAYS shown
                  _buildAttachmentsSection(t),

                  SizedBox(height: AppTokens.spacing.lg + 8),

                  // Optional Details Section - ALWAYS shown
                  _buildOptionalDetailsSection(t),

                  SizedBox(height: AppTokens.spacing.xl),

                  // Save Button - ALWAYS shown
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppTokens.spacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(existing),
                        style: FilledButton.styleFrom(
                          backgroundColor: brand.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radii.md),
                          ),
                        ),
                        icon: _saving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          t.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppTokens.spacing.md),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOcrSummary(AppLocalizations t) {
    return Padding(
      padding: EdgeInsets.all(AppTokens.spacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppSemanticColors.success.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTokens.radii.md),
          border: Border.all(
            color: AppSemanticColors.success.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(AppTokens.spacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppSemanticColors.success,
              size: 24,
            ),
            SizedBox(width: AppTokens.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt scanned',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppBrand.current.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Please review and complete the details below',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppBrand.current.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantySection(AppLocalizations t) {
    final brand = AppBrand.current;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: t.warranty_years),
          SizedBox(height: AppTokens.spacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTokens.radii.md),
              border: Border.all(
                color: brand.border,
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(AppTokens.spacing.md),
            child: Column(
              children: [
                // Purchase Date Row
                InkWell(
                  onTap: () => _pickDate(true),
                  borderRadius: BorderRadius.circular(AppTokens.radii.md),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppTokens.spacing.sm,
                      horizontal: AppTokens.spacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          color: brand.textSecondary,
                          size: 20,
                        ),
                        SizedBox(width: AppTokens.spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.items_purchase,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: brand.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                intl.DateFormat.yMMMd().format(_purchaseDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: brand.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: brand.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                Divider(height: AppTokens.spacing.md + 8),

                // Warranty Duration Chips
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.warranty_years,
                    style: TextStyle(
                      fontSize: 12,
                      color: brand.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: AppTokens.spacing.xs),
                Wrap(
                  spacing: AppTokens.spacing.xs,
                  runSpacing: AppTokens.spacing.xs,
                  children: [
                    AppFilterChip(
                      label: '2 years',
                      isSelected: _warrantyYears == 2,
                      onTap: () => _setWarrantyYears(2),
                    ),
                    AppFilterChip(
                      label: '3 years',
                      isSelected: _warrantyYears == 3,
                      onTap: () => _setWarrantyYears(3),
                    ),
                    AppFilterChip(
                      label: '5 years',
                      isSelected: _warrantyYears == 5,
                      onTap: () => _setWarrantyYears(5),
                    ),
                    AppFilterChip(
                      label: (_warrantyYears != null &&
                              _warrantyYears != 2 &&
                              _warrantyYears != 3 &&
                              _warrantyYears != 5)
                          ? '${t.warranty_custom} ($_warrantyYears ${t.years_suffix})'
                          : t.warranty_custom,
                      isSelected: _warrantyYears != null &&
                          _warrantyYears != 2 &&
                          _warrantyYears != 3 &&
                          _warrantyYears != 5,
                      onTap: () => _showCustomWarrantyDialog(),
                    ),
                  ],
                ),

                Divider(height: AppTokens.spacing.md + 8),

                // Expiry Date Row
                InkWell(
                  onTap: () => _pickDate(false),
                  borderRadius: BorderRadius.circular(AppTokens.radii.md),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppTokens.spacing.sm,
                      horizontal: AppTokens.spacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: brand.textSecondary,
                          size: 20,
                        ),
                        SizedBox(width: AppTokens.spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.items_expiry,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: brand.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                _expiryDate != null
                                    ? intl.DateFormat.yMMMd()
                                        .format(_expiryDate!)
                                    : 'Auto-calculated',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _expiryDate != null
                                      ? brand.textPrimary
                                      : brand.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: brand.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalDetailsSection(AppLocalizations t) {
    final brand = AppBrand.current;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Optional Details'),
          SizedBox(height: AppTokens.spacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTokens.radii.md),
              border: Border.all(
                color: brand.border,
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(AppTokens.spacing.md),
            child: Column(
              children: [
                TextFormField(
                  controller: _merchantCtrl,
                  decoration: InputDecoration(
                    labelText: t.items_merchant,
                    hintText: t.items_merchant_hint,
                    prefixIcon: Icon(Icons.store_outlined),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontSize: 14,
                    color: brand.textPrimary,
                  ),
                ),
                SizedBox(height: AppTokens.spacing.sm),
                _buildPaymentMethodField(t),
                SizedBox(height: AppTokens.spacing.sm),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: t.item_notes,
                    hintText: t.item_notes_hint,
                    prefixIcon: Icon(Icons.notes_outlined),
                    isDense: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 14,
                    color: brand.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(AppLocalizations t) {
    final hasItem = _savedItemId != null && _savedItemId != 0;
    final hasPending = _pendingAttachments.isNotEmpty;
    final hasSaved = _attachments.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.attachments,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppBrand.current.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _addAttachment,
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.add),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTokens.spacing.sm,
                    vertical: AppTokens.spacing.xs,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTokens.spacing.sm),
          if (_loadingAttachments)
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppTokens.spacing.md),
                child: CircularProgressIndicator(),
              ),
            )
          else if (!hasPending && !hasSaved)
            Container(
              decoration: BoxDecoration(
                color: AppSemanticColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTokens.radii.md),
                border: Border.all(
                  color: AppSemanticColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(AppTokens.spacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppSemanticColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: AppTokens.spacing.sm),
                  Expanded(
                    child: Text(
                      t.no_receipt_warning,
                      style: TextStyle(
                        color: AppBrand.current.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Show pending attachments ONLY in create mode (no itemId yet)
            // These are attachments added before first save
            if (!hasItem && hasPending)
              ..._pendingAttachments
                  .map((pending) => _buildPendingAttachmentTile(pending, t)),
            // Show saved attachments from database
            // These never show as pending
            ..._attachments.map((att) => _buildAttachmentTile(att, t)),

            // "Add another product from this receipt" action (only in edit mode with attachments)
            if (hasItem && hasSaved) ...[
              SizedBox(height: AppTokens.spacing.sm),
              OutlinedButton.icon(
                onPressed: _addAnotherProductFromReceipt,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(t.multi_item_add_from_receipt),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(AppTokens.spacing.sm),
                  side: BorderSide(color: AppBrand.current.primary),
                  foregroundColor: AppBrand.current.primary,
                ),
              ),
              SizedBox(height: AppTokens.spacing.xs),
              Text(
                t.multi_item_add_from_receipt_subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppBrand.current.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(ItemAttachment att, AppLocalizations t) {
    IconData icon;
    Color iconColor;
    switch (att.type) {
      case AttachmentType.image:
        icon = Icons.image;
        iconColor = AppBrand.current.primary;
        break;
      case AttachmentType.pdf:
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case AttachmentType.other:
        icon = Icons.insert_drive_file;
        iconColor = AppBrand.current.textSecondary;
        break;
    }

    final displayName = att.originalName ?? p.basename(att.path);

    return Padding(
      padding: EdgeInsets.only(bottom: AppTokens.spacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radii.md),
          border: Border.all(
            color: AppBrand.current.border,
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(AppTokens.spacing.sm),
        child: InkWell(
          onTap: () => _openAttachment(att),
          borderRadius: BorderRadius.circular(AppTokens.radii.md),
          child: Row(
            children: [
              Icon(icon, size: 28, color: iconColor),
              SizedBox(width: AppTokens.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppBrand.current.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatAttachmentType(att.type),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppBrand.current.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeAttachment(att),
                tooltip: t.delete,
                color: AppSemanticColors.error,
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingAttachmentTile(
      PendingAttachment pending, AppLocalizations t) {
    IconData icon;
    Color iconColor;
    switch (pending.type) {
      case AttachmentType.image:
        icon = Icons.image;
        iconColor = AppBrand.current.primary;
        break;
      case AttachmentType.pdf:
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case AttachmentType.other:
        icon = Icons.insert_drive_file;
        iconColor = AppBrand.current.textSecondary;
        break;
    }

    final displayName = pending.originalName ?? p.basename(pending.localPath);

    return Padding(
      padding: EdgeInsets.only(bottom: AppTokens.spacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radii.md),
          border: Border.all(
            color: AppBrand.current.border,
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(AppTokens.spacing.sm),
        child: InkWell(
          onTap: () => _openPendingAttachment(pending),
          borderRadius: BorderRadius.circular(AppTokens.radii.md),
          child: Row(
            children: [
              Icon(icon, size: 28, color: iconColor),
              SizedBox(width: AppTokens.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppBrand.current.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatAttachmentType(pending.type),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppBrand.current.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removePendingAttachment(pending),
                tooltip: t.delete,
                color: AppSemanticColors.error,
                iconSize: 20,
              ),
            ],
          ),
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

  Widget _buildCategoryField(AppLocalizations t) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: t.items_category,
        prefixIcon: Icon(Icons.category_outlined),
        isDense: true,
      ),
      initialValue: _selectedCategory,
      style: TextStyle(
        fontSize: 14,
        color: AppBrand.current.textPrimary,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return t.category_required;
        }
        return null;
      },
      items: Categories.all.map((code) {
        return DropdownMenuItem<String>(
          value: code,
          child: Text(Categories.label(context, code)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCategory = value);
      },
    );
  }

  Widget _buildPaymentMethodField(AppLocalizations t) {
    // Get current selected payment method display text
    String selectedText = t.not_set;
    if (_selectedPaymentMethod != null) {
      // Find the selected method to display its label
      final method = _availablePaymentMethods
          .where((m) => m.code == _selectedPaymentMethod)
          .firstOrNull;
      if (method != null) {
        selectedText = PaymentMethodService.getLabel(context, method);
        if (method.isArchived) {
          selectedText += ' (${t.payment_methods_archived})';
        }
      } else {
        // Archived method not in current list, show with code
        selectedText = PaymentMethodService.getLabelByCode(
            context, _selectedPaymentMethod!);
      }
    }

    // Always show a simple tappable field - never conditional rendering
    return InkWell(
      onTap:
          _loadingPaymentMethods ? null : () => _showPaymentMethodSelector(t),
      borderRadius: BorderRadius.circular(AppTokens.radii.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: t.payment_method_label,
          prefixIcon: Icon(Icons.payment_outlined),
          suffixIcon: _loadingPaymentMethods
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : const Icon(Icons.arrow_drop_down),
          isDense: true,
        ),
        child: Text(
          selectedText,
          style: _selectedPaymentMethod == null
              ? TextStyle(
                  color: AppBrand.current.textSecondary,
                  fontSize: 14,
                )
              : TextStyle(
                  fontSize: 14,
                  color: AppBrand.current.textPrimary,
                ),
        ),
      ),
    );
  }

  /// Show payment method selector in a bottom sheet
  Future<void> _showPaymentMethodSelector(AppLocalizations t) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.payment_method_label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Selection list
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // "Not set" option
                  ListTile(
                    leading: _selectedPaymentMethod == null
                        ? Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary)
                        : const SizedBox(width: 24),
                    title: Text(
                      t.not_set,
                      style: TextStyle(
                        color: _selectedPaymentMethod == null
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: _selectedPaymentMethod == null
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, '__CLEAR__'),
                  ),
                  const Divider(),
                  // Available payment methods (excluding archived for new receipts)
                  ..._availablePaymentMethods
                      .where((method) => !method.isArchived)
                      .map((method) {
                    final isSelected = _selectedPaymentMethod == method.code;
                    return ListTile(
                      leading: isSelected
                          ? Icon(Icons.check,
                              color: Theme.of(context).colorScheme.primary)
                          : const SizedBox(width: 24),
                      title: Text(
                        PaymentMethodService.getLabel(context, method),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, method.code),
                    );
                  }),
                  // Show currently selected archived method if editing
                  if (_selectedPaymentMethod != null)
                    ..._availablePaymentMethods
                        .where((method) =>
                            method.isArchived &&
                            method.code == _selectedPaymentMethod)
                        .map((method) {
                      return ListTile(
                        leading: Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                PaymentMethodService.getLabel(context, method),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(t.payment_methods_archived),
                              visualDensity: VisualDensity.compact,
                              labelStyle: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        subtitle: Text(t.payment_methods_archived_edit_hint),
                        onTap: () => Navigator.pop(context, method.code),
                      );
                    }),
                  const Divider(),
                  // Configure payment methods link
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(t.payment_methods_configure),
                    onTap: () async {
                      Navigator.pop(context); // Close bottom sheet
                      await Navigator.of(this.context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const PaymentMethodsManagementScreen(),
                        ),
                      );
                      // Reload payment methods after returning
                      _loadPaymentMethods();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Update selection if user chose something
    if (selected != null) {
      setState(() {
        _selectedPaymentMethod = selected == '__CLEAR__' ? null : selected;
      });
    }
  }
}

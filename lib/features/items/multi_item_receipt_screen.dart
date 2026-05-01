import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/features/premium/premium_exception.dart';
import 'package:garantie_safe/features/premium/upgrade_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import '../../core/backup_service.dart';
import '../../core/categories.dart';
import '../payments/payment_method.dart';
import '../payments/payment_method_service.dart';
import '../scan_ocr/receipt_parser_service.dart';
import 'item.dart';
import 'items_providers.dart';
import 'item_attachment.dart';
import 'attachments_repository.dart';

/// Provider for attachments repository
final attachmentsRepositoryProvider = Provider<AttachmentsRepository>((ref) {
  return AttachmentsRepository();
});

class MultiItemReceiptScreen extends ConsumerStatefulWidget {
  final ReceiptScanDraft scannedData;
  final String receiptFilePath;

  const MultiItemReceiptScreen({
    super.key,
    required this.scannedData,
    required this.receiptFilePath,
  });

  @override
  ConsumerState<MultiItemReceiptScreen> createState() =>
      _MultiItemReceiptScreenState();
}

class _MultiItemReceiptScreenState
    extends ConsumerState<MultiItemReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_ItemFormData> _items = [];
  bool _saving = false;

  // Shared editable fields
  final TextEditingController _merchantCtrl = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  String? _selectedPaymentMethod;
  List<PaymentMethod> _availablePaymentMethods = [];
  bool _loadingPaymentMethods = true;

  @override
  void initState() {
    super.initState();

    // Initialize shared fields from scanned data
    _merchantCtrl.text = widget.scannedData.merchant ?? '';
    _purchaseDate = widget.scannedData.purchaseDate ?? DateTime.now();

    // Start with one item
    _items.add(_ItemFormData());

    // Load payment methods
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingPaymentMethods = true);
    try {
      final methods = await PaymentMethodService.instance
          .getForSelection(currentCode: _selectedPaymentMethod);
      setState(() {
        _availablePaymentMethods = methods;
        _loadingPaymentMethods = false;
      });
    } catch (e) {
      setState(() => _loadingPaymentMethods = false);
    }
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addAnotherItem() {
    setState(() {
      _items.add(_ItemFormData());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  Future<void> _createItems() async {
    final t = AppLocalizations.of(context)!;

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.multi_item_validation_error)),
      );
      return;
    }

    // Validate that all items have expiry dates
    for (var i = 0; i < _items.length; i++) {
      final itemData = _items[i];
      if (itemData.warrantyYears == null && itemData.customExpiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${t.multi_item_item_number(i + 1)}: ${t.expiry_date_required}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final itemsRepo = ref.read(itemsRepositoryProvider);
      final attachmentRepo = ref.read(attachmentsRepositoryProvider);
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      final merchant =
          _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim();
      final purchaseMs =
          DateUtils.dateOnly(_purchaseDate).toUtc().millisecondsSinceEpoch;
      final ocrRawText = widget.scannedData.rawText;

      final createdItemIds = <int>[];

      // Create each item
      for (final itemData in _items) {
        final title = itemData.titleCtrl.text.trim();
        final categoryCode = itemData.selectedCategory;
        final warrantyYears = itemData.warrantyYears;

        // Calculate expiry date
        int expiryMs;
        if (itemData.customExpiryDate != null) {
          // Use custom expiry date
          expiryMs = DateUtils.dateOnly(itemData.customExpiryDate!)
              .toUtc()
              .millisecondsSinceEpoch;
        } else {
          // Calculate from warranty years
          final expiryDate = DateTime(
            _purchaseDate.year + warrantyYears!,
            _purchaseDate.month,
            _purchaseDate.day,
          );
          expiryMs =
              DateUtils.dateOnly(expiryDate).toUtc().millisecondsSinceEpoch;
        }

        // Create the item
        final item = Item(
          id: 0,
          vaultId: 'personal',
          title: title,
          merchant: merchant,
          purchaseDate: purchaseMs,
          expiryDate: expiryMs,
          warrantyYears: warrantyYears,
          categoryCode: categoryCode,
          paymentMethodCode: _selectedPaymentMethod,
          notes: null,
          ocrRawText: ocrRawText,
          deletedAt: null,
          createdAt: nowMs,
          updatedAt: nowMs,
        );

        final savedItemId = await itemsRepo.upsert(item);
        createdItemIds.add(savedItemId);
      }

      // Attach the receipt to all created items
      // All items share the same physical file
      final attachmentType = _getAttachmentType(widget.receiptFilePath);
      final originalName = p.basename(widget.receiptFilePath);

      for (var itemId in createdItemIds) {
        final attachment = ItemAttachment(
          itemId: itemId,
          path: widget.receiptFilePath,
          type: attachmentType,
          originalName: originalName,
          sortOrder: 0,
          createdAt: DateTime.now(),
        );
        await attachmentRepo.add(attachment);
      }

      await BackupService.markDataChanged(reason: 'multi_item_create');

      // Refresh items list
      ref.read(itemsListProvider.notifier).refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.multi_item_success(createdItemIds.length)),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to items list
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FreemiumLimitReachedException {
      debugPrint('Freemium limit reached during multi-item creation');
      if (!mounted) return;

      setState(() => _saving = false);

      // Show upgrade dialog when freemium limit is reached
      final upgraded = await showUpgradeDialog(context);

      if (upgraded) {
        // User upgraded - try saving again
        if (mounted) {
          _createItems(); // Retry create
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
      debugPrint('Error creating items: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _saving = false);
    }
  }

  AttachmentType _getAttachmentType(String path) {
    final ext = p.extension(path).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.heic', '.gif', '.webp'].contains(ext)) {
      return AttachmentType.image;
    } else if (ext == '.pdf') {
      return AttachmentType.pdf;
    }
    return AttachmentType.other;
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
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
      });
    }
  }

  Future<void> _pickCustomExpiryDate(_ItemFormData itemData) async {
    final t = AppLocalizations.of(context)!;
    final initialDate = itemData.customExpiryDate ?? _purchaseDate;

    final picked = await showDatePicker(
      context: context,
      initialDate:
          initialDate.isBefore(_purchaseDate) ? _purchaseDate : initialDate,
      firstDate: _purchaseDate,
      lastDate: DateTime(2100),
      helpText: t.items_pick_expiry_date,
    );
    if (picked != null && mounted) {
      setState(() {
        itemData.customExpiryDate = DateUtils.dateOnly(picked);
        itemData.warrantyYears =
            null; // Clear warranty years when custom date is set
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.multi_item_screen_title),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Shared receipt section
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t.multi_item_shared_section,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.multi_item_shared_info,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                          ),
                          const SizedBox(height: 16),

                          // Editable merchant field
                          TextFormField(
                            controller: _merchantCtrl,
                            decoration: InputDecoration(
                              labelText: t.items_merchant,
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.text,
                            enableSuggestions: true,
                            autocorrect: true,
                          ),
                          const SizedBox(height: 12),

                          // Editable purchase date
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            tileColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            title: Text(t.items_purchase),
                            subtitle: Text(_formatDate(_purchaseDate)),
                            trailing: IconButton(
                              icon: const Icon(Icons.date_range),
                              onPressed: _pickPurchaseDate,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Payment method selector
                          if (_loadingPaymentMethods)
                            const LinearProgressIndicator()
                          else
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: t.payment_method_label,
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                              initialValue: _selectedPaymentMethod,
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(t.not_set),
                                ),
                                ..._availablePaymentMethods.map((method) {
                                  return DropdownMenuItem<String>(
                                    value: method.code,
                                    child: Text(PaymentMethodService.getLabel(
                                        context, method)),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value;
                                });
                              },
                            ),
                          const SizedBox(height: 12),

                          // Receipt attachment summary
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.attachment,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.basename(widget.receiptFilePath),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Items section
                  Row(
                    children: [
                      const Icon(Icons.inventory_2),
                      const SizedBox(width: 8),
                      Text(
                        t.multi_item_items_section,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Item forms
                  for (var i = 0; i < _items.length; i++)
                    _buildItemBlock(i, _items[i], t),

                  // Add another button
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _addAnotherItem,
                    icon: const Icon(Icons.add),
                    label: Text(t.multi_item_add_another),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _saving
          ? const CircularProgressIndicator()
          : FloatingActionButton.extended(
              onPressed: _createItems,
              icon: const Icon(Icons.check),
              label: Text(t.multi_item_create_button(_items.length)),
            ),
    );
  }

  Widget _buildItemBlock(
      int index, _ItemFormData itemData, AppLocalizations t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.multi_item_item_number(index + 1),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeItem(index),
                    tooltip: t.delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Product name
            TextFormField(
              controller: itemData.titleCtrl,
              decoration: InputDecoration(
                labelText: t.items_name,
                hintText: t.items_name_hint,
              ),
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.text,
              enableSuggestions: true,
              autocorrect: true,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.field_required : null,
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: t.items_category),
              initialValue: itemData.selectedCategory,
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
                setState(() {
                  itemData.selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Warranty duration or custom expiry
            if (itemData.customExpiryDate == null) ...[
              Text(
                t.warranty_years,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('2 ${t.years_suffix}'),
                    selected: itemData.warrantyYears == 2,
                    onSelected: (_) {
                      setState(() {
                        itemData.warrantyYears = 2;
                        itemData.customWarrantyYears = null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text('3 ${t.years_suffix}'),
                    selected: itemData.warrantyYears == 3,
                    onSelected: (_) {
                      setState(() {
                        itemData.warrantyYears = 3;
                        itemData.customWarrantyYears = null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text('5 ${t.years_suffix}'),
                    selected: itemData.warrantyYears == 5,
                    onSelected: (_) {
                      setState(() {
                        itemData.warrantyYears = 5;
                        itemData.customWarrantyYears = null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text(t.warranty_custom),
                    selected: itemData.customWarrantyYears != null,
                    onSelected: (_) {
                      setState(() {
                        itemData.warrantyYears = null;
                        itemData.customWarrantyYears = 1;
                      });
                    },
                  ),
                ],
              ),

              // Custom warranty years input
              if (itemData.customWarrantyYears != null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: itemData.customWarrantyYears?.toString(),
                  decoration: InputDecoration(
                    labelText: t.warranty_custom_years,
                    suffixText: t.years_suffix,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return t.field_required;
                    }
                    final years = int.tryParse(v);
                    if (years == null || years < 1 || years > 99) {
                      return 'Enter 1-99 years';
                    }
                    return null;
                  },
                  onChanged: (v) {
                    final years = int.tryParse(v);
                    if (years != null && years >= 1 && years <= 99) {
                      setState(() {
                        itemData.customWarrantyYears = years;
                        itemData.warrantyYears = years;
                      });
                    }
                  },
                ),
              ],
              const SizedBox(height: 12),

              // Switch to custom expiry date
              TextButton.icon(
                onPressed: () => _pickCustomExpiryDate(itemData),
                icon: const Icon(Icons.date_range),
                label: Text(t.items_pick_expiry_date),
              ),
            ] else ...[
              // Custom expiry date selected
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.items_expiry),
                subtitle: Text(
                    '${_formatDate(itemData.customExpiryDate!)} (${t.custom_expiry})'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: t.use_warranty_duration,
                      onPressed: () {
                        setState(() {
                          itemData.customExpiryDate = null;
                          itemData.warrantyYears = null;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () => _pickCustomExpiryDate(itemData),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper class to hold form data for each item
class _ItemFormData {
  final TextEditingController titleCtrl = TextEditingController();
  String? selectedCategory;
  int? warrantyYears;
  int? customWarrantyYears;
  DateTime? customExpiryDate;

  void dispose() {
    titleCtrl.dispose();
  }
}

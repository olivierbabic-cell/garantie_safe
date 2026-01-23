// lib/features/items/item_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

import 'item.dart';
import 'items_providers.dart';

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

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd.$mm.$yyyy';
  }
}

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:garantie_safe/core/db/app_db.dart';
import 'package:garantie_safe/features/payments/payment_method.dart';
import 'package:garantie_safe/features/payments/payment_method_service.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

/// Comprehensive payment methods management screen
class PaymentMethodsManagementScreen extends StatefulWidget {
  const PaymentMethodsManagementScreen({super.key});

  @override
  State<PaymentMethodsManagementScreen> createState() =>
      _PaymentMethodsManagementScreenState();
}

class _PaymentMethodsManagementScreenState
    extends State<PaymentMethodsManagementScreen> {
  final _service = PaymentMethodService.instance;
  List<PaymentMethod> _methods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() => _loading = true);
    try {
      final methods = await _service.getAll();
      if (mounted) {
        setState(() {
          _methods = methods;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.payments_error_loading(e.toString()))),
        );
      }
    }
  }

  Future<void> _addCustomMethod() async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.payment_methods_add_dialog_title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t.payment_methods_add_dialog_hint,
          ),
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.text,
          enableSuggestions: true,
          autocorrect: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(t.payment_methods_add_dialog_save),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await _service.addCustomMethod(result);
        await _loadMethods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.snack_saved_prefix}: $result')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.trash_error_display(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _editCustomMethod(PaymentMethod method) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: method.customLabel);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.payment_methods_edit_dialog_title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t.payment_methods_add_dialog_hint,
          ),
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.text,
          enableSuggestions: true,
          autocorrect: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(t.payment_methods_edit_dialog_save),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await _service.updateCustomLabel(method, result);
        await _loadMethods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.snack_saved_prefix}: $result')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.trash_error_display(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _deleteMethod(PaymentMethod method) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.payment_methods_delete_confirm_title),
        content: Text(t.payment_methods_delete_confirm_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.payment_methods_delete_confirm_ok),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deleted = await _service.deleteCustomMethod(method);
        await _loadMethods();

        if (mounted) {
          if (!deleted) {
            // Was archived instead of deleted
            final db = await AppDb.instance.database;
            final count = Sqflite.firstIntValue(
                  await db.rawQuery(
                    'SELECT COUNT(*) FROM items WHERE payment_method_code = ?',
                    [method.code],
                  ),
                ) ??
                0;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t.payment_methods_cannot_delete_message(count),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.deleted)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.trash_error_display(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _toggleEnabled(PaymentMethod method) async {
    final t = AppLocalizations.of(context)!;
    try {
      await _service.toggleEnabled(method);
      await _loadMethods();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.trash_error_display(e.toString()))),
        );
      }
    }
  }

  Future<void> _unarchive(PaymentMethod method) async {
    final t = AppLocalizations.of(context)!;
    try {
      await _service.unarchive(method);
      await _loadMethods();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.trash_error_display(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.payment_methods_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Group methods
    final enabled =
        _methods.where((m) => !m.isArchived && m.isEnabled).toList();
    final disabled =
        _methods.where((m) => !m.isArchived && !m.isEnabled).toList();
    final archived = _methods.where((m) => m.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.payment_methods_title),
      ),
      body: _methods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    t.payment_methods_empty,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                if (enabled.isNotEmpty) ...[
                  _buildSectionHeader(t.payment_methods_section_enabled),
                  ...enabled.map((m) => _buildMethodTile(m)),
                  const Divider(height: 32),
                ],
                if (disabled.isNotEmpty) ...[
                  _buildSectionHeader(t.payment_methods_section_disabled),
                  ...disabled.map((m) => _buildMethodTile(m)),
                  const Divider(height: 32),
                ],
                if (archived.isNotEmpty) ...[
                  _buildSectionHeader(t.payment_methods_section_archived),
                  ...archived.map((m) => _buildMethodTile(m)),
                ],
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomMethod,
        icon: const Icon(Icons.add),
        label: Text(t.payment_methods_add),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildMethodTile(PaymentMethod method) {
    final t = AppLocalizations.of(context)!;
    final label = PaymentMethodService.getLabel(context, method);

    return ListTile(
      leading: Icon(
        method.isArchived
            ? Icons.archive
            : method.isEnabled
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
        color: method.isArchived
            ? Colors.grey
            : method.isEnabled
                ? Colors.green
                : Colors.grey,
      ),
      title: Text(label),
      subtitle: _buildSubtitle(method, t),
      trailing: _buildTrailing(method),
      onTap: method.isArchived
          ? () => _unarchive(method)
          : () => _toggleEnabled(method),
    );
  }

  Widget? _buildSubtitle(PaymentMethod method, AppLocalizations t) {
    final chips = <String>[];

    if (method.isArchived) {
      chips.add(t.payment_methods_archived);
    }
    if (!method.isBuiltIn) {
      chips.add(t.payment_methods_custom);
    }

    if (chips.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: chips.map((text) {
          return Chip(
            label: Text(text),
            visualDensity: VisualDensity.compact,
            labelStyle: const TextStyle(fontSize: 11),
            padding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget? _buildTrailing(PaymentMethod method) {
    if (method.isArchived) {
      return IconButton(
        icon: const Icon(Icons.unarchive),
        onPressed: () => _unarchive(method),
        tooltip: 'Restore',
      );
    }

    if (!method.isBuiltIn) {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.edit),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  MaterialLocalizations.of(context).deleteButtonTooltip,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            _editCustomMethod(method);
          } else if (value == 'delete') {
            _deleteMethod(method);
          }
        },
      );
    }

    return null;
  }
}

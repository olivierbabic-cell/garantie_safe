// lib/features/items/items_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

import 'item.dart';
import 'items_providers.dart';
import 'item_edit_screen.dart';

class ItemsListScreen extends ConsumerStatefulWidget {
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen> {
  int _filterIndex = 0; // 0 = all, 1 = soon, 2 = expired

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
        child: const Icon(Icons.add),
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ItemEditScreen()),
          );

          if (changed == true && mounted) {
            await ref.read(itemsListProvider.notifier).refresh();
          }
        },
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
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

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(itemsListProvider.notifier).refresh(),
                  child: filtered.isEmpty
                      ? _EmptyState(filterIndex: _filterIndex)
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final itemId = item.id;

                            return _ItemCard(
                              item: item,
                              statusText: _statusText(context, item),
                              onTap: () async {
                                final changed =
                                    await Navigator.of(context).push<bool>(
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
                                final ok = await _confirmDelete(context, t);
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

    bool soon(Item i) {
      final ms = i.expiryDate;
      if (ms == null) return false;
      final expiry =
          DateUtils.dateOnly(DateTime.fromMillisecondsSinceEpoch(ms));
      final diffDays = expiry.difference(today).inDays;
      return diffDays >= 0 && diffDays <= 45;
    }

    switch (_filterIndex) {
      case 1:
        return items.where(soon).toList();
      case 2:
        return items.where(expired).toList();
      default:
        return items;
    }
  }

  String? _statusText(BuildContext context, Item item) {
    final t = AppLocalizations.of(context)!;

    final ms = item.expiryDate;
    if (ms == null) return null;

    final today = DateUtils.dateOnly(DateTime.now());
    final expiry = DateUtils.dateOnly(DateTime.fromMillisecondsSinceEpoch(ms));
    final diffDays = expiry.difference(today).inDays;

    if (diffDays < 0) return t.filter_expired; // simple reuse, no new keys
    if (diffDays == 0) return 'Today'; // optional: später i18n key
    if (diffDays <= 45) return '${t.filter_soon}: $diffDays';
    return null;
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            selected: index == 0,
            onSelected: (_) => onChanged(0),
            label: Text(t.filter_all),
          ),
          ChoiceChip(
            selected: index == 1,
            onSelected: (_) => onChanged(1),
            label: Text(t.filter_soon),
          ),
          ChoiceChip(
            selected: index == 2,
            onSelected: (_) => onChanged(2),
            label: Text(t.filter_expired),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.statusText,
    this.onTap,
    this.onDelete,
  });

  final Item item;
  final String? statusText;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final subtitleParts = <String>[];

    final merchant = (item.merchant ?? '').trim();
    if (merchant.isNotEmpty) subtitleParts.add(merchant);

    final expiry = _formatExpiry(item.expiryDate);
    if (expiry != null) subtitleParts.add(expiry);

    final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join(' • ');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LeadingIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (statusText != null &&
                        statusText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _StatusPill(text: statusText!),
                    ],
                  ],
                ),
              ),
              if (onDelete != null)
                PopupMenuButton<String>(
                  tooltip: t.more,
                  onSelected: (_) => onDelete?.call(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(t.delete),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatExpiry(int? expiryDateMs) {
    if (expiryDateMs == null) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(expiryDateMs);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd.$mm.$yyyy';
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.receipt_long, color: cs.onSurfaceVariant),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filterIndex});

  final int filterIndex;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final title = switch (filterIndex) {
      1 => t.empty_soon_title,
      2 => t.empty_expired_title,
      _ => t.empty_all_title,
    };

    final hint = switch (filterIndex) {
      1 => t.empty_soon_hint,
      2 => t.empty_expired_hint,
      _ => t.empty_all_hint,
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.inbox_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            hint,
            textAlign: TextAlign.center,
          ),
        ),
      ],
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

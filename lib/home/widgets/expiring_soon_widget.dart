import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/features/items/items_providers.dart';
import 'package:garantie_safe/features/items/item.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class ExpiringSoonWidget extends ConsumerWidget {
  const ExpiringSoonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsListProvider);

    return itemsAsync.when(
      data: (items) => _buildContent(context, items),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context, List<Item> items) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<int>(
      future: Prefs.getReminderLeadTimeDays(),
      initialData: 7,
      builder: (context, snapshot) {
        final leadDays = snapshot.data ?? 7;
        final expiringItems = _getExpiringItems(items, leadDays);

        if (expiringItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      t.warrantiesExpiringSoonTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/items'),
                      child: Text(t.warrantiesViewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...expiringItems.take(3).map((item) {
                  final daysLeft = _getDaysUntilExpiry(item);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: daysLeft <= 0
                                ? Colors.red.shade700
                                : daysLeft <= 7
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            daysLeft <= 0
                                ? 'Expired'
                                : daysLeft == 1
                                    ? '1 day'
                                    : '$daysLeft days',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (expiringItems.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${expiringItems.length - 3} more',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Item> _getExpiringItems(List<Item> items, int leadDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threshold = today.add(Duration(days: leadDays));

    final expiring = items.where((item) {
      if (item.expiryDate == null) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(item.expiryDate!);
      final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
      return expiryDate.isBefore(threshold) ||
          expiryDate.isAtSameMomentAs(threshold);
    }).toList();

    // Sort by expiry date (soonest first)
    expiring.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

    return expiring;
  }

  int _getDaysUntilExpiry(Item item) {
    if (item.expiryDate == null) return 999;
    final expiry = DateTime.fromMillisecondsSinceEpoch(item.expiryDate!);
    final now = DateTime.now();

    // Normalize both dates to midnight for accurate day counting
    final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
    final today = DateTime(now.year, now.month, now.day);

    return expiryDate.difference(today).inDays;
  }
}

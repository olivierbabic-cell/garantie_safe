// lib/features/premium/upgrade_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:garantie_safe/features/premium/premium_service.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

/// Dialog shown when user hits freemium limit
/// Offers upgrade to premium or restore previous purchase
class UpgradeDialog extends StatefulWidget {
  const UpgradeDialog({super.key});

  @override
  State<UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<UpgradeDialog> {
  bool _loading = false;
  String? _price;
  Timer? _premiumCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
    _startPremiumCheck();
  }

  @override
  void dispose() {
    _premiumCheckTimer?.cancel();
    super.dispose();
  }

  /// Periodically check if premium was unlocked (via purchase stream)
  /// Auto-close dialog when premium is detected
  void _startPremiumCheck() {
    _premiumCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final isPremium = await PremiumService.instance.isPremium();
      if (isPremium && mounted) {
        // Premium unlocked! Close dialog successfully
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _loadProductDetails() async {
    final product = await PremiumService.instance.getProductDetails();
    if (product != null && mounted) {
      setState(() {
        _price = product.price;
      });
    }
  }

  Future<void> _handleUpgrade() async {
    setState(() => _loading = true);

    try {
      final success = await PremiumService.instance.buyLifetimeUnlock();

      if (!mounted) return;

      if (success) {
        // Purchase initiated - dialog will auto-close when purchase completes
        // via the premium check timer detecting the premium flag
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.premium_purchase_initiated),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.premium_purchase_failed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.premium_purchase_error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _loading = true);

    try {
      final success = await PremiumService.instance.restorePurchases();

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true); // Close dialog - premium restored
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.premium_restored),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.premium_no_purchase_found),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.premium_restore_error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(t.premium_upgrade_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.premium_limit_reached,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              t.premium_free_limit_info(PremiumService.maxFreeItems),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.premium_unlock_title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeature(t.premium_feature_unlimited, theme),
                  _buildFeature(t.premium_feature_lifetime, theme),
                  _buildFeature(t.premium_feature_no_subscription, theme),
                  _buildFeature(t.premium_feature_offline, theme),
                  if (_price != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      t.premium_price(_price!),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text(t.premium_not_now),
        ),
        TextButton(
          onPressed: _loading ? null : _handleRestore,
          child: Text(t.premium_restore),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _handleUpgrade,
          icon: const Icon(Icons.upgrade),
          label: Text(t.premium_upgrade),
        ),
      ],
    );
  }

  Widget _buildFeature(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show upgrade dialog
Future<bool> showUpgradeDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UpgradeDialog(),
  );
  return result ?? false;
}

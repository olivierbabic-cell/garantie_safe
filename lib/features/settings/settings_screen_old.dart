import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/locale_controller.dart';
import 'package:garantie_safe/features/backup/backup_restore_screen.dart';
import 'package:garantie_safe/features/backup/setup_hub_screen.dart';
import 'package:garantie_safe/features/items/trash_screen.dart';
import 'package:garantie_safe/features/items/items_repository.dart';
import 'package:garantie_safe/features/premium/premium_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;

  /// 'system' | 'de' | 'en'
  String _language = 'system';

  int? _lastBackupTimestamp;

  bool _isPremium = false;
  String? _premiumSource;
  int _activeItemCount = 0;
  bool _premiumLoading = false; // Loading state for premium actions
  Timer? _premiumCheckTimer; // Timer for reactive premium status
  bool? _debugPremiumOverride; // Debug override state (null = no override)

  @override
  void initState() {
    super.initState();
    _load();
    _startPremiumCheck();
  }

  @override
  void dispose() {
    _premiumCheckTimer?.cancel();
    super.dispose();
  }

  /// Periodically check if premium status changed (e.g., via purchase completed)
  void _startPremiumCheck() {
    _premiumCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final isPremiumNow = await PremiumService.instance.isPremium();
      if (isPremiumNow != _isPremium && mounted) {
        // Premium status changed - reload
        await _load();
      }
    });
  }

  Future<void> _load() async {
    final dark = await Prefs.getDarkMode();
    final lang = await Prefs.getLanguage(); // 'de' | 'en' | null
    final lastBackup = await Prefs.getBackupLastSuccessAt();

    // Load premium status
    final premium = await PremiumService.instance.isPremium();
    final source = await PremiumService.instance.getPremiumSource();

    // Load active item count for free users
    final itemCount = await ItemsRepository().countActiveItems();

    // Load debug override state (only in debug mode)
    bool? debugOverride;
    if (kDebugMode) {
      debugOverride = await Prefs.getDebugPremiumOverride();
    }

    if (!mounted) return;
    setState(() {
      _darkMode = dark;
      _language = (lang == null || lang.isEmpty) ? 'system' : lang;
      _lastBackupTimestamp = lastBackup;
      _isPremium = premium;
      _premiumSource = source;
      _activeItemCount = itemCount;
      _debugPremiumOverride = debugOverride;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    await Prefs.setDarkMode(value);
    if (!mounted) return;
    setState(() => _darkMode = value);
  }

  Future<void> _setLanguage(String code) async {
    await LocaleController.instance.setLanguage(code);
    if (!mounted) return;
    setState(() => _language = code);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Setup & Preferences Hub
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.tune, color: Colors.white),
              ),
              title: Text(t.setup_hub_card_title),
              subtitle: Text(t.setup_hub_card_subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SetupHubScreen(),
                  ),
                );
              },
            ),
          ),

          // Premium Card
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _isPremium ? Colors.amber : Colors.grey,
                    child: Icon(
                      _isPremium ? Icons.workspace_premium : Icons.lock,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(t.premium_card_title),
                  subtitle: Text(
                    _isPremium
                        ? t.premium_status_premium
                        : t.premium_status_free(
                            _activeItemCount,
                            PremiumService.maxFreeItems,
                          ),
                  ),
                ),
                if (!_isPremium)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        FilledButton.icon(
                          onPressed: _premiumLoading ? null : _handleUpgrade,
                          icon: _premiumLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upgrade),
                          label: Text(t.premium_buy_lifetime),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _premiumLoading ? null : _handleRestore,
                          child: Text(t.premium_restore),
                        ),
                      ],
                    ),
                  ),
                if (_isPremium && _premiumSource != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      t.premium_unlocked_via(_premiumSource!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),

          // Debug Premium Override (only in debug mode)
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              color: Colors.orange.shade50,
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.bug_report, color: Colors.white),
                    ),
                    title: Text(t.settings_debug_premium_override),
                    subtitle: Text(
                      _debugPremiumOverride == null
                          ? t.settings_debug_no_override
                          : _debugPremiumOverride!
                              ? t.settings_debug_forced_premium
                              : t.settings_debug_forced_free,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleDebugOverrideChanged(false),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _debugPremiumOverride == false
                                  ? Colors.orange.shade100
                                  : null,
                            ),
                            child: Text(t.settings_force_free),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleDebugOverrideChanged(null),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _debugPremiumOverride == null
                                  ? Colors.orange.shade100
                                  : null,
                            ),
                            child: Text(t.settings_real_state),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleDebugOverrideChanged(true),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _debugPremiumOverride == true
                                  ? Colors.orange.shade100
                                  : null,
                            ),
                            child: Text(t.settings_force_premium),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          Text(
            t.settings_section_general,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile(
            title: Text(t.settings_dark_mode),
            subtitle: Text(t.settings_dark_mode_sub),
            value: _darkMode,
            onChanged: _setDarkMode,
          ),
          const Divider(),

          // Sprache
          ListTile(
            title: Text(t.settings_language),
            trailing: DropdownButton<String>(
              value: _language,
              onChanged: (v) {
                if (v == null) return;
                _setLanguage(v);
              },
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(t.settings_language_system),
                ),
                DropdownMenuItem(
                  value: 'de',
                  child: Text(t.language_name_de),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(t.language_name_en),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            t.settings_section_security,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          // Backup & Restore
          ListTile(
            title: Text(t.backup_title),
            subtitle: Text(_formatLastBackup(t)),
            trailing: const Icon(Icons.backup),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BackupRestoreScreen(),
                ),
              );
              _load(); // Refresh backup status
            },
          ),
          const Divider(),

          // Trash
          ListTile(
            title: Text(t.trash_title),
            trailing: const Icon(Icons.delete),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrashScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatLastBackup(AppLocalizations t) {
    if (_lastBackupTimestamp == null) return t.backup_never;

    final date = DateTime.fromMillisecondsSinceEpoch(_lastBackupTimestamp!);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return t.backup_time_just_now;
    if (diff.inHours < 1) return t.backup_time_minutes_ago(diff.inMinutes);
    if (diff.inDays < 1) return t.backup_time_hours_ago(diff.inHours);
    if (diff.inDays < 7) return t.backup_time_days_ago(diff.inDays);

    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _handleUpgrade() async {
    setState(() => _premiumLoading = true);

    try {
      final success = await PremiumService.instance.buyLifetimeUnlock();

      if (!mounted) return;

      if (success) {
        // Purchase initiated or completed - show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.premium_purchase_initiated),
            backgroundColor: Colors.blue,
          ),
        );
        // Premium check timer will auto-reload when status changes
      } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.premium_purchase_error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _premiumLoading = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _premiumLoading = true);

    try {
      final success = await PremiumService.instance.restorePurchases();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.premium_restored),
            backgroundColor: Colors.green,
          ),
        );
        // Premium check timer will auto-reload when status changes
      } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.premium_restore_error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _premiumLoading = false);
      }
    }
  }

  Future<void> _handleDebugOverrideChanged(bool? value) async {
    if (!kDebugMode) return;

    await Prefs.setDebugPremiumOverride(value);
    await _load();
  }
}

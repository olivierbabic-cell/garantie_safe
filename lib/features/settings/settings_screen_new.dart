import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/locale_controller.dart';
import 'package:garantie_safe/features/backup/backup_restore_screen.dart';
import 'package:garantie_safe/features/items/trash_screen.dart';
import 'package:garantie_safe/features/items/items_repository.dart';
import 'package:garantie_safe/features/premium/premium_service.dart';
import 'package:garantie_safe/features/settings/notifications_settings_screen.dart';
import 'package:garantie_safe/features/settings/security_settings_screen.dart';
import 'package:garantie_safe/features/payments/payment_methods_management_screen.dart';
import 'package:garantie_safe/features/settings/widgets/settings_row.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _language = 'system';
  int? _lastBackupTimestamp;
  bool _isPremium = false;
  String? _premiumSource;
  int _activeItemCount = 0;
  bool _premiumLoading = false;
  Timer? _premiumCheckTimer;
  bool? _debugPremiumOverride;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _load();
    _startPremiumCheck();
    _loadAppVersion();
  }

  @override
  void dispose() {
    _premiumCheckTimer?.cancel();
    super.dispose();
  }

  void _startPremiumCheck() {
    _premiumCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final isPremiumNow = await PremiumService.instance.isPremium();
      if (isPremiumNow != _isPremium && mounted) {
        await _load();
      }
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  Future<void> _load() async {
    final dark = await Prefs.getDarkMode();
    final lang = await Prefs.getLanguage();
    final lastBackup = await Prefs.getBackupLastSuccessAt();
    final premium = await PremiumService.instance.isPremium();
    final source = await PremiumService.instance.getPremiumSource();
    final itemCount = await ItemsRepository().countActiveItems();

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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(t.settings_title),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ==================================================
          // PREFERENCES SECTION
          // ==================================================
          SettingsSection(
            title: t.settings_section_preferences,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          ),

          // Language
          SettingsRow(
            icon: Icons.language,
            title: t.settings_language,
            trailing: DropdownButton<String>(
              value: _language,
              underline: const SizedBox(),
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

          // Appearance / Theme
          SettingsRow(
            icon: Icons.palette_outlined,
            title: t.settings_appearance,
            subtitle: t.settings_appearance_sub,
            trailing: Switch(
              value: _darkMode,
              onChanged: _setDarkMode,
            ),
          ),

          // Notifications
          SettingsRow(
            icon: Icons.notifications_outlined,
            title: t.settings_notifications,
            subtitle: t.settings_notifications_sub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsSettingsScreen(),
                ),
              );
            },
          ),

          // Payment Methods
          SettingsRow(
            icon: Icons.payment,
            title: t.settings_payment_methods,
            subtitle: t.settings_payment_methods_sub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentMethodsManagementScreen(),
                ),
              );
            },
            showDivider: false,
          ),

          // ==================================================
          // BACKUP & SECURITY SECTION
          // ==================================================
          SettingsSection(title: t.settings_section_backup_security),

          // Backup & Restore
          SettingsRow(
            icon: Icons.backup,
            title: t.backup_title,
            subtitle: _formatLastBackup(t),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BackupRestoreScreen(),
                ),
              );
              _load();
            },
          ),

          // App Lock / Security
          SettingsRow(
            icon: Icons.lock_outline,
            title: t.settings_app_lock,
            subtitle: t.settings_app_lock_sub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SecuritySettingsScreen(),
                ),
              );
            },
            showDivider: false,
          ),

          // ==================================================
          // DATA & STORAGE SECTION
          // ==================================================
          SettingsSection(title: t.settings_section_data_storage),

          // Trash / Deleted Items
          SettingsRow(
            icon: Icons.delete_outline,
            title: t.trash_title,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrashScreen(),
                ),
              );
            },
            showDivider: false,
          ),

          // ==================================================
          // PREMIUM SECTION
          // ==================================================
          SettingsSection(title: t.premium_card_title),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isPremium ? Colors.amber.shade300 : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isPremium
                            ? Icons.workspace_premium
                            : Icons.lock_outline,
                        color: _isPremium ? Colors.amber : Colors.grey[600],
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPremium
                                  ? t.premium_status_premium
                                  : t.premium_status_free(
                                      _activeItemCount,
                                      PremiumService.maxFreeItems,
                                    ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isPremium && _premiumSource != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                t.premium_unlocked_via(_premiumSource!),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isPremium) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                ],
              ],
            ),
          ),

          // ==================================================
          // ABOUT SECTION
          // ==================================================
          SettingsSection(title: t.settings_section_about),

          // App Version
          SettingsRow(
            icon: Icons.info_outline,
            title: t.settings_app_version,
            subtitle: _appVersion.isNotEmpty ? _appVersion : '...',
            showDivider: false,
          ),

          // ==================================================
          // DEVELOPER OPTIONS (Debug Only)
          // ==================================================
          if (kDebugMode) ...[
            SettingsSection(title: t.settings_section_developer),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.bug_report,
                            color: Colors.orange[700], size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.settings_debug_premium_override,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _debugPremiumOverride == null
                                    ? t.settings_debug_no_override
                                    : _debugPremiumOverride!
                                        ? t.settings_debug_forced_premium
                                        : t.settings_debug_forced_free,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleDebugOverrideChanged(false),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _debugPremiumOverride == false
                                  ? Colors.orange.shade50
                                  : null,
                              side: BorderSide(
                                color: _debugPremiumOverride == false
                                    ? Colors.orange.shade400
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              t.settings_force_free,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleDebugOverrideChanged(null),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _debugPremiumOverride == null
                                  ? Colors.orange.shade50
                                  : null,
                              side: BorderSide(
                                color: _debugPremiumOverride == null
                                    ? Colors.orange.shade400
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              t.settings_real_state,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleDebugOverrideChanged(true),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _debugPremiumOverride == true
                                  ? Colors.orange.shade50
                                  : null,
                              side: BorderSide(
                                color: _debugPremiumOverride == true
                                    ? Colors.orange.shade400
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              t.settings_force_premium,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    setState(() => _premiumLoading = true);

    try {
      final success = await PremiumService.instance.buyLifetimeUnlock();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.premium_purchase_initiated),
            backgroundColor: Colors.blue,
          ),
        );
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

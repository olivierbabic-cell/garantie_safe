import 'package:flutter/material.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/core/services/warranty_notification_scheduler.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const NotificationsSettingsScreen({
    super.key,
    this.isOnboarding = false,
    this.onComplete,
  });

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _loading = true;
  bool _enableReminders = true;
  bool _remind30Days = true;
  bool _remind7Days = true;
  bool _remindOnExpiry = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await Prefs.getNotificationsEnabled();
    final remind30 = await Prefs.getRemind30Days();
    final remind7 = await Prefs.getRemind7Days();
    final remindExpiry = await Prefs.getRemindOnExpiryDay();

    if (!mounted) return;
    setState(() {
      _enableReminders = enabled;
      _remind30Days = remind30;
      _remind7Days = remind7;
      _remindOnExpiry = remindExpiry;
      _loading = false;
    });
  }

  Future<void> _updateEnableReminders(bool value) async {
    final t = AppLocalizations.of(context)!;
    await Prefs.setNotificationsEnabled(value);
    setState(() => _enableReminders = value);

    // Reschedule all notifications
    if (value) {
      await WarrantyNotificationScheduler.rescheduleAllActiveItems();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(value ? t.notifications_enabled : t.notifications_disabled),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateRemind30Days(bool value) async {
    await Prefs.setRemind30Days(value);
    setState(() => _remind30Days = value);

    // Reschedule all notifications
    if (_enableReminders) {
      await WarrantyNotificationScheduler.rescheduleAllActiveItems();
    }
  }

  Future<void> _updateRemind7Days(bool value) async {
    await Prefs.setRemind7Days(value);
    setState(() => _remind7Days = value);

    // Reschedule all notifications
    if (_enableReminders) {
      await WarrantyNotificationScheduler.rescheduleAllActiveItems();
    }
  }

  Future<void> _updateRemindOnExpiry(bool value) async {
    await Prefs.setRemindOnExpiryDay(value);
    setState(() => _remindOnExpiry = value);

    // Reschedule all notifications
    if (_enableReminders) {
      await WarrantyNotificationScheduler.rescheduleAllActiveItems();
    }
  }

  void _completeSetup() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.notifications_screen_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notifications_screen_title),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          if (!widget.isOnboarding)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.notifications_local_info,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!widget.isOnboarding) const SizedBox(height: 16),

          // Enable toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_enable_reminders),
            subtitle: Text(t.notifications_remind_before_expiry),
            value: _enableReminders,
            onChanged: _updateEnableReminders,
          ),
          const Divider(),

          // Reminder preferences heading
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              t.notifications_reminder_schedule,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _enableReminders
                        ? null
                        : Theme.of(context).disabledColor,
                  ),
            ),
          ),

          // 30 days before
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_30_days_before),
            value: _remind30Days,
            onChanged: _enableReminders ? _updateRemind30Days : null,
          ),

          // 7 days before
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_7_days_before),
            value: _remind7Days,
            onChanged: _enableReminders ? _updateRemind7Days : null,
          ),

          // On expiry day
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_on_expiry_day),
            value: _remindOnExpiry,
            onChanged: _enableReminders ? _updateRemindOnExpiry : null,
          ),

          const SizedBox(height: 16),

          // System notification permission note
          Text(
            t.notifications_system_permissions_note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),

          if (widget.isOnboarding) ...[
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _completeSetup,
              child: Text(t.continue_button),
            ),
          ],
        ],
      ),
    );
  }
}

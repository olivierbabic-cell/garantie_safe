import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _reminders = true;
  bool _weekly = false;
  int _leadDays = 7;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _summaryTime = const TimeOfDay(hour: 9, minute: 0);
  int _summaryWeekday = DateTime.monday; // 1..7

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();

    final reminders = sp.getBool('notif_reminders') ?? true;
    final weekly = sp.getBool('notif_weekly') ?? false;
    final leadDays = sp.getInt('notif_lead_days') ?? 7;

    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay summaryTime = const TimeOfDay(hour: 9, minute: 0);

    final rt = sp.getString('notif_reminder_time'); // "HH:MM"
    final st = sp.getString('notif_summary_time');

    if (rt != null && rt.contains(':')) {
      final p = rt.split(':');
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h != null && m != null) {
        reminderTime = TimeOfDay(hour: h, minute: m);
      }
    }

    if (st != null && st.contains(':')) {
      final p = st.split(':');
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h != null && m != null) {
        summaryTime = TimeOfDay(hour: h, minute: m);
      }
    }

    final summaryWeekday =
        sp.getInt('notif_summary_weekday') ?? DateTime.monday;

    if (!mounted) return;
    setState(() {
      _reminders = reminders;
      _weekly = weekly;
      _leadDays = leadDays;
      _reminderTime = reminderTime;
      _summaryTime = summaryTime;
      _summaryWeekday = summaryWeekday;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('notif_reminders', _reminders);
      await sp.setBool('notif_weekly', _weekly);
      await sp.setInt('notif_lead_days', _leadDays);
      await sp.setString('notif_reminder_time', _fmt(_reminderTime));
      await sp.setString('notif_summary_time', _fmt(_summaryTime));
      await sp.setInt('notif_summary_weekday', _summaryWeekday);

      if (!mounted) return;
      final t = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.notif_saved)),
      );

      // WICHTIG: Onboarding nicht "zurückpoppen", sondern Stack leeren und zur Home.
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(
      void Function(TimeOfDay) set, TimeOfDay initial) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    set(picked);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.notifications_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.notifications_intro, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_reminders),
            subtitle: Text(t.notifications_reminders_sub),
            value: _reminders,
            onChanged: _saving ? null : (v) => setState(() => _reminders = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_lead_title),
            subtitle: Text(t.notifications_lead_sub),
            trailing: DropdownButton<int>(
              value: _leadDays,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _leadDays = v ?? _leadDays),
              items: const [1, 3, 7, 14, 30]
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                  .toList(),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_time_title),
            trailing: TextButton(
              onPressed: _saving
                  ? null
                  : () => _pickTime((x) => _reminderTime = x, _reminderTime),
              child: Text(_fmt(_reminderTime)),
            ),
          ),
          const Divider(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_summary),
            subtitle: Text(t.notifications_summary_sub),
            value: _weekly,
            onChanged: _saving ? null : (v) => setState(() => _weekly = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_summary_day_title),
            trailing: DropdownButton<int>(
              value: _summaryWeekday,
              onChanged: _saving
                  ? null
                  : (v) =>
                      setState(() => _summaryWeekday = v ?? _summaryWeekday),
              items: [
                DropdownMenuItem(
                    value: DateTime.monday, child: Text(t.weekday_mon)),
                DropdownMenuItem(
                    value: DateTime.tuesday, child: Text(t.weekday_tue)),
                DropdownMenuItem(
                    value: DateTime.wednesday, child: Text(t.weekday_wed)),
                DropdownMenuItem(
                    value: DateTime.thursday, child: Text(t.weekday_thu)),
                DropdownMenuItem(
                    value: DateTime.friday, child: Text(t.weekday_fri)),
                DropdownMenuItem(
                    value: DateTime.saturday, child: Text(t.weekday_sat)),
                DropdownMenuItem(
                    value: DateTime.sunday, child: Text(t.weekday_sun)),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.notifications_summary_time_title),
            trailing: TextButton(
              onPressed: _saving
                  ? null
                  : () => _pickTime((x) => _summaryTime = x, _summaryTime),
              child: Text(_fmt(_summaryTime)),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(t.notifications_finish),
          ),
        ],
      ),
    );
  }
}

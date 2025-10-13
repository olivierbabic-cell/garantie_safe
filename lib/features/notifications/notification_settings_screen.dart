import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _enableReminders = true;
  double _daysBefore = 30; // Tage vor Ablauf
  bool _weeklyDigest = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _enableReminders = sp.getBool('notif_enableReminders') ?? true;
      _daysBefore = (sp.getInt('notif_daysBefore') ?? 30).toDouble();
      _weeklyDigest = sp.getBool('notif_weeklyDigest') ?? false;
    });
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('notif_enableReminders', _enableReminders);
    await sp.setInt('notif_daysBefore', _daysBefore.toInt());
    await sp.setBool('notif_weeklyDigest', _weeklyDigest);
  }

  void _finish() async {
    await _savePrefs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Benachrichtigungseinstellungen gespeichert')),
      );
      // TODO: hier später zum Dashboard/Home navigieren
      Navigator.of(context).pop(); // zurück
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erinnerungen & Benachrichtigungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Erinnerungen aktivieren'),
            subtitle: const Text('Ablauf von Garantien, Serviceintervalle etc.'),
            value: _enableReminders,
            onChanged: (v) => setState(() => _enableReminders = v),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Vorlaufzeit vor Ablauf'),
            subtitle: Text('${_daysBefore.toInt()} Tage'),
          ),
          Slider(
            value: _daysBefore,
            min: 7,
            max: 90,
            divisions: 83,
            label: '${_daysBefore.toInt()}',
            onChanged: _enableReminders ? (v) => setState(() => _daysBefore = v) : null,
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('Wöchentliche Zusammenfassung'),
            subtitle: const Text('Einmal pro Woche Überblick über fällige Garantien'),
            value: _weeklyDigest,
            onChanged: (v) => setState(() => _weeklyDigest = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Fertig'),
            onPressed: _finish,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hinweis: Push-Benachrichtigungen richten wir später ein. '
            'Diese Seite speichert nur deine Präferenzen.',
            style: TextStyle(color: Colors.black54),
          )
        ],
      ),
    );
  }
}
